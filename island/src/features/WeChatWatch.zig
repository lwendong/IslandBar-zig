const std = @import("std");
const NotificationModule = @import("Notification");
const Log = @import("Log");

const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const LPARAM = isize;
const PROCESS_QUERY_LIMITED_INFORMATION: DWORD = 0x1000;
const FALSE: BOOL = 0;
const max_windows = 512;
const announce_cooldown_ms: u64 = 5000;
const toast_min_width = 140;
const toast_max_width = 720;
const toast_min_height = 48;
const toast_max_height = 340;
const WindowCallback = *const fn (HWND, LPARAM) callconv(.winapi) BOOL;

const Rect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };

extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, size: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "user32" fn EnumWindows(callback: WindowCallback, param: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "user32" fn GetClassNameW(window: HWND, class_name: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn GetWindowTextW(window: HWND, text: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn GetWindowRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;

const WindowRecord = struct {
    handle: i64 = 0,
    pid: DWORD = 0,
    class_name: [256]u16 = @splat(0),
    title: [256]u16 = @splat(0),
    visible: bool = false,
    left: i32 = 0,
    top: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
};

const WindowVisit = struct {
    records: [max_windows]WindowRecord = undefined,
    count: usize = 0,
};

const Seen = struct {
    handle: i64 = 0,
    toast: bool = false,
    visible: bool = false,
    width: i32 = 0,
    height: i32 = 0,
    title: [128]u16 = @splat(0),
};

fn wideSlice(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn containsWide(text_arg: []const u16, needle: []const u16) bool {
    return std.mem.indexOf(u16, wideSlice(text_arg), needle) != null;
}

fn copyWide(destination: []u16, source: []const u16) void {
    if (destination.len == 0) return;
    @memset(destination, 0);
    const input = wideSlice(source);
    const count = @min(input.len, destination.len - 1);
    @memcpy(destination[0..count], input[0..count]);
}

fn copyUtf8(destination: []u8, source: []const u8) void {
    if (destination.len == 0) return;
    @memset(destination, 0);
    const count = @min(source.len, destination.len - 1);
    @memcpy(destination[0..count], source[0..count]);
}

fn processNameMatches(path_arg: []const u16) bool {
    const path = wideSlice(path_arg);
    var name_start: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        name_start = index + 1;
    };
    const name = path[name_start..];
    if (name.len < 6) return false;
    const weixin = [_]u16{ 'W', 'e', 'i', 'x', 'i', 'n' };
    const wechat = [_]u16{ 'W', 'e', 'C', 'h', 'a', 't' };
    return widePrefixIgnoreCase(name, &weixin) or widePrefixIgnoreCase(name, &wechat);
}

fn widePrefixIgnoreCase(text: []const u16, prefix: []const u16) bool {
    if (text.len < prefix.len) return false;
    for (text[0..prefix.len], prefix) |a, b| {
        const lower_a = if (a >= 'A' and a <= 'Z') a + ('a' - 'A') else a;
        const lower_b = if (b >= 'A' and b <= 'Z') b + ('a' - 'A') else b;
        if (lower_a != lower_b) return false;
    }
    return true;
}

fn looksLikeWeChatProcess(pid: DWORD) bool {
    if (pid == 0) return false;
    const process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid) orelse return false;
    defer _ = CloseHandle(process);
    var path: [260]u16 = @splat(0);
    var length: DWORD = @intCast(path.len);
    if (QueryFullProcessImageNameW(process, 0, &path, &length) == FALSE) return false;
    return processNameMatches(path[0..@min(length, path.len)]);
}

fn collectWindow(window: HWND, param: LPARAM) callconv(.winapi) BOOL {
    const visit: *WindowVisit = @ptrFromInt(@as(usize, @bitCast(param)));
    if (visit.count >= visit.records.len) return FALSE;
    var pid: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &pid);
    if (pid == 0 or !looksLikeWeChatProcess(pid)) return 1;

    var record = WindowRecord{};
    record.handle = @intCast(@intFromPtr(window));
    record.pid = pid;
    _ = GetClassNameW(window, &record.class_name, @intCast(record.class_name.len));
    _ = GetWindowTextW(window, &record.title, @intCast(record.title.len));
    var rect = Rect{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    _ = GetWindowRect(window, &rect);
    record.visible = IsWindowVisible(window) != FALSE;
    record.left = rect.left;
    record.top = rect.top;
    record.width = rect.right - rect.left;
    record.height = rect.bottom - rect.top;
    visit.records[visit.count] = record;
    visit.count += 1;
    return 1;
}

fn countProcessWindow(window: HWND, param: LPARAM) callconv(.winapi) BOOL {
    var pid: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &pid);
    if (pid != 0 and looksLikeWeChatProcess(pid)) {
        const found: *bool = @ptrFromInt(@as(usize, @bitCast(param)));
        found.* = true;
        return FALSE;
    }
    return 1;
}

pub fn isWeChatProcess(pid: DWORD) bool {
    return looksLikeWeChatProcess(pid);
}

pub fn processImagePath(pid: DWORD, output: []u16) bool {
    if (output.len == 0 or pid == 0) return false;
    @memset(output, 0);
    const process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid) orelse return false;
    defer _ = CloseHandle(process);
    var length: DWORD = @intCast(@min(output.len - 1, std.math.maxInt(DWORD)));
    if (QueryFullProcessImageNameW(process, 0, output.ptr, &length) == FALSE) return false;
    output[@min(length, output.len - 1)] = 0;
    return length != 0;
}

