pub const PlaybackState = enum(i32) { closed = 0, stopped = 1, paused = 2, playing = 3, unknown = 4 };
pub const TrackPosition = struct { ms: i64 = 0, from_session: bool = false };
pub const title_capacity = 192;
pub const artist_capacity = 128;
pub const album_capacity = 160;
pub const app_capacity = 64;
pub const app_name_capacity = 128;
pub const artwork_capacity = 32 * 1024;
pub const artwork_max_dimension = 128;
pub const poll_interval_ms: u64 = 1000;
pub const skip_poll_interval_ms: u64 = 250;
pub const skip_poll_window_ms: u64 = 6000;
pub const artwork_retry_ms: u64 = 1000;
pub const artwork_retry_window_ms: u64 = 15000;
pub const artwork_retry_slow_ms: u64 = 2000;

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const FileTime = extern struct { low: DWORD, high: DWORD };
const Translation = extern struct { language: u16, code_page: u16 };
const FindData = extern struct {
    attributes: DWORD,
    creation_time: FileTime,
    last_access_time: FileTime,
    last_write_time: FileTime,
    size_high: DWORD,
    size_low: DWORD,
    reserved0: DWORD,
    reserved1: DWORD,
    file_name: [260]u16,
    alternate_file_name: [14]u16,
};
const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const UnknownVTable = extern struct {
    query_interface: *const fn (*anyopaque, *const Guid, *HANDLE) callconv(.winapi) i32,
    add_ref: *const fn (*anyopaque) callconv(.winapi) u32,
    release: *const fn (*anyopaque) callconv(.winapi) u32,
};
const Unknown = extern struct { vtable: *const UnknownVTable };
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

extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn GetProcAddress(module: HANDLE, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn WaitForMultipleObjects(count: DWORD, handles: [*]const HANDLE, wait_all: BOOL, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetTickCount() callconv(.winapi) DWORD;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*]const u16, input_length: i32, output: ?[*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*BOOL) callconv(.winapi) i32;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn GetFileAttributesW(path: [*:0]const u16) callconv(.winapi) DWORD;
extern "kernel32" fn FindFirstFileW(path: [*:0]const u16, data: *FindData) callconv(.winapi) HANDLE;
extern "kernel32" fn FindNextFileW(search: HANDLE, data: *FindData) callconv(.winapi) BOOL;
extern "kernel32" fn FindClose(search: HANDLE) callconv(.winapi) BOOL;
extern "advapi32" fn RegOpenKeyExW(root: HANDLE, subkey: [*:0]const u16, options: DWORD, access: DWORD, result: *HANDLE) callconv(.winapi) i32;
extern "advapi32" fn RegQueryValueExW(key: HANDLE, value_name: ?[*:0]const u16, reserved: ?*DWORD, value_type: *DWORD, data: [*]u8, data_size: *DWORD) callconv(.winapi) i32;
extern "advapi32" fn RegCloseKey(key: HANDLE) callconv(.winapi) i32;
extern "version" fn GetFileVersionInfoSizeW(filename: [*:0]const u16, handle: *DWORD) callconv(.winapi) DWORD;
extern "version" fn GetFileVersionInfoW(filename: [*:0]const u16, handle: DWORD, size: DWORD, data: *anyopaque) callconv(.winapi) BOOL;
extern "version" fn VerQueryValueW(block: *const anyopaque, sub_block: [*:0]const u16, value: *?*anyopaque, length: *DWORD) callconv(.winapi) BOOL;
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

const wait_object_0: DWORD = 0;
const wait_timeout: DWORD = 258;
const infinite: DWORD = 0xFFFFFFFF;
const cp_utf8: DWORD = 65001;
const shgfi_icon: u32 = 0x100;
const shgfi_small_icon: u32 = 0x1;
const dib_rgb_colors: u32 = 0;
const bi_bitfields: u32 = 3;
const di_normal: u32 = 3;
const app_icon_side: i32 = 32;
const invalid_file_attributes: DWORD = 0xffffffff;
const file_attribute_directory: DWORD = 0x10;
const invalid_handle_value: usize = std.math.maxInt(usize);
const error_success: i32 = 0;
const reg_sz: DWORD = 1;
const key_query_value: DWORD = 0x0001;
const hkey_current_user: HANDLE = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2147483647))));
const hkey_local_machine: HANDLE = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2147483646))));
const winrt_init_multithreaded: u32 = 1;
const smtc_class_name = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager";
const iid_manager_statics = Guid{ .data1 = 0x2050C4EE, .data2 = 0x11A0, .data3 = 0x57DE, .data4 = .{ 0xAE, 0xD7, 0xC9, 0x7C, 0x70, 0x33, 0x82, 0x45 } };
const iid_async_info = Guid{ .data1 = 0x00000036, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const wait_slice_ms: DWORD = 5;
const async_operation_timeout_ms: DWORD = 5000;
var startup_failure_logged: i32 = 0;

fn reportStartupFailure(stage: []const u8, hresult: ?i32) void {
    if (@cmpxchgStrong(i32, &startup_failure_logged, 0, 1, .seq_cst, .seq_cst) != null) return;
    var message: [160]u8 = undefined;
    const rendered = if (hresult) |value|
        std.fmt.bufPrint(&message, "GSMTC initialization failed at {s} (HRESULT 0x{x:0>8})", .{ stage, @as(u32, @bitCast(value)) }) catch "GSMTC initialization failed"
    else
        std.fmt.bufPrint(&message, "GSMTC initialization failed at {s}", .{stage}) catch "GSMTC initialization failed";
    Log.logLine(rendered);
    if (hresult != null and hresult.? == -2147024891) {
        Log.logLine("GSMTC access denied: the app package must declare the globalMediaControl capability");
    }
}

pub const MusicInfo = struct {
    present: bool = false,
    state: PlaybackState = .closed,
    title: [title_capacity]u8 = @splat(0),
    artist: [artist_capacity]u8 = @splat(0),
    album: [album_capacity]u8 = @splat(0),
    app: [app_capacity]u8 = @splat(0),
    position_ms: i64 = 0,
    duration_ms: i64 = 0,
    artwork: [artwork_capacity]u8 = @splat(0),
    artwork_size: usize = 0,
    artwork_revision: u64 = 0,
    app_name: [app_name_capacity]u8 = @splat(0),
    icon: [artwork_capacity]u8 = @splat(0),
    icon_size: usize = 0,
    icon_revision: u64 = 0,
};

pub fn projectedPositionMs(position_ms: i64, duration_ms: i64, elapsed_ms: i64, playing: bool) i64 {
    if (!playing or position_ms <= 0 or duration_ms <= 0 or elapsed_ms <= 0) return position_ms;
    const projected = std.math.add(i64, position_ms, elapsed_ms) catch duration_ms;
    return @min(projected, duration_ms);
}

pub fn sessionReportsTimeline(position_ms: i64, duration_ms: i64) bool {
    return position_ms > 0 or duration_ms > 0;
}

pub fn trackPositionFor(position_ms: i64, duration_ms: i64, since_reading_ms: i64, stopwatch_ms: i64, playing: bool) TrackPosition {
    if (sessionReportsTimeline(position_ms, duration_ms)) return .{
        .ms = projectedPositionMs(position_ms, duration_ms, since_reading_ms, playing),
        .from_session = true,
    };
    return .{ .ms = @max(0, stopwatch_ms), .from_session = false };
}

pub fn playbackStateName(state: PlaybackState) []const u8 {
    return switch (state) {
        .closed => "closed",
        .stopped => "stopped",
        .paused => "paused",
        .playing => "playing",
        .unknown => "unknown",
    };
}

pub fn sessionScore(app_id: []const u16, playing: bool) i32 {
    const music_apps = [_][]const u8{ "qqmusic", "cloudmusic", "netease", "spotify", "musicbee", "foobar", "aimp", "potplayer", "groove", "zunemusic", "itunes", "kugou", "kuwo", "migu" };
    const video_apps = [_][]const u8{ "chrome", "msedge", "firefox", "brave", "opera", "vivaldi", "iexplore", "vlc", "mpc-hc", "mpc-be", "bilibili" };
    var score: i32 = 0;
    for (music_apps) |name| {
        if (containsAsciiIgnoreCase(app_id, name)) {
            score += 100;
            break;
        }
    }
    for (video_apps) |name| {
        if (containsAsciiIgnoreCase(app_id, name)) {
            score -= 100;
            break;
        }
    }
    if (playing) score += 50;
    return score;
}

pub fn shouldFetchArtwork(track_changed: bool, artwork_missing: bool, since_last_try_ms: u64, since_track_change_ms: u64) bool {
    if (track_changed) return true;
    if (!artwork_missing) return false;
    const cadence = if (since_track_change_ms < artwork_retry_window_ms) artwork_retry_ms else artwork_retry_slow_ms;
    return since_last_try_ms >= cadence;
}

pub fn nextPollIntervalMs(now_ms: u64, last_skip_ms: u64, last_track_change_ms: u64) u64 {
    const within_window = struct {
        fn check(now: u64, stamp: u64) bool {
            return stamp != 0 and now >= stamp and now - stamp < skip_poll_window_ms;
        }
    }.check;
    return if (within_window(now_ms, last_skip_ms) or within_window(now_ms, last_track_change_ms)) skip_poll_interval_ms else poll_interval_ms;
}

/// Extracts a real file icon through the Shell, draws it into the same top-down
/// 32-bit DIB used by the C++ implementation, and encodes it with the Zig PNG
/// writer. The caller owns the output buffer; no GDI or decoder memory escapes.
pub fn fetchAppIconForTest(executable_path: []const u16, output: []u8) usize {
    const path_len = std.mem.indexOfScalar(u16, executable_path, 0) orelse executable_path.len;
    if (path_len == 0 or path_len >= 260 or output.len == 0) return 0;
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

/// Resolves the executable named by a GSMTC app id. Desktop sessions usually
/// publish a full path, but some publish only `QQMusic.exe`; package ids such
/// as `package!App` are intentionally rejected because they are not file paths.
pub fn executableFromAppId(app_id_arg: []const u16, output: []u16) bool {
    if (output.len == 0) return false;
    @memset(output, 0);
    const app_id = app_id_arg[0 .. std.mem.indexOfScalar(u16, app_id_arg, 0) orelse app_id_arg.len];
    if (app_id.len == 0 or app_id.len >= output.len) return false;
    if (std.mem.indexOfScalar(u16, app_id, '!') != null) return false;

    var dot: ?usize = null;
    for (app_id, 0..) |unit, index| if (unit == '.') {
        dot = index;
    };
    const extension = if (dot) |index| app_id[index..] else return false;
    if (!wideAsciiEqualIgnoreCase(extension, ".exe")) return false;

    var candidate: [260]u16 = @splat(0);
    if (copyWideZ(&candidate, app_id) and GetFileAttributesW(wideZ(&candidate)) != invalid_file_attributes) {
        return copyWideZ(output, app_id);
    }
    @memset(output, 0);
    const base = basename(app_id);
    if (resolveBareExecutable(base, output)) return true;
    return searchInstallRoots(base, output);
}

pub fn fetchIconForAppId(app_id: []const u16, output: []u8) usize {
    var executable: [260]u16 = @splat(0);
    if (!executableFromAppId(app_id, &executable)) return 0;
    return fetchAppIconForTest(wideZSlice(&executable), output);
}

fn resolveBareExecutable(file_name: []const u16, output: []u16) bool {
    if (file_name.len == 0 or output.len == 0) return false;
    const roots = [_]HANDLE{ hkey_current_user, hkey_local_machine };
    const prefix = std.unicode.utf8ToUtf16LeStringLiteral("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths");
    var key_path: [512]u16 = @splat(0);
    const pieces = [_][]const u16{ prefix, file_name };
    if (!joinWidePath(&key_path, &pieces)) return false;

    for (roots) |root| {
        var key: HANDLE = null;
        if (RegOpenKeyExW(root, wideZ(&key_path), 0, key_query_value, &key) != error_success) continue;
        var value_type: DWORD = 0;
        var byte_count: DWORD = @intCast(@min(output.len * @sizeOf(u16), std.math.maxInt(DWORD)));
        const queried = RegQueryValueExW(key, null, null, &value_type, @ptrCast(output.ptr), &byte_count);
        _ = RegCloseKey(key);
        if (queried != error_success or value_type != reg_sz or output[0] == 0) {
            @memset(output, 0);
            continue;
        }

        var length = wideZSlice(output).len;
        if (length > 0 and output[0] == '"') {
            std.mem.copyForwards(u16, output[0..length], output[1 .. length + 1]);
            length -= 1;
            output[length] = 0;
            if (std.mem.indexOfScalar(u16, output[0..length], '"')) |closing| {
                output[closing] = 0;
                length = closing;
            }
        }
        if (length > 0 and GetFileAttributesW(wideZ(output)) != invalid_file_attributes) return true;
        @memset(output, 0);
    }
    return false;
}

fn searchInstallRoots(file_name: []const u16, output: []u16) bool {
    const roots = [_][]const u16{
        std.unicode.utf8ToUtf16LeStringLiteral("C:\\SOFTWARE"),
        std.unicode.utf8ToUtf16LeStringLiteral("C:\\Program Files"),
        std.unicode.utf8ToUtf16LeStringLiteral("C:\\Program Files (x86)"),
    };
    const wildcard = &.{@as(u16, '*')};
    var pattern: [260]u16 = @splat(0);
    var candidate: [260]u16 = @splat(0);
    var deeper: [260]u16 = @splat(0);

    for (roots) |root_z| {
        const root: []const u16 = root_z;
        const root_pattern = [_][]const u16{ root, wildcard };
        if (!joinWidePath(&pattern, &root_pattern)) continue;
        var outer_data: FindData = undefined;
        const outer = FindFirstFileW(wideZ(&pattern), &outer_data);
        if (isInvalidHandle(outer)) continue;

        var outer_more = true;
        while (outer_more) {
            const directory = wideZSlice(&outer_data.file_name);
            if ((outer_data.attributes & file_attribute_directory) != 0 and !isDotEntry(directory)) {
                const direct_parts = [_][]const u16{ root, directory, file_name };
                if (joinWidePath(&candidate, &direct_parts) and GetFileAttributesW(wideZ(&candidate)) != invalid_file_attributes) {
                    _ = FindClose(outer);
                    return copyWideZ(output, wideZSlice(&candidate));
                }

                const deeper_parts = [_][]const u16{ root, directory, wildcard };
                if (joinWidePath(&deeper, &deeper_parts)) {
                    var inner_data: FindData = undefined;
                    const inner = FindFirstFileW(wideZ(&deeper), &inner_data);
                    if (!isInvalidHandle(inner)) {
                        var inner_more = true;
                        while (inner_more) {
                            const inner_directory = wideZSlice(&inner_data.file_name);
                            if ((inner_data.attributes & file_attribute_directory) != 0 and !isDotEntry(inner_directory)) {
                                const nested_parts = [_][]const u16{ root, directory, inner_directory, file_name };
                                if (joinWidePath(&candidate, &nested_parts) and GetFileAttributesW(wideZ(&candidate)) != invalid_file_attributes) {
                                    _ = FindClose(inner);
                                    _ = FindClose(outer);
                                    return copyWideZ(output, wideZSlice(&candidate));
                                }
                            }
                            inner_more = FindNextFileW(inner, &inner_data) != 0;
                        }
                        _ = FindClose(inner);
                    }
                }
            }
            outer_more = FindNextFileW(outer, &outer_data) != 0;
        }
        _ = FindClose(outer);
    }
    return false;
}

fn isInvalidHandle(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle) == invalid_handle_value;
}

fn isDotEntry(name: []const u16) bool {
    return name.len == 0 or name[0] == '.';
}

fn wideZ(output: []u16) [*:0]const u16 {
    return @ptrCast(output.ptr);
}

fn wideZSlice(input: []const u16) []const u16 {
    return input[0 .. std.mem.indexOfScalar(u16, input, 0) orelse input.len];
}

fn copyWideZ(output: []u16, input_arg: []const u16) bool {
    if (output.len == 0) return false;
    @memset(output, 0);
    const input = wideZSlice(input_arg);
    if (input.len >= output.len) return false;
    @memcpy(output[0..input.len], input);
    output[input.len] = 0;
    return true;
}

fn appendWidePathPart(output: []u16, used: *usize, part_arg: []const u16, add_separator: bool) bool {
    const part = wideZSlice(part_arg);
    const separator_count: usize = if (add_separator and used.* != 0) 1 else 0;
    if (used.* + separator_count + part.len >= output.len) return false;
    if (separator_count != 0) {
        output[used.*] = '\\';
        used.* += 1;
    }
    @memcpy(output[used.* .. used.* + part.len], part);
    used.* += part.len;
    output[used.*] = 0;
    return true;
}

fn joinWidePath(output: []u16, parts: []const []const u16) bool {
    if (output.len == 0 or parts.len == 0) return false;
    @memset(output, 0);
    var used: usize = 0;
    for (parts, 0..) |part, index| {
        if (!appendWidePathPart(output, &used, part, index != 0)) {
            @memset(output, 0);
            return false;
        }
    }
    return used != 0;
}

fn wideAsciiEqualIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    if (wide.len != ascii.len) return false;
    for (wide, ascii) |left, right| {
        const folded_left = if (left >= 'A' and left <= 'Z') left + ('a' - 'A') else left;
        const folded_right = if (right >= 'A' and right <= 'Z') right + ('a' - 'A') else right;
        if (folded_left != folded_right) return false;
    }
    return true;
}

