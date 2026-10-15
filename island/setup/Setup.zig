const std = @import("std");

pub const Options = struct {
    uninstall: bool = false,
    autostart: bool = true,
    launch: bool = true,
    remove_settings: bool = false,
    silent: bool = false,
    help: bool = false,
    directory: ?[]const u16 = null,
};

pub fn parseArguments(arguments: []const []const u16) Options {
    var options: Options = .{};
    for (arguments) |argument| {
        if (eqlAsciiIgnoreCase(argument, "/uninstall") or eqlAsciiIgnoreCase(argument, "-uninstall")) {
            options.uninstall = true;
        } else if (eqlAsciiIgnoreCase(argument, "/remove-settings")) {
            options.remove_settings = true;
        } else if (eqlAsciiIgnoreCase(argument, "/no-autostart")) {
            options.autostart = false;
        } else if (eqlAsciiIgnoreCase(argument, "/no-launch")) {
            options.launch = false;
        } else if (eqlAsciiIgnoreCase(argument, "/silent")) {
            options.silent = true;
        } else if (eqlAsciiIgnoreCase(argument, "/?") or eqlAsciiIgnoreCase(argument, "/help")) {
            options.help = true;
        } else if (startsWithAsciiIgnoreCase(argument, "/dir=")) {
            options.directory = trimTrailingSlash(argument[5..]);
        }
    }
    return options;
}

pub fn appendProfilePath(profile: []const u16, leaf: []const u16, output: []u16) usize {
    if (output.len == 0) return 0;
    var used: usize = 0;
    const base = trimTrailingSlash(profile);
    const needed = base.len + @intFromBool(base.len != 0) + leaf.len;
    if (needed >= output.len) return 0;
    @memcpy(output[0..base.len], base);
    used = base.len;
    if (used != 0) {
        output[used] = '\\';
        used += 1;
    }
    @memcpy(output[used .. used + leaf.len], leaf);
    used += leaf.len;
    output[used] = 0;
    return used;
}

fn trimTrailingSlash(value: []const u16) []const u16 {
    var end = value.len;
    if (std.mem.indexOfScalar(u16, value, 0)) |nul| end = nul;
    while (end > 0 and (value[end - 1] == '\\' or value[end - 1] == '/')) : (end -= 1) {}
    return value[0..end];
}

fn startsWithAsciiIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    if (wide.len < ascii.len) return false;
    return eqlAsciiIgnoreCase(wide[0..ascii.len], ascii);
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

