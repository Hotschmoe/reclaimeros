#!/bin/bash

# Remove zig-out and .zig-cache directories
rm -rf zig-out .zig-cache

# Build the kernel
zig build

# Check if the -run flag is present
if [ "$1" == "-run" ]; then
    # Run QEMU with the built kernel
    qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a72 \
        -kernel zig-out/bin/kernel.elf \
        -nographic \
        -m 128M
fi