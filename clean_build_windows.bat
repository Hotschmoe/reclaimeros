@echo off

REM Remove zig-out and .zig-cache directories
if exist zig-out rmdir /s /q zig-out
if exist .zig-cache rmdir /s /q .zig-cache

REM Check if the -run flag is present
if "%1"=="-run" (
    REM Run zig build run
    zig build run
) else (
    REM Run zig build
    zig build
)