pub fn smokeCheck() bool {
    const options = parseArguments(&.{ &.{ '/', 'n', 'o', '-', 'l', 'a', 'u', 'n', 'c', 'h' }, &.{ '/', 'd', 'i', 'r', '=', 'C', ':', '\\', '\\' }, &.{ '/', 's', 'i', 'l', 'e', 'n', 't' } });
    var path: [64]u16 = undefined;
    const path_len = appendProfilePath(&.{ 'C', ':', '\\' }, &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r' }, &path);
    return !options.launch and options.silent and options.directory != null and path_len == 12 and
        std.mem.eql(u16, path[0..path_len], &.{ 'C', ':', '\\', 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r' });
}

// The installer is deliberately implemented in Zig rather than shelling out to
// PowerShell or an MSI framework. The setup target embeds the exact IslandBar.exe
// produced by the same build graph and uses only per-user locations and HKCU.
const DWORD = u32;
const BOOL = i32;
const HANDLE = ?*anyopaque;
const HKEY = HANDLE;
const HRESULT = i32;
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const ProcessEntry32W = extern struct {
    size: DWORD,
    usage: DWORD,
    process_id: DWORD,
    default_heap_id: usize,
    module_id: DWORD,
    thread_count: DWORD,
    parent_process_id: DWORD,
    base_priority: i32,
    flags: DWORD,
    exe_file: [260]u16,
};
const ShellExecuteInfoW = extern struct {
    cb_size: DWORD,
    mask: DWORD,
    window: HANDLE,
    verb: ?[*:0]const u16,
    file: ?[*:0]const u16,
    parameters: ?[*:0]const u16,
    directory: ?[*:0]const u16,
    show: i32,
    instance: HANDLE,
    id_list: HANDLE,
    class: ?[*:0]const u16,
    class_key: HKEY,
    hot_key: DWORD,
    icon_or_monitor: HANDLE,
    process: HANDLE,
};
const ShFileOperationW = extern struct {
    window: HANDLE,
    operation: u32,
    from: [*:0]const u16,
    to: ?[*:0]const u16,
    flags: u16,
    aborted: BOOL,
    name_mappings: HANDLE,
    progress_title: ?[*:0]const u16,
};

extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn GetCommandLineW() callconv(.winapi) [*:0]const u16;
extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetTempPathW(size: DWORD, path: [*]u16) callconv(.winapi) DWORD;
extern "kernel32" fn GetEnvironmentVariableW(name: [*:0]const u16, value: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn LocalFree(memory: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: DWORD, share: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn WriteFile(file: HANDLE, bytes: [*]const u8, length: DWORD, written: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(file: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn DeleteFileW(path: [*:0]const u16) callconv(.winapi) BOOL;
extern "kernel32" fn CreateDirectoryW(path: [*:0]const u16, security: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn RemoveDirectoryW(path: [*:0]const u16) callconv(.winapi) BOOL;
extern "kernel32" fn GetFileAttributesW(path: [*:0]const u16) callconv(.winapi) DWORD;
extern "kernel32" fn GetFileAttributesExW(path: [*:0]const u16, level: DWORD, info: *FileAttributeData) callconv(.winapi) BOOL;
extern "kernel32" fn MoveFileExW(from: [*:0]const u16, to: ?[*:0]const u16, flags: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn CopyFileW(from: [*:0]const u16, to: [*:0]const u16, fail_if_exists: BOOL) callconv(.winapi) BOOL;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, length: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn TerminateProcess(process: HANDLE, exit_code: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn CreateToolhelp32Snapshot(flags: DWORD, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Process32FirstW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn Process32NextW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn OutputDebugStringW(text: [*:0]const u16) callconv(.winapi) void;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*]const u16, input_len: i32, output: [*]u8, output_len: i32, default_char: ?[*:0]const u8, used_default: ?*BOOL) callconv(.winapi) i32;
extern "user32" fn MessageBoxW(window: HANDLE, text: [*:0]const u16, caption: [*:0]const u16, flags: u32) callconv(.winapi) i32;
extern "user32" fn FindWindowW(class_name: [*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "user32" fn FindWindowExW(parent: HANDLE, after: HANDLE, class_name: [*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "user32" fn IsWindowVisible(window: HANDLE) callconv(.winapi) BOOL;
extern "user32" fn ShowWindow(window: HANDLE, command: i32) callconv(.winapi) BOOL;
extern "kernel32" fn CompareStringOrdinal(a: [*]const u16, a_length: i32, b: [*]const u16, b_length: i32, ignore_case: BOOL) callconv(.winapi) i32;
extern "shell32" fn SHGetKnownFolderPath(folder: *const Guid, flags: DWORD, token: HANDLE, path: *?[*:0]u16) callconv(.winapi) HRESULT;
extern "shell32" fn SHFileOperationW(operation: *ShFileOperationW) callconv(.winapi) i32;
extern "shell32" fn ShellExecuteExW(info: *ShellExecuteInfoW) callconv(.winapi) BOOL;
extern "shell32" fn CommandLineToArgvW(command_line: [*:0]const u16, argc: *i32) callconv(.winapi) ?[*][*:0]u16;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, model: DWORD) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoTaskMemFree(memory: ?*anyopaque) callconv(.winapi) void;
extern "ole32" fn CoCreateInstance(class_id: *const Guid, outer: HANDLE, context: DWORD, iid: *const Guid, object: *HANDLE) callconv(.winapi) HRESULT;
extern "advapi32" fn RegCreateKeyExW(root: HKEY, subkey: [*:0]const u16, reserved: DWORD, class_name: ?[*:0]u16, options: DWORD, access: DWORD, security: ?*anyopaque, result: *HKEY, disposition: ?*DWORD) callconv(.winapi) DWORD;
extern "advapi32" fn RegSetValueExW(key: HKEY, name: [*:0]const u16, reserved: DWORD, kind: DWORD, data: [*]const u8, size: DWORD) callconv(.winapi) DWORD;
extern "advapi32" fn RegCloseKey(key: HKEY) callconv(.winapi) DWORD;
extern "advapi32" fn RegOpenKeyExW(root: HKEY, subkey: [*:0]const u16, options: DWORD, access: DWORD, result: *HKEY) callconv(.winapi) DWORD;
extern "advapi32" fn RegDeleteTreeW(root: HKEY, subkey: [*:0]const u16) callconv(.winapi) DWORD;

const FileAttributeData = extern struct { attributes: DWORD, creation_low: DWORD, creation_high: DWORD, access_low: DWORD, access_high: DWORD, write_low: DWORD, write_high: DWORD, size_high: DWORD, size_low: DWORD };

const invalid_handle = std.math.maxInt(usize);
const generic_write: DWORD = 0x40000000;
const file_share_read: DWORD = 1;
const create_always: DWORD = 2;
const file_attribute_normal: DWORD = 0x80;
const movefile_replace_existing: DWORD = 1;
const movefile_write_through: DWORD = 8;
const movefile_delay_until_reboot: DWORD = 4;
const error_already_exists: DWORD = 183;
const error_file_not_found: DWORD = 2;
const error_path_not_found: DWORD = 3;
const th32cs_snapprocess: DWORD = 2;
const process_query_limited_information: DWORD = 0x1000;
const process_terminate: DWORD = 1;
const synchronize: DWORD = 0x00100000;
const sw_show: i32 = 5;
const clsctx_inproc_server: DWORD = 1;
const reg_option_non_volatile: DWORD = 0;
const key_write: DWORD = 0x20006;
const key_read: DWORD = 0x20019;
const reg_sz: DWORD = 1;
const reg_dword: DWORD = 4;
const fo_delete: u32 = 3;
const fof_allow_undo: u16 = 0x0040;
const fof_no_confirmation: u16 = 0x0010;
const fof_silent: u16 = 0x0004;
const fof_no_error_ui: u16 = 0x0400;
const see_mask_no_close_process: DWORD = 0x40;
const see_mask_flag_no_ui: DWORD = 0x400;
const sw_shownormal: i32 = 1;
const cp_utf8: DWORD = 65001;
const hkey_current_user: HKEY = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2147483647))));

const app_name = std.unicode.utf8ToUtf16LeStringLiteral("IslandBar");
const program_name = std.unicode.utf8ToUtf16LeStringLiteral("island_bar.exe");
const uninstaller_name = std.unicode.utf8ToUtf16LeStringLiteral("IslandBarUninstall.exe");
const startup_link_name = std.unicode.utf8ToUtf16LeStringLiteral("IslandBar.lnk");
const menu_link_name = std.unicode.utf8ToUtf16LeStringLiteral("IslandBar.lnk");
const safe_link_name = std.unicode.utf8ToUtf16LeStringLiteral("IslandBar (safe mode).lnk");
const version_text = std.unicode.utf8ToUtf16LeStringLiteral("1.2");
const uninstall_key = std.unicode.utf8ToUtf16LeStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\IslandBar");
const settings_key = std.unicode.utf8ToUtf16LeStringLiteral("Software\\IslandBar");
const uninstall_caption = std.unicode.utf8ToUtf16LeStringLiteral("IslandBar setup");
const startup_folder_id = Guid{ .data1 = 0xB97D20BB, .data2 = 0xF46A, .data3 = 0x4C97, .data4 = .{ 0xBA, 0x10, 0x5E, 0x36, 0x08, 0x43, 0x08, 0x54 } };
const programs_folder_id = Guid{ .data1 = 0xA77F5D77, .data2 = 0x2E2B, .data3 = 0x44C3, .data4 = .{ 0xA6, 0xA2, 0xAB, 0xA6, 0x01, 0x05, 0x4A, 0x51 } };
const profile_folder_id = Guid{ .data1 = 0x5E6C858F, .data2 = 0x0E22, .data3 = 0x4760, .data4 = .{ 0x9A, 0xFE, 0xEA, 0x33, 0x17, 0xB6, 0x71, 0x73 } };
const clsid_shell_link = Guid{ .data1 = 0x00021401, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const iid_shell_link = Guid{ .data1 = 0x000214F9, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const iid_persist_file = Guid{ .data1 = 0x0000010B, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };

var setup_log_file: HANDLE = null;

fn isInvalid(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle.?) == invalid_handle;
}

fn zSlice(value: []const u16) []const u16 {
    return value[0 .. std.mem.indexOfScalar(u16, value, 0) orelse value.len];
}

fn hasWideText(value: []const u16) bool {
    return zSlice(value).len != 0;
}

fn copyWide(output: []u16, input: []const u16) usize {
    if (output.len == 0) return 0;
    @memset(output, 0);
    const source = zSlice(input);
    const count = @min(output.len - 1, source.len);
    @memcpy(output[0..count], source[0..count]);
    return count;
}

fn appendWide(output: []u16, used: *usize, input: []const u16) bool {
    const source = zSlice(input);
    if (used.* + source.len >= output.len) return false;
    @memcpy(output[used.* .. used.* + source.len], source);
    used.* += source.len;
    output[used.*] = 0;
    return true;
}

fn wideZ(output: []u16) [*:0]const u16 {
    return @ptrCast(output.ptr);
}

fn joinPath(output: []u16, base: []const u16, leaf: []const u16) bool {
    if (output.len == 0) return false;
    @memset(output, 0);
    const directory = trimTrailingSlash(base);
    var used: usize = 0;
    if (!appendWide(output, &used, directory)) return false;
    if (used != 0 and !appendWide(output, &used, &.{'\\'})) return false;
    return appendWide(output, &used, leaf);
}

fn pathDirectory(path_arg: []const u16, output: []u16) usize {
    const path = zSlice(path_arg);
    var slash: ?usize = null;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        slash = index;
    };
    const count = slash orelse return 0;
    @memset(output, 0);
    const length = @min(count, output.len -| 1);
    @memcpy(output[0..length], path[0..length]);
    return length;
}

fn fileName(path_arg: []const u16) []const u16 {
    const path = zSlice(path_arg);
    var offset: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        offset = index + 1;
    };
    return path[offset..];
}

fn asciiEqualIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    if (wide.len != ascii.len) return false;
    for (wide, ascii) |a, b| {
        const lower_a = if (a >= 'A' and a <= 'Z') a + ('a' - 'A') else a;
        const lower_b: u16 = if (b >= 'A' and b <= 'Z') b + ('a' - 'A') else b;
        if (lower_a != lower_b) return false;
    }
    return true;
}

fn openLog(program_path: []const u16) void {
    var temp: [1024]u16 = @splat(0);
    const length = GetTempPathW(@intCast(temp.len), &temp);
    if (length > 0 and length < temp.len) {
        var candidate: [2048]u16 = @splat(0);
        if (joinPath(&candidate, temp[0..length], std.unicode.utf8ToUtf16LeStringLiteral("IslandBarSetup.log"))) {
            setup_log_file = CreateFileW(wideZ(&candidate), generic_write, file_share_read, null, create_always, file_attribute_normal, null);
            if (!isInvalid(setup_log_file)) return;
            setup_log_file = null;
        }
    }
    var directory: [1024]u16 = @splat(0);
    if (pathDirectory(program_path, &directory) == 0) return;
    var candidate: [2048]u16 = @splat(0);
    if (joinPath(&candidate, &directory, std.unicode.utf8ToUtf16LeStringLiteral("IslandBarSetup.log"))) {
        setup_log_file = CreateFileW(wideZ(&candidate), generic_write, file_share_read, null, create_always, file_attribute_normal, null);
        if (isInvalid(setup_log_file)) setup_log_file = null;
    }
}

fn sayWide(line: []const u16) void {
    var terminated: [2048]u16 = @splat(0);
    const length = copyWide(&terminated, line);
    OutputDebugStringW(wideZ(&terminated));
    if (setup_log_file) |file| {
        var utf8: [8192]u8 = undefined;
        const converted = WideCharToMultiByte(cp_utf8, 0, terminated[0..length].ptr, @intCast(length), &utf8, @intCast(utf8.len - 1), null, null);
        if (converted > 0) {
            utf8[@intCast(converted)] = '\n';
            var written: DWORD = 0;
            _ = WriteFile(file, &utf8, @intCast(converted + 1), &written, null);
        }
    }
}

fn closeLog() void {
    if (setup_log_file) |file| _ = CloseHandle(file);
    setup_log_file = null;
}

fn knownFolder(folder: *const Guid, output: []u16) usize {
    var raw: ?[*:0]u16 = null;
    if (SHGetKnownFolderPath(folder, 0, null, &raw) < 0 or raw == null) return 0;
    defer CoTaskMemFree(@ptrCast(raw.?));
    return copyWide(output, std.mem.span(raw.?));
}

fn modulePath(output: []u16) usize {
    if (output.len == 0) return 0;
    @memset(output, 0);
    const length = GetModuleFileNameW(null, output.ptr, @intCast(output.len));
    if (length == 0 or length >= output.len) return 0;
    output[length] = 0;
    return length;
}

fn profilePath(output: []u16) usize {
    const known = knownFolder(&profile_folder_id, output);
    if (known != 0) return known;
    if (output.len == 0) return 0;
    const length = GetEnvironmentVariableW(std.unicode.utf8ToUtf16LeStringLiteral("USERPROFILE"), output.ptr, @intCast(output.len));
    if (length == 0 or length >= output.len) return 0;
    output[length] = 0;
    return length;
}

fn deleteFileQuietly(path: []const u16) bool {
    var terminated: [2048]u16 = @splat(0);
    if (copyWide(&terminated, path) == 0) return true;
    if (DeleteFileW(wideZ(&terminated)) != 0) return true;
    const error_code = GetLastError();
    return error_code == error_file_not_found or error_code == error_path_not_found;
}

fn extractPayload(destination: []const u16, payload: []const u8, error_text: []u16) bool {
    if (payload.len == 0 or payload.len > std.math.maxInt(DWORD)) {
        _ = copyWide(error_text, std.unicode.utf8ToUtf16LeStringLiteral("The embedded program payload is empty or too large."));
        return false;
    }

    var temporary: [2048]u16 = @splat(0);
    var temp_len = copyWide(&temporary, destination);
    if (!appendWide(&temporary, &temp_len, std.unicode.utf8ToUtf16LeStringLiteral(".new"))) return false;
    _ = deleteFileQuietly(&temporary);
    const file = CreateFileW(wideZ(&temporary), generic_write, 0, null, create_always, file_attribute_normal, null);
    if (isInvalid(file)) {
        _ = copyWide(error_text, std.unicode.utf8ToUtf16LeStringLiteral("Could not create the temporary program file."));
        return false;
    }
    var written: DWORD = 0;
    const payload_size: DWORD = @intCast(payload.len);
    const wrote = WriteFile(file, payload.ptr, payload_size, &written, null) != 0 and written == payload_size;
    _ = CloseHandle(file);
    if (!wrote) {
        _ = deleteFileQuietly(&temporary);
        _ = copyWide(error_text, std.unicode.utf8ToUtf16LeStringLiteral("Could not write the program payload."));
        return false;
    }
    var target: [2048]u16 = @splat(0);
    _ = copyWide(&target, destination);
    if (MoveFileExW(wideZ(&temporary), wideZ(&target), movefile_replace_existing | movefile_write_through) == 0) {
        _ = deleteFileQuietly(&temporary);
        _ = copyWide(error_text, std.unicode.utf8ToUtf16LeStringLiteral("Could not atomically replace the program file."));
        return false;
    }
    sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Program payload extracted."));
    return true;
}

fn comCall(comptime Function: type, object: HANDLE, slot: usize, args: anytype) @typeInfo(@typeInfo(Function).pointer.child).@"fn".return_type.? {
    const self = object orelse unreachable;
    const table_pointer = @as(*const ?*const anyopaque, @ptrCast(@alignCast(self))).* orelse unreachable;
    const table: [*]const *const anyopaque = @ptrCast(@alignCast(table_pointer));
    const function: Function = @ptrCast(@alignCast(table[slot]));
    return @call(.auto, function, .{self} ++ args);
}

fn comRelease(object: HANDLE) void {
    if (object) |value| _ = comCall(*const fn (*anyopaque) callconv(.winapi) u32, value, 2, .{});
}

fn createShortcut(link_path_arg: []const u16, target_arg: []const u16, arguments_arg: []const u16, working_arg: []const u16, description_arg: []const u16) bool {
    var link_path: [2048]u16 = @splat(0);
    var target: [2048]u16 = @splat(0);
    var arguments: [512]u16 = @splat(0);
    var working: [2048]u16 = @splat(0);
    var description: [512]u16 = @splat(0);
    _ = copyWide(&link_path, link_path_arg);
    _ = copyWide(&target, target_arg);
    _ = copyWide(&arguments, arguments_arg);
    _ = copyWide(&working, working_arg);
    _ = copyWide(&description, description_arg);

    var shell_link: HANDLE = null;
    const create_hr = CoCreateInstance(&clsid_shell_link, null, clsctx_inproc_server, &iid_shell_link, &shell_link);
    if (create_hr < 0 or shell_link == null) return false;
    defer comRelease(shell_link);
    _ = comCall(*const fn (*anyopaque, [*:0]const u16) callconv(.winapi) HRESULT, shell_link, 20, .{wideZ(&target)});
    _ = comCall(*const fn (*anyopaque, [*:0]const u16) callconv(.winapi) HRESULT, shell_link, 9, .{wideZ(&working)});
    _ = comCall(*const fn (*anyopaque, [*:0]const u16) callconv(.winapi) HRESULT, shell_link, 11, .{wideZ(&arguments)});
    _ = comCall(*const fn (*anyopaque, [*:0]const u16) callconv(.winapi) HRESULT, shell_link, 7, .{wideZ(&description)});

    var persist: HANDLE = null;
    const query_hr = comCall(*const fn (*anyopaque, *const Guid, *HANDLE) callconv(.winapi) HRESULT, shell_link, 0, .{ &iid_persist_file, &persist });
    if (query_hr < 0 or persist == null) return false;
    defer comRelease(persist);
    const save_hr = comCall(*const fn (*anyopaque, [*:0]const u16, BOOL) callconv(.winapi) HRESULT, persist, 6, .{ wideZ(&link_path), 1 });
    return save_hr >= 0;
}

fn writeRegistryString(key: HKEY, name: [*:0]const u16, value_arg: []const u16) bool {
    var value: [2048]u16 = @splat(0);
    const count = copyWide(&value, value_arg);
    const bytes = @as(DWORD, @intCast((count + 1) * @sizeOf(u16)));
    return RegSetValueExW(key, name, 0, reg_sz, @ptrCast(&value), bytes) == 0;
}

fn writeRegistryDword(key: HKEY, name: [*:0]const u16, value: DWORD) bool {
    return RegSetValueExW(key, name, 0, reg_dword, @ptrCast(&value), @sizeOf(DWORD)) == 0;
}

fn writeUninstallEntry(directory_arg: []const u16, program_bytes: u64, setup_path_arg: []const u16) bool {
    var directory: [2048]u16 = @splat(0);
    _ = copyWide(&directory, directory_arg);
    var program: [2048]u16 = @splat(0);
    var uninstaller: [2048]u16 = @splat(0);
    if (!joinPath(&program, &directory, program_name) or !joinPath(&uninstaller, &directory, uninstaller_name)) return false;
    var uninstall_command: [4096]u16 = @splat(0);
    var used: usize = 0;
    if (!appendWide(&uninstall_command, &used, &.{'"'}) or !appendWide(&uninstall_command, &used, &uninstaller) or !appendWide(&uninstall_command, &used, &.{'"'}) or !appendWide(&uninstall_command, &used, std.unicode.utf8ToUtf16LeStringLiteral(" /uninstall"))) return false;
    var quiet_command: [4096]u16 = @splat(0);
    used = 0;
    if (!appendWide(&quiet_command, &used, &.{'"'}) or !appendWide(&quiet_command, &used, &uninstaller) or !appendWide(&quiet_command, &used, &.{'"'}) or !appendWide(&quiet_command, &used, std.unicode.utf8ToUtf16LeStringLiteral(" /uninstall /silent"))) return false;

    var key: HKEY = null;
    const create = RegCreateKeyExW(hkey_current_user, uninstall_key, 0, null, reg_option_non_volatile, key_write, null, &key, null);
    if (create != 0 or key == null) return false;
    var ok = true;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("DisplayName"), app_name) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("DisplayVersion"), version_text) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("Publisher"), std.unicode.utf8ToUtf16LeStringLiteral("BugMakerJun")) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("InstallLocation"), &directory) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("DisplayIcon"), &program) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("UninstallString"), &uninstall_command) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("QuietUninstallString"), &quiet_command) and ok;
    ok = writeRegistryString(key, std.unicode.utf8ToUtf16LeStringLiteral("InstallSource"), setup_path_arg) and ok;
    ok = writeRegistryDword(key, std.unicode.utf8ToUtf16LeStringLiteral("NoModify"), 1) and ok;
    ok = writeRegistryDword(key, std.unicode.utf8ToUtf16LeStringLiteral("NoRepair"), 1) and ok;
    ok = writeRegistryDword(key, std.unicode.utf8ToUtf16LeStringLiteral("EstimatedSize"), @intCast(@min(program_bytes / 1024 + 64, std.math.maxInt(DWORD)))) and ok;
    _ = RegCloseKey(key);

    var settings: HKEY = null;
    if (RegCreateKeyExW(hkey_current_user, settings_key, 0, null, reg_option_non_volatile, key_write, null, &settings, null) == 0 and settings != null) {
        _ = writeRegistryString(settings, std.unicode.utf8ToUtf16LeStringLiteral("InstallDir"), &directory);
        _ = writeRegistryString(settings, std.unicode.utf8ToUtf16LeStringLiteral("Version"), version_text);
        _ = RegCloseKey(settings);
    }
    return ok;
}

