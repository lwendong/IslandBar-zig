const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");
const TextRenderer = @import("TextRenderer");
const MusicSession = @import("MusicSession");
const WicImage = @import("WicImage");
const Notification = @import("Notification");
const Weather = @import("Weather");
const TaskStripLayout = @import("TaskStripLayout");
const CardLayout = @import("CardLayout");
const Theme = @import("Theme");

const HResult = i32;
const UINT = u32;
const Handle = ?*anyopaque;
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const UnknownVTable = extern struct {
    query_interface: *const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) HResult,
    add_ref: *const fn (*anyopaque) callconv(.winapi) u32,
    release: *const fn (*anyopaque) callconv(.winapi) u32,
};
const Unknown = extern struct { vtable: *const UnknownVTable };
const WaitForClockFn = *const fn (UINT, ?[*]const Handle, UINT) callconv(.winapi) UINT;
const SampleDesc = extern struct { count: UINT, quality: UINT };
const D3D11Texture2DDesc = extern struct {
    width: UINT,
    height: UINT,
    mip_levels: UINT,
    array_size: UINT,
    format: i32,
    sample_desc: SampleDesc,
    usage: i32,
    bind_flags: UINT,
    cpu_access_flags: UINT,
    misc_flags: UINT,
};
const D3D11MappedSubresource = extern struct { data: Handle, row_pitch: UINT, depth_pitch: UINT };
const SwapChainDesc1 = extern struct {
    width: UINT,
    height: UINT,
    format: i32,
    stereo: i32,
    sample_desc: SampleDesc,
    buffer_usage: UINT,
    buffer_count: UINT,
    scaling: i32,
    swap_effect: i32,
    alpha_mode: i32,
    flags: UINT,
};
const Matrix3x2 = extern struct { m11: f32, m12: f32, m21: f32, m22: f32, m31: f32, m32: f32 };
const PixelFormat = extern struct { format: i32, alpha_mode: i32 };
const BitmapProperties1 = extern struct {
    pixel_format: PixelFormat,
    dpi_x: f32,
    dpi_y: f32,
    options: u32,
    color_context: Handle,
};
const D2DSizeU = extern struct { width: UINT, height: UINT };
const BitmapV5Header = extern struct {
    size: u32,
    width: i32,
    height: i32,
    planes: u16,
    bit_count: u16,
    compression: u32,
    image_size: u32,
    x_pels_per_meter: i32,
    y_pels_per_meter: i32,
    colors_used: u32,
    colors_important: u32,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    alpha_mask: u32,
    color_space_type: u32,
    endpoints: [36]u8,
    gamma_red: u32,
    gamma_green: u32,
    gamma_blue: u32,
    intent: u32,
    profile_data: u32,
    profile_size: u32,
    reserved: u32,
};
const D2DColor = extern struct { r: f32, g: f32, b: f32, a: f32 };
const D2DRectF = extern struct { left: f32, top: f32, right: f32, bottom: f32 };
const D2DRoundedRect = extern struct { rect: D2DRectF, radius_x: f32, radius_y: f32 };

extern "d3d11" fn D3D11CreateDevice(
    adapter: Handle,
    driver_type: i32,
    software: Handle,
    flags: UINT,
    feature_levels: ?[*]const UINT,
    feature_level_count: UINT,
    sdk_version: UINT,
    device: *Handle,
    feature_level: ?*UINT,
    immediate_context: *Handle,
) callconv(.winapi) HResult;
extern "d2d1" fn D2D1CreateFactory(factory_type: i32, iid: *const Guid, options: ?*const anyopaque, factory: *Handle) callconv(.winapi) HResult;
extern "dcomp" fn DCompositionCreateDevice(dxgi_device: Handle, iid: *const Guid, device: *Handle) callconv(.winapi) HResult;
extern "kernel32" fn GetModuleHandleW(name: [*:0]const u16) callconv(.winapi) Handle;
extern "kernel32" fn GetProcAddress(module: Handle, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "user32" fn IsWindow(window: Handle) callconv(.winapi) i32;
extern "user32" fn SendMessageTimeoutW(window: Handle, message: UINT, wparam: usize, lparam: isize, flags: UINT, timeout: UINT, result: *usize) callconv(.winapi) usize;
extern "user32" fn GetClassLongPtrW(window: Handle, index: i32) callconv(.winapi) usize;
extern "user32" fn GetWindowThreadProcessId(window: Handle, process_id: *u32) callconv(.winapi) u32;
extern "user32" fn GetDC(window: Handle) callconv(.winapi) Handle;
extern "user32" fn ReleaseDC(window: Handle, dc: Handle) callconv(.winapi) i32;
extern "user32" fn DrawIconEx(dc: Handle, x: i32, y: i32, icon: Handle, width: i32, height: i32, step: u32, brush: Handle, flags: UINT) callconv(.winapi) i32;
extern "kernel32" fn OpenProcess(access: u32, inherit: i32, process_id: u32) callconv(.winapi) Handle;
extern "kernel32" fn QueryFullProcessImageNameW(process: Handle, flags: u32, path: [*]u16, length: *u32) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: Handle) callconv(.winapi) i32;
extern "gdi32" fn CreateCompatibleDC(dc: Handle) callconv(.winapi) Handle;
extern "gdi32" fn DeleteDC(dc: Handle) callconv(.winapi) i32;
extern "gdi32" fn CreateDIBSection(dc: Handle, header: *const BitmapV5Header, usage: UINT, bits: *Handle, section: Handle, offset: u32) callconv(.winapi) Handle;
extern "gdi32" fn SelectObject(dc: Handle, object: Handle) callconv(.winapi) Handle;
extern "gdi32" fn DeleteObject(object: Handle) callconv(.winapi) i32;
extern "gdi32" fn GdiFlush() callconv(.winapi) i32;

const iid_dxgi_device = Guid{ .data1 = 0x54EC77FA, .data2 = 0x1377, .data3 = 0x44E6, .data4 = .{ 0x8C, 0x32, 0x88, 0xFD, 0x5F, 0x44, 0xC8, 0x4C } };
const iid_dxgi_factory2 = Guid{ .data1 = 0x50C83A1C, .data2 = 0xE072, .data3 = 0x4C48, .data4 = .{ 0x87, 0xB0, 0x36, 0x30, 0xFA, 0x36, 0xA6, 0xD0 } };
const iid_dxgi_surface = Guid{ .data1 = 0xCAFCB56C, .data2 = 0x6AC3, .data3 = 0x4889, .data4 = .{ 0xBF, 0x47, 0x9E, 0x23, 0xBB, 0xD2, 0x60, 0xEC } };
const iid_d3d11_resource = Guid{ .data1 = 0xDC8E63F3, .data2 = 0xD12B, .data3 = 0x4952, .data4 = .{ 0xB4, 0x7B, 0x5E, 0x45, 0x02, 0x6A, 0x86, 0x2D } };
const iid_d2d_factory3 = Guid{ .data1 = 0x0869759F, .data2 = 0x4F00, .data3 = 0x413F, .data4 = .{ 0xB0, 0x3E, 0x2B, 0xDA, 0x45, 0x40, 0x4D, 0x0F } };
const iid_dcomp_device = Guid{ .data1 = 0xC37EA93A, .data2 = 0xE7AA, .data3 = 0x450D, .data4 = .{ 0xB1, 0x6F, 0x97, 0x46, 0xCB, 0x04, 0x07, 0xF3 } };
const d3d_driver_hardware: i32 = 1;
const d3d_driver_warp: i32 = 5;
const d3d_create_device_bgra_support: UINT = 0x20;
const d3d11_sdk_version: UINT = 7;
const wait_timeout: UINT = 0x102;
const wait_failed: UINT = 0xFFFFFFFF;
const dcomp_dll_name = [_:0]u16{ 'd', 'c', 'o', 'm', 'p', '.', 'd', 'l', 'l' };
const d2d_factory_type_single_threaded: i32 = 0;
const d2d_device_context_options_none: UINT = 0;
const d2d_antialias_mode_per_primitive: i32 = 0;
const d2d_text_antialias_mode_grayscale: i32 = 0;
const dxgi_format_b8g8r8a8_unorm: i32 = 87;
const d3d11_usage_staging: i32 = 3;
const d3d11_cpu_access_read: UINT = 0x0002_0000;
const d3d11_map_read: i32 = 1;
const dxgi_usage_render_target_output: UINT = 0x20;
const dxgi_scaling_stretch: i32 = 0;
const dxgi_swap_effect_flip_sequential: i32 = 3;
const dxgi_alpha_mode_premultiplied: i32 = 1;
const d2d_bitmap_option_target: u32 = 1;
const d2d_bitmap_option_cannot_draw: u32 = 2;
const d2d_alpha_mode_premultiplied: i32 = 1;
const process_query_limited_information: u32 = 0x1000;
const wm_geticon: UINT = 0x007f;
const icon_big: usize = 1;
const icon_small: usize = 0;
const smto_abort_if_hung: UINT = 0x0002;
const gclp_hicon: i32 = -14;
const dib_rgb_colors: UINT = 0;
const bi_bitfields: u32 = 3;
const di_normal: UINT = 3;
const max_window_icons: usize = 64;

const WindowIcon = struct { window: Handle = null, bitmap: Handle = null };

