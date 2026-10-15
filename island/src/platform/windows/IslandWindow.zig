const std = @import("std");
const AppBar = @import("AppBar");

pub const HWND = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const HBRUSH = ?*anyopaque;
const HRGN = ?*anyopaque;
const HMENU = ?*anyopaque;
const HDC = ?*anyopaque;
const WndProc = *const fn (HWND, u32, usize, isize) callconv(.winapi) isize;
pub const PaintCallback = *const fn (HWND, ?*anyopaque) callconv(.winapi) void;
pub const TimerCallback = *const fn (?*anyopaque) callconv(.winapi) void;
pub const DisplayChangeCallback = *const fn (?*anyopaque) callconv(.winapi) void;
pub const HitTestCallback = *const fn (Point, ?*anyopaque) callconv(.winapi) bool;
pub const WheelHitTestCallback = *const fn (Point, ?*anyopaque) callconv(.winapi) bool;

const WindowClass = extern struct {
    style: u32,
    wnd_proc: WndProc,
    class_extra: i32,
    window_extra: i32,
    instance: HINSTANCE,
    icon: ?*anyopaque,
    cursor: ?*anyopaque,
    background: HBRUSH,
    menu_name: ?[*:0]const u16,
    class_name: [*:0]const u16,
};

pub const Point = extern struct { x: i32, y: i32 };
pub const Message = extern struct {
    window: HWND,
    id: u32,
    wparam: usize,
    lparam: isize,
    time: u32,
    point: Point,
    private: u32,
};