fn imageIsInside(image_arg: []const u16, directory_arg: []const u16) bool {
    const image = zSlice(image_arg);
    const directory = trimTrailingSlash(directory_arg);
    if (image.len <= directory.len or directory.len == 0) return false;
    if (!asciiEqualIgnoreCase(fileName(image), "island_bar.exe")) return false;
    return CompareStringOrdinal(image.ptr, @intCast(directory.len), directory.ptr, @intCast(directory.len), 1) == 2 and
        (image[directory.len] == '\\' or image[directory.len] == '/');
}

fn stopRunningBar(directory_arg: []const u16, only_directory: bool) i32 {
    const snapshot = CreateToolhelp32Snapshot(th32cs_snapprocess, 0);
    if (isInvalid(snapshot)) return 0;
    defer _ = CloseHandle(snapshot);
    var entry = std.mem.zeroes(ProcessEntry32W);
    entry.size = @sizeOf(ProcessEntry32W);
    if (Process32FirstW(snapshot, &entry) == 0) return 0;
    var stopped: i32 = 0;
    while (true) {
        if (!asciiEqualIgnoreCase(zSlice(&entry.exe_file), "island_bar.exe")) {
            if (Process32NextW(snapshot, &entry) == 0) break;
            continue;
        }
        var belongs = !only_directory;
        const probe = OpenProcess(process_query_limited_information, 0, entry.process_id);
        if (probe) |process| {
            var image: [2048]u16 = @splat(0);
            var length: DWORD = @intCast(image.len);
            const have_image = QueryFullProcessImageNameW(process, 0, &image, &length) != 0;
            if (only_directory) belongs = have_image and imageIsInside(image[0..length], directory_arg);
            _ = CloseHandle(process);
        }
        if (belongs) {
            const victim = OpenProcess(process_terminate | synchronize, 0, entry.process_id);
            if (victim) |handle| {
                if (TerminateProcess(handle, 0) != 0) {
                    stopped += 1;
                    _ = WaitForSingleObject(handle, 3000);
                }
                _ = CloseHandle(handle);
            }
        }
        if (Process32NextW(snapshot, &entry) == 0) break;
    }
    return stopped;
}

