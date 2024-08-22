const std = @import("std");
const console = @import("console.zig");

// Constants
pub const PAGE_SIZE: usize = 4096; // 4KB pages
pub const TOTAL_MEMORY: usize = 128 * 1024 * 1024; // 128MB
pub const TOTAL_PAGES: usize = TOTAL_MEMORY / PAGE_SIZE;
const BITMAP_SIZE: usize = (TOTAL_PAGES + 7) / 8; // Round up to nearest byte

// Bitmap to track free pages
var page_bitmap: [BITMAP_SIZE]u8 align(8) = undefined;

pub fn init_memory() void {
    console.puts("Starting memory initialization...\n");
    console.puts("BITMAP_SIZE: ");
    putInt(BITMAP_SIZE);
    console.puts(" bytes\n");

    console.puts("Zeroing bitmap...\n");
    var i: usize = 0;
    while (i < BITMAP_SIZE) : (i += 1) {
        page_bitmap[i] = 0;
        if (i % 1000 == 0 or i == BITMAP_SIZE - 1) {
            console.puts("Zeroed ");
            putInt(i + 1);
            console.puts(" / ");
            putInt(BITMAP_SIZE);
            console.puts(" bytes\n");
        }
    }

    console.puts("Memory bitmap initialized. Total pages: ");
    putInt(TOTAL_PAGES);
    console.puts("\n");

    console.puts("First 20 bytes of bitmap: ");
    i = 0;
    while (i < 20 and i < BITMAP_SIZE) : (i += 1) {
        putInt(@as(usize, page_bitmap[i]));
        console.puts(" ");
    }
    console.puts("\n");

    console.puts("Memory initialization complete.\n");
}

pub fn alloc_page() ?usize {
    console.puts("Entering alloc_page()\n");
    for (page_bitmap, 0..) |byte, byte_index| {
        if (byte != 0xFF) {
            const bit_index = @ctz(~@as(u8, byte));
            const bit_mask = @as(u8, 1) << @intCast(bit_index);
            page_bitmap[byte_index] |= bit_mask;
            const page_index = byte_index * 8 + bit_index;
            const page_address = page_index * PAGE_SIZE;
            console.puts("Allocated page at address: ");
            putInt(page_address);
            console.puts("\n");
            return page_address;
        }
    }
    console.puts("No free pages available\n");
    return null;
}

pub fn free_page(addr: usize) void {
    const page_index = addr / PAGE_SIZE;
    const byte_index = page_index / 8;
    const bit_index: u3 = @truncate(page_index % 8);
    page_bitmap[byte_index] &= ~(@as(u8, 1) << bit_index);
    console.puts("Freed page at address: ");
    putInt(addr);
    console.puts("\n");
}

pub fn putInt(value: usize) void {
    if (value == 0) {
        console.puts("0");
        return;
    }

    var buf: [20]u8 = undefined;
    var i: usize = 0;
    var v = value;

    while (v > 0) : (v /= 10) {
        buf[19 - i] = @intCast((v % 10) + '0');
        i += 1;
    }

    console.puts(buf[20 - i ..]);
}

pub fn get_allocated_pages_count() usize {
    var count: usize = 0;
    for (page_bitmap) |byte| {
        count += @popCount(byte);
    }
    return count;
}

pub fn debug_print_bitmap() void {
    console.puts("Bitmap state (1 = allocated, 0 = free):\n");
    for (page_bitmap, 0..) |byte, i| {
        for (0..8) |bit| {
            if (byte & (@as(u8, 1) << @intCast(bit)) != 0) {
                console.puts("1");
            } else {
                console.puts("0");
            }
        }
        if ((i + 1) % 8 == 0) {
            console.puts("\n");
        } else {
            console.puts(" ");
        }
    }
    console.puts("\n");
}
