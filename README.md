# Reclaimer OS

Reclaimer OS is an innovative, containerized operating system designed for mobile platforms, with a focus on AI integration and modularity. Built primarily in Zig, this project aims to create a next-generation OS that leverages containerization for enhanced security, flexibility, and performance.

## Project Overview

Reclaimer OS combines cutting-edge technologies and concepts:

- **Zig Programming Language**: Primary development language, offering performance and safety.
- **Containerization**: Core architecture for modularity and security.
- **AI Integration**: Built-in Large Language Model (LLM) for advanced OS capabilities.
- **Hardware AI Acceleration**: Designed to leverage AI accelerators in modern mobile chipsets.
- **Android Compatibility**: Initial support for running Android apps in containers.

Why Create a New Kernel in Zig for Container Orchestration?
1. Performance and Efficiency
Low-Level Control: Writing a kernel in Zig provides fine-grained control over hardware and system resources, enabling performance optimization for container orchestration tasks.
Minimalism: This kernel is designed specifically for container orchestration, stripping away unnecessary features found in general-purpose operating systems, resulting in a more lightweight and efficient system.
2. Security
Built-in Safety: Zig offers safety features like bounds checking and null safety, while still allowing low-level control, helping to build a more secure kernel with fewer vulnerabilities.
Isolation: A custom kernel allows for the implementation of advanced security models tailored to containerization, improving isolation between containers and reducing the attack surface.
3. Customizability
Tailored Design: The kernel architecture and container orchestration mechanisms are designed to meet specific needs or support novel features that existing kernels might not efficiently support.
Modular Architecture: The kernel is built with a modular architecture in mind, where each component (e.g., networking, storage) is designed as a container itself, offering extreme flexibility and customization.
4. Modern Language Benefits
Zig’s Simplicity and Power: Zig combines low-level control with modern language features, making it an excellent choice for systems programming. Its simple syntax, lack of hidden control flow, and manual memory management are ideal for kernel development.
Compile-time Guarantees: Zig’s powerful compile-time checks and optimizations reduce runtime errors, improving the reliability of the kernel.
5. Learning and Innovation
Research and Experimentation: Building a kernel from scratch is a valuable learning experience and provides opportunities to experiment with new ideas in systems programming, containerization, and operating system design.
Community Contribution: This project contributes to the open-source community, providing a platform that others can build upon, extend, or learn from.
6. Niche Applications
Specialized Use Cases: The kernel is optimized for container orchestration in resource-constrained environments like IoT devices, edge computing, or specialized data centers.
Mobile and Edge Computing: It is designed to efficiently manage containers on mobile or edge devices, where resources are limited, and existing kernels may not be optimized.
7. Future-Proofing
Modern Hardware Support: The kernel targets modern hardware architectures (e.g., ARM, RISC-V), optimizing for features like AI accelerators, specialized processors, or secure enclaves.
Integration with Modern Technologies: The kernel is designed with native support for emerging technologies, such as AI-driven resource management, real-time analytics, or decentralized networks.

## Key Features

1. **Containerized Architecture**: Every major OS function runs in its own container.
2. **Integrated AI Assistant**: LLM-powered assistant for enhanced user interaction and system management.
3. **Hardware Abstraction Layer (HAL)**: Efficient hardware management, including AI accelerators.
4. **Networking Stack**: Modular networking with support for cellular, Wi-Fi, and Bluetooth.
5. **Android Compatibility Layer**: Run Android apps within the OS (planned feature).
6. **Security-Focused Design**: Leveraging containerization for enhanced system security.

--------------------------------

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

--------------------------------

## Architecture

Reclaimer OS is built on a layered, containerized architecture:

1. **Zig Kernel**: Core OS functionality.
2. **Hardware Abstraction Layer (HAL)**: Manages hardware-specific interactions.
3. **Container Runtime**: Manages and runs containerized components.
4. **Container Orchestrator**: Coordinates different containers.
5. **System Containers**:
   - LLM Container: Integrates AI capabilities.
   - Networking Container: Manages all networking functions.
   - Display Container: Handles graphics and UI.
   - Input Container: Manages user input devices.
   - Application Containers: Run user applications, including potential Android apps.
   - Storage Container: Manages all storage functions. (easy to implement alt filesystems?)

### Container Update Process

Reclaimer OS implements a sophisticated container update mechanism to ensure system stability and minimize downtime:

1. **Parallel Deployment**: When a system container (e.g., networking stack) is updated, the new version is launched alongside the currently running container.

2. **Fallback Mode**: The original container continues to handle all ingress and egress traffic while the new container initializes.

3. **Gradual Transition**: Once ready, the system attempts to switch priority to the new container, placing the original in a fallback state. (maybe do health checks and tests on new container before switching)

