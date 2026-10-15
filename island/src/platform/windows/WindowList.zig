const std = @import("std");
const Monitor = @import("Monitor");
const TaskbarCatalog = @import("TaskbarCatalog");

pub const max_task_windows = 32;
pub const title_capacity = 128;
const HWND = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const LPARAM = isize;
const WPARAM = usize;

pub const WindowTraits = struct {
    has_title: bool = false,
    visible: bool = false,
    iconic: bool = false,
    tool_window: bool = false,
    app_window: bool = false,
    has_owner: bool = false,
    cloaked: bool = false,
    has_size: bool = false,
    is_shell: bool = false,
    is_self: bool = false,
};

pub const TaskEntry = struct {
    id: TaskbarCatalog.WindowId = 0,
    handle: HWND = null,
    process_id: DWORD = 0,
    process_created_at: u64 = 0,
    iconic: bool = false,
    title: [title_capacity]u16 = @splat(0),
};

pub fn shouldListWindow(traits: WindowTraits) bool {
    if (traits.is_self or traits.is_shell or !traits.visible or traits.cloaked or !traits.has_size) return false;
    if (!traits.has_title and !traits.app_window) return false;
    if (traits.app_window) return true;
    if (traits.has_owner or traits.tool_window) return false;
    return true;
}

pub fn pickNextWindow(entries: []const TaskEntry, current: HWND) ?usize {
    if (entries.len == 0) return null;
    var fallback: ?usize = null;
    for (entries, 0..) |entry, index| {
        if (entry.handle == current) continue;
        if (fallback == null) fallback = index;
        if (!entry.iconic) return index;
    }
    if (fallback) |index| return index;
    for (entries, 0..) |entry, index| if (entry.handle == current) return index;
    return null;
}

const Point = extern struct { x: i32, y: i32 };
const WindowPlacement = extern struct {
    length: DWORD,
    flags: DWORD,
    show_cmd: DWORD,
    min_position: Point,
    max_position: Point,
    normal_position: Monitor.Rect,
};