fn utf8ToWide(input_arg: []const u8, output: []u16) usize {
    if (input_arg.len == 0 or output.len == 0) return 0;
    const input = input_arg[0 .. std.mem.indexOfScalar(u8, input_arg, 0) orelse input_arg.len];
    const written = MultiByteToWideChar(cp_utf8, 0, input.ptr, @intCast(input.len), output.ptr, @intCast(output.len - 1));
    if (written <= 0) return 0;
    output[@intCast(written)] = 0;
    return @intCast(written);
}

fn wideToUtf8(input: []const u16, output: []u8) bool {
    if (input.len == 0 or output.len == 0) return false;
    @memset(output, 0);
    const written = WideCharToMultiByte(cp_utf8, 0, input.ptr, @intCast(input.len), output.ptr, @intCast(output.len - 1), null, null);
    if (written <= 0) return false;
    output[@intCast(written)] = 0;
    return true;
}

fn appendAsciiRaw(output: *[128]u16, used: *usize, input: []const u8) bool {
    if (used.* + input.len >= output.len) return false;
    for (input) |unit| {
        output[used.*] = unit;
        used.* += 1;
    }
    output[used.*] = 0;
    return true;
}

fn appendHexWord(output: *[128]u16, used: *usize, value: u16) bool {
    const digits = "0123456789abcdef";
    if (used.* + 4 >= output.len) return false;
    for (0..4) |position| {
        const shift: u4 = @intCast((3 - position) * 4);
        output[used.*] = digits[@as(usize, @intCast((value >> shift) & 0x0f))];
        used.* += 1;
    }
    output[used.*] = 0;
    return true;
}

