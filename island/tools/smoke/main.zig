const std = @import("std");

const HRESULT = i32;
const BOOL = i32;
const UINT = u32;
const DWORD = u32;
const HWND = ?*anyopaque;
const HMONITOR = ?*anyopaque;
const HANDLE = ?*anyopaque;

const Guid = extern struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,
};
const Point = extern struct { x: i32, y: i32 };
const Rect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const MonitorInfo = extern struct { size: DWORD, monitor: Rect, work: Rect, flags: DWORD };
const AppBarData = extern struct {
    size: DWORD,
    window: HWND,
    callback_message: UINT,
    edge: UINT,
    rect: Rect,
    data: isize,
};

const UnknownVTable = extern struct {
    query_interface: *const fn (*Unknown, *const Guid, *?*anyopaque) callconv(.winapi) HRESULT,
    add_ref: *const fn (*Unknown) callconv(.winapi) u32,
    release: *const fn (*Unknown) callconv(.winapi) u32,
};
const Unknown = extern struct { vtable: *const UnknownVTable };

const iid_unknown = Guid{ .data1 = 0, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const iid_d3d11_device5 = Guid{ .data1 = 0x8FFDE202, .data2 = 0xA0E7, .data3 = 0x45DF, .data4 = .{ 0x9E, 0x01, 0xE8, 0x37, 0x80, 0x1B, 0x5E, 0xA0 } };
const iid_dxgi_device = Guid{ .data1 = 0x54EC77FA, .data2 = 0x1377, .data3 = 0x44E6, .data4 = .{ 0x8C, 0x32, 0x88, 0xFD, 0x5F, 0x44, 0xC8, 0x4C } };
const iid_d2d_factory = Guid{ .data1 = 0x06152247, .data2 = 0x6F50, .data3 = 0x465A, .data4 = .{ 0x92, 0x45, 0x11, 0x8B, 0xFD, 0x3B, 0x60, 0x07 } };
const iid_d2d_factory3 = Guid{ .data1 = 0x0869759F, .data2 = 0x4F00, .data3 = 0x413F, .data4 = .{ 0xB0, 0x3E, 0x2B, 0xDA, 0x45, 0x40, 0x4D, 0x0F } };
const iid_dcomp_device = Guid{ .data1 = 0xC37EA93A, .data2 = 0xE7AA, .data3 = 0x450D, .data4 = .{ 0xB1, 0x6F, 0x97, 0x46, 0xCB, 0x04, 0x07, 0xF3 } };
const iid_dwrite_factory = Guid{ .data1 = 0xB859EE5A, .data2 = 0xD838, .data3 = 0x4B5B, .data4 = .{ 0xA2, 0xE8, 0x1A, 0xDC, 0x7D, 0x93, 0xDB, 0x48 } };
const iid_dwrite_factory3 = Guid{ .data1 = 0x9A1B41C3, .data2 = 0xD3BB, .data3 = 0x466A, .data4 = .{ 0x87, 0xFC, 0xFE, 0x67, 0x55, 0x6A, 0x3B, 0x65 } };
const clsid_ui_automation = Guid{ .data1 = 0xFF48DBA4, .data2 = 0x60EF, .data3 = 0x4201, .data4 = .{ 0xAA, 0x87, 0x54, 0x10, 0x3E, 0xEF, 0x59, 0x4E } };
const iid_ui_automation = Guid{ .data1 = 0x30CBE57D, .data2 = 0xD9D0, .data3 = 0x452A, .data4 = .{ 0xAB, 0x13, 0x7A, 0xC5, 0xAC, 0x48, 0x25, 0xEE } };

extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, apartment: DWORD) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoCreateInstance(clsid: *const Guid, outer: ?*anyopaque, context: DWORD, iid: *const Guid, object: *?*anyopaque) callconv(.winapi) HRESULT;
extern "d3d11" fn D3D11CreateDevice(adapter: ?*anyopaque, driver_type: i32, software: HANDLE, flags: UINT, feature_levels: ?[*]const u32, feature_level_count: UINT, sdk_version: UINT, device: *?*anyopaque, feature_level: ?*u32, immediate_context: *?*anyopaque) callconv(.winapi) HRESULT;
extern "d2d1" fn D2D1CreateFactory(factory_type: i32, iid: *const Guid, options: ?*const anyopaque, factory: *?*anyopaque) callconv(.winapi) HRESULT;
extern "dcomp" fn DCompositionCreateDevice(dxgi_device: ?*anyopaque, iid: *const Guid, device: *?*anyopaque) callconv(.winapi) HRESULT;
extern "dwrite" fn DWriteCreateFactory(factory_type: i32, iid: *const Guid, factory: *?*anyopaque) callconv(.winapi) HRESULT;
extern "user32" fn FindWindowW(class_name: ?[*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn GetWindowRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn MonitorFromPoint(point: Point, flags: DWORD) callconv(.winapi) HMONITOR;
extern "user32" fn GetMonitorInfoW(monitor: HMONITOR, info: *MonitorInfo) callconv(.winapi) BOOL;
extern "shcore" fn GetDpiForMonitor(monitor: HMONITOR, dpi_type: i32, dpi_x: *UINT, dpi_y: *UINT) callconv(.winapi) HRESULT;
extern "dwmapi" fn DwmIsCompositionEnabled(enabled: *BOOL) callconv(.winapi) HRESULT;
extern "shell32" fn SHAppBarMessage(message: DWORD, data: *AppBarData) callconv(.winapi) usize;

const result = struct {
    var failures: u32 = 0;
};

fn check(ok: bool, label: []const u8) void {
    if (ok) {
        std.debug.print("[ OK ] {s}\n", .{label});
    } else {
        std.debug.print("[FAIL] {s}\n", .{label});
        result.failures += 1;
    }
}

fn succeeded(hr: HRESULT) bool {
    return hr >= 0;
}

fn release(object: ?*anyopaque) void {
    if (object) |raw| {
        const unknown: *Unknown = @ptrCast(@alignCast(raw));
        _ = unknown.vtable.release(unknown);
    }
}

fn query(object: ?*anyopaque, iid: *const Guid) ?*anyopaque {
    const raw = object orelse return null;
    const unknown: *Unknown = @ptrCast(@alignCast(raw));
    var queried: ?*anyopaque = null;
    if (!succeeded(unknown.vtable.query_interface(unknown, iid, &queried))) return null;
    return queried;
}

fn testGraphics() void {
    var device: ?*anyopaque = null;
    var context: ?*anyopaque = null;
    var feature_level: u32 = 0;
    var hr = D3D11CreateDevice(null, 1, null, 0, null, 0, 7, &device, &feature_level, &context);
    if (!succeeded(hr) or device == null) {
        hr = D3D11CreateDevice(null, 5, null, 0, null, 0, 7, &device, &feature_level, &context);
    }
    check(succeeded(hr) and device != null, "D3D11 hardware or WARP device");
    if (device) |d3d_device| {
        const device5 = query(d3d_device, &iid_d3d11_device5);
        check(device5 != null, "ID3D11Device5");
        release(device5);
        const dxgi = query(d3d_device, &iid_dxgi_device);
        check(dxgi != null, "IDXGIDevice");
        if (dxgi) |dxgi_device| {
            var comp: ?*anyopaque = null;
            const comp_hr = DCompositionCreateDevice(dxgi_device, &iid_dcomp_device, &comp);
            check(succeeded(comp_hr) and comp != null, "DirectComposition device");
            release(comp);
        }
        release(dxgi);
    }
    release(context);
    release(device);

    var factory: ?*anyopaque = null;
    hr = D2D1CreateFactory(0, &iid_d2d_factory, null, &factory);
    check(succeeded(hr) and factory != null, "Direct2D factory");
    if (factory != null) {
        const factory3 = query(factory, &iid_d2d_factory3);
        check(factory3 != null, "ID2D1Factory3");
        release(factory3);
    }
    release(factory);

    var write_factory: ?*anyopaque = null;
    hr = DWriteCreateFactory(0, &iid_dwrite_factory, &write_factory);
    check(succeeded(hr) and write_factory != null, "DirectWrite factory");
    if (write_factory != null) {
        const factory3 = query(write_factory, &iid_dwrite_factory3);
        check(factory3 != null, "IDWriteFactory3");
        release(factory3);
    }
    release(write_factory);
}

fn testDesktop() void {
    var appbar = std.mem.zeroes(AppBarData);
    appbar.size = @sizeOf(AppBarData);
    check(SHAppBarMessage(5, &appbar) != 0, "shell appbar position");

    const taskbar = FindWindowW(&.{ 'S', 'h', 'e', 'l', 'l', '_', 'T', 'r', 'a', 'y', 'W', 'n', 'd', 0 }, null);
    var rect: Rect = undefined;
    check(taskbar != null and GetWindowRect(taskbar, &rect) != 0, "taskbar window bounds");

    const monitor = MonitorFromPoint(.{ .x = 0, .y = 0 }, 2);
    var info = std.mem.zeroes(MonitorInfo);
    info.size = @sizeOf(MonitorInfo);
    check(monitor != null and GetMonitorInfoW(monitor, &info) != 0, "monitor information");
    if (monitor != null) {
        var dpi_x: UINT = 0;
        var dpi_y: UINT = 0;
        check(succeeded(GetDpiForMonitor(monitor, 0, &dpi_x, &dpi_y)) and dpi_x > 0 and dpi_y > 0, "monitor DPI");
    }

    var composition: BOOL = 0;
    check(succeeded(DwmIsCompositionEnabled(&composition)), "DWM composition state");

    var automation: ?*anyopaque = null;
    const automation_hr = CoCreateInstance(&clsid_ui_automation, null, 1, &iid_ui_automation, &automation);
    check(succeeded(automation_hr) and automation != null, "UI Automation client");
    release(automation);
}

pub fn main() void {
    const com = CoInitializeEx(null, 0);
    check(succeeded(com), "COM MTA initialization");
    if (!succeeded(com)) std.process.exit(1);
    defer CoUninitialize();

    std.debug.print("--- IslandBar native API smoke ---\n", .{});
    testGraphics();
    testDesktop();
    std.debug.print("{d} failure(s)\n", .{result.failures});
    if (result.failures != 0) std.process.exit(1);
}

comptime {
    _ = iid_unknown;
}