4. **Automatic Rollback**: If the new container fails or behaves unexpectedly, the system automatically falls back to the original, ensuring continued functionality.

5. **Health Checks**: (rerun?) The system runs tests to verify the health and proper operation of the new container.

6. **Cleanup**: After successful transition and verification, the original container is safely brought down and destroyed.

This update process allows for seamless, zero-downtime updates with built-in fallback mechanisms, enhancing system reliability and maintainability.

### Prerequisites

- Zig (latest version)
- QEMU

### Building the Kernel

1. Clone the repository:
   ```
   git clone https://github.com/hotschmoe/reclaimer-os.git
   cd reclaimer-os
   ```

2. Build the kernel:
   ```
   zig build
   ```

3. Run the kernel in QEMU:
   ```
   zig build run
   ```

## Development Status

We are currently in the very early stages of development, focusing on:

1. Setting up a basic kernel that can boot and print a message.
2. Establishing the build system and development workflow.

### Development Checklist

To track our progress and guide our development efforts, we've created a comprehensive checklist:

<details>
<summary>Click to expand Development Checklist</summary>

## Reclaimer OS Development Checklist

### 1. Memory Management
- [ ] Implement basic physical memory allocator
  - Create a bitmap-based page allocator
  - Develop functions for page allocation and deallocation
- [ ] Set up paging and virtual memory
  - Initialize page tables
  - Implement virtual-to-physical address mapping functions
- [ ] Develop a basic heap allocator for kernel use
  - Create simple `kmalloc()` and `kfree()` functions

### 2. Process Management
- [ ] Implement basic process structures
  - Define process control block (PCB) structure
  - Create functions for process creation and termination
- [ ] Develop a simple scheduler
  - Implement a basic round-robin scheduling algorithm
  - Set up timer interrupts for preemptive multitasking

### 3. Interrupt Handling
- [ ] Set up Interrupt Descriptor Table (IDT)
- [ ] Implement basic interrupt handlers
  - Keyboard interrupts
  - Timer interrupts
  - System call interrupts

### 4. Device Drivers
- [ ] Develop a simple keyboard driver
  - Implement keyboard input buffering
  - Set up keyboard interrupt handler
- [ ] Create a basic display driver
  - Implement text mode display functions
  - Develop simple graphics mode if desired

### 5. File System
- [ ] Design and implement a simple in-memory file system
  - Create basic file and directory structures
  - Implement functions for file creation, deletion, reading, and writing

### 6. System Calls
- [ ] Define and implement basic system calls
  - Process control (e.g., fork, exec, exit)
  - File operations (e.g., open, close, read, write)
  - Memory management (e.g., brk, sbrk)

### 7. User Space
- [ ] Set up user space and kernel space separation
  - Implement memory protection mechanisms
- [ ] Develop context switching between kernel and user mode
  - Save and restore process state during switches

### 8. Shell
- [ ] Create a basic command-line interface
  - Implement command parsing and execution
  - Develop built-in shell commands

### 9. Networking
- [ ] Implement a simple networking stack
  - Start with loopback interface support
  - Develop basic TCP/IP stack if desired

### 10. Container Runtime
- [ ] Design the container architecture
  - Define container structure and lifecycle
- [ ] Implement basic containerization features
  - Process isolation
  - File system isolation
  - Resource limiting

### 11. Testing and Documentation
- [ ] Develop a test suite for kernel functions
- [ ] Write detailed documentation for all implemented features
- [ ] Create user and developer guides

### 12. Performance Optimization
- [ ] Profile and optimize critical paths in the kernel
- [ ] Implement more advanced memory management techniques
- [ ] Optimize process scheduling algorithm

### 13. Security Features
- [ ] Implement basic security measures
  - Memory protection between processes
  - Access control for system resources
- [ ] Develop a simple capability-based security model if desired

### 14. AI Integration (Long-term goal)
- [ ] Design AI integration architecture
- [ ] Implement basic AI assistant functionality
- [ ] Develop AI-enhanced system management features

</details>

This checklist represents a high-level overview of the development process. Each item may involve multiple sub-tasks and could be expanded into its own detailed checklist as development progresses. We'll update this checklist as we make progress and refine our goals.

## Contributing

We welcome contributions to Reclaimer OS! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contact

[Your contact information or project communication channels]

---

## LLM Context Prompt

For developers using LLMs to assist with this project, use the following prompt to provide context:

