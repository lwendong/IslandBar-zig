const std = @import("std");
const Monitor = @import("Monitor");
const Log = @import("Log");

pub const DockEdge = enum { none, top, bottom, left, right };
pub const AppBarResult = enum { registered, no_window, callback_refused, not_registered, space_not_granted };
const HWND = ?*anyopaque;
const HMONITOR = Monitor.HMONITOR;
const DWORD = u32;
const UINT = u32;
const LONG = i32;

const AppBarData = extern struct {
    size: DWORD,
    window: HWND,
    callback_message: UINT,
    edge: UINT,
    rect: Monitor.Rect,
    lparam: isize,
};

const MonitorInfo = extern struct { size: DWORD, monitor: Monitor.Rect, work: Monitor.Rect, flags: DWORD };

extern "shell32" fn SHAppBarMessage(message: DWORD, data: *AppBarData) callconv(.winapi) usize;
extern "user32" fn RegisterWindowMessageW(name: [*:0]const u16) callconv(.winapi) UINT;
extern "user32" fn MonitorFromWindow(window: HWND, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn GetMonitorInfoW(monitor: HMONITOR, info: *MonitorInfo) callconv(.winapi) i32;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;

const abm_new: DWORD = 0;
const abm_remove: DWORD = 1;
const abm_query_pos: DWORD = 2;
const abm_set_pos: DWORD = 3;
const abn_pos_changed: usize = 1;
const abn_fullscreen_app: usize = 2;
const abn_state_change: usize = 0;
const abn_window_arrange: usize = 3;
const abe_left: UINT = 0;
const abe_top: UINT = 1;
const abe_right: UINT = 2;
const abe_bottom: UINT = 3;
const monitor_default_to_nearest: DWORD = 2;
const callback_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', 'A', 'p', 'p', 'B', 'a', 'r', 'C', 'a', 'l', 'l', 'b', 'a', 'c', 'k', 0 };

var callback_message: UINT = 0;

pub const Landing = struct {
    landed: bool = false,
    other_edges_intact: bool = true,
    sane: bool = true,
};

pub fn appBarStripRect(bounds: Monitor.Rect, edge: DockEdge, thickness: LONG) Monitor.Rect {
    var target = bounds;
    switch (edge) {
        .top => {
            target.top = bounds.top;
            target.bottom = bounds.top + thickness;
        },
        .bottom => {
            target.bottom = bounds.bottom;
            target.top = bounds.bottom - thickness;
        },
        .left => {
            target.left = bounds.left;
            target.right = bounds.left + thickness;
        },
        .right => {
            target.right = bounds.right;
            target.left = bounds.right - thickness;
        },
        .none => {
            target.right = target.left;
            target.bottom = target.top;
        },
    }
    return target;
}

pub fn evaluateLanding(bounds: Monitor.Rect, before: Monitor.Rect, after: Monitor.Rect, edge: DockEdge, thickness: LONG) Landing {
    var result = Landing{ .sane = after.right > after.left and after.bottom > after.top };
    result.landed = switch (edge) {
        .top => after.top == bounds.top + thickness,
        .bottom => after.bottom == bounds.bottom - thickness,
        .left => after.left == bounds.left + thickness,
        .right => after.right == bounds.right - thickness,
        .none => false,
    };
    if (edge != .top and after.top != before.top) result.other_edges_intact = false;
    if (edge != .bottom and after.bottom != before.bottom) result.other_edges_intact = false;
    if (edge != .left and after.left != before.left) result.other_edges_intact = false;
    if (edge != .right and after.right != before.right) result.other_edges_intact = false;
    return result;
}

pub fn dockEdgeToAppBarEdge(edge: DockEdge) UINT {
    return switch (edge) {
        .left => abe_left,
        .top, .none => abe_top,
        .right => abe_right,
        .bottom => abe_bottom,
    };
}

pub fn appBarResultName(result: AppBarResult) []const u16 {
    return switch (result) {
        .registered => &.{ 'r', 'e', 'g', 'i', 's', 't', 'e', 'r', 'e', 'd' },
        .no_window => &.{ 'n', 'o', ' ', 'w', 'i', 'n', 'd', 'o', 'w' },
        .callback_refused => &.{ 'c', 'a', 'l', 'l', 'b', 'a', 'c', 'k', ' ', 'm', 'e', 's', 's', 'a', 'g', 'e', ' ', 'r', 'e', 'f', 'u', 's', 'e', 'd' },
        .not_registered => &.{ 'A', 'B', 'M', '_', 'N', 'E', 'W', ' ', 'r', 'e', 'f', 'u', 's', 'e', 'd' },
        .space_not_granted => &.{ 'r', 'e', 'g', 'i', 's', 't', 'e', 'r', 'e', 'd', ' ', 'b', 'u', 't', ' ', 'n', 'o', ' ', 's', 'p', 'a', 'c', 'e', ' ', 'g', 'r', 'a', 'n', 't', 'e', 'd' },
    };
}

fn makeData(window: HWND) AppBarData {
    return .{ .size = @sizeOf(AppBarData), .window = window, .callback_message = 0, .edge = 0, .rect = .{}, .lparam = 0 };
}

fn monitorRects(window: HWND) struct { bounds: Monitor.Rect, work: Monitor.Rect } {
    const monitor = MonitorFromWindow(window, monitor_default_to_nearest);
    var info = MonitorInfo{ .size = @sizeOf(MonitorInfo), .monitor = .{}, .work = .{}, .flags = 0 };
    if (GetMonitorInfoW(monitor, &info) != 0) return .{ .bounds = info.monitor, .work = info.work };
    return .{ .bounds = .{}, .work = .{} };
}

fn rectsEqual(left: Monitor.Rect, right: Monitor.Rect) bool {
    return Monitor.sameRect(left, right);
}

fn setDetail(output: *[256]u16, text: []const u8) void {
    @memset(output, 0);
    const amount = @min(text.len, output.len - 1);
    for (text[0..amount], 0..) |byte, index| output[index] = byte;
}

fn setDetailFormat(output: *[256]u16, comptime format: []const u8, args: anytype) void {
    var bytes: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&bytes, format, args) catch return;
    setDetail(output, text);
}

