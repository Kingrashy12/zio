const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .x86, .os_tag = .windows },
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    for (targets) |target| {
        const exe = b.addExecutable(.{
            .name = "zio",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(target),
                .optimize = optimize,
            }),
        });

        const target_option = b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{
            .custom = target.zigTriple(b.allocator) catch unreachable,
        } } });

        b.getInstallStep().dependOn(&target_option.step);

        // Add the ziglet dependency
        const ziglet = b.dependency("ziglet", .{});

        // Add the ziglet module to the executable
        exe.root_module.addImport("ziglet", ziglet.module("ziglet"));

        b.installArtifact(exe);

        // const run_step = b.step("run", "Run the app");

        // const run_cmd = b.addRunArtifact(exe);
        // run_step.dependOn(&run_cmd.step);

        // run_cmd.step.dependOn(b.getInstallStep());

        // // This allows the user to pass arguments to the application in the build
        // // command itself, like this: `zig build run -- arg1 arg2 etc`
        // if (b.args) |args| {
        //     run_cmd.addArgs(args);
        // }
    }
}
