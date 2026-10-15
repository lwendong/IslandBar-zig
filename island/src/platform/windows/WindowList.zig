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
    group_id: TaskbarCatalog.WindowId = 0,
    handle: HWND = null,
    process_id: DWORD = 0,
    process_created_at: u64 = 0,
    executable_path: [260]u16 = @splat(0),
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
extern "user32" fn GetAncestor(window: HWND, flags: UINT) callconv(.winapi) HWND;
extern "user32" fn GetWindowTextW(window: HWND, title: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn GetWindowRect(window: HWND, rect: *Monitor.Rect) callconv(.winapi) BOOL;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn CloseHandle(handle: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn GetProcessTimes(process: ?*anyopaque, created: *FileTime, exited: *FileTime, kernel: *FileTime, user: *FileTime) callconv(.winapi) BOOL;
extern "kernel32" fn QueryFullProcessImageNameW(process: ?*anyopaque, flags: DWORD, path: [*]u16, size: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn CompareStringOrdinal(string_a: [*]const u16, length_a: i32, string_b: [*]const u16, length_b: i32, ignore_case: BOOL) callconv(.winapi) i32;
extern "user32" fn EnumWindows(callback: *const fn (HWND, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn GetForegroundWindow() callconv(.winapi) HWND;
extern "user32" fn SetWinEventHook(event_min: DWORD, event_max: DWORD, module: ?*anyopaque, callback: *const fn (?*anyopaque, DWORD, HWND, i32, i32, DWORD, DWORD) callconv(.winapi) void, process_id: DWORD, thread_id: DWORD, flags: DWORD) callconv(.winapi) ?*anyopaque;
extern "user32" fn UnhookWinEvent(hook: ?*anyopaque) callconv(.winapi) BOOL;
extern "user32" fn InvalidateRect(window: HWND, rect: ?*Monitor.Rect, erase: BOOL) callconv(.winapi) BOOL;
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
const ProcessIdentity = struct {
    created_at: u64 = 0,
    executable_path: [process_path_capacity]u16 = @splat(0),
};
const process_query_limited_information: DWORD = 0x1000;
const process_path_capacity: usize = 260;
const compare_string_equal: i32 = 2;
const dwm_attribute_cloaked: DWORD = 14;
const exstyle_index: i32 = -20;
const ex_tool_window: isize = 0x80;
const ex_app_window: isize = 0x40000;
const gw_owner: UINT = 4;
const ga_rootowner: UINT = 3;
const wm_syscommand: UINT = 0x0112;
const sc_restore: WPARAM = 0xf120;
const sc_minimize: WPARAM = 0xf020;
const smto_abort_if_hung: UINT = 2;
const sw_restore: i32 = 9;
const sw_show_normal: DWORD = 1;
const asfw_any: DWORD = std.math.maxInt(DWORD);
const event_system_foreground: DWORD = 0x0003;
const event_system_minimize_start: DWORD = 0x0016;
const event_system_minimize_end: DWORD = 0x0017;
const event_object_create: DWORD = 0x8000;
const event_object_destroy: DWORD = 0x8001;
const event_object_show: DWORD = 0x8002;
const event_object_hide: DWORD = 0x8003;
const event_object_state_change: DWORD = 0x800a;
const event_object_name_change: DWORD = 0x800c;
const objid_window: i32 = 0;
const childid_self: i32 = 0;
const winevent_outofcontext: DWORD = 0;
const winevent_skip_own_process: DWORD = 2;

const EventRange = struct { first: DWORD, last: DWORD };

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
    next_group_id: TaskbarCatalog.WindowId = 1,
    event_hooks: [5]?*anyopaque = @splat(null),
    notification_window: HWND = null,
    refreshing: bool = false,
    event_refresh_pending: bool = false,

    pub fn refresh(self: *WindowList) usize {
        const previous_entries = self.entries;
        const previous_count = self.count;
        const previous_foreground = self.foreground;
        var enumerated: [max_task_windows]TaskEntry = @splat(.{});
        var context = EnumContext{ .self_process_id = GetCurrentProcessId(), .entries = &enumerated };
        self.total_seen = 0;
        const foreground_window = GetForegroundWindow();
        _ = EnumWindows(enumProc, @intCast(@intFromPtr(&context)));
        const listed = context.listed;
        self.foreground = taskbarForegroundWindow(foreground_window, enumerated[0..listed]);
        var process_cache: [max_task_windows]ProcessIdentity = @splat(.{});
        var cached_process_ids: [max_task_windows]DWORD = @splat(0);
        var cache_count: usize = 0;
        for (enumerated[0..listed], 0..) |*entry, index| {
            var identity = ProcessIdentity{};
            var identity_cached = false;
            for (0..cache_count) |cached_index| {
                if (cached_process_ids[cached_index] == entry.process_id) {
                    identity = process_cache[cached_index];
                    identity_cached = true;
                    break;
                }
            }
            if (!identity_cached) identity = queryProcessIdentity(entry.process_id);
            entry.process_created_at = identity.created_at;
            entry.executable_path = identity.executable_path;
            if (cache_count < process_cache.len) {
                cached_process_ids[cache_count] = entry.process_id;
                process_cache[cache_count] = identity;
                cache_count += 1;
            }
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
            for (previous_entries[0..previous_count]) |previous| {
                if (sameApplication(previous, entry.*)) {
                    entry.group_id = previous.group_id;
                    break;
                }
            }
            if (entry.group_id == 0) {
                for (enumerated[0..index]) |previous| {
                    if (sameApplication(previous, entry.*)) {
                        entry.group_id = previous.group_id;
                        break;
                    }
                }
            }
            if (entry.group_id == 0) {
                entry.group_id = self.next_group_id;
                self.next_group_id +%= 1;
                if (self.next_group_id == 0) self.next_group_id = 1;
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

    /// Mirrors taskbar-relevant top-level window changes on the UI thread.
    /// A periodic refresh in App remains as a recovery path if a hook fails.
    pub fn startEventTracking(self: *WindowList, owner_window: HWND) bool {
        if (owner_window == null) return false;
        if (active_event_list) |active| {
            if (active != self) return false;
        }
        for (self.event_hooks) |hook| if (hook != null) return true;

        active_event_list = self;
        self.notification_window = owner_window;
        const ranges = [_]EventRange{
            .{ .first = event_system_foreground, .last = event_system_foreground },
            .{ .first = event_system_minimize_start, .last = event_system_minimize_end },
            .{ .first = event_object_create, .last = event_object_hide },
            .{ .first = event_object_state_change, .last = event_object_state_change },
            .{ .first = event_object_name_change, .last = event_object_name_change },
        };
        var installed: usize = 0;
        for (ranges, 0..) |range, index| {
            self.event_hooks[index] = SetWinEventHook(
                range.first,
                range.last,
                null,
                windowEventProc,
                0,
                0,
                winevent_outofcontext | winevent_skip_own_process,
            );
            if (self.event_hooks[index] != null) installed += 1;
        }
        if (installed == 0) {
            active_event_list = null;
            self.notification_window = null;
        }
        return installed > 0;
    }

    pub fn stopEventTracking(self: *WindowList) void {
        for (&self.event_hooks) |*hook| {
            if (hook.*) |handle| _ = UnhookWinEvent(handle);
            hook.* = null;
        }
        if (active_event_list == self) active_event_list = null;
        self.notification_window = null;
        self.event_refresh_pending = false;
    }

    pub fn snapshot(self: *const WindowList, output: *TaskbarCatalog.Snapshot) void {
        output.* = .{ .revision = self.revision };
        for (self.entries[0..self.count]) |entry| {
            if (entry.group_id == 0 or output.find(entry.group_id) != null) continue;
            const representative = self.representativeForGroup(entry.group_id) orelse continue;
            var group_window_count: usize = 0;
            for (self.entries[0..self.count]) |member| {
                if (member.group_id == entry.group_id) group_window_count += 1;
            }
            output.entries[output.count] = .{
                .id = entry.group_id,
                .process_id = representative.process_id,
                .process_created_at = representative.process_created_at,
                .iconic = representative.iconic,
                .window_count = group_window_count,
                .title = representative.title,
            };
            if (self.foregroundBelongsToGroup(entry.group_id)) output.foreground_id = entry.group_id;
            output.count += 1;
        }
    }

    pub fn activateIdentity(self: *WindowList, request: TaskbarCatalog.Request) bool {
        if (request.catalog_revision != self.revision) return false;
        const target = self.activationTarget(request.id) orelse return false;
        if (!self.identityIsCurrent(target)) return false;
        return self.activate(target.handle);
    }

    pub fn minimizeIdentity(self: *WindowList, request: TaskbarCatalog.Request) bool {
        if (request.catalog_revision != self.revision) return false;
        const active = self.findHandle(self.foreground) orelse return false;
        if (active.group_id != request.id or !self.identityIsCurrent(active)) return false;
        return self.minimize(active.handle);
    }

    /// Returns a live HWND only while the exact catalog revision and process
    /// instance are still current. Thumbnail consumers must not keep stale
    /// window handles across catalog refreshes.
    pub fn handleForIdentity(self: *const WindowList, request: TaskbarCatalog.Request) ?HWND {
        if (request.catalog_revision != self.revision) return null;
        const entry = self.representativeForGroup(request.id) orelse return null;
        if (!self.identityIsCurrent(entry)) return null;
        return entry.handle;
    }

    /// Supplies the representative HWND for the current render snapshot. This
    /// is only used as an icon-cache key; actions and previews use the verified
    /// revision-bound handle above.
    pub fn handleForTaskGroup(self: *const WindowList, group_id: TaskbarCatalog.WindowId) HWND {
        const entry = self.representativeForGroup(group_id) orelse return null;
        return entry.handle;
    }

    fn representativeForGroup(self: *const WindowList, group_id: TaskbarCatalog.WindowId) ?*const TaskEntry {
        var first: ?*const TaskEntry = null;
        var first_restored: ?*const TaskEntry = null;
        for (self.entries[0..self.count]) |*entry| {
            if (entry.group_id != group_id) continue;
            if (first == null) first = entry;
            if (entry.handle == self.foreground) return entry;
            if (!entry.iconic and first_restored == null) first_restored = entry;
        }
        return first_restored orelse first;
    }

    fn activationTarget(self: *const WindowList, group_id: TaskbarCatalog.WindowId) ?*const TaskEntry {
        var members: [max_task_windows]*const TaskEntry = undefined;
        var member_count: usize = 0;
        var foreground_index: ?usize = null;
        for (self.entries[0..self.count]) |*entry| {
            if (entry.group_id != group_id) continue;
            members[member_count] = entry;
            if (entry.handle == self.foreground) foreground_index = member_count;
            member_count += 1;
        }
        if (member_count == 0) return null;
        if (foreground_index) |active_index| {
            if (member_count > 1) {
                for (1..member_count) |offset| {
                    const candidate = members[(active_index + offset) % member_count];
                    if (!candidate.iconic) return candidate;
                }
                return members[(active_index + 1) % member_count];
            }
            return members[active_index];
        }
        for (members[0..member_count]) |member| if (!member.iconic) return member;
        return members[0];
    }

    fn foregroundBelongsToGroup(self: *const WindowList, group_id: TaskbarCatalog.WindowId) bool {
        const active = self.findHandle(self.foreground) orelse return false;
        return active.group_id == group_id;
    }

    fn findHandle(self: *const WindowList, handle: HWND) ?*const TaskEntry {
        if (handle == null) return null;
        for (self.entries[0..self.count]) |*entry| if (entry.handle == handle) return entry;
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

var active_event_list: ?*WindowList = null;

fn windowEventProc(
    hook: ?*anyopaque,
    event: DWORD,
    window: HWND,
    object_id: i32,
    child_id: i32,
    event_thread: DWORD,
    event_time: DWORD,
) callconv(.winapi) void {
    _ = hook;
    _ = event_thread;
    _ = event_time;
    const list = active_event_list orelse return;
    if (!isTaskbarWindowEvent(event, window, object_id, child_id)) return;
    if (list.refreshing) {
        list.event_refresh_pending = true;
        return;
    }

    const old_revision = list.revision;
    const old_count = list.count;
    const old_foreground = list.foreground;
    list.refreshing = true;
    defer list.refreshing = false;
    for (0..2) |_| {
        list.event_refresh_pending = false;
        _ = list.refresh();
        if (!list.event_refresh_pending) break;
    }
    if (list.revision != old_revision or list.count != old_count or list.foreground != old_foreground) {
        _ = InvalidateRect(list.notification_window, null, 0);
    }
}

fn isTaskbarWindowEvent(event: DWORD, window: HWND, object_id: i32, child_id: i32) bool {
    if (event == event_system_foreground) return true;
    if (window == null or object_id != objid_window or child_id != childid_self) return false;
    return event == event_system_minimize_start or event == event_system_minimize_end or
        (event >= event_object_create and event <= event_object_hide) or
        event == event_object_state_change or event == event_object_name_change;
}

fn queryProcessIdentity(process_id: DWORD) ProcessIdentity {
    if (process_id == 0) return .{};
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return .{};
    defer _ = CloseHandle(process);
    var created = FileTime{ .low = 0, .high = 0 };
    var exited = FileTime{ .low = 0, .high = 0 };
    var kernel = FileTime{ .low = 0, .high = 0 };
    var user = FileTime{ .low = 0, .high = 0 };
    if (GetProcessTimes(process, &created, &exited, &kernel, &user) == 0) return .{};
    var identity = ProcessIdentity{ .created_at = (@as(u64, created.high) << 32) | created.low };
    var path_length: DWORD = @intCast(identity.executable_path.len);
    if (QueryFullProcessImageNameW(process, 0, &identity.executable_path, &path_length) != 0 and path_length < identity.executable_path.len) {
        identity.executable_path[path_length] = 0;
    } else {
        identity.executable_path = @splat(0);
    }
    return identity;
}

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

fn sameApplication(a: TaskEntry, b: TaskEntry) bool {
    const path_a = std.mem.sliceTo(&a.executable_path, 0);
    const path_b = std.mem.sliceTo(&b.executable_path, 0);
    if (path_a.len > 0 and path_b.len > 0) {
        return path_a.len == path_b.len and
            CompareStringOrdinal(path_a.ptr, @intCast(path_a.len), path_b.ptr, @intCast(path_b.len), 1) == compare_string_equal;
    }
    return a.process_id != 0 and a.process_id == b.process_id and
        a.process_created_at != 0 and a.process_created_at == b.process_created_at;
}

fn sameCatalog(old: []const TaskEntry, current: []const TaskEntry, old_foreground: HWND, current_foreground: HWND) bool {
    if (old_foreground != current_foreground or old.len != current.len) return false;
    for (old, current) |a, b| {
        if (a.id != b.id or a.group_id != b.group_id or a.iconic != b.iconic or !std.mem.eql(u16, &a.title, &b.title)) return false;
    }
    return true;
}

fn taskbarForegroundWindow(foreground: HWND, entries: []const TaskEntry) HWND {
    if (foreground == null) return null;
    for (entries) |entry| if (entry.handle == foreground) return foreground;

    const root_owner = GetAncestor(foreground, ga_rootowner);
    if (root_owner != null) {
        for (entries) |entry| if (entry.handle == root_owner) return root_owner;
    }
    return foreground;
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
