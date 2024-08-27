const std = @import("std");
const console = @import("console.zig");
const memory = @import("memory.zig");

pub fn test_memory() void {
    console.puts("Initial free pages: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");

    _ = memory.alloc_page();
    console.puts("Free pages after first allocation: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");

    const addr2 = memory.alloc_page();
    console.puts("Free pages after second allocation: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");

    _ = memory.alloc_page();
    console.puts("Free pages after third allocation: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");

    memory.free_page(addr2);
    console.puts("Free pages after freeing second page: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");

    // Try to free an invalid address
    memory.free_page(0x12345678);

    // Try a double free
    memory.free_page(addr2);

    console.puts("Final free page count: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");
}
