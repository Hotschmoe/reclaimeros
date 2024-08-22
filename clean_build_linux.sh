#!/bin/bash

# Remove zig-out and .zig-cache directories
rm -rf zig-out .zig-cache

# Check if the -run flag is present
if [ "$1" == "-run" ]; then
    # Run zig build run
    zig build run
else
    # Run zig build
    zig build
fi