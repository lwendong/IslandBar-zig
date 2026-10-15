const std = @import("std");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const SystemTime = extern struct {
    year: u16,
    month: u16,
    day_of_week: u16,
    day: u16,
    hour: u16,
    minute: u16,
    second: u16,
    milliseconds: u16,
};

extern "kernel32" fn GetLocalTime(time: *SystemTime) callconv(.winapi) void;
extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetTempPathW(size: DWORD, path: [*]u16) callconv(.winapi) DWORD;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: DWORD, share: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn WriteFile(handle: HANDLE, buffer: [*]const u8, bytes: DWORD, written: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn FlushFileBuffers(handle: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn GetStdHandle(kind: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn GetFileType(file: HANDLE) callconv(.winapi) DWORD;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "kernel32" fn GetConsoleProcessList(processes: ?[*]DWORD, process_count: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn AttachConsole(process_id: DWORD) callconv(.winapi) i32;
extern "kernel32" fn AllocConsole() callconv(.winapi) i32;
extern "kernel32" fn SetConsoleOutputCP(code_page: DWORD) callconv(.winapi) i32;
extern "kernel32" fn WriteConsoleW(handle: HANDLE, text: [*]const u16, length: DWORD, written: *DWORD, reserved: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*:0]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*:0]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;

const max_path = 260;
const max_record = 2048;
const mirror_capacity = 16384;
const generic_write: DWORD = 0x40000000;
const file_append_data: DWORD = 0x00000004;
const file_share_read: DWORD = 0x00000001;
const file_share_write: DWORD = 0x00000002;
const create_always: DWORD = 2;
const open_always: DWORD = 4;
const file_attribute_normal: DWORD = 0x00000080;
const cp_utf8: DWORD = 65001;
const std_output_handle: DWORD = @bitCast(@as(i32, -11));
const file_type_unknown: DWORD = 0;
const invalid_handle_value: usize = std.math.maxInt(usize);
const attach_parent_process: DWORD = std.math.maxInt(DWORD);
const log_file_name: [*:0]const u16 = &.{ 'i', 's', 'l', 'a', 'n', 'd', '_', 'b', 'a', 'r', '.', 'l', 'o', 'g', 0 };

var file: HANDLE = null;
var path: [max_path]u16 = @splat(0);
var path_length: usize = 0;
var tried: bool = false;
var mirror: [mirror_capacity]u8 = @splat(0);
var mirror_length: usize = 0;

pub const ConsoleStatus = struct {
    inherited: bool = false,
    attached: bool = false,
    attach_error: DWORD = 0,
    created: bool = false,
    disabled: bool = false,

    pub fn summary(self: ConsoleStatus, output: []u8) []const u8 {
        if (self.disabled) return "console: disabled by --no-console";
        return std.fmt.bufPrint(output, "console: inherited={d} attach={d} err={d}; {s}", .{
            @intFromBool(self.inherited),
            @intFromBool(self.attached),
            self.attach_error,
            if (self.inherited or self.attached or self.created) "usable" else "unavailable",
        }) catch "console: status unavailable";
    }
};

/// Borrows a parent console when present; only diagnostics which explicitly
/// print results create one. Redirection handles are left intact for CLI callers.
pub fn prepareConsole(create_if_missing: bool, disabled: bool) ConsoleStatus {
    if (disabled) return .{ .disabled = true };
    const inherited = GetConsoleProcessList(null, 0) > 0;
    const attached = AttachConsole(attach_parent_process) != 0;
    const attach_error = if (attached) 0 else GetLastError();
    const have_console = inherited or attached;
    const created = !have_console and create_if_missing and AllocConsole() != 0;
    _ = SetConsoleOutputCP(cp_utf8);
    return .{
        .inherited = inherited,
        .attached = attached,
        .attach_error = attach_error,
        .created = created,
    };
}

fn isInvalid(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle) == invalid_handle_value;
}

fn appendWide(destination: []u16, used_arg: usize, text: []const u16) usize {
    if (destination.len == 0) return used_arg;
    var used = @min(used_arg, destination.len - 1);
    for (text) |unit| {
        if (unit == 0 or used + 1 >= destination.len) break;
        destination[used] = unit;
        used += 1;
    }
    destination[used] = 0;
    return used;
}

fn setPathFromExe() bool {
    var exe_path: [max_path]u16 = @splat(0);
    const length = GetModuleFileNameW(null, &exe_path, max_path);
    if (length == 0 or length >= max_path) return false;
    var folder_end: ?usize = null;
    for (exe_path[0..length], 0..) |unit, index| if (unit == '\\' or unit == '/') {
        folder_end = index + 1;
    };
    const end = folder_end orelse return false;
    @memcpy(path[0..end], exe_path[0..end]);
    path_length = appendWide(&path, end, log_file_name[0..14]);
    return true;
}

fn setPathFromTemp() bool {
    var temp: [max_path]u16 = @splat(0);
    const length = GetTempPathW(max_path, &temp);
    if (length == 0 or length >= max_path) return false;
    @memcpy(path[0..length], temp[0..length]);
    path_length = appendWide(&path, length, log_file_name[0..14]);
    return true;
}

fn probePath() bool {
    const handle = CreateFileW(@ptrCast(&path), file_append_data, file_share_read | file_share_write, null, open_always, file_attribute_normal, null);
    if (isInvalid(handle)) return false;
    _ = CloseHandle(handle);
    return true;
}

/// Resolves the path beside the executable, falling back to the user's temp directory.
pub fn logPath(output: []u16) usize {
    if (path_length == 0) {
        if (!setPathFromExe() or !probePath()) _ = setPathFromTemp();
    }
    if (output.len == 0) return 0;
    const count = @min(path_length, output.len - 1);
    @memcpy(output[0..count], path[0..count]);
    output[count] = 0;
    return count;
}

pub fn stdoutIsUsable() bool {
    const output = GetStdHandle(std_output_handle);
    return !isInvalid(output) and GetFileType(output) != file_type_unknown;
}

fn appendMirror(text: []const u8) void {
    if (text.len >= mirror_capacity - mirror_length) return;
    @memcpy(mirror[mirror_length .. mirror_length + text.len], text);
    mirror_length += text.len;
    mirror[mirror_length] = 0;
}

fn timestamp(out: *[16]u8) []const u8 {
    var now: SystemTime = undefined;
    GetLocalTime(&now);
    const formatted = std.fmt.bufPrint(out, "{d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}", .{ now.hour, now.minute, now.second, now.milliseconds }) catch return "00:00:00.000";
    return formatted;
}

fn writeFileBytes(text: []const u8) void {
    if (isInvalid(file) or text.len == 0) return;
    var written: DWORD = 0;
    _ = WriteFile(file, text.ptr, @intCast(text.len), &written, null);
    _ = FlushFileBuffers(file);
}

fn openLogFile() void {
    if (tried) return;
    tried = true;
    var path_copy: [max_path]u16 = @splat(0);
    _ = logPath(&path_copy);
    file = CreateFileW(@ptrCast(&path), generic_write, file_share_read | file_share_write, null, create_always, file_attribute_normal, null);
    if (isInvalid(file)) {
        file = null;
        if (setPathFromTemp()) file = CreateFileW(@ptrCast(&path), generic_write, file_share_read | file_share_write, null, create_always, file_attribute_normal, null);
    }
}

fn logRecord(text: []const u8) void {
    openLogFile();
    var stamp_buffer: [16]u8 = undefined;
    const stamp = timestamp(&stamp_buffer);
    appendMirror("[");
    appendMirror(stamp);
    appendMirror("] ");
    appendMirror(text);
    if (text.len == 0 or text[text.len - 1] != '\n') appendMirror("\n");

    var line: [max_record + 32]u8 = undefined;
    var used: usize = 0;
    @memcpy(line[used .. used + stamp.len], stamp);
    used += stamp.len;
    @memcpy(line[used .. used + 2], "] ");
    used += 2;
    const body_len = @min(text.len, line.len - used - 2);
    @memcpy(line[used .. used + body_len], text[0..body_len]);
    used += body_len;
    if (body_len == 0 or line[used - 1] != '\n') {
        line[used] = '\r';
        line[used + 1] = '\n';
        used += 2;
    }
    writeFileBytes(line[0..used]);
}

/// Opens and truncates the current run's log file.
pub fn openLog() void {
    if (!tried) openLogFile();
    if (isInvalid(file)) return;
    logRecord("--- IslandBar Zig starting ---");
    var path_buffer: [max_path]u16 = @splat(0);
    _ = logPath(&path_buffer);
    var path_utf8: [max_path * 4 + 1]u8 = @splat(0);
    const wide_path: [*:0]const u16 = @ptrCast(&path_buffer);
    const converted = WideCharToMultiByte(cp_utf8, 0, wide_path, -1, &path_utf8, @intCast(path_utf8.len), null, null);
    if (converted > 0) {
        const path_utf8_length: usize = @intCast(converted - 1);
        logRecord(path_utf8[0..path_utf8_length]);
        if (stdoutIsUsable()) printLine(path_utf8[0..path_utf8_length]);
    }
}

pub fn closeLog() void {
    if (!isInvalid(file)) _ = CloseHandle(file);
    file = null;
}

/// Writes one timestamped UTF-8 record and flushes it immediately.
pub fn logLine(text: []const u8) void {
    logRecord(text);
}

pub fn logAndPrint(text: []const u8) void {
    logLine(text);
    printLine(text);
}

pub fn logAndPrintAscii(text: []const u8) void {
    logAndPrint(text);
}

fn trimNewlines(text: []const u8) []const u8 {
    var end = text.len;
    while (end > 0 and (text[end - 1] == '\n' or text[end - 1] == '\r')) : (end -= 1) {}
    return text[0..end];
}

/// Writes one line to a console or redirected standard output, when available.
pub fn printLine(text: []const u8) void {
    const output = GetStdHandle(std_output_handle);
    if (isInvalid(output) or GetFileType(output) == file_type_unknown) return;
    const trimmed = trimNewlines(text);
    const kind = GetFileType(output);
    if (kind == 2) {
        var terminated: [max_record + 1]u8 = @splat(0);
        const amount = @min(trimmed.len, terminated.len - 1);
        @memcpy(terminated[0..amount], trimmed[0..amount]);
        var wide: [max_record + 2]u16 = @splat(0);
        const count = MultiByteToWideChar(cp_utf8, 0, @ptrCast(&terminated), -1, &wide, @intCast(wide.len));
        if (count > 0) {
            var written: DWORD = 0;
            _ = WriteConsoleW(output, &wide, @intCast(count - 1), &written, null);
            _ = WriteConsoleW(output, &.{'\n'}, 1, &written, null);
        }
        return;
    }
    var written: DWORD = 0;
    if (trimmed.len != 0) _ = WriteFile(output, trimmed.ptr, @intCast(trimmed.len), &written, null);
    _ = WriteFile(output, "\r\n", 2, &written, null);
}

pub fn printLineAscii(text: []const u8) void {
    printLine(text);
}

/// Copies the current run's log mirror to a caller-owned UTF-16 buffer.
pub fn readLog(output: []u16) usize {
    if (output.len == 0) return 0;
    output[0] = 0;
    var encoded: [mirror_capacity + 1]u8 = @splat(0);
    const bytes = @min(mirror_length, encoded.len - 1);
    @memcpy(encoded[0..bytes], mirror[0..bytes]);
    const count = MultiByteToWideChar(cp_utf8, 0, @ptrCast(&encoded), -1, output.ptr, @intCast(@min(output.len, @as(usize, std.math.maxInt(i32)))));
    if (count <= 0) return 0;
    return @intCast(count - 1);
}

pub fn smokeCheck() bool {
    if (false) {
        openLog();
        logLine("probe");
        logAndPrint("probe");
        logAndPrintAscii("probe");
        printLine("probe");
        printLineAscii("probe");
        var output: [1]u16 = .{0};
        _ = readLog(&output);
        closeLog();
    }
    var console_summary: [96]u8 = undefined;
    const disabled = ConsoleStatus{ .disabled = true };
    if (!std.mem.eql(u8, disabled.summary(&console_summary), "console: disabled by --no-console")) return false;
    const allocated = ConsoleStatus{ .created = true };
    if (std.mem.indexOf(u8, allocated.summary(&console_summary), "usable") == null) return false;
    return trimNewlines("x\r\n").len == 1 and trimNewlines("").len == 0 and mirror_length <= mirror_capacity;
}