pub const ReadbackError = error{
    RendererNotInitialized,
    SwapChainBufferUnavailable,
    ResourceUnavailable,
    StagingTextureUnavailable,
    MapFailed,
    InvalidCoordinate,
    SampleOutOfBounds,
    InvalidRegion,
};

const MappedFrame = struct {
    context: *anyopaque,
    staging: Handle,
    resource: Handle,
    mapped: D3D11MappedSubresource,

    fn deinit(self: *MappedFrame) void {
        const staging = self.staging orelse return;
        const unmap = comMethod(*const fn (*anyopaque, *anyopaque, UINT) callconv(.winapi) void, self.context, 15);
        unmap(self.context, staging, 0);
        release(&self.staging);
        release(&self.resource);
    }
};

const PixelPoint = struct { x: usize, y: usize };

fn succeeded(hr: HResult) bool {
    return hr >= 0;
}

fn windowIcon(window: Handle, which: usize) Handle {
    var result: usize = 0;
    if (SendMessageTimeoutW(window, wm_geticon, which, 0, smto_abort_if_hung, 100, &result) == 0 or result == 0) return null;
    return @ptrFromInt(result);
}

fn release(object: *Handle) void {
    if (object.*) |raw| {
        const unknown: *Unknown = @ptrCast(@alignCast(raw));
        _ = unknown.vtable.release(raw);
        object.* = null;
    }
}

fn queryInterface(object: Handle, iid: *const Guid) ?*anyopaque {
    const raw = object orelse return null;
    const unknown: *Unknown = @ptrCast(@alignCast(raw));
    var result: Handle = null;
    if (!succeeded(unknown.vtable.query_interface(raw, iid, &result))) return null;
    return result;
}

fn comMethod(comptime T: type, object: *anyopaque, index: usize) T {
    const header: *const extern struct { vtable: [*]const ?*anyopaque } = @ptrCast(@alignCast(object));
    return @ptrCast(header.vtable[index] orelse unreachable);
}

pub const max_task_buttons: usize = TextRenderer.task_button_count_max;
pub const max_tray_menu_entries: usize = 6;

pub const CardOwner = enum(i32) { none = 0, system_panel = 1, notification = 2, music = 3 };
pub const PillAppearance = struct {
    box: Geometry.RoundedBox = .{ .rect = .{} },
    resting_pill: Geometry.RoundedBox = .{ .rect = .{} },
    deck_box: ?Geometry.RoundedBox = null,
    surface_box: ?Geometry.RoundedBox = null,
    fill: [4]f32 = .{ 0.05, 0.05, 0.07, 0.92 },
    opacity: f32 = 1,
    task_island: Geometry.RoundedBox = .{ .rect = .{} },
    task_buttons: []const TextRenderer.TaskButton = &.{},
    task_button_appear: []const f32 = &.{},
    task_hovered_index: i32 = -1,
    task_card_left_dip: f32 = 0,
    task_card_width_dip: f32 = 0,
    start_hover: f32 = 0,
    start_open: bool = false,
    system_hover: f32 = 0,
    system_open: bool = false,
    tray_visible: bool = false,
    tray_hover: f32 = 0,
    tray_open: bool = false,
    music_text: []const u8 = &.{},
    music_card: ?*const TextRenderer.MusicCardText = null,
    notification: ?*const Notification.Notification = null,
    card_notification: ?*const Notification.Notification = null,
    notification_icon_pixels: ?[]const u8 = null,
    notification_icon_width: i32 = 0,
    notification_icon_height: i32 = 0,
    notification_icon_revision: u64 = 0,
    call_up: bool = false,
    call_strip: TextRenderer.CallStripText = .{},
    fullscreen_app: bool = false,
    resting_state: Motion.IslandState = .collapsed,
    music_present: bool = false,
    music_level: f32 = 0,
    music_level_known: bool = false,
    music_wave_phase: f32 = 0,
    music_accent: Theme.Color = .{ .r = 0.40, .g = 0.80, .b = 0.95, .a = 1 },
    lyric_scroll_dip: f32 = 0,
    lyric_line_roll: f32 = 1,
    lyric_line_prev: []const u8 = &.{},
    lyric_line_prev_scroll_dip: f32 = 0,
    status_sky: []const u16 = &.{},
    status_temperature: []const u16 = &.{},
    status_code: i32 = -1,
    status_strip_opacity: f32 = 0,
    notification_card_box: ?Geometry.RoundedBox = null,
    notification_card_reveal: f32 = 0,
    system_panel: ?*const TextRenderer.SystemPanelText = null,
    system_panel_box: ?Geometry.RoundedBox = null,
    system_panel_reveal: f32 = 0,
    tray_page_open: bool = false,
    tray_page_title: ?[*:0]const u16 = null,
    tray_page_icons: []const TextRenderer.TrayIcon = &.{},
    tray_page_revision: u64 = 0,
    tray_page_hovered_index: i32 = -1,
    tray_menu_open: bool = false,
    tray_menu_rows: [max_tray_menu_entries]Geometry.RectF = @splat(.{}),
    tray_menu_row_count: usize = 0,
    tray_menu_hovered: i32 = -1,
    tray_menu_labels: [max_tray_menu_entries]?[*:0]const u16 = @splat(null),
    start_page: ?*const TextRenderer.StartCardText = null,
    start_page_box: ?Geometry.RoundedBox = null,
    start_page_reveal: f32 = 0,
    sound_page: ?*const TextRenderer.SoundPageText = null,
    sound_page_box: ?Geometry.RoundedBox = null,
    sound_page_reveal: f32 = 0,
};
pub const ContentStrengths = struct { bar: f32 = 1, card: f32 = 1 };
pub const FrameState = struct {
    pill: PillAppearance = .{},
    resting_pill: Geometry.RoundedBox = .{ .rect = .{} },
    outer_card_up: bool = false,
    fullscreen_app: bool = false,
    card_owner: CardOwner = .none,
    state: Motion.IslandState = .collapsed,
    resting_state: Motion.IslandState = .collapsed,
    clock: TextRenderer.ClockStyle = .compact,
    status_sky: ?[*:0]const u16 = null,
    status_code: i32 = -1,
    status_temperature: ?[*:0]const u16 = null,
    status_strip_opacity: f32 = 0,
    content_opacity: f32 = 1,
    card_opacity: f32 = 1,
    lyric_line_roll: f32 = 1,
    lyric_line_prev: ?[*:0]const u8 = null,
    lyric_line_prev_scroll_dip: f32 = 0,
    music_level: f32 = 0,
    music_level_known: bool = false,
    music_wave_phase: f32 = 0,
    music_accent: [4]f32 = .{ 0.40, 0.80, 0.95, 1 },
    notification: ?*const Notification.Notification = null,
    notification_icon_pixels: ?[]const u8 = null,
    notification_icon_width: i32 = 0,
    notification_icon_height: i32 = 0,
    notification_icon_revision: u64 = 0,
    music: ?*const MusicSession.MusicInfo = null,
    transport_glyph: ?[*:0]const u8 = null,
    progress_fraction: f32 = 0,
    music_position_ms: i64 = 0,
    music_duration_ms: i64 = 0,
    artwork_pixels: ?[]const u8 = null,
    artwork_width: i32 = 0,
    artwork_height: i32 = 0,
    background_pixels: ?[]const u8 = null,
    background_width: i32 = 0,
    background_height: i32 = 0,
    artwork_revision: u64 = 0,
    background_revision: u64 = 0,
    task_buttons: [max_task_buttons]TextRenderer.TaskButton = @splat(.{}),
    task_button_count: usize = 0,
    task_button_appear: [max_task_buttons]f32 = @splat(0),
    task_button_appear_valid: bool = false,
    task_hovered_index: i32 = -1,
    task_button_windows: [max_task_buttons]?*anyopaque = @splat(null),
    tray_icons: ?[]const TextRenderer.TrayIcon = null,
    tray_icon_count: usize = 0,
    tray_revision: u64 = 0,
    tray_hovered_index: i32 = -1,
    tray_button_hovered: bool = false,
    tray_button_wash: f32 = 0,
    tray_page_open: bool = false,
    tray_page_title: ?[*:0]const u16 = null,
    tray_menu_open: bool = false,
    tray_menu_rows: [max_tray_menu_entries]Geometry.RectF = @splat(.{}),
    tray_menu_row_count: usize = 0,
    tray_menu_hovered: i32 = -1,
    tray_menu_labels: [max_tray_menu_entries]?[*:0]const u16 = @splat(null),
    start_card: TextRenderer.StartCardText = .{},
    start_page_open: bool = false,
    start_hovered: bool = false,
    start_wash: f32 = 0,
    system_button_hovered: bool = false,
    system_button_wash: f32 = 0,
    system_button_open: bool = false,
    start_button_open: bool = false,
    system_panel_open: bool = false,
    system_panel: TextRenderer.SystemPanelText = .{},
    sound_page_open: bool = false,
    sound_page: TextRenderer.SoundPageText = .{},
    card_left_dip: f32 = 0,
    icon_pixels: ?[]const u8 = null,
    icon_width: i32 = 0,
    icon_height: i32 = 0,
    icon_revision: u64 = 0,
    lyric_line: ?[*:0]const u8 = null,
    fallback_line: ?[*:0]const u8 = null,
    notice_line: ?[*:0]const u8 = null,
    call_up: bool = false,
    call_strip: TextRenderer.CallStripText = .{},
    lyric_scroll_dip: f32 = 0,
};

