const std = @import("std");
const WicImage = @import("WicImage");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;

const ShellFileInfo = extern struct {
    icon: HANDLE,
    icon_index: i32,
    attributes: DWORD,
    display_name: [260]u16,
    type_name: [80]u16,
};

const BitmapV5Header = extern struct {
    size: u32,
    width: i32,
    height: i32,
    planes: u16,
    bits_per_pixel: u16,
    compression: u32,
    image_size: u32,
    x_pels_per_meter: i32,
    y_pels_per_meter: i32,
    colors_used: u32,
    colors_important: u32,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    alpha_mask: u32,
    color_space_type: u32,
    endpoints: [9]i32,
    gamma_red: u32,
    gamma_green: u32,
    gamma_blue: u32,
    intent: u32,
    profile_data: u32,
    profile_size: u32,
    reserved: u32,
};

extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "user32" fn GetDC(window: HANDLE) callconv(.winapi) HANDLE;
extern "user32" fn ReleaseDC(window: HANDLE, dc: HANDLE) callconv(.winapi) i32;
extern "user32" fn DrawIconEx(dc: HANDLE, x: i32, y: i32, icon: HANDLE, width: i32, height: i32, step: u32, brush: HANDLE, flags: u32) callconv(.winapi) BOOL;
extern "user32" fn DestroyIcon(icon: HANDLE) callconv(.winapi) BOOL;
extern "gdi32" fn CreateCompatibleDC(dc: HANDLE) callconv(.winapi) HANDLE;
extern "gdi32" fn DeleteDC(dc: HANDLE) callconv(.winapi) BOOL;
extern "gdi32" fn CreateDIBSection(dc: HANDLE, info: *const BitmapV5Header, usage: u32, bits: *?*anyopaque, section: HANDLE, offset: DWORD) callconv(.winapi) HANDLE;
extern "gdi32" fn SelectObject(dc: HANDLE, object: HANDLE) callconv(.winapi) HANDLE;
extern "gdi32" fn DeleteObject(object: HANDLE) callconv(.winapi) BOOL;
extern "gdi32" fn GdiFlush() callconv(.winapi) BOOL;
extern "shell32" fn SHGetFileInfoW(path: [*:0]const u16, attributes: DWORD, info: *ShellFileInfo, size: u32, flags: u32) callconv(.winapi) usize;

const shgfi_icon: u32 = 0x100;
const shgfi_small_icon: u32 = 0x1;
const dib_rgb_colors: u32 = 0;
const bi_bitfields: u32 = 3;
const di_normal: u32 = 3;
const app_icon_side: i32 = 32;

fn validPathLength(executable_path: []const u16, output_len: usize) ?usize {
    if (output_len == 0) return null;
    const path_len = std.mem.indexOfScalar(u16, executable_path, 0) orelse executable_path.len;
    if (path_len == 0 or path_len >= 260) return null;
    return path_len;
}

/// Extracts the Shell-associated icon, draws it into a top-down 32-bit DIB,
/// and encodes PNG into caller-owned storage. No GDI resource escapes.
pub fn fetchFileIconPng(executable_path: []const u16, output: []u8) usize {
    const path_len = validPathLength(executable_path, output.len) orelse return 0;
    var path: [260]u16 = @splat(0);
    @memcpy(path[0..path_len], executable_path[0..path_len]);
    const path_z: [*:0]const u16 = @ptrCast(&path);

    var info = std.mem.zeroes(ShellFileInfo);
    if (SHGetFileInfoW(path_z, 0, &info, @intCast(@sizeOf(ShellFileInfo)), shgfi_icon | shgfi_small_icon) == 0 or info.icon == null) return 0;
    defer _ = DestroyIcon(info.icon);

    const header = BitmapV5Header{
        .size = @intCast(@sizeOf(BitmapV5Header)),
        .width = app_icon_side,
        .height = -app_icon_side,
        .planes = 1,
        .bits_per_pixel = 32,
        .compression = bi_bitfields,
        .image_size = @intCast(app_icon_side * app_icon_side * 4),
        .x_pels_per_meter = 0,
        .y_pels_per_meter = 0,
        .colors_used = 0,
        .colors_important = 0,
        .red_mask = 0x00FF0000,
        .green_mask = 0x0000FF00,
        .blue_mask = 0x000000FF,
        .alpha_mask = 0xFF000000,
        .color_space_type = 0,
        .endpoints = @splat(0),
        .gamma_red = 0,
        .gamma_green = 0,
        .gamma_blue = 0,
        .intent = 0,
        .profile_data = 0,
        .profile_size = 0,
        .reserved = 0,
    };

    const screen = GetDC(null);
    if (screen == null) return 0;
    defer _ = ReleaseDC(null, screen);
    const memory = CreateCompatibleDC(screen) orelse return 0;
    defer _ = DeleteDC(memory);
    var bits: ?*anyopaque = null;
    const bitmap = CreateDIBSection(memory, &header, dib_rgb_colors, &bits, null, 0) orelse return 0;
    defer _ = DeleteObject(bitmap);
    const pixel_memory = bits orelse return 0;
    const previous = SelectObject(memory, bitmap) orelse return 0;
    _ = DrawIconEx(memory, 0, 0, info.icon, app_icon_side, app_icon_side, 0, null, di_normal);
    _ = GdiFlush();
    _ = SelectObject(memory, previous);
    const pixels: [*]const u8 = @ptrCast(pixel_memory);
    const byte_count: usize = @intCast(app_icon_side * app_icon_side * 4);
    return WicImage.encodeBgraToPng(pixels[0..byte_count], app_icon_side, app_icon_side, output);
}

test "icon requests validate path and caller buffer before touching Windows" {
    try std.testing.expectEqual(@as(?usize, null), validPathLength(&.{}, 128));
    try std.testing.expectEqual(@as(?usize, null), validPathLength(&.{ 'C', ':', '\\', 'a', 0 }, 0));
    try std.testing.expectEqual(@as(?usize, 4), validPathLength(&.{ 'C', ':', '\\', 'a', 0, 'x' }, 128));
    const too_long: [260]u16 = @splat('x');
    try std.testing.expectEqual(@as(?usize, null), validPathLength(&too_long, 128));
}

test "current executable icon is returned as a PNG in caller-owned memory" {
    var executable: [260]u16 = @splat(0);
    const path_len = GetModuleFileNameW(null, &executable, @intCast(executable.len));
    try std.testing.expect(path_len > 0 and path_len < executable.len);
    var encoded: [16 * 1024]u8 = undefined;
    const size = fetchFileIconPng(executable[0..path_len], &encoded);
    try std.testing.expect(size > 8);
    const png_signature = [_]u8{ 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };
    try std.testing.expect(std.mem.eql(u8, encoded[0..png_signature.len], &png_signature));
}
