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

export fn kmain() noreturn {
    console.puts("Start\n");

    memory.init_memory();
    console.puts("Memory init done\n");

    exceptions.init_exceptions();
    console.puts("Exceptions init done\n");

    shell.shell_prompt();

    while (true) {
        const c = console.getchar();
        shell.shell_input(c);
    }

    // while (true) {
    //     console.puts("Heartbeat\n");
    //     utilities.delay(100000000);
    // }
}