/// The native device chain used by Renderer::CreateDeviceResources.
/// Swap-chain binding and draw submission are kept separate so each stage has
/// explicit COM ownership and can be rebuilt after a device loss.
pub const DeviceResources = struct {
    d3d_device: Handle = null,
    d3d_context: Handle = null,
    swap_chain: Handle = null,
    composition_device: Handle = null,
    composition_target: Handle = null,
    composition_visual: Handle = null,
    d2d_factory: Handle = null,
    d2d_device: Handle = null,
    d2d_context: Handle = null,
    effect_group: Handle = null,
    opacity_animation: Handle = null,
    opacity_animated: bool = false,
    wait_for_clock: ?WaitForClockFn = null,
    surface_width: UINT = 0,
    surface_height: UINT = 0,
    dpi: UINT = 96,
    scale: f32 = 1,
    visual_bound: bool = false,
    window_icons: [max_window_icons]WindowIcon = @splat(.{}),
    window_icon_count: usize = 0,

    pub fn createDeviceResources(self: *DeviceResources) bool {
        const feature_levels = [_]UINT{ 0xB100, 0xB000 }; // 11.1, 11.0
        var feature_level: UINT = 0;
        var hr = D3D11CreateDevice(
            null,
            d3d_driver_hardware,
            null,
            d3d_create_device_bgra_support,
            &feature_levels,
            feature_levels.len,
            d3d11_sdk_version,
            &self.d3d_device,
            &feature_level,
            &self.d3d_context,
        );
        if (!succeeded(hr)) {
            release(&self.d3d_context);
            release(&self.d3d_device);
            hr = D3D11CreateDevice(
                null,
                d3d_driver_warp,
                null,
                d3d_create_device_bgra_support,
                &feature_levels,
                feature_levels.len,
                d3d11_sdk_version,
                &self.d3d_device,
                &feature_level,
                &self.d3d_context,
            );
        }
        if (!succeeded(hr) or self.d3d_device == null) {
            self.shutdown();
            return false;
        }

        var dxgi_device = queryInterface(self.d3d_device, &iid_dxgi_device);
        if (dxgi_device == null) {
            self.shutdown();
            return false;
        }
        defer release(&dxgi_device);

        hr = DCompositionCreateDevice(dxgi_device, &iid_dcomp_device, &self.composition_device);
        if (!succeeded(hr) or self.composition_device == null) {
            self.shutdown();
            return false;
        }

        hr = D2D1CreateFactory(d2d_factory_type_single_threaded, &iid_d2d_factory3, null, &self.d2d_factory);
        if (!succeeded(hr) or self.d2d_factory == null) {
            self.shutdown();
            return false;
        }

        const create_d2d_device = comMethod(*const fn (*anyopaque, *anyopaque, *Handle) callconv(.winapi) HResult, self.d2d_factory.?, 17);
        hr = create_d2d_device(self.d2d_factory.?, dxgi_device.?, &self.d2d_device);
        if (!succeeded(hr) or self.d2d_device == null) {
            self.shutdown();
            return false;
        }

        const create_context = comMethod(*const fn (*anyopaque, UINT, *Handle) callconv(.winapi) HResult, self.d2d_device.?, 4);
        hr = create_context(self.d2d_device.?, d2d_device_context_options_none, &self.d2d_context);
        if (!succeeded(hr) or self.d2d_context == null) {
            self.shutdown();
            return false;
        }

        const set_dpi = comMethod(*const fn (*anyopaque, f32, f32) callconv(.winapi) void, self.d2d_context.?, 51);
        set_dpi(self.d2d_context.?, 96, 96);
        const set_antialias = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) void, self.d2d_context.?, 32);
        set_antialias(self.d2d_context.?, d2d_antialias_mode_per_primitive);
        const set_text_antialias = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) void, self.d2d_context.?, 34);
        set_text_antialias(self.d2d_context.?, d2d_text_antialias_mode_grayscale);

        const create_effect_group = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, self.composition_device.?, 23);
        hr = create_effect_group(self.composition_device.?, &self.effect_group);
        if (!succeeded(hr) or self.effect_group == null) {
            self.shutdown();
            return false;
        }
        if (GetModuleHandleW(&dcomp_dll_name)) |dcomp_module| {
            if (GetProcAddress(dcomp_module, "DCompositionWaitForCompositorClock")) |address| {
                self.wait_for_clock = @ptrCast(address);
            }
        }
        return true;
    }

    fn createSwapChain(self: *DeviceResources, width_px: UINT, height_px: UINT) bool {
        if (self.d3d_device == null or self.scale <= 0) return false;
        var dxgi_device = queryInterface(self.d3d_device, &iid_dxgi_device);
        if (dxgi_device == null) return false;
        defer release(&dxgi_device);

        var adapter: Handle = null;
        const get_adapter = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, dxgi_device.?, 7);
        if (!succeeded(get_adapter(dxgi_device.?, &adapter)) or adapter == null) return false;
        defer release(&adapter);

        var factory: Handle = null;
        const get_parent = comMethod(*const fn (*anyopaque, *const Guid, *Handle) callconv(.winapi) HResult, adapter.?, 6);
        if (!succeeded(get_parent(adapter.?, &iid_dxgi_factory2, &factory)) or factory == null) return false;
        defer release(&factory);

        const surface_width = @max(1, @as(i32, @intFromFloat(@round(@as(f32, @floatFromInt(width_px)) / self.scale))));
        const surface_height = @max(1, @as(i32, @intFromFloat(@round(@as(f32, @floatFromInt(height_px)) / self.scale))));
        const desc = SwapChainDesc1{
            .width = @intCast(surface_width),
            .height = @intCast(surface_height),
            .format = dxgi_format_b8g8r8a8_unorm,
            .stereo = 0,
            .sample_desc = .{ .count = 1, .quality = 0 },
            .buffer_usage = dxgi_usage_render_target_output,
            .buffer_count = 2,
            .scaling = dxgi_scaling_stretch,
            .swap_effect = dxgi_swap_effect_flip_sequential,
            .alpha_mode = dxgi_alpha_mode_premultiplied,
            .flags = 0,
        };
        const create_swap_chain = comMethod(*const fn (*anyopaque, *anyopaque, *const SwapChainDesc1, Handle, *Handle) callconv(.winapi) HResult, factory.?, 24);
        if (!succeeded(create_swap_chain(factory.?, self.d3d_device.?, &desc, null, &self.swap_chain)) or self.swap_chain == null) return false;
        self.surface_width = desc.width;
        self.surface_height = desc.height;
        return true;
    }

    pub fn bindToWindow(self: *DeviceResources, window: Handle, scale_arg: f32) bool {
        if (window == null or self.composition_device == null or self.swap_chain == null) return false;
        self.scale = if (scale_arg > 0) scale_arg else 1;
        self.dpi = @intFromFloat(@round(self.scale * 96));

        if (!self.visual_bound) {
            const create_visual = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, self.composition_device.?, 7);
            const visual_hr = create_visual(self.composition_device.?, &self.composition_visual);
            if (!succeeded(visual_hr) or self.composition_visual == null) return false;
            const set_content = comMethod(*const fn (*anyopaque, *anyopaque) callconv(.winapi) HResult, self.composition_visual.?, 15);
            const content_hr = set_content(self.composition_visual.?, self.swap_chain.?);
            if (!succeeded(content_hr)) return false;
            const set_effect = comMethod(*const fn (*anyopaque, *anyopaque) callconv(.winapi) HResult, self.composition_visual.?, 10);
            const effect_hr = set_effect(self.composition_visual.?, self.effect_group.?);
            if (!succeeded(effect_hr)) return false;

            const create_target = comMethod(*const fn (*anyopaque, Handle, i32, *Handle) callconv(.winapi) HResult, self.composition_device.?, 6);
            const target_hr = create_target(self.composition_device.?, window, 1, &self.composition_target);
            if (!succeeded(target_hr) or self.composition_target == null) return false;
            const set_root = comMethod(*const fn (*anyopaque, *anyopaque) callconv(.winapi) HResult, self.composition_target.?, 3);
            const root_hr = set_root(self.composition_target.?, self.composition_visual.?);
            if (!succeeded(root_hr)) return false;
            self.visual_bound = true;
        }

        const transform = Matrix3x2{ .m11 = self.scale, .m12 = 0, .m21 = 0, .m22 = self.scale, .m31 = 0, .m32 = 0 };
        const set_transform = comMethod(*const fn (*anyopaque, *const Matrix3x2) callconv(.winapi) HResult, self.composition_visual.?, 8);
        const transform_hr = set_transform(self.composition_visual.?, &transform);
        if (!succeeded(transform_hr)) return false;
        const commit = comMethod(*const fn (*anyopaque) callconv(.winapi) HResult, self.composition_device.?, 3);
        const commit_hr = commit(self.composition_device.?);
        return succeeded(commit_hr);
    }

    /// Presents one cleared composition frame containing the island's rounded
    /// surface. The back-buffer wrapper is released before Present, as required
    /// by DXGI's flip model and the original C++ renderer.
    pub fn renderPill(self: *DeviceResources, pill: PillAppearance, text_renderer: ?*TextRenderer.TextRenderer, clock_style: TextRenderer.ClockStyle, weather_reading: Weather.Reading) bool {
        last_render_pill_failure = "";
        last_render_pill_hresult = 0;
        if (!self.isReady() or !self.visual_bound) return false;

        var surface: Handle = null;
        const get_buffer = comMethod(*const fn (*anyopaque, UINT, *const Guid, *Handle) callconv(.winapi) HResult, self.swap_chain.?, 9);
        const surface_hr = get_buffer(self.swap_chain.?, 0, &iid_dxgi_surface, &surface);
        if (!succeeded(surface_hr) or surface == null) return false;
        defer release(&surface);

        const properties = BitmapProperties1{
            .pixel_format = .{ .format = dxgi_format_b8g8r8a8_unorm, .alpha_mode = d2d_alpha_mode_premultiplied },
            .dpi_x = 96,
            .dpi_y = 96,
            .options = d2d_bitmap_option_target | d2d_bitmap_option_cannot_draw,
            .color_context = null,
        };
        var target: Handle = null;
        const create_target = comMethod(*const fn (*anyopaque, *anyopaque, *const BitmapProperties1, *Handle) callconv(.winapi) HResult, self.d2d_context.?, 62);
        const bitmap_hr = create_target(self.d2d_context.?, surface.?, &properties, &target);
        if (!succeeded(bitmap_hr) or target == null) return false;
        defer release(&target);

        const set_target = comMethod(*const fn (*anyopaque, Handle) callconv(.winapi) void, self.d2d_context.?, 74);
        set_target(self.d2d_context.?, target);
        var target_attached = true;
        defer if (target_attached) set_target(self.d2d_context.?, null);

        if (!self.opacity_animated) {
            const effect_opacity = comMethod(*const fn (*anyopaque, f32) callconv(.winapi) HResult, self.effect_group.?, 4);
            const opacity_hr = effect_opacity(self.effect_group.?, pill.opacity);
            if (!succeeded(opacity_hr)) return false;
        }

        var fallback_brush: Handle = null;
        if (text_renderer == null) {
            const color = D2DColor{ .r = pill.fill[0], .g = pill.fill[1], .b = pill.fill[2], .a = pill.fill[3] };
            const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, self.d2d_context.?, 8);
            if (!succeeded(create_brush(self.d2d_context.?, &color, null, &fallback_brush)) or fallback_brush == null) return false;
        }
        defer release(&fallback_brush);

        const begin_draw = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 48);
        begin_draw(self.d2d_context.?);
        const clear = comMethod(*const fn (*anyopaque, *const D2DColor) callconv(.winapi) void, self.d2d_context.?, 47);
        const transparent = D2DColor{ .r = 0, .g = 0, .b = 0, .a = 0 };
        clear(self.d2d_context.?, &transparent);

        const surface_box = pill.surface_box orelse pill.box;
        const rect = surface_box.rect;
        if (pill.opacity > 0.001 and rect.right > rect.left and rect.bottom > rect.top) {
            if (text_renderer) |text| {
                text.drawPillSurface(self.d2d_context, surface_box, pill.deck_box, pill.opacity);
            } else if (fallback_brush) |brush| {
                const rounded = D2DRoundedRect{
                    .rect = .{ .left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom },
                    .radius_x = @max(0, surface_box.radius_x),
                    .radius_y = @max(0, surface_box.radius_y),
                };
                const fill_rounded = comMethod(*const fn (*anyopaque, *const D2DRoundedRect, *anyopaque) callconv(.winapi) void, self.d2d_context.?, 19);
                fill_rounded(self.d2d_context.?, &rounded, brush);
            }
        }
        if (pill.opacity > 0.001) {
            if (text_renderer) |text| {
                if (pill.call_up) {
                    text.drawCallStrip(self.d2d_context, pill.box, pill.call_strip, pill.opacity);
                } else if (pill.music_card) |music_card| {
                    if (!text.drawMusicCard(self.d2d_context, pill.box, music_card, pill.opacity)) {
                        last_render_pill_failure = "music card renderer";
                        return false;
                    }
                } else if (pill.music_text.len != 0) {
                    if (pill.notification != null) {
                        if (!text.drawInlineText(self.d2d_context, pill.box, pill.music_text, pill.opacity)) return false;
                    } else if (!text.drawTrackLine(self.d2d_context, pill.box, pill.music_text, pill.lyric_scroll_dip, pill.opacity, pill.lyric_line_roll, pill.lyric_line_prev, pill.lyric_line_prev_scroll_dip)) return false;
                } else if (clock_style == .compact) {
                    var sky: [24]u16 = @splat(0);
                    var temperature: [16]u16 = @splat(0);
                    var weather_code: i32 = -1;
                    if (weather_reading.valid) {
                        weather_code = weather_reading.weather_code;
                        Weather.weatherPiecesFor(weather_reading.temperature_c, weather_code, &sky, &temperature);
                    }
                    if (!text.drawStatusLine(self.d2d_context, pill.box, pill.opacity, wideZSlice(&sky), wideZSlice(&temperature), weather_code)) return false;
                } else if (!text.drawClock(self.d2d_context, pill.box, clock_style, pill.opacity)) return false;
            }
        }

        if (pill.opacity > 0.001 and pill.music_present and pill.resting_state == .music_strip and pill.notification == null and !pill.call_up) {
            if (text_renderer) |text| {
                const line_box = if (Geometry.width(pill.resting_pill.rect) > 0) pill.resting_pill else pill.box;
                if (pill.music_level_known) text.drawAudioWave(self.d2d_context, line_box, pill.music_wave_phase, pill.music_level, pill.music_accent, pill.opacity);
                if (pill.music_text.len != 0) _ = text.drawTrackLine(self.d2d_context, line_box, pill.music_text, pill.lyric_scroll_dip, pill.opacity, pill.lyric_line_roll, pill.lyric_line_prev, pill.lyric_line_prev_scroll_dip);
            }
        }

        if (pill.opacity > 0.001 and pill.status_strip_opacity > 0.01 and !pill.fullscreen_app) {
            if (text_renderer) |text| {
                const bar_island = if (Geometry.width(pill.resting_pill.rect) > 0)
                    Motion.rowAnchorBox(pill.box, pill.resting_pill)
                else
                    pill.box;
                var strip = TaskStripLayout.statusStripFor(bar_island);
                const slide = (1 - pill.status_strip_opacity) * 6;
                strip.rect.left += slide;
                strip.rect.right += slide;
                text.drawPillSurface(self.d2d_context, strip, strip, pill.status_strip_opacity * pill.opacity);
                if (!text.drawStatusLine(self.d2d_context, strip, pill.status_strip_opacity * pill.opacity, pill.status_sky, pill.status_temperature, pill.status_code)) return false;
            }
        }

        if (pill.opacity > 0.001 and (pill.card_notification != null or pill.notification != null) and pill.notification_card_box != null and pill.notification_card_reveal > 0.5) {
            if (text_renderer) |text| {
                const notification = pill.card_notification orelse pill.notification.?;
                const card = pill.notification_card_box.?;
                const revealed_bottom = @min(card.rect.bottom, card.rect.top + pill.notification_card_reveal);
                const clip = D2DRectF{ .left = card.rect.left, .top = card.rect.top, .right = card.rect.right, .bottom = revealed_bottom };
                const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, self.d2d_context.?, 45);
                const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 46);
                push_clip(self.d2d_context.?, &clip, 0);
                const drawn = text.drawNotification(
                    self.d2d_context,
                    card,
                    std.mem.sliceTo(&notification.app, 0),
                    std.mem.sliceTo(&notification.title, 0),
                    std.mem.sliceTo(&notification.body, 0),
                    pill.notification_icon_pixels,
                    pill.notification_icon_width,
                    pill.notification_icon_height,
                    pill.notification_icon_revision,
                    pill.opacity,
                );
                pop_clip(self.d2d_context.?);
                if (!drawn) return false;
            }
        }

        if (pill.opacity > 0.001 and pill.system_panel != null and pill.system_panel_box != null and pill.system_panel_reveal > 0.5) {
            if (text_renderer) |text| {
                const card = pill.system_panel_box.?;
                const revealed_bottom = @min(card.rect.bottom, card.rect.top + pill.system_panel_reveal);
                const clip = D2DRectF{ .left = card.rect.left, .top = card.rect.top, .right = card.rect.right, .bottom = revealed_bottom };
                const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, self.d2d_context.?, 45);
                const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 46);
                push_clip(self.d2d_context.?, &clip, 0);
                const drawn = text.drawSystemPanel(self.d2d_context, card, pill.system_panel.?, pill.opacity);
                pop_clip(self.d2d_context.?);
                if (!drawn) return false;
            }
        }

        if (pill.opacity > 0.001 and pill.sound_page != null and pill.sound_page_box != null and pill.sound_page_reveal > 0.5) {
            if (text_renderer) |text| {
                const card = pill.sound_page_box.?;
                const revealed_bottom = @min(card.rect.bottom, card.rect.top + pill.sound_page_reveal);
                const clip = D2DRectF{ .left = card.rect.left, .top = card.rect.top, .right = card.rect.right, .bottom = revealed_bottom };
                const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, self.d2d_context.?, 45);
                const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 46);
                push_clip(self.d2d_context.?, &clip, 0);
                const drawn = text.drawSoundPage(self.d2d_context, card, pill.sound_page.?, pill.opacity);
                pop_clip(self.d2d_context.?);
                if (!drawn) return false;
            }
        }

        if (pill.opacity > 0.001 and pill.tray_page_open and pill.system_panel_box != null and pill.system_panel_reveal > 0.5 and !pill.fullscreen_app) {
            if (text_renderer) |text| {
                const card = pill.system_panel_box.?;
                const revealed_bottom = @min(card.rect.bottom, card.rect.top + pill.system_panel_reveal);
                const clip = D2DRectF{ .left = card.rect.left, .top = card.rect.top, .right = card.rect.right, .bottom = revealed_bottom };
                const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, self.d2d_context.?, 45);
                const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 46);
                push_clip(self.d2d_context.?, &clip, 0);
                const drawn = text.drawTrayPage(self.d2d_context, card, pill.tray_page_title, pill.tray_page_icons, pill.tray_page_revision, pill.tray_page_hovered_index, pill.opacity);
                pop_clip(self.d2d_context.?);
                if (!drawn) return false;
            }
        }

        if (pill.opacity > 0.001 and pill.tray_menu_open) {
            if (text_renderer) |text| {
                const count = @min(pill.tray_menu_row_count, max_tray_menu_entries);
                text.drawTrayMenu(
                    self.d2d_context,
                    pill.tray_menu_rows[0..count],
                    pill.tray_menu_labels[0..count],
                    pill.tray_menu_hovered,
                    pill.opacity,
                );
            }
        }

        if (pill.opacity > 0.001 and pill.start_page != null and pill.start_page_box != null and pill.start_page_reveal > 0.5) {
            if (text_renderer) |text| {
                const card = pill.start_page_box.?;
                const revealed_bottom = @min(card.rect.bottom, card.rect.top + pill.start_page_reveal);
                const clip = D2DRectF{ .left = card.rect.left, .top = card.rect.top, .right = card.rect.right, .bottom = revealed_bottom };
                const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, self.d2d_context.?, 45);
                const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, self.d2d_context.?, 46);
                push_clip(self.d2d_context.?, &clip, 0);
                const drawn = text.drawStartPage(self.d2d_context, card, pill.start_page.?, pill.opacity);
                pop_clip(self.d2d_context.?);
                if (!drawn) return false;
            }
        }

        // The task row is drawn after the expanded card so its buttons stay
        // visible where the card overlaps the desktop strip, matching the
        // original Renderer::DrawDecks order.
        if (pill.opacity > 0.001 and pill.task_buttons.len != 0 and !pill.fullscreen_app) {
            if (text_renderer) |text| {
                var resolved_buttons: [max_task_buttons]TextRenderer.TaskButton = @splat(.{});
                const count = @min(pill.task_buttons.len, resolved_buttons.len);
                @memcpy(resolved_buttons[0..count], pill.task_buttons[0..count]);
                for (resolved_buttons[0..count]) |*button| {
                    button.icon = self.iconForWindow(button.window);
                }
                if (!text.drawTaskIcons(
                    self.d2d_context,
                    pill.task_island,
                    resolved_buttons[0..count],
                    pill.task_hovered_index,
                    pill.opacity,
                    pill.task_button_appear,
                    pill.task_card_left_dip,
                    pill.task_card_width_dip,
                )) return false;
            }
        }

        // The two left controls and the tray button hang from the pill. They are
        // drawn from the same anchor used by hit testing so their targets stay
        // under their visible marks in every island state.
        if (pill.opacity > 0.001 and !pill.fullscreen_app) {
            if (text_renderer) |text| {
                const deck = pill.deck_box orelse pill.box;
                text.drawStartButton(self.d2d_context, deck, pill.start_hover, pill.start_open, pill.opacity);
                text.drawSystemButton(self.d2d_context, deck, pill.system_hover, pill.system_open, pill.opacity);
                if (pill.tray_visible) text.drawTrayButton(self.d2d_context, deck, pill.tray_hover, pill.tray_open, pill.opacity);
            }
        }

        const end_draw = comMethod(*const fn (*anyopaque, ?*u64, ?*u64) callconv(.winapi) HResult, self.d2d_context.?, 49);
        const draw_hr = end_draw(self.d2d_context.?, null, null);
        set_target(self.d2d_context.?, null);
        target_attached = false;
        if (!succeeded(draw_hr)) {
            last_render_pill_failure = "D2D EndDraw";
            last_render_pill_hresult = draw_hr;
            return false;
        }

        const present = comMethod(*const fn (*anyopaque, UINT, UINT) callconv(.winapi) HResult, self.swap_chain.?, 8);
        const present_hr = present(self.swap_chain.?, 1, 0);
        if (!succeeded(present_hr)) {
            last_render_pill_failure = "DXGI Present";
            last_render_pill_hresult = present_hr;
            return false;
        }
        const commit = comMethod(*const fn (*anyopaque) callconv(.winapi) HResult, self.composition_device.?, 3);
        const commit_hr = commit(self.composition_device.?);
        if (!succeeded(commit_hr)) {
            last_render_pill_failure = "DirectComposition Commit";
            last_render_pill_hresult = commit_hr;
        }
        return succeeded(commit_hr);
    }

    /// Reads two pixels from the most recently presented composition buffer.
    /// Coordinates are expressed in DIPs, matching the C++ renderer contract.
    /// DXGI's back buffer is not CPU-readable, so this copies it into a staging
    /// texture and maps that texture for the duration of the read.
    pub fn readBackFrame(
        self: *DeviceResources,
        inside_x_dip: f32,
        inside_y_dip: f32,
        outside_x_dip: f32,
        outside_y_dip: f32,
        inside_alpha: ?*u8,
        outside_alpha: ?*u8,
        inside_rgb: ?*[3]u8,
    ) ReadbackError!void {
        var frame = try self.mapBackBuffer();
        defer frame.deinit();

        const inside = try self.pixelPoint(inside_x_dip, inside_y_dip);
        const outside = try self.pixelPoint(outside_x_dip, outside_y_dip);
        samplePixel(&frame, inside, inside_alpha, inside_rgb);
        samplePixel(&frame, outside, outside_alpha, null);
    }

    /// Calculates alpha-weighted Rec. 601 luminance for a DIP-space rectangle.
    /// Transparent pixels do not contribute, so the desktop behind the island
    /// cannot change the measurement.
    pub fn regionLuminance(self: *DeviceResources, rect: Geometry.RectF) ReadbackError!f32 {
        const left = try pixelCoordinate(rect.left, self.scale);
        const top = try pixelCoordinate(rect.top, self.scale);
        const right = try pixelCoordinate(rect.right, self.scale);
        const bottom = try pixelCoordinate(rect.bottom, self.scale);
        if (left < 0 or top < 0 or right > self.surface_width or bottom > self.surface_height or right <= left or bottom <= top)
            return error.InvalidRegion;

        var frame = try self.mapBackBuffer();
        defer frame.deinit();
        var weighted_luma: f64 = 0;
        var alpha_weight: f64 = 0;
        var y = top;
        while (y < bottom) : (y += 1) {
            var x = left;
            while (x < right) : (x += 1) {
                const pixel = mappedPixel(&frame, .{ .x = @intCast(x), .y = @intCast(y) });
                const alpha = @as(f64, @floatFromInt(pixel[3])) / 255.0;
                const luma = 0.114 * @as(f64, @floatFromInt(pixel[0])) +
                    0.587 * @as(f64, @floatFromInt(pixel[1])) +
                    0.299 * @as(f64, @floatFromInt(pixel[2]));
                weighted_luma += luma * alpha;
                alpha_weight += alpha;
            }
        }
        return if (alpha_weight > 0) @floatCast(weighted_luma / alpha_weight) else 0;
    }

    /// Returns a compact ASCII alpha map of a DIP-space rectangle. `#` denotes
    /// nearly opaque glyph pixels, spaces are transparent pixels, and the other
    /// marks distinguish the translucent pill fill from bright text.
    pub fn describeRegionAlpha(
        self: *DeviceResources,
        rect: Geometry.RectF,
        columns: usize,
        rows: usize,
        output: []u8,
    ) ReadbackError![]const u8 {
        if (columns == 0 or rows == 0 or output.len == 0) return output[0..0];
        if (columns > std.math.maxInt(i32) or rows > std.math.maxInt(i32)) return error.InvalidRegion;

        const left = try pixelCoordinate(rect.left, self.scale);
        const top = try pixelCoordinate(rect.top, self.scale);
        const right = try pixelCoordinate(rect.right, self.scale);
        const bottom = try pixelCoordinate(rect.bottom, self.scale);
        if (right <= left or bottom <= top) return error.InvalidRegion;

        var frame = try self.mapBackBuffer();
        defer frame.deinit();
        const width: i64 = @as(i64, right) - left;
        const height: i64 = @as(i64, bottom) - top;
        const column_count: i64 = @intCast(columns);
        const row_count: i64 = @intCast(rows);
        var used: usize = 0;
        for (0..rows) |row| {
            for (0..columns) |column| {
                if (used >= output.len) return output[0..used];
                const x = @as(i64, left) + @divTrunc(width * @as(i64, @intCast(column)), column_count) + @divTrunc(width, column_count * 2);
                const y = @as(i64, top) + @divTrunc(height * @as(i64, @intCast(row)), row_count) + @divTrunc(height, row_count * 2);
                const alpha = if (x >= 0 and y >= 0 and x < self.surface_width and y < self.surface_height)
                    mappedPixel(&frame, .{ .x = @intCast(x), .y = @intCast(y) })[3]
                else
                    0;
                output[used] = if (alpha < 10) ' ' else if (alpha > 245) '#' else if (alpha > 240) '+' else if (alpha > 236) '-' else '.';
                used += 1;
            }
            if (used < output.len) {
                output[used] = '\n';
                used += 1;
            }
        }
        return output[0..used];
    }

    fn mapBackBuffer(self: *DeviceResources) ReadbackError!MappedFrame {
        const device = self.d3d_device orelse return error.RendererNotInitialized;
        const context = self.d3d_context orelse return error.RendererNotInitialized;
        const swap_chain = self.swap_chain orelse return error.RendererNotInitialized;
        if (self.surface_width == 0 or self.surface_height == 0 or self.scale <= 0) return error.RendererNotInitialized;

        var surface: Handle = null;
        const get_buffer = comMethod(*const fn (*anyopaque, UINT, *const Guid, *Handle) callconv(.winapi) HResult, swap_chain, 9);
        const surface_hr = get_buffer(swap_chain, 0, &iid_dxgi_surface, &surface);
        if (!succeeded(surface_hr) or surface == null) {
            release(&surface);
            return error.SwapChainBufferUnavailable;
        }
        var resource: Handle = queryInterface(surface, &iid_d3d11_resource) orelse {
            release(&surface);
            return error.ResourceUnavailable;
        };
        release(&surface);

        const desc = D3D11Texture2DDesc{
            .width = self.surface_width,
            .height = self.surface_height,
            .mip_levels = 1,
            .array_size = 1,
            .format = dxgi_format_b8g8r8a8_unorm,
            .sample_desc = .{ .count = 1, .quality = 0 },
            .usage = d3d11_usage_staging,
            .bind_flags = 0,
            .cpu_access_flags = d3d11_cpu_access_read,
            .misc_flags = 0,
        };
        var staging: Handle = null;
        const create_texture = comMethod(*const fn (*anyopaque, *const D3D11Texture2DDesc, ?*const anyopaque, *Handle) callconv(.winapi) HResult, device, 5);
        const create_hr = create_texture(device, &desc, null, &staging);
        if (!succeeded(create_hr) or staging == null) {
            release(&staging);
            release(&resource);
            return error.StagingTextureUnavailable;
        }

        const copy_resource = comMethod(*const fn (*anyopaque, *anyopaque, *anyopaque) callconv(.winapi) void, context, 47);
        copy_resource(context, staging.?, resource.?);
        const flush = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 111);
        flush(context);

        var mapped = D3D11MappedSubresource{ .data = null, .row_pitch = 0, .depth_pitch = 0 };
        const map = comMethod(*const fn (*anyopaque, *anyopaque, UINT, i32, UINT, *D3D11MappedSubresource) callconv(.winapi) HResult, context, 14);
        const map_hr = map(context, staging.?, 0, d3d11_map_read, 0, &mapped);
        if (!succeeded(map_hr) or mapped.data == null) {
            if (succeeded(map_hr)) {
                const unmap = comMethod(*const fn (*anyopaque, *anyopaque, UINT) callconv(.winapi) void, context, 15);
                unmap(context, staging.?, 0);
            }
            release(&staging);
            release(&resource);
            return error.MapFailed;
        }
        return .{ .context = context, .staging = staging, .resource = resource, .mapped = mapped };
    }

    fn pixelPoint(self: *const DeviceResources, x_dip: f32, y_dip: f32) ReadbackError!PixelPoint {
        const x = try pixelCoordinate(x_dip, self.scale);
        const y = try pixelCoordinate(y_dip, self.scale);
        if (x < 0 or y < 0 or x >= self.surface_width or y >= self.surface_height) return error.SampleOutOfBounds;
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }

    fn createIconBitmap(self: *DeviceResources, width: u32, height: u32, pixels: [*]const u8) Handle {
        const context = self.d2d_context orelse return null;
        if (width == 0 or height == 0 or width > std.math.maxInt(u32) / 4) return null;
        const size = D2DSizeU{ .width = width, .height = height };
        const properties = BitmapProperties1{
            .pixel_format = .{ .format = dxgi_format_b8g8r8a8_unorm, .alpha_mode = d2d_alpha_mode_premultiplied },
            .dpi_x = 96,
            .dpi_y = 96,
            .options = 0,
            .color_context = null,
        };
        var bitmap: Handle = null;
        const create = comMethod(*const fn (*anyopaque, D2DSizeU, ?[*]const u8, UINT, *const BitmapProperties1, *Handle) callconv(.winapi) HResult, context, 4);
        const stride = width * 4;
        if (!succeeded(create(context, size, pixels, stride, &properties, &bitmap))) return null;
        return bitmap;
    }

    fn iconForWindow(self: *DeviceResources, window_arg: Handle) Handle {
        const window = window_arg orelse return null;
        for (self.window_icons[0..self.window_icon_count]) |slot| {
            if (slot.window == window) return slot.bitmap;
        }
        if (IsWindow(window) == 0 or self.window_icon_count >= self.window_icons.len) return null;

        const slot_index = self.window_icon_count;
        self.window_icons[slot_index] = .{ .window = window, .bitmap = null };
        self.window_icon_count += 1;

        // Prefer the icon supplied by the window itself, then its class icon,
        // and finally the small window icon. This matches the C++ lookup order.
        var icon = windowIcon(window, icon_big);
        if (icon == null) {
            const class_icon = GetClassLongPtrW(window, gclp_hicon);
            if (class_icon != 0) icon = @ptrFromInt(class_icon);
        }
        if (icon == null) icon = windowIcon(window, icon_small);

        if (icon) |window_icon| {
            self.window_icons[slot_index].bitmap = self.bitmapFromWindowIcon(window_icon);
            return self.window_icons[slot_index].bitmap;
        }

        // Protected processes may refuse WM_GETICON and process queries; when
        // the latter succeeds, use the executable's associated icon as the
        // same fallback as Renderer::IconForWindow.
        var process_id: u32 = 0;
        _ = GetWindowThreadProcessId(window, &process_id);
        if (process_id == 0) return null;
        const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
        defer _ = CloseHandle(process);
        var executable_path: [260]u16 = @splat(0);
        var path_length: u32 = executable_path.len;
        if (QueryFullProcessImageNameW(process, 0, &executable_path, &path_length) == 0 or path_length == 0 or path_length >= executable_path.len) return null;

        var png: [16 * 1024]u8 = undefined;
        const png_length = MusicSession.fetchAppIconForTest(executable_path[0..path_length], &png);
        if (png_length == 0) return null;
        var decoded = WicImage.DecodedImage{};
        if (!WicImage.decodeImage(png[0..png_length], &decoded, .other) or decoded.width <= 0 or decoded.height <= 0) return null;
        const pixels = decoded.pixels orelse return null;
        self.window_icons[slot_index].bitmap = self.createIconBitmap(@intCast(decoded.width), @intCast(decoded.height), pixels);
        return self.window_icons[slot_index].bitmap;
    }

    fn bitmapFromWindowIcon(self: *DeviceResources, icon: Handle) Handle {
        const screen = GetDC(null) orelse return null;
        defer _ = ReleaseDC(null, screen);
        const memory = CreateCompatibleDC(screen) orelse return null;
        defer _ = DeleteDC(memory);

        var header = std.mem.zeroes(BitmapV5Header);
        header.size = @sizeOf(BitmapV5Header);
        header.width = 32;
        header.height = -32;
        header.planes = 1;
        header.bit_count = 32;
        header.compression = bi_bitfields;
        header.red_mask = 0x00ff0000;
        header.green_mask = 0x0000ff00;
        header.blue_mask = 0x000000ff;
        header.alpha_mask = 0xff000000;

        var bits: Handle = null;
        const dib = CreateDIBSection(memory, &header, dib_rgb_colors, &bits, null, 0) orelse return null;
        defer _ = DeleteObject(dib);
        const previous = SelectObject(memory, dib) orelse return null;
        _ = DrawIconEx(memory, 0, 0, icon, 32, 32, 0, null, di_normal);
        _ = GdiFlush();
        _ = SelectObject(memory, previous);
        const pixel_memory = bits orelse return null;
        const pixels: [*]const u8 = @ptrCast(pixel_memory);
        return self.createIconBitmap(32, 32, pixels);
    }

    pub fn initialize(self: *DeviceResources, window: Handle, width_px: UINT, height_px: UINT, scale_arg: f32) bool {
        self.shutdown();
        self.scale = if (scale_arg > 0) scale_arg else 1;
        self.dpi = @intFromFloat(@round(self.scale * 96));
        if (!self.createDeviceResources() or !self.createSwapChain(width_px, height_px) or !self.bindToWindow(window, self.scale)) {
            self.shutdown();
            return false;
        }
        return true;
    }

    pub fn isReady(self: *const DeviceResources) bool {
        return self.d3d_device != null and self.d3d_context != null and self.swap_chain != null and
            self.composition_device != null and self.d2d_factory != null and
            self.composition_target != null and self.composition_visual != null and
            self.d2d_device != null and self.d2d_context != null and self.effect_group != null;
    }

    /// Starts a compositor-side linear opacity ramp, matching Renderer::AnimateOpacity.
    /// Once accepted, per-frame opacity writes are skipped until shutdown so they
    /// cannot overwrite the compositor animation.
    pub fn animateOpacity(self: *DeviceResources, from: f32, to: f32, seconds: f64) bool {
        if (self.composition_device == null or self.effect_group == null or seconds <= 0) return false;

        release(&self.opacity_animation);
        const create_animation = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, self.composition_device.?, 25);
        if (!succeeded(create_animation(self.composition_device.?, &self.opacity_animation)) or self.opacity_animation == null) return false;

        const slope = (to - from) / @as(f32, @floatCast(seconds));
        const add_cubic = comMethod(*const fn (*anyopaque, f64, f32, f32, f32, f32) callconv(.winapi) HResult, self.opacity_animation.?, 5);
        _ = add_cubic(self.opacity_animation.?, 0, from, slope, 0, 0);
        const end = comMethod(*const fn (*anyopaque, f64, f32) callconv(.winapi) HResult, self.opacity_animation.?, 8);
        _ = end(self.opacity_animation.?, seconds, to);

        const set_animation = comMethod(*const fn (*anyopaque, *anyopaque) callconv(.winapi) HResult, self.effect_group.?, 3);
        if (!succeeded(set_animation(self.effect_group.?, self.opacity_animation.?))) {
            release(&self.opacity_animation);
            return false;
        }
        self.opacity_animated = true;

        const commit = comMethod(*const fn (*anyopaque) callconv(.winapi) HResult, self.composition_device.?, 3);
        if (!succeeded(commit(self.composition_device.?))) {
            self.opacity_animated = false;
            release(&self.opacity_animation);
            return false;
        }
        return true;
    }

    /// Waits for one DirectComposition presentation tick when the OS exports the
    /// optional API. Returns false on old Windows versions, timeout, or failure.
    pub fn waitForCompositorClock(self: *const DeviceResources, timeout_ms: UINT) bool {
        const wait = self.wait_for_clock orelse return false;
        const result = wait(0, null, timeout_ms);
        return result != wait_timeout and result != wait_failed;
    }

    pub fn shutdown(self: *DeviceResources) void {
        for (self.window_icons[0..self.window_icon_count]) |*slot| release(&slot.bitmap);
        self.window_icons = @splat(.{});
        self.window_icon_count = 0;
        release(&self.opacity_animation);
        self.opacity_animated = false;
        release(&self.composition_target);
        release(&self.composition_visual);
        release(&self.effect_group);
        release(&self.composition_device);
        release(&self.d2d_context);
        release(&self.d2d_device);
        release(&self.d2d_factory);
        release(&self.swap_chain);
        release(&self.d3d_context);
        release(&self.d3d_device);
        self.surface_width = 0;
        self.surface_height = 0;
        self.dpi = 96;
        self.scale = 1;
        self.visual_bound = false;
        self.wait_for_clock = null;
    }
};

