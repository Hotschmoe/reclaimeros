#include <stdint.h>
#include <stdbool.h>

// Memory constants
#define PHYSICAL_MEMORY_SIZE (128ULL * 1024 * 1024)  // 128 MB
#define PAGE_SIZE 4096                               // 4 KB pages
#define NUM_PHYSICAL_PAGES (PHYSICAL_MEMORY_SIZE / PAGE_SIZE)
#define KERNEL_VIRTUAL_BASE 0xFFFF000000000000ULL    // High memory for kernel space
#define USER_VIRTUAL_BASE 0x0000000000000000ULL      // Low memory for user space
#define VIRTUAL_MEMORY_SIZE (1ULL << 48)             // 256 TB (48-bit address space)
#define NUM_VIRTUAL_PAGES (VIRTUAL_MEMORY_SIZE / PAGE_SIZE)

// Page table levels
#define PAGE_LEVELS 4
#define ENTRIES_PER_PAGE 512

// Page flags
#define PAGE_PRESENT  (1ULL << 0)
#define PAGE_WRITABLE (1ULL << 1)
#define PAGE_USER     (1ULL << 2)
#define PAGE_ACCESSED (1ULL << 8)
#define PAGE_DIRTY    (1ULL << 9)

// Memory regions
typedef enum {
    MEMORY_REGION_KERNEL,
    MEMORY_REGION_USER,
    MEMORY_REGION_DEVICE
} MemoryRegion;

// Page table entry
typedef uint64_t pte_t;

// Page table
typedef struct {
    pte_t entries[ENTRIES_PER_PAGE];
} PageTable;

// Memory block for allocation
typedef struct MemoryBlock {
    struct MemoryBlock* next;
    size_t size;
    bool is_free;
} MemoryBlock;

// Global variables
static uint8_t physical_page_bitmap[NUM_PHYSICAL_PAGES / 8];
static PageTable* kernel_page_table;
static uintptr_t physical_memory_start;
static MemoryBlock* free_list;

// Function prototypes
void memory_init(uintptr_t start_address);
void* kmalloc(size_t size);
void kfree(void* ptr);
void* vmalloc(size_t size, MemoryRegion region);
void vfree(void* ptr);
static void* allocate_pages(size_t num_pages);
static void free_pages(void* ptr, size_t num_pages);
static int find_free_pages(int num_pages);
static void mark_pages(int start_page, int num_pages, bool is_free);
static uintptr_t virtual_to_physical(uintptr_t virtual_addr);
static void map_page(uintptr_t virtual_addr, uintptr_t physical_addr, uint64_t flags);
static void unmap_page(uintptr_t virtual_addr);
static PageTable* create_page_table();

// Initialize memory management
void memory_init(uintptr_t start_address) {
    physical_memory_start = start_address;
    
    // Initialize physical page bitmap: all pages are free
    for (int i = 0; i < NUM_PHYSICAL_PAGES / 8; i++) {
        physical_page_bitmap[i] = 0xFF;
    }
    
    // Mark the pages used by the kernel as occupied
    // Assuming the kernel uses the first 16MB of physical memory
    int kernel_pages = (16 * 1024 * 1024) / PAGE_SIZE;
    mark_pages(0, kernel_pages, false);
    
    // Create initial kernel page table
    kernel_page_table = create_page_table();
    
    // Identity map the first 1GB of physical memory for kernel
    for (uintptr_t addr = 0; addr < (1ULL << 30); addr += PAGE_SIZE) {
        map_page(KERNEL_VIRTUAL_BASE + addr, addr, PAGE_PRESENT | PAGE_WRITABLE);
    }
    
    // Initialize free list for kernel heap
    free_list = (MemoryBlock*)allocate_pages(1);
    free_list->next = NULL;
    free_list->size = PAGE_SIZE - sizeof(MemoryBlock);
    free_list->is_free = true;
}