fn restoreShellTaskbar() void {
    const classes = [_][*:0]const u16{
        std.unicode.utf8ToUtf16LeStringLiteral("Shell_TrayWnd"),
        std.unicode.utf8ToUtf16LeStringLiteral("Shell_SecondaryTrayWnd"),
    };
    for (classes) |class_name| {
        var window = FindWindowW(class_name, null);
        while (window != null) : (window = FindWindowExW(null, window, class_name, null)) {
            if (IsWindowVisible(window) == 0) _ = ShowWindow(window, sw_show);
        }
    }
}

fn fileSize(path_arg: []const u16) u64 {
    var path: [2048]u16 = @splat(0);
    _ = copyWide(&path, path_arg);
    var info = std.mem.zeroes(FileAttributeData);
    if (GetFileAttributesExW(wideZ(&path), 0, &info) == 0) return 0;
    return (@as(u64, info.size_high) << 32) | info.size_low;
}

fn removeRegistryTree(subkey: []const u16) void {
    var key: [512]u16 = @splat(0);
    _ = copyWide(&key, subkey);
    const result = RegDeleteTreeW(hkey_current_user, wideZ(&key));
    if (result == 0) sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Removed an IslandBar registry entry."));
}

fn deleteDirectoryToRecycleBin(path_arg: []const u16) bool {
    var path: [2048]u16 = @splat(0);
    const length = copyWide(&path, path_arg);
    if (length == 0 or length + 1 >= path.len) return false;
    path[length] = 0;
    path[length + 1] = 0;
    var operation = ShFileOperationW{
        .window = null,
        .operation = fo_delete,
        .from = wideZ(&path),
        .to = null,
        .flags = fof_allow_undo | fof_no_confirmation | fof_silent | fof_no_error_ui,
        .aborted = 0,
        .name_mappings = null,
        .progress_title = null,
    };
    return SHFileOperationW(&operation) == 0 and operation.aborted == 0;
}

