# Tracy Zig

This is a standalone version of the Zig compiler's [Tracy bindings](https://github.com/ziglang/zig/blob/master/src/tracy.zig), including build tooling.

## Usage

1. Add this repo as a dependency: `zig fetch --save git+https://github.com/silversquirl/zig-tracy`
2. Add the tracy module to your executable in your build.zig:
   ```zig
   [...]
   const tracy_dep = b.dependency("tracy", .{
       .target = target,
       .optimize = optimize,
       .enable = b.option(bool, "tracy", "Enable profiling with Tracy") orelse false,
   });
   exe.root_module.addImport("tracy", tracy_dep.module("tracy"));
   [...]
   ```
3. Instrument your code using the `tracy` module, then build with `-Dtracy`