// Kernel memory allocation
void* kmalloc(size_t size) {
    size_t total_size = size + sizeof(MemoryBlock);
    MemoryBlock* current = free_list;
    MemoryBlock* prev = NULL;
    
    while (current != NULL) {
        if (current->is_free && current->size >= total_size) {
            if (current->size > total_size + sizeof(MemoryBlock)) {
                // Split the block
                MemoryBlock* new_block = (MemoryBlock*)((char*)current + total_size);
                new_block->next = current->next;
                new_block->size = current->size - total_size;
                new_block->is_free = true;
                
                current->next = new_block;
                current->size = total_size;
            }
            
            current->is_free = false;
            return (void*)((char*)current + sizeof(MemoryBlock));
        }
        
        prev = current;
        current = current->next;
    }
    
    // No suitable block found, allocate new pages
    size_t pages_needed = (total_size + PAGE_SIZE - 1) / PAGE_SIZE;
    MemoryBlock* new_block = (MemoryBlock*)allocate_pages(pages_needed);
    
    if (new_block == NULL) {
        return NULL;  // Out of memory
    }
    
    new_block->next = free_list;
    new_block->size = pages_needed * PAGE_SIZE - sizeof(MemoryBlock);
    new_block->is_free = false;
    
    free_list = new_block;
    
    return (void*)((char*)new_block + sizeof(MemoryBlock));
}

// Kernel memory deallocation
void kfree(void* ptr) {
    if (ptr == NULL) {
        return;
    }
    
    MemoryBlock* block = (MemoryBlock*)((char*)ptr - sizeof(MemoryBlock));
    block->is_free = true;
    
    // Coalesce free blocks
    MemoryBlock* current = free_list;
    while (current != NULL && current->next != NULL) {
        if (current->is_free && current->next->is_free) {
            current->size += current->next->size + sizeof(MemoryBlock);
            current->next = current->next->next;
        } else {
            current = current->next;
        }
    }
}

// Virtual memory allocation
void* vmalloc(size_t size, MemoryRegion region) {
    size_t pages_needed = (size + PAGE_SIZE - 1) / PAGE_SIZE;
    uintptr_t virtual_base = (region == MEMORY_REGION_KERNEL) ? KERNEL_VIRTUAL_BASE : USER_VIRTUAL_BASE;
    
    // Find contiguous virtual address space
    uintptr_t virtual_addr = virtual_base;
    size_t contiguous_pages = 0;
    
    while (virtual_addr < VIRTUAL_MEMORY_SIZE) {
        if (virtual_to_physical(virtual_addr) == 0) {
            contiguous_pages++;
            if (contiguous_pages == pages_needed) {
                break;
            }
        } else {
            contiguous_pages = 0;
        }
        virtual_addr += PAGE_SIZE;
    }
    
    if (contiguous_pages < pages_needed) {
        return NULL;  // No contiguous virtual address space available
    }
    
    virtual_addr -= (pages_needed - 1) * PAGE_SIZE;
    
    // Allocate physical pages and map them
    for (size_t i = 0; i < pages_needed; i++) {
        uintptr_t physical_addr = (uintptr_t)allocate_pages(1);
        if (physical_addr == 0) {
            // Failed to allocate physical memory, clean up and return NULL
            for (size_t j = 0; j < i; j++) {
                unmap_page(virtual_addr + j * PAGE_SIZE);
            }
            return NULL;
        }
        
        uint64_t flags = PAGE_PRESENT | PAGE_WRITABLE;
        if (region == MEMORY_REGION_USER) {
            flags |= PAGE_USER;
        }
        
        map_page(virtual_addr + i * PAGE_SIZE, physical_addr, flags);
    }
    
    return (void*)virtual_addr;
}

// Virtual memory deallocation
void vfree(void* ptr) {
    if (ptr == NULL) {
        return;
    }
    
    uintptr_t virtual_addr = (uintptr_t)ptr;
    
    // Find the end of the allocation
    while (virtual_to_physical(virtual_addr) != 0) {
        uintptr_t physical_addr = virtual_to_physical(virtual_addr);
        unmap_page(virtual_addr);
        free_pages((void*)physical_addr, 1);
        virtual_addr += PAGE_SIZE;
    }
}