fn runShell(path_arg: []const u16, directory_arg: []const u16) bool {
    var path: [2048]u16 = @splat(0);
    var directory: [2048]u16 = @splat(0);
    _ = copyWide(&path, path_arg);
    _ = copyWide(&directory, directory_arg);
    var info = std.mem.zeroes(ShellExecuteInfoW);
    info.cb_size = @sizeOf(ShellExecuteInfoW);
    info.mask = see_mask_no_close_process | see_mask_flag_no_ui;
    info.file = wideZ(&path);
    info.directory = wideZ(&directory);
    info.show = sw_shownormal;
    if (ShellExecuteExW(&info) == 0) return false;
    if (info.process) |process| _ = CloseHandle(process);
    return true;
}

fn defaultInstallDirectory(options: Options, setup_path: []const u16, output: []u16) bool {
    if (options.directory) |requested| {
        if (trimTrailingSlash(requested).len != 0) return copyWide(output, requested) != 0;
    }
    if (options.uninstall and asciiEqualIgnoreCase(fileName(setup_path), "IslandBarUninstall.exe")) {
        return pathDirectory(setup_path, output) != 0;
    }
    var profile: [1024]u16 = @splat(0);
    if (profilePath(&profile) == 0) return false;
    return appendProfilePath(&profile, std.unicode.utf8ToUtf16LeStringLiteral("IslandBar"), output) != 0;
}

