const std = @import("std");

// QEMU UART address
const UART_BASE: usize = 0x09000000;

// UART registers
const UART_DR: *volatile u32 = @ptrFromInt(UART_BASE + 0x00);

pub fn putchar(c: u8) void {
    UART_DR.* = c;
}

pub fn puts(s: []const u8) void {
    for (s) |c| {
        putchar(c);
    }
}

pub fn printf(comptime fmt: []const u8, args: anytype) void {
    var buf: [100]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt, args) catch {
        puts("Error: printf buffer overflow\n");
        return;
    };
    puts(slice);
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
