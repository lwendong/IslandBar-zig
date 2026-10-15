const std = @import("std");
const TrayCatalog = @import("TrayCatalog");

const HANDLE = ?*anyopaque;
const HKEY = HANDLE;
const DWORD = u32;
const BOOL = i32;
const BYTE = u8;
const ACCESS_READ: DWORD = 0x20019;
const KEY_QUERY_VALUE: DWORD = 1;
const REG_SZ: DWORD = 1;
const REG_BINARY: DWORD = 3;
const REG_DWORD: DWORD = 4;
const TH32CS_SNAPPROCESS: DWORD = 2;
const ERROR_SUCCESS: i32 = 0;
const INVALID_HANDLE_VALUE: usize = std.math.maxInt(usize);
const png_capacity = 16 * 1024;
const max_name = 260;
const max_icons = 256;

const FileTime = extern struct { low: DWORD, high: DWORD };
const ProcessEntry32W = extern struct {
    size: DWORD,
    usage: DWORD,
    process_id: DWORD,
    default_heap_id: usize,
    module_id: DWORD,
    threads: DWORD,
    parent_process_id: DWORD,
    base_priority: i32,
    flags: DWORD,
    exe_file: [max_name]u16,
};
const Guid = TrayCatalog.Guid;
pub const IconInfo = TrayCatalog.Icon;
const Entry = struct {
    icon: IconInfo = .{},
    written_at: u64 = 0,
    png_storage: []u8 = &.{},
};

extern "kernel32" fn CreateToolhelp32Snapshot(flags: DWORD, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Process32FirstW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn Process32NextW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "advapi32" fn RegOpenKeyExW(key: HKEY, subkey: [*:0]const u16, options: DWORD, access: DWORD, result: *HKEY) callconv(.winapi) i32;
extern "advapi32" fn RegCloseKey(key: HKEY) callconv(.winapi) i32;
extern "advapi32" fn RegEnumKeyExW(key: HKEY, index: DWORD, name: [*]u16, name_length: *DWORD, reserved: ?*DWORD, class_name: ?[*]u16, class_length: ?*DWORD, last_write: ?*FileTime) callconv(.winapi) i32;
extern "advapi32" fn RegQueryValueExW(key: HKEY, value_name: [*:0]const u16, reserved: ?*DWORD, value_type: ?*DWORD, data: ?[*]BYTE, data_size: *DWORD) callconv(.winapi) i32;
extern "advapi32" fn RegQueryInfoKeyW(key: HKEY, class_name: ?[*]u16, class_length: ?*DWORD, reserved: ?*DWORD, subkeys: ?*DWORD, max_subkey_length: ?*DWORD, max_class_length: ?*DWORD, values: ?*DWORD, max_value_name_length: ?*DWORD, max_value_length: ?*DWORD, security_descriptor_length: ?*DWORD, last_write: ?*FileTime) callconv(.winapi) i32;
extern "ole32" fn CLSIDFromString(text: [*:0]const u16, guid: *Guid) callconv(.winapi) i32;

const current_user_key: HKEY = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2147483647))));
const settings_key: [*:0]const u16 = &.{ 'C', 'o', 'n', 't', 'r', 'o', 'l', ' ', 'P', 'a', 'n', 'e', 'l', '\\', 'N', 'o', 't', 'i', 'f', 'y', 'I', 'c', 'o', 'n', 'S', 'e', 't', 't', 'i', 'n', 'g', 's', 0 };
const value_executable: [*:0]const u16 = &.{ 'E', 'x', 'e', 'c', 'u', 't', 'a', 'b', 'l', 'e', 'P', 'a', 't', 'h', 0 };
const value_snapshot: [*:0]const u16 = &.{ 'I', 'c', 'o', 'n', 'S', 'n', 'a', 'p', 's', 'h', 'o', 't', 0 };
const value_promoted: [*:0]const u16 = &.{ 'I', 's', 'P', 'r', 'o', 'm', 'o', 't', 'e', 'd', 0 };
const value_uid: [*:0]const u16 = &.{ 'U', 'I', 'D', 0 };
const value_guid: [*:0]const u16 = &.{ 'I', 'c', 'o', 'n', 'G', 'u', 'i', 'd', 0 };
const value_tooltip: [*:0]const u16 = &.{ 'I', 'n', 'i', 't', 'i', 'a', 'l', 'T', 'o', 'o', 'l', 't', 'i', 'p', 0 };