fn handleInstall(options: Options, setup_path_arg: []const u16, directory_arg: []const u16, program_arg: []const u16, uninstaller_arg: []const u16, startup_link_arg: []const u16, menu_link_arg: []const u16, safe_link_arg: []const u16, payload: []const u8) bool {
    var directory: [2048]u16 = @splat(0);
    _ = copyWide(&directory, directory_arg);
    if (CreateDirectoryW(wideZ(&directory), null) == 0 and GetLastError() != error_already_exists) {
        sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Could not create the installation directory."));
        return false;
    }

    var stopped = stopRunningBar(&directory, true);
    if (stopped > 0) {
        sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Stopped the IslandBar copy in the installation directory."));
        Sleep(700);
        restoreShellTaskbar();
    }
    var error_text: [512]u16 = @splat(0);
    if (!extractPayload(program_arg, payload, &error_text)) {
        stopped += stopRunningBar(&directory, false);
        if (stopped > 0) Sleep(700);
        @memset(&error_text, 0);
        if (!extractPayload(program_arg, payload, &error_text)) {
            sayWide(&error_text);
            return false;
        }
    }

    var setup_path: [2048]u16 = @splat(0);
    _ = copyWide(&setup_path, setup_path_arg);
    var uninstaller_path: [2048]u16 = @splat(0);
    _ = copyWide(&uninstaller_path, uninstaller_arg);
    if (CopyFileW(wideZ(&setup_path), wideZ(&uninstaller_path), 0) != 0) sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Uninstaller copy written."));

    if (hasWideText(menu_link_arg)) _ = createShortcut(menu_link_arg, program_arg, &.{}, &directory, app_name);
    if (hasWideText(safe_link_arg)) _ = createShortcut(safe_link_arg, program_arg, std.unicode.utf8ToUtf16LeStringLiteral("--keep-taskbar"), &directory, std.unicode.utf8ToUtf16LeStringLiteral("保留 Windows 系统任务栏，只当浮层用（排错）"));
    if (options.autostart and hasWideText(startup_link_arg)) {
        _ = createShortcut(startup_link_arg, program_arg, &.{}, &directory, std.unicode.utf8ToUtf16LeStringLiteral("Start IslandBar at logon"));
    }
    _ = writeUninstallEntry(&directory, fileSize(program_arg), &setup_path);

    if (options.launch and !runShell(program_arg, &directory)) sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Starting IslandBar failed.")) else if (options.launch) sayWide(std.unicode.utf8ToUtf16LeStringLiteral("IslandBar started."));
    sayWide(std.unicode.utf8ToUtf16LeStringLiteral("IslandBar installation completed."));
    return true;
}

