const console = @import("console.zig");
const std = @import("std");
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

export fn kmain() noreturn {
    console.puts("Hello world!\n");
    console.puts("Checkpoint 1: Before memory initialization\n");
    memory.init_memory();
    console.puts("Checkpoint 2: After memory initialization\n");

    console.puts("Total memory: ");
    memory.putInt(memory.TOTAL_MEMORY);
    console.puts(" bytes\n");
    console.puts("Page size: ");
    memory.putInt(memory.PAGE_SIZE);
    console.puts(" bytes\n");
    console.puts("Total pages: ");
    memory.putInt(memory.TOTAL_PAGES);
    console.puts("\n");

    console.puts("Checkpoint 3: Before first page allocation\n");
    const page1 = memory.alloc_page() orelse {
        console.puts("Failed to allocate page 1\n");
        @panic("Out of memory");
    };
    console.puts("Checkpoint 4: After first page allocation\n");

    console.puts("Checkpoint 5: Before second page allocation\n");
    const page2 = memory.alloc_page() orelse {
        console.puts("Failed to allocate page 2\n");
        memory.free_page(page1);
        @panic("Out of memory");
    };
    console.puts("Checkpoint 6: After second page allocation\n");

    memory.debug_print_bitmap();

    console.puts("Checkpoint 7: Before freeing pages\n");
    memory.free_page(page1);
    memory.free_page(page2);
    console.puts("Checkpoint 8: After freeing pages\n");

    memory.debug_print_bitmap();

    console.puts("Checkpoint 9: Before final allocation\n");
    const page3 = memory.alloc_page() orelse {
        console.puts("Failed to allocate page 3\n");
        @panic("Out of memory");
    };
    console.puts("Checkpoint 10: After final allocation\n");

    memory.free_page(page3);

    console.puts("Final allocated pages: ");
    memory.putInt(memory.get_allocated_pages_count());
    console.puts("\n");

    memory.debug_print_bitmap();

    console.puts("Memory allocation test completed successfully!\n");

    while (true) {}
}
