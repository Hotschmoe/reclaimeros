const console = @import("console.zig");
const memory = @import("memory.zig");
const exceptions = @import("exceptions.zig");

comptime {
    asm (
        \\.globl _start
        \\_start:
        \\ldr x30, =stack_top
        \\mov sp, x30
        \\
        \\bl kmain
        \\b .
    );
}

fn delay(cycles: usize) void {
    var i: usize = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}

export fn kmain() noreturn {
    console.puts("Start\n");
    delay(100000);

    memory.init_memory();
    console.puts("Memory init done\n");
    delay(100000);

    exceptions.init_exceptions();
    console.puts("Exceptions init done\n");
    delay(100000);

    console.puts("Initial free pages: ");
    console.putInt(memory.get_free_page_count());
    console.puts("\n");
    delay(100000);

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

    console.puts("End of main\n");
    delay(100000);

    while (true) {
        console.puts("Heartbeat\n");
        delay(100000000);
    }
}
