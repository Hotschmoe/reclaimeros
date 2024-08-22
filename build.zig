const std = @import("std");

pub fn build(b: *std.Build) void {
    // https://wiki.osdev.org/Zig_Bare_Bones
    const features = std.Target.aarch64.Feature;

    var enabled_features = std.Target.Cpu.Feature.Set.empty;
    enabled_features.addFeature(@intFromEnum(features.v9_2a));

    const target_query = std.Target.Query{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = enabled_features,
    };

    const target = b.resolveTargetQuery(target_query);
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/kernel/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    kernel.setLinkerScript(b.path("src/kernel/linker.ld"));

    const install_step = b.addInstallArtifact(kernel, .{});
    install_step.dest_dir = .{ .custom = "bin" };

    b.getInstallStep().dependOn(&install_step.step);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&install_step.step);

    // Add a run step to execute QEMU with the generated kernel.elf file
    const run_cmd_args = &[_][]const u8{
        "qemu-system-aarch64.exe",
        "-machine",
        "virt",
        "-cpu",
        "cortex-a72",
        "-kernel",
        "zig-out/bin/kernel.elf",
        "-nographic",
        "-m",
        "1G",
    };
    const run_cmd = b.addSystemCommand(run_cmd_args);
    run_cmd.step.dependOn(&install_step.step);
    const run_step = b.step("run", "Run QEMU with the built kernel");
    run_step.dependOn(&run_cmd.step);
}
