const std = @import("std");

pub const title_capacity = 192;
pub const artist_capacity = 128;
pub const app_capacity = 64;
pub const poll_interval_ms: u32 = 1000;

const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const LPARAM = isize;
const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};

pub const PlayerWindowInfo = struct {
    present: bool = false,
    title: [title_capacity]u8 = @splat(0),
    artist: [artist_capacity]u8 = @splat(0),
    app: [app_capacity]u8 = @splat(0),
};

extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*:0]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*:0]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;
extern "kernel32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, size: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "user32" fn GetWindowTextW(window: HWND, text: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn EnumWindows(callback: *const fn (HWND, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;

const process_query_limited_information: DWORD = 0x1000;
const cp_utf8: DWORD = 65001;
const wait_timeout: DWORD = 258;

const known_players = [_][]const u16{
    &.{ 'c', 'l', 'o', 'u', 'd', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' },
    &.{ 'q', 'q', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' },
    &.{ 'k', 'u', 'g', 'o', 'u', '.', 'e', 'x', 'e' },
    &.{ 'k', 'u', 'g', 'o', 'u', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' },
    &.{ 'k', 'w', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' },
    &.{ 'k', 'u', 'w', 'o', '.', 'e', 'x', 'e' },
    &.{ 's', 'p', 'o', 't', 'i', 'f', 'y', '.', 'e', 'x', 'e' },
    &.{ 'm', 'u', 's', 'i', 'c', 'b', 'e', 'e', '.', 'e', 'x', 'e' },
    &.{ 'f', 'o', 'o', 'b', 'a', 'r', '2', '0', '0', '0', '.', 'e', 'x', 'e' },
    &.{ 'a', 'i', 'm', 'p', '.', 'e', 'x', 'e' },
    &.{ 'z', 'u', 'n', 'e', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' },
    &.{ 'i', 't', 'u', 'n', 'e', 's', '.', 'e', 'x', 'e' },
    &.{ 'm', 'i', 'g', 'u', '.', 'e', 'x', 'e' },
    &.{ 'c', 'l', 'o', 'u', 'd', 'm', 'u', 's', 'i', 'c', '_', 'p', 'c', '.', 'e', 'x', 'e' },
};

const not_songs = [_][]const u16{
    &.{ '网', '易', '云', '音', '乐' },
    &.{ '网', '易', '云', '音', '乐', ' ', 'f', 'o', 'r', ' ', 'W', 'i', 'n', 'd', 'o', 'w', 's' },
    &.{ '网', '易', '云', '音', '乐', 'f', 'o', 'r', ' ', 'W', 'i', 'n', 'd', 'o', 'w', 's' },
    &.{ 'Q', 'Q', '音', '乐' },
    &.{ '酷', '狗', '音', '乐' },
    &.{ '酷', '我', '音', '乐' },
    &.{ '咪', '咕', '音', '乐' },
    &.{ 'S', 'p', 'o', 't', 'i', 'f', 'y' },
    &.{ 'S', 'p', 'o', 't', 'i', 'f', 'y', ' ', 'F', 'r', 'e', 'e' },
    &.{ 'S', 'p', 'o', 't', 'i', 'f', 'y', ' ', 'P', 'r', 'e', 'm', 'i', 'u', 'm' },
    &.{ 'M', 'u', 's', 'i', 'c', 'B', 'e', 'e' },
    &.{ 'f', 'o', 'o', 'b', 'a', 'r', '2', '0', '0', '0' },
    &.{ 'i', 'T', 'u', 'n', 'e', 's' },
    &.{ 'C', 'l', 'o', 'u', 'd', 'M', 'u', 's', 'i', 'c' },
};

fn cWide(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn lowerAscii(unit: u16) u16 {
    return if (unit >= 'A' and unit <= 'Z') unit + ('a' - 'A') else unit;
}

fn equalsIgnoreCase(left: []const u16, right: []const u16) bool {
    if (left.len != right.len) return false;
    for (left, right) |a, b| if (lowerAscii(a) != lowerAscii(b)) return false;
    return true;
}

fn bareExecutableName(path: []const u16) []const u16 {
    var start: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        start = index + 1;
    };
    return path[start..];
}

pub fn isKnownPlayerExecutable(executable_name: []const u16) bool {
    const name = bareExecutableName(cWide(executable_name));
    if (name.len == 0) return false;
    for (known_players) |known| if (equalsIgnoreCase(name, known)) return true;
    return false;
}

fn isSpace(unit: u16) bool {
    return unit == ' ' or unit == '\t' or unit == '\r' or unit == '\n' or unit == 0x00a0 or unit == 0x3000;
}

fn trim(text: []const u16) []const u16 {
    var begin: usize = 0;
    var end = text.len;
    while (begin < end and isSpace(text[begin])) : (begin += 1) {}
    while (end > begin and isSpace(text[end - 1])) : (end -= 1) {}
    return text[begin..end];
}

fn toUtf8(text_arg: []const u16, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    const text = cWide(text_arg);
    if (text.len == 0) return true;
    const count = @min(text.len, 511);
    var terminated: [512]u16 = @splat(0);
    @memcpy(terminated[0..count], text[0..count]);
    const bytes = WideCharToMultiByte(cp_utf8, 0, @ptrCast(&terminated), -1, output.ptr, @intCast(@min(output.len, @as(usize, std.math.maxInt(i32)))), null, null);
    return bytes > 0;
}

pub fn parsePlayerWindowTitle(window_title: []const u16, title_output: []u8, artist_output: []u8) bool {
    if (title_output.len != 0) title_output[0] = 0;
    if (artist_output.len != 0) artist_output[0] = 0;
    if (title_output.len == 0 or artist_output.len == 0) return false;
    const text = trim(cWide(window_title));
    if (text.len == 0 or text.len < 3) return false;
    var separator: ?usize = null;
    var index: usize = 0;
    while (index + 3 <= text.len) : (index += 1) {
        if (text[index] == ' ' and text[index + 1] == '-' and text[index + 2] == ' ') separator = index;
    }
    const split = separator orelse return false;
    const song = trim(text[0..split]);
    const artist = trim(text[split + 3 ..]);
    if (song.len == 0 or artist.len == 0) return false;
    for (not_songs) |not_song| if (equalsIgnoreCase(song, not_song)) return false;
    return toUtf8(song, title_output) and toUtf8(artist, artist_output);
}

const Search = struct {
    found: bool = false,
    found_visible: bool = false,
    title: [title_capacity]u8 = @splat(0),
    artist: [artist_capacity]u8 = @splat(0),
    app: [app_capacity]u8 = @splat(0),
};

fn visitWindow(window: HWND, parameter: LPARAM) callconv(.winapi) BOOL {
    const search: *Search = @ptrFromInt(@as(usize, @intCast(parameter)));
    if (search.found_visible) return 0;
    var title: [512]u16 = @splat(0);
    if (GetWindowTextW(window, &title, title.len) <= 0) return 1;
    var process_id: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &process_id);
    if (process_id == 0 or process_id == GetCurrentProcessId()) return 1;
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return 1;
    var path: [260]u16 = @splat(0);
    var path_length: DWORD = path.len;
    const have_path = QueryFullProcessImageNameW(process, 0, &path, &path_length) != 0;
    _ = CloseHandle(process);
    if (!have_path or !isKnownPlayerExecutable(&path)) return 1;
    if (!parsePlayerWindowTitle(&title, &search.title, &search.artist)) return 1;
    const visible = IsWindowVisible(window) != 0;
    if (search.found and search.found_visible or search.found and !visible) return 1;
    const exe = bareExecutableName(&path);
    _ = toUtf8(exe, &search.app);
    search.found = true;
    search.found_visible = visible;
    return 1;
}

pub const PlayerWindowWatch = struct {
    stop_event: HANDLE = null,
    thread: HANDLE = null,
    running: bool = false,
    lock: CriticalSection = .{ .debug_info = null, .lock_count = 0, .recursion_count = 0, .owning_thread = null, .lock_semaphore = null, .spin_count = 0 },
    lock_ready: bool = false,
    published: PlayerWindowInfo = .{},
    revision: i32 = 0,
    poll_count: i32 = 0,

    pub fn start(self: *PlayerWindowWatch) bool {
        if (@atomicLoad(bool, &self.running, .acquire)) return true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        if (self.stop_event == null) return false;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        @atomicStore(bool, &self.running, true, .release);
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            @atomicStore(bool, &self.running, false, .release);
            _ = CloseHandle(self.stop_event);
            self.stop_event = null;
            return false;
        }
        return true;
    }

    pub fn stop(self: *PlayerWindowWatch) void {
        if (!@atomicLoad(bool, &self.running, .acquire)) return;
        @atomicStore(bool, &self.running, false, .release);
        if (self.stop_event != null) _ = SetEvent(self.stop_event);
        if (self.thread != null) {
            _ = WaitForSingleObject(self.thread, 0xFFFFFFFF);
            _ = CloseHandle(self.thread);
            self.thread = null;
        }
        if (self.stop_event != null) {
            _ = CloseHandle(self.stop_event);
            self.stop_event = null;
        }
    }

    pub fn snapshot(self: *PlayerWindowWatch, output: *PlayerWindowInfo) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        output.* = self.published;
        LeaveCriticalSection(&self.lock);
    }

    pub fn revisionCount(self: *const PlayerWindowWatch) i64 {
        return @atomicLoad(i32, @constCast(&self.revision), .seq_cst);
    }

    pub fn pollCount(self: *const PlayerWindowWatch) i64 {
        return @atomicLoad(i32, @constCast(&self.poll_count), .seq_cst);
    }

    fn run(self: *PlayerWindowWatch) void {
        while (true) {
            self.poll();
            _ = @atomicRmw(i32, &self.poll_count, .Add, 1, .seq_cst);
            if (WaitForSingleObject(self.stop_event, poll_interval_ms) != wait_timeout) break;
            if (!@atomicLoad(bool, &self.running, .acquire)) break;
        }
    }

    fn poll(self: *PlayerWindowWatch) void {
        var search = Search{};
        _ = EnumWindows(visitWindow, @intCast(@intFromPtr(&search)));
        var info = PlayerWindowInfo{ .present = search.found };
        if (search.found) {
            @memcpy(&info.title, &search.title);
            @memcpy(&info.artist, &search.artist);
            @memcpy(&info.app, &search.app);
        }
        self.publish(info);
    }

    fn publish(self: *PlayerWindowWatch, info: PlayerWindowInfo) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        const same = self.published.present == info.present and
            std.mem.eql(u8, cString(&self.published.title), cString(&info.title)) and
            std.mem.eql(u8, cString(&self.published.artist), cString(&info.artist)) and
            std.mem.eql(u8, cString(&self.published.app), cString(&info.app));
        if (!same) {
            self.published = info;
            _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
        }
        LeaveCriticalSection(&self.lock);
    }
};

fn threadEntry(context: ?*anyopaque) callconv(.winapi) DWORD {
    const watch: *PlayerWindowWatch = @ptrCast(@alignCast(context orelse return 0));
    watch.run();
    return 0;
}

fn cString(text: []const u8) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse text.len];
}

pub fn smokeCheck() bool {
    var title: [title_capacity]u8 = @splat(0);
    var artist: [artist_capacity]u8 = @splat(0);
    if (!parsePlayerWindowTitle(&.{ ' ', '长', '大', ' ', '-', ' ', '宋', '扬', 0 }, &title, &artist)) return false;
    if (!std.mem.eql(u8, cString(&title), "长大")) return false;
    if (!std.mem.eql(u8, cString(&artist), "宋扬")) return false;
    if (parsePlayerWindowTitle(&.{ '网', '易', '云', '音', '乐', ' ', '-', ' ', '艺', '人', 0 }, &title, &artist)) return false;
    if (!isKnownPlayerExecutable(&.{ 'C', ':', '\\', 'c', 'l', 'o', 'u', 'd', 'm', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e', 0 })) return false;
    if (isKnownPlayerExecutable(&.{ 'b', 'r', 'o', 'w', 's', 'e', 'r', '.', 'e', 'x', 'e', 0 })) return false;
    if (false) {
        var watch = PlayerWindowWatch{};
        _ = watch.start();
        var info = PlayerWindowInfo{};
        watch.snapshot(&info);
        _ = watch.revisionCount();
        _ = watch.pollCount();
        watch.stop();
    }
    return true;
}
