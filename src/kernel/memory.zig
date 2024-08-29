const std = @import("std");
const console = @import("console.zig");

pub const PAGE_SIZE: usize = 4096;
pub const TOTAL_PAGES: usize = 256 * 1024; // 1GB of manageable memory
pub const MEMORY_START: usize = 0x41000000; // Start of manageable memory
pub const HUGE_PAGE_SIZE: usize = 2 * 1024 * 1024; // 2MB huge pages
pub const HUGE_PAGES: usize = TOTAL_PAGES * PAGE_SIZE / HUGE_PAGE_SIZE;

pub var page_allocator: PageAllocator = undefined;

pub const PageAllocator = struct {
    buddy_allocator: BuddyAllocator,
    slab_allocator: SlabAllocator,
    huge_page_allocator: HugePageAllocator,
    bitmap: HybridBitmap,
    memory_start: usize,
    total_memory: usize,

    pub fn init() PageAllocator {
        return PageAllocator{
            .buddy_allocator = BuddyAllocator.init(),
            .slab_allocator = SlabAllocator.init(),
            .huge_page_allocator = HugePageAllocator.init(),
            .bitmap = HybridBitmap.init(),
            .memory_start = MEMORY_START,
            .total_memory = TOTAL_PAGES * PAGE_SIZE,
        };
    }

    pub fn allocate(self: *PageAllocator, len: usize) ?[*]u8 {
        if (len <= SlabAllocator.MAX_SLAB_SIZE) {
            return self.slab_allocator.allocate(len);
        } else if (len >= HUGE_PAGE_SIZE) {
            return self.huge_page_allocator.allocate(len);
        } else {
            return self.buddy_allocator.allocate(len);
        }
    }

    pub fn deallocate(self: *PageAllocator, ptr: [*]u8, len: usize) void {
        const addr = @intFromPtr(ptr);
        if (addr < MEMORY_START or addr >= MEMORY_START + (TOTAL_PAGES * PAGE_SIZE)) {
            console.puts("Invalid address for freeing: 0x");
            console.putIntHex(addr);
            console.puts("\n");
            return;
        }

        if (len <= SlabAllocator.MAX_SLAB_SIZE) {
            self.slab_allocator.deallocate(ptr, len);
        } else if (len >= HUGE_PAGE_SIZE) {
            self.huge_page_allocator.deallocate(ptr, len);
        } else {
            self.buddy_allocator.deallocate(ptr, len);
        }
    }

    pub fn balanceMemory(self: *PageAllocator) void {
        // Implement memory ballooning logic
        const total_free = self.buddy_allocator.getTotalFreeMemory() +
            self.slab_allocator.getTotalFreeMemory() +
            self.huge_page_allocator.getTotalFreeMemory();

        const target_free = self.total_memory / 4; // Aim to keep 25% free
        if (total_free < target_free) {
            // Need to reclaim memory
            const to_reclaim = target_free - total_free;
            self.reclaimMemory(to_reclaim);
        } else if (total_free > target_free * 2) {
            // Can release memory
            const to_release = total_free - target_free;
            self.releaseMemory(to_release);
        }
    }

    fn reclaimMemory(self: *PageAllocator, amount: usize) void {
        // Implement memory reclamation logic
        // This could involve compacting memory, swapping out pages, etc.
        _ = self;
        _ = amount;
        console.puts("Memory reclamation not yet implemented\n");
    }

    fn releaseMemory(self: *PageAllocator, amount: usize) void {
        // Implement memory release logic
        // This could involve returning memory to the system or a higher-level allocator
        _ = self;
        _ = amount;
        console.puts("Memory release not yet implemented\n");
    }

    pub fn alloc_page(self: *PageAllocator) ?usize {
        return self.buddy_allocator.allocate(PAGE_SIZE);
    }
};

