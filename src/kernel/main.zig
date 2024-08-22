const console = @import("console.zig");
const std = @import("std");
const memory = @import("memory.zig");

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

export fn kmain() noreturn {
    console.puts("Hello world!\n");
    console.puts("Initializing memory...\n"); // Debug print
    memory.init_memory();
    console.puts("Memory initialized\n");

    // Test memory allocation
    const page_addr = memory.alloc_page() orelse {
        // Handle out of memory
        @panic("Out of memory");
    };

    // Use the allocated page...

    // Free the page when done
    memory.free_page(page_addr);

    while (true) {}
}
