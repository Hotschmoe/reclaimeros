const std = @import("std");

const PHYSICAL_MEMORY_SIZE: u64 = 128 * 1024 * 1024; // 128 MB
const PAGE_SIZE: u64 = 4096; // 4 KB pages
const NUM_PHYSICAL_PAGES: u64 = PHYSICAL_MEMORY_SIZE / PAGE_SIZE;
const KERNEL_VIRTUAL_BASE: u64 = 0xFFFF000000000000; // High memory for kernel space
const USER_VIRTUAL_BASE: u64 = 0x0000000000000000; // Low memory for user space
const VIRTUAL_MEMORY_SIZE: u64 = 1 << 48; // 256 TB (48-bit address space)
const NUM_VIRTUAL_PAGES: u64 = VIRTUAL_MEMORY_SIZE / PAGE_SIZE;

const PAGE_LEVELS: u8 = 4;
const ENTRIES_PER_PAGE: u16 = 512;

const PAGE_PRESENT: u64 = 1 << 0;
const PAGE_WRITABLE: u64 = 1 << 1;
const PAGE_USER: u64 = 1 << 2;
const PAGE_ACCESSED: u64 = 1 << 8;
const PAGE_DIRTY: u64 = 1 << 9;

const MemoryRegion = enum {
    Kernel,
    User,
    Device,
};

const PTE = u64;

const PageTable = struct {
    entries: [ENTRIES_PER_PAGE]PTE,
};

const MemoryBlock = struct {
    next: ?*MemoryBlock,
    size: usize,
    is_free: bool,
};

var physical_page_bitmap: [NUM_PHYSICAL_PAGES / 8]u8 = undefined;
var kernel_page_table: *PageTable = undefined;
var physical_memory_start: usize = undefined;
var free_list: ?*MemoryBlock = null;

pub fn memory_init(start_address: usize) void {
    physical_memory_start = start_address;

    @memset(&physical_page_bitmap, 0xFF);

    const kernel_pages = (16 * 1024 * 1024) / PAGE_SIZE;
    mark_pages(0, kernel_pages, false);

    kernel_page_table = create_page_table() catch unreachable;

    var addr: u64 = 0;
    while (addr < (1 << 30)) : (addr += PAGE_SIZE) {
        map_page(KERNEL_VIRTUAL_BASE + addr, addr, PAGE_PRESENT | PAGE_WRITABLE);
    }

    free_list = @ptrCast(*MemoryBlock, allocate_pages(1) catch unreachable);
    free_list.?.next = null;
    free_list.?.size = PAGE_SIZE - @sizeOf(MemoryBlock);
    free_list.?.is_free = true;
}

pub fn kmalloc(allocator: *std.mem.Allocator, size: usize) ?*anyopaque {
    const total_size = size + @sizeOf(MemoryBlock);
    var current = free_list;
    var prev: ?*MemoryBlock = null;

    while (current) |curr| {
        if (curr.is_free and curr.size >= total_size) {
            if (curr.size > total_size + @sizeOf(MemoryBlock)) {
                const new_block = @intToPtr(*MemoryBlock, @ptrToInt(curr) + total_size);
                new_block.next = curr.next;
                new_block.size = curr.size - total_size;
                new_block.is_free = true;

                curr.next = new_block;
                curr.size = total_size;
            }

            curr.is_free = false;
            return @intToPtr(*anyopaque, @ptrToInt(curr) + @sizeOf(MemoryBlock));
        }

        prev = curr;
        current = curr.next;
    }

    const pages_needed = (total_size + PAGE_SIZE - 1) / PAGE_SIZE;
    const new_block = allocate_pages(pages_needed) catch return null;

    const block = @ptrCast(*MemoryBlock, new_block);
    block.next = free_list;
    block.size = pages_needed * PAGE_SIZE - @sizeOf(MemoryBlock);
    block.is_free = false;

    free_list = block;

    return @intToPtr(*anyopaque, @ptrToInt(block) + @sizeOf(MemoryBlock));
}

pub fn kfree(allocator: *std.mem.Allocator, ptr: *anyopaque) void {
    if (ptr == null) {
        return;
    }

    const block = @intToPtr(*MemoryBlock, @ptrToInt(ptr) - @sizeOf(MemoryBlock));
    block.is_free = true;

    var current = free_list;
    while (current) |curr| {
        if (curr.next) |next| {
            if (curr.is_free and next.is_free) {
                curr.size += next.size + @sizeOf(MemoryBlock);
                curr.next = next.next;
            } else {
                current = curr.next;
            }
        } else {
            break;
        }
    }
}

