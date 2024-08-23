const console = @import("console.zig");

pub const PAGE_SIZE: usize = 4096;
const TOTAL_PAGES: usize = 1024; // 4MB of manageable memory
const MEMORY_START: usize = 0x41000000; // Start of manageable memory

var page_bitmap: [TOTAL_PAGES]bool = undefined;

pub fn init_memory() void {
    console.puts("Initializing memory management system\n");
    for (0..TOTAL_PAGES) |i| {
        page_bitmap[i] = false;
    }
    console.puts("Memory initialization complete\n");
}

pub fn alloc_page() usize {
    console.puts("Starting page allocation...\n");

    var i: usize = 0;
    while (i < page_bitmap.len) {
        if (!page_bitmap[i]) {
            page_bitmap[i] = true;
            const page_address = MEMORY_START + (i * PAGE_SIZE);

            console.puts("Allocated page at address: 0x");
            console.putIntHex(page_address); // Use Hex format for better readability in memory addresses
            console.puts("\n");

            return page_address;
        }

        i += 1;

        // Debugging statement to show progress
        if (i % 100 == 0) {
            console.puts("Checked ");
            console.putInt(i);
            console.puts(" pages during allocation.\n");
        }
    }

    console.puts("Allocation failed: No free pages available\n");
    return 0; // Return 0 to indicate allocation failure
}

pub fn free_page(addr: usize) void {
    if (addr < MEMORY_START or addr >= MEMORY_START + (TOTAL_PAGES * PAGE_SIZE)) {
        console.puts("Invalid address for freeing: 0x");
        console.putInt(addr);
        console.puts("\n");
        return;
    }

    const page_index = (addr - MEMORY_START) / PAGE_SIZE;
    if (!page_bitmap[page_index]) {
        console.puts("Double free detected at address: 0x");
        console.putInt(addr);
        console.puts("\n");
        return;
    }

    page_bitmap[page_index] = false;
    console.puts("Freed page at address: 0x");
    console.putInt(addr);
    console.puts("\n");
}

pub fn get_free_page_count() usize {
    console.puts("Starting to count free pages...\n");
    var count: usize = 0;
    var i: usize = 0;
    while (i < page_bitmap.len) {
        const is_allocated = page_bitmap[i];
        if (!is_allocated) {
            count += 1;
        }

        // Print every 512 pages checked
        if (i % 512 == 0) {
            console.puts("Currently checked ");
            console.putInt(i);
            console.puts(" pages.\n");
        }

        i += 1;
    }

    console.puts("Finished counting. Total free pages: ");
    console.putInt(count);
    console.puts("\n");
    return count;
}