const WinRect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const NativePaintStruct = extern struct { hdc: HDC, erase: i32, paint: WinRect, restore: i32, update: i32, reserved: [32]u8 };
extern "kernel32" fn GetModuleHandleW(module_name: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
extern "kernel32" fn GetLastError() callconv(.winapi) u32;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "dwmapi" fn DwmSetWindowAttribute(window: HWND, attribute: u32, value: *const anyopaque, size: u32) callconv(.winapi) i32;
extern "user32" fn RegisterClassW(window_class: *const WindowClass) callconv(.winapi) u16;
extern "user32" fn CreateWindowExW(extended_style: u32, class_name: [*:0]const u16, window_name: [*:0]const u16, style: u32, x: i32, y: i32, width: i32, height: i32, parent: HWND, menu: HMENU, instance: HINSTANCE, parameter: ?*anyopaque) callconv(.winapi) HWND;
extern "user32" fn DefWindowProcW(window: HWND, message: u32, wparam: usize, lparam: isize) callconv(.winapi) isize;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) i32;
extern "user32" fn GetMessageW(message: *Message, window: HWND, minimum: u32, maximum: u32) callconv(.winapi) i32;
extern "user32" fn TranslateMessage(message: *const Message) callconv(.winapi) i32;
extern "user32" fn DispatchMessageW(message: *const Message) callconv(.winapi) isize;
extern "user32" fn PostQuitMessage(exit_code: i32) callconv(.winapi) void;
extern "user32" fn DestroyWindow(window: HWND) callconv(.winapi) i32;
extern "user32" fn InvalidateRect(window: HWND, rect: ?*const WinRect, erase: i32) callconv(.winapi) i32;
extern "user32" fn SetTimer(window: HWND, id: usize, interval_ms: u32, callback: ?*const anyopaque) callconv(.winapi) usize;
extern "user32" fn KillTimer(window: HWND, id: usize) callconv(.winapi) i32;
extern "user32" fn BeginPaint(window: HWND, paint: *NativePaintStruct) callconv(.winapi) HDC;
extern "user32" fn EndPaint(window: HWND, paint: *const NativePaintStruct) callconv(.winapi) i32;
extern "gdi32" fn CreateRoundRectRgn(left: i32, top: i32, right: i32, bottom: i32, ellipse_width: i32, ellipse_height: i32) callconv(.winapi) HRGN;
extern "gdi32" fn CreateRectRgn(left: i32, top: i32, right: i32, bottom: i32) callconv(.winapi) HRGN;
extern "gdi32" fn DeleteObject(object: ?*anyopaque) callconv(.winapi) i32;
extern "user32" fn SetWindowRgn(window: HWND, region: HRGN, redraw: i32) callconv(.winapi) i32;
extern "user32" fn SetWindowPos(window: HWND, insert_after: ?*anyopaque, x: i32, y: i32, width: i32, height: i32, flags: u32) callconv(.winapi) i32;
extern "user32" fn GetCursorPos(point: *Point) callconv(.winapi) i32;
extern "user32" fn GetCursor() callconv(.winapi) ?*anyopaque;
extern "user32" fn LoadCursorW(instance: HINSTANCE, cursor_name: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "user32" fn SetCursor(cursor: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "user32" fn ClientToScreen(window: HWND, point: *Point) callconv(.winapi) i32;
extern "user32" fn SetCapture(window: HWND) callconv(.winapi) HWND;
extern "user32" fn GetCapture() callconv(.winapi) HWND;
extern "user32" fn ReleaseCapture() callconv(.winapi) i32;
extern "user32" fn GetWindowRect(window: HWND, rect: *WinRect) callconv(.winapi) i32;
extern "user32" fn GetDpiForWindow(window: HWND) callconv(.winapi) u32;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) i32;
extern "user32" fn SendMessageW(window: HWND, message: u32, wparam: usize, lparam: isize) callconv(.winapi) isize;

const class_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', '.', 'I', 's', 'l', 'a', 'n', 'd', 'W', 'i', 'n', 'd', 'o', 'w', 0 };
const window_title: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', 0 };
const ws_popup: u32 = 0x80000000;
const ws_ex_topmost: u32 = 0x00000008;
const ws_ex_toolwindow: u32 = 0x00000080;
const ws_ex_noactivate: u32 = 0x08000000;
const ws_ex_no_redirection_bitmap: u32 = 0x00200000;
const ws_ex_transparent: u32 = 0x00000020;
const ws_ex_appwindow: u32 = 0x00040000;
const dwmwa_excluded_from_peek: u32 = 12;
const gwl_style: i32 = -16;
const gwl_exstyle: i32 = -20;
const cs_hredraw: u32 = 0x0002;
const cs_vredraw: u32 = 0x0001;
const wm_destroy: u32 = 0x0002;
const wm_nccreate: u32 = 0x0081;
const wm_ncdestroy: u32 = 0x0082;
const wm_paint: u32 = 0x000f;
const wm_timer: u32 = 0x0113;
const wm_mouseactivate: u32 = 0x0021;
const wm_setcursor: u32 = 0x0020;
const wm_nchittest: u32 = 0x0084;
const wm_mousemove: u32 = 0x0200;
const ht_client: isize = 1;
const ht_transparent: isize = -1;
const cursor_arrow: ?*anyopaque = @ptrFromInt(32512);
const cursor_hand: ?*anyopaque = @ptrFromInt(32649);
const wm_erasebkgnd: u32 = 0x0014;
const wm_settingchange: u32 = 0x001a;
const wm_displaychange: u32 = 0x007e;
const wm_dpichanged: u32 = 0x02e0;
const wm_lbuttondown: u32 = 0x0201;
const wm_lbuttonup: u32 = 0x0202;
const wm_rbuttonup: u32 = 0x0205;
const wm_mousewheel: u32 = 0x020a;
const sw_hide: i32 = 0;
const sw_shownoactivate: i32 = 4;
const ma_noactivate: isize = 3;
const pointer_timer_id: usize = 1;
const shell_timer_id: usize = 2;
const pointer_poll_ms: u32 = 8;
const mousemove_callback_min_interval_ms: u64 = 8;
const shell_poll_ms: u32 = 1000;
const wheel_delta: i32 = 120;
const error_class_already_exists: u32 = 1410;
const gwlp_userdata: i32 = -21;
const swp_noactivate: u32 = 0x0010;
const swp_showwindow: u32 = 0x0040;
const swp_no_owner_zorder: u32 = 0x0200;
const hwnd_topmost: ?*anyopaque = @ptrFromInt(std.math.maxInt(usize));

const NativeCreateStruct = extern struct {
    create_params: ?*anyopaque,
    instance: HINSTANCE,
    menu: HMENU,
    parent: HWND,
    height: i32,
    width: i32,
    y: i32,
    x: i32,
    style: i32,
    name: ?[*:0]const u16,
    class: ?[*:0]const u16,
    extended_style: u32,
};

extern "user32" fn SetWindowLongPtrW(window: HWND, index: i32, value: isize) callconv(.winapi) isize;
extern "user32" fn GetWindowLongPtrW(window: HWND, index: i32) callconv(.winapi) isize;

pub const NativeWindow = struct {
    hwnd: HWND = null,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    radius: i32 = 0,
    paint_callback: ?PaintCallback = null,
    timer_callback: ?TimerCallback = null,
    display_change_callback: ?DisplayChangeCallback = null,
    pointer_callback: ?TimerCallback = null,
    hit_test_callback: ?HitTestCallback = null,
    cursor_hit_test_callback: ?HitTestCallback = null,
    wheel_hit_test_callback: ?WheelHitTestCallback = null,
    app_bar: ?*AppBar.AppBar = null,
    callback_context: ?*anyopaque = null,
    shown: bool = false,
    destroyed: bool = false,
    pointer_timer: usize = 0,
    pointer_interval_ms: u32 = pointer_poll_ms,
    shell_timer: usize = 0,
    last_mousemove_callback_ms: u64 = 0,
    pointer_inside: bool = false,
    pointer_inside_changed: bool = false,
    last_pointer: Point = .{ .x = 0, .y = 0 },
    have_pointer: bool = false,
    pending_clicks: u32 = 0,
    pending_right_clicks: u32 = 0,
    last_right_click: Point = .{ .x = 0, .y = 0 },
    pending_presses: u32 = 0,
    last_press: Point = .{ .x = 0, .y = 0 },
    left_button_down: bool = false,
    wheel_notches: i32 = 0,
    wheel_remainder: i32 = 0,
    applied_input_region: ?Rect = null,

    pub fn create(self: *NativeWindow, x: i32, y: i32, width: i32, height: i32, radius: i32, paint: PaintCallback, timer_callback: ?TimerCallback, context: ?*anyopaque) bool {
        if (self.hwnd != null or width <= 0 or height <= 0) return false;
        self.x = x;
        self.y = y;
        self.width = width;
        self.height = height;
        self.radius = @max(0, radius);
        self.paint_callback = paint;
        self.timer_callback = timer_callback;
        self.callback_context = context;
        self.destroyed = false;

        const instance = GetModuleHandleW(null) orelse return false;
        const descriptor = WindowClass{
            .style = cs_hredraw | cs_vredraw,
            .wnd_proc = nativeWindowProc,
            .class_extra = 0,
            .window_extra = 0,
            .instance = instance,
            .icon = null,
            .cursor = null,
            .background = null,
            .menu_name = null,
            .class_name = class_name,
        };
        if (RegisterClassW(&descriptor) == 0 and GetLastError() != error_class_already_exists) return false;

        self.hwnd = CreateWindowExW(
            ws_ex_topmost | ws_ex_noactivate | ws_ex_toolwindow | ws_ex_no_redirection_bitmap,
            class_name,
            window_title,
            ws_popup,
            x,
            y,
            width,
            height,
            null,
            null,
            instance,
            @ptrCast(self),
        );
        if (self.hwnd == null) {
            return false;
        }

        const exclude_from_peek: i32 = 1;
        _ = DwmSetWindowAttribute(self.hwnd, dwmwa_excluded_from_peek, &exclude_from_peek, @sizeOf(i32));
        if (self.radius > 0) {
            const region = CreateRoundRectRgn(0, 0, width + 1, height + 1, self.radius * 2, self.radius * 2);
            if (region == null) {
                self.destroy();
                return false;
            }
            if (SetWindowRgn(self.hwnd, region, 1) == 0) {
                _ = DeleteObject(region);
                self.destroy();
                return false;
            }
        }

        self.pointer_timer = SetTimer(self.hwnd, pointer_timer_id, pointer_poll_ms, null);
        self.pointer_interval_ms = pointer_poll_ms;
        self.shell_timer = SetTimer(self.hwnd, shell_timer_id, shell_poll_ms, null);
        return true;
    }

    /// Replaces the pointer poll timer without disturbing the independent shell
    /// maintenance timer. The main loop uses a short interval only while an
    /// animation is moving, then backs off to the C++ loop's 100 ms idle wait.
    pub fn setPointerPollInterval(self: *NativeWindow, interval_ms: u32) void {
        if (self.hwnd == null or self.pointer_timer == 0 or interval_ms == 0 or self.pointer_interval_ms == interval_ms) return;
        const timer = SetTimer(self.hwnd, pointer_timer_id, interval_ms, null);
        if (timer != 0) {
            self.pointer_timer = timer;
            self.pointer_interval_ms = interval_ms;
        }
    }

    pub fn handle(self: *const NativeWindow) HWND {
        return self.hwnd;
    }

    pub fn dpi(self: *const NativeWindow) u32 {
        const hwnd = self.hwnd orelse return 0;
        return GetDpiForWindow(hwnd);
    }

    pub fn setPointerCallback(self: *NativeWindow, callback: ?TimerCallback) void {
        self.pointer_callback = callback;
    }

    pub fn setDisplayChangeCallback(self: *NativeWindow, callback: ?DisplayChangeCallback) void {
        self.display_change_callback = callback;
    }

    pub fn setBounds(self: *NativeWindow, x: i32, y: i32, width: i32, height: i32) bool {
        const hwnd = self.hwnd orelse return false;
        if (width <= 0 or height <= 0) return false;
        self.x = x;
        self.y = y;
        self.width = width;
        self.height = height;
        return SetWindowPos(hwnd, hwnd_topmost, x, y, width, height, swp_noactivate | swp_no_owner_zorder) != 0;
    }

    /// Applies the current drawn-content bounds as the native window region.
    /// Windows then routes points outside that region to the window beneath it
    /// before WM_NCHITTEST, including windows owned by other processes.
    pub fn setInputRegion(self: *NativeWindow, region: Rect) bool {
        const hwnd = self.hwnd orelse return false;
        if (self.applied_input_region) |applied| {
            if (applied.left == region.left and applied.top == region.top and
                applied.right == region.right and applied.bottom == region.bottom) return true;
        }
        const native_region = CreateRectRgn(region.left, region.top, region.right, region.bottom) orelse return false;
        if (SetWindowRgn(hwnd, native_region, 1) == 0) {
            _ = DeleteObject(native_region);
            return false;
        }
        self.applied_input_region = region;
        return true;
    }

    pub fn setHitTestCallback(self: *NativeWindow, callback: ?HitTestCallback) void {
        self.hit_test_callback = callback;
    }

    pub fn setCursorHitTestCallback(self: *NativeWindow, callback: ?HitTestCallback) void {
        self.cursor_hit_test_callback = callback;
    }

    pub fn setWheelHitTestCallback(self: *NativeWindow, callback: ?WheelHitTestCallback) void {
        self.wheel_hit_test_callback = callback;
    }

    pub fn setAppBar(self: *NativeWindow, app_bar: ?*AppBar.AppBar) void {
        self.app_bar = app_bar;
    }

    pub fn windowRect(self: *const NativeWindow, rect: *Rect) bool {
        const hwnd = self.hwnd orelse return false;
        var native: WinRect = undefined;
        if (GetWindowRect(hwnd, &native) == 0) return false;
        rect.* = .{ .left = native.left, .top = native.top, .right = native.right, .bottom = native.bottom };
        return true;
    }

    pub fn show(self: *NativeWindow) void {
        const hwnd = self.hwnd orelse return;
        self.shown = true;
        _ = SetWindowPos(hwnd, hwnd_topmost, self.x, self.y, self.width, self.height, swp_noactivate | swp_showwindow);
        _ = ShowWindow(hwnd, sw_shownoactivate);
    }

    pub fn hide(self: *NativeWindow) void {
        const hwnd = self.hwnd orelse return;
        self.shown = false;
        _ = ShowWindow(hwnd, sw_hide);
    }

    pub fn invalidate(self: *const NativeWindow) void {
        if (self.hwnd) |hwnd| _ = InvalidateRect(hwnd, null, 0);
    }

    /// Returns the latest pointer position in screen pixels, or false until it has been sampled.
    pub fn pointerPosition(self: *const NativeWindow, point: *Point) bool {
        if (!self.have_pointer) return false;
        point.* = self.last_pointer;
        return true;
    }

    pub fn isPointerInside(self: *const NativeWindow) bool {
        return self.pointer_inside;
    }

    pub fn takePointerInsideChanged(self: *NativeWindow, inside: *bool) bool {
        if (!self.pointer_inside_changed) return false;
        self.pointer_inside_changed = false;
        inside.* = self.pointer_inside;
        return true;
    }

    pub fn takeClick(self: *NativeWindow) bool {
        if (self.pending_clicks == 0) return false;
        self.pending_clicks -= 1;
        return true;
    }

    pub fn takeRightClick(self: *NativeWindow, point: *Point) bool {
        if (self.pending_right_clicks == 0) return false;
        self.pending_right_clicks -= 1;
        point.* = self.last_right_click;
        return true;
    }

    pub fn takePress(self: *NativeWindow, point: *Point) bool {
        if (self.pending_presses == 0) return false;
        self.pending_presses -= 1;
        point.* = self.last_press;
        return true;
    }

    pub fn pendingClicks(self: *const NativeWindow) u32 {
        return self.pending_clicks;
    }

    pub fn leftButtonDown(self: *const NativeWindow) bool {
        return self.left_button_down;
    }

    /// Returns complete wheel notches while retaining sub-notch high-resolution wheel motion.
    pub fn takeWheelNotches(self: *NativeWindow) i32 {
        const notches = @divTrunc(self.wheel_notches, wheel_delta);
        self.wheel_notches -= notches * wheel_delta;
        return notches;
    }

    pub fn destroy(self: *NativeWindow) void {
        if (self.pointer_timer != 0) {
            if (self.hwnd) |hwnd| _ = KillTimer(hwnd, self.pointer_timer);
            self.pointer_timer = 0;
            self.pointer_interval_ms = pointer_poll_ms;
        }
        if (self.shell_timer != 0) {
            if (self.hwnd) |hwnd| _ = KillTimer(hwnd, self.shell_timer);
            self.shell_timer = 0;
        }
        if (self.hwnd) |hwnd| {
            _ = DestroyWindow(hwnd);
            self.hwnd = null;
        }
        self.shown = false;
        self.destroyed = true;
        self.applied_input_region = null;
    }

    pub fn messageLoop(self: *NativeWindow) i32 {
        if (self.hwnd == null) return 1;
        var message: Message = undefined;
        while (true) {
            const result = GetMessageW(&message, null, 0, 0);
            if (result <= 0) {
                self.destroyed = true;
                return if (result == 0) @intCast(message.wparam) else -1;
            }
            _ = TranslateMessage(&message);
            _ = DispatchMessageW(&message);
            if (self.destroyed) return 0;
        }
    }
};

fn nativeWindowProc(window: HWND, message: u32, wparam: usize, lparam: isize) callconv(.winapi) isize {
    if (message == wm_nccreate) {
        const create_info: *const NativeCreateStruct = @ptrFromInt(@as(usize, @bitCast(lparam)));
        const raw_self = create_info.create_params orelse return 0;
        const self: *NativeWindow = @ptrCast(@alignCast(raw_self));
        self.hwnd = window;
        _ = SetWindowLongPtrW(window, gwlp_userdata, @bitCast(@intFromPtr(self)));
        return 1;
    }

    const stored_self = GetWindowLongPtrW(window, gwlp_userdata);
    if (stored_self == 0) return DefWindowProcW(window, message, wparam, lparam);
    const self: *NativeWindow = @ptrFromInt(@as(usize, @bitCast(stored_self)));
    if (self.app_bar) |app_bar| {
        if (app_bar.handleCallback(window, message, wparam, lparam)) {
            _ = InvalidateRect(window, null, 0);
            return 0;
        }
    }
    switch (message) {
        wm_mouseactivate => return ma_noactivate,
        wm_displaychange, wm_dpichanged, wm_settingchange => {
            if (self.display_change_callback) |callback| callback(self.callback_context);
            return 0;
        },
        wm_setcursor => {
            if (@as(u16, @truncate(@as(usize, @bitCast(lparam)))) != @as(u16, @intCast(ht_client))) {
                return DefWindowProcW(window, message, wparam, lparam);
            }
            var point: Point = undefined;
            const over_control = GetCursorPos(&point) != 0 and
                (if (self.cursor_hit_test_callback) |callback| callback(point, self.callback_context) else false);
            const cursor = LoadCursorW(null, if (over_control) cursor_hand else cursor_arrow);
            _ = SetCursor(cursor);
            return 1;
        },
        wm_nchittest => {
            const point = Point{ .x = signedLowWord(lparam), .y = signedHighWord(lparam) };
            if (self.hit_test_callback) |callback| {
                return if (callback(point, self.callback_context)) ht_client else ht_transparent;
            }
            return ht_transparent;
        },
        wm_mousemove => {
            if (updatePointer(self)) {
                const now = GetTickCount64();
                const callback_due = self.last_mousemove_callback_ms == 0 or
                    now -| self.last_mousemove_callback_ms >= mousemove_callback_min_interval_ms;
                if (callback_due) {
                    self.last_mousemove_callback_ms = now;
                    if (self.pointer_callback) |callback| callback(self.callback_context);
                }
            }
            return 0;
        },
        wm_erasebkgnd => return 1,
        wm_timer => {
            if (wparam == pointer_timer_id) {
                _ = updatePointer(self);
                if (self.pointer_callback) |callback| callback(self.callback_context);
            } else if (wparam == shell_timer_id) {
                if (self.timer_callback) |callback| callback(self.callback_context);
            }
            return 0;
        },
        wm_lbuttondown => {
            var point = Point{ .x = signedLowWord(lparam), .y = signedHighWord(lparam) };
            _ = ClientToScreen(window, &point);
            self.last_press = point;
            self.pending_presses +%= 1;
            self.left_button_down = true;
            _ = SetCapture(window);
            return 0;
        },
        wm_lbuttonup => {
            self.pending_clicks +%= 1;
            self.left_button_down = false;
            if (GetCapture() == window) _ = ReleaseCapture();
            return 0;
        },
        wm_rbuttonup => {
            var point = Point{ .x = signedLowWord(lparam), .y = signedHighWord(lparam) };
            _ = ClientToScreen(window, &point);
            self.last_right_click = point;
            self.pending_right_clicks +%= 1;
            return 0;
        },
        wm_mousewheel => {
            const point = Point{ .x = signedLowWord(lparam), .y = signedHighWord(lparam) };
            const callback = self.wheel_hit_test_callback orelse return DefWindowProcW(window, message, wparam, lparam);
            if (!callback(point, self.callback_context)) return DefWindowProcW(window, message, wparam, lparam);
            const delta: i16 = @bitCast(@as(u16, @truncate(wparam >> 16)));
            self.wheel_notches += delta;
            return 0;
        },
        wm_paint => {
            if (self.paint_callback) |callback| {
                callback(window, self.callback_context);
            } else {
                var paint: NativePaintStruct = undefined;
                if (BeginPaint(window, &paint) != null) _ = EndPaint(window, &paint);
            }
            return 0;
        },
        wm_destroy => {
            self.hwnd = null;
            self.pointer_timer = 0;
            self.shell_timer = 0;
            self.shown = false;
            self.destroyed = true;
            PostQuitMessage(0);
            return 0;
        },
        wm_ncdestroy => {
            _ = SetWindowLongPtrW(window, gwlp_userdata, 0);
            return DefWindowProcW(window, message, wparam, lparam);
        },
        else => return DefWindowProcW(window, message, wparam, lparam),
    }
}

fn signedLowWord(value: isize) i32 {
    const bits: usize = @bitCast(value);
    return @as(i16, @bitCast(@as(u16, @truncate(bits))));
}

fn signedHighWord(value: isize) i32 {
    const bits: usize = @bitCast(value);
    return @as(i16, @bitCast(@as(u16, @truncate(bits >> 16))));
}

fn updatePointer(self: *NativeWindow) bool {
    var point: Point = undefined;
    if (GetCursorPos(&point) == 0) return false;
    if (self.have_pointer and point.x == self.last_pointer.x and point.y == self.last_pointer.y) return false;
    self.have_pointer = true;
    self.last_pointer = point;
    const inside = point.x >= self.x and point.x < self.x + self.width and point.y >= self.y and point.y < self.y + self.height;
    if (inside != self.pointer_inside) {
        self.pointer_inside = inside;
        self.pointer_inside_changed = true;
        if (self.hwnd) |hwnd| _ = InvalidateRect(hwnd, null, 0);
    }
    return true;
}

pub const Rect = struct { left: i32 = 0, top: i32 = 0, right: i32 = 0, bottom: i32 = 0 };
pub const State = enum { hidden, resting, expanded, music_strip, call_strip, system_panel, sound_page, start_page };
pub const PointerDecision = enum { ignore, accept };

pub fn contains(rect: Rect, x: i32, y: i32) bool {
    return x >= rect.left and x < rect.right and y >= rect.top and y < rect.bottom;
}

pub fn intersect(a: Rect, b: Rect) ?Rect {
    const result = Rect{
        .left = @max(a.left, b.left),
        .top = @max(a.top, b.top),
        .right = @min(a.right, b.right),
        .bottom = @min(a.bottom, b.bottom),
    };
    if (result.right <= result.left or result.bottom <= result.top) return null;
    return result;
}

pub fn clampToMonitor(window: Rect, monitor: Rect) Rect {
    const width = @max(0, window.right - window.left);
    const height = @max(0, window.bottom - window.top);
    const left = std.math.clamp(window.left, monitor.left, @max(monitor.left, monitor.right - width));
    const top = std.math.clamp(window.top, monitor.top, @max(monitor.top, monitor.bottom - height));
    return .{ .left = left, .top = top, .right = left + width, .bottom = top + height };
}

pub fn pointerDecision(state: State, pointer_inside: bool, control_hit: bool) PointerDecision {
    if (state == .hidden) return .ignore;
    if (pointer_inside or control_hit or state == .expanded or state == .system_panel or state == .sound_page or state == .start_page)
        return .accept;
    return .ignore;
}

pub fn smokeCheck() bool {
    const monitor = Rect{ .left = -1920, .top = 0, .right = 0, .bottom = 1080 };
    const original = Rect{ .left = -20, .top = 10, .right = 80, .bottom = 110 };
    const clamped = clampToMonitor(original, monitor);
    var events = NativeWindow{};
    events.pending_clicks = 2;
    events.pending_right_clicks = 1;
    events.pending_presses = 1;
    events.last_press = .{ .x = -25, .y = 14 };
    events.wheel_notches = 190;
    var press: Point = undefined;
    if (!events.takeClick() or events.pendingClicks() != 1) return false;
    var right_click: Point = undefined;
    events.last_right_click = .{ .x = -50, .y = 24 };
    if (!events.takeRightClick(&right_click) or right_click.x != -50 or right_click.y != 24 or
        !events.takePress(&press) or press.x != -25 or press.y != 14) return false;
    if (events.takeWheelNotches() != 1 or events.wheel_notches != 70) return false;
    if (signedLowWord(packPoint(-25, 14)) != -25 or signedHighWord(packPoint(-25, 14)) != 14) return false;
    const pure_ok = contains(original, 0, 50) and !contains(original, 80, 50) and
        intersect(original, monitor) != null and clamped.left == -100 and clamped.right == 0 and
        pointerDecision(.hidden, true, true) == .ignore and pointerDecision(.resting, false, true) == .accept;
    if (!pure_ok) return false;

    var native = NativeWindow{};
    if (!native.create(100, 100, 40, 40, 0, noOpPaint, null, null)) return false;
    defer native.destroy();
    native.setPointerPollInterval(16);
    if (native.pointer_interval_ms != 16) return false;
    native.setPointerPollInterval(pointer_poll_ms);
    if (native.pointer_interval_ms != pointer_poll_ms) return false;
    native.setHitTestCallback(testHitTestLeftWindow);
    native.setWheelHitTestCallback(testWheelHitTest);
    var second = NativeWindow{};
    if (!second.create(200, 100, 40, 40, 0, noOpPaint, null, null)) return false;
    defer second.destroy();
    second.setHitTestCallback(testHitTestRightWindow);

    const first_hwnd = native.handle() orelse return false;
    const second_hwnd = second.handle() orelse return false;
    const native_dpi = native.dpi();
    if (native_dpi < 48 or native_dpi > 960) return false;
    const native_style: u32 = @truncate(@as(usize, @bitCast(GetWindowLongPtrW(first_hwnd, gwl_style))));
    const extended_style: u32 = @truncate(@as(usize, @bitCast(GetWindowLongPtrW(first_hwnd, gwl_exstyle))));
    const required_extended_style = ws_ex_topmost | ws_ex_noactivate | ws_ex_toolwindow | ws_ex_no_redirection_bitmap;
    if ((native_style & ws_popup) == 0 or (extended_style & required_extended_style) != required_extended_style or
        (extended_style & (ws_ex_transparent | ws_ex_appwindow)) != 0 or IsWindowVisible(first_hwnd) != 0) return false;
    var display_change_count: u32 = 0;
    native.callback_context = @ptrCast(&display_change_count);
    native.setDisplayChangeCallback(testDisplayChangeCallback);
    _ = SendMessageW(first_hwnd, wm_displaychange, 0, 0);
    native.show();
    const shown_extended_style: u32 = @truncate(@as(usize, @bitCast(GetWindowLongPtrW(first_hwnd, gwl_exstyle))));
    const visible_and_topmost = IsWindowVisible(first_hwnd) != 0 and (shown_extended_style & ws_ex_topmost) != 0;
    native.hide();
    const first_inside = SendMessageW(first_hwnd, wm_nchittest, 0, packPoint(115, 115));
    const first_outside = SendMessageW(first_hwnd, wm_nchittest, 0, packPoint(215, 115));
    const second_inside = SendMessageW(second_hwnd, wm_nchittest, 0, packPoint(215, 115));
    const second_outside = SendMessageW(second_hwnd, wm_nchittest, 0, packPoint(115, 115));
    _ = SendMessageW(first_hwnd, wm_mousewheel, packWheelDelta(120), packPoint(215, 115));
    _ = SendMessageW(first_hwnd, wm_mousewheel, packWheelDelta(60), packPoint(115, 115));
    _ = SendMessageW(first_hwnd, wm_mousewheel, packWheelDelta(60), packPoint(115, 115));
    return first_inside == ht_client and first_outside == ht_transparent and
        second_inside == ht_client and second_outside == ht_transparent and
        native.takeWheelNotches() == 1 and second.takeWheelNotches() == 0 and display_change_count == 1 and
        visible_and_topmost and cursorMessageCheck(&native, first_hwnd);
}

fn cursorMessageCheck(window: *NativeWindow, hwnd: *anyopaque) bool {
    const previous_cursor = GetCursor();
    defer _ = SetCursor(previous_cursor);
    window.setCursorHitTestCallback(testCursorHit);
    const hand_result = SendMessageW(hwnd, wm_setcursor, @intFromPtr(hwnd), ht_client);
    const hand = LoadCursorW(null, cursor_hand) orelse return false;
    if (hand_result != 1 or GetCursor() != hand) return false;
    window.setCursorHitTestCallback(testCursorMiss);
    const arrow_result = SendMessageW(hwnd, wm_setcursor, @intFromPtr(hwnd), ht_client);
    const arrow = LoadCursorW(null, cursor_arrow) orelse return false;
    return arrow_result == 1 and GetCursor() == arrow;
}

fn noOpPaint(_: HWND, _: ?*anyopaque) callconv(.winapi) void {}

fn testHitTestLeftWindow(point: Point, _: ?*anyopaque) callconv(.winapi) bool {
    return point.x >= 110 and point.x < 120 and point.y >= 110 and point.y < 120;
}

fn testHitTestRightWindow(point: Point, _: ?*anyopaque) callconv(.winapi) bool {
    return point.x >= 210 and point.x < 220 and point.y >= 110 and point.y < 120;
}

fn testWheelHitTest(point: Point, _: ?*anyopaque) callconv(.winapi) bool {
    return point.x >= 110 and point.x < 120 and point.y >= 110 and point.y < 120;
}

fn testDisplayChangeCallback(raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const count: *u32 = @ptrCast(@alignCast(raw));
    count.* += 1;
}

fn testCursorHit(_: Point, _: ?*anyopaque) callconv(.winapi) bool {
    return true;
}

fn testCursorMiss(_: Point, _: ?*anyopaque) callconv(.winapi) bool {
    return false;
}

fn packWheelDelta(delta: i16) usize {
    return @as(usize, @as(u16, @bitCast(delta))) << 16;
}

fn packPoint(x: i16, y: i16) isize {
    const low: u32 = @intCast(@as(u16, @bitCast(x)));
    const high: u32 = @intCast(@as(u16, @bitCast(y)));
    const bits: usize = low | (high << 16);
    return @bitCast(bits);
}