fn handleUninstall(options: Options, setup_path_arg: []const u16, directory_arg: []const u16, program_arg: []const u16, uninstaller_arg: []const u16, startup_link_arg: []const u16, menu_link_arg: []const u16, safe_link_arg: []const u16) bool {
    var directory: [2048]u16 = @splat(0);
    _ = copyWide(&directory, directory_arg);
    const stopped = stopRunningBar(&directory, true);
    if (stopped > 0) {
        Sleep(500);
        restoreShellTaskbar();
    }
    if (hasWideText(startup_link_arg)) _ = deleteFileQuietly(startup_link_arg);
    if (hasWideText(menu_link_arg)) _ = deleteFileQuietly(menu_link_arg);
    if (hasWideText(safe_link_arg)) _ = deleteFileQuietly(safe_link_arg);
    removeRegistryTree(uninstall_key);
    removeRegistryTree(settings_key);
    _ = deleteFileQuietly(program_arg);
    if (options.remove_settings) {
        const setting_names = [_][:0]const u16{
            std.unicode.utf8ToUtf16LeStringLiteral("weather.txt"),
            std.unicode.utf8ToUtf16LeStringLiteral("start_folder.txt"),
            std.unicode.utf8ToUtf16LeStringLiteral("start_pins.txt"),
            std.unicode.utf8ToUtf16LeStringLiteral("island_bar.log"),
            std.unicode.utf8ToUtf16LeStringLiteral("start_pins.txt.migrated"),
        };
        for (setting_names) |name| {
            var path: [2048]u16 = @splat(0);
            if (joinPath(&path, &directory, name)) _ = deleteFileQuietly(&path);
        }
        var pins: [2048]u16 = @splat(0);
        if (joinPath(&pins, &directory, std.unicode.utf8ToUtf16LeStringLiteral("Start"))) _ = deleteDirectoryToRecycleBin(&pins);
        _ = RemoveDirectoryW(wideZ(&directory));
    }
    if (asciiEqualIgnoreCase(fileName(setup_path_arg), "IslandBarUninstall.exe")) {
        var setup_path: [2048]u16 = @splat(0);
        _ = copyWide(&setup_path, setup_path_arg);
        _ = MoveFileExW(wideZ(&setup_path), null, movefile_delay_until_reboot);
    } else if (hasWideText(uninstaller_arg)) {
        _ = deleteFileQuietly(uninstaller_arg);
    }
    sayWide(std.unicode.utf8ToUtf16LeStringLiteral("IslandBar uninstall completed."));
    return true;
}

