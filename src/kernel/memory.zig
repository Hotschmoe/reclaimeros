const console = @import("console.zig");

pub const PAGE_SIZE: usize = 4096;
pub const TOTAL_PAGES: usize = 256 * 1024; // 1GB of manageable memory (1024MB / 4KB = 256 * 1024 pages)
pub const MEMORY_START: usize = 0x41000000; // Start of manageable memory

var page_bitmap: [TOTAL_PAGES]bool = undefined;

pub fn init_memory() void {
    console.puts("Initializing memory management system\n");
    for (0..TOTAL_PAGES) |i| {
        page_bitmap[i] = false;
    }
    console.puts("Memory initialization complete\n");
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
