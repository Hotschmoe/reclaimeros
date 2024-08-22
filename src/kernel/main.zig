const console = @import("console.zig");
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
    console.puts("Init done\n");
    delay(100000);

    console.puts("Before allocation\n");
    delay(100000);

    const addr = memory.alloc_page();

    console.puts("After allocation\n");
    delay(100000);

    console.puts("Allocated address: ");
    console.putInt(addr);
    console.puts("\n");
    delay(100000);

    console.puts("End of main\n");
    delay(100000);

    while (true) {
        console.puts("Heartbeat\n");
        delay(1000000);
    }
}
