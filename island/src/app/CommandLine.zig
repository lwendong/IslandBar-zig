const std = @import("std");
const Motion = @import("Motion");

extern "shell32" fn CommandLineToArgvW(command_line: [*:0]const u16, argc: *i32) callconv(.winapi) ?[*][*:0]u16;
extern "kernel32" fn GetCommandLineW() callconv(.winapi) [*:0]const u16;
extern "kernel32" fn LocalFree(memory: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn WideCharToMultiByte(code_page: u32, flags: u32, input: [*]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;

const RuntimeArgs = struct {
    argv: [*][*:0]u16,
    count: usize,

    fn open() ?RuntimeArgs {
        var argc: i32 = 0;
        const argv = CommandLineToArgvW(GetCommandLineW(), &argc) orelse return null;
        if (argc <= 0) {
            _ = LocalFree(@ptrCast(argv));
            return null;
        }
        return .{ .argv = argv, .count = @intCast(argc) };
    }

    fn close(self: *RuntimeArgs) void {
        _ = LocalFree(@ptrCast(self.argv));
    }

    fn at(self: *const RuntimeArgs, index: usize) []const u16 {
        return std.mem.span(self.argv[index]);
    }

    fn has(self: *const RuntimeArgs, expected: []const u16) bool {
        for (1..self.count) |index| {
            if (std.mem.eql(u16, self.at(index), expected)) return true;
        }
        return false;
    }

    fn valueAfter(self: *const RuntimeArgs, flag: []const u16, offset: usize) ?[]const u16 {
        if (self.count < 2) return null;
        for (1..self.count) |index| {
            if (!std.mem.eql(u16, self.at(index), flag)) continue;
            const value_index = std.math.add(usize, index, offset) catch return null;
            return if (value_index < self.count) self.at(value_index) else null;
        }
        return null;
    }

    fn intAfter(self: *const RuntimeArgs, flag: []const u16, default: i64) i64 {
        const value = self.valueAfter(flag, 1) orelse return default;
        return parseInteger(value, default);
    }

    fn atOffsetEquals(self: *const RuntimeArgs, flag: []const u16, offset: usize, expected: []const u16) bool {
        const value = self.valueAfter(flag, offset) orelse return false;
        return std.mem.eql(u16, value, expected);
    }
};

fn parseInteger(value: []const u16, default: i64) i64 {
    if (value.len == 0 or value.len > 20) return default;

    const negative = value[0] == '-';
    const first_digit: usize = @intFromBool(negative);
    if (first_digit == value.len) return default;

    var magnitude: u64 = 0;
    for (value[first_digit..]) |digit| {
        if (digit < '0' or digit > '9') return default;
        magnitude = std.math.mul(u64, magnitude, 10) catch return default;
        magnitude = std.math.add(u64, magnitude, digit - '0') catch return default;
    }

    if (negative) {
        const min_magnitude: u64 = @as(u64, std.math.maxInt(i64)) + 1;
        if (magnitude > min_magnitude) return default;
        if (magnitude == min_magnitude) return std.math.minInt(i64);
        return -@as(i64, @intCast(magnitude));
    }
    return std.math.cast(i64, magnitude) orelse default;
}

const smoke_flag: []const u16 = &.{ '-', '-', 's', 'm', 'o', 'k', 'e' };
const self_test_flag: []const u16 = &.{ '-', '-', 's', 'e', 'l', 'f', '-', 't', 'e', 's', 't' };
const keep_taskbar_flag: []const u16 = &.{ '-', '-', 'k', 'e', 'e', 'p', '-', 't', 'a', 's', 'k', 'b', 'a', 'r' };
const no_console_flag: []const u16 = &.{ '-', '-', 'n', 'o', '-', 'c', 'o', 'n', 's', 'o', 'l', 'e' };
const keep_strip_flag: []const u16 = &.{ '-', '-', 'k', 'e', 'e', 'p', '-', 's', 't', 'r', 'i', 'p' };
const appbar_flag: []const u16 = &.{ '-', '-', 'a', 'p', 'p', 'b', 'a', 'r' };
const system_panel_flag: []const u16 = &.{ '-', '-', 's', 'y', 's', 't', 'e', 'm', '-', 'p', 'a', 'n', 'e', 'l' };
const offline_flag: []const u16 = &.{ '-', '-', 'o', 'f', 'f', 'l', 'i', 'n', 'e' };
const window_list_flag: []const u16 = &.{ '-', '-', 'w', 'i', 'n', 'd', 'o', 'w', '-', 'l', 'i', 's', 't' };
const probe_taskbar_flag: []const u16 = &.{ '-', '-', 'p', 'r', 'o', 'b', 'e', '-', 't', 'a', 's', 'k', 'b', 'a', 'r' };
const activate_flag: []const u16 = &.{ '-', '-', 'a', 'c', 't', 'i', 'v', 'a', 't', 'e' };
const tray_dump_flag: []const u16 = &.{ '-', '-', 't', 'r', 'a', 'y', '-', 'd', 'u', 'm', 'p' };
const tray_surface_flag: []const u16 = &.{ '-', '-', 't', 'r', 'a', 'y', '-', 's', 'u', 'r', 'f', 'a', 'c', 'e' };
const toast_dump_flag: []const u16 = &.{ '-', '-', 't', 'o', 'a', 's', 't', '-', 'd', 'u', 'm', 'p' };
const tray_press_flag: []const u16 = &.{ '-', '-', 't', 'r', 'a', 'y', '-', 'p', 'r', 'e', 's', 's' };
const fire_flag: []const u16 = &.{ '-', '-', 'f', 'i', 'r', 'e' };
const right_flag: []const u16 = &.{ '-', '-', 'r', 'i', 'g', 'h', 't' };
const help_flag: []const u16 = &.{ '-', '-', 'h', 'e', 'l', 'p' };
const volume_test_flag: []const u16 = &.{ '-', '-', 'v', 'o', 'l', 'u', 'm', 'e', '-', 't', 'e', 's', 't' };
const volume_set_flag: []const u16 = &.{ '-', '-', 'v', 'o', 'l', 'u', 'm', 'e', '-', 's', 'e', 't' };
const state_flag: []const u16 = &.{ '-', '-', 's', 't', 'a', 't', 'e' };
pub const lyrics_test_flag: []const u16 = &.{ '-', '-', 'l', 'y', 'r', 'i', 'c', 's', '-', 't', 'e', 's', 't' };
pub const lyrics_verbose_flag: []const u16 = &.{ '-', '-', 'l', 'y', 'r', 'i', 'c', 's', '-', 'v', 'e', 'r', 'b', 'o', 's', 'e' };
const demo_flag: []const u16 = &.{ '-', '-', 'd', 'e', 'm', 'o' };
const start_hover_flag: []const u16 = &.{ '-', '-', 's', 't', 'a', 'r', 't', '-', 'h', 'o', 'v', 'e', 'r' };
const music_preview_flag: []const u16 = &.{ '-', '-', 'm', 'u', 's', 'i', 'c', '-', 'p', 'r', 'e', 'v', 'i', 'e', 'w' };
pub const icon_dump_flag: []const u16 = &.{ '-', '-', 'i', 'c', 'o', 'n', '-', 'd', 'u', 'm', 'p' };
pub const notify_flag: []const u16 = &.{ '-', '-', 'n', 'o', 't', 'i', 'f', 'y' };
pub const notify_body_flag: []const u16 = &.{ '-', '-', 'b', 'o', 'd', 'y' };
pub const notify_app_flag: []const u16 = &.{ '-', '-', 'a', 'p', 'p' };
pub const notify_icon_flag: []const u16 = &.{ '-', '-', 'i', 'c', 'o', 'n' };
pub const notify_urgency_flag: []const u16 = &.{ '-', '-', 'u', 'r', 'g', 'e', 'n', 'c', 'y' };
pub const sticky_flag: []const u16 = &.{ '-', '-', 's', 't', 'i', 'c', 'k', 'y' };

pub const RuntimeOptions = struct {
    self_test: bool = false,
    no_console: bool = false,
    keep_taskbar: bool = false,
    keep_strip: bool = false,
    appbar: bool = false,
    system_panel: bool = false,
    offline: bool = false,
    window_list: bool = false,
    probe_taskbar: bool = false,
    activate_window: bool = false,
    tray_dump: bool = false,
    tray_surface: bool = false,
    toast_dump: bool = false,
    toast_limit: i64 = 10,
    tray_press: ?i32 = null,
    tray_fire: bool = false,
    tray_right: bool = false,
    volume_test: bool = false,
    volume_set: ?i32 = null,
    forced_state: ?Motion.IslandState = null,
    lyrics_test: bool = false,
    lyrics_verbose: bool = false,
    demo: bool = false,
    start_hover: bool = false,
    music_preview: bool = false,
    icon_dump: bool = false,
    notify: bool = false,
    help: bool = false,
};

pub fn runtimeOptions() RuntimeOptions {
    var args = RuntimeArgs.open() orelse return .{};
    defer args.close();
    var state_text: [32]u8 = undefined;
    const state_value = if (args.valueAfter(state_flag, 1)) |wide| wideTextToUtf8(wide, &state_text) else "";
    return .{
        .self_test = args.has(smoke_flag) or args.has(self_test_flag),
        .no_console = args.has(no_console_flag),
        .keep_taskbar = args.has(keep_taskbar_flag),
        .keep_strip = args.has(keep_strip_flag),
        .appbar = args.has(appbar_flag),
        .system_panel = args.has(system_panel_flag),
        .offline = args.has(offline_flag),
        .window_list = args.has(window_list_flag),
        .probe_taskbar = args.has(probe_taskbar_flag),
        .activate_window = args.has(activate_flag),
        .tray_dump = args.has(tray_dump_flag),
        .tray_surface = args.has(tray_surface_flag),
        .toast_dump = args.has(toast_dump_flag),
        .toast_limit = args.intAfter(toast_dump_flag, 10),
        .tray_press = if (args.has(tray_press_flag) and args.valueAfter(tray_press_flag, 1) != null) std.math.cast(i32, args.intAfter(tray_press_flag, 0)) else null,
        .tray_fire = args.atOffsetEquals(tray_press_flag, 2, fire_flag),
        .tray_right = args.atOffsetEquals(tray_press_flag, 3, right_flag),
        .volume_test = args.has(volume_test_flag),
        .volume_set = if (args.has(volume_set_flag) and args.valueAfter(volume_set_flag, 1) != null) std.math.cast(i32, args.intAfter(volume_set_flag, 0)) else null,
        .forced_state = if (state_value.len > 0) Motion.stateFromName(state_value) else null,
        .lyrics_test = args.has(lyrics_test_flag),
        .lyrics_verbose = args.has(lyrics_verbose_flag),
        .demo = args.has(demo_flag),
        .start_hover = args.has(start_hover_flag),
        .music_preview = args.has(music_preview_flag),
        .icon_dump = args.has(icon_dump_flag),
        .notify = args.has(notify_flag),
        .help = args.has(help_flag) or args.has(&.{ '-', 'h' }),
    };
}

pub fn hasArgument(flag: []const u16) bool {
    var args = RuntimeArgs.open() orelse return false;
    defer args.close();
    return args.has(flag);
}

pub fn valueAfter(flag: []const u16, output: []u8) ?[]const u8 {
    return valueAfterOffset(flag, 1, output);
}

pub fn valueAfterOffset(flag: []const u16, offset: usize, output: []u8) ?[]const u8 {
    if (output.len == 0) return null;
    var args = RuntimeArgs.open() orelse return null;
    defer args.close();
    const value = args.valueAfter(flag, offset) orelse return null;
    const converted = wideTextToUtf8(value, output);
    return if (converted.len == 0) null else converted;
}

pub fn wideTextToUtf8(source: []const u16, output: []u8) []const u8 {
    if (source.len == 0 or output.len == 0) return "";
    const source_length = std.mem.indexOfScalar(u16, source, 0) orelse source.len;
    if (source_length == 0) return "";
    const converted = WideCharToMultiByte(65001, 0, source.ptr, @intCast(source_length), output.ptr, @intCast(output.len), null, null);
    if (converted <= 0) return "";
    return output[0..@intCast(converted)];
}

pub fn smokeCheck() bool {
    var args = RuntimeArgs.open() orelse return false;
    defer args.close();
    if (!args.has(self_test_flag)) return false;

    const minimum = std.unicode.utf8ToUtf16LeStringLiteral("-9223372036854775808");
    const overflow = std.unicode.utf8ToUtf16LeStringLiteral("9223372036854775808");
    const invalid = std.unicode.utf8ToUtf16LeStringLiteral("12x");
    const negative = &.{ '-', '4', '2' };
    var utf8: [16]u8 = undefined;
    return parseInteger(negative, 0) == -42 and
        parseInteger(minimum, 0) == std.math.minInt(i64) and
        parseInteger(overflow, 7) == 7 and
        parseInteger(invalid, 9) == 9 and
        parseInteger(&.{}, 11) == 11 and
        std.mem.eql(u8, wideTextToUtf8(&.{ 0x4e2d, 0x6587 }, &utf8), "中文");
}
