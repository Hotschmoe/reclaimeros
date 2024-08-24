// We are going to be using a monolithic kernel structure for now
// This will aid in debugging and development using LLM assistance
// We will be using Zig for the kernel
// We will be using QEMU for the emulator
// We will be using aarch64 for the architecture
// We will attempt to keep components in sections with a ----- HEADER -----
// We will attempt to keep the code as readable as possible by using few comments and keeping function names as descriptive as possible
// ---------- KERNEL ----------

const std = @import("std");

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
    puts("Kernel starting\n");

    init_memory();
    init_exceptions();

    puts("Kernel initialization complete\n");
    puts("Starting shell...\n");

    shell_prompt();

    while (true) {
        const c = getchar();
        shell_input(c);
    }
}

// ---------- CONSOLE ----------

pub const UART_BASE: usize = 0x09000000;

const UART_DR: *volatile u32 = @ptrFromInt(UART_BASE + 0x00);
const UART_FR: *volatile u32 = @ptrFromInt(UART_BASE + 0x18);

fn putchar(c: u8) void {
    while ((UART_FR.* & (1 << 5)) != 0) {
        delay(100);
    }
    UART_DR.* = c;
    delay(1000);
}

pub fn puts(s: []const u8) void {
    for (s) |c| {
        putchar(c);
    }
}

pub fn putInt(value: usize) void {
    if (value == 0) {
        putchar('0');
        return;
    }

    var buf: [20]u8 = undefined;
    var i: usize = 0;
    var v = value;

    while (v > 0) : (v /= 10) {
        buf[19 - i] = @intCast((v % 10) + '0');
        i += 1;
    }

    puts(buf[20 - i ..]);
}

pub fn putIntHex(value: usize) void {
    const hex_digits = "0123456789ABCDEF";
    var temp: [16]u8 = undefined; // Buffer to store the hex representation
    var i: usize = 0;

    // Convert the integer to a hexadecimal string
    var val = value;
    while (val > 0) {
        temp[i] = hex_digits[val & 0xF];
        val >>= 4;
        i += 1;
    }

    if (i == 0) {
        // Special case for value == 0
        puts("0");
        return;
    }

    // Print the hex string in reverse order
    while (i > 0) {
        i -= 1;
        putchar(temp[i]);
    }
}

fn getchar() u8 {
    while ((UART_FR.* & (1 << 4)) != 0) {
        delay(100);
    }
    return @truncate(UART_DR.*);
}

// ---------- MEMORY ----------

pub const PAGE_SIZE: usize = 4096;
pub const TOTAL_PAGES: usize = 1024; // 4MB of manageable memory
pub const MEMORY_START: usize = 0x41000000; // Start of manageable memory

var page_bitmap: [TOTAL_PAGES]bool = undefined;

pub fn init_memory() void {
    puts("Initializing memory management system\n");
    _ = memset(@ptrCast(&page_bitmap), 0, TOTAL_PAGES);
    puts("Memory initialization complete\n");
}

pub fn memset(dest: [*]u8, c: u8, n: usize) [*]u8 {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        dest[i] = c;
    }
    return dest;
}

pub fn alloc_page() ?usize {
    var i: usize = 0;
    while (i < page_bitmap.len) : (i += 1) {
        if (!page_bitmap[i]) {
            page_bitmap[i] = true;
            return MEMORY_START + (i * PAGE_SIZE);
        }
    }
    return null; // Out of memory
}

pub fn free_page(addr: usize) void {
    if (addr < MEMORY_START or addr >= MEMORY_START + (TOTAL_PAGES * PAGE_SIZE)) {
        @panic("Invalid free address");
    }

    const page_index = (addr - MEMORY_START) / PAGE_SIZE;
    if (!page_bitmap[page_index]) {
        return;
    }

    page_bitmap[page_index] = false;
}

pub fn get_free_page_count() usize {
    var count: usize = 0;
    for (page_bitmap) |is_allocated| {
        if (!is_allocated) {
            count += 1;
        }
    }
    return count;
}

// ---------- EXCEPTIONS ----------

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
    puts("Synchronous exception occurred\n");
    while (true) {}
}

export fn handle_irq() callconv(.C) void {
    puts("IRQ occurred\n");
    while (true) {}
}

export fn handle_fiq() callconv(.C) void {
    puts("FIQ occurred\n");
    while (true) {}
}

export fn handle_serror() callconv(.C) void {
    puts("SError occurred\n");
    while (true) {}
}

pub fn init_exceptions() void {
    asm volatile (
        \\adr x0, exception_vector_table
        \\msr vbar_el1, x0
        \\
        \\ // Enable interrupts
        \\msr daifclr, #2
    );
    puts("Exception handlers initialized and interrupts enabled\n");
}

// ---------- SHELL ----------

const MAX_CMD_LENGTH: usize = 64;
var cmd_buffer: [MAX_CMD_LENGTH]u8 = undefined;
var cmd_index: usize = 0;

fn shell_prompt() void {
    puts("kernel> ");
}

fn process_command() void {
    const cmd = cmd_buffer[0..cmd_index];

    if (str_eq(cmd, "help")) {
        puts("Available commands:\n");
        puts("  help   - Display this help message\n");
        puts("  reboot - Reboot the system\n");
    } else if (str_eq(cmd, "reboot")) {
        puts("Rebooting...\n");
        reboot();
    } else {
        puts("Unknown command. Type 'help' for available commands.\n");
    }

    cmd_index = 0;
}

fn str_eq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..) |char, i| {
        if (char != b[i]) return false;
    }
    return true;
}

fn shell_input(c: u8) void {
    switch (c) {
        '\r', '\n' => {
            putchar('\n');
            if (cmd_index > 0) {
                process_command();
            }
            shell_prompt();
        },
        8, 127 => { // Backspace and Delete
            if (cmd_index > 0) {
                cmd_index -= 1;
                puts("\x08 \x08"); // Move cursor back, print space, move cursor back again
            }
        },
        else => {
            if (cmd_index < MAX_CMD_LENGTH - 1) {
                cmd_buffer[cmd_index] = c;
                cmd_index += 1;
                putchar(c);
            }
        },
    }
}

fn reboot() noreturn {
    puts("Rebooting system...\n");
    delay(1000000); // Wait a bit before rebooting

    // Use the Power State Coordination Interface (PSCI) to reboot
    asm volatile (
        \\mov x0, #0x84000000
        \\add x0, x0, #0x9 // PSCI_SYSTEM_RESET (0x84000009)
        \\hvc #0
    );

    unreachable;
}

var kernel_stack: [16 * 1024]u8 align(16) = undefined;
export var stack_top: *u8 = &kernel_stack[kernel_stack.len - 1];
