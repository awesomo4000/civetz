const std = @import("std");
const vendor = @import("vendor/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build vendor libraries
    const mbedtls = vendor.buildMbedTLS(b, target, optimize);
    const civetweb = vendor.buildCivetWeb(b, target, optimize, mbedtls) catch @panic("Failed to build CivetWeb");

    const mod = b.addModule("civetz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    mod.linkLibrary(civetweb);
    mod.linkLibrary(mbedtls);

    const exe = b.addExecutable(.{
        .name = "civetz",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "civetz", .module = mod },
            },
        }),
    });

    exe.root_module.linkLibrary(civetweb);
    exe.root_module.linkLibrary(mbedtls);

    // Strip in release builds
    if (optimize != .Debug) {
        exe.root_module.strip = true;
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
