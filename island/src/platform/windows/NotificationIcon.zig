const std = @import("std");
const NotificationInput = @import("NotificationInput");
const AppIcon = @import("AppIcon");
const WicImage = @import("WicImage");
const Log = @import("Log");

const HANDLE = ?*anyopaque;
const DWORD = u32;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*:0]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit_handle: i32, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, size: *DWORD) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: DWORD, share_mode: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn GetFileSizeEx(file: HANDLE, size: *i64) callconv(.winapi) i32;
extern "kernel32" fn ReadFile(file: HANDLE, buffer: [*]u8, bytes_to_read: DWORD, bytes_read: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) i32;

const cp_utf8: DWORD = 65001;
const process_query_limited_information: DWORD = 0x1000;
const generic_read: DWORD = 0x80000000;
const file_share_read: DWORD = 0x00000001;
const file_share_write: DWORD = 0x00000002;
const open_existing: DWORD = 3;
const file_attribute_normal: DWORD = 0x00000080;
const invalid_handle_value: usize = std.math.maxInt(usize);

fn cWide(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn asciiLower(character: u16) u16 {
    return if (character >= 'A' and character <= 'Z') character + ('a' - 'A') else character;
}

fn endsWithIgnoreCase(text: []const u16, ending: []const u16) bool {
    if (text.len <= ending.len) return false;
    const suffix = text[text.len - ending.len ..];
    for (suffix, ending) |actual, expected| if (asciiLower(actual) != asciiLower(expected)) return false;
    return true;
}

/// Accepts only absolute drive or UNC file paths with a known icon-bearing extension.
pub fn isPlainIconFilePath(source_arg: []const u16) bool {
    const source = cWide(source_arg);
    if (source.len == 0 or source.len >= 260) return false;
    const drive = source.len > 3 and source[1] == ':' and source[2] == '\\' and
        ((source[0] >= 'A' and source[0] <= 'Z') or (source[0] >= 'a' and source[0] <= 'z'));
    const unc = source.len > 3 and source[0] == '\\' and source[1] == '\\';
    if (!drive and !unc) return false;
    for (source[2..]) |character| switch (character) {
        ':', '?', '*', '<', '>', '|', '"' => return false,
        else => {},
    };
    const extensions = [_][]const u16{
        &.{ '.', 'p', 'n', 'g' },
        &.{ '.', 'j', 'p', 'g' },
        &.{ '.', 'j', 'p', 'e', 'g' },
        &.{ '.', 'b', 'm', 'p' },
        &.{ '.', 'g', 'i', 'f' },
        &.{ '.', 'i', 'c', 'o' },
        &.{ '.', 't', 'i', 'f' },
        &.{ '.', 't', 'i', 'f', 'f' },
        &.{ '.', 'e', 'x', 'e' },
        &.{ '.', 'd', 'l', 'l' },
    };
    for (extensions) |extension| if (endsWithIgnoreCase(source, extension)) return true;
    return false;
}

/// Resolves an explicit UTF-8 icon field, or falls back to the sender's executable path.
pub fn notificationIconSource(notification: *const NotificationInput.Message, output: []u16) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    if (notification.icon_path[0] != 0) {
        const path: [*:0]const u8 = @ptrCast(&notification.icon_path);
        return MultiByteToWideChar(cp_utf8, 0, path, -1, output.ptr, @intCast(@min(output.len, @as(usize, std.math.maxInt(i32))))) > 0;
    }
    if (notification.sender_pid == 0) return false;
    const process = OpenProcess(process_query_limited_information, 0, notification.sender_pid) orelse return false;
    var length: DWORD = @intCast(@min(output.len, @as(usize, std.math.maxInt(DWORD))));
    const success = QueryFullProcessImageNameW(process, 0, output.ptr, &length) != 0;
    _ = CloseHandle(process);
    if (!success) output[0] = 0;
    return success;
}