pub fn vmalloc(allocator: *std.mem.Allocator, size: usize, region: MemoryRegion) ?*anyopaque {
    const pages_needed = (size + PAGE_SIZE - 1) / PAGE_SIZE;
    const virtual_base = if (region == .Kernel) KERNEL_VIRTUAL_BASE else USER_VIRTUAL_BASE;

    var virtual_addr: u64 = virtual_base;
    var contiguous_pages: usize = 0;

    while (virtual_addr < VIRTUAL_MEMORY_SIZE) : (virtual_addr += PAGE_SIZE) {
        if (virtual_to_physical(virtual_addr) == 0) {
            contiguous_pages += 1;
            if (contiguous_pages == pages_needed) {
                break;
            }
        } else {
            contiguous_pages = 0;
        }
    }

    if (contiguous_pages < pages_needed) {
        return null;
    }

    virtual_addr -= (pages_needed - 1) * PAGE_SIZE;

    var i: usize = 0;
    while (i < pages_needed) : (i += 1) {
        const physical_addr = allocate_pages(1) catch {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                unmap_page(virtual_addr + j * PAGE_SIZE);
            }
            return null;
        };

        var flags: u64 = PAGE_PRESENT | PAGE_WRITABLE;
        if (region == .User) {
            flags |= PAGE_USER;
        }

        map_page(virtual_addr + i * PAGE_SIZE, @ptrToInt(physical_addr), flags);
    }

    return @intToPtr(*anyopaque, virtual_addr);
}

pub fn vfree(allocator: *std.mem.Allocator, ptr: *anyopaque) void {
    if (ptr == null) {
        return;
    }

    var virtual_addr = @ptrToInt(ptr);

    while (virtual_to_physical(virtual_addr) != 0) {
        const physical_addr = virtual_to_physical(virtual_addr);
        unmap_page(virtual_addr);
        free_pages(@intToPtr(*anyopaque, physical_addr), 1);
        virtual_addr += PAGE_SIZE;
    }
}

fn allocate_pages(num_pages: usize) !*anyopaque {
    const start_page = find_free_pages(num_pages) orelse return error.OutOfMemory;

    mark_pages(start_page, num_pages, false);

    return @intToPtr(*anyopaque, physical_memory_start + (start_page * PAGE_SIZE));
}

fn free_pages(ptr: *anyopaque, num_pages: usize) void {
    const addr = @ptrToInt(ptr);
    const page = (addr - physical_memory_start) / PAGE_SIZE;

    mark_pages(@intCast(u64, page), num_pages, true);
}

fn find_free_pages(num_pages: usize) ?u64 {
    var start: i64 = -1;
    var count: usize = 0;

    var i: u64 = 0;
    while (i < NUM_PHYSICAL_PAGES) : (i += 1) {
        if (physical_page_bitmap[i / 8] & (1 << @intCast(u3, i % 8)) != 0) {
            if (start == -1) {
                start = @intCast(i64, i);
            }
            count += 1;
            if (count == num_pages) {
                return @intCast(u64, start);
            }
        } else {
            start = -1;
            count = 0;
        }
    }

    return null;
}

fn mark_pages(start_page: u64, num_pages: usize, is_free: bool) void {
    var i = start_page;
    const end = start_page + num_pages;
    while (i < end) : (i += 1) {
        const byte_index = i / 8;
        const bit_index = @intCast(u3, i % 8);
        if (is_free) {
            physical_page_bitmap[byte_index] |= @as(u8, 1) << bit_index;
        } else {
            physical_page_bitmap[byte_index] &= ~(@as(u8, 1) << bit_index);
        }
    }
}

fn virtual_to_physical(virtual_addr: u64) u64 {
    var table = kernel_page_table;

    var level: u8 = PAGE_LEVELS;
    while (level > 1) : (level -= 1) {
        const index = (virtual_addr >> (12 + 9 * (level - 1))) & 0x1FF;
        const pte = table.entries[index];

        if (pte & PAGE_PRESENT == 0) {
            return 0;
        }

        table = @intToPtr(*PageTable, pte & ~@as(u64, 0xFFF));
    }

    const index = (virtual_addr >> 12) & 0x1FF;
    const pte = table.entries[index];

    if (pte & PAGE_PRESENT == 0) {
        return 0;
    }

    return (pte & ~@as(u64, 0xFFF)) | (virtual_addr & 0xFFF);
}

fn map_page(virtual_addr: u64, physical_addr: u64, flags: u64) void {
    var table = kernel_page_table;

    var level: u8 = PAGE_LEVELS;
    while (level > 1) : (level -= 1) {
        const index = (virtual_addr >> (12 + 9 * (level - 1))) & 0x1FF;
        const pte = &table.entries[index];

        if (pte.* & PAGE_PRESENT == 0) {
            const new_table = create_page_table() catch unreachable;
            pte.* = @ptrToInt(new_table) | PAGE_PRESENT | PAGE_WRITABLE;
            if (flags & PAGE_USER != 0) {
                pte.* |= PAGE_USER;
            }
        }

        table = @intToPtr(*PageTable, pte.* & ~@as(u64, 0xFFF));
    }

    const index = (virtual_addr >> 12) & 0x1FF;
    table.entries[index] = physical_addr | flags;
}

fn unmap_page(virtual_addr: u64) void {
    var table = kernel_page_table;

    var level: u8 = PAGE_LEVELS;
    while (level > 1) : (level -= 1) {
        const index = (virtual_addr >> (12 + 9 * (level - 1))) & 0x1FF;
        const pte = table.entries[index];

        if (pte & PAGE_PRESENT == 0) {
            return;
        }

        table = @intToPtr(*PageTable, pte & ~@as(u64, 0xFFF));
    }

    const index = (virtual_addr >> 12) & 0x1FF;
    table.entries[index] = 0;
}

fn create_page_table() !*PageTable {
    const table = @ptrCast(*PageTable, try allocate_pages(1));

    for (table.entries) |*entry| {
        entry.* = 0;
    }

    return table;
}
