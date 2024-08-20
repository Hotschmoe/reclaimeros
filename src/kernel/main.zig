const std = @import("std");

// UART memory-mapped I/O address for QEMU virt machine
const UART0: usize = 0x09000000;

// Function to write a string to UART
fn uart_puts(s: []const u8) void {
    for (s) |c| {
        @as(*volatile u8, @ptrFromInt(UART0)).* = c;
    }
}

// Define kmain function
fn kmain() void {
    uart_puts("Hello from ReclaimerOS!\n");
    uart_puts("Kernel initialization complete.\n");
}

export fn _start() noreturn {
    // Set up the stack pointer
    asm volatile (
        \\ ldr x30, =stack_top
        \\ mov sp, x30
    );

    // Call the main kernel function
    kmain();

    // Halt the CPU
    while (true) {
        asm volatile ("wfi");
    }
}

// Define a stack for the kernel
export var stack_bottom: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
export const stack_top = &stack_bottom[stack_bottom.len - 1];
