const std = @import("std");

const HANDLE = ?*anyopaque;
const HWND = HANDLE;
const HINSTANCE = HANDLE;
const HDC = HANDLE;
const HBRUSH = HANDLE;
const BOOL = i32;
const UINT = u32;
const DWORD = u32;
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;
const WindowProc = *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT;

const Rect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const Size = extern struct { cx: i32, cy: i32 };
const PaintStruct = extern struct { dc: HDC, erase: BOOL, paint: Rect, restore: BOOL, update: BOOL, reserved: [32]u8 };
const WindowClassEx = extern struct { size: UINT, style: UINT, proc: WindowProc, class_extra: i32, window_extra: i32, instance: HINSTANCE, icon: HANDLE, cursor: HANDLE, background: HBRUSH, menu_name: ?[*:0]const u16, class_name: [*:0]const u16, small_icon: HANDLE };
const Message = extern struct { window: HWND, id: UINT, wparam: WPARAM, lparam: LPARAM, time: DWORD, point: extern struct { x: i32, y: i32 }, private: DWORD };
const ThumbnailProperties = extern struct { flags: DWORD, destination: Rect, source: Rect, opacity: u8, visible: BOOL, source_client_area_only: BOOL };

extern "kernel32" fn GetModuleHandleW(module: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "user32" fn RegisterClassExW(value: *const WindowClassEx) callconv(.winapi) u16;
extern "user32" fn CreateWindowExW(ex_style: DWORD, class_name: [*:0]const u16, title: [*:0]const u16, style: DWORD, x: i32, y: i32, width: i32, height: i32, parent: HWND, menu: HANDLE, instance: HINSTANCE, parameter: ?*anyopaque) callconv(.winapi) HWND;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) BOOL;
extern "user32" fn UpdateWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPos(window: HWND, after: HWND, x: i32, y: i32, width: i32, height: i32, flags: UINT) callconv(.winapi) BOOL;
extern "user32" fn GetWindowRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn BeginPaint(window: HWND, paint: *PaintStruct) callconv(.winapi) HDC;
extern "user32" fn EndPaint(window: HWND, paint: *const PaintStruct) callconv(.winapi) BOOL;
extern "user32" fn GetClientRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn DefWindowProcW(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn LoadCursorW(instance: HINSTANCE, cursor: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "user32" fn InvalidateRect(window: HWND, rect: ?*const Rect, erase: BOOL) callconv(.winapi) BOOL;
extern "user32" fn PeekMessageW(message: *Message, window: HWND, min: UINT, max: UINT, remove: UINT) callconv(.winapi) BOOL;
extern "user32" fn TranslateMessage(message: *const Message) callconv(.winapi) BOOL;
extern "user32" fn DispatchMessageW(message: *const Message) callconv(.winapi) LRESULT;
extern "user32" fn DestroyWindow(window: HWND) callconv(.winapi) BOOL;
extern "gdi32" fn DeleteObject(object: HANDLE) callconv(.winapi) BOOL;
extern "gdi32" fn CreateSolidBrush(color: DWORD) callconv(.winapi) HBRUSH;
extern "gdi32" fn FillRect(dc: HDC, rect: *const Rect, brush: HBRUSH) callconv(.winapi) i32;
extern "dwmapi" fn DwmRegisterThumbnail(destination: HWND, source: HWND, thumbnail: *HANDLE) callconv(.winapi) i32;
extern "dwmapi" fn DwmUnregisterThumbnail(thumbnail: HANDLE) callconv(.winapi) i32;
extern "dwmapi" fn DwmQueryThumbnailSourceSize(thumbnail: HANDLE, size: *Size) callconv(.winapi) i32;
extern "dwmapi" fn DwmUpdateThumbnailProperties(thumbnail: HANDLE, properties: *const ThumbnailProperties) callconv(.winapi) i32;
extern "dwmapi" fn DwmGetWindowAttribute(window: HWND, attribute: DWORD, value: *i32, size: DWORD) callconv(.winapi) i32;

const wm_paint: UINT = 0x000f;
const wm_erasebkgnd: UINT = 0x0014;
const cs_v_redraw: UINT = 1;
const cs_h_redraw: UINT = 2;
const error_class_already_exists: DWORD = 1410;
const ws_overlappedwindow: DWORD = 0x00cf0000;
const ws_popup: DWORD = 0x80000000;
const ws_child: DWORD = 0x40000000;
const ws_visible: DWORD = 0x10000000;
const ws_ex_topmost: DWORD = 8;
const ws_ex_noactivate: DWORD = 0x08000000;
const ws_ex_toolwindow: DWORD = 0x80;
const sw_shownoactivate: i32 = 4;
const swp_noactivate: UINT = 0x10;
const swp_showwindow: UINT = 0x40;
const pm_remove: UINT = 1;
const dwm_destination: DWORD = 1;
const dwm_source: DWORD = 2;
const dwm_opacity: DWORD = 4;
const dwm_visible: DWORD = 8;
const dwm_client_only: DWORD = 0x10;
const dwm_attribute_cloaked: DWORD = 14;
const thumbnail_class: [*:0]const u16 = &.{ 'T', 'h', 'u', 'm', 'b', 'P', 'r', 'o', 'b', 'e', 'D', 'e', 's', 't', 'i', 'n', 'a', 't', 'i', 'o', 'n', 0 };
const source_class: [*:0]const u16 = &.{ 'T', 'h', 'u', 'm', 'b', 'P', 'r', 'o', 'b', 'e', 'S', 'o', 'u', 'r', 'c', 'e', 0 };
const source_title: [*:0]const u16 = &.{ 't', 'h', 'u', 'm', 'b', 'p', 'r', 'o', 'b', 'e', ' ', 's', 'o', 'u', 'r', 'c', 'e', 0 };
const dest_title: [*:0]const u16 = &.{ 't', 'h', 'u', 'm', 'b', 'p', 'r', 'o', 'b', 'e', ' ', 'd', 'e', 's', 't', 'i', 'n', 'a', 't', 'i', 'o', 'n', 0 };
var phase: i32 = 0;

fn rgb(r: u8, g: u8, b: u8) DWORD {
    return @as(DWORD, r) | (@as(DWORD, g) << 8) | (@as(DWORD, b) << 16);
}

fn sourceProc(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    if (message == wm_erasebkgnd) return 1;
    if (message == wm_paint) {
        var paint = std.mem.zeroes(PaintStruct);
        const dc = BeginPaint(window, &paint);
        var client = std.mem.zeroes(Rect);
        _ = GetClientRect(window, &client);
        const green = CreateSolidBrush(rgb(0, 160, 0));
        _ = FillRect(dc, &client, green);
        _ = DeleteObject(green);
        const red = CreateSolidBrush(rgb(220, 0, 0));
        const square = Rect{ .left = 20, .top = 20, .right = 120, .bottom = 120 };
        _ = FillRect(dc, &square, red);
        _ = DeleteObject(red);
        const white = CreateSolidBrush(rgb(255, 255, 255));
        const x = 20 + @mod(phase, 20) * 10;
        const bar = Rect{ .left = x, .top = 150, .right = x + 80, .bottom = 190 };
        _ = FillRect(dc, &bar, white);
        _ = DeleteObject(white);
        _ = EndPaint(window, &paint);
        return 0;
    }
    return DefWindowProcW(window, message, wparam, lparam);
}

fn destinationProc(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    if (message == wm_erasebkgnd) return 1;
    return DefWindowProcW(window, message, wparam, lparam);
}

fn registerClass(name: [*:0]const u16, proc: WindowProc) bool {
    const instance = GetModuleHandleW(null);
    const wc = WindowClassEx{ .size = @sizeOf(WindowClassEx), .style = cs_h_redraw | cs_v_redraw, .proc = proc, .class_extra = 0, .window_extra = 0, .instance = instance, .icon = null, .cursor = LoadCursorW(null, @ptrFromInt(32512)), .background = null, .menu_name = null, .class_name = name, .small_icon = null };
    return RegisterClassExW(&wc) != 0 or GetLastError() == error_class_already_exists;
}

fn updateThumbnail(dest: HWND, source: HWND, handle: *HANDLE, explicit_source: bool) i32 {
    const registered = DwmRegisterThumbnail(dest, source, handle);
    std.debug.print("DwmRegisterThumbnail: 0x{x:0>8}, handle {s}\n", .{ @as(u32, @bitCast(registered)), if (handle.* != null) "ok" else "NONE" });
    if (registered < 0 or handle.* == null) return registered;
    var size = Size{ .cx = 0, .cy = 0 };
    _ = DwmQueryThumbnailSourceSize(handle.*, &size);
    std.debug.print("source size: {d}x{d}\n", .{ size.cx, size.cy });
    const flags = dwm_destination | dwm_source | dwm_opacity | dwm_visible | (if (explicit_source) 0 else dwm_client_only);
    const props = ThumbnailProperties{
        .flags = flags,
        .destination = .{ .left = 0, .top = 0, .right = 480, .bottom = 360 },
        .source = if (explicit_source) .{ .left = 0, .top = 0, .right = size.cx, .bottom = size.cy } else .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
        .opacity = 255,
        .visible = 1,
        .source_client_area_only = 0,
    };
    const updated = DwmUpdateThumbnailProperties(handle.*, &props);
    std.debug.print("DwmUpdateThumbnailProperties: 0x{x:0>8}\n", .{@as(u32, @bitCast(updated))});
    return updated;
}

pub fn main() void {
    std.debug.print("--- DWM thumbnail probe ---\n", .{});
    if (!registerClass(source_class, &sourceProc) or !registerClass(thumbnail_class, &destinationProc)) {
        std.debug.print("FATAL: could not register a window class (error {d})\n", .{GetLastError()});
        return;
    }
    const instance = GetModuleHandleW(null);
    const source = CreateWindowExW(0, source_class, source_title, ws_overlappedwindow, 100, 100, 640, 480, null, null, instance, null) orelse return;
    _ = ShowWindow(source, sw_shownoactivate);
    _ = UpdateWindow(source);
    const ex_style = ws_ex_topmost | ws_ex_noactivate | ws_ex_toolwindow;
    const dest = CreateWindowExW(ex_style, thumbnail_class, dest_title, ws_popup, 800, 200, 480, 360, null, null, instance, null) orelse {
        _ = DestroyWindow(source);
        return;
    };
    _ = ShowWindow(dest, sw_shownoactivate);
    const topmost: HWND = @ptrFromInt(std.math.maxInt(usize));
    _ = SetWindowPos(dest, topmost, 800, 200, 480, 360, swp_noactivate | swp_showwindow);
    var bounds = std.mem.zeroes(Rect);
    _ = GetWindowRect(dest, &bounds);
    std.debug.print("destination at {d},{d} {d}x{d}\n", .{ bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top });

    var a: HANDLE = null;
    _ = updateThumbnail(dest, source, &a, false);
    const host = CreateWindowExW(ex_style, thumbnail_class, dest_title, ws_popup, 200, 800, 480, 360, null, null, instance, null);
    var child: HWND = null;
    var b: HANDLE = null;
    if (host) |host_window| {
        child = CreateWindowExW(0, thumbnail_class, dest_title, ws_child | ws_visible, 0, 0, 480, 360, host_window, null, instance, null);
        _ = ShowWindow(host_window, sw_shownoactivate);
        _ = SetWindowPos(host_window, topmost, 200, 800, 480, 360, swp_noactivate | swp_showwindow);
        if (child) |child_window| _ = updateThumbnail(child_window, source, &b, false);
    }
    const explicit = CreateWindowExW(ex_style, thumbnail_class, dest_title, ws_popup, 800, 600, 480, 360, null, null, instance, null);
    var c: HANDLE = null;
    if (explicit) |window| {
        _ = ShowWindow(window, sw_shownoactivate);
        _ = SetWindowPos(window, topmost, 800, 600, 480, 360, swp_noactivate | swp_showwindow);
        _ = updateThumbnail(window, source, &c, true);
    }
    var source_cloaked: i32 = 0;
    var dest_cloaked: i32 = 0;
    _ = DwmGetWindowAttribute(source, dwm_attribute_cloaked, &source_cloaked, @sizeOf(i32));
    _ = DwmGetWindowAttribute(dest, dwm_attribute_cloaked, &dest_cloaked, @sizeOf(i32));
    std.debug.print("cloaked: source={d} destination={d}\n", .{ source_cloaked, dest_cloaked });

    const started = GetTickCount64();
    while (GetTickCount64() - started < 10_000) {
        var message = std.mem.zeroes(Message);
        while (PeekMessageW(&message, null, 0, 0, pm_remove) != 0) {
            _ = TranslateMessage(&message);
            _ = DispatchMessageW(&message);
        }
        phase += 1;
        _ = InvalidateRect(source, null, 0);
        _ = UpdateWindow(source);
        Sleep(500);
    }
    if (b) |thumb| _ = DwmUnregisterThumbnail(thumb);
    if (c) |thumb| _ = DwmUnregisterThumbnail(thumb);
    if (a) |thumb| _ = DwmUnregisterThumbnail(thumb);
    if (explicit) |window| _ = DestroyWindow(window);
    if (host) |window| _ = DestroyWindow(window);
    _ = DestroyWindow(dest);
    _ = DestroyWindow(source);
    std.debug.print("done\n", .{});
}
