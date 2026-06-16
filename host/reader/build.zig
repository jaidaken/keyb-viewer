const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reader_mod = b.addModule("reader", .{
        .root_source_file = b.path("src/reader.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "keyb-reader",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{.{ .name = "reader", .module = reader_mod }},
        }),
    });
    exe.root_module.linkSystemLibrary("hidapi-hidraw", .{});
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    if (b.args) |args| run.addArgs(args);
    const run_step = b.step("run", "Run the reader");
    run_step.dependOn(&run.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/unit_test.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "reader", .module = reader_mod }},
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);

    const fmt_check = b.addFmt(.{ .paths = &.{ "src", "build.zig" }, .check = true });
    const check_step = b.step("check", "zig fmt --check");
    check_step.dependOn(&fmt_check.step);
}
