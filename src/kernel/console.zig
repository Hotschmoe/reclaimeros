const std = @import("std");
const utilities = @import("utilities.zig");
// QEMU UART address
const UART_BASE: usize = 0x09000000;

// UART registers
const UART_DR: *volatile u32 = @ptrFromInt(UART_BASE + 0x00);
const UART_FR: *volatile u32 = @ptrFromInt(UART_BASE + 0x18);

pub fn putchar(c: u8) void {
    while ((UART_FR.* & (1 << 5)) != 0) {
        utilities.delay(100);
    }
    UART_DR.* = c;
    utilities.delay(1000);
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

pub fn getchar() u8 {
    while ((UART_FR.* & (1 << 4)) != 0) {
        utilities.delay(100);
    }
    return @truncate(UART_DR.*);
}
