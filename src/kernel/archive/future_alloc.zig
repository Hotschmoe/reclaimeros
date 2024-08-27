fn allocate_memory(size: usize) ?usize {
    const num_pages = (size + PAGE_SIZE - 1) / PAGE_SIZE;
    var addr: usize = 0;

    for (0..num_pages) |_| {
        const page_addr = alloc_page();
        if (page_addr == std.math.maxInt(usize)) {
            // Allocation failed, free any pages we've already allocated
            if (addr != 0) {
                free_memory(addr, size);
            }
            return null;
        }
        if (addr == 0) {
            addr = page_addr;
        }
    }

    return addr;
}

fn map_pages(virt_addr: usize, num_pages: usize) bool {
    for (0..num_pages) |i| {
        const phys_addr = alloc_page();
        if (phys_addr == std.math.maxInt(usize)) {
            // Allocation failed, unmap any pages we've already mapped
            unmap_pages(virt_addr, i);
            return false;
        }
        map_page(virt_addr + i * PAGE_SIZE, phys_addr);
    }
    return true;
}

fn expand_heap(num_pages: usize) bool {
    var i: usize = 0;
    while (i < num_pages) : (i += 1) {
        const page_addr = alloc_page();
        if (page_addr == std.math.maxInt(usize)) {
            // Allocation failed, return false
            return false;
        }
        // Add the new page to the heap
        add_to_heap(page_addr);
    }
    return true;
}

fn handle_page_fault(addr: usize) void {
    const page_addr = alloc_page();
    if (page_addr == std.math.maxInt(usize)) {
        // Allocation failed, trigger an out-of-memory error
        panic("Out of memory in page fault handler");
    }
    map_page(addr & ~(PAGE_SIZE - 1), page_addr);
}
