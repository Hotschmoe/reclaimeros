const std = @import("std");

// QEMU UART address
const UART_BASE: usize = 0x09000000;

// UART registers
const UART_DR: *volatile u32 = @ptrFromInt(UART_BASE + 0x00);
const UART_FR: *volatile u32 = @ptrFromInt(UART_BASE + 0x18);

fn delay(cycles: usize) void {
    var i: usize = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}

pub fn putchar(c: u8) void {
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