fn versionProductName(executable: []const u16, output: []u8) bool {
    if (executable.len == 0 or output.len == 0) return false;
    var path: [260]u16 = @splat(0);
    if (!copyWideZ(&path, executable)) return false;
    var ignored: DWORD = 0;
    const block_size = GetFileVersionInfoSizeW(wideZ(&path), &ignored);
    if (block_size == 0) return false;
    const block = std.heap.page_allocator.alloc(u8, block_size) catch return false;
    defer std.heap.page_allocator.free(block);
    if (GetFileVersionInfoW(wideZ(&path), 0, block_size, @ptrCast(block.ptr)) == 0) return false;

    const translation_query = std.unicode.utf8ToUtf16LeStringLiteral("\\VarFileInfo\\Translation");
    var translation_value: ?*anyopaque = null;
    var translation_bytes: DWORD = 0;
    if (VerQueryValueW(@ptrCast(block.ptr), translation_query, &translation_value, &translation_bytes) == 0 or
        translation_bytes < @sizeOf(Translation)) return false;
    const translations: [*]const Translation = @ptrCast(@alignCast(translation_value orelse return false));
    const translation = translations[0];

    const keys = [_][]const u8{ "ProductName", "FileDescription" };
    for (keys) |key| {
        var query: [128]u16 = @splat(0);
        var used: usize = 0;
        if (!appendAsciiRaw(&query, &used, "\\StringFileInfo\\") or
            !appendHexWord(&query, &used, translation.language) or
            !appendHexWord(&query, &used, translation.code_page) or
            !appendAsciiRaw(&query, &used, "\\") or
            !appendAsciiRaw(&query, &used, key)) continue;

        var value: ?*anyopaque = null;
        var value_bytes: DWORD = 0;
        if (VerQueryValueW(@ptrCast(block.ptr), wideZ(&query), &value, &value_bytes) == 0 or value_bytes <= @sizeOf(u16)) continue;
        const value_ptr: [*]const u16 = @ptrCast(@alignCast(value orelse continue));
        const units: usize = @min(value_bytes / @sizeOf(u16), 256);
        const text = wideZSlice(value_ptr[0..units]);
        var end = text.len;
        while (end > 0 and (text[end - 1] == ' ' or text[end - 1] == '\t')) : (end -= 1) {}
        if (end == 0 or end >= 120) continue;
        var numeric_version = true;
        for (text[0..end]) |unit| {
            if (!((unit >= '0' and unit <= '9') or unit == '.' or unit == ' ')) {
                numeric_version = false;
                break;
            }
        }
        if (numeric_version) continue;
        if (wideToUtf8(text[0..end], output)) return true;
    }
    return false;
}

fn fillAppDisplayName(app_id_utf8: []const u8, app_id_wide: []const u16, executable: []const u16, output: []u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    if (knownPlayerDisplayName(executable)) |known| {
        if (wideToUtf8(known, output)) return;
    }
    if (knownPlayerDisplayName(app_id_wide)) |known| {
        if (wideToUtf8(known, output)) return;
    }
    if (executable.len != 0) {
        if (versionProductName(executable, output)) return;
        const base = basename(executable);
        var end = base.len;
        for (base, 0..) |unit, index| if (unit == '.') {
            end = index;
        };
        if (end != 0 and wideToUtf8(base[0..end], output)) return;
    }
    putBytesZ(output, app_id_utf8);
}

pub fn knownPlayerDisplayName(executable: []const u16) ?[]const u16 {
    const base = basename(executable);
    if (eqlAsciiIgnoreCase(base, "cloudmusic.exe") or eqlAsciiIgnoreCase(base, "cloudmusic_pc.exe")) return &.{ 0x7F51, 0x6613, 0x4E91, 0x97F3, 0x4E50 };
    return null;
}

pub const Transport = enum { play_pause, previous, next };

const WinRtApi = struct {
    module: HANDLE,
    initialize: *const fn (u32) callconv(.winapi) i32,
    uninitialize: *const fn () callconv(.winapi) void,
    create_string: *const fn ([*]const u16, u32, *HANDLE) callconv(.winapi) i32,
    delete_string: *const fn (HANDLE) callconv(.winapi) i32,
    get_string_buffer: *const fn (HANDLE, *u32) callconv(.winapi) [*]const u16,
    get_activation_factory: *const fn (HANDLE, *const Guid, *HANDLE) callconv(.winapi) i32,

    fn load() ?WinRtApi {
        const combase = GetModuleHandleW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse
            LoadLibraryW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse {
            reportStartupFailure("loading combase.dll", null);
            return null;
        };
        const initialize = GetProcAddress(combase, "RoInitialize") orelse {
            reportStartupFailure("resolving RoInitialize", null);
            return null;
        };
        const uninitialize = GetProcAddress(combase, "RoUninitialize") orelse {
            reportStartupFailure("resolving RoUninitialize", null);
            return null;
        };
        const create_string = GetProcAddress(combase, "WindowsCreateString") orelse {
            reportStartupFailure("resolving WindowsCreateString", null);
            return null;
        };
        const delete_string = GetProcAddress(combase, "WindowsDeleteString") orelse {
            reportStartupFailure("resolving WindowsDeleteString", null);
            return null;
        };
        const get_string_buffer = GetProcAddress(combase, "WindowsGetStringRawBuffer") orelse {
            reportStartupFailure("resolving WindowsGetStringRawBuffer", null);
            return null;
        };
        const get_activation_factory = GetProcAddress(combase, "RoGetActivationFactory") orelse {
            reportStartupFailure("resolving RoGetActivationFactory", null);
            return null;
        };
        return .{
            .module = combase,
            .initialize = @ptrCast(initialize),
            .uninitialize = @ptrCast(uninitialize),
            .create_string = @ptrCast(create_string),
            .delete_string = @ptrCast(delete_string),
            .get_string_buffer = @ptrCast(get_string_buffer),
            .get_activation_factory = @ptrCast(get_activation_factory),
        };
    }

    fn createAsciiString(self: *const WinRtApi, value: []const u8) HANDLE {
        var wide: [160]u16 = @splat(0);
        if (value.len >= wide.len) return null;
        for (value, 0..) |byte, index| {
            if (byte > 0x7F) return null;
            wide[index] = byte;
        }
        var result: HANDLE = null;
        const result_code = self.create_string(&wide, @intCast(value.len), &result);
        if (result_code < 0) {
            reportStartupFailure("WindowsCreateString", result_code);
            return null;
        }
        return result;
    }

    fn createManagerFactory(self: *const WinRtApi) HANDLE {
        const class_name = self.createAsciiString(smtc_class_name) orelse return null;
        defer _ = self.delete_string(class_name);
        var factory: HANDLE = null;
        const result_code = self.get_activation_factory(class_name, &iid_manager_statics, &factory);
        if (result_code < 0) {
            reportStartupFailure("RoGetActivationFactory(GSMTC manager statics)", result_code);
            return null;
        }
        return factory;
    }

    fn copyStringUtf8(self: *const WinRtApi, value: HANDLE, output: []u8) void {
        if (output.len == 0) return;
        output[0] = 0;
        if (value == null) return;
        defer _ = self.delete_string(value);
        var wide_length: u32 = 0;
        const wide = self.get_string_buffer(value, &wide_length);
        if (wide_length == 0) return;
        var units: usize = wide_length;
        while (units > 0) : (units -= 1) {
            const converted = WideCharToMultiByte(cp_utf8, 0, wide, @intCast(units), output.ptr, @intCast(output.len - 1), null, null);
            if (converted > 0) {
                output[@intCast(converted)] = 0;
                return;
            }
        }
    }
};

