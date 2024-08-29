@echo off

REM Remove zig-out and .zig-cache directories
if exist zig-out rmdir /s /q zig-out
if exist .zig-cache rmdir /s /q .zig-cache

REM Build the kernel
zig build

REM Check if the -run flag is present
if "%1"=="-run" (
    REM Run QEMU with the built kernel
    qemu-system-aarch64.exe ^
        -machine virt ^
        -cpu cortex-a72 ^
        -kernel zig-out\bin\kernel.elf ^
        -nographic ^
        -m 128M
)
