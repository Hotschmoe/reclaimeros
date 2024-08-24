const console = @import("console.zig");

// Exception Vector Table
export fn exception_vector_table() callconv(.Naked) void {
    asm volatile (
        \\.align 11
        \\
        \\ // Current EL with SP0
        \\vector_el1_sp0_sync:
        \\    b handle_sync_exception
        \\.balign 0x80
        \\vector_el1_sp0_irq:
        \\    b handle_irq
        \\.balign 0x80
        \\vector_el1_sp0_fiq:
        \\    b handle_fiq
        \\.balign 0x80
        \\vector_el1_sp0_serror:
        \\    b handle_serror
        \\
        \\ // Current EL with SPx
        \\.balign 0x80
        \\vector_el1_spx_sync:
        \\    b handle_sync_exception
        \\.balign 0x80
        \\vector_el1_spx_irq:
        \\    b handle_irq
        \\.balign 0x80
        \\vector_el1_spx_fiq:
        \\    b handle_fiq
        \\.balign 0x80
        \\vector_el1_spx_serror:
        \\    b handle_serror
        \\
        \\ // Lower EL using AArch64
        \\.balign 0x80
        \\vector_el0_aarch64_sync:
        \\    b handle_sync_exception
        \\.balign 0x80
        \\vector_el0_aarch64_irq:
        \\    b handle_irq
        \\.balign 0x80
        \\vector_el0_aarch64_fiq:
        \\    b handle_fiq
        \\.balign 0x80
        \\vector_el0_aarch64_serror:
        \\    b handle_serror
        \\
        \\ // Lower EL using AArch32
        \\.balign 0x80
        \\vector_el0_aarch32_sync:
        \\    b handle_sync_exception
        \\.balign 0x80
        \\vector_el0_aarch32_irq:
        \\    b handle_irq
        \\.balign 0x80
        \\vector_el0_aarch32_fiq:
        \\    b handle_fiq
        \\.balign 0x80
        \\vector_el0_aarch32_serror:
        \\    b handle_serror
    );
}

export fn handle_sync_exception() callconv(.C) void {
    console.puts("Synchronous exception occurred\n");
    while (true) {}
}

export fn handle_irq() callconv(.C) void {
    console.puts("IRQ occurred\n");
    while (true) {}
}

export fn handle_fiq() callconv(.C) void {
    console.puts("FIQ occurred\n");
    while (true) {}
}

export fn handle_serror() callconv(.C) void {
    console.puts("SError occurred\n");
    while (true) {}
}

pub fn init_exceptions() void {
    // Set VBAR_EL1 to the address of our exception vector table
    asm volatile (
        \\adr x0, exception_vector_table
        \\msr vbar_el1, x0
    );
    console.puts("Exception handlers initialized\n");
}
