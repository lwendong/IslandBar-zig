const std = @import("std");
const WicImage = @import("WicImage");

pub const StartApp = struct { name: [112]u16 = @splat(0), target: [512]u16 = @splat(0) };
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const HINSTANCE = ?*anyopaque;
const HWND = ?*anyopaque;
extern "shell32" fn ShellExecuteW(window: HWND, operation: ?[*:0]const u16, file: [*:0]const u16, parameters: ?[*:0]const u16, directory: ?[*:0]const u16, show: i32) callconv(.winapi) HINSTANCE;
extern "shell32" fn SHCreateItemFromParsingName(path: [*:0]const u16, bind_context: ?*anyopaque, iid: *const Guid, result: *?*anyopaque) callconv(.winapi) i32;
extern "shell32" fn SHCreateItemWithParent(parent_id_list: ?*anyopaque, parent_folder: *anyopaque, child_id_list: *anyopaque, iid: *const Guid, result: *?*anyopaque) callconv(.winapi) i32;
extern "shell32" fn SHGetIDListFromObject(object: *anyopaque, id_list: *?*anyopaque) callconv(.winapi) i32;
extern "ole32" fn CoTaskMemFree(memory: ?*anyopaque) callconv(.winapi) void;
extern "user32" fn GetShellWindow() callconv(.winapi) HWND;
extern "kernel32" fn CompareStringEx(locale_name: ?[*:0]const u16, flags: u32, first: [*:0]const u16, first_len: i32, second: [*:0]const u16, second_len: i32, version: ?*anyopaque, reserved: ?*anyopaque, sort_handle: isize) callconv(.winapi) i32;
extern "kernel32" fn GetModuleFileNameW(module: ?*anyopaque, path: [*]u16, size: u32) callconv(.winapi) u32;
extern "kernel32" fn CreateDirectoryW(path: [*:0]const u16, security: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn FindFirstFileW(pattern: [*:0]const u16, data: *FindDataW) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn FindNextFileW(search: ?*anyopaque, data: *FindDataW) callconv(.winapi) i32;
extern "kernel32" fn FindClose(search: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: u32, share: u32, security: ?*anyopaque, creation: u32, flags: u32, template: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetFileSizeEx(file: ?*anyopaque, size: *i64) callconv(.winapi) i32;
extern "kernel32" fn ReadFile(file: ?*anyopaque, buffer: [*]u8, count: u32, read: *u32, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn WriteFile(file: ?*anyopaque, buffer: [*]const u8, count: u32, written: *u32, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn MoveFileExW(existing: [*:0]const u16, replacement: [*:0]const u16, flags: u32) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn MultiByteToWideChar(code_page: u32, flags: u32, input: [*]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: u32, flags: u32, input: [*]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;
extern "ole32" fn CoCreateInstance(class_id: *const Guid, outer: ?*anyopaque, context: u32, iid: *const Guid, result: *?*anyopaque) callconv(.winapi) i32;
extern "ole32" fn PropVariantClear(value: *PropVariant) callconv(.winapi) i32;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, co_init: u32) callconv(.winapi) i32;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "shell32" fn SHFileOperationW(operation: *ShFileOperation) callconv(.winapi) i32;
extern "user32" fn GetDC(window: HWND) callconv(.winapi) ?*anyopaque;
extern "user32" fn ReleaseDC(window: HWND, dc: ?*anyopaque) callconv(.winapi) i32;
extern "gdi32" fn GetDIBits(dc: ?*anyopaque, bitmap: ?*anyopaque, start_scan: u32, lines: u32, bits: [*]u8, info: *BitmapInfo, usage: u32) callconv(.winapi) i32;
extern "gdi32" fn DeleteObject(object: ?*anyopaque) callconv(.winapi) i32;

const IID_SHELL_ITEM = Guid{ .data1 = 0x43826d1e, .data2 = 0xe718, .data3 = 0x42ee, .data4 = .{ 0xbc, 0x55, 0xa1, 0xe2, 0x61, 0xc3, 0x7b, 0xfe } };
const IID_SHELL_FOLDER = Guid{ .data1 = 0x000214e6, .data2 = 0x0000, .data3 = 0x0000, .data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
const IID_ENUM_ID_LIST = Guid{ .data1 = 0x000214f2, .data2 = 0x0000, .data3 = 0x0000, .data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
const CLSID_SHELL_LINK = Guid{ .data1 = 0x00021401, .data2 = 0x0000, .data3 = 0x0000, .data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
const IID_SHELL_LINK_W = Guid{ .data1 = 0x000214f9, .data2 = 0x0000, .data3 = 0x0000, .data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
const IID_PERSIST_FILE = Guid{ .data1 = 0x0000010b, .data2 = 0x0000, .data3 = 0x0000, .data4 = .{ 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 } };
const IID_SHELL_ITEM_IMAGE_FACTORY = Guid{ .data1 = 0xbcc18b79, .data2 = 0xba16, .data3 = 0x442f, .data4 = .{ 0x80, 0xc4, 0x8a, 0x59, 0xc3, 0x0c, 0x46, 0x3b } };
const IID_PROPERTY_STORE = Guid{ .data1 = 0x886d8eeb, .data2 = 0x8cf2, .data3 = 0x4446, .data4 = .{ 0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99 } };
const BHID_SF_OBJECT = Guid{ .data1 = 0x3981e224, .data2 = 0xf559, .data3 = 0x11d3, .data4 = .{ 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5 } };
const shell_user_locale: ?[*:0]const u16 = null;
const S_OK: i32 = 0;
const SIGDN_NORMAL_DISPLAY: i32 = 0;
const SIGDN_PARENT_RELATIVE_PARSING: i32 = @bitCast(@as(u32, 0x80018001));
const SHCONTF_FOLDERS: u32 = 0x20;
const SHCONTF_NONFOLDERS: u32 = 0x40;
const CSTR_LESS_THAN: i32 = 1;
const CSTR_GREATER_THAN: i32 = 3;
const MAX_PATH: usize = 260;
const GENERIC_READ: u32 = 0x80000000;
const GENERIC_WRITE: u32 = 0x40000000;
const FILE_SHARE_READ: u32 = 1;
const FILE_SHARE_WRITE: u32 = 2;
const OPEN_EXISTING: u32 = 3;
const CREATE_ALWAYS: u32 = 2;
const FILE_ATTRIBUTE_NORMAL: u32 = 0x80;
const FILE_ATTRIBUTE_DIRECTORY: u32 = 0x10;
const INVALID_HANDLE_VALUE: usize = std.math.maxInt(usize);
const CP_UTF8: u32 = 65001;
const MOVEFILE_REPLACE_EXISTING: u32 = 1;
const CLSCTX_INPROC_SERVER: u32 = 1;
const COINIT_APARTMENTTHREADED: u32 = 2;
const RPC_E_CHANGED_MODE: i32 = -2147417850;
const FO_DELETE: u32 = 3;
const FOF_SILENT: u16 = 0x0004;
const FOF_NOCONFIRMATION: u16 = 0x0010;
const FOF_ALLOWUNDO: u16 = 0x0040;
const FOF_NOERRORUI: u16 = 0x0400;

const ShFileOperation = extern struct {
    window: HWND,
    function: u32,
    from: [*:0]const u16,
    to: ?[*:0]const u16,
    flags: u16,
    any_operations_aborted: i32,
    name_mappings: ?*anyopaque,
    progress_title: ?[*:0]const u16,
};

const FileTime = extern struct { low: u32, high: u32 };
const FindDataW = extern struct {
    attributes: u32,
    creation_time: FileTime,
    last_access_time: FileTime,
    last_write_time: FileTime,
    size_high: u32,
    size_low: u32,
    reserved0: u32,
    reserved1: u32,
    file_name: [MAX_PATH]u16,
    alternate_name: [14]u16,
};
const PropertyKey = extern struct { format_id: Guid, property_id: u32 };
const PropVariant = extern struct { variant_type: u16 = 0, reserved: [3]u16 = .{ 0, 0, 0 }, data: [16]u8 = @splat(0) };
const BitmapInfoHeader = extern struct {
    size: u32,
    width: i32,
    height: i32,
    planes: u16,
    bit_count: u16,
    compression: u32,
    size_image: u32,
    x_pixels_per_meter: i32,
    y_pixels_per_meter: i32,
    colors_used: u32,
    colors_important: u32,
};
const BitmapInfo = extern struct { header: BitmapInfoHeader, color: u32 = 0 };
const BitmapSize = extern struct { width: i32, height: i32 };
const app_user_model_id_key = PropertyKey{
    .format_id = .{ .data1 = 0x9f4c2855, .data2 = 0x9f79, .data3 = 0x4b39, .data4 = .{ 0xa8, 0xd0, 0xe1, 0xd4, 0x2d, 0xe1, 0xd5, 0xf3 } },
    .property_id = 5,
};

const ComHeader = extern struct { vtable: [*]const ?*anyopaque };

fn comMethod(comptime T: type, object: *anyopaque, index: usize) T {
    const header: *const ComHeader = @ptrCast(@alignCast(object));
    return @ptrCast(header.vtable[index] orelse unreachable);
}

fn release(object: ?*anyopaque) void {
    if (object) |value| {
        const release_fn = comMethod(*const fn (*anyopaque) callconv(.winapi) u32, value, 2);
        _ = release_fn(value);
    }
}

fn copyWideZ(output: []u16, input: [*:0]const u16) void {
    if (output.len == 0) return;
    const length = std.mem.len(input);
    const count = @min(length, output.len - 1);
    @memcpy(output[0..count], input[0..count]);
    output[count] = 0;
}

fn compareApp(_: void, left: StartApp, right: StartApp) bool {
    const order = CompareStringEx(shell_user_locale, 0, @ptrCast(&left.name), -1, @ptrCast(&right.name), -1, null, null, 0);
    if (order == CSTR_LESS_THAN) return true;
    if (order == CSTR_GREATER_THAN) return false;
    return std.mem.order(u16, cWide(&left.target), cWide(&right.target)) == .lt;
}

fn readShellItem(item: *anyopaque, output: *StartApp) bool {
    const get_name = comMethod(*const fn (*anyopaque, i32, *?[*:0]u16) callconv(.winapi) i32, item, 5);
    var name: ?[*:0]u16 = null;
    var target: ?[*:0]u16 = null;
    const name_hr = get_name(item, SIGDN_NORMAL_DISPLAY, &name);
    const target_hr = get_name(item, SIGDN_PARENT_RELATIVE_PARSING, &target);
    defer {
        if (name) |value| CoTaskMemFree(value);
        if (target) |value| CoTaskMemFree(value);
    }
    if (name_hr < 0 or target_hr < 0 or name == null or target == null) return false;
    copyWideZ(&output.name, name.?);
    copyWideZ(&output.target, target.?);
    return output.name[0] != 0 and output.target[0] != 0;
}

fn pathJoin(output: []u16, left: []const u16, right: []const u16) ?usize {
    if (output.len == 0 or left.len + right.len + 2 > output.len) return null;
    @memset(output, 0);
    @memcpy(output[0..left.len], left);
    var used = left.len;
    if (used != 0 and output[used - 1] != '\\' and output[used - 1] != '/') {
        output[used] = '\\';
        used += 1;
    }
    @memcpy(output[used .. used + right.len], right);
    used += right.len;
    output[used] = 0;
    return used;
}

fn moduleDirectory(output: []u16) ?usize {
    if (output.len < 2) return null;
    @memset(output, 0);
    const length = GetModuleFileNameW(null, output.ptr, @intCast(@min(output.len, MAX_PATH)));
    if (length == 0 or length >= output.len) return null;
    var slash: ?usize = null;
    for (output[0..length], 0..) |unit, index| if (unit == '\\' or unit == '/') {
        slash = index + 1;
    };
    const end = slash orelse return null;
    output[end] = 0;
    return end;
}

fn utf8ToWide(input: []const u8, output: []u16) ?usize {
    if (output.len == 0) return null;
    @memset(output, 0);
    if (input.len == 0) return 0;
    const count = MultiByteToWideChar(CP_UTF8, 0, input.ptr, @intCast(input.len), output.ptr, @intCast(@min(output.len - 1, std.math.maxInt(i32))));
    if (count <= 0 or count >= output.len) return null;
    output[@intCast(count)] = 0;
    return @intCast(count);
}

fn readSettingLine(path: []const u16, output: []u16) bool {
    const file = CreateFileW(@ptrCast(path.ptr), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
    if (file == null or @intFromPtr(file.?) == INVALID_HANDLE_VALUE) return false;
    defer _ = CloseHandle(file);
    var size: i64 = 0;
    if (GetFileSizeEx(file, &size) == 0 or size < 0 or size >= 4096) return false;
    var bytes: [4096]u8 = @splat(0);
    var read: u32 = 0;
    if (ReadFile(file, &bytes, @intCast(size), &read, null) == 0) return false;
    var wide: [2048]u16 = @splat(0);
    const count = MultiByteToWideChar(CP_UTF8, 0, &bytes, @intCast(read), &wide, wide.len - 1);
    if (count <= 0) return false;
    var line_start: usize = 0;
    var all = wide[0..@intCast(count)];
    if (all.len != 0 and all[0] == 0xFEFF) all = all[1..];
    while (line_start < all.len) {
        var line_end = line_start;
        while (line_end < all.len and all[line_end] != '\n') : (line_end += 1) {}
        var first = line_start;
        var last = line_end;
        while (first < last and (all[first] == ' ' or all[first] == '\t' or all[first] == '\r')) : (first += 1) {}
        while (last > first and (all[last - 1] == ' ' or all[last - 1] == '\t' or all[last - 1] == '\r')) : (last -= 1) {}
        if (first < last and all[first] != '#') {
            const length = last - first;
            if (length >= output.len) return false;
            @memcpy(output[0..length], all[first..last]);
            output[length] = 0;
            return true;
        }
        line_start = line_end + 1;
    }
    return false;
}

fn writeDefaultSetting(path: []const u16, folder: []const u16) void {
    const file = CreateFileW(@ptrCast(path.ptr), GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
    if (file == null or @intFromPtr(file.?) == INVALID_HANDLE_VALUE) return;
    defer _ = CloseHandle(file);
    const prefix = "# IslandBar pinned applications folder. Change the path on the last line.\r\n# Put .lnk or .url shortcuts there; each filename becomes a tile name.\r\n";
    var written: u32 = 0;
    if (WriteFile(file, prefix.ptr, @intCast(prefix.len), &written, null) == 0 or written != prefix.len) return;
    var utf8: [1024]u8 = undefined;
    const byte_count = WideCharToMultiByte(CP_UTF8, 0, folder.ptr, @intCast(cWide(folder).len), &utf8, @intCast(utf8.len), null, null);
    if (byte_count > 0) {
        written = 0;
        _ = WriteFile(file, &utf8, @intCast(byte_count), &written, null);
        written = 0;
        _ = WriteFile(file, "\r\n".ptr, 2, &written, null);
    }
}

fn fileNameStem(name: []const u16) []const u16 {
    const filename = cWide(name);
    if (std.mem.lastIndexOfScalar(u16, filename, '.')) |dot| if (dot > 0) return filename[0..dot];
    return filename;
}

fn comparePinned(_: void, left: StartApp, right: StartApp) bool {
    const order = CompareStringEx(shell_user_locale, 0, @ptrCast(&left.name), -1, @ptrCast(&right.name), -1, null, null, 0);
    if (order == CSTR_LESS_THAN) return true;
    if (order == CSTR_GREATER_THAN) return false;
    return std.mem.order(u16, cWide(&left.target), cWide(&right.target)) == .lt;
}

fn createShortcut(folder: []const u16, name: []const u16, target: []const u16) bool {
    if (folder.len == 0 or name.len == 0 or target.len == 0) return false;
    var parsing: [600]u16 = @splat(0);
    const prefix = [_]u16{ 's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', '\\' };
    if (prefix.len + target.len >= parsing.len) return false;
    @memcpy(parsing[0..prefix.len], &prefix);
    @memcpy(parsing[prefix.len .. prefix.len + target.len], target);
    parsing[prefix.len + target.len] = 0;

    var item: ?*anyopaque = null;
    if (SHCreateItemFromParsingName(@ptrCast(&parsing), null, &IID_SHELL_ITEM, &item) < 0 or item == null) return false;
    defer release(item);
    var id_list: ?*anyopaque = null;
    if (SHGetIDListFromObject(item.?, &id_list) < 0 or id_list == null) return false;
    defer CoTaskMemFree(id_list);

    var link: ?*anyopaque = null;
    if (CoCreateInstance(&CLSID_SHELL_LINK, null, CLSCTX_INPROC_SERVER, &IID_SHELL_LINK_W, &link) < 0 or link == null) return false;
    defer release(link);
    const set_id_list = comMethod(*const fn (*anyopaque, ?*anyopaque) callconv(.winapi) i32, link.?, 5);
    if (set_id_list(link.?, id_list) < 0) return false;
    const set_description = comMethod(*const fn (*anyopaque, [*:0]const u16) callconv(.winapi) i32, link.?, 7);
    var description: [512]u16 = @splat(0);
    if (target.len >= description.len) return false;
    @memcpy(description[0..target.len], target);
    description[target.len] = 0;
    if (set_description(link.?, @ptrCast(&description)) < 0) return false;

    // Packaged applications need the same AppUserModelID property their Start-menu shortcut carries.
    if (std.mem.indexOfScalar(u16, target, '!') != null) {
        const query_store = comMethod(*const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) i32, link.?, 0);
        var store: ?*anyopaque = null;
        if (query_store(link.?, &IID_PROPERTY_STORE, &store) >= 0 and store != null) {
            var value = PropVariant{};
            value.variant_type = 31; // VT_LPWSTR
            const value_pointer: *?[*:0]const u16 = @ptrCast(@alignCast(&value.data));
            value_pointer.* = @ptrCast(&description);
            const set_value = comMethod(*const fn (*anyopaque, *const PropertyKey, *const PropVariant) callconv(.winapi) i32, store.?, 6);
            const commit = comMethod(*const fn (*anyopaque) callconv(.winapi) i32, store.?, 7);
            if (set_value(store.?, &app_user_model_id_key, &value) >= 0) _ = commit(store.?);
            _ = PropVariantClear(&value);
            release(store);
        }
    }

    const query = comMethod(*const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) i32, link.?, 0);
    var persist: ?*anyopaque = null;
    if (query(link.?, &IID_PERSIST_FILE, &persist) < 0 or persist == null) return false;
    defer release(persist);

    var shortcut_name: [128]u16 = @splat(0);
    if (name.len + 4 >= shortcut_name.len) return false;
    @memcpy(shortcut_name[0..name.len], name);
    const suffix = [_]u16{ '.', 'l', 'n', 'k' };
    @memcpy(shortcut_name[name.len .. name.len + 4], &suffix);
    shortcut_name[name.len + 4] = 0;
    var path: [MAX_PATH]u16 = @splat(0);
    const path_len = pathJoin(&path, folder, cWide(&shortcut_name)) orelse return false;
    const save = comMethod(*const fn (*anyopaque, [*:0]const u16, i32) callconv(.winapi) i32, persist.?, 6);
    return save(persist.?, @ptrCast(&path), 1) >= 0 and path_len != 0;
}

fn recycleFile(path: []const u16) bool {
    if (path.len == 0 or path.len + 2 > MAX_PATH + 2) return false;
    var from: [MAX_PATH + 2]u16 = @splat(0);
    @memcpy(from[0..path.len], path);
    from[path.len] = 0;
    from[path.len + 1] = 0;
    var operation = ShFileOperation{
        .window = null,
        .function = FO_DELETE,
        .from = @ptrCast(&from),
        .to = null,
        .flags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_SILENT,
        .any_operations_aborted = 0,
        .name_mappings = null,
        .progress_title = null,
    };
    return SHFileOperationW(&operation) == 0;
}

pub fn pinsFolderSettingPath(output: []u16) bool {
    const directory_end = moduleDirectory(output) orelse return false;
    const filename = [_]u16{ 's', 't', 'a', 'r', 't', '_', 'f', 'o', 'l', 'd', 'e', 'r', '.', 't', 'x', 't' };
    if (directory_end + filename.len >= output.len) return false;
    @memcpy(output[directory_end .. directory_end + filename.len], &filename);
    output[directory_end + filename.len] = 0;
    return true;
}

pub fn pinsFolderPath(output: []u16) bool {
    if (output.len == 0) return false;
    @memset(output, 0);
    var setting: [MAX_PATH]u16 = @splat(0);
    if (!pinsFolderSettingPath(&setting)) return false;
    if (readSettingLine(cWide(&setting), output)) return true;

    const directory_end = moduleDirectory(output) orelse return false;
    const folder = [_]u16{ 'S', 't', 'a', 'r', 't' };
    if (directory_end + folder.len >= output.len) return false;
    @memcpy(output[directory_end .. directory_end + folder.len], &folder);
    output[directory_end + folder.len] = 0;
    writeDefaultSetting(cWide(&setting), output[0 .. directory_end + folder.len]);
    return true;
}

fn migrateLegacyPins(folder: []const u16) void {
    var module_dir: [MAX_PATH]u16 = @splat(0);
    const dir_len = moduleDirectory(&module_dir) orelse return;
    var legacy_path: [MAX_PATH]u16 = @splat(0);
    if (pathJoin(&legacy_path, module_dir[0..dir_len], &.{ 's', 't', 'a', 'r', 't', '_', 'p', 'i', 'n', 's', '.', 't', 'x', 't' }) == null) return;
    const file = CreateFileW(@ptrCast(&legacy_path), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
    if (file == null or @intFromPtr(file.?) == INVALID_HANDLE_VALUE) return;
    var bytes: [64 * 1024]u8 = undefined;
    var read: u32 = 0;
    const read_ok = ReadFile(file, &bytes, @intCast(bytes.len), &read, null) != 0;
    _ = CloseHandle(file);
    if (!read_ok or read == 0) return;

    var wide: [32 * 1024]u16 = @splat(0);
    const count = MultiByteToWideChar(CP_UTF8, 0, &bytes, @intCast(read), &wide, @intCast(wide.len - 1));
    if (count <= 0) return;
    var lines = wide[0..@intCast(count)];
    if (lines.len != 0 and lines[0] == 0xFEFF) lines = lines[1..];
    var start: usize = 0;
    while (start < lines.len) {
        var end = start;
        while (end < lines.len and lines[end] != '\n') : (end += 1) {}
        var line_end = end;
        while (line_end > start and (lines[line_end - 1] == '\r' or lines[line_end - 1] == ' ' or lines[line_end - 1] == '\t')) : (line_end -= 1) {}
        if (line_end > start and lines[start] != '#') {
            const line = lines[start..line_end];
            const bar = std.mem.indexOfScalar(u16, line, '|');
            const name = if (bar) |separator| line[0..separator] else line;
            const target = if (bar) |separator| line[separator + 1 ..] else line;
            var filename: [128]u16 = @splat(0);
            const filename_len = sanitizePinName(name, &filename);
            if (filename_len != 0) _ = createShortcut(folder, filename[0..filename_len], target);
        }
        start = end + 1;
    }

    var retired: [MAX_PATH]u16 = @splat(0);
    const legacy_len = cWide(&legacy_path).len;
    const suffix = [_]u16{ '.', 'm', 'i', 'g', 'r', 'a', 't', 'e', 'd' };
    if (legacy_len + suffix.len < retired.len) {
        @memcpy(retired[0..legacy_len], legacy_path[0..legacy_len]);
        @memcpy(retired[legacy_len .. legacy_len + suffix.len], &suffix);
        retired[legacy_len + suffix.len] = 0;
        _ = MoveFileExW(@ptrCast(&legacy_path), @ptrCast(&retired), MOVEFILE_REPLACE_EXISTING);
    }
}

pub const StartApps = struct {
    list: std.ArrayList(StartApp) = .empty,
    pins: std.ArrayList(StartApp) = .empty,
    pin_icons: std.ArrayList([]u8) = .empty,
    icon_threads: std.ArrayList(std.Thread) = .empty,
    icon_mutex: std.atomic.Mutex = .unlocked,
    allocator: std.mem.Allocator = std.heap.page_allocator,
    revision: u64 = 1,
    icon_revision: u64 = 1,
    pins_folder: [MAX_PATH]u16 = @splat(0),

    pub fn deinit(self: *StartApps) void {
        self.joinIconWorkers();
        for (self.pin_icons.items) |icon| if (icon.len != 0) self.allocator.free(icon);
        self.pin_icons.deinit(self.allocator);
        self.icon_threads.deinit(self.allocator);
        self.list.deinit(self.allocator);
        self.pins.deinit(self.allocator);
        self.* = .{};
    }

    /// Reads the same AppsFolder items that Windows presents in its All Apps list.
    /// Shell COM enumeration is intentionally done on demand; it can take hundreds of milliseconds.
    pub fn refreshList(self: *StartApps) i32 {
        self.list.clearRetainingCapacity();

        const parsing_name: [*:0]const u16 = &.{ 's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', 0 };
        var folder_item: ?*anyopaque = null;
        if (SHCreateItemFromParsingName(parsing_name, null, &IID_SHELL_ITEM, &folder_item) < 0 or folder_item == null) return 0;
        defer release(folder_item);

        const bind = comMethod(*const fn (*anyopaque, ?*anyopaque, *const Guid, *const Guid, *?*anyopaque) callconv(.winapi) i32, folder_item.?, 3);
        var folder: ?*anyopaque = null;
        if (bind(folder_item.?, null, &BHID_SF_OBJECT, &IID_SHELL_FOLDER, &folder) < 0 or folder == null) return 0;
        defer release(folder);

        const enumerate = comMethod(*const fn (*anyopaque, HWND, u32, *?*anyopaque) callconv(.winapi) i32, folder.?, 4);
        var enumerator: ?*anyopaque = null;
        if (enumerate(folder.?, GetShellWindow(), SHCONTF_FOLDERS | SHCONTF_NONFOLDERS, &enumerator) < 0 or enumerator == null) return 0;
        defer release(enumerator);

        const next = comMethod(*const fn (*anyopaque, u32, *?*anyopaque, ?*u32) callconv(.winapi) i32, enumerator.?, 3);
        while (true) {
            var child: ?*anyopaque = null;
            if (next(enumerator.?, 1, &child, null) != S_OK or child == null) break;
            defer CoTaskMemFree(child);
            var item: ?*anyopaque = null;
            if (SHCreateItemWithParent(null, folder.?, child.?, &IID_SHELL_ITEM, &item) < 0 or item == null) continue;
            defer release(item);
            var app = StartApp{};
            if (!readShellItem(item.?, &app)) continue;
            self.list.append(self.allocator, app) catch break;
        }

        std.mem.sort(StartApp, self.list.items, {}, compareApp);
        self.revision +%= 1;
        return @intCast(self.list.items.len);
    }

    pub fn listCount(self: *const StartApps) i32 {
        return @intCast(self.list.items.len);
    }

    pub fn listAt(self: *const StartApps, index: usize) ?*const StartApp {
        return if (index < self.list.items.len) &self.list.items[index] else null;
    }

    pub fn revisionValue(self: *const StartApps) u64 {
        return self.revision;
    }

    pub fn loadPins(self: *StartApps) void {
        if (!pinsFolderPath(&self.pins_folder)) return;
        _ = CreateDirectoryW(@ptrCast(&self.pins_folder), null);
        migrateLegacyPins(cWide(&self.pins_folder));
        self.readPinsFolder(cWide(&self.pins_folder));
    }

    fn collectPinFiles(self: *StartApps, folder: []const u16, extension: []const u16) void {
        var pattern: [MAX_PATH]u16 = @splat(0);
        const pattern_len = pathJoin(&pattern, folder, extension) orelse return;
        var data: FindDataW = undefined;
        const search = FindFirstFileW(@ptrCast(&pattern), &data);
        if (search == null or @intFromPtr(search.?) == INVALID_HANDLE_VALUE) return;
        defer _ = FindClose(search);
        while (true) {
            if ((data.attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
                var app = StartApp{};
                const name = cWide(&data.file_name);
                const stem_name = fileNameStem(name);
                if (stem_name.len < app.name.len) {
                    @memcpy(app.name[0..stem_name.len], stem_name);
                    var full_path: [MAX_PATH]u16 = @splat(0);
                    if (pathJoin(&full_path, folder, name)) |length| {
                        if (length < app.target.len) {
                            @memcpy(app.target[0..length], full_path[0..length]);
                            self.pins.append(self.allocator, app) catch return;
                        }
                    }
                }
            }
            if (FindNextFileW(search, &data) == 0) break;
        }
        _ = pattern_len;
    }

    fn readPinsFolder(self: *StartApps, folder: []const u16) void {
        self.joinIconWorkers();
        for (self.pin_icons.items) |icon| if (icon.len != 0) self.allocator.free(icon);
        self.pin_icons.clearRetainingCapacity();
        self.pins.clearRetainingCapacity();
        self.collectPinFiles(folder, &.{ '*', '.', 'l', 'n', 'k' });
        self.collectPinFiles(folder, &.{ '*', '.', 'u', 'r', 'l' });
        std.mem.sort(StartApp, self.pins.items, {}, comparePinned);
        for (self.pins.items) |_| self.pin_icons.append(self.allocator, &.{}) catch break;
        self.revision +%= 1;
        for (self.pins.items) |pin_item| {
            const thread = std.Thread.spawn(.{}, resolveIconWorker, .{ self, pin_item.target }) catch continue;
            self.icon_threads.append(self.allocator, thread) catch thread.join();
        }
    }

    fn joinIconWorkers(self: *StartApps) void {
        for (self.icon_threads.items) |thread| thread.join();
        self.icon_threads.clearRetainingCapacity();
    }

    fn lockIcons(self: *StartApps) void {
        while (!self.icon_mutex.tryLock()) std.atomic.spinLoopHint();
    }

    fn resolveIconWorker(self: *StartApps, target: [512]u16) void {
        const com_result = CoInitializeEx(null, COINIT_APARTMENTTHREADED);
        defer if (com_result >= 0) CoUninitialize();
        if (com_result < 0 and com_result != RPC_E_CHANGED_MODE) return;
        var png: [16 * 1024]u8 = @splat(0);
        const length = startAppIconPng(cWide(&target), 32, &png);
        if (length == 0) return;
        const owned = self.allocator.dupe(u8, png[0..length]) catch return;
        self.lockIcons();
        defer self.icon_mutex.unlock();
        for (self.pins.items, 0..) |pin_item, index| {
            if (std.mem.eql(u16, cWide(&pin_item.target), cWide(&target)) and index < self.pin_icons.items.len) {
                if (self.pin_icons.items[index].len != 0) self.allocator.free(self.pin_icons.items[index]);
                self.pin_icons.items[index] = owned;
                self.icon_revision +%= 1;
                return;
            }
        }
        self.allocator.free(owned);
    }

    pub fn pinCount(self: *const StartApps) i32 {
        return @intCast(self.pins.items.len);
    }

    pub fn pinAt(self: *const StartApps, index: usize) ?*const StartApp {
        return if (index < self.pins.items.len) &self.pins.items[index] else null;
    }

    pub fn pin(self: *StartApps, target: []const u16, name: []const u16) bool {
        if (target.len == 0 or name.len == 0 or cWide(&self.pins_folder).len == 0) return false;
        var safe_name: [128]u16 = @splat(0);
        const length = sanitizePinName(name, &safe_name);
        if (length == 0 or !createShortcut(cWide(&self.pins_folder), safe_name[0..length], target)) return false;
        self.readPinsFolder(cWide(&self.pins_folder));
        return true;
    }

    pub fn unpin(self: *StartApps, index: usize) bool {
        if (index >= self.pins.items.len) return false;
        if (!recycleFile(cWide(&self.pins.items[index].target))) return false;
        self.readPinsFolder(cWide(&self.pins_folder));
        return true;
    }

    pub fn pinIconPng(self: *StartApps, index: usize, size_out: ?*usize) ?[]const u8 {
        self.lockIcons();
        defer self.icon_mutex.unlock();
        if (size_out) |size| size.* = 0;
        if (index >= self.pin_icons.items.len) return null;
        const icon = self.pin_icons.items[index];
        if (icon.len == 0) return null;
        if (size_out) |size| size.* = icon.len;
        return icon;
    }

    /// Copies an icon while holding the worker lock so callers can safely keep the bytes
    /// after an icon-resolution worker replaces the cached pin image.
    pub fn copyPinIconPng(self: *StartApps, index: usize, output: []u8) usize {
        self.lockIcons();
        defer self.icon_mutex.unlock();
        if (index >= self.pin_icons.items.len or output.len == 0) return 0;
        const icon = self.pin_icons.items[index];
        const count = @min(icon.len, output.len);
        @memcpy(output[0..count], icon[0..count]);
        return count;
    }

    pub fn iconRevision(self: *const StartApps) u64 {
        return self.icon_revision;
    }
};

pub fn sanitizePinName(name: []const u16, output: []u16) usize {
    if (output.len == 0) return 0;
    var written: usize = 0;
    for (name) |unit| {
        if (unit == 0) break;
        if (written + 1 >= output.len) break;
        output[written] = switch (unit) {
            '\\', '/', ':', '*', '?', '"', '<', '>', '|' => '_',
            else => unit,
        };
        written += 1;
    }
    if (written == 0 and output.len >= 9) {
        output[0] = 'S';
        output[1] = 'h';
        output[2] = 'o';
        output[3] = 'r';
        output[4] = 't';
        output[5] = 'c';
        output[6] = 'u';
        output[7] = 't';
        written = 8;
    }
    output[written] = 0;
    return written;
}

pub fn stem(path_arg: []const u16) []const u16 {
    const path = cWide(path_arg);
    var start: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        start = index + 1;
    };
    const leaf = path[start..];
    if (std.mem.lastIndexOfScalar(u16, leaf, '.')) |dot| if (dot > 0) return leaf[0..dot];
    return leaf;
}

pub fn launchStartApp(target: [*:0]const u16) bool {
    const input = cWide(std.mem.span(target));
    var parsing: [600]u16 = @splat(0);
    const has_path = std.mem.indexOf(u16, input, &.{ ':', '\\' }) != null or std.mem.indexOf(u16, input, &.{ 's', 'h', 'e', 'l', 'l', ':' }) != null;
    var length: usize = 0;
    if (has_path) {
        length = @min(input.len, parsing.len - 1);
        @memcpy(parsing[0..length], input[0..length]);
    } else {
        const prefix = [_]u16{ 's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', '\\' };
        @memcpy(parsing[0..prefix.len], &prefix);
        length = prefix.len + @min(input.len, parsing.len - prefix.len - 1);
        @memcpy(parsing[prefix.len..length], input[0 .. length - prefix.len]);
    }
    parsing[length] = 0;
    const result = ShellExecuteW(null, &.{ 'o', 'p', 'e', 'n', 0 }, @ptrCast(&parsing), null, null, 1);
    return if (result) |handle| @intFromPtr(handle) > 32 else false;
}

/// Extracts a shell item's icon and encodes it as a transparent PNG.
/// `target` may be an AppsFolder name or a filesystem shortcut path.
pub fn startAppIconPng(target: []const u16, side: i32, output: []u8) usize {
    if (target.len == 0 or side <= 0 or output.len == 0) return 0;
    var parsing: [600]u16 = @splat(0);
    const is_drive_path = target.len >= 3 and target[1] == ':' and (target[2] == '\\' or target[2] == '/');
    const is_unc_path = target.len >= 2 and target[0] == '\\' and target[1] == '\\';
    const has_shell_prefix = std.mem.startsWith(u16, target, &.{ 's', 'h', 'e', 'l', 'l', ':' });
    var parsing_len: usize = 0;
    if (is_drive_path or is_unc_path or has_shell_prefix) {
        if (target.len >= parsing.len) return 0;
        @memcpy(parsing[0..target.len], target);
        parsing_len = target.len;
    } else {
        const prefix = [_]u16{ 's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', '\\' };
        if (prefix.len + target.len >= parsing.len) return 0;
        @memcpy(parsing[0..prefix.len], &prefix);
        @memcpy(parsing[prefix.len .. prefix.len + target.len], target);
        parsing_len = prefix.len + target.len;
    }
    parsing[parsing_len] = 0;

    var item: ?*anyopaque = null;
    if (SHCreateItemFromParsingName(@ptrCast(&parsing), null, &IID_SHELL_ITEM, &item) < 0 or item == null) return 0;
    defer release(item);
    const query = comMethod(*const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) i32, item.?, 0);
    var image_factory: ?*anyopaque = null;
    if (query(item.?, &IID_SHELL_ITEM_IMAGE_FACTORY, &image_factory) < 0 or image_factory == null) return 0;
    defer release(image_factory);
    const get_image = comMethod(*const fn (*anyopaque, BitmapSize, u32, *?*anyopaque) callconv(.winapi) i32, image_factory.?, 3);
    var bitmap: ?*anyopaque = null;
    if (get_image(image_factory.?, .{ .width = side, .height = side }, 0x04, &bitmap) < 0 or bitmap == null) return 0;
    defer _ = DeleteObject(bitmap);

    const width: usize = @intCast(side);
    const pixel_count = std.math.mul(usize, width, width) catch return 0;
    const byte_count = std.math.mul(usize, pixel_count, 4) catch return 0;
    const pixels = std.heap.page_allocator.alloc(u8, byte_count) catch return 0;
    defer std.heap.page_allocator.free(pixels);
    @memset(pixels, 0);
    var info = BitmapInfo{
        .header = .{
            .size = @sizeOf(BitmapInfoHeader),
            .width = side,
            .height = -side,
            .planes = 1,
            .bit_count = 32,
            .compression = 0,
            .size_image = @intCast(byte_count),
            .x_pixels_per_meter = 0,
            .y_pixels_per_meter = 0,
            .colors_used = 0,
            .colors_important = 0,
        },
    };
    const screen = GetDC(null) orelse return 0;
    defer _ = ReleaseDC(null, screen);
    if (GetDIBits(screen, bitmap, 0, @intCast(side), pixels.ptr, &info, 0) == 0) return 0;
    return WicImage.encodeBgraToPng(pixels, side, side, output);
}

fn cWide(input: []const u16) []const u16 {
    return input[0 .. std.mem.indexOfScalar(u16, input, 0) orelse input.len];
}

pub fn smokeCheck() bool {
    compileCheck(false);
    var clean: [32]u16 = @splat(0);
    const length = sanitizePinName(&.{ 'A', '/', 'B', 0 }, &clean);
    return length == 3 and clean[0] == 'A' and clean[1] == '_' and clean[2] == 'B' and
        std.mem.eql(u16, stem(&.{ 'C', ':', '\\', 'a', '.', 'l', 'n', 'k', 0 }), &.{'a'});
}

/// Keeps the Windows-backed API bodies type-checked as part of the ordinary build.
/// `execute` is false in the self-test so no shell window is opened.
pub fn compileCheck(execute: bool) void {
    var apps = StartApps{};
    defer apps.deinit();
    if (execute) {
        _ = apps.refreshList();
        apps.loadPins();
        _ = apps.pin(&.{ 'x', 0 }, &.{ 'x', 0 });
        _ = apps.unpin(0);
        var path: [MAX_PATH]u16 = @splat(0);
        _ = pinsFolderSettingPath(&path);
        _ = pinsFolderPath(&path);
    }
    _ = apps.listCount();
    _ = apps.listAt(0);
    _ = apps.pinCount();
    _ = apps.pinAt(0);
    _ = apps.pinIconPng(0, null);
    _ = apps.revisionValue();
    _ = apps.iconRevision();
    if (execute) {
        var png: [16 * 1024]u8 = @splat(0);
        _ = startAppIconPng(&.{ 'n', 'o', 't', '-', 'a', '-', 'r', 'e', 'a', 'l', '-', 'a', 'p', 'p', 0 }, 32, &png);
    }
}