pub const card_content_lead_fraction: f32 = 0.35;

/// The stage that failed in the most recent native rendering self-check.
/// Callers can report it without hiding which part of the GPU path failed.
pub var last_native_check_failure: []const u8 = "";
pub var last_background_luminance_with: f32 = 0;
pub var last_background_luminance_without: f32 = 0;
pub var last_background_png_length: usize = 0;
pub var last_native_check_hresult: HResult = 0;
pub var last_render_pill_failure: []const u8 = "";
pub var last_render_pill_hresult: HResult = 0;

/// Exercises the full device + swap-chain + composition binding path against an
/// existing HWND. The caller owns the window and must keep it alive until this
/// function returns.
pub fn nativeWindowCheck(window: Handle, width_px: UINT, height_px: UINT, scale: f32, text_renderer: ?*TextRenderer.TextRenderer, clock_style: TextRenderer.ClockStyle) bool {
    var check_stage: []const u8 = "device initialization";
    var check_passed = false;
    last_native_check_hresult = 0;
    defer if (!check_passed) {
        last_native_check_failure = check_stage;
    };
    var resources = DeviceResources{};
    if (!resources.initialize(window, width_px, height_px, scale)) return false;
    defer resources.shutdown();
    const height: f32 = @floatFromInt(height_px);
    const pill = PillAppearance{
        .box = .{ .rect = .{ .left = 0, .top = 0, .right = @floatFromInt(width_px), .bottom = height }, .radius_x = height / 2, .radius_y = height / 2 },
    };
    check_stage = "device readiness";
    if (!resources.isReady()) return false;
    if (clock_style != .compact) {
        check_stage = "initial card frame";
        if (!resources.renderPill(pill, text_renderer, clock_style, .{ .temperature_c = 0, .weather_code = -1 })) return false;
        if (!resources.renderPill(pill, text_renderer, clock_style, .{ .temperature_c = 0, .weather_code = -1 })) return false;
        check_stage = "initial card readback";
        if (!verifySurfaceReadback(&resources)) return false;
        if (text_renderer) |text| {
            var artwork_pixels: [64 * 32 * 4]u8 = undefined;
            for (0..32) |y| {
                for (0..64) |x| {
                    const offset = (y * 64 + x) * 4;
                    const warm = ((x / 8 + y / 8) % 2) == 0;
                    artwork_pixels[offset + 0] = if (warm) 24 else 210;
                    artwork_pixels[offset + 1] = if (warm) 96 else 48;
                    artwork_pixels[offset + 2] = if (warm) 228 else 32;
                    artwork_pixels[offset + 3] = 255;
                }
            }
            var artwork_png: [64 * 32 * 4 + 2048]u8 = undefined;
            const artwork_png_len = WicImage.encodeBgraToPng(&artwork_pixels, 64, 32, &artwork_png);
            var background_png: [32 * 1024]u8 = undefined;
            const background_png_len = if (artwork_png_len > 0)
                WicImage.makeBlurredBackgroundPng(artwork_png[0..artwork_png_len], 105, 59, &background_png)
            else
                0;
            var music_card = TextRenderer.MusicCardText{
                .title = "Zig migration rendering test",
                .artist = "IslandBar",
                .album = "Direct2D readback",
                .app = "Media session",
                .playing = true,
                .position_ms = 42_000,
                .duration_ms = 191_000,
                .progress_fraction = 0.22,
                .artwork_png = if (artwork_png_len > 0) artwork_png[0..artwork_png_len] else &.{},
                .artwork_revision = 1,
                .background_png = if (background_png_len > 0) background_png[0..background_png_len] else &.{},
                .background_revision = if (background_png_len > 0) 1 else 0,
            };
            var card_pill = pill;
            card_pill.music_card = &music_card;
            last_background_png_length = background_png_len;
            check_stage = "card artwork rendering";
            if (!resources.renderPill(card_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) {
                check_stage = if (last_render_pill_failure.len > 0) last_render_pill_failure else "card frame rendering";
                last_native_check_hresult = last_render_pill_hresult;
                return false;
            }
            if (text.music_background_cache.bitmap == null) {
                check_stage = if (text.last_png_bitmap_failure.len > 0)
                    text.last_png_bitmap_failure
                else
                    "background bitmap unavailable";
                last_native_check_hresult = text.last_png_bitmap_hresult;
                return false;
            }
            if (!resources.renderPill(card_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;
            check_stage = "card artwork readback";
            if (!verifySurfaceReadback(&resources)) return false;
            check_stage = "rounded card clipping";
            var rounded_corner_alpha: u8 = 255;
            resources.readBackFrame(2, 2, 8, 8, &rounded_corner_alpha, null, null) catch return false;
            if (rounded_corner_alpha != 0) return false;

            // Read back the same complete card with and without the WIC-produced
            // background. A successful decode alone does not prove Direct2D drew
            // it, so require the image wash to measurably change the card pixels.
            const background_region = Geometry.RectF{
                .left = card_pill.box.rect.left + 12,
                .top = card_pill.box.rect.top + 12,
                .right = card_pill.box.rect.right - 12,
                .bottom = card_pill.box.rect.bottom - 12,
            };
            check_stage = "blurred artwork pixel readback";
            const with_background = resources.regionLuminance(background_region) catch return false;
            music_card.background_png = &.{};
            music_card.background_revision = 0;
            check_stage = "background-free card rendering";
            if (!resources.renderPill(card_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;
            // The composition swap chain is flip-sequential with two buffers.
            // Replace both before reading buffer 0, or it may still contain the
            // preceding frame with the background image.
            if (!resources.renderPill(card_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;
            check_stage = "background-free pixel readback";
            const without_background = resources.regionLuminance(background_region) catch return false;
            last_background_luminance_with = with_background;
            last_background_luminance_without = without_background;
            last_background_png_length = background_png_len;
            check_stage = "background luminance contrast";
            if (background_png_len == 0 or with_background <= without_background + 12) return false;
            music_card.background_png = background_png[0..background_png_len];
            music_card.background_revision = 1;
            check_stage = "card text rendering";
            if (!resources.renderPill(card_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;

            const layout = CardLayout.musicCardFor(card_pill.box);
            const title_region = Geometry.RectF{
                .left = layout.title.left,
                .top = layout.title.top,
                .right = @min(layout.title.right, layout.title.left + 100),
                .bottom = layout.title.bottom,
            };
            const blank_region = Geometry.RectF{
                .left = @max(layout.title.left, layout.title.right - 60),
                .top = layout.title.top,
                .right = layout.title.right,
                .bottom = layout.title.bottom,
            };
            const title_luminance = resources.regionLuminance(title_region) catch return false;
            const blank_luminance = resources.regionLuminance(blank_region) catch return false;
            if (title_luminance <= blank_luminance) return false;

            const task_title_storage = [_:0]u16{
                'A', 'c', 't', 'i', 'v', 'e', ' ', 0xD83D, 0xDE80, ' ', 'w', 'i', 'n', 'd', 'o', 'w', ' ',
                't', 'i', 't', 'l', 'e', ' ', 't', 'h',    'a',    't', ' ', 'n', 'e', 'e', 'd', 's', ' ',
                'a', 'n', ' ', 'e', 'l', 'l', 'i', 'p',    's',    'i', 's',
            };
            const task_title: [*:0]const u16 = &task_title_storage;
            var task_buttons = [_]TextRenderer.TaskButton{
                .{ .title = task_title, .active = true, .hover_amount = 1 },
            };
            const task_appear = [_]f32{1};
            var task_pill = card_pill;
            const task_island = TaskStripLayout.islandBoxFor(@floatFromInt(width_px), 220, 36);
            task_pill.task_island = task_island;
            task_pill.task_buttons = &task_buttons;
            task_pill.task_button_appear = &task_appear;
            task_pill.task_hovered_index = 0;
            check_stage = "task title rendering";
            if (!resources.renderPill(task_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;

            const task_amounts = [_]f32{1};
            const task_title_box = TaskStripLayout.taskTitleAtAmounts(task_island, 0, 1, &task_amounts, 0, 0, @floatFromInt(width_px));
            const task_text_region = Geometry.RectF{
                .left = task_title_box.left,
                .top = task_title_box.top,
                .right = task_title_box.right,
                .bottom = task_title_box.bottom,
            };
            const task_blank_region = Geometry.RectF{
                .left = task_title_box.right + 1,
                .top = task_title_box.top,
                .right = task_title_box.right + 7,
                .bottom = task_title_box.bottom,
            };
            const active_text_luminance = resources.regionLuminance(task_text_region) catch return false;
            const active_blank_luminance = resources.regionLuminance(task_blank_region) catch return false;
            if (active_text_luminance <= active_blank_luminance) return false;

            task_buttons[0].active = false;
            check_stage = "inactive task title rendering";
            if (!resources.renderPill(task_pill, text, .card, .{ .temperature_c = 0, .weather_code = -1 })) return false;
            const inactive_text_luminance = resources.regionLuminance(task_text_region) catch return false;
            const inactive_blank_luminance = resources.regionLuminance(task_blank_region) catch return false;
            if (inactive_text_luminance <= inactive_blank_luminance) return false;
        }
        check_stage = "compositor opacity animation";
        if (!resources.animateOpacity(0, 1, 0.15)) return false;
        check_stage = "final card frame";
        if (!resources.renderPill(pill, text_renderer, clock_style, .{ .temperature_c = 0, .weather_code = -1 })) return false;
        if (!verifySurfaceReadback(&resources)) return false;
        check_stage = "compositor clock wait";
        if (!resources.waitForCompositorClock(50)) return false;
        check_passed = true;
        return true;
    }
    check_stage = "compact weather frames";
    for ([_]i32{ 0, 2, 3, 45, 61, 73, 95 }) |weather_code| {
        if (!resources.renderPill(pill, text_renderer, clock_style, .{ .temperature_c = 18.4, .weather_code = weather_code, .valid = true })) return false;
    }
    if (text_renderer) |text| {
        var music_pill = pill;
        music_pill.resting_pill = pill.box;
        music_pill.resting_state = .music_strip;
        music_pill.music_present = true;
        music_pill.music_text = "歌词滚动与波形测试这是一段更长的测试文本";
        music_pill.lyric_line_prev = "上一句歌词";
        music_pill.lyric_line_roll = 0.45;
        music_pill.lyric_scroll_dip = 160;
        music_pill.lyric_line_prev_scroll_dip = 60;
        music_pill.music_level = 0.42;
        music_pill.music_level_known = true;
        music_pill.music_wave_phase = 0.8;
        music_pill.music_accent = Theme.currentTheme().accent;
        music_pill.status_sky = &.{ 0x6679, 0x5929 };
        music_pill.status_temperature = &.{ '2', '1', 0x00b0 };
        music_pill.status_code = 3;
        music_pill.status_strip_opacity = 0.8;
        check_stage = "music strip rendering";
        if (!resources.renderPill(music_pill, text, .compact, .{ .temperature_c = 18.4, .weather_code = 3, .valid = true })) return false;

        music_pill.call_up = true;
        music_pill.call_strip = .{ .seconds = 73, .level = 0.6, .level_known = true };
        check_stage = "call strip rendering";
        if (!resources.renderPill(music_pill, text, .compact, .{ .temperature_c = 0, .weather_code = -1 })) return false;
    }
    check_stage = "compact surface readback";
    check_passed = verifySurfaceReadback(&resources);
    return check_passed;
}

fn verifySurfaceReadback(resources: *DeviceResources) bool {
    if (resources.surface_width < 24 or resources.surface_height < 8) return false;
    const center_x = @as(f32, @floatFromInt(resources.surface_width)) * 0.5;
    const center_y = @as(f32, @floatFromInt(resources.surface_height)) * 0.5;
    var inside_alpha: u8 = 0;
    var outside_alpha: u8 = 255;
    var inside_rgb: [3]u8 = .{ 0, 0, 0 };
    resources.readBackFrame(center_x, center_y, 8, 1, &inside_alpha, &outside_alpha, &inside_rgb) catch return false;
    if (inside_alpha <= 200 or outside_alpha != 0) return false;

    const content = Geometry.RectF{
        .left = center_x - 6,
        .top = center_y - 4,
        .right = center_x + 6,
        .bottom = center_y + 4,
    };
    const luminance = resources.regionLuminance(content) catch return false;
    if (luminance <= 0) return false;
    var alpha_map: [48]u8 = undefined;
    const described = resources.describeRegionAlpha(content, 8, 4, &alpha_map) catch return false;
    return described.len > 0;
}

fn wideZSlice(buffer: []const u16) []const u16 {
    const end = std.mem.indexOfScalar(u16, buffer, 0) orelse buffer.len;
    return buffer[0..end];
}

fn pixelCoordinate(dip: f32, scale: f32) ReadbackError!i32 {
    if (!std.math.isFinite(dip) or !std.math.isFinite(scale)) return error.InvalidCoordinate;
    const pixels = dip * scale;
    if (!std.math.isFinite(pixels) or pixels < -2147483648.0 or pixels >= 2147483648.0) return error.InvalidCoordinate;
    return @intFromFloat(pixels);
}

fn mappedPixel(frame: *const MappedFrame, point: PixelPoint) [4]u8 {
    const data: [*]const u8 = @ptrCast(frame.mapped.data.?);
    const offset = point.y * @as(usize, frame.mapped.row_pitch) + point.x * 4;
    return .{ data[offset], data[offset + 1], data[offset + 2], data[offset + 3] };
}

fn samplePixel(frame: *const MappedFrame, point: PixelPoint, alpha: ?*u8, rgb: ?*[3]u8) void {
    const bgra = mappedPixel(frame, point);
    if (alpha) |output| output.* = bgra[3];
    if (rgb) |output| output.* = .{ bgra[2], bgra[1], bgra[0] };
}

pub fn nextCardOwner(current: CardOwner, card_up: bool, card_wanted: bool, panel_requested: bool, notification_active: bool, music_present: bool) CardOwner {
    if (!card_up) return .none;
    if (!card_wanted) return current;
    if (panel_requested) return .system_panel;
    if (notification_active) return .notification;
    if (music_present) return .music;
    return current;
}

pub fn contentStrengthsFor(card_up: bool, eased_progress_arg: f32, opening: bool) ContentStrengths {
    var result = ContentStrengths{};
    if (!card_up) return result;

    const eased_progress = @max(0, @min(1, eased_progress_arg));
    const sequenced_arg = if (opening)
        (eased_progress - card_content_lead_fraction) / (1 - card_content_lead_fraction)
    else
        1 - eased_progress / card_content_lead_fraction;
    const sequenced = @max(0, @min(1, sequenced_arg));
    result.card = 0.35 + 0.65 * sequenced;
    return result;
}

pub fn smokeCheck() bool {
    var resources = DeviceResources{};
    if (!resources.createDeviceResources()) return false;
    defer resources.shutdown();
    if (!resources.createSwapChain(220, 36)) return false;
    return resources.swap_chain != null and resources.surface_width > 0 and resources.surface_height > 0 and
        nextCardOwner(.music, true, true, true, true, true) == .system_panel and
        nextCardOwner(.music, true, false, false, false, false) == .music and
        nextCardOwner(.music, false, true, false, false, false) == .none and
        contentStrengthsFor(true, 0, true).card == 0.35 and
        contentStrengthsFor(true, 0.35, true).card == 0.35 and
        contentStrengthsFor(true, 1, true).card == 1 and
        contentStrengthsFor(true, 0, false).card == 1 and
        contentStrengthsFor(true, 0.35, false).card == 0.35 and
        contentStrengthsFor(false, 0.5, true).card == 1 and
        contentStrengthsFor(true, 0.5, false).bar == 1;
}