fn edgeName(edge: DockEdge) []const u8 {
    return switch (edge) {
        .top => "top",
        .bottom => "bottom",
        .left => "left",
        .right => "right",
        .none => "none",
    };
}

pub fn callbackMessage() UINT {
    if (callback_message == 0) callback_message = RegisterWindowMessageW(callback_name);
    return callback_message;
}

pub const AppBar = struct {
    fullscreen_app: bool = false,
    registered: bool = false,
    registration: AppBarData = makeData(null),
    reserved: Monitor.Rect = .{},
    claimed_thickness_px: LONG = 0,
    claimed_edge: DockEdge = .top,
    detail: [256]u16 = @splat(0),

    pub fn claim(self: *AppBar, window: HWND, edge: DockEdge, thickness_px: LONG) AppBarResult {
        self.detail[0] = 0;
        if (window == null) {
            setDetail(&self.detail, "no window to register");
            return .no_window;
        }
        if (!self.registered) {
            const callback = callbackMessage();
            if (callback == 0) {
                setDetailFormat(&self.detail, "RegisterWindowMessage failed (error {d})", .{GetLastError()});
                return .callback_refused;
            }
            var data = makeData(window);
            data.callback_message = callback;
            if (SHAppBarMessage(abm_new, &data) == 0) {
                setDetailFormat(&self.detail, "ABM_NEW refused (error {d})", .{GetLastError()});
                return .not_registered;
            }
            self.registered = true;
        }

        const before = monitorRects(window).work;
        const anchor = monitorRects(window).bounds;
        const width = anchor.right - anchor.left;
        const height = anchor.bottom - anchor.top;
        if (width <= 0 or height <= 0) {
            setDetailFormat(&self.detail, "refused: empty monitor ({d}x{d})", .{ width, height });
            return .space_not_granted;
        }
        if (thickness_px <= 0 or thickness_px > @divTrunc(height, 4)) {
            setDetailFormat(&self.detail, "refused: {d}px is not sane for {d}px screen", .{ thickness_px, height });
            return .space_not_granted;
        }

        var query = makeData(window);
        query.edge = dockEdgeToAppBarEdge(edge);
        query.rect = anchor;
        _ = SHAppBarMessage(abm_query_pos, &query);
        var target = appBarStripRect(anchor, edge, thickness_px);
        if (target.right <= target.left or target.bottom <= target.top) {
            setDetail(&self.detail, "no edge to dock to");
            return .no_window;
        }
        if (edge == .top or edge == .bottom) {
            if (query.rect.left > target.left and query.rect.left < target.right) target.left = query.rect.left;
            if (query.rect.right < target.right and query.rect.right > target.left) target.right = query.rect.right;
        } else {
            if (query.rect.top > target.top and query.rect.top < target.bottom) target.top = query.rect.top;
            if (query.rect.bottom < target.bottom and query.rect.bottom > target.top) target.bottom = query.rect.bottom;
        }
        if (target.right <= target.left or target.bottom <= target.top) {
            setDetailFormat(&self.detail, "refused: computed rectangle empty at {d},{d}", .{ target.left, target.top });
            return .space_not_granted;
        }

        var set = makeData(window);
        set.edge = query.edge;
        set.rect = target;
        Log.logLine("appbar: reserving work area strip");
        _ = SHAppBarMessage(abm_set_pos, &set);
        self.reserved = set.rect;
        self.registration = set;
        const after = monitorRects(window).work;
        const moved = !rectsEqual(before, after);
        if ((edge == .top and before.top == anchor.top + thickness_px) or
            (edge == .bottom and before.bottom == anchor.bottom - thickness_px)) return .registered;
        if (moved) {
            const landing = evaluateLanding(anchor, before, after, edge, thickness_px);
            if (!landing.sane or !landing.landed or !landing.other_edges_intact) {
                Log.logLine("appbar: work area did not land; releasing reservation");
                self.release();
                setDetailFormat(&self.detail, "released: work area mismatch for {d}px strip", .{thickness_px});
                return .space_not_granted;
            }
        }
        setDetailFormat(&self.detail, "work area changed; requested {d}px on {s}", .{ thickness_px, edgeName(edge) });
        if (!moved) return .space_not_granted;
        self.claimed_thickness_px = thickness_px;
        self.claimed_edge = edge;
        return .registered;
    }

    pub fn release(self: *AppBar) void {
        if (!self.registered) return;
        var data = self.registration;
        data.size = @sizeOf(AppBarData);
        _ = SHAppBarMessage(abm_remove, &data);
        self.registered = false;
        self.reserved = .{};
        self.fullscreen_app = false;
        self.claimed_thickness_px = 0;
        Log.logLine("appbar: released");
    }

    pub fn handleCallback(self: *AppBar, window: HWND, message: UINT, wparam: usize, lparam: isize) bool {
        const callback = callbackMessage();
        if (callback == 0 or message != callback) return false;
        switch (wparam) {
            abn_pos_changed => if (self.registered) {
                const edge: DockEdge = if (self.claimed_thickness_px > 0) self.claimed_edge else switch (self.registration.edge) {
                    abe_bottom => .bottom,
                    abe_left => .left,
                    abe_right => .right,
                    else => .top,
                };
                const thickness = if (self.claimed_thickness_px > 0) self.claimed_thickness_px else self.registration.rect.bottom - self.registration.rect.top;
                if (thickness > 0) _ = self.claim(window, edge, thickness);
            },
            abn_fullscreen_app => self.fullscreen_app = lparam != 0,
            abn_state_change, abn_window_arrange => {},
            else => {},
        }
        return true;
    }

    pub fn isFullscreenAppInFront(self: *const AppBar) bool {
        return self.fullscreen_app;
    }
};

pub fn smokeCheck() bool {
    const bounds = Monitor.Rect{ .left = -1920, .top = 0, .right = 0, .bottom = 1080 };
    const top = appBarStripRect(bounds, .top, 48);
    if (!Monitor.sameRect(top, .{ .left = -1920, .top = 0, .right = 0, .bottom = 48 })) return false;
    const before = Monitor.Rect{ .left = -1920, .top = 0, .right = 0, .bottom = 1040 };
    const after = Monitor.Rect{ .left = -1920, .top = 48, .right = 0, .bottom = 1040 };
    const landing = evaluateLanding(bounds, before, after, .top, 48);
    if (!landing.sane or !landing.landed or !landing.other_edges_intact) return false;
    if (dockEdgeToAppBarEdge(.bottom) != abe_bottom) return false;
    if (false) {
        var bar = AppBar{};
        _ = bar.claim(null, .top, 1);
        bar.release();
        _ = bar.handleCallback(null, 0, abn_pos_changed, 0);
    }
    return true;
}