// Allocate physical pages
static void* allocate_pages(size_t num_pages) {
    int start_page = find_free_pages(num_pages);
    
    if (start_page == -1) {
        return NULL;  // Out of memory
    }
    
    mark_pages(start_page, num_pages, false);
    
    return (void*)(physical_memory_start + (start_page * PAGE_SIZE));
}

// Free physical pages
static void free_pages(void* ptr, size_t num_pages) {
    uintptr_t addr = (uintptr_t)ptr;
    int page = (addr - physical_memory_start) / PAGE_SIZE;
    
    mark_pages(page, num_pages, true);
}

// Find a contiguous block of free physical pages
static int find_free_pages(int num_pages) {
    int start = -1;
    int count = 0;
    
    for (int i = 0; i < NUM_PHYSICAL_PAGES; i++) {
        if (physical_page_bitmap[i / 8] & (1 << (i % 8))) {
            if (start == -1) {
                start = i;
            }
            count++;
            if (count == num_pages) {
                return start;
            }
        } else {
            start = -1;
            count = 0;
        }
    }
    
    return -1;  // Not enough contiguous free pages
}

// Mark physical pages as free or occupied
static void mark_pages(int start_page, int num_pages, bool is_free) {
    for (int i = start_page; i < start_page + num_pages; i++) {
        if (is_free) {
            physical_page_bitmap[i / 8] |= (1 << (i % 8));
        } else {
            physical_page_bitmap[i / 8] &= ~(1 << (i % 8));
        }
    }
}

// Convert virtual address to physical address
static uintptr_t virtual_to_physical(uintptr_t virtual_addr) {
    PageTable* table = kernel_page_table;
    
    for (int level = PAGE_LEVELS - 1; level > 0; level--) {
        int index = (virtual_addr >> (12 + 9 * level)) & 0x1FF;
        pte_t pte = table->entries[index];
        
        if (!(pte & PAGE_PRESENT)) {
            return 0;  // Page not present
        }
        
        table = (PageTable*)(pte & ~0xFFF);
    }
    
    int index = (virtual_addr >> 12) & 0x1FF;
    pte_t pte = table->entries[index];
    
    if (!(pte & PAGE_PRESENT)) {
        return 0;  // Page not present
    }
    
    return (pte & ~0xFFF) | (virtual_addr & 0xFFF);
}

// Map a virtual page to a physical page
static void map_page(uintptr_t virtual_addr, uintptr_t physical_addr, uint64_t flags) {
    PageTable* table = kernel_page_table;
    
    for (int level = PAGE_LEVELS - 1; level > 0; level--) {
        int index = (virtual_addr >> (12 + 9 * level)) & 0x1FF;
        pte_t* pte = &table->entries[index];
        
        if (!(*pte & PAGE_PRESENT)) {
            PageTable* new_table = create_page_table();
            *pte = (pte_t)new_table | PAGE_PRESENT | PAGE_WRITABLE;
            if (flags & PAGE_USER) {
                *pte |= PAGE_USER;
            }
        }
        
        table = (PageTable*)(*pte & ~0xFFF);
    }
    
    int index = (virtual_addr >> 12) & 0x1FF;
    table->entries[index] = physical_addr | flags;
}

// Unmap a virtual page
static void unmap_page(uintptr_t virtual_addr) {
    PageTable* table = kernel_page_table;
    
    for (int level = PAGE_LEVELS - 1; level > 0; level--) {
        int index = (virtual_addr >> (12 + 9 * level)) & 0x1FF;
        pte_t pte = table->entries[index];
        
        if (!(pte & PAGE_PRESENT)) {
            return;  // Page not present, nothing to unmap
        }
        
        table = (PageTable*)(pte & ~0xFFF);
    }
    
    int index = (virtual_addr >> 12) & 0x1FF;
    table->entries[index] = 0;  // Clear the page table entry
}

// Create a new page table
static PageTable* create_page_table() {
    PageTable* table = (PageTable*)allocate_pages(1);
    if (table == NULL) {
        return NULL;  // Out of memory
    }
    
    for (int i = 0; i < ENTRIES_PER_PAGE; i++) {
        table->entries[i] = 0;
    }
    
    return table;
}