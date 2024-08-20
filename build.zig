const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .aarch64,
            .os_tag = .freestanding,
            .abi = .none,
        },
    });

    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/kernel/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    kernel.setLinkerScriptPath(b.path("src/kernel/linker.ld"));

    b.installArtifact(kernel);

    // Add a step to print when the build is complete
    const build_step = b.step("build", "Build the kernel");
    build_step.dependOn(&b.addInstallArtifact(kernel, .{}).step);

    // Add a custom command to print the completion message
    const print_done = b.addSystemCommand(&.{
        "cmd.exe", "/C", "echo Kernel build complete!",
    });
    build_step.dependOn(&print_done.step);

    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-system-aarch64",
        "-machine",
        "virt",
        "-cpu",
        "cortex-a72",
        "-kernel",
        b.getInstallPath(.bin, "kernel"),
        "-serial",
        "stdio",
        "-display",
        "none",
        "-d",
        "cpu_reset,guest_errors,unimp",
        "-D",
        "qemu.log",
        "-smp",
        "1",
        "-m",
        "128M",
        "-no-reboot",
        "-no-shutdown",
        "-global",
        "loader.start_address=0x400000",
    });

    // Add a step to print when QEMU is starting
    const print_qemu_start = b.addSystemCommand(&.{
        "cmd.exe", "/C", "echo Starting QEMU...",
    });
    run_cmd.step.dependOn(&print_qemu_start.step);

    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the kernel in QEMU");
    run_step.dependOn(&run_cmd.step);
}