pub fn run(payload: []const u8) void {
    var setup_path: [2048]u16 = @splat(0);
    const setup_len = modulePath(&setup_path);
    if (setup_len == 0) return;
    openLog(&setup_path);
    sayWide(std.unicode.utf8ToUtf16LeStringLiteral("IslandBar setup 1.2 started."));

    const com_result = CoInitializeEx(null, 2);
    const com_initialized = com_result >= 0;
    defer if (com_initialized) CoUninitialize();

    var argc: i32 = 0;
    const argv = CommandLineToArgvW(GetCommandLineW(), &argc) orelse {
        closeLog();
        return;
    };
    defer _ = LocalFree(@ptrCast(argv));
    var argument_slices: [128][]const u16 = undefined;
    var argument_count: usize = 0;
    if (argc > 1) for (1..@intCast(@min(argc, 129))) |index| {
        argument_slices[argument_count] = std.mem.span(argv[index]);
        argument_count += 1;
    };
    const options = parseArguments(argument_slices[0..argument_count]);
    if (options.help) {
        @setEvalBranchQuota(10000);
        const help = std.unicode.utf8ToUtf16LeStringLiteral("IslandBarSetup installs and uninstalls IslandBar for the current user.\n\n  (no arguments)     install and start it\n  /uninstall         remove it; settings are kept\n  /remove-settings   with /uninstall: remove settings too\n  /dir=PATH          choose an installation directory\n  /no-autostart      do not add the Startup shortcut\n  /no-launch         install without starting the bar\n  /silent            suppress message boxes\n");
        _ = MessageBoxW(null, help, uninstall_caption, 0x40);
        sayWide(std.unicode.utf8ToUtf16LeStringLiteral("Help shown; nothing changed."));
        closeLog();
        return;
    }

    var directory: [2048]u16 = @splat(0);
    if (!defaultInstallDirectory(options, &setup_path, &directory)) {
        const message = std.unicode.utf8ToUtf16LeStringLiteral("Cannot determine the user's profile or installation directory.");
        sayWide(message);
        if (!options.silent) _ = MessageBoxW(null, message, uninstall_caption, 0x10);
        closeLog();
        std.process.exit(1);
    }
    var program: [2048]u16 = @splat(0);
    var uninstaller: [2048]u16 = @splat(0);
    _ = joinPath(&program, &directory, program_name);
    _ = joinPath(&uninstaller, &directory, uninstaller_name);

    var startup_folder: [2048]u16 = @splat(0);
    var programs_folder: [2048]u16 = @splat(0);
    const startup_len = knownFolder(&startup_folder_id, &startup_folder);
    const programs_len = knownFolder(&programs_folder_id, &programs_folder);
    var startup_link: [2048]u16 = @splat(0);
    var menu_link: [2048]u16 = @splat(0);
    var safe_link: [2048]u16 = @splat(0);
    if (startup_len != 0) _ = joinPath(&startup_link, &startup_folder, startup_link_name);
    if (programs_len != 0) {
        _ = joinPath(&menu_link, &programs_folder, menu_link_name);
        _ = joinPath(&safe_link, &programs_folder, safe_link_name);
    }

    var success = false;
    if (options.uninstall) {
        success = handleUninstall(options, &setup_path, &directory, &program, &uninstaller, &startup_link, &menu_link, &safe_link);
    } else {
        success = handleInstall(options, &setup_path, &directory, &program, &uninstaller, &startup_link, &menu_link, &safe_link, payload);
    }
    closeLog();
    if (!options.silent) {
        const message = if (success)
            (if (options.uninstall) std.unicode.utf8ToUtf16LeStringLiteral("IslandBar has been uninstalled.") else std.unicode.utf8ToUtf16LeStringLiteral("IslandBar 1.2 is installed."))
        else
            std.unicode.utf8ToUtf16LeStringLiteral("IslandBar setup failed. Check IslandBarSetup.log for details.");
        _ = MessageBoxW(null, message, uninstall_caption, if (success) 0x40 else 0x10);
    }
    std.process.exit(if (success) 0 else 1);
}
