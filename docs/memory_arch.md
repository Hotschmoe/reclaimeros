# Memory Management in Container-Oriented Kernel

## Overview

This kernel implements a sophisticated memory management system designed for a container orchestration system at the kernel level. The system is optimized to support diverse container types, including system functions as containers and native user-space containers such as Linux and Android runtimes.

## Key Features

1. **Hybrid Allocator**: Combines multiple allocation strategies for optimal performance across various memory requirements.
   - Buddy Allocator: Efficiently handles diverse allocation sizes.
   - Slab Allocator: Optimizes small, frequent allocations.
   - Huge Page Allocator: Manages large memory blocks efficiently.

2. **Advanced Bitmap Structure**: 
   - Flat Bitset: For efficient management of normal-sized pages.
   - Hierarchical Bitmap: For quick identification and allocation of huge pages.

3. **Memory Ballooning**: Allows dynamic adjustment of memory allocation between containers.

4. **NUMA Awareness**: Improves performance on multi-processor systems.

5. **Memory Isolation and Protection**: Ensures security between containers.

## Implementation Highlights

- The core allocation system is based on a Buddy Allocator, supplemented with a Slab Allocator for small allocations and a Huge Page Allocator for large memory blocks.
- A hybrid bitmap structure combines a flat bitset (using Zig's `std.bit_set.IntegerBitSet`) for normal pages and a custom hierarchical bitmap for huge pages.
- The system is designed to be flexible, efficient, and capable of handling the diverse memory requirements of different container types and system functions.

This memory management system provides a solid foundation for our container-oriented kernel, offering the necessary performance and flexibility to support a wide range of containerized applications and system functions.