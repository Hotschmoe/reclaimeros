const console = @import("console.zig");

pub const PAGE_SIZE: usize = 4096;

pub fn init_memory() void {
    console.puts("Minimal memory init\n");
}

pub fn alloc_page() usize {
    const addr: usize = 0x41000000; // Just return a fixed address
    console.puts("Allocated fixed address: ");
    console.putInt(addr);
    console.puts("\n");
    return addr;
}

pub fn free_page(addr: usize) void {
    console.puts("Free page called for ");
    console.putInt(addr);
    console.puts(" (not implemented)\n");
}
