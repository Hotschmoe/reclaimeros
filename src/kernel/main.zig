const UART0: usize = 0x09000000;

fn uart_put(c: u8) void {
    @as(*volatile u8, @ptrFromInt(UART0)).* = c;
}

fn uart_print(s: []const u8) void {
    for (s) |c| {
        uart_put(c);
    }
}

fn uart_print_hex(n: usize) void {
    const hex_chars = "0123456789ABCDEF";
    var i: u6 = 60;
    while (true) : (i -%= 4) {
        uart_put(hex_chars[@as(u4, @truncate((n >> i) & 0xF))]);
        if (i == 0) break;
    }
}

export fn _start() linksection(".text._start") noreturn {
    uart_print("Kernel starting at address: 0x");
    uart_print_hex(@intFromPtr(&_start));
    uart_print("\n");

    uart_print("UART address: 0x");
    uart_print_hex(UART0);
    uart_print("\n");

    while (true) {
        uart_put('.');
        var i: usize = 0;
        while (i < 10000000) : (i += 1) {
            asm volatile ("nop");
        }
    }
}
