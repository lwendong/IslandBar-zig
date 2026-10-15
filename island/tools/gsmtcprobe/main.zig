const std = @import("std");
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const iid_unknown = Guid{ .data1 = 0, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetProcAddress(module: ?*anyopaque, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;

pub const PlaybackType = enum { music, video, image, unknown, other };
pub const PlaybackStatus = enum { closed, opened, changing, stopped, playing, paused, other };

pub fn playbackTypeName(value: PlaybackType) []const u8 {
    return switch (value) {
        .music => "Music",
        .video => "Video",
        .image => "Image",
        .unknown => "Unknown",
        .other => "(other)",
    };
}

pub fn playbackStatusName(value: PlaybackStatus) []const u8 {
    return switch (value) {
        .closed => "Closed",
        .opened => "Opened",
        .changing => "Changing",
        .stopped => "Stopped",
        .playing => "Playing",
        .paused => "Paused",
        .other => "(other)",
    };
}

pub fn timeSpanText(ticks_100ns: i64, output: []u8) usize {
    if (output.len == 0) return 0;
    const seconds: u64 = @intCast(@max(0, @divTrunc(ticks_100ns, 10_000_000)));
    const hours = seconds / 3600;
    const minutes = (seconds % 3600) / 60;
    const secs = seconds % 60;
    const rendered = if (hours > 0)
        std.fmt.bufPrint(output, "{d}:{d:0>2}:{d:0>2}", .{ hours, minutes, secs }) catch return 0
    else
        std.fmt.bufPrint(output, "{d:0>2}:{d:0>2}", .{ minutes, secs }) catch return 0;
    return rendered.len;
}

fn gsmTcFactoryAvailable() ?bool {
    const module = GetModuleHandleW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse
        LoadLibraryW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse return null;
    const create_ptr = GetProcAddress(module, "WindowsCreateString") orelse return null;
    const get_factory_ptr = GetProcAddress(module, "RoGetActivationFactory") orelse return null;
    const delete_ptr = GetProcAddress(module, "WindowsDeleteString") orelse return null;
    const initialize_ptr = GetProcAddress(module, "RoInitialize") orelse return null;
    const uninitialize_ptr = GetProcAddress(module, "RoUninitialize") orelse return null;
    const create: *const fn ([*]const u16, u32, *?*anyopaque) callconv(.winapi) i32 = @ptrCast(create_ptr);
    const get_factory: *const fn (?*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) i32 = @ptrCast(get_factory_ptr);
    const delete: *const fn (?*anyopaque) callconv(.winapi) i32 = @ptrCast(delete_ptr);
    const initialize: *const fn (u32) callconv(.winapi) i32 = @ptrCast(initialize_ptr);
    const uninitialize: *const fn () callconv(.winapi) void = @ptrCast(uninitialize_ptr);
    if (initialize(1) < 0) return null;
    defer uninitialize();
    const class_text = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager";
    var class: [128]u16 = undefined;
    for (class_text, 0..) |ch, i| class[i] = ch;
    var hstring: ?*anyopaque = null;
    if (create(&class, @intCast(class_text.len), &hstring) < 0) return null;
    defer _ = delete(hstring);
    var factory: ?*anyopaque = null;
    return get_factory(hstring, &iid_unknown, &factory) >= 0 and factory != null;
}

pub fn main() void {
    var time: [32]u8 = undefined;
    const time_len = timeSpanText(3_661 * 10_000_000, &time);
    std.debug.print("GSMTC probe helpers ready\n", .{});
    std.debug.print("  states: {s}, {s}\n", .{ playbackTypeName(.unknown), playbackStatusName(.playing) });
    std.debug.print("  time span example: {s}\n", .{time[0..time_len]});
    if (gsmTcFactoryAvailable()) |available| {
        std.debug.print("  GSMTC WinRT factory: {s}\n", .{if (available) "available" else "unavailable"});
    } else {
        std.debug.print("  GSMTC WinRT factory: query failed\n", .{});
    }
}

pub fn smokeCheck() bool {
    var buffer: [32]u8 = undefined;
    const len = timeSpanText(3_661 * 10_000_000, &buffer);
    return std.mem.eql(u8, "1:01:01", buffer[0..len]) and
        std.mem.eql(u8, "Music", playbackTypeName(.music)) and
        std.mem.eql(u8, "Paused", playbackStatusName(.paused));
}