pub fn anyWeChatProcessRunning() bool {
    var found = false;
    _ = EnumWindows(countProcessWindow, @bitCast(@as(usize, @intFromPtr(&found))));
    return found;
}

pub fn looksLikeWeChatToast(class_name: ?[]const u16, title: ?[]const u16, visible: bool, width: i32, height: i32) bool {
    if (!visible or width < toast_min_width or width > toast_max_width or height < toast_min_height or height > toast_max_height) return false;
    if (class_name) |class| {
        if (containsWide(class, &.{ 'T', 'r', 'a', 'y', 'I', 'c', 'o', 'n', 'M', 'e', 's', 's', 'a', 'g', 'e', 'W', 'i', 'n', 'd', 'o', 'w' })) return false;
        if (containsWide(class, &.{ 'B', 'a', 's', 'e', '_', 'P', 'o', 'w', 'e', 'r', 'M', 'e', 's', 's', 'a', 'g', 'e', 'W', 'i', 'n', 'd', 'o', 'w' })) return false;
        if (containsWide(class, &.{ 'C', 'h', 'r', 'o', 'm', 'e', '_' })) return false;
        if (containsWide(class, &.{ 'I', 'M', 'E' })) return false;
        if (containsWide(class, &.{ 'S', 'y', 's', 't', 'e', 'm', 'M', 'e', 's', 's', 'a', 'g', 'e', 'W', 'i', 'n', 'd', 'o', 'w' })) return false;
    }
    _ = title;
    return true;
}

pub fn looksLikeWeChatCall(title: ?[]const u16, visible: bool) bool {
    if (!visible) return false;
    const value = title orelse return false;
    const actual = wideSlice(value);
    if (actual.len == 0) return false;
    return containsWide(actual, &.{ 0x97F3, 0x89C6, 0x9891, 0x901A, 0x8BDD });
}

pub fn shouldAnnounceWeChatSound(wechat_running: bool, was_active: bool, is_active: bool, was_sessions: i32, sessions: i32, primed: bool, since_last_announce_ms: u64) bool {
    if (!wechat_running or !primed) return false;
    const became_active = !was_active and is_active;
    const new_session = sessions > was_sessions;
    return (became_active or new_session) and since_last_announce_ms >= announce_cooldown_ms;
}

