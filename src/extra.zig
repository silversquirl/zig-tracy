pub inline fn setThreadName(name: [*:0]const u8) void {
    if (!enable) return;
    ___tracy_set_thread_name(name);
}
extern fn ___tracy_set_thread_name(name: [*:0]const u8) void;

extern fn ___tracy_emit_plot(name: [*:0]const u8, val: f64) void;
extern fn ___tracy_emit_plot_float(name: [*:0]const u8, val: f32) void;
extern fn ___tracy_emit_plot_int(name: [*:0]const u8, val: i64) void;
extern fn ___tracy_emit_plot_config(
    name: [*:0]const u8,
    format: PlotConfig.Format,
    step: i32,
    fill: i32,
    color: u32,
) void;

pub inline fn plot(name: [*:0]const u8) Plot {
    return if (enable) .{ .name = name } else .{};
}

pub const Plot = if (enable) struct {
    name: [*:0]const u8,

    pub const Config = PlotConfig;
    pub inline fn config(plt: Plot, cfg: Config) void {
        ___tracy_emit_plot_config(
            plt.name,
            cfg.format,
            @intFromBool(cfg.step),
            @intFromBool(cfg.fill),
            cfg.color,
        );
    }

    pub inline fn update(plt: Plot, val: anytype) void {
        switch (@typeInfo(@TypeOf(val))) {
            .float => |f| if (f.bits <= 32)
                ___tracy_emit_plot_float(plt.name, val)
            else
                ___tracy_emit_plot(plt.name, val),
            .comptime_float => ___tracy_emit_plot(plt.name, val),

            .int, .comptime_int => ___tracy_emit_plot_int(plt.name, std.math.lossyCast(i64, val)),

            else => @compileError("invalid argument type " ++ @typeName(@TypeOf(val)) ++ ", expected float or integer"),
        }
    }
} else struct {
    pub const Config = PlotConfig;
    pub inline fn config(plt: Plot, cfg: Config) void {
        _ = plt;
        _ = cfg;
    }
    pub inline fn update(plt: Plot, val: anytype) void {
        _ = plt;
        _ = val;
    }
};

const PlotConfig = struct {
    format: Format = .number,
    step: bool = false,
    fill: bool = true,
    color: u32 = 0,

    pub const Format = enum(i32) { number, memory, percentage, watt };
};
