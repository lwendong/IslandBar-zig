const std = @import("std");

const HKEY = ?*anyopaque;
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const iid_unknown = Guid{ .data1 = 0, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };

extern "advapi32" fn RegGetValueW(key: HKEY, subkey: [*:0]const u16, value: [*:0]const u16, flags: u32, value_type: ?*u32, data: ?*anyopaque, data_size: *u32) callconv(.winapi) i32;
extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetProcAddress(module: ?*anyopaque, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;

fn locationSwitch() ?bool {
    const key: HKEY = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2147483646))));
    const subkey: [*:0]const u16 = &.{ 'S', 'Y', 'S', 'T', 'E', 'M', '\\', 'C', 'u', 'r', 'r', 'e', 'n', 't', 'C', 'o', 'n', 't', 'r', 'o', 'l', 'S', 'e', 't', '\\', 'S', 'e', 'r', 'v', 'i', 'c', 'e', 's', '\\', 'l', 'f', 's', 'v', 'c', '\\', 'S', 'e', 'r', 'v', 'i', 'c', 'e', '\\', 'C', 'o', 'n', 'f', 'i', 'g', 'u', 'r', 'a', 't', 'i', 'o', 'n', 0 };
    const value_name: [*:0]const u16 = &.{ 'S', 't', 'a', 't', 'u', 's', 0 };
    var enabled: u32 = 0;
    var size: u32 = @sizeOf(u32);
    const status = RegGetValueW(key, subkey, value_name, 0x00000010, null, &enabled, &size);
    if (status != 0) return null;
    return enabled != 0;
}

fn geolocatorFactoryAvailable() ?bool {
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
    var class: [96]u16 = undefined;
    const class_name = asciiToWide("Windows.Devices.Geolocation.Geolocator", &class);
    var hstring: ?*anyopaque = null;
    if (create(class_name.ptr, @intCast(class_name.len), &hstring) < 0) return null;
    defer _ = delete(hstring);
    var factory: ?*anyopaque = null;
    return get_factory(hstring, &iid_unknown, &factory) >= 0 and factory != null;
}

fn asciiToWide(source: []const u8, output: []u16) []const u16 {
    const count = @min(source.len, output.len);
    for (source[0..count], 0..) |ch, i| output[i] = ch;
    return output[0..count];
}

pub fn main() void {
    std.debug.print("Windows location probe (read-only; does not request consent)\n", .{});
    if (locationSwitch()) |enabled| {
        std.debug.print("  system location switch: {s}\n", .{if (enabled) "on" else "off"});
    } else {
        std.debug.print("  system location switch: unavailable\n", .{});
    }
    if (geolocatorFactoryAvailable()) |available| {
        std.debug.print("  Geolocator WinRT factory: {s}\n", .{if (available) "available" else "unavailable"});
    } else {
        std.debug.print("  Geolocator WinRT factory: query failed\n", .{});
    }
}