extern "dwmapi" fn DwmGetWindowAttribute(window: HWND, attribute: DWORD, value: *anyopaque, size: DWORD) callconv(.winapi) i32;
extern "user32" fn GetClassNameW(window: HWND, name: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn IsIconic(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn GetWindowLongPtrW(window: HWND, index: i32) callconv(.winapi) isize;
extern "user32" fn GetWindow(window: HWND, command: UINT) callconv(.winapi) HWND;
extern "user32" fn GetWindowTextW(window: HWND, title: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn GetWindowRect(window: HWND, rect: *Monitor.Rect) callconv(.winapi) BOOL;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn CloseHandle(handle: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn GetProcessTimes(process: ?*anyopaque, created: *FileTime, exited: *FileTime, kernel: *FileTime, user: *FileTime) callconv(.winapi) BOOL;
extern "user32" fn EnumWindows(callback: *const fn (HWND, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn GetForegroundWindow() callconv(.winapi) HWND;
extern "user32" fn IsWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn SendMessageTimeoutW(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM, flags: UINT, timeout: UINT, result: *usize) callconv(.winapi) usize;
extern "user32" fn GetWindowPlacement(window: HWND, placement: *WindowPlacement) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPlacement(window: HWND, placement: *const WindowPlacement) callconv(.winapi) BOOL;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) BOOL;
extern "user32" fn SetForegroundWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn AllowSetForegroundWindow(process_id: DWORD) callconv(.winapi) BOOL;
extern "user32" fn GetCurrentThreadId() callconv(.winapi) DWORD;
extern "user32" fn AttachThreadInput(from_thread: DWORD, to_thread: DWORD, attach: BOOL) callconv(.winapi) BOOL;
extern "user32" fn BringWindowToTop(window: HWND) callconv(.winapi) BOOL;

const UINT = u32;
const FileTime = extern struct { low: DWORD, high: DWORD };
const process_query_limited_information: DWORD = 0x1000;
const dwm_attribute_cloaked: DWORD = 14;
const exstyle_index: i32 = -20;
const ex_tool_window: isize = 0x80;
const ex_app_window: isize = 0x40000;
const gw_owner: UINT = 4;
const wm_syscommand: UINT = 0x0112;
const sc_restore: WPARAM = 0xf120;
const sc_minimize: WPARAM = 0xf020;
const smto_abort_if_hung: UINT = 2;
const sw_restore: i32 = 9;
const sw_show_normal: DWORD = 1;
const asfw_any: DWORD = std.math.maxInt(DWORD);

pub fn foregroundWindow() HWND {
    return GetForegroundWindow();
}

fn asciiClassEql(actual: []const u16, expected: []const u8) bool {
    if (actual.len != expected.len) return false;
    for (actual, expected) |a, b| {
        const lower = if (a >= 'A' and a <= 'Z') a + ('a' - 'A') else a;
        const expected_lower = if (b >= 'A' and b <= 'Z') b + ('a' - 'A') else b;
        if (lower != expected_lower) return false;
    }
    return true;
}

fn isShellWindow(window: HWND) bool {
    var class_name: [128]u16 = @splat(0);
    const length = GetClassNameW(window, &class_name, class_name.len);
    if (length <= 0) return false;
    const name = class_name[0..@intCast(length)];
    const classes = [_][]const u8{
        "Shell_TrayWnd",                "Shell_SecondaryTrayWnd",                "Progman",               "WorkerW",
        "Windows.UI.Core.CoreWindow",   "ApplicationManager_DesktopShellWindow", "MultitaskingViewFrame", "ForegroundStaging",
        "XamlExplorerHostIslandWindow", "TaskListThumbnailWnd",
    };
    for (classes) |class| if (asciiClassEql(name, class)) return true;
    return false;
}

fn isCloaked(window: HWND) bool {
    var cloaked: DWORD = 0;
    return DwmGetWindowAttribute(window, dwm_attribute_cloaked, &cloaked, @sizeOf(DWORD)) >= 0 and cloaked != 0;
}

const EnumContext = struct {
    self_process_id: DWORD,
    listed: usize = 0,
    cloaked_skipped: usize = 0,
    untitled_skipped: usize = 0,
    invisible_skipped: usize = 0,
    owned_skipped: usize = 0,
    tool_skipped: usize = 0,
    shell_skipped: usize = 0,
    self_skipped: usize = 0,
    entries: *[max_task_windows]TaskEntry,
};

fn enumProc(window: HWND, parameter: LPARAM) callconv(.winapi) BOOL {
    const context: *EnumContext = @ptrFromInt(@as(usize, @intCast(parameter)));
    if (IsWindowVisible(window) == 0) {
        context.invisible_skipped += 1;
        return 1;
    }
    var process_id: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &process_id);
    const ex_style = GetWindowLongPtrW(window, exstyle_index);
    var title: [title_capacity]u16 = @splat(0);
    const title_length = GetWindowTextW(window, &title, title.len);
    var rect: Monitor.Rect = .{};
    const has_rect = GetWindowRect(window, &rect) != 0;
    const traits = WindowTraits{
        .visible = true,
        .iconic = IsIconic(window) != 0,
        .tool_window = (ex_style & ex_tool_window) != 0,
        .app_window = (ex_style & ex_app_window) != 0,
        .has_owner = GetWindow(window, gw_owner) != null,
        .cloaked = isCloaked(window),
        .has_title = title_length > 0,
        .has_size = has_rect and rect.right > rect.left and rect.bottom > rect.top,
        .is_shell = isShellWindow(window),
        .is_self = process_id == context.self_process_id,
    };
    if (!shouldListWindow(traits)) {
        if (traits.cloaked) context.cloaked_skipped += 1 else if (traits.is_shell) context.shell_skipped += 1 else if (traits.is_self) context.self_skipped += 1 else if (!traits.has_title and !traits.app_window) context.untitled_skipped += 1 else if (traits.has_owner) context.owned_skipped += 1 else if (traits.tool_window) context.tool_skipped += 1;
        return 1;
    }
    if (context.listed >= max_task_windows) return 0;
    context.entries[context.listed] = .{
        .handle = window,
        .process_id = process_id,
        .iconic = traits.iconic,
        .title = title,
    };
    context.listed += 1;
    return 1;
}

fn copyWide(destination: []u16, source: []const u16) void {
    if (destination.len == 0) return;
    const text = source[0 .. std.mem.indexOfScalar(u16, source, 0) orelse source.len];
    const count = @min(text.len, destination.len - 1);
    @memcpy(destination[0..count], text[0..count]);
    destination[count] = 0;
}

fn formatSummary(output: *[192]u16, comptime format: []const u8, args: anytype) void {
    var bytes: [192]u8 = undefined;
    const text = std.fmt.bufPrint(&bytes, format, args) catch return;
    @memset(output, 0);
    for (text[0..@min(text.len, output.len - 1)], 0..) |byte, index| output[index] = byte;
}

pub const WindowList = struct {
    entries: [max_task_windows]TaskEntry = @splat(.{}),
    count: usize = 0,
    foreground: HWND = null,
    total_seen: usize = 0,
    summary: [192]u16 = @splat(0),
    revision: u64 = 0,
    next_window_id: TaskbarCatalog.WindowId = 1,

    pub fn refresh(self: *WindowList) usize {
        const previous_entries = self.entries;
        const previous_count = self.count;
        const previous_foreground = self.foreground;
        var enumerated: [max_task_windows]TaskEntry = @splat(.{});
        var context = EnumContext{ .self_process_id = GetCurrentProcessId(), .entries = &enumerated };
        self.total_seen = 0;
        self.foreground = GetForegroundWindow();
        _ = EnumWindows(enumProc, @intCast(@intFromPtr(&context)));
        const listed = context.listed;
        for (enumerated[0..listed]) |*entry| {
            entry.process_created_at = processCreatedAt(entry.process_id) orelse 0;
            for (previous_entries[0..previous_count]) |previous| {
                if (!sameWindowInstance(previous, entry.*)) continue;
                entry.id = previous.id;
                break;
            }
            if (entry.id == 0) {
                entry.id = self.next_window_id;
                self.next_window_id +%= 1;
                if (self.next_window_id == 0) self.next_window_id = 1;
            }
        }
        var next: [max_task_windows]TaskEntry = @splat(.{});
        var next_count: usize = 0;
        for (previous_entries[0..previous_count]) |previous| {
            for (enumerated[0..listed]) |entry| if (entry.id == previous.id) {
                next[next_count] = entry;
                next_count += 1;
                break;
            };
        }
        for (enumerated[0..listed]) |entry| {
            if (next_count >= max_task_windows) break;
            var exists = false;
            for (next[0..next_count]) |prior| if (prior.id == entry.id) {
                exists = true;
                break;
            };
            if (!exists) {
                next[next_count] = entry;
                next_count += 1;
            }
        }
        self.entries = next;
        self.count = next_count;
        if (!sameCatalog(previous_entries[0..previous_count], self.entries[0..self.count], previous_foreground, self.foreground)) self.revision +%= 1;
        const skipped = context.cloaked_skipped + context.untitled_skipped + context.owned_skipped + context.tool_skipped + context.shell_skipped + context.self_skipped + context.invisible_skipped;
        self.total_seen = listed + skipped;
        formatSummary(&self.summary, "{d} listed of {d}: {d} invisible, {d} cloaked, {d} untitled, {d} owned, {d} tool, {d} shell, {d} self", .{
            self.count,               self.total_seen,       context.invisible_skipped, context.cloaked_skipped,
            context.untitled_skipped, context.owned_skipped, context.tool_skipped,      context.shell_skipped,
            context.self_skipped,
        });
        return self.count;
    }

    pub fn snapshot(self: *const WindowList, output: *TaskbarCatalog.Snapshot) void {
        output.* = .{ .count = self.count, .revision = self.revision };
        for (self.entries[0..self.count], 0..) |entry, index| {
            output.entries[index] = .{
                .id = entry.id,
                .process_id = entry.process_id,
                .process_created_at = entry.process_created_at,
                .iconic = entry.iconic,
                .title = entry.title,
            };
            if (entry.handle == self.foreground) output.foreground_id = entry.id;
        }
    }

    pub fn activateIdentity(self: *WindowList, request: TaskbarCatalog.Request) bool {
        const entry = self.findEntry(request.id) orelse return false;
        if (request.catalog_revision != self.revision or !self.identityIsCurrent(entry)) return false;
        return self.activate(entry.handle);
    }

    pub fn minimizeIdentity(self: *WindowList, request: TaskbarCatalog.Request) bool {
        const entry = self.findEntry(request.id) orelse return false;
        if (request.catalog_revision != self.revision or !self.identityIsCurrent(entry)) return false;
        return self.minimize(entry.handle);
    }

    /// Returns a live HWND only while the exact catalog revision and process
    /// instance are still current. Thumbnail consumers must not keep stale
    /// window handles across catalog refreshes.
    pub fn handleForIdentity(self: *const WindowList, request: TaskbarCatalog.Request) ?HWND {
        if (request.catalog_revision != self.revision) return null;
        const entry = self.findEntry(request.id) orelse return null;
        if (!self.identityIsCurrent(entry)) return null;
        return entry.handle;
    }

    fn findEntry(self: *const WindowList, id: TaskbarCatalog.WindowId) ?*const TaskEntry {
        for (self.entries[0..self.count]) |*entry| if (entry.id == id) return entry;
        return null;
    }

    fn identityIsCurrent(self: *const WindowList, entry: *const TaskEntry) bool {
        _ = self;
        if (entry.handle == null or IsWindow(entry.handle) == 0 or entry.process_created_at == 0) return false;
        var current_pid: DWORD = 0;
        _ = GetWindowThreadProcessId(entry.handle, &current_pid);
        if (current_pid != entry.process_id) return false;
        return (processCreatedAt(current_pid) orelse return false) == entry.process_created_at;
    }

    pub fn activate(self: *WindowList, window: HWND) bool {
        _ = self;
        if (window == null or IsWindow(window) == 0) return false;
        const was_iconic = IsIconic(window) != 0;
        if (was_iconic) requestRestore(window);
        const raised = SetForegroundWindow(window) != 0;
        if (raised and !was_iconic) return true;
        _ = AllowSetForegroundWindow(asfw_any);
        if (SetForegroundWindow(window) != 0) return IsIconic(window) == 0;
        var target_process: DWORD = 0;
        const target_thread = GetWindowThreadProcessId(window, &target_process);
        const self_thread = GetCurrentThreadId();
        if (target_thread == 0 or target_thread == self_thread) return false;
        if (AttachThreadInput(self_thread, target_thread, 1) != 0) {
            _ = BringWindowToTop(window);
            if (IsIconic(window) != 0) requestRestore(window);
            _ = SetForegroundWindow(window);
            _ = AttachThreadInput(self_thread, target_thread, 0);
        }
        return GetForegroundWindow() == window and IsIconic(window) == 0;
    }

    pub fn minimize(self: *WindowList, window: HWND) bool {
        _ = self;
        if (window == null or IsWindow(window) == 0) return false;
        if (IsIconic(window) != 0) return true;
        var ignored: usize = 0;
        _ = SendMessageTimeoutW(window, wm_syscommand, sc_minimize, 0, smto_abort_if_hung, 200, &ignored);
        return IsIconic(window) != 0;
    }
};

fn processCreatedAt(process_id: DWORD) ?u64 {
    if (process_id == 0) return null;
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
    defer _ = CloseHandle(process);
    var created = FileTime{ .low = 0, .high = 0 };
    var exited = FileTime{ .low = 0, .high = 0 };
    var kernel = FileTime{ .low = 0, .high = 0 };
    var user = FileTime{ .low = 0, .high = 0 };
    if (GetProcessTimes(process, &created, &exited, &kernel, &user) == 0) return null;
    return (@as(u64, created.high) << 32) | created.low;
}

fn sameWindowInstance(a: TaskEntry, b: TaskEntry) bool {
    return a.id != 0 and a.process_created_at != 0 and a.handle == b.handle and
        a.process_id == b.process_id and a.process_created_at == b.process_created_at;
}

fn sameCatalog(old: []const TaskEntry, current: []const TaskEntry, old_foreground: HWND, current_foreground: HWND) bool {
    if (old_foreground != current_foreground or old.len != current.len) return false;
    for (old, current) |a, b| {
        if (a.id != b.id or a.iconic != b.iconic or !std.mem.eql(u16, &a.title, &b.title)) return false;
    }
    return true;
}

fn requestRestore(window: HWND) void {
    var ignored: usize = 0;
    _ = SendMessageTimeoutW(window, wm_syscommand, sc_restore, 0, smto_abort_if_hung, 200, &ignored);
    if (IsIconic(window) == 0) return;
    var placement = WindowPlacement{
        .length = @sizeOf(WindowPlacement),
        .flags = 0,
        .show_cmd = 0,
        .min_position = .{ .x = 0, .y = 0 },
        .max_position = .{ .x = 0, .y = 0 },
        .normal_position = .{},
    };
    if (GetWindowPlacement(window, &placement) != 0) {
        placement.show_cmd = sw_show_normal;
        _ = SetWindowPlacement(window, &placement);
    }
    if (IsIconic(window) == 0) return;
    _ = ShowWindow(window, sw_restore);
}

pub fn smokeCheck() bool {
    const eligible = WindowTraits{ .has_title = true, .visible = true, .has_size = true };
    if (!shouldListWindow(eligible)) return false;
    if (shouldListWindow(.{ .visible = true, .has_size = true, .is_self = true })) return false;
    if (shouldListWindow(.{ .visible = true, .has_size = true, .has_title = true, .cloaked = true })) return false;
    if (!shouldListWindow(.{ .visible = true, .has_size = true, .app_window = true, .has_owner = true, .tool_window = true })) return false;
    const entries = [_]TaskEntry{
        .{ .handle = @ptrFromInt(1), .iconic = true },
        .{ .handle = @ptrFromInt(2), .iconic = false },
    };
    if (pickNextWindow(&entries, null) != 1) return false;
    if (false) {
        var list = WindowList{};
        _ = list.refresh();
        _ = list.activate(null);
        _ = list.minimize(null);
    }
    return true;
}

test "taskbar window identity includes HWND, PID and process creation time" {
    const first = TaskEntry{ .id = 1, .handle = @ptrFromInt(10), .process_id = 7, .process_created_at = 100 };
    try std.testing.expect(sameWindowInstance(first, first));
    try std.testing.expect(!sameWindowInstance(first, .{ .id = 2, .handle = @ptrFromInt(10), .process_id = 8, .process_created_at = 100 }));
    try std.testing.expect(!sameWindowInstance(first, .{ .id = 2, .handle = @ptrFromInt(10), .process_id = 7, .process_created_at = 101 }));
    try std.testing.expect(!sameWindowInstance(first, .{ .id = 2, .handle = @ptrFromInt(11), .process_id = 7, .process_created_at = 100 }));
}