fn comMethod(comptime T: type, object: *anyopaque, index: usize) T {
    const header: *const extern struct { vtable: [*]const ?*anyopaque } = @ptrCast(@alignCast(object));
    return @ptrCast(header.vtable[index] orelse unreachable);
}

fn releaseCom(object: *HANDLE) void {
    if (object.*) |raw| {
        const unknown: *Unknown = @ptrCast(@alignCast(raw));
        _ = unknown.vtable.release(raw);
        object.* = null;
    }
}

fn queryComInterface(object: HANDLE, iid: *const Guid) HANDLE {
    const raw = object orelse return null;
    const unknown: *Unknown = @ptrCast(@alignCast(raw));
    var result: HANDLE = null;
    const result_code = unknown.vtable.query_interface(raw, iid, &result);
    if (result_code < 0) {
        reportStartupFailure("QueryInterface(IAsyncInfo)", result_code);
        return null;
    }
    return result;
}

fn awaitAsyncObject(api: *const WinRtApi, operation_arg: HANDLE, stop_event: HANDLE) HANDLE {
    var operation = operation_arg;
    defer releaseCom(&operation);
    var info = queryComInterface(operation, &iid_async_info);
    if (info == null) return null;
    defer releaseCom(&info);
    const get_status = comMethod(*const fn (*anyopaque, *u32) callconv(.winapi) i32, info.?, 7);
    // IAsyncInfo is queried separately for Status. The operation ABI's own
    // IInspectable vtable then places Completed at 6/7 and GetResults at 8.
    const get_results = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, operation.?, 8);
    const started = GetTickCount();
    while (true) {
        if (stop_event != null and WaitForSingleObject(stop_event, 0) == wait_object_0) {
            cancelAsync(info.?);
            return null;
        }
        if (GetTickCount() -% started >= async_operation_timeout_ms) {
            reportStartupFailure("WinRT async operation timed out", null);
            cancelAsync(info.?);
            return null;
        }
        var status: u32 = 0;
        const status_result = get_status(info.?, &status);
        if (status_result < 0) {
            reportStartupFailure("IAsyncInfo.get_Status", status_result);
            return null;
        }
        if (status == 1) {
            var result: HANDLE = null;
            const result_code = get_results(operation.?, &result);
            if (result_code < 0) {
                reportStartupFailure("IAsyncOperation.GetResults", result_code);
                releaseCom(&result);
                return null;
            }
            return result;
        }
        if (status > 1) {
            const get_error = comMethod(*const fn (*anyopaque, *i32) callconv(.winapi) i32, info.?, 8);
            var error_code: i32 = 0;
            if (get_error(info.?, &error_code) < 0) error_code = @intCast(status);
            reportStartupFailure("IAsyncOperation completion", error_code);
            return null;
        }
        Sleep(wait_slice_ms);
    }
    _ = api;
}

fn awaitAsyncBool(api: *const WinRtApi, operation_arg: HANDLE, stop_event: HANDLE) ?bool {
    var operation = operation_arg;
    defer releaseCom(&operation);
    var info = queryComInterface(operation, &iid_async_info);
    if (info == null) return null;
    defer releaseCom(&info);
    const get_status = comMethod(*const fn (*anyopaque, *u32) callconv(.winapi) i32, info.?, 7);
    const get_results = comMethod(*const fn (*anyopaque, *u8) callconv(.winapi) i32, operation.?, 8);
    const started = GetTickCount();
    while (true) {
        if (stop_event != null and WaitForSingleObject(stop_event, 0) == wait_object_0) {
            cancelAsync(info.?);
            return null;
        }
        if (GetTickCount() -% started >= async_operation_timeout_ms) {
            cancelAsync(info.?);
            return null;
        }
        var status: u32 = 0;
        if (get_status(info.?, &status) < 0) return null;
        if (status == 1) {
            var result: u8 = 0;
            if (get_results(operation.?, &result) < 0) return null;
            return result != 0;
        }
        if (status > 1) return null;
        Sleep(wait_slice_ms);
    }
    _ = api;
}

fn cancelAsync(info: *anyopaque) void {
    const cancel = comMethod(*const fn (*anyopaque) callconv(.winapi) i32, info, 9);
    _ = cancel(info);
}

fn createSessionManager(api: *const WinRtApi, stop_event: HANDLE) HANDLE {
    var factory = api.createManagerFactory();
    if (factory == null) return null;
    defer releaseCom(&factory);
    const request = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, factory.?, 6);
    var operation: HANDLE = null;
    const request_result = request(factory.?, &operation);
    if (request_result < 0) {
        reportStartupFailure("RequestAsync", request_result);
        releaseCom(&operation);
        return null;
    }
    return awaitAsyncObject(api, operation, stop_event);
}

fn sessionForManager(manager: HANDLE) HANDLE {
    const get_current = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, manager.?, 6);
    var session: HANDLE = null;
    if (get_current(manager.?, &session) < 0) {
        releaseCom(&session);
        return null;
    }
    return session;
}

