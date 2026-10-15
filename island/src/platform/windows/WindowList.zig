const std = @import("std");
const Monitor = @import("Monitor");

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
    handle: HWND = null,
    process_id: DWORD = 0,
    iconic: bool = false,
    title: [title_capacity]u16 = @splat(0),
    mark: u64 = 0,
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
        .mark = process_id,
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
    order: [max_task_windows]HWND = @splat(null),
    order_count: usize = 0,

    pub fn refresh(self: *WindowList) usize {
        var context = EnumContext{ .self_process_id = GetCurrentProcessId(), .entries = &self.entries };
        self.total_seen = 0;
        self.foreground = GetForegroundWindow();
        _ = EnumWindows(enumProc, @intCast(@intFromPtr(&context)));
        const listed = context.listed;
        var next: [max_task_windows]HWND = @splat(null);
        var next_count: usize = 0;
        for (self.order[0..self.order_count]) |previous| {
            if (next_count >= max_task_windows) break;
            for (self.entries[0..listed]) |entry| if (entry.handle == previous) {
                next[next_count] = previous;
                next_count += 1;
                break;
            };
        }
        for (self.entries[0..listed]) |entry| {
            if (next_count >= max_task_windows) break;
            var exists = false;
            for (next[0..next_count]) |handle| if (handle == entry.handle) {
                exists = true;
                break;
            };
            if (!exists) {
                next[next_count] = entry.handle;
                next_count += 1;
            }
        }
        self.order = next;
        self.order_count = next_count;
        var stable: [max_task_windows]TaskEntry = @splat(.{});
        for (next[0..next_count], 0..) |handle, index| {
            for (self.entries[0..listed]) |entry| if (entry.handle == handle) {
                stable[index] = entry;
                break;
            };
        }
        self.entries = stable;
        self.count = @min(self.order_count, listed);
        const skipped = context.cloaked_skipped + context.untitled_skipped + context.owned_skipped + context.tool_skipped + context.shell_skipped + context.self_skipped + context.invisible_skipped;
        self.total_seen = listed + skipped;
        formatSummary(&self.summary, "{d} listed of {d}: {d} invisible, {d} cloaked, {d} untitled, {d} owned, {d} tool, {d} shell, {d} self", .{
            self.count,               self.total_seen,       context.invisible_skipped, context.cloaked_skipped,
            context.untitled_skipped, context.owned_skipped, context.tool_skipped,      context.shell_skipped,
            context.self_skipped,
        });
        return self.count;
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
