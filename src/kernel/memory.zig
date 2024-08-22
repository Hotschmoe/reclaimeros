const std = @import("std");

// Constants
const PAGE_SIZE: usize = 4096; // 4KB pages
const TOTAL_MEMORY: usize = 1024 * 1024 * 1024; // 1GB for example
const TOTAL_PAGES: usize = TOTAL_MEMORY / PAGE_SIZE;

// Bitmap to track free pages
var page_bitmap: [TOTAL_PAGES / 8]u8 = undefined;

pub fn init_memory() void {
    // Initialize all pages as free
    @memset(&page_bitmap, 0);
}

pub fn alloc_page() ?usize {
    for (page_bitmap, 0..) |byte, i| {
        if (byte != 0xFF) {
            for (0..8) |j| {
                if ((byte & (@as(u8, 1) << @truncate(j))) == 0) {
                    // Mark page as allocated
                    page_bitmap[i] |= (@as(u8, 1) << @truncate(j));
                    return (i * 8 + j) * PAGE_SIZE;
                }
            }
        }
    }
    return null; // No free pages
}

pub fn free_page(addr: usize) void {
    const page_index = addr / PAGE_SIZE;
    const byte_index = page_index / 8;
    const bit_index: u3 = @truncate(page_index % 8);
    page_bitmap[byte_index] &= ~(@as(u8, 1) << bit_index);
}