fn wideSlice(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn asciiLower(unit: u16) u16 {
    return if (unit >= 'A' and unit <= 'Z') unit + ('a' - 'A') else unit;
}

fn equalWideIgnoreCase(a_arg: []const u16, b_arg: []const u16) bool {
    const a = wideSlice(a_arg);
    const b = wideSlice(b_arg);
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (asciiLower(x) != asciiLower(y)) return false;
    return true;
}

fn basename(path_arg: []const u16) []const u16 {
    const path = wideSlice(path_arg);
    var offset: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        offset = index + 1;
    };
    return path[offset..];
}

fn keyIsRunning(running: []const [max_name]u16, exe_path: []const u16) bool {
    const exe_name = basename(exe_path);
    for (running) |name| if (equalWideIgnoreCase(exe_name, &name)) return true;
    return false;
}

fn closeFileHandle(handle: HANDLE) void {
    if (handle) |value| {
        if (@intFromPtr(value) != INVALID_HANDLE_VALUE) _ = CloseHandle(handle);
    }
}

fn collectRunningProcesses(allocator: std.mem.Allocator, names: *std.ArrayList([max_name]u16)) void {
    const snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == null or @intFromPtr(snapshot.?) == INVALID_HANDLE_VALUE) return;
    defer closeFileHandle(snapshot);
    var process = std.mem.zeroes(ProcessEntry32W);
    process.size = @sizeOf(ProcessEntry32W);
    if (Process32FirstW(snapshot, &process) == 0) return;
    while (true) {
        var name = process.exe_file;
        for (&name) |*unit| unit.* = asciiLower(unit.*);
        names.append(allocator, name) catch return;
        if (Process32NextW(snapshot, &process) == 0) break;
    }
}

fn readStringValue(key: HKEY, name: [*:0]const u16, output: []u16) void {
    if (output.len == 0) return;
    @memset(output, 0);
    var kind: DWORD = 0;
    var bytes: DWORD = 0;
    if (RegQueryValueExW(key, name, null, &kind, null, &bytes) != ERROR_SUCCESS or kind != REG_SZ or bytes == 0) return;
    var max_bytes = @min(bytes, @as(DWORD, @intCast((output.len - 1) * @sizeOf(u16))));
    if (RegQueryValueExW(key, name, null, &kind, @ptrCast(output.ptr), &max_bytes) == ERROR_SUCCESS) output[output.len - 1] = 0;
}

fn readBinaryValue(allocator: std.mem.Allocator, key: HKEY, name: [*:0]const u16) ?[]u8 {
    var kind: DWORD = 0;
    var bytes: DWORD = 0;
    if (RegQueryValueExW(key, name, null, &kind, null, &bytes) != ERROR_SUCCESS or kind != REG_BINARY or bytes == 0 or bytes > png_capacity) return null;
    const data = allocator.alloc(u8, bytes) catch return null;
    var actual = bytes;
    if (RegQueryValueExW(key, name, null, &kind, data.ptr, &actual) != ERROR_SUCCESS or actual == 0) {
        allocator.free(data);
        return null;
    }
    if (actual != data.len) return allocator.realloc(data, actual) catch {
        allocator.free(data);
        return null;
    };
    return data;
}