/// Mirrors the C++ session ranking: prefer recognized music players, reject
/// known video/browser sessions, and add a playing bonus. The shell's current
/// session is only a fallback because it often picks a recently started video.
fn chooseSessionForManager(api: *const WinRtApi, manager: HANDLE) HANDLE {
    const get_sessions = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, manager.?, 7);
    var sessions: HANDLE = null;
    if (get_sessions(manager.?, &sessions) < 0 or sessions == null) {
        releaseCom(&sessions);
        return sessionForManager(manager);
    }
    defer releaseCom(&sessions);

    const get_size = comMethod(*const fn (*anyopaque, *u32) callconv(.winapi) i32, sessions.?, 7);
    var count: u32 = 0;
    if (get_size(sessions.?, &count) < 0) return sessionForManager(manager);

    const get_at = comMethod(*const fn (*anyopaque, u32, *HANDLE) callconv(.winapi) i32, sessions.?, 6);
    var best: HANDLE = null;
    var best_score: i32 = std.math.minInt(i32);
    for (0..count) |index| {
        var candidate: HANDLE = null;
        if (get_at(sessions.?, @intCast(index), &candidate) < 0 or candidate == null) {
            releaseCom(&candidate);
            continue;
        }
        const score = scoreSession(api, candidate.?);
        if (score > best_score) {
            releaseCom(&best);
            best = candidate;
            best_score = score;
        } else {
            releaseCom(&candidate);
        }
    }
    if (best != null) return best;
    return sessionForManager(manager);
}

fn scoreSession(api: *const WinRtApi, session: *anyopaque) i32 {
    const get_app_id = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session, 6);
    var app_id: HANDLE = null;
    var score: i32 = 0;
    if (get_app_id(session, &app_id) >= 0 and app_id != null) {
        var length: u32 = 0;
        const text = api.get_string_buffer(app_id, &length);
        score = sessionScore(text[0..@intCast(length)], false);
    }
    if (app_id != null) _ = api.delete_string(app_id);

    const get_playback = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session, 9);
    var playback: HANDLE = null;
    if (get_playback(session, &playback) >= 0 and playback != null) {
        defer releaseCom(&playback);
        const get_status = comMethod(*const fn (*anyopaque, *i32) callconv(.winapi) i32, playback.?, 7);
        var status: i32 = 0;
        if (get_status(playback.?, &status) >= 0 and status == 4) score += 50;
    } else {
        releaseCom(&playback);
    }
    return score;
}

fn readStringProperty(api: *const WinRtApi, object: HANDLE, slot: usize, output: []u8) void {
    const get_value = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, object.?, slot);
    var value: HANDLE = null;
    if (get_value(object.?, &value) >= 0) api.copyStringUtf8(value, output) else releaseCom(&value);
}

fn convertStatus(status: i32) PlaybackState {
    return switch (status) {
        0 => .closed,
        3 => .stopped,
        5 => .paused,
        4 => .playing,
        else => .unknown,
    };
}

fn pollManager(api: *const WinRtApi, previous: *const MusicInfo, fresh: *MusicInfo, stop_event: HANDLE) bool {
    var manager = createSessionManager(api, stop_event);
    if (manager == null) return false;
    defer releaseCom(&manager);
    fresh.* = .{};
    var session = chooseSessionForManager(api, manager);
    if (session) |session_value| {
        defer releaseCom(&session);
        fresh.present = true;

        const get_media = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session_value, 7);
        var media_operation: HANDLE = null;
        if (get_media(session_value, &media_operation) >= 0) {
            var properties = awaitAsyncObject(api, media_operation, stop_event);
            if (properties) |properties_value| {
                defer releaseCom(&properties);
                readStringProperty(api, properties_value, 6, &fresh.title);
                readStringProperty(api, properties_value, 9, &fresh.artist);
                readStringProperty(api, properties_value, 10, &fresh.album);
            }
        } else releaseCom(&media_operation);

        readStringProperty(api, session_value, 6, &fresh.app);
        const same_app = std.mem.eql(u8, &fresh.app, &previous.app);
        if (same_app) {
            putBytesZ(&fresh.app_name, &previous.app_name);
            fresh.icon_size = previous.icon_size;
            fresh.icon_revision = previous.icon_revision;
            if (previous.icon_size > 0) @memcpy(fresh.icon[0..previous.icon_size], previous.icon[0..previous.icon_size]);
        } else {
            var app_id_wide: [260]u16 = @splat(0);
            const app_id_length = utf8ToWide(&fresh.app, &app_id_wide);
            var executable: [260]u16 = @splat(0);
            var executable_slice: []const u16 = &.{};
            if (app_id_length > 0 and executableFromAppId(app_id_wide[0..app_id_length], &executable)) {
                executable_slice = wideZSlice(&executable);
                fresh.icon_size = fetchAppIconForTest(executable_slice, &fresh.icon);
                if (fresh.icon_size > 0) fresh.icon_revision = previous.icon_revision +% 1;
            }
            fillAppDisplayName(&fresh.app, if (app_id_length != 0) app_id_wide[0..app_id_length] else &.{}, executable_slice, &fresh.app_name);
        }

        const get_playback = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session_value, 9);
        var playback: HANDLE = null;
        if (get_playback(session_value, &playback) >= 0) {
            defer releaseCom(&playback);
            const get_status = comMethod(*const fn (*anyopaque, *i32) callconv(.winapi) i32, playback.?, 7);
            var status: i32 = 0;
            if (get_status(playback.?, &status) >= 0) fresh.state = convertStatus(status) else fresh.state = .unknown;
        } else {
            releaseCom(&playback);
            fresh.state = .unknown;
        }

        const get_timeline = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session_value, 8);
        var timeline: HANDLE = null;
        if (get_timeline(session_value, &timeline) >= 0) {
            defer releaseCom(&timeline);
            const get_end = comMethod(*const fn (*anyopaque, *i64) callconv(.winapi) i32, timeline.?, 7);
            const get_position = comMethod(*const fn (*anyopaque, *i64) callconv(.winapi) i32, timeline.?, 10);
            var ticks: i64 = 0;
            if (get_position(timeline.?, &ticks) >= 0) fresh.position_ms = @divTrunc(ticks, 10_000);
            ticks = 0;
            if (get_end(timeline.?, &ticks) >= 0) fresh.duration_ms = @divTrunc(ticks, 10_000);
        } else releaseCom(&timeline);

        const same_track = std.mem.eql(u8, &fresh.title, &previous.title) and
            std.mem.eql(u8, &fresh.artist, &previous.artist) and std.mem.eql(u8, &fresh.album, &previous.album);
        if (same_track and previous.artwork_size > 0) {
            fresh.artwork_size = previous.artwork_size;
            fresh.artwork_revision = previous.artwork_revision;
            @memcpy(fresh.artwork[0..previous.artwork_size], previous.artwork[0..previous.artwork_size]);
        }
    }
    return true;
}

