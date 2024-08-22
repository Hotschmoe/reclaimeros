const console = @import("console.zig");

pub const PAGE_SIZE: usize = 4096;
pub const TOTAL_MEMORY: usize = 128 * 1024 * 1024;
pub const TOTAL_PAGES: usize = TOTAL_MEMORY / PAGE_SIZE;
const BITMAP_SIZE: usize = (TOTAL_PAGES + 7) / 8;

var page_bitmap: [BITMAP_SIZE]u8 align(8) = undefined;

pub fn init_memory() void {
    console.puts("Init start\n");
    for (0..BITMAP_SIZE) |i| {
        page_bitmap[i] = 0;
        if (i % 1000 == 0) {
            console.putchar('.');
        }
    }
    // Reserve the first page (address 0) to avoid null pointer issues
    page_bitmap[0] = 1;
    console.puts("\nInit end\n");
}

fn delay(cycles: usize) void {
    var i: usize = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}

pub fn alloc_page() usize {
    console.puts("Alloc start\n");
    delay(10000);

    // Always allocate the second page for simplicity
    const addr: usize = PAGE_SIZE;
    console.puts("Allocated at ");
    console.putInt(addr);
    console.puts("\n");
    delay(10000);

    console.puts("Before return\n");
    delay(10000);

    console.puts("Return value: ");
    console.putInt(addr);
    console.puts("\n");
    delay(10000);

    console.puts("After printing return value\n");
    delay(10000);

    return addr;
}

pub fn free_page(addr: usize) void {
    console.puts("Freed page at ");
    console.putInt(addr);
    console.puts("\n");
    delay(10000);
}