/// Loads a PNG or an executable-associated icon into caller-owned premultiplied BGRA storage.
pub fn loadNotificationIconPixels(source_arg: []const u16, pixels: []u8, width: *i32, height: *i32, fetch_icon: AppIcon.FetchPngFn) ?usize {
    const source = cWide(source_arg);
    if (source.len == 0 or pixels.len == 0 or !isPlainIconFilePath(source)) return null;
    const path: [*:0]const u16 = @ptrCast(source.ptr);

    var encoded: [16 * 1024]u8 = undefined;
    var encoded_size: usize = 0;
    if (endsWithIgnoreCase(source, &.{ '.', 'p', 'n', 'g' })) {
        const file = CreateFileW(path, generic_read, file_share_read | file_share_write, null, open_existing, file_attribute_normal, null) orelse return null;
        if (@intFromPtr(file) == invalid_handle_value) return null;
        defer _ = CloseHandle(file);
        var file_size: i64 = 0;
        if (GetFileSizeEx(file, &file_size) == 0 or file_size <= 0) return null;
        const bounded: usize = @intCast(@min(file_size, @as(i64, @intCast(encoded.len))));
        var read: DWORD = 0;
        if (ReadFile(file, &encoded, @intCast(bounded), &read, null) == 0) return null;
        encoded_size = read;
    } else {
        encoded_size = fetch_icon(source, &encoded);
    }
    if (encoded_size == 0) return null;

    var decoded = WicImage.DecodedImage{};
    if (!WicImage.decodeImage(encoded[0..encoded_size], &decoded, .other) or decoded.width <= 0 or decoded.height <= 0) return null;
    const pixel_result = @mulWithOverflow(@as(usize, @intCast(decoded.width)), @as(usize, @intCast(decoded.height)));
    if (pixel_result[1] != 0) return null;
    const byte_result = @mulWithOverflow(pixel_result[0], 4);
    if (byte_result[1] != 0) return null;
    const byte_count = byte_result[0];
    const source_pixels = decoded.pixels orelse return null;
    if (byte_count > pixels.len) return null;
    @memcpy(pixels[0..byte_count], source_pixels[0..byte_count]);
    width.* = decoded.width;
    height.* = decoded.height;
    return byte_count;
}

pub fn smokeCheck(fetch_icon: AppIcon.FetchPngFn) bool {
    const drive_png: []const u16 = &.{ 'C', ':', '\\', 'i', 'c', 'o', 'n', '.', 'P', 'N', 'G', 0 };
    const drive_script: []const u16 = &.{ 'C', ':', '\\', 't', 'o', 'o', 'l', '.', 'l', 'n', 'k', 0 };
    const uri: []const u16 = &.{ 's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', 0 };
    if (!isPlainIconFilePath(drive_png)) {
        Log.logLine("self-test NotificationIcon: drive PNG path rejected");
        return false;
    }
    if (isPlainIconFilePath(drive_script) or isPlainIconFilePath(uri)) {
        Log.logLine("self-test NotificationIcon: unsafe source accepted");
        return false;
    }
    if (isPlainIconFilePath(&.{ 'C', ':', '\\', 'x', '?', '.', 'p', 'n', 'g', 0 })) {
        Log.logLine("self-test NotificationIcon: query path accepted");
        return false;
    }
    const empty_notification = NotificationInput.Message{};
    if (notificationIconSource(&empty_notification, &.{})) {
        Log.logLine("self-test NotificationIcon: empty sender produced source");
        return false;
    }

    const codec_pixel = [_]u8{ 0, 0, 255, 255 };
    var codec_png: [128]u8 = undefined;
    const codec_png_len = WicImage.encodeBgraToPng(&codec_pixel, 1, 1, &codec_png);
    var codec_image = WicImage.DecodedImage{};
    if (codec_png_len == 0 or !WicImage.decodeImage(codec_png[0..codec_png_len], &codec_image, .other)) {
        Log.logLine("self-test NotificationIcon: the encoder's small PNG failed the WIC round trip");
        return false;
    }

    var executable: [260]u16 = @splat(0);
    const path_len = GetModuleFileNameW(null, &executable, executable.len);
    if (path_len == 0 or path_len >= executable.len) {
        Log.logLine("self-test NotificationIcon: executable path lookup failed");
        return false;
    }
    var png: [16 * 1024]u8 = undefined;
    const png_len = fetch_icon(executable[0..path_len], &png);
    if (png_len == 0) {
        Log.logLine("self-test NotificationIcon: shell icon extraction returned no PNG");
        return false;
    }
    var decoded = WicImage.DecodedImage{};
    if (!WicImage.decodeImage(png[0..png_len], &decoded, .other)) {
        Log.logLine("self-test NotificationIcon: extracted PNG could not be decoded");
        return false;
    }
    if (decoded.width != 32 or decoded.height != 32 or decoded.pixels == null) {
        Log.logLine("self-test NotificationIcon: extracted image dimensions or pixels invalid");
        return false;
    }
    var icon_pixels: [32 * 32 * 4]u8 = undefined;
    var icon_width: i32 = 0;
    var icon_height: i32 = 0;
    const pixel_count = loadNotificationIconPixels(executable[0..path_len], &icon_pixels, &icon_width, &icon_height, fetch_icon) orelse {
        Log.logLine("self-test NotificationIcon: loading the executable icon returned no pixels");
        return false;
    };
    const passed = icon_width == 32 and icon_height == 32 and pixel_count == icon_pixels.len;
    if (!passed) Log.logLine("self-test NotificationIcon: loaded icon pixel dimensions inconsistent");
    return passed;
}

comptime {
    if (false) {
        var path: [260]u16 = undefined;
        var bytes: [16 * 1024]u8 = undefined;
        var width: i32 = 0;
        var height: i32 = 0;
        const empty_notification = NotificationInput.Message{};
        _ = notificationIconSource(&empty_notification, &path);
        _ = loadNotificationIconPixels(&path, &bytes, &width, &height, AppIcon.unavailable);
    }
}
