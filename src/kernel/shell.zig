const console = @import("console.zig");
const tests = @import("tests.zig");
const utilities = @import("utilities.zig");
const memory = @import("memory.zig");

const MAX_CMD_LENGTH: usize = 64;
var cmd_buffer: [MAX_CMD_LENGTH]u8 = undefined;
var cmd_index: usize = 0;

pub fn display_prompt() void {
    console.puts("kernel> ");
}

pub fn shell_prompt() void {
    console.puts("\n");
    console.puts("______ _____ _____  _       ___  ________  ___ ___________   \n");
    console.puts("| ___ \\  ___/  __ \\| |     / _ \\|_   _|  \\/  ||  ___| ___ \\  \n");
    console.puts("| |_/ / |__ | /  \\/| |    / /_\\ \\ | | | .  . || |__ | |_/ /  \n");
    console.puts("|    /|  __|| |    | |    |  _  | | | | |\\/| ||  __||    /   \n");
    console.puts("| |\\ \\| |___| \\__/\\| |____| | | |_| |_| |  | || |___| |\\ \\   \n");
    console.puts("\\_| \\_\\____/ \\____/\\_____/\\_| |_/\\___/\\_|  |_/\\____/\\_| \\_|  \n");
    console.puts("\n");
    console.puts("Welcome, Reclaimer. The fate of humanity rests in your hands.\n");
    console.puts("May the wisdom of the Forerunners guide your commands.\n");
    console.puts("\n");
    display_prompt();
}

pub fn process_command() void {
    const cmd = cmd_buffer[0..cmd_index];

    if (str_eq(cmd, "help")) {
        console.puts("Available commands:\n");
        console.puts("  help          - Display this help message\n");
        console.puts("  reboot        - Reboot the system\n");
        console.puts("  meminfo       - Display memory usage information\n");
        console.puts("  uptime        - Show system uptime\n");
        console.puts("  echo          - Echo the following text\n");
        console.puts("  version       - Display kernel version\n");
        console.puts("  memtest       - Run verbose memory test\n");
        console.puts("  memtest_hard  - Run strenuous memory test\n");
        console.puts("  shutdown      - Exit and shutdown the system\n");
    } else if (str_eq(cmd, "reboot")) {
        console.puts("Rebooting...\n");
        reboot();
        // } else if (str_eq(cmd, "meminfo")) {
        //     display_meminfo();
    } else if (str_eq(cmd, "uptime")) {
        display_uptime();
    } else if (str_starts_with(cmd, "echo ")) {
        console.puts(cmd[5..]);
        console.puts("\n");
    } else if (str_eq(cmd, "version")) {
        console.puts("RECLAIMER Kernel v0.1\n");
        console.puts("Built with Zig 0.13 for aarch64\n");
        // } else if (str_eq(cmd, "memtest")) {
        //     tests.test_memory();
        // } else if (str_eq(cmd, "memtest_hard")) {
        //     tests.test_memory_hard();
    } else if (str_eq(cmd, "shutdown")) {
        console.puts("Shutting down...\n");
        shutdown();
    } else {
        console.puts("Unknown command. Type 'help' for available commands.\n");
    }

    cmd_index = 0;
}

pub fn str_eq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..) |char, i| {
        if (char != b[i]) return false;
    }
    return true;
}

pub fn str_starts_with(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    return str_eq(s[0..prefix.len], prefix);
}

// pub fn display_meminfo() void {
//     console.puts("Gathering memory information...\n");
//     const free_pages = memory.get_free_page_count();
//     const total_pages = memory.TOTAL_PAGES;
//     const used_pages = total_pages - free_pages;

//     console.puts("Memory Information:\n");
//     console.puts("  Total memory: ");
//     console.putInt(total_pages * memory.PAGE_SIZE / 1024 / 1024);
//     console.puts(" MB\n");
//     console.puts("  Total pages: ");
//     console.putInt(total_pages);
//     console.puts("\n  Used pages:  ");
//     console.putInt(used_pages);
//     console.puts(" (");
//     console.putInt((used_pages * 100) / total_pages);
//     console.puts("%)\n");
//     console.puts("  Free pages:  ");
//     console.putInt(free_pages);
//     console.puts(" (");
//     console.putInt((free_pages * 100) / total_pages);
//     console.puts("%)\n");
// }

var boot_time: u64 = undefined;

pub fn init_uptime() void {
    boot_time = get_system_time();
}

pub fn display_uptime() void {
    const current_time = get_system_time();
    const uptime = current_time - boot_time;

    // Convert to seconds, considering the timer frequency
    const timer_freq: u64 = asm ("mrs %[freq], cntfrq_el0"
        : [freq] "=r" (-> u64),
    );
    const uptime_seconds = uptime / timer_freq;

    console.puts("System uptime: ");
    console.putInt(uptime_seconds);
    console.puts(" seconds\n");
}

pub fn get_system_time() u64 {
    var time: u64 = undefined;
    asm volatile ("mrs %[time], cntpct_el0"
        : [time] "=r" (time),
    );
    return time;
}

pub fn shell_input(c: u8) void {
    switch (c) {
        '\r', '\n' => {
            console.putchar('\n');
            if (cmd_index > 0) {
                process_command();
            }
            display_prompt();
        },
        8, 127 => { // Backspace and Delete
            if (cmd_index > 0) {
                cmd_index -= 1;
                console.puts("\x08 \x08"); // Move cursor back, print space, move cursor back again
            }
        },
        else => {
            if (cmd_index < MAX_CMD_LENGTH - 1) {
                cmd_buffer[cmd_index] = c;
                cmd_index += 1;
                console.putchar(c);
            }
        },
    }
}

pub fn reboot() noreturn {
    console.puts("Rebooting system...\n");
    utilities.delay(1000000); // Wait a bit before rebooting

    // Use the Power State Coordination Interface (PSCI) to reboot
    asm volatile (
        \\mov x0, #0x84000000
        \\add x0, x0, #0x9 // PSCI_SYSTEM_RESET (0x84000009)
        \\hvc #0
    );

    unreachable;
}

pub fn shutdown() noreturn {
    console.puts("Shutting down system...\n");
    utilities.delay(1000000); // Wait a bit before shutting down

    // Use the Power State Coordination Interface (PSCI) to shutdown
    asm volatile (
        \\mov x0, #0x84000000
        \\add x0, x0, #0x8 // PSCI_SYSTEM_OFF (0x84000008)
        \\hvc #0
    );

    unreachable;
}

var kernel_stack: [16 * 1024]u8 align(16) = undefined;
export var stack_top: *u8 = &kernel_stack[kernel_stack.len - 1];
