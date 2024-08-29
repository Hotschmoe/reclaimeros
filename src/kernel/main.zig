const console = @import("console.zig");
const memory = @import("memory.zig");
const exceptions = @import("exceptions.zig");
const tests = @import("tests.zig");
const utilities = @import("utilities.zig");
const shell = @import("shell.zig");

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

export fn kmain() void {
    console.puts("Starting kernel initialization...\n");

    // 1. Initialize early console output (if not already done)
    // This is usually done before kmain() is called, but ensure it's ready

    // 2. Initialize memory management system
    memory.page_allocator = memory.PageAllocator.init();
    console.puts("Memory management system initialized.\n");

    // 3. Initialize exception handling
    exceptions.init_exceptions();
    console.puts("Exception handling initialized.\n");

    // 4. Initialize other hardware components (if any)
    // For example: timer, interrupt controller, etc.

    // 5. Initialize the shell
    shell.shell_prompt();

    // 6. Enter the main kernel loop
    while (true) {
        const c = console.getchar();
        shell.shell_input(c);
    }
}
