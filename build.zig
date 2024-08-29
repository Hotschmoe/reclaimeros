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

    // Remove the run step and QEMU command from here
}