fn keyLastWriteTime(subkey: []const u16) u64 {
    var key: HKEY = null;
    var path: [512]u16 = @splat(0);
    const prefix = "Control Panel\\NotifyIconSettings\\";
    for (prefix, 0..) |unit, index| path[index] = unit;
    const name = wideSlice(subkey);
    if (prefix.len + name.len >= path.len) return 0;
    @memcpy(path[prefix.len .. prefix.len + name.len], name);
    path[prefix.len + name.len] = 0;
    if (RegOpenKeyExW(current_user_key, @ptrCast(&path), 0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS) return 0;
    defer _ = RegCloseKey(key);
    var written = FileTime{ .low = 0, .high = 0 };
    if (RegQueryInfoKeyW(key, null, null, null, null, null, null, null, null, null, null, &written) != ERROR_SUCCESS) return 0;
    return (@as(u64, written.high) << 32) | written.low;
}

fn entryBefore(a: Entry, b: Entry) bool {
    return a.written_at > b.written_at;
}

fn insertionSort(entries: []Entry) void {
    var i: usize = 1;
    while (i < entries.len) : (i += 1) {
        var j = i;
        while (j > 0 and entryBefore(entries[j], entries[j - 1])) : (j -= 1) std.mem.swap(Entry, &entries[j], &entries[j - 1]);
    }
}

fn copyWide(out: []u16, input: []const u16) void {
    if (out.len == 0) return;
    @memset(out, 0);
    const text = wideSlice(input);
    @memcpy(out[0..@min(out.len - 1, text.len)], text[0..@min(out.len - 1, text.len)]);
}

fn sameEntry(a: *const Entry, b: *const Entry) bool {
    return equalWideIgnoreCase(&a.icon.name, &b.icon.name) and
        equalWideIgnoreCase(&a.icon.exe_path, &b.icon.exe_path) and
        a.icon.uid == b.icon.uid and a.icon.has_uid == b.icon.has_uid and
        a.icon.has_guid == b.icon.has_guid and std.meta.eql(a.icon.guid, b.icon.guid) and
        a.icon.promoted == b.icon.promoted and a.written_at == b.written_at and
        a.png_storage.len == b.png_storage.len and std.mem.eql(u8, a.png_storage, b.png_storage);
}

pub const TrayIcons = struct {
    entries: std.ArrayList(Entry) = .empty,
    list: std.ArrayList(IconInfo) = .empty,
    revision: u64 = 1,
    examined: i32 = 0,
    running_apps: i32 = 0,
    processes_seen: i32 = 0,

    pub fn deinit(self: *TrayIcons, allocator: std.mem.Allocator) void {
        for (self.entries.items) |entry| allocator.free(entry.png_storage);
        self.entries.deinit(allocator);
        self.list.deinit(allocator);
        self.* = .{};
    }

    pub fn count(self: *const TrayIcons) usize {
        return self.list.items.len;
    }

    pub fn at(self: *const TrayIcons, index: usize) ?*const IconInfo {
        if (index >= self.list.items.len) return null;
        return &self.list.items[index];
    }

    pub fn exePathAt(self: *const TrayIcons, index: usize) ?[]const u16 {
        if (index >= self.entries.items.len) return null;
        return wideSlice(&self.entries.items[index].icon.exe_path);
    }

    pub fn getRevision(self: *const TrayIcons) u64 {
        return self.revision;
    }

    pub fn getExamined(self: *const TrayIcons) i32 {
        return self.examined;
    }

    pub fn getRunningApps(self: *const TrayIcons) i32 {
        return self.running_apps;
    }

    pub fn getProcessesSeen(self: *const TrayIcons) i32 {
        return self.processes_seen;
    }

    pub fn refresh(self: *TrayIcons, allocator: std.mem.Allocator) usize {
        var running = std.ArrayList([max_name]u16).empty;
        defer running.deinit(allocator);
        collectRunningProcesses(allocator, &running);
        self.processes_seen = @intCast(running.items.len);

        var root: HKEY = null;
        if (RegOpenKeyExW(current_user_key, settings_key, 0, ACCESS_READ, &root) != ERROR_SUCCESS) {
            self.clearEntries(allocator);
            self.examined = 0;
            self.running_apps = 0;
            return 0;
        }
        defer _ = RegCloseKey(root);

        var fresh = std.ArrayList(Entry).empty;
        defer {
            for (fresh.items) |entry| allocator.free(entry.png_storage);
            fresh.deinit(allocator);
        }
        self.examined = 0;
        self.running_apps = 0;
        var index: DWORD = 0;
        while (true) {
            var subkey_name: [256]u16 = @splat(0);
            var subkey_len: DWORD = @intCast(subkey_name.len);
            if (RegEnumKeyExW(root, index, &subkey_name, &subkey_len, null, null, null, null) != ERROR_SUCCESS) break;
            index += 1;
            var subkey: HKEY = null;
            if (RegOpenKeyExW(root, @ptrCast(&subkey_name), 0, ACCESS_READ, &subkey) != ERROR_SUCCESS) continue;
            self.examined += 1;
            var entry = Entry{};
            readStringValue(subkey, value_executable, &entry.icon.exe_path);
            if (readBinaryValue(allocator, subkey, value_snapshot)) |png| entry.png_storage = png;
            var promoted: DWORD = 0;
            var size = @as(DWORD, @sizeOf(DWORD));
            var kind: DWORD = 0;
            if (RegQueryValueExW(subkey, value_promoted, null, &kind, @ptrCast(&promoted), &size) == ERROR_SUCCESS and kind == REG_DWORD) entry.icon.promoted = promoted != 0;
            var uid: DWORD = 0;
            size = @sizeOf(DWORD);
            kind = 0;
            if (RegQueryValueExW(subkey, value_uid, null, &kind, @ptrCast(&uid), &size) == ERROR_SUCCESS and kind == REG_DWORD) {
                entry.icon.uid = uid;
                entry.icon.has_uid = true;
            }
            var guid_text: [64]u16 = @splat(0);
            readStringValue(subkey, value_guid, &guid_text);
            if (wideSlice(&guid_text).len > 0) {
                var guid: Guid = std.mem.zeroes(Guid);
                if (CLSIDFromString(@ptrCast(&guid_text), &guid) >= 0) {
                    entry.icon.guid = guid;
                    entry.icon.has_guid = true;
                }
            }
            _ = RegCloseKey(subkey);

            const png = entry.png_storage;
            if (png.len < 8 or png[0] != 0x89 or png[1] != 0x50 or !keyIsRunning(running.items, &entry.icon.exe_path)) {
                allocator.free(entry.png_storage);
                continue;
            }
            self.running_apps += 1;
            var tooltip: [256]u16 = @splat(0);
            if (RegOpenKeyExW(root, @ptrCast(&subkey_name), 0, ACCESS_READ, &subkey) == ERROR_SUCCESS) {
                readStringValue(subkey, value_tooltip, &tooltip);
                _ = RegCloseKey(subkey);
            }
            if (wideSlice(&tooltip).len == 0) copyWide(&tooltip, basename(&entry.icon.exe_path));
            copyWide(&entry.icon.name, &tooltip);
            entry.icon.png = entry.png_storage;
            entry.written_at = keyLastWriteTime(&subkey_name);
            fresh.append(allocator, entry) catch {
                allocator.free(entry.png_storage);
                break;
            };
            if (fresh.items.len >= max_icons) break;
        }
        insertionSort(fresh.items);
        var changed = fresh.items.len != self.entries.items.len;
        if (!changed) for (fresh.items, self.entries.items) |*a, *b| {
            if (!sameEntry(a, b)) {
                changed = true;
                break;
            }
        };

        self.clearEntries(allocator);
        self.entries = fresh;
        fresh = .empty;
        for (self.entries.items) |*entry| {
            entry.icon.png = entry.png_storage;
            self.list.append(allocator, entry.icon) catch {};
        }
        if (changed) self.revision +%= 1;
        return self.count();
    }

    fn clearEntries(self: *TrayIcons, allocator: std.mem.Allocator) void {
        for (self.entries.items) |entry| allocator.free(entry.png_storage);
        self.entries.clearRetainingCapacity();
        self.list.clearRetainingCapacity();
    }

    pub fn settingsKeyPath() []const u16 {
        return settings_key[0..32];
    }
};

pub fn smokeCheck() bool {
    var icons = TrayIcons{};
    if (icons.count() != 0 or icons.getRevision() != 1 or icons.getExamined() != 0) return false;
    if (icons.at(0) != null or icons.exePathAt(0) != null) return false;
    const path: []const u16 = &.{ 'C', ':', '\\', 'P', 'r', 'o', 'g', 'r', 'a', 'm', '.', 'E', 'X', 'E', 0 };
    const names = [_][max_name]u16{wideProcessName("program.exe")};
    return keyIsRunning(&names, path);
}

fn wideProcessName(comptime name: []const u8) [max_name]u16 {
    var output: [max_name]u16 = @splat(0);
    for (name, 0..) |char, index| output[index] = std.ascii.toLower(char);
    return output;
}

comptime {
    if (false) {
        var icons = TrayIcons{};
        _ = icons.refresh(std.heap.page_allocator);
        icons.deinit(std.heap.page_allocator);
    }
}
