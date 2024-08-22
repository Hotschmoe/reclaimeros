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
    console.puts("\nInit end\n");
}

fn delay(cycles: usize) void {
    var i: usize = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}

pub fn alloc_page() ?usize {
    console.puts("Alloc start\n");
    delay(10000);

    console.puts("BITMAP_SIZE: ");
    console.putInt(BITMAP_SIZE);
    console.puts("\n");
    delay(10000);

    for (page_bitmap, 0..) |byte, byte_index| {
        console.puts("Checking byte ");
        console.putInt(byte_index);
        console.puts(": ");
        console.putInt(@as(usize, byte));
        console.puts("\n");
        delay(10000);

        if (byte != 0xFF) {
            console.puts("Found non-full byte\n");
            delay(10000);

            const bit_index = @ctz(~@as(u8, byte));
            console.puts("Free bit at index: ");
            console.putInt(bit_index);
            console.puts("\n");
            delay(10000);

            page_bitmap[byte_index] |= (@as(u8, 1) << @intCast(bit_index));
            const addr = (byte_index * 8 + bit_index) * PAGE_SIZE;

            console.puts("Allocated at ");
            console.putInt(addr);
            console.puts("\n");
            delay(10000);

            return addr;
        }

        if (byte_index % 100 == 99) {
            console.puts("Checked 100 bytes\n");
            delay(10000);
        }
    }

    console.puts("Alloc failed\n");
    delay(10000);
    return null;
}
