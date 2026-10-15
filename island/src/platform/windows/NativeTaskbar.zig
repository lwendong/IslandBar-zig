const Log = @import("Log");

const HANDLE = ?*anyopaque;
const HWND = HANDLE;
const HMONITOR = HANDLE;
const DWORD = u32;
const BOOL = i32;
const FALSE: BOOL = 0;
const TRUE: BOOL = 1;
const RECT = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const MonitorInfo = extern struct { size: DWORD, monitor: RECT, work: RECT, flags: DWORD };
const SidAndAttributes = extern struct { sid: ?*anyopaque, attributes: DWORD };
const TokenMandatoryLabel = extern struct { label: SidAndAttributes };

extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn GetCurrentProcess() callconv(.winapi) HANDLE;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "user32" fn FindWindowW(class_name: ?[*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn FindWindowExW(parent: HWND, child_after: HWND, class_name: ?[*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn IsWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) BOOL;
extern "user32" fn GetDesktopWindow() callconv(.winapi) HWND;
extern "user32" fn MonitorFromWindow(window: HWND, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn GetMonitorInfoW(monitor: HMONITOR, info: *MonitorInfo) callconv(.winapi) BOOL;
extern "user32" fn SystemParametersInfoW(action: UINT, param: UINT, value: *RECT, flags: UINT) callconv(.winapi) BOOL;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "advapi32" fn OpenProcessToken(process: HANDLE, access: DWORD, token: *HANDLE) callconv(.winapi) BOOL;
extern "advapi32" fn GetTokenInformation(token: HANDLE, info_class: i32, buffer: [*]u8, buffer_size: DWORD, returned: *DWORD) callconv(.winapi) BOOL;
extern "advapi32" fn GetSidSubAuthorityCount(sid: ?*anyopaque) callconv(.winapi) ?*u8;
extern "advapi32" fn GetSidSubAuthority(sid: ?*anyopaque, index: DWORD) callconv(.winapi) ?*DWORD;

const UINT = u32;
const PROCESS_QUERY_LIMITED_INFORMATION: DWORD = 0x1000;
const TOKEN_QUERY: DWORD = 0x0008;
const TOKEN_INTEGRITY_LEVEL: i32 = 25;
const MONITOR_DEFAULTTONEAREST: DWORD = 2;
const SPI_SETWORKAREA: UINT = 0x002F;
const SPI_GETWORKAREA: UINT = 0x0030;
const SPIF_SENDCHANGE: UINT = 0x0002;
const SW_HIDE: i32 = 0;
const SW_SHOW: i32 = 5;
const tray_class: [*:0]const u16 = &.{ 'S', 'h', 'e', 'l', 'l', '_', 'T', 'r', 'a', 'y', 'W', 'n', 'd', 0 };
const secondary_tray_class: [*:0]const u16 = &.{ 'S', 'h', 'e', 'l', 'l', '_', 'S', 'e', 'c', 'o', 'n', 'd', 'a', 'r', 'y', 'T', 'r', 'a', 'y', 'W', 'n', 'd', 0 };
const tray_notify_class: [*:0]const u16 = &.{ 'T', 'r', 'a', 'y', 'N', 'o', 't', 'i', 'f', 'y', 'W', 'n', 'd', 0 };

pub const WorkAreaRelease = struct {
    released: bool = false,
    changed: bool = false,
    before: RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    after: RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
};

fn sameRect(a: RECT, b: RECT) bool {
    return a.left == b.left and a.top == b.top and a.right == b.right and a.bottom == b.bottom;
}

fn readWorkArea(out: *RECT) bool {
    return SystemParametersInfoW(SPI_GETWORKAREA, 0, out, 0) != FALSE;
}

fn writeWorkArea(value_arg: RECT) bool {
    var value = value_arg;
    return SystemParametersInfoW(SPI_SETWORKAREA, 0, &value, SPIF_SENDCHANGE) != FALSE;
}

fn integrityRid(process: HANDLE, rid: *DWORD) bool {
    var token: HANDLE = null;
    if (OpenProcessToken(process, TOKEN_QUERY, &token) == FALSE) return false;
    defer _ = CloseHandle(token);
    var buffer: [256]u8 align(8) = @splat(0);
    var returned: DWORD = 0;
    if (GetTokenInformation(token, TOKEN_INTEGRITY_LEVEL, &buffer, buffer.len, &returned) == FALSE) return false;
    const mandatory: *const TokenMandatoryLabel = @ptrCast(@alignCast(&buffer));
    const sid = mandatory.label.sid orelse return false;
    const count_ptr = GetSidSubAuthorityCount(sid) orelse return false;
    if (count_ptr.* == 0) return false;
    const sub_authority = GetSidSubAuthority(sid, @as(DWORD, count_ptr.*) - 1) orelse return false;
    rid.* = sub_authority.*;
    return true;
}

pub const NativeTaskbar = struct {
    tray_window: HWND = null,
    tray_notify: HWND = null,
    was_visible: bool = false,
    we_hid_it: bool = false,
    located: bool = false,
    work_before: RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    have_work_before: bool = false,
    released_work_area: bool = false,

    pub fn deinit(self: *NativeTaskbar) void {
        self.restore();
    }

    pub fn locate(self: *NativeTaskbar) bool {
        self.tray_window = FindWindowW(tray_class, null);
        self.tray_notify = if (self.tray_window) |tray| FindWindowExW(tray, null, tray_notify_class, null) else null;
        if (self.tray_window) |tray| {
            self.was_visible = IsWindowVisible(tray) != FALSE;
            self.located = true;
        } else {
            self.located = false;
        }
        return self.tray_window != null;
    }

    pub fn hide(self: *NativeTaskbar) bool {
        if (self.tray_window == null or IsWindow(self.tray_window) == FALSE) _ = self.locate();
        const tray = self.tray_window orelse return false;
        if (!self.we_hid_it) self.was_visible = IsWindowVisible(tray) != FALSE;
        if (self.was_visible or self.we_hid_it) _ = ShowWindow(tray, SW_HIDE);
        var secondary = FindWindowW(secondary_tray_class, null);
        while (secondary) |window| {
            _ = ShowWindow(window, SW_HIDE);
            secondary = FindWindowExW(null, window, secondary_tray_class, null);
        }
        if (self.tray_notify) |notify| _ = ShowWindow(notify, SW_HIDE);
        self.we_hid_it = true;
        return IsWindowVisible(tray) == FALSE;
    }

    pub fn restore(self: *NativeTaskbar) void {
        self.restoreWorkArea();
        if (!self.we_hid_it or !self.was_visible) {
            self.we_hid_it = false;
            return;
        }
        if (self.tray_window == null or IsWindow(self.tray_window) == FALSE) self.tray_window = FindWindowW(tray_class, null);
        if (self.tray_window) |tray| {
            _ = ShowWindow(tray, SW_SHOW);
            if (self.tray_notify) |notify| _ = ShowWindow(notify, SW_SHOW);
        }
        var secondary = FindWindowW(secondary_tray_class, null);
        while (secondary) |window| {
            _ = ShowWindow(window, SW_SHOW);
            secondary = FindWindowExW(null, window, secondary_tray_class, null);
        }
        self.we_hid_it = false;
    }

    pub fn ensureHidden(self: *NativeTaskbar) bool {
        if (!self.we_hid_it) {
            if (self.tray_window == null or IsWindow(self.tray_window) == FALSE) {
                if (!self.locate()) return false;
            }
            if (IsWindowVisible(self.tray_window) == FALSE) return false;
            return self.hide();
        }
        if (self.tray_window != null and IsWindow(self.tray_window) == FALSE) {
            self.handleExplorerRestart();
            return self.hide();
        }
        const tray = self.tray_window orelse return self.hide();
        if (IsWindowVisible(tray) != FALSE) return self.hide();
        var secondary = FindWindowW(secondary_tray_class, null);
        while (secondary) |window| {
            if (IsWindowVisible(window) != FALSE) return self.hide();
            secondary = FindWindowExW(null, window, secondary_tray_class, null);
        }
        return false;
    }

    fn taskbarMonitorBounds(self: *const NativeTaskbar, out: *RECT) bool {
        const reference = if (self.tray_window) |tray| if (IsWindow(tray) != FALSE) tray else GetDesktopWindow() else GetDesktopWindow();
        const monitor = MonitorFromWindow(reference, MONITOR_DEFAULTTONEAREST) orelse return false;
        var info = MonitorInfo{ .size = @sizeOf(MonitorInfo), .monitor = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .work = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .flags = 0 };
        if (GetMonitorInfoW(monitor, &info) == FALSE) return false;
        out.* = info.monitor;
        return true;
    }

    pub fn releaseWorkArea(self: *NativeTaskbar) WorkAreaRelease {
        var result = WorkAreaRelease{};
        if (!self.we_hid_it) return result;
        var screen: RECT = undefined;
        if (!self.taskbarMonitorBounds(&screen)) return result;
        var before: RECT = undefined;
        if (!readWorkArea(&before)) return result;
        result.before = before;
        if (!self.have_work_before) {
            self.work_before = before;
            self.have_work_before = true;
        }
        if (sameRect(before, screen)) {
            self.released_work_area = true;
            result.released = true;
            result.after = before;
            return result;
        }
        if (!writeWorkArea(screen)) return result;
        var after: RECT = undefined;
        if (!readWorkArea(&after)) return result;
        result.after = after;
        self.released_work_area = sameRect(after, screen);
        result.released = self.released_work_area;
        result.changed = !sameRect(before, after);
        return result;
    }

    pub fn ensureWorkAreaReleased(self: *NativeTaskbar) WorkAreaRelease {
        var result = WorkAreaRelease{};
        if (!self.we_hid_it or !self.released_work_area) return result;
        var screen: RECT = undefined;
        if (!self.taskbarMonitorBounds(&screen)) return result;
        var now: RECT = undefined;
        if (!readWorkArea(&now)) return result;
        result.before = now;
        result.after = now;
        if (sameRect(now, screen)) {
            result.released = true;
            return result;
        }
        if (!writeWorkArea(screen)) return result;
        var after: RECT = undefined;
        if (!readWorkArea(&after)) return result;
        result.after = after;
        self.released_work_area = sameRect(after, screen);
        result.released = self.released_work_area;
        result.changed = !sameRect(now, after);
        return result;
    }

    pub fn restoreWorkArea(self: *NativeTaskbar) void {
        if (!self.have_work_before) return;
        const written = writeWorkArea(self.work_before);
        var after: RECT = undefined;
        const read = readWorkArea(&after);
        if (written and read and sameRect(after, self.work_before)) {
            Log.logLine("taskbar work area restored and confirmed");
        } else {
            Log.logLine("taskbar work area restore could not be confirmed");
        }
        self.have_work_before = false;
        self.released_work_area = false;
    }

    pub fn workAreaReleased(self: *const NativeTaskbar) bool {
        return self.released_work_area;
    }

    pub fn isFound(self: *const NativeTaskbar) bool {
        return self.tray_window != null;
    }

    pub fn isVisible(self: *const NativeTaskbar) bool {
        const tray = self.tray_window orelse return false;
        return IsWindow(tray) != FALSE and IsWindowVisible(tray) != FALSE;
    }

    pub fn weHidIt(self: *const NativeTaskbar) bool {
        return self.we_hid_it;
    }

    pub fn isBlockedByIntegrity(self: *const NativeTaskbar) bool {
        const tray = self.tray_window orelse return false;
        var tray_pid: DWORD = 0;
        _ = GetWindowThreadProcessId(tray, &tray_pid);
        if (tray_pid == 0) return false;
        var current_rid: DWORD = 0;
        var tray_rid: DWORD = 0;
        if (!integrityRid(GetCurrentProcess(), &current_rid)) return false;
        const process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, tray_pid) orelse return false;
        defer _ = CloseHandle(process);
        if (!integrityRid(process, &tray_rid)) return false;
        return current_rid < tray_rid;
    }

    fn handleExplorerRestart(self: *NativeTaskbar) void {
        self.we_hid_it = true;
        self.located = false;
    }
};

pub fn smokeCheck() bool {
    const rect = RECT{ .left = -10, .top = 2, .right = 300, .bottom = 400 };
    if (!sameRect(rect, rect)) return false;
    if (sameRect(rect, .{ .left = -10, .top = 2, .right = 301, .bottom = 400 })) return false;
    const taskbar = NativeTaskbar{};
    return !taskbar.isFound() and !taskbar.isVisible() and !taskbar.weHidIt() and !taskbar.workAreaReleased();
}

comptime {
    if (false) {
        var taskbar = NativeTaskbar{};
        _ = taskbar.locate();
        _ = taskbar.hide();
        _ = taskbar.ensureHidden();
        _ = taskbar.releaseWorkArea();
        _ = taskbar.ensureWorkAreaReleased();
        taskbar.restore();
        _ = taskbar.isBlockedByIntegrity();
        taskbar.deinit();
    }
}
