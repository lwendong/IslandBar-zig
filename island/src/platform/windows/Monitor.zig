pub const HMONITOR = ?*anyopaque;
const HWND = ?*anyopaque;
const HDC = ?*anyopaque;
const BOOL = i32;
const DWORD = u32;
const LPARAM = isize;
const HRESULT = i32;

pub const Rect = extern struct {
    left: i32 = 0,
    top: i32 = 0,
    right: i32 = 0,
    bottom: i32 = 0,
};

const Point = extern struct { x: i32, y: i32 };

const MonitorInfo = extern struct {
    size: DWORD,
    monitor: Rect,
    work: Rect,
    flags: DWORD,
};

pub const MonitorGeometry = struct {
    monitor: HMONITOR = null,
    screen: Rect = .{},
    work: Rect = .{},
    dpi: DWORD = 96,
    dpi_y: DWORD = 96,
    primary: bool = false,
};

pub const DockEdge = enum { none, top, bottom, left, right };

pub const BorderInflation = struct { x: i32 = 0, y: i32 = 0 };

pub fn screenWidth(monitor: MonitorGeometry) i32 {
    return monitor.screen.right - monitor.screen.left;
}

pub fn screenHeight(monitor: MonitorGeometry) i32 {
    return monitor.screen.bottom - monitor.screen.top;
}

pub fn workWidth(monitor: MonitorGeometry) i32 {
    return monitor.work.right - monitor.work.left;
}

pub fn workHeight(monitor: MonitorGeometry) i32 {
    return monitor.work.bottom - monitor.work.top;
}

pub fn insetEdge(monitor: MonitorGeometry) DockEdge {
    if (monitor.work.top > monitor.screen.top) return .top;
    if (monitor.work.bottom < monitor.screen.bottom) return .bottom;
    if (monitor.work.left > monitor.screen.left) return .left;
    if (monitor.work.right < monitor.screen.right) return .right;
    return .none;
}

pub fn taskbarThickness(monitor: MonitorGeometry) i32 {
    return switch (insetEdge(monitor)) {
        .top => monitor.work.top - monitor.screen.top,
        .bottom => monitor.screen.bottom - monitor.work.bottom,
        .left => monitor.work.left - monitor.screen.left,
        .right => monitor.screen.right - monitor.work.right,
        .none => 0,
    };
}

pub fn inflateRect(rect: Rect, x: i32, y: i32) Rect {
    return .{ .left = rect.left - x, .top = rect.top - y, .right = rect.right + x, .bottom = rect.bottom + y };
}

pub fn sameRect(left: Rect, right: Rect) bool {
    return left.left == right.left and left.top == right.top and left.right == right.right and left.bottom == right.bottom;
}

pub fn windowCoversMonitor(window: Rect, monitor: Rect) bool {
    return window.left <= monitor.left and window.top <= monitor.top and
        window.right >= monitor.right and window.bottom >= monitor.bottom;
}

