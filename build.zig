pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable = b.option(bool, "enable", "Enable profiling") orelse false;
    const callstack = b.option(bool, "callstack", "Include callstacks in profile") orelse false;
    const allocation = b.option(bool, "allocation", "Include allocation information in profile") orelse false;
    const no_exit = b.option(bool, "no_exit", "Wait for server to attach before exiting") orelse false;

    const upstream = b.dependency("upstream", .{});

    const mod = b.addModule("tracy", .{
        .root_source_file = b.path("src/tracy.zig"),
        .target = target,
        .optimize = optimize,
    });
    if (enable) {
        mod.link_libc = true;
        mod.link_libcpp = true;
        mod.addCSourceFile(.{
            .file = upstream.path("public/TracyClient.cpp"),
            .flags = &.{ "-std=c++11", "-Werror", "-DTRACY_ENABLE", "-fno-sanitize=undefined" },
        });
        if (no_exit) {
            mod.addCMacro("TRACY_NO_EXIT", "");
        }
    }

    const options = b.addOptions();
    options.addOption(bool, "enable_tracy", enable);
    options.addOption(bool, "enable_tracy_callstack", callstack);
    options.addOption(bool, "enable_tracy_allocation", allocation);
    mod.addImport("build_options", options.createModule());

    {
        const cli = b.step("update-bindings", "Update tracy bindings by fetching from Zig's github repository");

        const url_template = "https://raw.githubusercontent.com/ziglang/zig/{s}/src/tracy.zig";

        const url = if (builtin.zig_version.build) |commit|
            b.fmt(url_template, .{commit})
        else
            b.fmt(url_template, .{"refs/tags/" ++ builtin.zig_version_string});

        const fetch = b.addSystemCommand(&.{ "curl", "-sSLf", "-o", "src/tracy.zig", url });
        cli.dependOn(&fetch.step);
    }
}

const std = @import("std");
const builtin = @import("builtin");
