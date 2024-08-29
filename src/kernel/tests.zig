// const std = @import("std");
// const console = @import("console.zig");
// const memory = @import("memory.zig");

// pub fn test_memory() void {
//     console.puts("Starting memory test...\n");

//     // Ensure memory system is initialized
//     memory.init_memory();

//     console.puts("Initial free pages: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     var allocator = memory.PageAllocator.init();
//     console.puts("PageAllocator initialized\n");

//     // First allocation
//     console.puts("Attempting first allocation (100 bytes)...\n");
//     const alloc1 = allocator.allocate(100) orelse {
//         console.puts("First allocation failed\n");
//         return;
//     };
//     console.puts("First allocation successful. Address: 0x");
//     console.putIntHex(@intFromPtr(alloc1));
//     console.puts("\n");
//     console.puts("Free pages after first allocation: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Second allocation
//     console.puts("Attempting second allocation (5000 bytes)...\n");
//     const alloc2 = allocator.allocate(5000) orelse {
//         console.puts("Second allocation failed\n");
//         allocator.deallocate(alloc1, 100);
//         return;
//     };
//     console.puts("Second allocation successful. Address: 0x");
//     console.putIntHex(@intFromPtr(alloc2));
//     console.puts("\n");
//     console.puts("Free pages after second allocation: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Third allocation
//     console.puts("Attempting third allocation (10000 bytes)...\n");
//     const alloc3 = allocator.allocate(10000) orelse {
//         console.puts("Third allocation failed\n");
//         allocator.deallocate(alloc1, 100);
//         allocator.deallocate(alloc2, 5000);
//         return;
//     };
//     console.puts("Third allocation successful. Address: 0x");
//     console.putIntHex(@intFromPtr(alloc3));
//     console.puts("\n");
//     console.puts("Free pages after third allocation: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Deallocate second allocation
//     console.puts("Deallocating second allocation...\n");
//     allocator.deallocate(alloc2, 5000);
//     console.puts("Free pages after freeing second allocation: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Try to free an invalid address
//     console.puts("Attempting to free an invalid address...\n");
//     allocator.deallocate(@ptrFromInt(0x12345678), 100);

//     // Try a double free
//     console.puts("Attempting a double free...\n");
//     allocator.deallocate(alloc2, 5000);

//     // Clean up remaining allocations
//     console.puts("Cleaning up remaining allocations...\n");
//     allocator.deallocate(alloc1, 100);
//     allocator.deallocate(alloc3, 10000);

//     console.puts("Final free page count: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");
//     console.puts("Memory test completed.\n");
// }

// pub fn test_memory_hard() void {
//     console.puts("Starting strenuous memory test...\n");

//     // Ensure memory system is initialized
//     memory.init_memory();

//     var allocator = memory.PageAllocator.init();
//     console.puts("PageAllocator initialized\n");

//     const initial_free_pages = memory.get_free_page_count();
//     console.puts("Initial free pages: ");
//     console.putInt(initial_free_pages);
//     console.puts("\n");

//     const num_allocations = 100;
//     var allocations: [num_allocations]struct { ptr: ?[*]u8, size: usize } = undefined;

//     // Perform multiple allocations of varying sizes
//     for (0..num_allocations) |i| {
//         const size = (i % 10 + 1) * 1000; // Sizes from 1000 to 10000 bytes
//         console.puts("Attempting allocation ");
//         console.putInt(i);
//         console.puts(" of size ");
//         console.putInt(size);
//         console.puts(" bytes...\n");

//         const ptr = allocator.allocate(size) orelse {
//             console.puts("Allocation failed at index ");
//             console.putInt(i);
//             console.puts("\n");
//             return;
//         };
//         allocations[i] = .{ .ptr = ptr, .size = size };
//         console.puts("Allocation successful. Address: 0x");
//         console.putIntHex(@intFromPtr(ptr));
//         console.puts("\n");
//     }

//     console.puts("All allocations successful\n");
//     console.puts("Free pages after allocations: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Deallocate in a non-sequential order
//     const dealloc_order = [_]usize{ 50, 20, 80, 10, 90, 30, 70, 0, 60, 40 };
//     for (dealloc_order) |index| {
//         const alloc = allocations[index];
//         if (alloc.ptr) |ptr| {
//             allocator.deallocate(ptr, alloc.size);
//             allocations[index].ptr = null;
//         }
//     }

//     console.puts("Partial deallocation complete\n");
//     console.puts("Free pages after partial deallocation: ");
//     console.putInt(memory.get_free_page_count());
//     console.puts("\n");

//     // Attempt to allocate a large chunk
//     if (allocator.allocate(1024 * 1024)) |large_alloc| {
//         console.puts("Unexpected success in large allocation\n");
//         allocator.deallocate(large_alloc, 1024 * 1024);
//     } else {
//         console.puts("Large allocation failed (expected)\n");
//     }

//     // Deallocate remaining allocations
//     for (allocations) |alloc| {
//         if (alloc.ptr) |ptr| {
//             allocator.deallocate(ptr, alloc.size);
//         }
//     }

//     const final_free_pages = memory.get_free_page_count();
//     console.puts("Final free pages: ");
//     console.putInt(final_free_pages);
//     console.puts("\n");

//     if (final_free_pages == initial_free_pages) {
//         console.puts("Memory test passed: All pages freed successfully\n");
//     } else {
//         console.puts("Memory test failed: Page count mismatch\n");
//     }

//     console.puts("Strenuous memory test completed.\n");
// }