const BuddyAllocator = struct {
    const MAX_ORDER: usize = 11; // 2^11 * 4KB = 8MB max allocation

    free_lists: [MAX_ORDER]?*Block,

    const Block = struct {
        next: ?*Block,
        order: u5,
    };

    pub fn init() BuddyAllocator {
        var self = BuddyAllocator{
            .free_lists = .{null} ** MAX_ORDER,
        };
        // Initialize with all memory
        const total_blocks = TOTAL_PAGES >> MAX_ORDER;
        var i: usize = 0;
        while (i < total_blocks) : (i += 1) {
            const block = @as(*Block, @ptrFromInt(MEMORY_START + i * (PAGE_SIZE << MAX_ORDER)));
            block.order = MAX_ORDER;
            self.addToFreeList(block);
        }
        return self;
    }

    fn addToFreeList(self: *BuddyAllocator, block: *Block) void {
        block.next = self.free_lists[block.order];
        self.free_lists[block.order] = block;
    }

    pub fn allocate(self: *BuddyAllocator, size: usize) ?[*]u8 {
        const pages_needed = (size + PAGE_SIZE - 1) / PAGE_SIZE;
        const order = @as(u5, @intCast(std.math.log2_int(usize, std.math.next_power_of_two(pages_needed))));

        if (order > MAX_ORDER) return null;

        var current_order = order;
        while (current_order <= MAX_ORDER) : (current_order += 1) {
            if (self.free_lists[current_order]) |block| {
                self.free_lists[current_order] = block.next;
                while (current_order > order) {
                    current_order -= 1;
                    const buddy = @as(*Block, @ptrFromInt(@intFromPtr(block) + (PAGE_SIZE << current_order)));
                    buddy.order = current_order;
                    self.addToFreeList(buddy);
                }
                return @ptrCast(block);
            }
        }

        return null;
    }

    pub fn deallocate(self: *BuddyAllocator, ptr: [*]u8, size: usize) void {
        const pages_needed = (size + PAGE_SIZE - 1) / PAGE_SIZE;
        var order = @as(u5, @intCast(std.math.log2_int(usize, std.math.next_power_of_two(pages_needed))));
        var block = @as(*Block, @ptrCast(ptr));

        while (order < MAX_ORDER) {
            const buddy_addr = @intFromPtr(block) ^ (PAGE_SIZE << order);
            const buddy = @as(*Block, @ptrFromInt(buddy_addr));

            if (buddy.order != order) break;

            // Remove buddy from its free list
            var current = &self.free_lists[order];
            while (current.*) |curr_block| {
                if (curr_block == buddy) {
                    current.* = curr_block.next;
                    break;
                }
                current = &curr_block.next;
            } else break;

            block = @as(*Block, @ptrFromInt(@min(@intFromPtr(block), @intFromPtr(buddy))));
            order += 1;
        }

        block.order = order;
        self.addToFreeList(block);
    }

    pub fn getTotalFreeMemory(self: *BuddyAllocator) usize {
        var total: usize = 0;
        for (self.free_lists, 0..) |maybe_block, order| {
            var block = maybe_block;
            while (block) |b| {
                total += PAGE_SIZE << @intCast(order);
                block = b.next;
            }
        }
        return total;
    }
};

const SlabAllocator = struct {
    const MAX_SLAB_SIZE: usize = 2048;
    const MIN_SLAB_SIZE: usize = 8;
    const SLAB_CLASSES: usize = 8;

    slabs: [SLAB_CLASSES]Slab,

    const Slab = struct {
        free_list: ?*SlabBlock,
        block_size: usize,
    };

    const SlabBlock = struct {
        next: ?*SlabBlock,
    };

    pub fn init() SlabAllocator {
        var self = SlabAllocator{ .slabs = undefined };
        var size: usize = MIN_SLAB_SIZE;
        for (&self.slabs) |*slab| {
            slab.* = Slab{ .free_list = null, .block_size = size };
            size *= 2;
        }
        return self;
    }

    pub fn allocate(self: *SlabAllocator, size: usize) ?[*]u8 {
        const slab_index = std.math.log2_int(usize, std.math.next_power_of_two(size)) - std.math.log2_int(usize, MIN_SLAB_SIZE);
        if (slab_index >= SLAB_CLASSES) return null;

        var slab = &self.slabs[slab_index];
        if (slab.free_list) |block| {
            slab.free_list = block.next;
            return @ptrCast(block);
        }

        // Allocate a new page for this slab class
        const page = @as([*]u8, @ptrFromInt(page_allocator.alloc_page() orelse return null));
        const blocks_per_page = PAGE_SIZE / slab.block_size;
        var i: usize = 0;
        while (i < blocks_per_page - 1) : (i += 1) {
            const block = @as(*SlabBlock, @ptrCast(&page[i * slab.block_size]));
            block.next = @as(*SlabBlock, @ptrCast(&page[(i + 1) * slab.block_size]));
        }
        const last_block = @as(*SlabBlock, @ptrCast(&page[(blocks_per_page - 1) * slab.block_size]));
        last_block.next = null;

        slab.free_list = @ptrCast(&page[slab.block_size]);
        return page;
    }

    pub fn deallocate(self: *SlabAllocator, ptr: [*]u8, size: usize) void {
        const slab_index = std.math.log2_int(usize, std.math.next_power_of_two(size)) - std.math.log2_int(usize, MIN_SLAB_SIZE);
        if (slab_index >= SLAB_CLASSES) return;

        var slab = &self.slabs[slab_index];
        const block = @as(*SlabBlock, @ptrCast(ptr));
        block.next = slab.free_list;
        slab.free_list = block;
    }

    pub fn getTotalFreeMemory(self: *SlabAllocator) usize {
        var total: usize = 0;
        for (self.slabs) |slab| {
            var block = slab.free_list;
            while (block) |b| {
                total += slab.block_size;
                block = b.next;
            }
        }
        return total;
    }
};

