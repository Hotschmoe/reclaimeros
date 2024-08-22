const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    std.debug.print("Build function started\n", .{});

    // Detect and print the host system
    const os_name = "Windows";

    // Print the host system
    std.debug.print("Host system: {s}\n", .{os_name});

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

    std.debug.print("Building kernel executable\n", .{});

    const kernel = b.addExecutable(.{
        .name = "kernel.elf", // explicitly named .elf so that it becomes an elf
        .root_source_file = b.path("src/kernel/main.zig"),
        .target = target,
        .optimize = optimize,
        //.code_model = .kernel, // llvm not happy with this
    });
    kernel.setLinkerScript(b.path("src/kernel/linker.ld"));
    var kernel_install_step = b.addInstallArtifact(kernel, .{});

    std.debug.print("Adding install step\n", .{});

    const install_step = b.addInstallArtifact(kernel, .{});
    install_step.dest_dir = .{ .custom = "bin" }; // Ensure the correct directory

    // Modify the clean step
    const clean_step = b.step("clean", "Clean build artifacts");
    const clean_cmd_args = &[_][]const u8{
        "powershell",                                                                                  "-Command",
        "Remove-Item -Path zig-out, .zig-cache -Recurse -Force -ErrorAction SilentlyContinue; exit 0",
    };
    const clean_cmd = b.addSystemCommand(clean_cmd_args);
    clean_step.dependOn(&clean_cmd.step);

    // Ensure clean step runs before install
    b.getInstallStep().dependOn(clean_step);
    b.getInstallStep().dependOn(&install_step.step);

    std.debug.print("Build function completed\n", .{});

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel_install_step.step);

    // Add a run step to execute QEMU with the generated kernel.elf file
    const run_cmd_args = &[_][]const u8{
        "qemu-system-aarch64.exe",
        "-machine",
        "virt",
        "-cpu",
        "cortex-a72",
        "-kernel",
        "zig-out\\bin\\kernel.elf",
        "-nographic",
    };
    const run_cmd = b.addSystemCommand(run_cmd_args);
    const run_step = b.step("run", "Run QEMU with the built kernel");
    run_step.dependOn(&kernel_install_step.step);
    run_step.dependOn(&run_cmd.step);
}
