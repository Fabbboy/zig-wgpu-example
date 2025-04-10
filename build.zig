const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const wgpu_native_dep = b.dependency("wgpu_native_zig", .{});
    exe_mod.addImport("wgpu", wgpu_native_dep.module("wgpu"));

    const exe = b.addExecutable(.{
        .name = "codeman",
        .root_module = exe_mod,
    });

    exe.linkSystemLibrary("glfw3");
    exe.linkLibC();

    b.installArtifact(exe);
}