const HugePageAllocator = struct {
    free_list: ?*HugePageBlock,

    const HugePageBlock = struct {
        next: ?*HugePageBlock,
        size: usize,
    };

    pub fn init() HugePageAllocator {
        return HugePageAllocator{ .free_list = null };
    }

    pub fn allocate(self: *HugePageAllocator, size: usize) ?[*]u8 {
        const pages_needed = (size + HUGE_PAGE_SIZE - 1) / HUGE_PAGE_SIZE;
        var current = &self.free_list;
        while (current.*) |block| {
            if (block.size >= pages_needed) {
                if (block.size > pages_needed) {
                    const new_block = @as(*HugePageBlock, @ptrFromInt(@intFromPtr(block) + pages_needed * HUGE_PAGE_SIZE));
                    new_block.size = block.size - pages_needed;
                    new_block.next = block.next;
                    current.* = new_block;
                } else {
                    current.* = block.next;
                }
                return @ptrCast(block);
            }
            current = &block.next;
        }
        return null;
    }

    pub fn deallocate(self: *HugePageAllocator, ptr: [*]u8, size: usize) void {
        const pages = (size + HUGE_PAGE_SIZE - 1) / HUGE_PAGE_SIZE;
        const block = @as(*HugePageBlock, @ptrCast(ptr));
        block.size = pages;
        block.next = self.free_list;
        self.free_list = block;
        // TODO: Implement coalescing of adjacent free blocks
    }

    pub fn getTotalFreeMemory(self: *HugePageAllocator) usize {
        var total: usize = 0;
        var block = self.free_list;
        while (block) |b| {
            total += b.size * HUGE_PAGE_SIZE;
            block = b.next;
        }
        return total;
    }
};

const HybridBitmap = struct {
    normal_pages: std.bit_set.DynamicBitSet,
    huge_pages: HierarchicalBitmap,

    const HUGE_PAGE_LEVELS: usize = 4; // Adjust based on your huge page size range

    pub fn init() HybridBitmap {
        return HybridBitmap{
            .normal_pages = std.bit_set.DynamicBitSet.initFull(std.heap.page_allocator, TOTAL_PAGES) catch unreachable,
            .huge_pages = HierarchicalBitmap.init(),
        };
    }

    pub fn allocateNormal(self: *HybridBitmap, pages: usize) ?usize {
        var start: usize = 0;
        while (start + pages <= TOTAL_PAGES) : (start += 1) {
            if (self.normal_pages.isSet(start)) {
                var is_free = true;
                var i: usize = 0;
                while (i < pages) : (i += 1) {
                    if (!self.normal_pages.isSet(start + i)) {
                        is_free = false;
                        break;
                    }
                }
                if (is_free) {
                    i = 0;
                    while (i < pages) : (i += 1) {
                        self.normal_pages.unset(start + i);
                    }
                    return start;
                }
            }
        }
        return null;
    }

    pub fn deallocateNormal(self: *HybridBitmap, start: usize, pages: usize) void {
        var i: usize = 0;
        while (i < pages) : (i += 1) {
            self.normal_pages.set(start + i);
        }
    }

    pub fn allocateHuge(self: *HybridBitmap, size: usize) ?usize {
        return self.huge_pages.allocate(size);
    }

    pub fn deallocateHuge(self: *HybridBitmap, start: usize, size: usize) void {
        self.huge_pages.deallocate(start, size);
    }
};

const HierarchicalBitmap = struct {
    levels: [HUGE_PAGE_LEVELS]Level,

    const HUGE_PAGE_LEVELS: usize = 4;
    const BITS_PER_LEVEL: usize = 64;

    const Level = struct {
        bitmap: u64,
        child_index: [BITS_PER_LEVEL]usize,
    };

    pub fn init() HierarchicalBitmap {
        var self = HierarchicalBitmap{ .levels = undefined };
        for (&self.levels) |*level| {
            level.bitmap = ~@as(u64, 0);
            @memset(&level.child_index, 0);
        }
        return self;
    }

    pub fn allocate(self: *HierarchicalBitmap, size: usize) ?usize {
        const level = std.math.log2_int(usize, size / HUGE_PAGE_SIZE);
        if (level >= HUGE_PAGE_LEVELS) return null;

        var current_level: usize = HUGE_PAGE_LEVELS - 1;
        var index: usize = 0;

        while (current_level > level) : (current_level -= 1) {
            const bit = @ctz(self.levels[current_level].bitmap);
            if (bit == BITS_PER_LEVEL) return null;

            index = (index << 6) | bit;
            self.levels[current_level].bitmap &= ~(@as(u64, 1) << @intCast(bit));
        }

        const bit = @ctz(self.levels[current_level].bitmap);
        if (bit == BITS_PER_LEVEL) return null;

        index = (index << 6) | bit;
        self.levels[current_level].bitmap &= ~(@as(u64, 1) << @intCast(bit));

        return index * HUGE_PAGE_SIZE;
    }

    pub fn deallocate(self: *HierarchicalBitmap, start: usize, size: usize) void {
        const level = std.math.log2_int(usize, size / HUGE_PAGE_SIZE);
        if (level >= HUGE_PAGE_LEVELS) return;

        var current_level: usize = level;
        var index = start / HUGE_PAGE_SIZE;

        while (current_level < HUGE_PAGE_LEVELS) : (current_level += 1) {
            const bit: u6 = @intCast(index & 0x3F);
            self.levels[current_level].bitmap |= @as(u64, 1) << bit;
            if (self.levels[current_level].bitmap != ~@as(u64, 0)) break;
            index >>= 6;
        }
    }
};