fn putBytesZ(output: []u8, input_arg: []const u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const input = input_arg[0 .. std.mem.indexOfScalar(u8, input_arg, 0) orelse input_arg.len];
    const take = @min(input.len, output.len - 1);
    @memcpy(output[0..take], input[0..take]);
}

fn sessionTransport(api: *const WinRtApi, action: Transport, stop_event: HANDLE) ?bool {
    var manager = createSessionManager(api, stop_event);
    if (manager == null) return null;
    defer releaseCom(&manager);
    var session = chooseSessionForManager(api, manager);
    if (session == null) return null;
    defer releaseCom(&session);
    const slot: usize = switch (action) {
        .next => 16,
        .previous => 17,
        .play_pause => 20,
    };
    const method = comMethod(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, session.?, slot);
    var operation: HANDLE = null;
    if (method(session.?, &operation) < 0) {
        releaseCom(&operation);
        return null;
    }
    return awaitAsyncBool(api, operation, stop_event);
}

fn infoChanged(a: *const MusicInfo, b: *const MusicInfo) bool {
    return a.present != b.present or a.state != b.state or @divTrunc(a.position_ms, 1000) != @divTrunc(b.position_ms, 1000) or
        a.artwork_revision != b.artwork_revision or !std.mem.eql(u8, &a.title, &b.title) or
        !std.mem.eql(u8, &a.artist, &b.artist) or !std.mem.eql(u8, &a.album, &b.album) or !std.mem.eql(u8, &a.app, &b.app);
}

/// Owns the GSMTC apartment and worker. All WinRT calls stay on that worker; the UI only copies snapshots.
pub const MusicSession = struct {
    stop_event: HANDLE = null,
    action_event: HANDLE = null,
    thread: HANDLE = null,
    running_flag: i32 = 0,
    lock: CriticalSection = .{ .debug_info = null, .lock_count = 0, .recursion_count = 0, .owning_thread = null, .lock_semaphore = null, .spin_count = 0 },
    lock_ready: bool = false,
    current_info: MusicInfo = .{},
    revision: i32 = 0,
    poll_count: i32 = 0,
    action_pending: i32 = 0,
    toggle_count: i32 = 0,
    pending_action: Transport = .play_pause,

    pub fn start(self: *MusicSession) bool {
        if (@atomicLoad(i32, &self.running_flag, .seq_cst) != 0) return true;
        @atomicStore(i32, &startup_failure_logged, 0, .seq_cst);
        if (self.lock_ready) return false;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        self.action_event = CreateEventW(null, 0, 0, null);
        if (self.stop_event == null or self.action_event == null) {
            self.closeEvents();
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            self.closeEvents();
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        // GSMTC activation can stay pending on machines where the shell media service is
        // unavailable. Keep it off the UI startup path; async waits are cancellable and bounded.
        // A worker that already reported an apartment/API failure is joined and reported as unavailable.
        if (@atomicLoad(i32, &self.running_flag, .seq_cst) == -1) {
            self.stop();
            return false;
        }
        @atomicStore(i32, &self.running_flag, 1, .seq_cst);
        return true;
    }

    pub fn stop(self: *MusicSession) void {
        if (self.stop_event) |event| _ = SetEvent(event);
        if (self.thread) |thread| {
            // The worker owns the WinRT apartment and uses the critical section
            // until it exits. Do not destroy either while it may still be running.
            _ = WaitForSingleObject(thread, infinite);
            _ = CloseHandle(thread);
            self.thread = null;
        }
        self.closeEvents();
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
        @atomicStore(i32, &self.running_flag, 0, .seq_cst);
    }

    fn closeEvents(self: *MusicSession) void {
        if (self.stop_event) |event| {
            _ = CloseHandle(event);
            self.stop_event = null;
        }
        if (self.action_event) |event| {
            _ = CloseHandle(event);
            self.action_event = null;
        }
    }

    pub fn snapshot(self: *MusicSession, output: *MusicInfo) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        output.* = self.current_info;
        LeaveCriticalSection(&self.lock);
    }

    pub fn getRevision(self: *const MusicSession) u64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.revision, .seq_cst)));
    }

    pub fn getPollCount(self: *const MusicSession) i64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.poll_count, .seq_cst)));
    }

    pub fn requestTransport(self: *MusicSession, action: Transport) bool {
        if (@atomicLoad(i32, &self.running_flag, .seq_cst) == 0 or self.action_event == null) return false;
        EnterCriticalSection(&self.lock);
        self.pending_action = action;
        _ = @atomicRmw(i32, &self.action_pending, .Xchg, 1, .seq_cst);
        LeaveCriticalSection(&self.lock);
        if (self.action_event) |event| _ = SetEvent(event);
        return true;
    }

    pub fn requestTogglePlayPause(self: *MusicSession) bool {
        return self.requestTransport(.play_pause);
    }

    pub fn getToggleCount(self: *const MusicSession) i64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.toggle_count, .seq_cst)));
    }

    fn threadEntry(parameter: ?*anyopaque) callconv(.winapi) DWORD {
        const self: *MusicSession = @ptrCast(@alignCast(parameter orelse return 0));
        self.run();
        return 0;
    }

    fn run(self: *MusicSession) void {
        const api = WinRtApi.load() orelse {
            reportStartupFailure("loading WinRT APIs", null);
            @atomicStore(i32, &self.running_flag, -1, .seq_cst);
            return;
        };
        const apartment = api.initialize(winrt_init_multithreaded);
        if (apartment < 0) {
            reportStartupFailure("RoInitialize(MTA)", apartment);
            @atomicStore(i32, &self.running_flag, -1, .seq_cst);
            return;
        }
        defer api.uninitialize();

        const previous = std.heap.page_allocator.create(MusicInfo) catch {
            @atomicStore(i32, &self.running_flag, -1, .seq_cst);
            return;
        };
        defer std.heap.page_allocator.destroy(previous);
        previous.* = .{};
        const fresh = std.heap.page_allocator.create(MusicInfo) catch {
            @atomicStore(i32, &self.running_flag, -1, .seq_cst);
            return;
        };
        defer std.heap.page_allocator.destroy(fresh);
        var last_poll: DWORD = 0;
        var last_skip: u64 = 0;
        var last_track_change: u64 = 0;

        while (true) {
            const now = GetTickCount();
            const interval = nextPollIntervalMs(now, last_skip, last_track_change);
            const elapsed: u64 = now -% last_poll;
            const remaining: DWORD = if (elapsed >= interval) 0 else @intCast(interval - elapsed);
            const waits = [_]HANDLE{ self.stop_event, self.action_event };
            const signalled = WaitForMultipleObjects(waits.len, &waits, 0, remaining);
            if (signalled == wait_object_0) break;
            if (self.stop_event) |event| if (WaitForSingleObject(event, 0) == wait_object_0) break;

            const pending = @cmpxchgStrong(i32, &self.action_pending, 1, 0, .seq_cst, .seq_cst);
            const action_requested = signalled == wait_object_0 + 1 or pending != null;
            if (action_requested) {
                EnterCriticalSection(&self.lock);
                const action = self.pending_action;
                LeaveCriticalSection(&self.lock);
                if (sessionTransport(&api, action, self.stop_event)) |accepted| {
                    if (accepted and action == .play_pause and previous.present) {
                        previous.state = if (previous.state == .playing) .paused else .playing;
                        EnterCriticalSection(&self.lock);
                        self.current_info = previous.*;
                        LeaveCriticalSection(&self.lock);
                        _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
                    }
                    _ = @atomicRmw(i32, &self.toggle_count, .Add, 1, .seq_cst);
                }
                _ = @atomicRmw(i32, &self.action_pending, .Xchg, 0, .seq_cst);
                if (action == .previous or action == .next) last_skip = GetTickCount();
                continue;
            }

            const tick = GetTickCount();
            if (tick -% last_poll < interval) continue;
            last_poll = tick;
            if (!pollManager(&api, previous, fresh, self.stop_event)) {
                reportStartupFailure("creating a session manager", null);
                continue;
            }
            _ = @atomicRmw(i32, &self.poll_count, .Add, 1, .seq_cst);
            if (infoChanged(fresh, previous)) {
                if (fresh.present and (!std.mem.eql(u8, &fresh.title, &previous.title) or !std.mem.eql(u8, &fresh.artist, &previous.artist) or !std.mem.eql(u8, &fresh.album, &previous.album))) {
                    last_track_change = GetTickCount();
                }
                EnterCriticalSection(&self.lock);
                self.current_info = fresh.*;
                LeaveCriticalSection(&self.lock);
                previous.* = fresh.*;
                _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
            }
        }
        @atomicStore(i32, &self.running_flag, 0, .seq_cst);
    }
};

