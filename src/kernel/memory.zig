const console = @import("console.zig");
const std = @import("std");

pub const PAGE_SIZE: usize = 4096;
pub const TOTAL_PAGES: usize = 256 * 1024; // 1GB of manageable memory (1024MB / 4KB = 256 * 1024 pages)
pub const MEMORY_START: usize = 0x41000000; // Start of manageable memory

var page_bitmap: [TOTAL_PAGES]bool = undefined;

pub const PageAllocator = struct {
    pub fn init() PageAllocator {
        return PageAllocator{};
    }

    pub fn allocate(self: *PageAllocator, len: usize) ?[*]u8 {
        _ = self;
        const pages_needed = (len + PAGE_SIZE - 1) / PAGE_SIZE;
        var consecutive_pages: usize = 0;
        var start_page: usize = 0;

        console.puts("Allocating ");
        console.putInt(len);
        console.puts(" bytes (");
        console.putInt(pages_needed);
        console.puts(" pages)\n");

        console.puts("Searching for free pages...\n");
        console.puts("Total pages: ");
        console.putInt(page_bitmap.len);
        console.puts("\n");

        var i: usize = 0;
        while (i < page_bitmap.len) : (i += 1) {
            if (i % 1000 == 0) {
                console.puts("Checking page ");
                console.putInt(i);
                console.puts("\n");
            }

            if (!page_bitmap[i]) {
                if (consecutive_pages == 0) {
                    start_page = i;
                    console.puts("Found potential start page: ");
                    console.putInt(start_page);
                    console.puts("\n");
                }
                consecutive_pages += 1;
                if (consecutive_pages == pages_needed) {
                    console.puts("Found enough consecutive pages. Marking as allocated...\n");
                    // Mark pages as allocated
                    var j: usize = 0;
                    while (j < pages_needed) : (j += 1) {
                        page_bitmap[start_page + j] = true;
                        console.puts("Marked page ");
                        console.putInt(start_page + j);
                        console.puts(" as allocated\n");
                    }
                    const allocated_address = MEMORY_START + (start_page * PAGE_SIZE);
                    console.puts("Allocation complete. Address: 0x");
                    console.putIntHex(allocated_address);
                    console.puts("\n");
                    return @ptrFromInt(allocated_address);
                }
            } else {
                consecutive_pages = 0;
            }
        }

        console.puts("Allocation failed: Not enough consecutive free pages\n");
        return null;
    }

    pub fn deallocate(self: *PageAllocator, ptr: [*]u8, len: usize) void {
        _ = self;
        const start_addr = @intFromPtr(ptr);
        if (start_addr < MEMORY_START or start_addr >= MEMORY_START + (TOTAL_PAGES * PAGE_SIZE)) {
            console.puts("Invalid address for freeing: 0x");
            console.putIntHex(@intFromPtr(ptr));
            console.puts("\n");
            return;
        }

        const start_page = (start_addr - MEMORY_START) / PAGE_SIZE;
        const pages_to_free = (len + PAGE_SIZE - 1) / PAGE_SIZE;

        var i: usize = 0;
        while (i < pages_to_free) : (i += 1) {
            const page_index = start_page + i;
            if (!page_bitmap[page_index]) {
                console.puts("Double free detected at page index: ");
                console.putInt(page_index);
                console.puts("\n");
                return;
            }
            page_bitmap[page_index] = false;
        }
    }
};

pub fn init_memory() void {
    console.puts("Initializing memory management system\n");
    for (0..TOTAL_PAGES) |i| {
        page_bitmap[i] = false;
    }
    console.puts("Memory initialization complete. Verifying...\n");
    for (0..TOTAL_PAGES) |i| {
        if (page_bitmap[i]) {
            console.puts("Error: Page ");
            console.putInt(i);
            console.puts(" is not properly initialized\n");
            return;
        }
        if (i % 10000 == 0) {
            console.puts("Verified up to page ");
            console.putInt(i);
            console.puts("\n");
        }
    }
    console.puts("Memory initialization verified successfully\n");
}

pub fn alloc_page() usize {
    var i: usize = 0;
    while (i < page_bitmap.len) {
        if (!page_bitmap[i]) {
            page_bitmap[i] = true;
            const page_address = MEMORY_START + (i * PAGE_SIZE);
            return page_address;
        }
        i += 1;
    }

    console.puts("Allocation failed: No free pages available\n");
    return 0; // Return 0 to indicate allocation failure
}

pub fn free_page(addr: usize) void {
    if (addr < MEMORY_START or addr >= MEMORY_START + (TOTAL_PAGES * PAGE_SIZE)) {
        console.puts("Invalid address for freeing: 0x");
        console.putIntHex(addr);
        console.puts("\n");
        return;
    }

    const page_index = (addr - MEMORY_START) / PAGE_SIZE;
    if (!page_bitmap[page_index]) {
        console.puts("Double free detected at address: 0x");
        console.putIntHex(addr);
        console.puts("\n");
        return;
    }

    page_bitmap[page_index] = false;
}

pub fn get_free_page_count() usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < page_bitmap.len) {
        if (!page_bitmap[i]) {
            count += 1;
        }
        i += 1;
    }

    console.puts("Total free pages: ");
    console.putInt(count);
    console.puts("\n");
    return count;
}
