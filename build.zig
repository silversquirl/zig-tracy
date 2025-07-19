pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create default module
    {
        const enable = b.option(bool, "enable", "Enable profiling (default: false)") orelse false;
        const sampling = b.option(bool, "sampling", "Enable sampling (default: true)") orelse true;
        const callstack = b.option(u32, "callstack", "Number of stack frames to include in profile (default: 0)") orelse 0;
        const allocation = b.option(bool, "allocation", "Include allocation information in profile") orelse false;
        const wait = b.option(bool, "wait", "Wait for server to attach before exiting") orelse false;

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
                .flags = &.{ "-std=c++11", "-Wno-unused-result", "-DTRACY_ENABLE", "-fno-sanitize=undefined" },
            });
            if (!sampling) mod.addCMacro("TRACY_NO_SAMPLING", "");
            if (wait) mod.addCMacro("TRACY_NO_EXIT", "");
        }

        const options = b.addOptions();
        options.addOption(bool, "enable_tracy", enable);
        options.addOption(bool, "enable_tracy_callstack", callstack != 0);
        options.addOption(u32, "tracy_callstack_depth", callstack);
        options.addOption(bool, "enable_tracy_allocation", allocation);
        mod.addImport("build_options", options.createModule());
    }

    // Create a variant that's always disabled.
    // This is useful for quickly disabling tracy in specific files, or under specific conditions.
    {
        // Copy the source file to avoid "file exists in multiple modules" errors
        const copy = b.addWriteFiles().addCopyFile(b.path("src/tracy.zig"), "tracy.zig");

        const mod = b.addModule("tracy_always_disabled", .{
            .root_source_file = copy,
        });

        const options = b.addOptions();
        options.addOption(bool, "enable_tracy", false);
        mod.addImport("build_options", options.createModule());
    }

    {
        const cli = b.step("update-bindings", "Update tracy bindings by fetching from Zig's github repository");

        const script =
            \\ver=$("$1" version | sed -E 's/^.*\+([0-9a-f]+)$/\1/;t;s/^/refs\/tags\//')
            \\url="https://raw.githubusercontent.com/ziglang/zig/$ver/src/tracy.zig"
            \\curl -sSLf "$url" | cat - src/extra.zig >src/tracy.zig
        ;
        const fetch = b.addSystemCommand(&.{ "sh", "-c", script, "--", b.graph.zig_exe });
        fetch.setCwd(b.path("."));

        cli.dependOn(&fetch.step);
    }
}

const std = @import("std");
const builtin = @import("builtin");