extern "user32" fn MonitorFromPoint(point: Point, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn MonitorFromRect(rect: *const Rect, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn MonitorFromWindow(window: HWND, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn GetMonitorInfoW(monitor: HMONITOR, info: *MonitorInfo) callconv(.winapi) BOOL;
extern "user32" fn GetSystemMetrics(index: i32) callconv(.winapi) i32;
extern "user32" fn GetDC(window: HWND) callconv(.winapi) HDC;
extern "user32" fn ReleaseDC(window: HWND, dc: HDC) callconv(.winapi) i32;
extern "user32" fn EnumDisplayMonitors(dc: HDC, clip: ?*const Rect, callback: *const fn (HMONITOR, HDC, ?*Rect, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn GetForegroundWindow() callconv(.winapi) HWND;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn IsIconic(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn IsZoomed(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn GetWindowRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn GetClassNameW(window: HWND, class_name: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn FindWindowW(class_name: [*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn EnumWindows(callback: *const fn (HWND, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPos(window: HWND, insert_after: HWND, x: i32, y: i32, width: i32, height: i32, flags: DWORD) callconv(.winapi) BOOL;
extern "user32" fn GetDeviceCaps(dc: HDC, index: i32) callconv(.winapi) i32;
extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetProcAddress(module: ?*anyopaque, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "shcore" fn GetDpiForMonitor(monitor: HMONITOR, dpi_type: i32, dpi_x: *DWORD, dpi_y: *DWORD) callconv(.winapi) HRESULT;
extern "dwmapi" fn DwmGetWindowAttribute(window: HWND, attribute: DWORD, value: *anyopaque, size: DWORD) callconv(.winapi) HRESULT;

const GetSystemMetricsForDpiFn = *const fn (i32, DWORD) callconv(.winapi) i32;

const monitor_default_to_nearest: DWORD = 2;
const monitor_default_to_primary: DWORD = 1;
const monitor_info_primary: DWORD = 1;
const monitor_dpi_effective: i32 = 0;
const log_pixels_x: i32 = 88;
const metric_cx_screen: i32 = 0;
const metric_cy_screen: i32 = 1;
const metric_cx_size_frame: i32 = 32;
const metric_cy_size_frame: i32 = 33;
const metric_cx_padded_border: i32 = 92;
const metric_cy_padded_border: i32 = 92;
const dwm_attribute_cloaked: DWORD = 14;
const swp_no_activate: DWORD = 0x0010;
const swp_no_zorder: DWORD = 0x0004;
const swp_no_send_changing: DWORD = 0x0400;
const user32_module_name: [*:0]const u16 = &.{ 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 };

fn queryDpi(monitor: HMONITOR) DWORD {
    var dpi_x: DWORD = 96;
    var dpi_y: DWORD = 96;
    if (GetDpiForMonitor(monitor, monitor_dpi_effective, &dpi_x, &dpi_y) >= 0) return if (dpi_x != 0) dpi_x else 96;
    const dc = GetDC(null);
    if (dc) |screen| {
        const gdi_dpi = GetDeviceCaps(screen, log_pixels_x);
        _ = ReleaseDC(null, screen);
        if (gdi_dpi > 0) return @intCast(gdi_dpi);
    }
    return 96;
}

fn metricForDpi(index: i32, dpi: DWORD) i32 {
    const user32 = GetModuleHandleW(user32_module_name) orelse return GetSystemMetrics(index);
    const proc = GetProcAddress(user32, "GetSystemMetricsForDpi") orelse return GetSystemMetrics(index);
    const function: GetSystemMetricsForDpiFn = @ptrCast(@alignCast(proc));
    return function(index, dpi);
}

pub fn maximizedBorderPx(dpi: DWORD) BorderInflation {
    return .{
        .x = metricForDpi(metric_cx_size_frame, dpi) + metricForDpi(metric_cx_padded_border, dpi),
        .y = metricForDpi(metric_cy_size_frame, dpi) + metricForDpi(metric_cy_padded_border, dpi),
    };
}

pub fn looksLikeWindowsMaximizedRect(window: Rect, work_area: Rect, dpi: DWORD) bool {
    const border = maximizedBorderPx(dpi);
    return sameRect(window, inflateRect(work_area, border.x, border.y));
}

pub fn queryMonitor(monitor_arg: HMONITOR) MonitorGeometry {
    const monitor = monitor_arg orelse MonitorFromPoint(.{ .x = 0, .y = 0 }, monitor_default_to_primary);
    var geometry = MonitorGeometry{ .monitor = monitor };
    var info: MonitorInfo = .{ .size = @sizeOf(MonitorInfo), .monitor = .{}, .work = .{}, .flags = 0 };
    if (GetMonitorInfoW(monitor, &info) != 0) {
        geometry.screen = info.monitor;
        geometry.work = info.work;
        geometry.primary = (info.flags & monitor_info_primary) != 0;
    } else {
        geometry.screen = .{
            .left = 0,
            .top = 0,
            .right = GetSystemMetrics(metric_cx_screen),
            .bottom = GetSystemMetrics(metric_cy_screen),
        };
        geometry.work = geometry.screen;
    }
    geometry.dpi = queryDpi(monitor);
    geometry.dpi_y = geometry.dpi;
    return geometry;
}

pub fn queryMonitorForWindow(window: HWND) MonitorGeometry {
    return queryMonitor(MonitorFromWindow(window, monitor_default_to_nearest));
}

const MonitorCollector = struct {
    output: []MonitorGeometry,
    count: usize = 0,
};

fn collectMonitor(monitor: HMONITOR, _: HDC, _: ?*Rect, parameter: LPARAM) callconv(.winapi) BOOL {
    const collector: *MonitorCollector = @ptrFromInt(@as(usize, @intCast(parameter)));
    if (collector.count >= collector.output.len) return 0;
    collector.output[collector.count] = queryMonitor(monitor);
    collector.count += 1;
    return 1;
}

pub fn queryAllMonitors(output: []MonitorGeometry) usize {
    if (output.len == 0) return 0;
    var collector = MonitorCollector{ .output = output };
    _ = EnumDisplayMonitors(null, null, collectMonitor, @intCast(@intFromPtr(&collector)));
    return collector.count;
}

fn wideAsciiEqlIgnoreCase(actual: []const u16, expected: []const u8) bool {
    if (actual.len != expected.len) return false;
    for (actual, expected) |left, right| {
        const folded = if (left >= 'A' and left <= 'Z') left + ('a' - 'A') else left;
        if (folded != @as(u16, right)) return false;
    }
    return true;
}

pub const FullscreenProbe = struct {
    pub const Reason = enum {
        no_foreground,
        own_process,
        hidden,
        minimized,
        excluded_shell_class,
        cloaked,
        rect_unavailable,
        does_not_cover_monitor,
        maximized_work_area,
        fullscreen,
    };

    detected: bool = false,
    hwnd: usize = 0,
    process_id: DWORD = 0,
    class_name: [64]u8 = @splat(0),
    class_name_len: usize = 0,
    window_rect: Rect = .{},
    visible: bool = false,
    minimized: bool = false,
    zoomed: bool = false,
    reason: Reason = .no_foreground,
};

fn readWindowClassName(window: HWND, output: *[64]u16) usize {
    const count = GetClassNameW(window, output, @intCast(output.len));
    return if (count > 0) @intCast(count) else 0;
}

fn windowClassIsExcluded(window: HWND) bool {
    var class_name: [64]u16 = @splat(0);
    const count = readWindowClassName(window, &class_name);
    if (count == 0) return false;
    const class = class_name[0..count];
    return wideAsciiEqlIgnoreCase(class, "Progman") or
        wideAsciiEqlIgnoreCase(class, "WorkerW") or
        wideAsciiEqlIgnoreCase(class, "Shell_TrayWnd") or
        wideAsciiEqlIgnoreCase(class, "Shell_SecondaryTrayWnd");
}

fn isCloaked(window: HWND) bool {
    var cloaked: i32 = 0;
    return DwmGetWindowAttribute(window, dwm_attribute_cloaked, &cloaked, @sizeOf(i32)) >= 0 and cloaked != 0;
}

pub fn probeFullScreenApp(monitor: Rect) FullscreenProbe {
    var probe = FullscreenProbe{};
    const foreground = GetForegroundWindow() orelse return probe;
    probe.hwnd = @intFromPtr(foreground);
    _ = GetWindowThreadProcessId(foreground, &probe.process_id);
    var wide_class: [64]u16 = @splat(0);
    probe.class_name_len = readWindowClassName(foreground, &wide_class);
    for (wide_class[0..probe.class_name_len], 0..) |char, index| {
        probe.class_name[index] = if (char <= 0x7f) @intCast(char) else '?';
    }
    probe.visible = IsWindowVisible(foreground) != 0;
    probe.minimized = IsIconic(foreground) != 0;
    probe.zoomed = IsZoomed(foreground) != 0;

    if (probe.process_id == GetCurrentProcessId()) {
        probe.reason = .own_process;
        return probe;
    }
    if (!probe.visible) {
        probe.reason = .hidden;
        return probe;
    }
    if (probe.minimized) {
        probe.reason = .minimized;
        return probe;
    }
    if (windowClassIsExcluded(foreground)) {
        probe.reason = .excluded_shell_class;
        return probe;
    }
    if (isCloaked(foreground)) {
        probe.reason = .cloaked;
        return probe;
    }

    if (GetWindowRect(foreground, &probe.window_rect) == 0) {
        probe.reason = .rect_unavailable;
        return probe;
    }
    if (!windowCoversMonitor(probe.window_rect, monitor)) {
        probe.reason = .does_not_cover_monitor;
        return probe;
    }
    if (probe.zoomed) {
        const owner = MonitorFromRect(&monitor, monitor_default_to_nearest);
        var info: MonitorInfo = .{ .size = @sizeOf(MonitorInfo), .monitor = .{}, .work = .{}, .flags = 0 };
        if (GetMonitorInfoW(owner, &info) != 0 and
            looksLikeWindowsMaximizedRect(probe.window_rect, info.work, queryDpi(owner)))
        {
            probe.reason = .maximized_work_area;
            return probe;
        }
    }
    probe.detected = true;
    probe.reason = .fullscreen;
    return probe;
}

pub fn fullScreenAppInFront(monitor: Rect) bool {
    return probeFullScreenApp(monitor).detected;
}

pub fn shellTopBandThicknessPx(monitor: HMONITOR) i32 {
    const tray = FindWindowW("Shell_TrayWnd", null) orelse return 0;
    var rect: Rect = .{};
    if (GetWindowRect(tray, &rect) == 0) return 0;
    const owner = MonitorFromWindow(tray, monitor_default_to_nearest);
    if (monitor == null or owner != monitor) return 0;
    var info: MonitorInfo = .{ .size = @sizeOf(MonitorInfo), .monitor = .{}, .work = .{}, .flags = 0 };
    if (GetMonitorInfoW(owner, &info) == 0) return 0;
    const width = rect.right - rect.left;
    const height = rect.bottom - rect.top;
    if (width <= 0 or height <= 0 or width < height or rect.top > info.monitor.top) return 0;
    const thickness = rect.bottom - info.monitor.top;
    return if (thickness > 0) thickness else 0;
}

const NudgePass = struct {
    monitor_screen: Rect,
    work_before: Rect,
    work_after: Rect,
    self_pid: DWORD,
    moved: usize = 0,
};

fn nudgeWindow(window: HWND, parameter: LPARAM) callconv(.winapi) BOOL {
    const pass: *NudgePass = @ptrFromInt(@as(usize, @intCast(parameter)));
    if (IsWindowVisible(window) == 0 or IsIconic(window) != 0 or IsZoomed(window) == 0) return 1;
    var process_id: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &process_id);
    if (process_id == 0 or process_id == pass.self_pid or isCloaked(window)) return 1;
    const owner = MonitorFromWindow(window, monitor_default_to_nearest);
    var info: MonitorInfo = .{ .size = @sizeOf(MonitorInfo), .monitor = .{}, .work = .{}, .flags = 0 };
    if (GetMonitorInfoW(owner, &info) == 0 or !sameRect(info.monitor, pass.monitor_screen)) return 1;
    var rect: Rect = .{};
    if (GetWindowRect(window, &rect) == 0) return 1;
    const border = maximizedBorderPx(queryDpi(owner));
    if (!sameRect(rect, inflateRect(pass.work_before, border.x, border.y))) return 1;
    const target = inflateRect(pass.work_after, border.x, border.y);
    if (SetWindowPos(window, null, target.left, target.top, target.right - target.left, target.bottom - target.top, swp_no_activate | swp_no_zorder | swp_no_send_changing) != 0) pass.moved += 1;
    return 1;
}

pub fn nudgeStaleMaximizedWindows(monitor_screen: Rect, work_before: Rect, work_after: Rect) usize {
    if (sameRect(work_before, work_after)) return 0;
    var pass = NudgePass{
        .monitor_screen = monitor_screen,
        .work_before = work_before,
        .work_after = work_after,
        .self_pid = GetCurrentProcessId(),
    };
    _ = EnumWindows(nudgeWindow, @intCast(@intFromPtr(&pass)));
    return pass.moved;
}

pub fn smokeCheck() bool {
    if (false) {
        var monitor_list: [1]MonitorGeometry = undefined;
        _ = queryMonitor(null);
        _ = queryAllMonitors(&monitor_list);
        _ = maximizedBorderPx(96);
        _ = looksLikeWindowsMaximizedRect(.{}, .{}, 96);
        _ = fullScreenAppInFront(.{});
        _ = shellTopBandThicknessPx(null);
        _ = nudgeStaleMaximizedWindows(.{}, .{}, .{});
    }
    const screen = Rect{ .left = 0, .top = 0, .right = 1920, .bottom = 1080 };
    const work = Rect{ .left = 0, .top = 32, .right = 1920, .bottom = 1080 };
    const geometry = MonitorGeometry{ .screen = screen, .work = work };
    return screenWidth(geometry) == 1920 and screenHeight(geometry) == 1080 and
        workHeight(geometry) == 1048 and insetEdge(geometry) == .top and
        taskbarThickness(geometry) == 32 and
        sameRect(inflateRect(work, 8, 8), .{ .left = -8, .top = 24, .right = 1928, .bottom = 1088 }) and
        windowCoversMonitor(.{ .left = -8, .top = -8, .right = 1928, .bottom = 1088 }, screen);
}

comptime {
    _ = &queryDpi;
    _ = &metricForDpi;
    _ = &collectMonitor;
    _ = &windowClassIsExcluded;
    _ = &isCloaked;
    _ = &nudgeWindow;
}