```
I am developing Reclaimer OS, a containerized operating system for mobile platforms. Here's a summary of the project:

- Primary language: Zig
- Target architecture: AArch64 (ARM64)
- Development environment: Uses QEMU for emulation
- Architecture: Containerized, with each major OS function in its own container
- Current development stage: Early kernel development
- Build system: Custom Zig build script (build.zig)

Key components (planned or in early development):
1. Zig Kernel: Core OS functionality
2. Hardware Abstraction Layer (HAL)
3. Container Runtime and Orchestrator
4. LLM-based AI Assistant integrated into the OS (powerful online API based, with small local model for fallback)
5. Networking stack in a privileged container
6. Planned Android app compatibility container

Project structure:
- src/: Contains all source code
  - kernel/: Core OS functionality
  - hal/: Hardware Abstraction Layer
  - containers/: Container runtime and orchestration
  - llm/: LLM integration and AI assistant
  - networking/: Networking stack
  - ui/: User interface
- docs/: Project documentation
- build.zig: Zig build script

Current focus:
1. Setting up a basic kernel that can boot and print a message
2. Establishing the build system and development workflow

When providing advice or code suggestions, please consider:
- The use of Zig (0.13.0) as the primary language
- The project's containerized architecture
- The target AArch64 architecture
- The early stage of development, focusing on basic kernel functionality
- The use of QEMU for testing and development

Refer to the Development Checklist in the README for upcoming tasks and features to be implemented.
```

This prompt can be used when seeking assistance from AI language models during the development process.

## Architecture

Reclaimer OS is built on a layered, containerized architecture. Here's a high-level view of the system structure:

```mermaid
graph TD
    A[Hardware Layer] --> B[Zig Kernel]
    B --> C[Hardware Abstraction Layer HAL]
    C --> D[Container Runtime]
    D --> E[Container Orchestrator]
    E --> F[System Containers]
    E --> G[Application Containers]
    F --> H[LLM Container]
    F --> I[Networking Container]
    F --> J[Display Container]
    F --> K[Input Container]
    G --> L[Native Apps]
    G --> M[Android Apps Container]
    N[AI Assistant Interface] --> H
    N --> I
    N --> J
    N --> K
    O[User Interface Layer] --> N
    P[LLM Update Service] --> H
```

Key components of the architecture:

[... explanation of components here ...]

## File Structure

Current File Structure, will change as needed:

This file structure is subject to change as the project evolves. Here's a brief explanation of each main component:

- `src/`: Contains all the source code for the OS.
  - `kernel/`: Core OS functionality.
  - `hal/`: Hardware Abstraction Layer code.
  - `containers/`: Container runtime and orchestration logic.
  - `llm/`: LLM integration and AI assistant functionality.
  - `networking/`: Networking stack implementation.
  - `ui/`: User interface code.
- `docs/`: Project documentation.
- `build.zig`: Zig build script.
- `README.md`: Project overview and documentation.
- `LICENSE`: License file.
- `.gitignore`: Specifies intentionally untracked files to ignore.

As development progresses, this structure may be refined to better suit the project's needs.

## References

use this system prompt for LLM context when using refernce kernel codebases:

```I'm developing Reclaimer OS, an innovative containerized operating system for mobile platforms, primarily using Zig and targeting the aarch64 architecture. Key points about the project:

- Primary language: Zig (version 0.13.0)
- Target architecture: aarch64 (ARM64)
- Development environment: QEMU for emulation
- Architecture: Containerized, with major OS functions in separate containers
- Current stage: Early kernel development
- Build system: Custom Zig build script (build.zig)

Key planned components:
1. Zig Kernel: Core OS functionality
2. Hardware Abstraction Layer (HAL)
3. Container Runtime and Orchestrator
4. Integrated LLM-based AI Assistant
5. Containerized Networking stack
6. Android app compatibility (future goal)

Current focus:
- Setting up a basic bootable kernel
- Establishing the build system and development workflow

I'm referencing C-based aarch64 kernel codebases to understand architecture-specific implementations. Please help me with:

1. Explaining key differences between C and Zig for aarch64 kernel development.
2. Analyzing C code snippets from reference kernels, focusing on aarch64-specific elements.
3. Translating aarch64-specific C code to Zig, leveraging Zig-specific features.
4. Identifying critical aarch64 hardware features relevant to kernel implementation.
5. Outlining a basic structure for our Zig-based aarch64 kernel.
6. Addressing potential challenges in transitioning from C to Zig for an aarch64 kernel.

Reference C-based aarch64 kernel codebases:
- armOS: https://github.com/thanoskoutr/armOS
- kernel-aarch64: https://github.com/ekonwang/kernel-aarch64
- qemu-ramfb-aarch64-driver: https://github.com/luickk/qemu-ramfb-aarch64-driver

Additional resources:
- Zig Language Documentation: https://ziglang.org/documentation/master/
- Zig Standard Library Documentation: https://ziglang.org/documentation/master/std/
- ARM Architecture Reference Manual (for aarch64 specifics)

When providing advice or code suggestions, please consider:
- The use of Zig as the primary language
- The project's containerized architecture
- The target aarch64 architecture
- The early stage of development
- The use of QEMU for testing and development

Please provide detailed explanations and, where applicable, code examples in both C and Zig.```