pub const WeChatWatcher = struct {
    call_notification_id: i64 = 0,
    call_start_ms: u64 = 0,
    call_pid: DWORD = 0,
    wechat_audio_was_active: bool = false,
    wechat_audio_sessions: i32 = 0,
    wechat_audio_primed: bool = false,
    last_sound_announce_ms: u64 = 0,
    sound_announcements: i32 = 0,
    last_handle: i64 = 0,
    last_announce_ms: u64 = 0,
    announced: i32 = 0,
    seen: [max_windows]Seen = @splat(.{}),
    seen_count: usize = 0,

    pub fn soundAnnouncements(self: *const WeChatWatcher) i32 {
        return self.sound_announcements;
    }

    pub fn announcementCount(self: *const WeChatWatcher) i32 {
        return self.announced;
    }

    pub fn pollSound(self: *WeChatWatcher, store: ?*NotificationModule.Store, wechat_running: bool, session_active: bool, session_count: i32, now_ms: u64) usize {
        const destination = store orelse return 0;
        const since = now_ms -% self.last_sound_announce_ms;
        const announce = shouldAnnounceWeChatSound(wechat_running, self.wechat_audio_was_active, session_active, self.wechat_audio_sessions, session_count, self.wechat_audio_primed, since);
        if (!self.wechat_audio_primed or session_active != self.wechat_audio_was_active or session_count != self.wechat_audio_sessions) Log.logLine("wechat: audio state changed");
        self.wechat_audio_was_active = session_active;
        self.wechat_audio_sessions = session_count;
        self.wechat_audio_primed = true;
        if (!announce) return 0;

        var notification = NotificationModule.Notification{};
        copyUtf8(&notification.app, "微信");
        copyUtf8(&notification.title, "有新消息");
        _ = destination.pushAt(notification, now_ms);
        self.last_sound_announce_ms = now_ms;
        self.sound_announcements += 1;
        Log.logLine("wechat: announced a notification sound");
        return 1;
    }

    pub fn poll(self: *WeChatWatcher, store: ?*NotificationModule.Store, now_ms: u64) usize {
        const destination = store orelse return 0;
        var visit = WindowVisit{};
        _ = EnumWindows(collectWindow, @bitCast(@as(usize, @intFromPtr(&visit))));

        var current: [max_windows]Seen = @splat(.{});
        var current_count: usize = 0;
        var call_up = false;
        for (visit.records[0..visit.count]) |*window| {
            if (looksLikeWeChatCall(&window.title, window.visible)) {
                call_up = true;
                self.call_pid = window.pid;
            }
            const toast = looksLikeWeChatToast(&window.class_name, &window.title, window.visible, window.width, window.height);
            var snapshot = Seen{ .handle = window.handle, .toast = toast, .visible = window.visible, .width = window.width, .height = window.height };
            copyWide(&snapshot.title, &window.title);
            current[current_count] = snapshot;
            current_count += 1;

            var known: ?*const Seen = null;
            for (self.seen[0..self.seen_count]) |*old| {
                if (old.handle == window.handle) {
                    known = old;
                    break;
                }
            }
            if (known) |old| {
                if (old.visible != snapshot.visible or old.width != snapshot.width or old.height != snapshot.height or !std.mem.eql(u16, wideSlice(&old.title), wideSlice(&snapshot.title))) {
                    Log.logLine(if (toast) "wechat: tracked window changed; toast-sized" else "wechat: tracked window changed; not toast-sized");
                }
            } else {
                Log.logLine(if (toast) "wechat: window appeared; toast-sized" else "wechat: window appeared; not toast-sized");
            }

            if (!toast) continue;
            if (window.handle == self.last_handle and now_ms -% self.last_announce_ms < announce_cooldown_ms) continue;
            if (now_ms -% self.last_announce_ms < announce_cooldown_ms) continue;

            var notification = NotificationModule.Notification{};
            copyUtf8(&notification.app, "微信");
            copyUtf8(&notification.title, "有新消息");
            notification.urgency = .normal;
            _ = destination.pushAt(notification, now_ms);
            self.last_handle = window.handle;
            self.last_announce_ms = now_ms;
            self.announced += 1;
            self.seen = current;
            self.seen_count = current_count;
            Log.logLine("wechat: announced a toast window");
            return 1;
        }
        self.seen = current;
        self.seen_count = current_count;

        if (call_up and self.call_notification_id == 0) {
            var call = NotificationModule.Notification{};
            copyUtf8(&call.app, "微信");
            copyUtf8(&call.title, "通话中");
            call.sticky = true;
            const stored = destination.pushAt(call, now_ms);
            self.call_notification_id = stored.id;
            self.call_start_ms = now_ms;
            Log.logLine("wechat: call started");
            return 1;
        } else if (!call_up and self.call_notification_id != 0) {
            _ = destination.markRead(self.call_notification_id);
            self.call_notification_id = 0;
            self.call_start_ms = 0;
            self.call_pid = 0;
            Log.logLine("wechat: call ended");
        }
        return 0;
    }
};

pub fn smokeCheck() bool {
    const class_name: []const u16 = &.{ 'T', 'r', 'a', 'y', 'I', 'c', 'o', 'n', 'M', 'e', 's', 's', 'a', 'g', 'e', 'W', 'i', 'n', 'd', 'o', 'w', 0 };
    const call_title: []const u16 = &.{ 0x5FAE, 0x4FE1, 0x97F3, 0x89C6, 0x9891, 0x901A, 0x8BDD, 0 };
    if (looksLikeWeChatToast(class_name, null, true, 300, 180)) return false;
    if (!looksLikeWeChatToast(null, null, true, 300, 180)) return false;
    if (looksLikeWeChatToast(null, null, false, 300, 180) or looksLikeWeChatToast(null, null, true, 1, 1)) return false;
    if (!looksLikeWeChatCall(call_title, true) or looksLikeWeChatCall(call_title, false) or looksLikeWeChatCall(null, true)) return false;
    if (shouldAnnounceWeChatSound(true, false, true, 1, 1, false, 9000)) return false;
    if (shouldAnnounceWeChatSound(false, false, true, 1, 2, true, 9000)) return false;
    if (shouldAnnounceWeChatSound(true, false, true, 1, 1, true, 4999)) return false;
    if (!shouldAnnounceWeChatSound(true, false, true, 1, 1, true, 5000)) return false;
    if (!shouldAnnounceWeChatSound(true, true, true, 1, 2, true, 5000)) return false;
    return true;
}

comptime {
    if (false) {
        var watcher = WeChatWatcher{};
        var store = NotificationModule.Store{};
        _ = watcher.poll(&store, 10);
        _ = watcher.pollSound(&store, true, true, 1, 10);
        _ = anyWeChatProcessRunning();
        _ = isWeChatProcess(1);
    }
}