fn basename(path: []const u16) []const u16 {
    var start: usize = 0;
    for (path, 0..) |unit, i| if (unit == '\\' or unit == '/') {
        start = i + 1;
    };
    return path[start..];
}

fn eqlAsciiIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    if (wide.len != ascii.len) return false;
    for (wide, ascii) |a, b| {
        const lower_a = if (a >= 'A' and a <= 'Z') a + ('a' - 'A') else a;
        const lower_b = if (b >= 'A' and b <= 'Z') b + ('a' - 'A') else b;
        if (lower_a != lower_b) return false;
    }
    return true;
}

fn containsAsciiIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    if (ascii.len == 0 or ascii.len > wide.len) return false;
    var start: usize = 0;
    while (start + ascii.len <= wide.len) : (start += 1) {
        if (eqlAsciiIgnoreCase(wide[start .. start + ascii.len], ascii)) return true;
    }
    return false;
}

pub fn smokeCheck() bool {
    const projected = projectedPositionMs(1500, 10000, 500, true);
    const clamped = projectedPositionMs(9800, 10000, 1000, true);
    const paused = projectedPositionMs(1500, 10000, 500, false);
    const from_stopwatch = trackPositionFor(0, 0, 0, 2500, true);
    var current_path: [260]u16 = @splat(0);
    const current_path_len = GetModuleFileNameW(null, &current_path, current_path.len);
    var resolved_path: [260]u16 = @splat(0);
    if (current_path_len == 0 or current_path_len >= current_path.len or
        !executableFromAppId(current_path[0..current_path_len], &resolved_path)) return false;
    var rejected_path: [260]u16 = undefined;
    if (executableFromAppId(&.{ 'p', 'a', 'c', 'k', 'a', 'g', 'e', '!', 'A', 'p', 'p', '.', 'e', 'x', 'e' }, &rejected_path) or
        executableFromAppId(&.{ 'n', 'o', 't', 'a', 'p', 'p', '.', 'd', 'l', 'l' }, &rejected_path)) return false;
    return std.mem.eql(u16, current_path[0..current_path_len], wideZSlice(&resolved_path)) and
        projected == 2000 and clamped == 10000 and paused == 1500 and !sessionReportsTimeline(0, 0) and
        from_stopwatch.ms == 2500 and !from_stopwatch.from_session and playbackStateName(.playing).len == 7 and
        knownPlayerDisplayName(&.{ 'C', ':', '\\', 'c', 'l', 'o', 'u', 'd', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' }) != null and
        sessionScore(&.{ 'C', ':', '\\', 'A', 'p', 'p', 's', '\\', 'S', 'p', 'o', 't', 'i', 'f', 'y', '.', 'e', 'x', 'e' }, true) == 150 and
        sessionScore(&.{ 'c', 'h', 'r', 'o', 'm', 'e', '.', 'e', 'x', 'e' }, true) == -50 and
        shouldFetchArtwork(true, false, 0, 0) and !shouldFetchArtwork(false, false, 5000, 5000) and
        !shouldFetchArtwork(false, true, 999, 1000) and shouldFetchArtwork(false, true, 1000, 1000) and
        !shouldFetchArtwork(false, true, 1999, 20000) and shouldFetchArtwork(false, true, 2000, 20000) and
        nextPollIntervalMs(1000, 800, 0) == skip_poll_interval_ms and
        nextPollIntervalMs(8000, 1000, 0) == poll_interval_ms and
        nextPollIntervalMs(1000, 0, 1001) == poll_interval_ms;
}

const std = @import("std");
const Log = @import("Log");
const WicImage = @import("WicImage");
