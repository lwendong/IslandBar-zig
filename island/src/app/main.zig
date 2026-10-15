const std = @import("std");
const CommandLine = @import("CommandLine");
const Geometry = @import("Geometry");
const InputRegion = @import("InputRegion");
const GlassMaterial = @import("GlassMaterial");
const WicImage = @import("WicImage");
const AppBar = @import("AppBar");
const AudioVolume = @import("AudioVolume");
const Weather = @import("Weather");
const MusicSession = @import("MusicSession");
const Lyrics = @import("Lyrics");
const SoundOutput = @import("SoundOutput");
const StartApps = @import("StartApps");
const TrayPress = @import("TrayPress");
const Renderer = @import("Renderer");
const Diagnostics = @import("Diagnostics");
const IslandWindow = @import("IslandWindow");
const TextRenderer = @import("TextRenderer");
const Setup = @import("Setup");
const Log = @import("Log");
const Motion = @import("Motion");
const PlayerWindow = @import("PlayerWindow");
const DisplayBrightness = @import("DisplayBrightness");
const MiniJson = @import("MiniJson");
const Monitor = @import("Monitor");
const NativeTaskbar = @import("NativeTaskbar");
const Notification = @import("Notification");
const NotificationIcon = @import("NotificationIcon");
const NotificationPipe = @import("NotificationPipe");
const StartMenu = @import("StartMenu");
const StatePolicy = @import("StatePolicy");
const SystemStatus = @import("SystemStatus");
const SystemToggles = @import("SystemToggles");
const SysStatusProbe = @import("SysStatusProbe");
const ThumbnailPreview = @import("ThumbnailPreview");
const Theme = @import("Theme");
const ToastStore = @import("ToastStore");
const TrayIcons = @import("TrayIcons");
const WindowList = @import("WindowList");
const WeChatWatch = @import("WeChatWatch");
const TaskStripLayout = @import("TaskStripLayout");
const CardLayout = @import("CardLayout");

const HWND = IslandWindow.HWND;
const HBRUSH = ?*anyopaque;
const HDC = ?*anyopaque;
const HGDIOBJ = ?*anyopaque;
const HANDLE = ?*anyopaque;
const DWORD = u32;

const WinRect = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

const PaintStruct = extern struct {
    hdc: HDC,
    erase: i32,
    paint: WinRect,
    restore: i32,
    update: i32,
    reserved: [32]u8,
};

const SystemTime = extern struct {
    year: u16,
    month: u16,
    day_of_week: u16,
    day: u16,
    hour: u16,
    minute: u16,
    second: u16,
    milliseconds: u16,
};
const Luid = extern struct { low_part: u32 = 0, high_part: i32 = 0 };
const LuidAndAttributes = extern struct { luid: Luid = .{}, attributes: u32 = 0 };
const TokenPrivileges = extern struct { count: u32 = 0, privileges: [1]LuidAndAttributes = @splat(.{}) };

extern "kernel32" fn ExitProcess(exit_code: u32) callconv(.winapi) noreturn;
extern "kernel32" fn CreateMutexW(attributes: ?*anyopaque, initial_owner: i32, name: [*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetLastError() callconv(.winapi) u32;
extern "kernel32" fn CloseHandle(handle: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn GetModuleHandleW(module_name: ?[*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetModuleFileNameW(module: ?*anyopaque, filename: [*]u16, size: u32) callconv(.winapi) u32;
extern "kernel32" fn GetProcAddress(module: ?*anyopaque, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "user32" fn GetSystemMetrics(index: i32) callconv(.winapi) i32;
extern "user32" fn IsWindow(window: HWND) callconv(.winapi) i32;
extern "user32" fn GetDpiForSystem() callconv(.winapi) u32;
extern "user32" fn LockWorkStation() callconv(.winapi) i32;
extern "user32" fn ExitWindowsEx(flags: u32, reason: u32) callconv(.winapi) i32;
extern "powrprof" fn SetSuspendState(hibernate: u8, force_critical: u8, disable_wake_event: u8) callconv(.winapi) u8;
extern "user32" fn BeginPaint(window: HWND, paint: *PaintStruct) callconv(.winapi) HDC;
extern "user32" fn EndPaint(window: HWND, paint: *const PaintStruct) callconv(.winapi) i32;
extern "user32" fn DrawTextW(dc: HDC, text: [*]const u16, count: i32, rect: *WinRect, format: u32) callconv(.winapi) i32;
extern "kernel32" fn GetLocalTime(time: *SystemTime) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn GetEnvironmentVariableW(name: [*:0]const u16, buffer: [*]u16, size: u32) callconv(.winapi) u32;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: u32, share: u32, security: ?*anyopaque, creation: u32, flags: u32, template: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn WriteFile(file: ?*anyopaque, buffer: [*]const u8, count: u32, written: *u32, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn GetCurrentProcess() callconv(.winapi) ?*anyopaque;
extern "kernel32" fn Sleep(milliseconds: u32) callconv(.winapi) void;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: i32, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, length: *DWORD) callconv(.winapi) i32;
extern "kernel32" fn CreateToolhelp32Snapshot(flags: DWORD, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Process32FirstW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) i32;
extern "kernel32" fn Process32NextW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) i32;
extern "kernel32" fn TerminateProcess(process: HANDLE, exit_code: u32) callconv(.winapi) i32;
extern "kernel32" fn PostMessageW(window: HWND, message: u32, wparam: usize, lparam: isize) callconv(.winapi) i32;
extern "shell32" fn ShellExecuteW(window: HWND, operation: ?[*:0]const u16, file: [*:0]const u16, parameters: ?[*:0]const u16, directory: ?[*:0]const u16, show: i32) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn WideCharToMultiByte(code_page: u32, flags: u32, input: [*]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;
extern "gdi32" fn GetStockObject(index: i32) callconv(.winapi) HBRUSH;
extern "gdi32" fn FillRect(dc: HDC, rect: *const WinRect, brush: HBRUSH) callconv(.winapi) i32;
extern "gdi32" fn SetTextColor(dc: HDC, color: u32) callconv(.winapi) u32;
extern "gdi32" fn SetBkMode(dc: HDC, mode: i32) callconv(.winapi) i32;
extern "gdi32" fn SelectObject(dc: HDC, object: HGDIOBJ) callconv(.winapi) HGDIOBJ;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, co_init: u32) callconv(.winapi) i32;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "advapi32" fn GetUserNameW(name: [*]u16, size: *u32) callconv(.winapi) i32;
extern "advapi32" fn OpenProcessToken(process: ?*anyopaque, access: u32, token: *?*anyopaque) callconv(.winapi) i32;
extern "advapi32" fn LookupPrivilegeValueW(system_name: ?[*:0]const u16, name: [*:0]const u16, luid: *Luid) callconv(.winapi) i32;
extern "advapi32" fn AdjustTokenPrivileges(token: ?*anyopaque, disable_all: i32, new_state: *const TokenPrivileges, buffer_len: u32, previous_state: ?*TokenPrivileges, return_len: ?*u32) callconv(.winapi) i32;
const ProcessEntry32W = extern struct {
    size: DWORD,
    usage: DWORD,
    process_id: DWORD,
    default_heap_id: usize,
    module_id: DWORD,
    threads: DWORD,
    parent_process_id: DWORD,
    base_priority: i32,
    flags: DWORD,
    exe_file: [260]u16,
};
const black_brush: i32 = 4;
const default_gui_font: i32 = 17;
const transparent_background: i32 = 1;
const draw_text_center: u32 = 0x0001;
const draw_text_vertical_center: u32 = 0x0004;
const draw_text_single_line: u32 = 0x0020;
const error_already_exists: u32 = 183;
const error_invalid_handle: usize = std.math.maxInt(usize);
const th32cs_snapprocess: DWORD = 2;
const process_terminate: DWORD = 1;
const process_query_limited_information: DWORD = 0x1000;
const wm_close: u32 = 0x0010;
const sw_show_normal: i32 = 1;
const generic_write: u32 = 0x40000000;
const create_always: u32 = 2;
const file_attribute_normal: u32 = 0x80;
const coinit_apartment_threaded: u32 = 0x2;
const rpc_e_changed_mode: i32 = -2147417850;
const per_monitor_aware_v2: ?*anyopaque = @ptrFromInt(std.math.maxInt(usize) - 3);
const single_instance_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', '.', 'S', 'i', 'n', 'g', 'l', 'e', 'I', 'n', 's', 't', 'a', 'n', 'c', 'e', 0 };
var window_width_px: i32 = @intFromFloat(Geometry.pill_width_dip);
var window_height_px: i32 = @intFromFloat(Geometry.pill_height_dip);
var weather_reader = Weather.WeatherReader{};

const wide_wifi: [*:0]const u16 = &.{ 'W', 'i', '-', 'F', 'i', 0 };
const wide_bluetooth: [*:0]const u16 = &.{ 'B', 'l', 'u', 'e', 't', 'o', 'o', 't', 'h', 0 };
const wide_airplane: [*:0]const u16 = &.{ 0x98de, 0x884c, 0x6a21, 0x5f0f, 0 };
const wide_accessibility: [*:0]const u16 = &.{ 0x8f85, 0x52a9, 0x529f, 0x80fd, 0 };
const wide_battery_saver: [*:0]const u16 = &.{ 0x8282, 0x80fd, 0x6a21, 0x5f0f, 0 };
const wide_captions: [*:0]const u16 = &.{ 0x5b9e, 0x65f6, 0x5b57, 0x5e55, 0 };
const wide_night_light: [*:0]const u16 = &.{ 0x591c, 0x95f4, 0x6a21, 0x5f0f, 0 };
const wide_hotspot: [*:0]const u16 = &.{ 0x79fb, 0x52a8, 0x70ed, 0x70b9, 0 };
const wide_nearby: [*:0]const u16 = &.{ 0x5c31, 0x8fd1, 0x5171, 0x4eab, 0 };
const wide_wired_display: [*:0]const u16 = &.{ 0x6709, 0x7ebf, 0x663e, 0x793a, 0x5668, 0 };
const wide_projection: [*:0]const u16 = &.{ 0x6295, 0x5f71, 0 };
const wide_appearance: [*:0]const u16 = &.{ 0x5916, 0x89c2, 0 };
const wide_battery: [*:0]const u16 = &.{ 'B', 'a', 't', 't', 'e', 'r', 'y', 0 };
const wide_available: [*:0]const u16 = &.{ 0x53ef, 0x7528, 0 };
const wide_not_connected: [*:0]const u16 = &.{ 0x672a, 0x8fde, 0x63a5, 0 };
const wide_off: [*:0]const u16 = &.{ 0x5173, 0 };
const wide_sound_title: [*:0]const u16 = &.{ 0x58F0, 0x97F3, 0x8F93, 0x51FA, 0 };
const wide_sound_device_label: [*:0]const u16 = &.{ 0x8F93, 0x51FA, 0x8BBE, 0x5907, 0 };
const wide_sound_spatial_label: [*:0]const u16 = &.{ 0x7A7A, 0x95F4, 0x97F3, 0x6548, 0 };
const wide_sound_mixer_label: [*:0]const u16 = &.{ 0x97F3, 0x91CF, 0x5408, 0x6210, 0x5668, 0 };
const wide_sound_footer: [*:0]const u16 = &.{ 0x66F4, 0x591A, 0x97F3, 0x91CF, 0x8BBE, 0x7F6E, 0 };
const wide_sound_off: [*:0]const u16 = &.{ 0x5173, 0 };
const wide_sound_sonic: [*:0]const u16 = &.{ 0x7528, 0x4E8E, 0x8033, 0x673A, 0x7684, ' ', 'W', 'i', 'n', 'd', 'o', 'w', 's', ' ', 'S', 'o', 'n', 'i', 'c', 0 };
const wide_output_device: [*:0]const u16 = &.{ 'O', 'u', 't', 'p', 'u', 't', ' ', 'd', 'e', 'v', 'i', 'c', 'e', 0 };
const wide_tray_page: [*:0]const u16 = &.{ 0x6258, 0x76D8, 0 };
const wide_start_page: [*:0]const u16 = &.{ 0x5F00, 0x59CB, 0 };
const wide_open_verb: [*:0]const u16 = &.{ 'o', 'p', 'e', 'n', 0 };
const wide_explorer: [*:0]const u16 = &.{ 'e', 'x', 'p', 'l', 'o', 'r', 'e', 'r', '.', 'e', 'x', 'e', 0 };
const shutdown_privilege: [*:0]const u16 = &.{ 'S', 'e', 'S', 'h', 'u', 't', 'd', 'o', 'w', 'n', 'P', 'r', 'i', 'v', 'i', 'l', 'e', 'g', 'e', 0 };
const start_icon_buffer_bytes: usize = 16 * 1024;
const wide_on: [*:0]const u16 = &.{ 0x5f00, 0 };
const wide_disabled: [*:0]const u16 = &.{ 0x5df2, 0x5173, 0x95ed, 0 };
const uri_accessibility: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'e', 'a', 's', 'e', 'o', 'f', 'a', 'c', 'c', 'e', 's', 's', 0 };
const uri_battery: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'b', 'a', 't', 't', 'e', 'r', 'y', 's', 'a', 'v', 'e', 'r', 0 };
const uri_hotspot: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 't', 'w', 'o', 'r', 'k', '-', 'm', 'o', 'b', 'i', 'l', 'e', 'h', 'o', 't', 's', 'p', 'o', 't', 0 };
const uri_nearby: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 'a', 'r', 'b', 'y', '-', 's', 'h', 'a', 'r', 'i', 'n', 'g', 0 };
const uri_display: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'd', 'i', 's', 'p', 'l', 'a', 'y', 0 };
const uri_typing: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 't', 'y', 'p', 'i', 'n', 'g', 0 };
const uri_wifi: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 't', 'w', 'o', 'r', 'k', '-', 'w', 'i', 'f', 'i', 0 };
const uri_bluetooth: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'b', 'l', 'u', 'e', 't', 'o', 'o', 't', 'h', 0 };
const uri_airplane: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 't', 'w', 'o', 'r', 'k', 0 };
const uri_night_light: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'i', 'g', 'h', 't', 'l', 'i', 'g', 'h', 't', 0 };
const uri_sound: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 's', 'o', 'u', 'n', 'd', 0 };
const uri_settings: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 0 };

fn addPanelTile(tiles: *[CardLayout.max_system_panel_tiles]TextRenderer.SystemPanelTile, count: *usize, label: ?[*:0]const u16, state: ?[*:0]const u16, icon: TextRenderer.SystemPanelIcon, icon_value: i32, on: bool, chevron: bool, action: TextRenderer.PanelAction, uri: ?[*:0]const u16) void {
    if (count.* >= tiles.len) return;
    tiles[count.*] = .{ .label = label, .state_text = state, .icon = icon, .icon_value = icon_value, .on = on, .chevron = chevron, .action = action, .uri = uri };
    count.* += 1;
}

fn buildSystemPanelText(context: *PaintContext) void {
    var all: [CardLayout.max_system_panel_tiles]TextRenderer.SystemPanelTile = @splat(.{});
    var count: usize = 0;
    const status = &context.system_status;
    const network_state = if (!status.wifi_radio_on) wide_disabled else switch (status.network) {
        .none => wide_disabled,
        .disconnected => wide_not_connected,
        .connected => wide_available,
    };
    addPanelTile(&all, &count, wide_wifi, network_state, .network, @backingInt(status.signal), status.wifi_radio_on, false, .toggle_wifi, null);
    addPanelTile(&all, &count, wide_bluetooth, if (status.bluetooth_on) wide_not_connected else wide_off, .bluetooth, @intFromBool(status.bluetooth_on), status.bluetooth_on, false, .toggle_bluetooth, null);
    addPanelTile(&all, &count, wide_airplane, null, .airplane, 0, !status.wifi_radio_on and !status.bluetooth_on, false, .toggle_radio, null);
    addPanelTile(&all, &count, wide_accessibility, null, .accessibility, 0, false, true, .open_settings, uri_accessibility);
    addPanelTile(&all, &count, wide_battery_saver, if (status.battery_saver_on) wide_on else wide_off, .battery_saver, 0, status.battery_saver_on, false, .open_settings, uri_battery);
    addPanelTile(&all, &count, wide_captions, if (status.live_captions_on) wide_on else wide_off, .captions, 0, status.live_captions_on, false, .toggle_live_captions, null);
    addPanelTile(&all, &count, wide_night_light, if (status.night_light_on) wide_on else wide_off, .moon, 0, status.night_light_on, false, .toggle_night_light, null);
    addPanelTile(&all, &count, wide_hotspot, null, .hotspot, 0, false, false, .open_settings, uri_hotspot);
    addPanelTile(&all, &count, wide_nearby, null, .share, 0, false, false, .open_settings, uri_nearby);
    addPanelTile(&all, &count, wide_wired_display, null, .wired_display, 0, false, true, .open_settings, uri_display);
    addPanelTile(&all, &count, wide_projection, null, .projection, 0, false, true, .projection_modes, null);
    if (SystemStatus.shouldDrawInputMethod(status, context.installed_layout_count)) {
        SystemStatus.inputMethodLabel(status.input_language_id, &context.input_language_label);
        addPanelTile(&all, &count, @ptrCast(&context.input_language_label), null, .input_method, 0, true, false, .open_settings, uri_typing);
    }
    @memset(&context.theme_name, 0);
    const current_name = &Theme.currentTheme().name;
    const current_name_len = std.mem.indexOfScalar(u16, current_name, 0) orelse current_name.len;
    @memcpy(context.theme_name[0..@min(current_name_len, context.theme_name.len - 1)], current_name[0..@min(current_name_len, context.theme_name.len - 1)]);
    addPanelTile(&all, &count, wide_appearance, @ptrCast(&context.theme_name), .settings, 0, false, false, .cycle_theme, null);
    if (SystemStatus.shouldDrawBattery(status)) {
        var ascii: [8]u8 = undefined;
        const value = std.fmt.bufPrint(&ascii, "{d}%", .{status.battery_percent}) catch &.{};
        @memset(&context.battery_label, 0);
        for (value, 0..) |byte, index| context.battery_label[index] = byte;
        addPanelTile(&all, &count, wide_battery, @ptrCast(&context.battery_label), .battery, status.battery_percent, status.on_ac_power or status.battery_percent > 20, false, .open_settings, uri_battery);
    }
    addPanelTile(&all, &count, wide_tray_page, null, .share, 0, false, false, .open_tray_page, null);
    addPanelTile(&all, &count, wide_start_page, null, .settings, 0, false, false, .open_start_page, null);

    context.system_panel_text = .{};
    const per_page: usize = @intCast(CardLayout.max_system_tiles);
    const page_count_usize = @max(1, (count + per_page - 1) / per_page);
    const page_count: i32 = @intCast(page_count_usize);
    const page = @mod(context.system_panel_page, page_count);
    context.system_panel_page = page;
    context.system_panel_text.page_index = page;
    context.system_panel_text.page_count = page_count;
    const first = @as(usize, @intCast(page)) * CardLayout.max_system_tiles;
    const copied = @min(CardLayout.max_system_tiles, count - first);
    context.system_panel_text.tile_count = copied;
    @memcpy(context.system_panel_text.tiles[0..copied], all[first .. first + copied]);
    context.system_panel_text.volume = context.volume_level;
    context.system_panel_text.muted = context.volume_muted;
    context.system_panel_text.has_brightness = context.brightness_available;
    context.system_panel_text.brightness = @as(f32, @floatFromInt(context.brightness_percent)) / 100;
}

fn wideArrayZ(array: *const [128]u16) [*:0]const u16 {
    return @ptrCast(array);
}

fn buildSoundPageText(context: *PaintContext) void {
    var page = TextRenderer.SoundPageText{};
    page.title = wide_sound_title;
    page.device_label = wide_sound_device_label;
    page.spatial_label = wide_sound_spatial_label;
    page.mixer_label = wide_sound_mixer_label;
    page.footer = wide_sound_footer;
    page.spatial[0] = .{ .label = wide_sound_off, .selected = true };
    page.spatial[1] = .{ .label = wide_sound_sonic, .selected = false };

    const snapshot = &context.sound_snapshot;
    for (snapshot.devices[0..@min(snapshot.device_count, page.devices.len)], 0..) |*device, index| {
        page.devices[index] = .{
            .name = wideArrayZ(&device.name),
            .form_factor = device.form_factor,
            .is_default = device.is_default,
        };
        page.device_count += 1;
    }
    page.mix[0] = .{
        .label = if (snapshot.default_device_name[0] != 0) wideArrayZ(&snapshot.default_device_name) else wide_output_device,
        .volume = context.volume_level,
        .muted = context.volume_muted,
    };
    page.mix_count = 1;
    for (snapshot.sessions[0..@min(snapshot.session_count, SoundOutput.max_sessions)], 0..) |*session, index| {
        if (page.mix_count >= page.mix.len) break;
        page.mix[page.mix_count] = .{
            .label = wideArrayZ(&session.name),
            .volume = session.volume,
            .muted = false,
            .icon_png = if (session.icon_size > 0) session.icon[0..@min(session.icon_size, session.icon.len)] else null,
            .icon_size = @min(session.icon_size, session.icon.len),
            .icon_revision = session.icon_revision,
        };
        _ = index;
        page.mix_count += 1;
    }
    page.scroll = context.sound_page_scroll;
    context.sound_page_text = page;
}

fn buildTrayPageText(context: *PaintContext) void {
    @memset(&context.tray_page_icons, .{});
    context.tray_page_icon_count = 0;
    const source = context.tray_icons orelse return;
    const count = @min(source.count(), context.tray_page_icons.len);
    for (0..count) |index| {
        const info = source.at(index) orelse continue;
        context.tray_page_icons[index] = .{
            .name = info.name,
            .png = info.png,
            .promoted = info.promoted,
            .uid = info.uid,
            .has_uid = info.has_uid,
            .has_guid = info.has_guid,
            .guid = .{ .data1 = info.guid.data1, .data2 = info.guid.data2, .data3 = info.guid.data3, .data4 = info.guid.data4 },
        };
        context.tray_page_icon_count += 1;
    }
    context.tray_page_revision = source.getRevision();
}

fn buildStartCardText(context: *PaintContext) void {
    const apps = context.start_apps orelse return;
    const pin_count = @min(@as(usize, @intCast(@max(0, apps.pinCount()))), context.start_pin_icons.len);
    @memset(&context.start_pin_icons, null);
    @memset(&context.start_pin_icon_sizes, 0);
    for (0..pin_count) |index| {
        const begin = index * start_icon_buffer_bytes;
        if (begin > context.start_pin_icon_data.len or context.start_pin_icon_data.len - begin < start_icon_buffer_bytes) continue;
        const destination = context.start_pin_icon_data[begin .. begin + start_icon_buffer_bytes];
        const icon_size = apps.copyPinIconPng(index, destination);
        if (icon_size != 0) {
            context.start_pin_icons[index] = destination[0..icon_size];
            context.start_pin_icon_sizes[index] = icon_size;
        }
    }
    context.start_card_text = .{
        .pins = apps.pins.items,
        .pin_count = pin_count,
        .pin_icons = context.start_pin_icons[0..pin_count],
        .pin_icon_sizes = context.start_pin_icon_sizes[0..pin_count],
        .pin_icon_revision = apps.iconRevision(),
        .list = apps.list.items,
        .list_count = @intCast(@max(0, apps.listCount())),
        .picker_scroll_row = context.start_picker_scroll_row,
        .page = context.start_page_state,
        .hovered_pin = context.start_hovered_pin,
        .hovered_picker_row = context.start_hovered_picker_row,
        .hovered_power_row = context.start_hovered_power_row,
        .power_button_hovered = context.start_power_hovered,
        .power_confirm_row = context.start_power_confirm_row,
        .account_name = @ptrCast(&context.account_name),
    };
    context.last_start_icon_revision = apps.iconRevision();
}

fn paintClock(window: HWND) void {
    var paint: PaintStruct = undefined;
    const dc = BeginPaint(window, &paint) orelse return;
    var client = WinRect{
        .left = 0,
        .top = 0,
        .right = window_width_px,
        .bottom = window_height_px,
    };
    _ = FillRect(dc, &client, GetStockObject(black_brush));

    const old_font = SelectObject(dc, GetStockObject(default_gui_font));
    _ = SetBkMode(dc, transparent_background);
    _ = SetTextColor(dc, 0x00E6E6E6);
    var time: SystemTime = undefined;
    GetLocalTime(&time);
    var text = [_]u16{ 0, 0, ':', 0, 0 };
    text[0] = '0' + @as(u16, @intCast(time.hour / 10));
    text[1] = '0' + time.hour % 10;
    text[3] = '0' + @as(u16, @intCast(time.minute / 10));
    text[4] = '0' + time.minute % 10;
    var weather_line: [64]u16 = @splat(0);
    weather_reader.getLine(&weather_line);
    if (weather_line[0] != 0) {
        var length: usize = 0;
        while (length < weather_line.len and weather_line[length] != 0) : (length += 1) {}
        _ = DrawTextW(dc, &weather_line, @intCast(length), &client, draw_text_center | draw_text_vertical_center | draw_text_single_line);
    } else {
        _ = DrawTextW(dc, &text, @intCast(text.len), &client, draw_text_center | draw_text_vertical_center | draw_text_single_line);
    }
    _ = SelectObject(dc, old_font);
    _ = EndPaint(window, &paint);
}
const wide_no_fullscreen: [*:0]const u16 = &.{ 'I', 'S', 'L', 'A', 'N', 'D', 'B', 'A', 'R', '_', 'N', 'O', '_', 'F', 'U', 'L', 'L', 'S', 'C', 'R', 'E', 'E', 'N', 0 };
const wide_no_media: [*:0]const u16 = &.{ 'I', 'S', 'L', 'A', 'N', 'D', 'B', 'A', 'R', '_', 'N', 'O', '_', 'M', 'E', 'D', 'I', 'A', 0 };
const wide_no_session: [*:0]const u16 = &.{ 'I', 'S', 'L', 'A', 'N', 'D', 'B', 'A', 'R', '_', 'N', 'O', '_', 'S', 'E', 'S', 'S', 'I', 'O', 'N', 0 };
fn runNotify() i32 {
    var notification = Notification.Notification{};
    var title: [Notification.title_capacity * 4]u8 = undefined;
    var body: [Notification.body_capacity * 4]u8 = undefined;
    var app: [Notification.app_name_capacity * 4]u8 = undefined;
    var icon: [260 * 4]u8 = undefined;
    var urgency: [16]u8 = undefined;

    if (CommandLine.valueAfter(CommandLine.notify_flag, &title)) |value| copyBytesZ(&notification.title, value);
    if (CommandLine.valueAfter(CommandLine.notify_body_flag, &body)) |value| copyBytesZ(&notification.body, value);
    if (CommandLine.valueAfter(CommandLine.notify_app_flag, &app)) |value| copyBytesZ(&notification.app, value);
    if (CommandLine.valueAfter(CommandLine.notify_icon_flag, &icon)) |value| copyBytesZ(&notification.icon_path, value);
    if (CommandLine.valueAfter(CommandLine.notify_urgency_flag, &urgency)) |value| {
        if (std.ascii.eqlIgnoreCase(value, "high")) {
            notification.urgency = .high;
        } else if (std.ascii.eqlIgnoreCase(value, "low")) {
            notification.urgency = .low;
        }
    }
    notification.sticky = CommandLine.hasArgument(CommandLine.sticky_flag);

    if (notification.title[0] == 0 and notification.body[0] != 0) {
        copyBytesZ(&notification.title, std.mem.sliceTo(&notification.body, 0));
        notification.body[0] = 0;
    }
    if (notification.title[0] == 0 and notification.body[0] == 0) {
        Log.logAndPrint("usage: IslandBar.exe --notify <title> [--body <text>] [--app <name>] [--icon <path>] [--urgency low|normal|high] [--sticky]");
        return 2;
    }

    var response: [512]u8 = @splat(0);
    if (NotificationPipe.sendNotification(&notification, NotificationPipe.pipe_name, &response, 2000)) {
        logFormatted("sent: {s}", .{std.mem.sliceTo(&response, 0)});
        return 0;
    }
    logFormatted("could not reach the bar on \\\\.\\pipe\\IslandBar.Notify: {s}", .{
        if (response[0] != 0) std.mem.sliceTo(&response, 0) else "no reason reported",
    });
    return 1;
}

fn enablePerMonitorV2() void {
    const user32 = GetModuleHandleW(&.{ 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0 }) orelse return;
    const address = GetProcAddress(user32, "SetThreadDpiAwarenessContext") orelse return;
    const set_context: *const fn (?*anyopaque) callconv(.winapi) ?*anyopaque = @ptrCast(address);
    _ = set_context(per_monitor_aware_v2);
}

fn environmentSwitchEnabled(name: [*:0]const u16) bool {
    var value: [8]u16 = @splat(0);
    return GetEnvironmentVariableW(name, &value, @intCast(value.len)) > 0 and value[0] == '1';
}

var native_taskbar = NativeTaskbar.NativeTaskbar{};
var manage_native_taskbar = false;
var release_taskbar_strip = false;

fn logFormatted(comptime format: []const u8, args: anytype) void {
    var buffer: [1024]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, format, args) catch return;
    Log.logAndPrint(line);
}

fn runWindowList(activate: bool) i32 {
    var windows = WindowList.WindowList{};
    const count = windows.refresh();
    Log.logAndPrint("IslandBar window list");
    Log.logAndPrint("-----------------------------------------------");
    var summary_utf8: [768]u8 = undefined;
    logFormatted("  {s}", .{CommandLine.wideTextToUtf8(&windows.summary, &summary_utf8)});
    const foreground_address = if (windows.foreground) |foreground| @intFromPtr(foreground) else 0;
    logFormatted("  foreground: 0x{x}", .{foreground_address});
    if (count == 0) {
        Log.logAndPrint("Nothing would be listed. If application windows are open, check their descriptions.");
        return 0;
    }

    Log.logAndPrint("These would appear as buttons, front to back:");
    for (windows.entries[0..count], 0..) |entry, index| {
        var title_utf8: [512]u8 = undefined;
        logFormatted("{d: >2}. pid {d: <6} {s}{s}", .{
            index + 1,
            entry.process_id,
            if (entry.iconic) "[min] " else "",
            CommandLine.wideTextToUtf8(&entry.title, &title_utf8),
        });
    }
    if (!activate) return 0;

    var target_index: ?usize = null;
    for (windows.entries[0..count], 0..) |entry, index| {
        if (entry.handle != windows.foreground) {
            target_index = index;
            break;
        }
    }
    const index = target_index orelse {
        Log.logAndPrint("Nothing to activate.");
        return 0;
    };
    const target = windows.entries[index];
    logFormatted("Activating entry {d} (pid {d}, {s}minimised)...", .{
        index + 1,
        target.process_id,
        if (target.iconic) "" else "not ",
    });
    const raised = windows.activate(target.handle);
    Log.logAndPrint(if (raised) "activate SUCCEEDED" else "activate was REFUSED by Windows");
    return if (raised) 0 else 1;
}

fn runTrayDump() i32 {
    const allocator = std.heap.page_allocator;
    var icons = TrayIcons.TrayIcons{};
    defer icons.deinit(allocator);
    const count = icons.refresh(allocator);
    var key_utf8: [256]u8 = undefined;
    logFormatted("tray dump: {d} icon(s) with a running application, from {s}", .{
        count,
        CommandLine.wideTextToUtf8(TrayIcons.TrayIcons.settingsKeyPath(), &key_utf8),
    });
    logFormatted("  (looked at {d} entr(ies) in the key, {d} process(es) in the snapshot, {d} matched a running application)", .{
        icons.getExamined(),
        icons.getProcessesSeen(),
        icons.getRunningApps(),
    });
    for (0..count) |index| {
        const icon = icons.at(index) orelse continue;
        const path = icons.exePathAt(index) orelse &.{};
        var name_utf8: [512]u8 = undefined;
        var path_utf8: [1024]u8 = undefined;
        logFormatted("  [{d}] {s} -- {d} byte PNG, promoted={d}, {s}", .{
            index,
            CommandLine.wideTextToUtf8(&icon.name, &name_utf8),
            icon.png.len,
            @intFromBool(icon.promoted),
            CommandLine.wideTextToUtf8(path, &path_utf8),
        });
    }
    return if (count > 0) 0 else 1;
}

fn runTraySurface() i32 {
    const allocator = std.heap.page_allocator;
    var icons = TrayIcons.TrayIcons{};
    defer icons.deinit(allocator);
    const count = icons.refresh(allocator);

    var stage = TrayPress.Stage{};
    defer stage.reset();
    var note: [160]u16 = @splat(0);
    const staged = stage.begin(&note);
    const flyout = stage.flyout_home;
    logFormatted("tray surface: {d} icon(s); the shell's tray {s}", .{
        count,
        if (staged) "is laid out (overflow opened invisibly)" else "could not be laid out",
    });
    if (!staged) {
        var note_utf8: [512]u8 = undefined;
        logFormatted("  ({s})", .{CommandLine.wideTextToUtf8(&note, &note_utf8)});
    } else {
        logFormatted("  the overflow flyout is at {d},{d} {d}x{d}", .{
            flyout.left,
            flyout.top,
            flyout.right - flyout.left,
            flyout.bottom - flyout.top,
        });
    }

    var answered: usize = 0;
    for (0..count) |index| {
        const icon = icons.at(index) orelse continue;
        var request = TrayPress.Request{
            .uid = icon.uid,
            .has_uid = icon.has_uid,
            .has_guid = icon.has_guid,
            .guid = .{
                .data1 = icon.guid.data1,
                .data2 = icon.guid.data2,
                .data3 = icon.guid.data3,
                .data4 = icon.guid.data4,
            },
        };
        copyWide(&request.name, &icon.name);
        if (icons.exePathAt(index)) |path| copyWide(&request.exe_path, path);

        var rect = TrayPress.Rect{};
        const have = staged and stage.resolveIconRect(&request, &rect);
        if (have) answered += 1;
        var name_utf8: [512]u8 = undefined;
        if (have) {
            const in_flyout = rect.left >= flyout.left - 4 and rect.right <= flyout.right + 4 and
                rect.top >= flyout.top - 4 and rect.bottom <= flyout.bottom + 4;
            logFormatted("  [{d}] {s} ({s}) -- {d},{d} {d}x{d} {s}", .{
                index,
                CommandLine.wideTextToUtf8(&icon.name, &name_utf8),
                if (icon.has_guid) "GUID" else "UID",
                rect.left,
                rect.top,
                rect.right - rect.left,
                rect.bottom - rect.top,
                if (in_flyout) "(overflow)" else "(tray proper: no button rectangle published)",
            });
        } else {
            logFormatted("  [{d}] {s} ({s}) -- the shell has no rectangle for it", .{
                index,
                CommandLine.wideTextToUtf8(&icon.name, &name_utf8),
                if (icon.has_guid) "GUID" else "UID",
            });
        }
    }
    logFormatted("  {d} of {d} answer (the rest are registered but not displayed)", .{ answered, count });
    return if (answered > 0) 0 else 1;
}

fn runToastDump(limit_arg: i64) i32 {
    const limit = if (limit_arg <= 0) 10 else limit_arg;
    var reader = ToastStore.ToastReader{};
    if (!reader.start(null)) {
        Log.logAndPrint("toast dump: the system toast database is not readable");
        return 1;
    }
    defer reader.stop();
    var text: [64 * 1024]u16 = @splat(0);
    const rows = reader.dump(limit, &text);
    logFormatted("toast dump: {d} of the newest {d} toast(s) in {s}", .{
        rows,
        limit,
        if (reader.available()) "the live database" else "nowhere",
    });
    if (rows > 0) {
        var output: [192 * 1024 + 1]u8 = undefined;
        Log.logAndPrint(CommandLine.wideTextToUtf8(&text, &output));
    }
    return if (rows > 0) 0 else 1;
}

fn runTrayPress(index_arg: i32, fire: bool, right_click: bool) i32 {
    const allocator = std.heap.page_allocator;
    var icons = TrayIcons.TrayIcons{};
    defer icons.deinit(allocator);
    const count = icons.refresh(allocator);
    if (index_arg < 0 or index_arg >= count) {
        logFormatted("tray press: [{d}] is not one of the {d} icon(s) on the card", .{ index_arg, count });
        return 1;
    }
    const index: usize = @intCast(index_arg);
    const icon = icons.at(index) orelse return 1;
    var request = TrayPress.Request{
        .uid = icon.uid,
        .has_uid = icon.has_uid,
        .has_guid = icon.has_guid,
        .guid = .{
            .data1 = icon.guid.data1,
            .data2 = icon.guid.data2,
            .data3 = icon.guid.data3,
            .data4 = icon.guid.data4,
        },
    };
    copyWide(&request.name, &icon.name);
    if (icons.exePathAt(index)) |path| copyWide(&request.exe_path, path);
    var name_utf8: [512]u8 = undefined;
    logFormatted("tray press: [{d}] '{s}' ({s})", .{
        index,
        CommandLine.wideTextToUtf8(&icon.name, &name_utf8),
        if (icon.has_guid) "registered by GUID" else "registered by UID",
    });
    const com_result = CoInitializeEx(null, 0);
    const com_ok = com_result >= 0 or com_result == rpc_e_changed_mode;
    if (!com_ok) {
        Log.logAndPrint("tray press: COM could not be initialized");
        return 1;
    }
    const outcome = TrayPress.pressTrayIcon(&request, fire, right_click);
    if (com_result >= 0) CoUninitialize();
    logFormatted("  the shell says the icon is at {d},{d} {d}x{d}", .{
        outcome.rect.left,
        outcome.rect.top,
        outcome.rect.right - outcome.rect.left,
        outcome.rect.bottom - outcome.rect.top,
    });
    var shell_name_utf8: [512]u8 = undefined;
    logFormatted("  -> {s}{s} (shell calls it '{s}'), lookup {d} ms, press {d} ms", .{
        TrayPress.resultName(outcome.result),
        if (right_click) " [right click]" else "",
        CommandLine.wideTextToUtf8(&outcome.shell_name, &shell_name_utf8),
        outcome.lookup_ms,
        outcome.press_ms,
    });
    return if (outcome.result == .pressed or outcome.result == .found) 0 else 1;
}

fn runIconDump() i32 {
    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (com_result < 0 and com_result != rpc_e_changed_mode) return 1;
    const initialized_com = com_result >= 0;
    defer if (initialized_com) CoUninitialize();

    var app_id: [512]u8 = @splat(0);
    const app_id_utf8 = CommandLine.valueAfter(CommandLine.icon_dump_flag, &app_id) orelse {
        Log.logAndPrint("icon dump: an app id is required, e.g. QQMusic.exe");
        return 2;
    };
    var app_id_wide: [512]u16 = @splat(0);
    const app_id_length = std.unicode.utf8ToUtf16Le(&app_id_wide, app_id_utf8) catch {
        Log.logAndPrint("icon dump: the app id could not be read");
        return 2;
    };
    var executable: [260]u16 = @splat(0);
    if (!MusicSession.executableFromAppId(app_id_wide[0..app_id_length], &executable)) {
        logFormatted("icon dump: '{s}' did not resolve to an executable", .{app_id_utf8});
        return 1;
    }
    var executable_utf8: [1024]u8 = undefined;
    logFormatted("icon dump: resolved to {s}", .{CommandLine.wideTextToUtf8(&executable, &executable_utf8)});

    var png: [MusicSession.artwork_capacity]u8 = undefined;
    const png_size = MusicSession.fetchAppIconForTest(&executable, &png);
    logFormatted("icon dump: encoded {d} bytes of PNG", .{png_size});
    if (png_size == 0) return 1;

    var decoded = WicImage.DecodedImage{};
    if (!WicImage.decodeImage(png[0..png_size], &decoded, .other)) {
        Log.logAndPrint("icon dump: the PNG did not decode");
        return 1;
    }
    const pixels = decoded.pixels orelse return 1;
    if (decoded.width <= 0 or decoded.height <= 0) return 1;
    const total: usize = @intCast(decoded.width * decoded.height);
    var visible: usize = 0;
    var alpha_sum: u64 = 0;
    var max_alpha: u8 = 0;
    for (0..total) |index| {
        const alpha = pixels[index * 4 + 3];
        alpha_sum += alpha;
        max_alpha = @max(max_alpha, alpha);
        if (alpha > 8) visible += 1;
    }
    const mean_alpha = @as(f64, @floatFromInt(alpha_sum)) / @as(f64, @floatFromInt(total));
    logFormatted("icon dump: decoded {d}x{d}, {d} of {d} pixels visible, max alpha {d}, mean alpha {d:.1}", .{
        decoded.width, decoded.height, visible, total, max_alpha, mean_alpha,
    });

    const encoded_size = WicImage.encodeBgraToPng(pixels[0 .. total * 4], decoded.width, decoded.height, &png);
    if (encoded_size == 0) {
        Log.logAndPrint("icon dump: could not re-encode the decoded pixels");
        return 1;
    }

    var output_path: [260]u16 = @splat(0);
    const log_length = Log.logPath(&output_path);
    if (log_length == 0 or log_length >= output_path.len) {
        Log.logAndPrint("icon dump: could not find the log directory");
        return 1;
    }
    var stem_end = log_length;
    for (output_path[0..log_length], 0..) |unit, index| if (unit == '.') {
        stem_end = index;
    };
    const suffix = "-icon.png";
    if (stem_end + suffix.len >= output_path.len) {
        Log.logAndPrint("icon dump: output path is too long");
        return 1;
    }
    for (suffix, 0..) |unit, index| output_path[stem_end + index] = unit;
    output_path[stem_end + suffix.len] = 0;

    const file = CreateFileW(@ptrCast(&output_path), generic_write, 0, null, create_always, file_attribute_normal, null);
    if (file == null or @intFromPtr(file.?) == error_invalid_handle) {
        var path_utf8: [1024]u8 = undefined;
        logFormatted("icon dump: could not write {s}", .{CommandLine.wideTextToUtf8(&output_path, &path_utf8)});
        return 1;
    }
    defer _ = CloseHandle(file);
    var written: u32 = 0;
    if (WriteFile(file, &png, @intCast(encoded_size), &written, null) == 0 or written != encoded_size) {
        Log.logAndPrint("icon dump: writing the icon failed");
        return 1;
    }
    var output_utf8: [1024]u8 = undefined;
    logFormatted("icon dump: wrote {s} ({d} bytes)", .{ CommandLine.wideTextToUtf8(&output_path, &output_utf8), written });
    return 0;
}

fn percentFromLevel(level: f32) i32 {
    return @intFromFloat(@round(level * 100));
}

fn runVolumeSet(percent_arg: i32) i32 {
    const percent = @max(0, @min(percent_arg, 100));
    var volume = AudioVolume.AudioVolume{};
    if (!volume.start()) {
        Log.logAndPrint("volume set: no audio endpoint available");
        return 1;
    }
    defer volume.stop();

    var before: f32 = 0;
    const had_before = volume.get(&before);
    const wanted = @as(f32, @floatFromInt(percent)) / 100;
    volume.setLevel(wanted);
    var after: f32 = 0;
    for (0..200) |_| {
        Sleep(10);
        if (volume.get(&after) and @abs(after - wanted) < 0.011) break;
    }
    logFormatted("volume set: {s}{d}% -> {d}% (asked for {d}%)", .{
        if (had_before) "" else "unknown -> ",
        if (had_before) percentFromLevel(before) else 0,
        percentFromLevel(after),
        percent,
    });
    return 0;
}

fn runVolumeTest() i32 {
    var volume = AudioVolume.AudioVolume{};
    if (!volume.start()) {
        Log.logAndPrint("volume test: no audio endpoint available");
        return 1;
    }
    defer volume.stop();

    var original: f32 = 0;
    if (!volume.get(&original)) {
        Log.logAndPrint("volume test: the endpoint gave no level");
        return 1;
    }
    logFormatted("volume test: read {d}% (muted={d})", .{ percentFromLevel(original), @intFromBool(volume.isMuted()) });

    var failures: i32 = 0;
    const steps = [_]struct { level: f32, label: []const u8 }{
        .{ .level = 0.25, .label = "set to 25%" },
        .{ .level = 0.75, .label = "set to 75%" },
    };
    for (steps) |step| {
        volume.setLevel(step.level);
        Sleep(900);
        var read: f32 = 0;
        _ = volume.get(&read);
        logFormatted("volume test: {s} -> device reports {d}%", .{ step.label, percentFromLevel(read) });
        if (@abs(read - step.level) > 0.05) failures += 1;
    }

    const muted_before = volume.isMuted();
    volume.toggleMute();
    Sleep(900);
    const muted_after = volume.isMuted();
    logFormatted("volume test: mute {d} -> {d}", .{ @intFromBool(muted_before), @intFromBool(muted_after) });
    if (muted_after == muted_before) failures += 1;
    volume.toggleMute();
    Sleep(400);

    volume.setLevel(original);
    Sleep(900);
    var restored: f32 = 0;
    _ = volume.get(&restored);
    logFormatted("volume test: restored to {d}% (was {d}%)", .{ percentFromLevel(restored), percentFromLevel(original) });
    if (@abs(restored - original) > 0.05) failures += 1;
    Log.logAndPrint(if (failures == 0) "volume test: PASS" else "volume test: FAIL");
    return if (failures == 0) 0 else 1;
}

fn copyWide(output: []u16, input: []const u16) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const text = input[0 .. std.mem.indexOfScalar(u16, input, 0) orelse input.len];
    const count = @min(output.len - 1, text.len);
    @memcpy(output[0..count], text[0..count]);
}

fn printHelp() void {
    Log.logAndPrint("usage: island_bar.exe [options]");
    Log.logAndPrint("  (no arguments)   show the bar and hide the native taskbar");
    Log.logAndPrint("  --keep-taskbar   leave the native taskbar visible");
    Log.logAndPrint("  --appbar         claim the top work-area strip (opt-in)");
    Log.logAndPrint("  --system-panel  open the system panel on startup");
    Log.logAndPrint("  --keep-strip     keep the strip reserved by the shell taskbar");
    Log.logAndPrint("  --self-test      run the runtime assertions");
    Log.logAndPrint("  --no-console     do not attach to or create a console");
    Log.logAndPrint("  --probe-taskbar  test shell taskbar control routes and restore it");
    Log.logAndPrint("  --window-list [--activate]  list top-level application windows");
    Log.logAndPrint("  --tray-dump      list tray icons found in the registry");
    Log.logAndPrint("  --tray-surface   inspect icon positions in the hidden overflow flyout");
    Log.logAndPrint("  --tray-press N [--fire] [--right]  inspect or press a tray icon");
    Log.logAndPrint("  --toast-dump [N] read recent Windows toast notifications");
    Log.logAndPrint("  --volume-test   round-trip volume and restore the original level");
    Log.logAndPrint("  --volume-set N  set system output volume to N percent");
    Log.logAndPrint("  --lyrics-test TITLE [ARTIST]  fetch and inspect timed lyrics");
    Log.logAndPrint("  --lyrics-verbose  include both services' request and response details");
    Log.logAndPrint("  --notify TITLE [--body TEXT] [--app NAME] [--icon PATH] [--urgency low|normal|high] [--sticky]");
    Log.logAndPrint("  --offline        do not start the weather reader");
    Log.logAndPrint("  --demo           cycle collapsed/hover/expanded states without input");
    Log.logAndPrint("  --music-preview  preview the collapsed, music strip, hover, and card states");
    Log.logAndPrint("  --state NAME     pin the island to a named state");
    Log.logAndPrint("  --start-hover    keep the Start button highlighted for screenshots");
    Log.logAndPrint("  --no-console     keep diagnostics in the log without console output");
    Log.logAndPrint("  --icon-dump APP  resolve a media app id and save its icon beside the log");
}

fn runLyricsTestFromCommandLine(verbose: bool) i32 {
    var title_buffer: [512]u8 = undefined;
    var artist_buffer: [512]u8 = undefined;
    const title_candidate = CommandLine.valueAfterOffset(CommandLine.lyrics_test_flag, 1, &title_buffer) orelse "";
    const artist_candidate = CommandLine.valueAfterOffset(CommandLine.lyrics_test_flag, 2, &artist_buffer) orelse "";
    const title = if (std.mem.eql(u8, title_candidate, "--lyrics-verbose")) "" else title_candidate;
    const artist = if (std.mem.eql(u8, artist_candidate, "--lyrics-verbose")) "" else artist_candidate;
    logFormatted("lyrics test: title=\"{s}\" artist=\"{s}\"", .{ title, artist });
    if (title.len == 0) {
        Log.logAndPrint("lyrics test: no title given; use --lyrics-test <title> [artist]");
        return 2;
    }

    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (com_result < 0 and com_result != rpc_e_changed_mode) return 1;
    defer if (com_result >= 0) CoUninitialize();

    const started = GetTickCount64();
    var lyrics = Lyrics.Lyrics{};
    var report = Lyrics.LyricsFetchReport{};
    var reason: [384]u8 = @splat(0);
    const ok = Lyrics.fetchLyricsVerbose(title, artist, 10_000, &lyrics, &reason, &report);
    const elapsed = GetTickCount64() - started;
    if (verbose) {
        dumpLyricAttempt("netease", &report.netease);
        dumpLyricAttempt("qq", &report.qq);
    }
    if (!ok) {
        logFormatted("lyrics test: FAILED after {d} ms -- {s}", .{ elapsed, if (reason[0] != 0) std.mem.sliceTo(&reason, 0) else "no reason recorded" });
        return 1;
    }

    logFormatted("lyrics test: OK in {d} ms, {d} lines, [ti:]={s} [ar:]={s}", .{
        elapsed,
        lyrics.count,
        std.mem.sliceTo(&lyrics.title, 0),
        std.mem.sliceTo(&lyrics.artist, 0),
    });
    for (lyrics.lines[0..@min(lyrics.count, 6)]) |line| {
        const time_ms = line.time_ms;
        var line_text: [320]u8 = undefined;
        const formatted = std.fmt.bufPrint(&line_text, "  [{d:0>2}:{d:0>2}.{d:0>3}] {s}", .{
            @divTrunc(time_ms, 60_000),
            @mod(@divTrunc(time_ms, 1000), 60),
            @mod(time_ms, 1000),
            std.mem.sliceTo(&line.text, 0),
        }) catch continue;
        Log.logAndPrint(formatted);
    }
    if (lyrics.count > 6) logFormatted("  ... and {d} more", .{lyrics.count - 6});
    if (lyrics.count > 0) {
        const probe = @divTrunc(lyrics.lines[lyrics.count - 1].time_ms, 3);
        const at = lyrics.lineAt(probe);
        if (at) |index| {
            logFormatted("  at {d} ms the strip shows: {s}", .{ probe, std.mem.sliceTo(&lyrics.lines[index].text, 0) });
        } else {
            logFormatted("  at {d} ms the strip shows: (nothing)", .{probe});
        }
    }
    return 0;
}

fn dumpLyricAttempt(name: []const u8, attempt: *const Lyrics.FetchAttempt) void {
    logFormatted("  {s} search: HTTP {d}  {s}", .{ name, attempt.search_status, std.mem.sliceTo(&attempt.search_url, 0) });
    if (attempt.search_body[0] != 0) logFormatted("    <- {s}", .{std.mem.sliceTo(&attempt.search_body, 0)[0..@min(400, std.mem.sliceTo(&attempt.search_body, 0).len)]});
    logFormatted("  {s} lyric : HTTP {d}  {s}", .{ name, attempt.lyric_status, std.mem.sliceTo(&attempt.lyric_url, 0) });
    if (attempt.lyric_body[0] != 0) logFormatted("    <- {s}", .{std.mem.sliceTo(&attempt.lyric_body, 0)[0..@min(400, std.mem.sliceTo(&attempt.lyric_body, 0).len)]});
    logFormatted("  {s} verdict: {s}", .{ name, if (attempt.verdict[0] != 0) std.mem.sliceTo(&attempt.verdict, 0) else "(nothing recorded)" });
}

const PaintContext = struct {
    renderer: *Renderer.DeviceResources,
    text_renderer: *TextRenderer.TextRenderer,
    pill: Renderer.PillAppearance,
    clock_style: TextRenderer.ClockStyle = .compact,
    motion: Motion.Motion = .{},
    window: ?*IslandWindow.NativeWindow = null,
    window_x: i32 = 0,
    window_y: i32 = 0,
    scale: f32 = 1,
    last_tick_ms: u64 = 0,
    last_clock_second: u16 = std.math.maxInt(u16),
    task_windows: WindowList.WindowList = .{},
    task_last_refresh_ms: u64 = 0,
    task_buttons: [Renderer.max_task_buttons]TextRenderer.TaskButton = @splat(.{}),
    task_button_appear: [Renderer.max_task_buttons]f32 = @splat(1),
    task_hover_amount: [Renderer.max_task_buttons]f32 = @splat(0),
    task_hover_velocity: [Renderer.max_task_buttons]f32 = @splat(0),
    task_hovered_index: i32 = -1,
    thumbnail_preview: ?*ThumbnailPreview.ThumbnailPreview = null,
    thumbnail_target: HWND = null,
    thumbnail_target_since_ms: u64 = 0,
    thumbnail_reported_refusals: i32 = 0,
    music_session: ?*MusicSession.MusicSession = null,
    audio_volume: ?*AudioVolume.AudioVolume = null,
    status_reader: ?*SystemStatus.SystemStatusReader = null,
    monitor: Monitor.HMONITOR = null,
    monitor_bounds: Monitor.Rect = .{},
    monitor_work: Monitor.Rect = .{},
    app_bar: ?*AppBar.AppBar = null,
    app_bar_reclaim: bool = false,
    bar_thickness_px: i32 = 0,
    fullscreen_app: bool = false,
    fullscreen_last_poll_ms: u64 = 0,
    fullscreen_disabled: bool = false,
    status_strip_opacity: f32 = 0,
    status_strip_animating: bool = false,
    last_weather_revision: u64 = 0,
    music_wave_phase: f32 = 0,
    music_wave_accent: WicImage.AccentColour = .{},
    last_wave_artwork_revision: u64 = std.math.maxInt(u64),
    music_meter_redraw_ms: u64 = 0,
    system_status: SystemStatus.SystemStatus = .{},
    status_sampled_ms: u64 = 0,
    installed_layout_count: i32 = 0,
    volume_level: f32 = 0,
    volume_muted: bool = false,
    brightness_available: bool = false,
    brightness_percent: i32 = 50,
    system_panel_page: i32 = 0,
    system_panel_pinned: bool = false,
    card_owner: Renderer.CardOwner = .none,
    panel_level: CardLayout.PanelLevel = .tiles,
    card_hang: TaskStripLayout.CardHang = .system_button,
    forced_state: ?Motion.IslandState = null,
    system_panel_text: TextRenderer.SystemPanelText = .{},
    tray_icons: ?*TrayIcons.TrayIcons = null,
    tray_page_open: bool = false,
    tray_page_icons: [TextRenderer.tray_icon_count_max]TextRenderer.TrayIcon = @splat(.{}),
    tray_page_icon_count: usize = 0,
    tray_page_revision: u64 = 0,
    tray_hovered_index: i32 = -1,
    tray_last_refresh_ms: u64 = 0,
    tray_menu_open: bool = false,
    tray_menu_cell: i32 = -1,
    tray_menu_actions: [CardLayout.max_tray_menu_entries]CardLayout.TrayMenuAction = @splat(.open),
    tray_menu_action_count: usize = 0,
    tray_menu_layout: CardLayout.TrayMenuLayout = .{},
    tray_menu_hovered: i32 = -1,
    tray_quit_armed: bool = false,
    start_apps: ?*StartApps.StartApps = null,
    start_page_open: bool = false,
    start_page_state: i32 = 0,
    start_picker_scroll_row: i32 = 0,
    start_power_confirm_row: i32 = -1,
    start_hovered_pin: i32 = -1,
    start_hovered_picker_row: i32 = -1,
    start_hovered_power_row: i32 = -1,
    start_power_hovered: bool = false,
    start_button_wash: f32 = 0,
    start_button_velocity: f32 = 0,
    system_button_wash: f32 = 0,
    system_button_velocity: f32 = 0,
    tray_button_wash: f32 = 0,
    tray_button_velocity: f32 = 0,
    forced_start_hover: bool = false,
    start_pin_icons: [18]?[]const u8 = @splat(null),
    start_pin_icon_sizes: [18]usize = @splat(0),
    start_pin_icon_data: []u8 = &.{},
    start_card_text: TextRenderer.StartCardText = .{},
    last_start_icon_revision: u64 = 0,
    account_name: [256]u16 = @splat(0),
    sound_output: ?*SoundOutput.SoundOutput = null,
    sound_snapshot: SoundOutput.Snapshot = .{},
    last_sound_revision: u64 = 0,
    sound_page_open: bool = false,
    sound_page_scroll: f32 = 0,
    sound_page_text: TextRenderer.SoundPageText = .{},
    mixer_drag_row: i32 = -1,
    mixer_drag_pid: u32 = 0,
    pending_press_point: ?IslandWindow.Point = null,
    input_language_label: [8]u16 = @splat(0),
    battery_label: [8]u16 = @splat(0),
    theme_name: [33]u16 = @splat(0),
    lyrics_provider: ?*Lyrics.LyricsProvider = null,
    player_window: ?*PlayerWindow.PlayerWindowWatch = null,
    notification_server: ?*NotificationPipe.NotificationServer = null,
    notifications: ?*Notification.Store = null,
    notification_shown: Notification.Notification = .{},
    have_notification_shown: bool = false,
    wechat: WeChatWatch.WeChatWatcher = .{},
    wechat_last_poll_ms: u64 = 0,
    wechat_last_sound_poll_ms: u64 = 0,
    call_meter_redraw_ms: u64 = 0,
    call_icon_pid: DWORD = 0,
    call_icon_revision: u64 = 0,
    call_icon_width: i32 = 0,
    call_icon_height: i32 = 0,
    call_icon_size: usize = 0,
    call_icon_pixels: [128 * 128 * 4]u8 = @splat(0),
    notification_icon_notification_id: i64 = 0,
    notification_icon_revision: u64 = 0,
    notification_icon_width: i32 = 0,
    notification_icon_height: i32 = 0,
    notification_icon_size: usize = 0,
    notification_icon_pixels: [128 * 128 * 4]u8 = @splat(0),
    music_snapshot: MusicSession.MusicInfo = .{},
    player_snapshot: PlayerWindow.PlayerWindowInfo = .{},
    last_music_revision: u64 = 0,
    last_player_revision: i64 = 0,
    last_lyrics_revision: u64 = 0,
    last_music_reading_ms: u64 = 0,
    track_stopwatch_ms: i64 = 0,
    active_title: [MusicSession.title_capacity]u8 = @splat(0),
    active_artist: [MusicSession.artist_capacity]u8 = @splat(0),
    active_present: bool = false,
    active_playing: bool = false,
    active_from_session: bool = false,
    active_position_ms: i64 = 0,
    music_card_text: TextRenderer.MusicCardText = .{},
    music_background_png: [MusicSession.artwork_capacity]u8 = @splat(0),
    music_background_png_size: usize = 0,
    music_background_revision: u64 = 0,
    last_music_card_second: i64 = -1,
    requested_title: [256]u8 = @splat(0),
    requested_artist: [256]u8 = @splat(0),
    current_lyric_line: Lyrics.LyricLine = .{},
    shown_lyric_text: [Lyrics.line_capacity]u8 = @splat(0),
    replaced_lyric_text: [Lyrics.line_capacity]u8 = @splat(0),
    lyric_line_age_seconds: f32 = 1,
    lyric_scroll_dip: f32 = 0,
    replaced_lyric_scroll_dip: f32 = 0,
};

const animation_poll_ms: u32 = 16;
const music_poll_ms: u32 = 33;
const call_poll_ms: u32 = 50;
const idle_poll_ms: u32 = 100;

fn pointerPollIntervalFor(animation_active: bool, call_active: bool, music_active: bool) u32 {
    if (animation_active) return animation_poll_ms;
    if (call_active) return call_poll_ms;
    if (music_active) return music_poll_ms;
    return idle_poll_ms;
}

fn framePacingPolicyCheck() bool {
    return pointerPollIntervalFor(true, true, true) == animation_poll_ms and
        pointerPollIntervalFor(false, true, true) == call_poll_ms and
        pointerPollIntervalFor(false, false, true) == music_poll_ms and
        pointerPollIntervalFor(false, false, false) == idle_poll_ms;
}

const MediaSourceAvailability = struct {
    session: bool,
    player_window: bool,
};

fn mediaSourceAvailabilityFor(no_media: bool, no_session: bool) MediaSourceAvailability {
    return .{
        .session = !no_media and !no_session,
        .player_window = !no_media,
    };
}

fn mediaSourcePolicyCheck() bool {
    const normal = mediaSourceAvailabilityFor(false, false);
    const no_media = mediaSourceAvailabilityFor(true, false);
    const no_session = mediaSourceAvailabilityFor(false, true);
    return normal.session and normal.player_window and
        !no_media.session and !no_media.player_window and
        !no_session.session and no_session.player_window;
}

fn cardTransitionPolicyCheck() bool {
    const owner_open = Renderer.nextCardOwner(.none, true, true, true, false, true);
    const level_open = CardLayout.nextPanelLevel(.tiles, true, true, true, false, false);
    const owner_closing = Renderer.nextCardOwner(owner_open, true, false, false, false, true);
    const level_closing = CardLayout.nextPanelLevel(level_open, true, false, false, false, false);
    const owner_closed = Renderer.nextCardOwner(owner_closing, false, false, false, false, true);
    const level_closed = CardLayout.nextPanelLevel(level_closing, false, false, false, false, false);
    return owner_open == .system_panel and level_open == .tray and
        owner_closing == .system_panel and level_closing == .tray and
        owner_closed == .none and level_closed == .tiles;
}

fn cardAnchorPolicyCheck() bool {
    var renderer = Renderer.DeviceResources{};
    var text_renderer = TextRenderer.TextRenderer{};
    var context = PaintContext{ .renderer = &renderer, .text_renderer = &text_renderer, .pill = .{} };
    const previous_width = window_width_px;
    defer window_width_px = previous_width;
    window_width_px = 2560;
    context.scale = 1;
    context.motion.setAnchor(Motion.anchorForWindow(0, 0, 2560, 0));
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    const system = systemPanelCardBox(&context);
    const system_centre = TaskStripLayout.deckCardAnchorCentre(resting, .system_button);
    if (@abs((system.rect.left + system.rect.right) * 0.5 - system_centre) > 0.01) return false;

    context.card_hang = .tray_button;
    const tray = systemPanelCardBox(&context);
    const tray_centre = TaskStripLayout.deckCardAnchorCentre(resting, .tray_button);
    if (@abs((tray.rect.left + tray.rect.right) * 0.5 - tray_centre) > 0.01) return false;
    context.card_hang = .start_button;
    const start = systemPanelCardBox(&context);
    const start_centre = TaskStripLayout.deckCardAnchorCentre(resting, .start_button);
    if (@abs((start.rect.left + start.rect.right) * 0.5 - start_centre) > 0.01) return false;

    context.card_hang = .tray_button;
    context.tray_page_open = false;
    const closing_tray = systemPanelCardBox(&context);
    return @abs(closing_tray.rect.left - tray.rect.left) < 0.01 and
        @abs((closing_tray.rect.left + closing_tray.rect.right) * 0.5 - tray_centre) < 0.01;
}

fn paintWindow(window: HWND, context: ?*anyopaque) callconv(.winapi) void {
    const opaque_context = context orelse {
        paintClock(window);
        return;
    };
    const paint_context: *PaintContext = @ptrCast(@alignCast(opaque_context));
    var paint: PaintStruct = undefined;
    if (BeginPaint(window, &paint) == null) return;
    var weather_reading = Weather.Reading{ .temperature_c = 0, .weather_code = -1 };
    weather_reading.valid = weather_reader.get(&weather_reading.temperature_c, &weather_reading.weather_code);
    var status_sky: [32]u16 = @splat(0);
    var status_temperature: [32]u16 = @splat(0);
    if (weather_reading.valid) Weather.weatherPiecesFor(weather_reading.temperature_c, weather_reading.weather_code, &status_sky, &status_temperature);
    var pill = paint_context.pill;
    pill.box = paint_context.motion.current();
    const now = GetTickCount64();
    const active_notification = activeNotification(paint_context, now);
    const outer_card_up = paint_context.motion.target() == .expanded or paint_context.motion.visibleFromState() == .expanded;
    const panel_wanted = paint_context.system_panel_pinned or paint_context.sound_page_open or
        paint_context.start_page_open or paint_context.tray_page_open;
    paint_context.panel_level = CardLayout.nextPanelLevel(
        paint_context.panel_level,
        outer_card_up,
        panel_wanted,
        paint_context.tray_page_open,
        paint_context.sound_page_open,
        paint_context.start_page_open,
    );
    paint_context.card_owner = Renderer.nextCardOwner(
        paint_context.card_owner,
        outer_card_up,
        paint_context.motion.target() == .expanded,
        panel_wanted,
        active_notification != null,
        paint_context.active_present,
    );
    if (paint_context.card_owner == .notification) {
        if (active_notification) |notification| {
            paint_context.notification_shown = notification.*;
            paint_context.have_notification_shown = true;
        }
    } else {
        paint_context.have_notification_shown = false;
    }
    const resting_state: Motion.IslandState = if (paint_context.active_present) .music_strip else .collapsed;
    pill.resting_pill = Motion.boxForState(resting_state, paint_context.motion.anchor);
    pill.resting_state = resting_state;
    pill.music_present = paint_context.active_present;
    pill.music_wave_phase = paint_context.music_wave_phase;
    pill.music_accent = .{ .r = paint_context.music_wave_accent.r, .g = paint_context.music_wave_accent.g, .b = paint_context.music_wave_accent.b, .a = 1 };
    pill.music_level = 0;
    pill.music_level_known = if (paint_context.audio_volume) |volume| volume.peak(&pill.music_level) else false;
    pill.lyric_scroll_dip = paint_context.lyric_scroll_dip;
    pill.lyric_line_roll = Lyrics.lyricLineRollFor(paint_context.lyric_line_age_seconds);
    pill.lyric_line_prev = std.mem.sliceTo(&paint_context.replaced_lyric_text, 0);
    pill.lyric_line_prev_scroll_dip = paint_context.replaced_lyric_scroll_dip;
    pill.fullscreen_app = paint_context.fullscreen_app;
    pill.status_sky = std.mem.sliceTo(&status_sky, 0);
    pill.status_temperature = std.mem.sliceTo(&status_temperature, 0);
    pill.status_code = if (weather_reading.valid) weather_reading.weather_code else -1;
    pill.status_strip_opacity = paint_context.status_strip_opacity;
    if (active_notification) |notification| {
        pill.notification = notification;
        pill.box = Motion.boxForState(.notice_strip, paint_context.motion.anchor);
        if (notification.id == paint_context.wechat.call_notification_id) {
            pill.call_up = true;
            const process_id = paint_context.wechat.call_pid;
            if (process_id != paint_context.call_icon_pid) {
                paint_context.call_icon_pid = process_id;
                paint_context.call_icon_revision +%= 1;
                paint_context.call_icon_size = 0;
                paint_context.call_icon_width = 0;
                paint_context.call_icon_height = 0;
                if (processImagePath(process_id)) |icon_source| {
                    if (NotificationIcon.loadNotificationIconPixels(
                        &icon_source,
                        &paint_context.call_icon_pixels,
                        &paint_context.call_icon_width,
                        &paint_context.call_icon_height,
                    )) |byte_count| {
                        paint_context.call_icon_size = byte_count;
                        maskCircularIcon(paint_context.call_icon_pixels[0..byte_count], paint_context.call_icon_width, paint_context.call_icon_height);
                    }
                }
            }
            const elapsed_seconds = if (now >= paint_context.wechat.call_start_ms)
                @min((now - paint_context.wechat.call_start_ms) / 1000, std.math.maxInt(i32))
            else
                0;
            var level: f32 = 0;
            var level_known = false;
            if (paint_context.audio_volume) |volume| level_known = volume.peak(&level);
            pill.call_strip = .{
                .seconds = @intCast(elapsed_seconds),
                .level = level,
                .level_known = level_known,
                .icon_pixels = if (paint_context.call_icon_size == 0) null else paint_context.call_icon_pixels[0..paint_context.call_icon_size],
                .icon_width = paint_context.call_icon_width,
                .icon_height = paint_context.call_icon_height,
                .icon_revision = paint_context.call_icon_revision,
            };
        }
        if (paint_context.notification_icon_notification_id != notification.id) {
            paint_context.notification_icon_notification_id = notification.id;
            paint_context.notification_icon_revision +%= 1;
            paint_context.notification_icon_size = 0;
            paint_context.notification_icon_width = 0;
            paint_context.notification_icon_height = 0;
            var icon_source: [260]u16 = @splat(0);
            if (NotificationIcon.notificationIconSource(notification, &icon_source)) {
                if (NotificationIcon.loadNotificationIconPixels(
                    &icon_source,
                    &paint_context.notification_icon_pixels,
                    &paint_context.notification_icon_width,
                    &paint_context.notification_icon_height,
                )) |byte_count| {
                    paint_context.notification_icon_size = byte_count;
                }
            }
        }
        const message = if (notification.title[0] != 0)
            std.mem.sliceTo(&notification.title, 0)
        else
            std.mem.sliceTo(&notification.body, 0);
        pill.music_text = message;
    } else if (paint_context.active_present) {
        const lyric = std.mem.sliceTo(&paint_context.shown_lyric_text, 0);
        pill.music_text = if (lyric.len != 0) lyric else std.mem.sliceTo(&paint_context.active_title, 0);
    }
    if ((active_notification != null or (paint_context.card_owner == .notification and paint_context.have_notification_shown)) and
        paint_context.notification_icon_size != 0)
    {
        pill.notification_icon_pixels = paint_context.notification_icon_pixels[0..paint_context.notification_icon_size];
        pill.notification_icon_width = paint_context.notification_icon_width;
        pill.notification_icon_height = paint_context.notification_icon_height;
        pill.notification_icon_revision = paint_context.notification_icon_revision;
    }
    const notice_active = active_notification != null;
    if (outer_card_up) {
        const reveal = Motion.outerCardRevealDip(Geometry.height(paint_context.motion.current().rect));
        switch (paint_context.card_owner) {
            .none => {},
            .notification => {
                if (!notice_active) pill.box = Motion.boxForState(.collapsed, paint_context.motion.anchor);
                pill.card_notification = if (paint_context.have_notification_shown) &paint_context.notification_shown else null;
                pill.notification_card_box = notificationCardBox(paint_context);
                pill.notification_card_reveal = reveal;
            },
            .music => {
                pill.box = paint_context.motion.current();
                pill.music_card = &paint_context.music_card_text;
            },
            .system_panel => {
                pill.box = if (notice_active)
                    Motion.boxForState(.notice_strip, paint_context.motion.anchor)
                else
                    Motion.boxForState(.collapsed, paint_context.motion.anchor);
                const card = systemPanelCardBox(paint_context);
                switch (paint_context.panel_level) {
                    .sound => {
                        pill.sound_page = &paint_context.sound_page_text;
                        pill.sound_page_box = card;
                        pill.sound_page_reveal = reveal;
                    },
                    .start => {
                        pill.start_page = &paint_context.start_card_text;
                        pill.start_page_box = card;
                        pill.start_page_reveal = reveal;
                    },
                    .tray => {
                        pill.tray_page_open = true;
                        pill.tray_page_title = wide_tray_page;
                        pill.tray_page_icons = paint_context.tray_page_icons[0..paint_context.tray_page_icon_count];
                        pill.tray_page_revision = paint_context.tray_page_revision;
                        pill.tray_page_hovered_index = paint_context.tray_hovered_index;
                        pill.system_panel_box = card;
                        pill.system_panel_reveal = reveal;
                        pill.tray_menu_open = paint_context.tray_menu_open;
                        pill.tray_menu_rows = paint_context.tray_menu_layout.rows;
                        pill.tray_menu_row_count = paint_context.tray_menu_action_count;
                        pill.tray_menu_hovered = paint_context.tray_menu_hovered;
                        for (0..paint_context.tray_menu_action_count) |index| {
                            const action = paint_context.tray_menu_actions[index];
                            pill.tray_menu_labels[index] = if (paint_context.tray_quit_armed and action == .quit_application)
                                CardLayout.trayMenuArmedLabel(action).ptr
                            else
                                CardLayout.trayMenuLabel(action).ptr;
                        }
                    },
                    .tiles => {
                        pill.system_panel = &paint_context.system_panel_text;
                        pill.system_panel_box = card;
                        pill.system_panel_reveal = reveal;
                    },
                }
            },
        }
    }
    const task_count = taskButtonCount(paint_context);
    @memset(&paint_context.task_buttons, .{});
    for (paint_context.task_windows.entries[0..task_count], 0..) |*entry, index| {
        paint_context.task_buttons[index] = .{
            .title = @ptrCast(&entry.title),
            .window = entry.handle,
            .active = entry.handle == paint_context.task_windows.foreground,
            .minimised = entry.iconic,
            .fill = pill.fill,
            .hover_amount = paint_context.task_hover_amount[index],
        };
        paint_context.task_button_appear[index] = 1;
    }
    const resting_deck = Motion.boxForState(.collapsed, paint_context.motion.anchor);
    const deck_island = Motion.rowAnchorBox(pill.box, resting_deck);
    const tray_visible = if (paint_context.tray_icons) |icons| icons.count() > 0 else false;
    pill.deck_box = deck_island;
    const active_theme = Theme.currentTheme();
    pill.fill = .{ active_theme.pill_bottom.r, active_theme.pill_bottom.g, active_theme.pill_bottom.b, active_theme.pill_bottom.a };
    pill.surface_box = TaskStripLayout.barClusterFor(deck_island, tray_visible);
    if (paint_context.fullscreen_app) {
        pill.surface_box = if (notice_active) pill.box else null;
        if (!notice_active) pill.opacity = 0;
    }
    pill.start_hover = paint_context.start_button_wash;
    const panel_controls_lit = CardLayout.controlLitFor(paint_context.panel_level, outer_card_up and paint_context.card_owner == .system_panel);
    pill.start_open = panel_controls_lit.start;
    pill.system_hover = paint_context.system_button_wash;
    pill.system_open = panel_controls_lit.system;
    pill.tray_visible = tray_visible;
    pill.tray_hover = paint_context.tray_button_wash;
    pill.tray_open = panel_controls_lit.tray;
    pill.task_island = TaskStripLayout.rowAnchorWithTray(deck_island, tray_visible);
    pill.task_buttons = paint_context.task_buttons[0..task_count];
    pill.task_button_appear = paint_context.task_button_appear[0..task_count];
    pill.task_hovered_index = paint_context.task_hovered_index;
    if (outer_card_up and paint_context.card_owner == .system_panel) {
        const card = systemPanelCardBox(paint_context);
        pill.task_card_left_dip = card.rect.left;
        pill.task_card_width_dip = Geometry.width(card.rect);
    } else {
        pill.task_card_left_dip = 0;
        pill.task_card_width_dip = 0;
    }
    _ = paint_context.renderer.renderPill(pill, paint_context.text_renderer, .compact, weather_reading);
    _ = EndPaint(window, &paint);
    _ = updateInputRegion(paint_context);
    if (paint_context.motion.isAnimating()) _ = paint_context.renderer.waitForCompositorClock(8);
}

fn taskButtonCount(context: *const PaintContext) usize {
    const monitor_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01);
    return TaskStripLayout.taskIconsThatFitForMonitor(monitor_width_dip, context.task_windows.count);
}

fn updateTaskThumbnailPreview(context: *PaintContext, island: Geometry.RoundedBox, count: usize, now: u64) void {
    const preview = context.thumbnail_preview orelse return;
    const index = context.task_hovered_index;
    const wanted = if (index >= 0 and @as(usize, @intCast(index)) < count)
        context.task_windows.entries[@intCast(index)].handle
    else
        null;
    if (wanted != context.thumbnail_target) {
        context.thumbnail_target = wanted;
        context.thumbnail_target_since_ms = now;
    }
    const rested = wanted != null and now -| context.thumbnail_target_since_ms >= 350;
    const follow = wanted != null and preview.visible;
    const card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    var shown = false;
    if ((rested or follow) and !card_up and !context.fullscreen_app and wanted != null) {
        const target = wanted.?;
        if (IsWindow(target) != 0) {
            const monitor = context.monitor_bounds;
            const button = TaskStripLayout.taskIconButtonAtAmounts(island, @intCast(index), count, &context.task_hover_amount, 0, 0);
            const icon_px = ThumbnailPreview.Rect{
                .left = monitor.left + @as(i32, @intFromFloat(@round(button.left * context.scale))),
                .top = monitor.top + @as(i32, @intFromFloat(@round(button.top * context.scale))),
                .right = monitor.left + @as(i32, @intFromFloat(@round(button.right * context.scale))),
                .bottom = monitor.top + @as(i32, @intFromFloat(@round(button.bottom * context.scale))),
            };
            const source_size = preview.begin(target);
            const placement = ThumbnailPreview.thumbnailBoxFor(
                source_size.cx,
                source_size.cy,
                icon_px,
                .{ .left = monitor.left, .top = monitor.top, .right = monitor.right, .bottom = monitor.bottom },
                context.scale,
            );
            shown = placement.valid and preview.place(&placement);
            if (preview.refusals != context.thumbnail_reported_refusals) {
                context.thumbnail_reported_refusals = preview.refusals;
                logFormatted("thumbnail: compositor refused task window (HRESULT=0x{x})", .{@as(u64, @bitCast(preview.last_result))});
            }
        }
    }
    if (!shown) preview.hide();
}

fn pointInBox(box: Geometry.RoundedBox, x: f32, y: f32) bool {
    return Geometry.containsWithTolerance(box, x, y, Geometry.hit_tolerance_dip);
}

fn notificationCardBox(context: *const PaintContext) Geometry.RoundedBox {
    const screen_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01);
    const left = std.math.clamp(context.motion.anchor.center_x - Motion.expanded_width_dip * 0.5, 0, @max(0, screen_width_dip - Motion.expanded_width_dip));
    const strip = Motion.boxForState(.notice_strip, context.motion.anchor);
    return Motion.placedCardFor(strip, left);
}

fn systemPanelCardBox(context: *const PaintContext) Geometry.RoundedBox {
    const screen_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01);
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    const hang: TaskStripLayout.CardHang = if (context.start_page_open)
        .start_button
    else if (context.tray_page_open)
        .tray_button
    else
        context.card_hang;
    const centre = TaskStripLayout.deckCardAnchorCentre(resting, hang);
    const left = CardLayout.cardLeftFor(centre - Motion.expanded_width_dip * 0.5, Motion.expanded_width_dip, screen_width_dip);
    return Motion.placedCardFor(resting, left);
}

fn updateInputRegion(context: *PaintContext) bool {
    const window = context.window orelse return false;
    const card_up = (context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded) and context.card_owner != .none;
    const card = switch (context.card_owner) {
        .notification => notificationCardBox(context),
        .music => Motion.placedCardFor(Motion.boxForState(.collapsed, context.motion.anchor), CardLayout.cardLeftFor(
            context.motion.anchor.center_x - Motion.expanded_width_dip * 0.5,
            Motion.expanded_width_dip,
            @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01),
        )),
        .none, .system_panel => systemPanelCardBox(context),
    };
    const tray_count: i32 = if (context.tray_icons) |icons| @intCast(icons.count()) else 0;
    const region = InputRegion.forFrame(.{
        .monitor_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01),
        .dpi = @intFromFloat(context.scale * Geometry.dip_per_inch),
        .state = context.motion.target(),
        .anchor = context.motion.anchor,
        .current = context.motion.current(),
        .card_up = card_up,
        .card_left_dip = if (card_up) card.rect.left else 0,
        .task_icon_count = @intCast(taskButtonCount(context)),
        .status_strip_width_dip = if (context.status_strip_opacity > 0.001) TaskStripLayout.status_strip_width_dip else 0,
        .tray_icon_count = tray_count,
    });
    const ok = window.setInputRegion(.{ .left = region.left, .top = region.top, .right = region.right, .bottom = region.bottom });
    if (!ok) Log.logLine("window input region could not be updated");
    return ok;
}

fn sampleSystemStatus(context: *PaintContext, now: u64) bool {
    var refreshed = false;
    if (SystemToggles.takeRadioOutcome()) |outcome| {
        const verdict = if (outcome.succeeded) "as asked" else "NOT as asked";
        const refused = if (outcome.hresult != 0) " (radio call refused or failed)" else "";
        if (outcome.wifi_asked and outcome.bluetooth_asked) {
            logFormatted("radios: Wi-Fi {s}, Bluetooth {s} -- {s}{s}", .{ if (outcome.wifi_now) "on" else "off", if (outcome.bluetooth_now) "on" else "off", verdict, refused });
        } else if (outcome.wifi_asked) {
            logFormatted("radios: Wi-Fi {s} -- {s}{s}", .{ if (outcome.wifi_now) "on" else "off", verdict, refused });
        } else {
            logFormatted("radios: Bluetooth {s} -- {s}{s}", .{ if (outcome.bluetooth_now) "on" else "off", verdict, refused });
        }
        if (context.status_reader) |reader| reader.sample(&context.system_status);
        context.status_sampled_ms = GetTickCount64();
        refreshed = true;
    }
    if (SystemToggles.takeNightLightOutcome()) |outcome| {
        logFormatted("night light: asked for {s}; it is now {s} ({s})", .{ if (outcome.wanted) "on" else "off", if (outcome.state_after) "on" else "off", if (outcome.state_after == outcome.wanted and outcome.succeeded) "it took" else "IT DID NOT CHANGE" });
        if (context.status_reader) |reader| reader.sample(&context.system_status);
        context.status_sampled_ms = GetTickCount64();
        refreshed = true;
    }
    if (context.status_sampled_ms == 0 or now -| context.status_sampled_ms >= 2000) {
        if (context.status_reader) |reader| {
            reader.sample(&context.system_status);
            context.installed_layout_count = reader.layoutCount();
        }
        context.brightness_available = DisplayBrightness.readBrightnessPercent(context.monitor, &context.brightness_percent);
        context.status_sampled_ms = now;
        refreshed = true;
    }
    if (context.audio_volume) |volume| {
        var level = context.volume_level;
        if (volume.get(&level)) context.volume_level = level;
        context.volume_muted = volume.isMuted();
    }
    if (context.sound_output) |sound| {
        const revision = sound.revision();
        if (revision != context.last_sound_revision) {
            context.last_sound_revision = revision;
            context.sound_snapshot = sound.snapshot();
            refreshed = true;
        }
    }
    context.system_status.volume_percent = @intFromFloat(@round(context.volume_level * 100));
    context.system_status.muted = context.volume_muted;
    buildSystemPanelText(context);
    buildSoundPageText(context);
    return refreshed;
}

fn handleSystemPanelClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const hit = CardLayout.systemPanelHitFor(
        systemPanelCardBox(context),
        @intCast(context.system_panel_text.tile_count),
        if (context.brightness_available) 2 else 1,
        context.system_panel_text.page_index,
        context.system_panel_text.page_count,
        local_x,
        local_y,
    );
    switch (hit.target) {
        .page_up => context.system_panel_page = @mod(context.system_panel_page - 1 + context.system_panel_text.page_count, context.system_panel_text.page_count),
        .page_down => context.system_panel_page = @mod(context.system_panel_page + 1, context.system_panel_text.page_count),
        .speaker => if (context.audio_volume) |volume| volume.toggleMute(),
        .volume_device => {
            context.sound_page_open = true;
            context.tray_page_open = false;
            context.start_page_open = false;
            context.card_hang = .system_button;
            context.sound_page_scroll = 0;
        },
        .gear => _ = StartMenu.openUri(uri_settings),
        .slider => {
            if (hit.index == 0) {
                if (context.audio_volume) |volume| volume.setLevel(hit.fraction);
                context.volume_level = hit.fraction;
            } else if (hit.index == 1 and context.brightness_available) {
                var landed: i32 = context.brightness_percent;
                const wanted: i32 = @intFromFloat(@round(hit.fraction * 100));
                if (DisplayBrightness.setBrightnessPercent(context.monitor, wanted, &landed)) context.brightness_percent = landed;
            }
        },
        .tile => {
            if (hit.index < 0 or hit.index >= context.system_panel_text.tile_count) return false;
            const tile = context.system_panel_text.tiles[@intCast(hit.index)];
            switch (tile.action) {
                .open_settings => {
                    if (tile.uri) |uri| _ = StartMenu.openUri(uri);
                },
                .open_sound_page => {
                    context.sound_page_open = true;
                    context.tray_page_open = false;
                    context.start_page_open = false;
                    context.card_hang = .system_button;
                    context.sound_page_scroll = 0;
                },
                .open_tray_page => {
                    context.tray_page_open = true;
                    context.sound_page_open = false;
                    context.start_page_open = false;
                    context.card_hang = .tray_button;
                    if (context.tray_icons) |icons| {
                        _ = icons.refresh(std.heap.page_allocator);
                        context.tray_last_refresh_ms = GetTickCount64();
                    }
                    buildTrayPageText(context);
                },
                .open_start_page => {
                    context.start_page_open = true;
                    context.sound_page_open = false;
                    context.tray_page_open = false;
                    context.card_hang = .start_button;
                    context.start_page_state = 0;
                    context.start_power_confirm_row = -1;
                    if (context.start_apps) |apps| _ = apps.refreshList();
                    buildStartCardText(context);
                },
                .toggle_live_captions => logFormatted("live captions: Win+Ctrl+L queued={d}", .{@intFromBool(SystemToggles.toggleLiveCaptions())}),
                .cycle_theme => _ = Theme.cycleTheme(),
                .toggle_wifi => {
                    const on = !context.system_status.wifi_radio_on;
                    const started = SystemToggles.requestRadios(true, false, on);
                    logFormatted("Wi-Fi radio: asked to switch {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_bluetooth => {
                    const on = !context.system_status.bluetooth_on;
                    const started = SystemToggles.requestRadios(false, true, on);
                    logFormatted("Bluetooth radio: asked to switch {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_radio => {
                    const on = !(context.system_status.wifi_radio_on or context.system_status.bluetooth_on);
                    const started = SystemToggles.requestRadios(true, true, on);
                    logFormatted("airplane mode: asked for Wi-Fi and Bluetooth {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_night_light => {
                    const on = !context.system_status.night_light_on;
                    const started = SystemToggles.requestNightLight(on);
                    logFormatted("night light: asked to switch {s} through Settings; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .projection_modes => _ = StartMenu.sendWindowsKeyChord('P'),
                .toggle_mute => if (context.audio_volume) |volume| volume.toggleMute(),
                .none => return false,
            }
        },
        .none => return false,
    }
    _ = sampleSystemStatus(context, 0);
    buildSoundPageText(context);
    if (context.window) |window| window.invalidate();
    return true;
}

fn setMixerLevel(context: *PaintContext, row: i32, fraction_arg: f32) void {
    const fraction = std.math.clamp(fraction_arg, 0, 1);
    if (row == 0) {
        if (context.audio_volume) |volume| volume.setLevel(fraction);
        context.volume_level = fraction;
        context.mixer_drag_pid = 0;
    } else if (row > 0) {
        const session_index: usize = @intCast(row - 1);
        if (session_index >= context.sound_snapshot.session_count) return;
        const session = context.sound_snapshot.sessions[session_index];
        context.mixer_drag_pid = session.pid;
        if (context.sound_output) |sound| sound.setSessionVolume(session.pid, fraction);
    } else return;
    context.mixer_drag_row = row;
    buildSoundPageText(context);
}

fn handleSoundPageClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const card = systemPanelCardBox(context);
    const device_count: i32 = @intCast(context.sound_page_text.device_count);
    const mix_count: i32 = @intCast(context.sound_page_text.mix_count);
    const hit = CardLayout.soundPageHitFor(card, device_count, mix_count, context.sound_page_scroll, local_x, local_y);
    switch (hit.target) {
        .back => {
            context.sound_page_open = false;
            context.mixer_drag_row = -1;
        },
        .device => {
            if (hit.index >= 0 and @as(usize, @intCast(hit.index)) < context.sound_snapshot.device_count) {
                const device = &context.sound_snapshot.devices[@intCast(hit.index)];
                if (!device.is_default) {
                    if (context.sound_output) |sound| {
                        sound.setDefaultDevice(std.mem.sliceTo(&device.id, 0));
                        sound.refresh();
                    }
                }
            }
        },
        .spatial => logFormatted("sound page: spatial sound row {d} has no public read/write API", .{hit.index}),
        .mixer_slider => setMixerLevel(context, hit.index, hit.fraction),
        .mixer_gear, .footer => {
            _ = StartMenu.openUri(uri_sound);
            context.sound_page_open = false;
            context.mixer_drag_row = -1;
            _ = context.motion.setTarget(.collapsed);
        },
        .scrollbar => {
            const layout = CardLayout.soundPageFor(card, device_count, mix_count, context.sound_page_scroll);
            if (local_y < layout.scroll_thumb.top) context.sound_page_scroll -= 140 else if (local_y > layout.scroll_thumb.bottom) context.sound_page_scroll += 140;
            context.sound_page_scroll = std.math.clamp(context.sound_page_scroll, 0, CardLayout.soundPageScrollLimit(card, device_count, mix_count));
        },
        .none => return false,
    }
    buildSoundPageText(context);
    if (context.window) |window| window.invalidate();
    return true;
}

fn trayPressWorker(request: TrayPress.Request, right_click: bool) void {
    const com_result = CoInitializeEx(null, 0);
    const com_ok = com_result >= 0 or com_result == rpc_e_changed_mode;
    if (!com_ok) {
        Log.logLine("tray icon click: COM initialization failed");
        return;
    }
    defer if (com_result >= 0) CoUninitialize();
    const outcome = TrayPress.pressTrayIcon(&request, true, right_click);
    var line: [96]u8 = undefined;
    const message = std.fmt.bufPrint(&line, "tray icon click: {s}{s}", .{ @tagName(outcome.result), if (right_click) " (right click)" else "" }) catch "tray icon click finished";
    Log.logLine(message);
}

fn makeTrayPressRequest(icon: anytype, path: ?[]const u16) TrayPress.Request {
    var request = TrayPress.Request{
        .uid = icon.uid,
        .has_uid = icon.has_uid,
        .has_guid = icon.has_guid,
        .guid = .{ .data1 = icon.guid.data1, .data2 = icon.guid.data2, .data3 = icon.guid.data3, .data4 = icon.guid.data4 },
    };
    copyWide(&request.name, &icon.name);
    if (path) |value| copyWide(&request.exe_path, value);
    return request;
}

fn wideBasename(path_arg: []const u16) []const u16 {
    const path = std.mem.sliceTo(path_arg, 0);
    var offset: usize = 0;
    for (path, 0..) |unit, index| if (unit == '\\' or unit == '/') {
        offset = index + 1;
    };
    return path[offset..];
}

fn sameImageName(a_arg: []const u16, b_arg: []const u16) bool {
    const a = wideBasename(a_arg);
    const b = wideBasename(b_arg);
    if (a.len == 0 or a.len != b.len) return false;
    for (a, b) |left, right| {
        const lower_left = if (left >= 'A' and left <= 'Z') left + ('a' - 'A') else left;
        const lower_right = if (right >= 'A' and right <= 'Z') right + ('a' - 'A') else right;
        if (lower_left != lower_right) return false;
    }
    return true;
}

fn processImagePath(process_id: DWORD) ?[260]u16 {
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
    defer _ = CloseHandle(process);
    var path: [260]u16 = @splat(0);
    var length: DWORD = @intCast(path.len);
    if (QueryFullProcessImageNameW(process, 0, &path, &length) == 0 or length == 0) return null;
    path[@min(length, @as(DWORD, @intCast(path.len - 1)))] = 0;
    return path;
}

fn windowForImage(context: *PaintContext, image: []const u16) HWND {
    if (wideBasename(image).len == 0) return null;
    for (context.task_windows.entries[0..context.task_windows.count]) |entry| {
        const path = processImagePath(entry.process_id) orelse continue;
        if (sameImageName(&path, image)) return entry.handle;
    }
    return null;
}

fn trayMenuFactsFor(context: *PaintContext, cell: usize) CardLayout.TrayMenuFacts {
    const icons = context.tray_icons orelse return .{};
    if (cell >= icons.count()) return .{};
    const path = icons.exePathAt(cell) orelse return .{};
    const has_path = std.mem.sliceTo(path, 0).len != 0;
    if (!has_path) return .{};
    return .{ .has_exe_path = true, .has_window = windowForImage(context, path) != null };
}

fn terminateProcessesOfImage(image: []const u16) usize {
    if (wideBasename(image).len == 0) return 0;
    const snapshot = CreateToolhelp32Snapshot(th32cs_snapprocess, 0) orelse return 0;
    if (@intFromPtr(snapshot) == error_invalid_handle) return 0;
    defer _ = CloseHandle(snapshot);
    var entry = std.mem.zeroes(ProcessEntry32W);
    entry.size = @sizeOf(ProcessEntry32W);
    if (Process32FirstW(snapshot, &entry) == 0) return 0;
    var ended: usize = 0;
    while (true) {
        if (sameImageName(&entry.exe_file, image)) {
            if (OpenProcess(process_terminate, 0, entry.process_id)) |process| {
                if (TerminateProcess(process, 0) != 0) ended += 1;
                _ = CloseHandle(process);
            }
        }
        if (Process32NextW(snapshot, &entry) == 0) break;
    }
    return ended;
}

fn startTrayPress(context: *PaintContext, cell: usize, right_click: bool) void {
    const icons = context.tray_icons orelse return;
    const icon = icons.at(cell) orelse return;
    const request = makeTrayPressRequest(icon, icons.exePathAt(cell));
    if (std.Thread.spawn(.{}, trayPressWorker, .{ request, right_click })) |thread| {
        thread.detach();
    } else |_| {
        Log.logLine("tray icon click worker could not start");
    }
}

fn closeTrayMenu(context: *PaintContext) void {
    context.tray_menu_open = false;
    context.tray_menu_cell = -1;
    context.tray_menu_action_count = 0;
    context.tray_menu_hovered = -1;
    context.tray_quit_armed = false;
}

fn dismissSystemPanel(context: *PaintContext) void {
    context.system_panel_pinned = false;
    context.sound_page_open = false;
    context.start_page_open = false;
    context.tray_page_open = false;
    closeTrayMenu(context);
    context.mixer_drag_row = -1;
    context.mixer_drag_pid = 0;
    _ = context.motion.setTarget(if (context.active_present) .music_strip else .collapsed);
}

fn openTrayMenu(context: *PaintContext, cell: usize, card: Geometry.RoundedBox) bool {
    const icons = context.tray_icons orelse return false;
    if (cell >= icons.count()) return false;
    const page = CardLayout.trayPageFor(card, @intCast(context.tray_page_icon_count));
    if (cell >= @as(usize, @intCast(page.count))) return false;
    context.tray_menu_cell = @intCast(cell);
    context.tray_menu_action_count = CardLayout.trayMenuEntriesFor(trayMenuFactsFor(context, cell), &context.tray_menu_actions);
    const icon_cell = page.cells[cell];
    context.tray_menu_layout = CardLayout.trayMenuFor(card, icon_cell.right, icon_cell.bottom, @intCast(context.tray_menu_action_count));
    context.tray_menu_open = context.tray_menu_action_count != 0 and context.tray_menu_layout.count != 0;
    context.tray_menu_hovered = -1;
    context.tray_quit_armed = false;
    return context.tray_menu_open;
}

fn runTrayMenuAction(context: *PaintContext, action: CardLayout.TrayMenuAction) void {
    const icons = context.tray_icons orelse return;
    if (context.tray_menu_cell < 0 or @as(usize, @intCast(context.tray_menu_cell)) >= icons.count()) return;
    const cell: usize = @intCast(context.tray_menu_cell);
    const path = icons.exePathAt(cell) orelse &.{};
    const image = wideBasename(path);
    switch (action) {
        .open => startTrayPress(context, cell, false),
        .application_menu => startTrayPress(context, cell, true),
        .activate_window => {
            const target = windowForImage(context, image);
            const raised = if (target) |window| context.task_windows.activate(window) else false;
            logFormatted("tray menu: {s} -> {s}", .{ "activate window", if (raised) "brought forward" else "nothing to bring forward" });
        },
        .open_location => {
            if (image.len == 0) return;
            var arguments: [512]u16 = @splat(0);
            const prefix = [_]u16{ '/', 's', 'e', 'l', 'e', 'c', 't', ',', '"' };
            if (path.len + prefix.len + 2 > arguments.len) return;
            @memcpy(arguments[0..prefix.len], &prefix);
            @memcpy(arguments[prefix.len .. prefix.len + path.len], path);
            arguments[prefix.len + path.len] = '"';
            arguments[prefix.len + path.len + 1] = 0;
            _ = ShellExecuteW(null, wide_open_verb, wide_explorer, @ptrCast(&arguments), null, sw_show_normal);
            logFormatted("tray menu: opened the location of {s}", .{"the tray application"});
        },
        .close_window => {
            if (windowForImage(context, image) == null) return;
            var closed: usize = 0;
            for (context.task_windows.entries[0..context.task_windows.count]) |entry| {
                const process_path = processImagePath(entry.process_id) orelse continue;
                if (sameImageName(&process_path, image) and PostMessageW(entry.handle, wm_close, 0, 0) != 0) closed += 1;
            }
            logFormatted("tray menu: asked the application to close {d} window(s)", .{closed});
        },
        .quit_application => {
            const ended = terminateProcessesOfImage(image);
            logFormatted("tray menu: ended {d} process(es)", .{ended});
        },
    }
}

fn handleTrayPageClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const card = systemPanelCardBox(context);
    const index = CardLayout.trayPageCellAt(card, @intCast(context.tray_page_icon_count), local_x, local_y);
    if (index >= 0) {
        startTrayPress(context, @intCast(index), false);
        context.tray_page_open = false;
        context.tray_menu_open = false;
    } else if (local_y <= card.rect.top + 34 and local_x <= card.rect.left + 48) {
        context.tray_page_open = false;
        closeTrayMenu(context);
    } else {
        return false;
    }
    if (index >= 0) {
        dismissSystemPanel(context);
    }
    if (context.window) |window| window.invalidate();
    return true;
}

fn enableShutdownPrivilege() bool {
    var token: ?*anyopaque = null;
    if (OpenProcessToken(GetCurrentProcess(), 0x20 | 0x8, &token) == 0 or token == null) return false;
    defer _ = CloseHandle(token);
    var luid = Luid{};
    if (LookupPrivilegeValueW(null, shutdown_privilege, &luid) == 0) return false;
    var privileges = TokenPrivileges{ .count = 1 };
    privileges.privileges[0] = .{ .luid = luid, .attributes = 0x2 };
    return AdjustTokenPrivileges(token, 0, &privileges, 0, null, null) != 0;
}

fn runPowerAction(row: i32) bool {
    switch (row) {
        0 => {
            const ok = LockWorkStation() != 0;
            Log.logLine(if (ok) "power action: lock succeeded" else "power action: lock failed");
            return ok;
        },
        1 => {
            const ok = SetSuspendState(0, 1, 0) != 0;
            Log.logLine(if (ok) "power action: sleep succeeded" else "power action: sleep failed");
            return ok;
        },
        2 => {
            const ok = ExitWindowsEx(0x00000004 | 0x00000010, 0) != 0;
            Log.logLine(if (ok) "power action: sign out requested" else "power action: sign out failed");
            return ok;
        },
        3, 4 => {
            _ = enableShutdownPrivilege();
            const flags: u32 = if (row == 3) 0x00000002 | 0x00000010 else 0x00000001 | 0x00000010;
            const ok = ExitWindowsEx(flags, 0) != 0;
            Log.logLine(if (row == 3) (if (ok) "power action: restart requested" else "power action: restart failed") else if (ok) "power action: shutdown requested" else "power action: shutdown failed");
            return ok;
        },
        else => return false,
    }
}

fn handleStartPageClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const apps = context.start_apps orelse return false;
    const card = systemPanelCardBox(context);
    const layout = CardLayout.startPageFor(card);
    if (!layout.valid) return false;

    if (CardLayout.startRectHasPoint(layout.power_button, local_x, local_y)) {
        if (context.start_page_state == 1) {
            context.start_page_state = 0;
        } else {
            context.start_page_state = if (context.start_page_state == 2) 0 else 2;
        }
        context.start_power_confirm_row = -1;
    } else if (context.start_page_state == 0) {
        const pin_index = CardLayout.startPinCellAt(layout, @intCast(apps.pinCount()), local_x, local_y);
        if (pin_index >= 0) {
            if (apps.pinAt(@intCast(pin_index))) |app| {
                const launched = StartApps.launchStartApp(@ptrCast(&app.target));
                logFormatted("start page: launched pinned app; result={d}", .{@intFromBool(launched)});
            }
            context.start_page_open = false;
            _ = context.motion.setTarget(.collapsed);
        } else if (CardLayout.startRectHasPoint(layout.grid, local_x, local_y)) {
            context.start_page_state = 1;
            context.start_picker_scroll_row = 0;
            _ = apps.refreshList();
        } else {
            return false;
        }
    } else if (context.start_page_state == 1) {
        const row = CardLayout.startPickerRowAt(card, context.start_picker_scroll_row, apps.listCount(), local_x, local_y);
        if (row >= 0) {
            if (apps.listAt(@intCast(row))) |app| {
                const added = apps.pin(std.mem.sliceTo(&app.target, 0), std.mem.sliceTo(&app.name, 0));
                logFormatted("start page: pin app; result={d}", .{@intFromBool(added)});
                context.start_page_state = 0;
                context.start_power_confirm_row = -1;
            }
        } else return false;
    } else if (context.start_page_state == 2) {
        const row = CardLayout.startPowerRowAt(card, local_x, local_y);
        if (row < 0) return false;
        if (row >= 2 and context.start_power_confirm_row != row) {
            context.start_power_confirm_row = row;
        } else {
            const success = runPowerAction(row);
            context.start_power_confirm_row = -1;
            if (success or row >= 2) {
                context.start_page_open = false;
                _ = context.motion.setTarget(.collapsed);
            }
        }
    } else return false;

    buildStartCardText(context);
    if (context.window) |window| window.invalidate();
    return true;
}

fn hasActiveNotification(context: *const PaintContext, now: u64) bool {
    return activeNotification(context, now) != null;
}

fn activeNotification(context: *const PaintContext, now: u64) ?*const Notification.Notification {
    const store = context.notifications orelse return null;
    return store.activeDisplayWithFallback(now, context.wechat.call_notification_id);
}

fn musicCardActive(context: *const PaintContext) bool {
    return context.active_present and !context.system_panel_pinned and
        !context.sound_page_open and !context.start_page_open and !context.tray_page_open;
}

fn copyBytesZ(output: []u8, input: []const u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const count = @min(input.len, output.len - 1);
    @memcpy(output[0..count], input[0..count]);
}

fn maskCircularIcon(pixels: []u8, width: i32, height: i32) void {
    if (width <= 0 or height <= 0) return;
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const pixel_count = @mulWithOverflow(w, h);
    if (pixel_count[1] != 0) return;
    const byte_count = @mulWithOverflow(pixel_count[0], 4);
    if (byte_count[1] != 0 or pixels.len < byte_count[0]) return;
    const cx = @as(f32, @floatFromInt(width)) * 0.5;
    const cy = @as(f32, @floatFromInt(height)) * 0.5;
    const radius = @max(0, @min(cx, cy) - 0.5);
    for (0..h) |y| {
        for (0..w) |x| {
            const dx = @as(f32, @floatFromInt(x)) + 0.5 - cx;
            const dy = @as(f32, @floatFromInt(y)) + 0.5 - cy;
            const coverage = std.math.clamp(radius + 0.5 - @sqrt(dx * dx + dy * dy), 0, 1);
            if (coverage >= 0.999) continue;
            const offset = (y * w + x) * 4;
            for (0..4) |channel| {
                pixels[offset + channel] = @intFromFloat(@round(@as(f32, @floatFromInt(pixels[offset + channel])) * coverage));
            }
        }
    }
}

fn buildMusicCardText(context: *PaintContext) void {
    const info = &context.music_snapshot;
    const lyric_duration = if (context.lyrics_provider) |provider|
        if (provider.current()) |lyrics| lyrics.track_duration_ms else 0
    else
        0;
    const duration = if (context.active_from_session and info.duration_ms > 0) info.duration_ms else lyric_duration;
    const app_name = if (context.active_from_session and info.app_name[0] != 0)
        std.mem.sliceTo(&info.app_name, 0)
    else if (context.active_from_session)
        std.mem.sliceTo(&info.app, 0)
    else
        "Media";
    const artwork = if (context.active_from_session and info.artwork_size > 0)
        info.artwork[0..@min(info.artwork_size, info.artwork.len)]
    else
        &.{};
    const app_icon = if (context.active_from_session and info.icon_size > 0)
        info.icon[0..@min(info.icon_size, info.icon.len)]
    else
        &.{};
    const fraction: f32 = if (duration > 0)
        @as(f32, @floatFromInt(@min(context.active_position_ms, duration))) / @as(f32, @floatFromInt(duration))
    else
        0;
    context.music_card_text = .{
        .title = std.mem.sliceTo(&context.active_title, 0),
        .artist = std.mem.sliceTo(&context.active_artist, 0),
        .album = if (context.active_from_session) std.mem.sliceTo(&info.album, 0) else &.{},
        .app = app_name,
        .playing = context.active_playing,
        .position_ms = context.active_position_ms,
        .duration_ms = duration,
        .progress_fraction = fraction,
        .artwork_png = artwork,
        .artwork_revision = info.artwork_revision,
        .background_png = if (context.active_from_session and context.music_background_png_size > 0)
            context.music_background_png[0..context.music_background_png_size]
        else
            &.{},
        .background_revision = context.music_background_revision,
        .app_icon_png = app_icon,
        .app_icon_revision = info.icon_revision,
    };
}

fn pointToLocalDip(point: IslandWindow.Point, context: *const PaintContext) [2]f32 {
    return .{
        @as(f32, @floatFromInt(point.x - context.window_x)) / context.scale,
        @as(f32, @floatFromInt(point.y - context.window_y)) / context.scale,
    };
}

fn nativeHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    const local = pointToLocalDip(point, context);
    if (context.fullscreen_app) {
        if (context.motion.target() == .full_bar) return false;
        const resting = Motion.boxForState(.collapsed, context.motion.anchor);
        const current = Motion.boxForState(context.motion.target(), context.motion.anchor);
        return pointInBox(resting, local[0], local[1]) or pointInBox(current, local[0], local[1]);
    }
    const notification_active = hasActiveNotification(context, GetTickCount64());
    if (notification_active) {
        const strip = Motion.boxForState(.notice_strip, context.motion.anchor);
        if (pointInBox(strip, local[0], local[1])) return true;
    }
    const outer_card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    if (outer_card_up) switch (context.card_owner) {
        .notification => if (pointInBox(notificationCardBox(context), local[0], local[1])) return true,
        .system_panel => if (pointInBox(systemPanelCardBox(context), local[0], local[1])) return true,
        .music => if (pointInBox(context.motion.current(), local[0], local[1])) return true,
        .none => {},
    };
    if (notification_active) return false;
    const task_count = taskButtonCount(context);
    const task_island = TaskStripLayout.rowAnchorWithTray(
        Motion.boxForState(.collapsed, context.motion.anchor),
        if (context.tray_icons) |icons| icons.count() > 0 else false,
    );
    if (task_count > 0 and TaskStripLayout.taskRowContains(task_island, task_count, local[0], local[1], 0, 0)) return true;
    const resting_deck = Motion.boxForState(.collapsed, context.motion.anchor);
    const deck_island = if (hasActiveNotification(context, GetTickCount64()))
        Motion.boxForState(.notice_strip, context.motion.anchor)
    else
        Motion.rowAnchorBox(context.motion.current(), resting_deck);
    if (TaskStripLayout.startButtonHit(deck_island, local[0], local[1]) or
        TaskStripLayout.systemButtonHit(deck_island, local[0], local[1])) return true;
    if (context.tray_icons) |icons| {
        if (icons.count() > 0 and TaskStripLayout.trayButtonHit(deck_island, local[0], local[1])) return true;
    }
    const current = context.motion.current();
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    return pointInBox(current, local[0], local[1]) or pointInBox(resting, local[0], local[1]);
}

fn nativeWheelHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    if (context.motion.target() != .expanded or hasActiveNotification(context, GetTickCount64())) return false;
    if (!context.sound_page_open and !(context.start_page_open and context.start_page_state == 1)) return false;
    const local = pointToLocalDip(point, context);
    return pointInBox(systemPanelCardBox(context), local[0], local[1]);
}

fn nativeCursorHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    if (context.fullscreen_app) return false;
    const local = pointToLocalDip(point, context);
    const notification_active = hasActiveNotification(context, GetTickCount64());
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    const deck = if (notification_active)
        Motion.boxForState(.notice_strip, context.motion.anchor)
    else
        Motion.rowAnchorBox(context.motion.current(), resting);
    const tray_visible = context.tray_icons != null and context.tray_icons.?.count() > 0;
    if (TaskStripLayout.startButtonHit(deck, local[0], local[1]) or
        TaskStripLayout.systemButtonHit(deck, local[0], local[1]) or
        (tray_visible and TaskStripLayout.trayButtonHit(deck, local[0], local[1]))) return true;

    const task_count = taskButtonCount(context);
    const task_island = TaskStripLayout.rowAnchorWithTray(deck, tray_visible);
    if (task_count > 0 and TaskStripLayout.taskIconUnderPointer(task_island, task_count, local[0], local[1]) >= 0) return true;

    const outer_card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    if (!outer_card_up) return false;
    const card = systemPanelCardBox(context);
    switch (context.card_owner) {
        .none, .notification => return false,
        .music => return CardLayout.musicControlAt(context.motion.current(), local[0], local[1]) != .none,
        .system_panel => switch (context.panel_level) {
            .sound => {
                const hit = CardLayout.soundPageHitFor(
                    card,
                    @intCast(context.sound_page_text.device_count),
                    @intCast(context.sound_page_text.mix_count),
                    context.sound_page_scroll,
                    local[0],
                    local[1],
                );
                return hit.target != .none;
            },
            .tray => {
                if (CardLayout.trayPageCellAt(card, @intCast(context.tray_page_icon_count), local[0], local[1]) >= 0) return true;
                return context.tray_menu_open and CardLayout.trayMenuRowAt(context.tray_menu_layout, local[0], local[1]) >= 0;
            },
            .start => {
                const layout = CardLayout.startPageFor(card);
                if (CardLayout.startRectHasPoint(layout.power_button, local[0], local[1])) return true;
                return switch (context.start_page_state) {
                    0 => CardLayout.startPinCellAt(layout, @intCast(context.start_card_text.pin_count), local[0], local[1]) >= 0 or
                        CardLayout.startRectHasPoint(layout.grid, local[0], local[1]),
                    1 => CardLayout.startPickerRowAt(card, context.start_picker_scroll_row, @intCast(context.start_card_text.list_count), local[0], local[1]) >= 0,
                    2 => CardLayout.startPowerRowAt(card, local[0], local[1]) >= 0,
                    else => false,
                };
            },
            .tiles => {
                const hit = CardLayout.systemPanelHitFor(
                    card,
                    @intCast(context.system_panel_text.tile_count),
                    1 + @as(i32, @intFromBool(context.system_panel_text.has_brightness)),
                    context.system_panel_text.page_index,
                    context.system_panel_text.page_count,
                    local[0],
                    local[1],
                );
                return hit.target != .none;
            },
        },
    }
}

fn nativeHitTestPolicyCheck() bool {
    var renderer = Renderer.DeviceResources{};
    var text_renderer = TextRenderer.TextRenderer{};
    var context = PaintContext{ .renderer = &renderer, .text_renderer = &text_renderer, .pill = .{} };
    const previous_width = window_width_px;
    const previous_height = window_height_px;
    defer {
        window_width_px = previous_width;
        window_height_px = previous_height;
    }
    window_width_px = 1920;
    window_height_px = @intFromFloat(Geometry.window_height_dip);
    context.scale = 1;
    context.motion.setAnchor(Motion.anchorForWindow(0, 0, 1920, 0));
    const pill = Motion.boxForState(.collapsed, context.motion.anchor);
    const centre = IslandWindow.Point{ .x = 960, .y = 24 };
    if (!nativeHitTest(centre, @ptrCast(&context))) return false;
    if (nativeHitTest(.{ .x = 300, .y = 100 }, @ptrCast(&context))) return false;
    const start = TaskStripLayout.startButtonFor(pill);
    if (!nativeHitTest(.{
        .x = @intFromFloat((start.left + start.right) * 0.5),
        .y = @intFromFloat((start.top + start.bottom) * 0.5),
    }, @ptrCast(&context))) return false;
    if (!context.motion.setTarget(.expanded)) return false;
    _ = context.motion.tick(0.36);
    context.card_owner = .system_panel;
    if (!nativeHitTest(.{ .x = 960, .y = 100 }, @ptrCast(&context))) return false;
    if (nativeHitTest(.{ .x = 300, .y = 100 }, @ptrCast(&context))) return false;
    const deck = Motion.rowAnchorBox(context.motion.current(), Motion.boxForState(.collapsed, context.motion.anchor));
    const start_button = TaskStripLayout.startButtonFor(deck);
    const system_button = TaskStripLayout.systemButtonFor(deck);
    if (!nativeCursorHitTest(pointAtDipRectCenter(start_button), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(system_button), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat((start_button.right + system_button.left) * 0.5), .y = @intFromFloat((start_button.top + start_button.bottom) * 0.5) }, @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = 960, .y = 100 }, @ptrCast(&context))) return false;

    context.task_windows.count = 3;
    const task_count = taskButtonCount(&context);
    const task_island = TaskStripLayout.rowAnchorWithTray(deck, false);
    const task_button = TaskStripLayout.taskIconButtonAtAmounts(task_island, 1, task_count, &context.task_hover_amount, 0, 0);
    if (!nativeCursorHitTest(pointAtDipRectCenter(task_button), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat(task_button.right + TaskStripLayout.task_icon_gap_dip * 0.5), .y = @intFromFloat((task_button.top + task_button.bottom) * 0.5) }, @ptrCast(&context))) return false;

    context.active_present = true;
    context.card_owner = .music;
    const music_layout = CardLayout.musicCardFor(context.motion.current());
    if (!nativeCursorHitTest(pointAtDipRectCenter(music_layout.play_pause), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(music_layout.previous), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(music_layout.next), @ptrCast(&context)) or
        nativeCursorHitTest(pointAtDipRectCenter(music_layout.title), @ptrCast(&context))) return false;
    context.active_present = false;

    context.start_page_open = true;
    context.card_owner = .system_panel;
    context.panel_level = .start;
    const start_card = systemPanelCardBox(&context);
    const start_layout = CardLayout.startPageFor(start_card);
    if (!nativeCursorHitTest(pointAtDipRectCenter(start_layout.power_button), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat((start_card.rect.left + start_card.rect.right) * 0.5), .y = @intFromFloat(start_card.rect.top + 8) }, @ptrCast(&context))) return false;
    context.start_page_open = false;

    context.sound_page_open = true;
    context.panel_level = .sound;
    const sound_layout = CardLayout.soundPageFor(systemPanelCardBox(&context), 0, 0, 0);
    if (!nativeCursorHitTest(pointAtDipRectCenter(sound_layout.back_button), @ptrCast(&context)) or
        nativeCursorHitTest(pointAtDipRectCenter(sound_layout.title), @ptrCast(&context))) return false;
    context.sound_page_open = false;

    context.tray_page_open = true;
    context.panel_level = .tray;
    context.tray_page_icon_count = 1;
    const tray_layout = CardLayout.trayPageFor(systemPanelCardBox(&context), 1);
    if (!nativeCursorHitTest(pointAtDipRectCenter(tray_layout.cells[0]), @ptrCast(&context))) return false;
    context.tray_page_open = false;

    context.system_panel_pinned = true;
    context.panel_level = .tiles;
    context.system_panel_text.tile_count = 1;
    const panel_layout = CardLayout.systemPanelFor(systemPanelCardBox(&context), 1, 1, false, 0, 1);
    return nativeCursorHitTest(pointAtDipRectCenter(panel_layout.tiles[0]), @ptrCast(&context));
}

fn pointAtDipRectCenter(rect: Geometry.RectF) IslandWindow.Point {
    return .{
        .x = @intFromFloat((rect.left + rect.right) * 0.5),
        .y = @intFromFloat((rect.top + rect.bottom) * 0.5),
    };
}

fn nativeWindowDpiCheck() bool {
    const monitor = Monitor.queryMonitor(null);
    const width = Monitor.screenWidth(monitor);
    const height = Geometry.dipToPixels(Geometry.window_height_dip, monitor.dpi);
    var window = IslandWindow.NativeWindow{};
    if (!window.create(monitor.screen.left, monitor.screen.top, width, height, 0, paintWindow, null, null)) return false;
    defer window.destroy();
    const hwnd = window.handle() orelse return false;
    const window_dpi = window.dpi();
    const owning_monitor = Monitor.queryMonitorForWindow(hwnd);
    return window_dpi != 0 and window_dpi == owning_monitor.dpi;
}

fn pointerStep(raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    const window = context.window orelse return;
    const now = GetTickCount64();
    const elapsed_ms = if (context.last_tick_ms == 0) 0 else now -| context.last_tick_ms;
    context.last_tick_ms = now;
    const dt = @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000;
    const changed_by_motion = context.motion.tick(dt);
    var hover_animation_active = false;
    var local_time: SystemTime = undefined;
    GetLocalTime(&local_time);
    const clock_changed = local_time.second != context.last_clock_second;
    context.last_clock_second = local_time.second;
    if (context.fullscreen_last_poll_ms == 0 or now -| context.fullscreen_last_poll_ms >= 250) {
        context.fullscreen_last_poll_ms = now;
        const measured = !context.fullscreen_disabled and Monitor.fullScreenAppInFront(context.monitor_bounds);
        if (measured != context.fullscreen_app) {
            context.fullscreen_app = measured;
            logFormatted("fullscreen: {s}", .{if (measured) "full-screen app in front" else "normal desktop restored"});
            if (context.app_bar) |bar| {
                if (measured and bar.registered) {
                    bar.release();
                } else if (!measured and context.app_bar_reclaim and !bar.registered and context.bar_thickness_px > 0) {
                    _ = bar.claim(window.handle(), .top, context.bar_thickness_px);
                }
            }
            window.invalidate();
        }
    }
    var task_refresh_changed = false;
    if (context.task_last_refresh_ms == 0 or now -| context.task_last_refresh_ms >= 500) {
        context.task_last_refresh_ms = now;
        const previous_count = context.task_windows.count;
        const previous_foreground = context.task_windows.foreground;
        var previous_handles: [WindowList.max_task_windows]?*anyopaque = @splat(null);
        for (context.task_windows.entries, 0..) |entry, index| previous_handles[index] = entry.handle;
        _ = context.task_windows.refresh();
        task_refresh_changed = previous_count != context.task_windows.count or previous_foreground != context.task_windows.foreground;
        if (!task_refresh_changed) {
            for (context.task_windows.entries, 0..) |entry, index| {
                if (previous_handles[index] != entry.handle) {
                    task_refresh_changed = true;
                    break;
                }
            }
        }
        if (task_refresh_changed) window.invalidate();
    }
    const system_status_refreshed = sampleSystemStatus(context, now);
    if (context.tray_icons) |icons| {
        if (context.tray_last_refresh_ms == 0 or now -| context.tray_last_refresh_ms >= 5000) {
            context.tray_last_refresh_ms = now;
            const previous_count = icons.count();
            const previous_revision = icons.getRevision();
            _ = icons.refresh(std.heap.page_allocator);
            const tray_changed = previous_count != icons.count() or previous_revision != icons.getRevision();
            if (context.tray_page_revision != icons.getRevision()) {
                buildTrayPageText(context);
                if (context.tray_page_open) window.invalidate();
            }
            if (tray_changed) {
                if (context.tray_menu_open) closeTrayMenu(context);
                window.invalidate();
            }
        }
    }
    if (context.start_apps) |apps| {
        const icon_revision = apps.iconRevision();
        if (icon_revision != context.last_start_icon_revision) {
            buildStartCardText(context);
            if (context.start_page_open) window.invalidate();
        }
    }

    if (context.notification_server) |server| {
        if (context.notifications) |store| {
            var incoming = Notification.Notification{};
            while (server.take(&incoming)) {
                const stored = store.pushAt(incoming, now);
                logFormatted("notification: [{s}] {s}", .{
                    if (stored.app[0] != 0) std.mem.sliceTo(&stored.app, 0) else "?",
                    if (stored.title[0] != 0) std.mem.sliceTo(&stored.title, 0) else std.mem.sliceTo(&stored.body, 0),
                });
                _ = context.motion.setTarget(.notice_strip);
                window.invalidate();
            }
        }
    }

    if (context.notifications) |store| {
        if (now -| context.wechat_last_poll_ms >= 500) {
            context.wechat_last_poll_ms = now;
            if (context.wechat.poll(store, now) > 0) {
                logFormatted("wechat: {d} window announcement(s) so far", .{context.wechat.announcementCount()});
                _ = context.motion.setTarget(.notice_strip);
                window.invalidate();
            }
        }
        if (context.sound_output != null and now -| context.wechat_last_sound_poll_ms >= 200) {
            context.wechat_last_sound_poll_ms = now;
            const snapshot = context.sound_snapshot;
            var wechat_session_active = false;
            var wechat_session_count: i32 = 0;
            for (snapshot.sessions[0..@min(snapshot.session_count, snapshot.sessions.len)]) |session| {
                if (!WeChatWatch.isWeChatProcess(session.pid)) continue;
                wechat_session_count += 1;
                wechat_session_active = wechat_session_active or session.active;
            }
            if (context.wechat.pollSound(
                store,
                WeChatWatch.anyWeChatProcessRunning(),
                wechat_session_active,
                wechat_session_count,
                now,
            ) > 0) {
                _ = context.motion.setTarget(.notice_strip);
                window.invalidate();
            }
        }
    }
    if (context.wechat.call_notification_id != 0 and now -| context.call_meter_redraw_ms >= 50) {
        context.call_meter_redraw_ms = now;
        window.invalidate();
    }

    if (context.music_session) |music| {
        const music_revision = music.getRevision();
        if (music_revision != context.last_music_revision) {
            context.last_music_revision = music_revision;
            context.last_music_reading_ms = now;
            music.snapshot(&context.music_snapshot);
            window.invalidate();
        }
    }
    if (context.player_window) |player| {
        const player_revision = player.revisionCount();
        if (player_revision != context.last_player_revision) {
            context.last_player_revision = player_revision;
            player.snapshot(&context.player_snapshot);
            window.invalidate();
        }
    }

    const session_up = context.music_snapshot.present and context.music_snapshot.title[0] != 0;
    const player_up = !session_up and context.player_snapshot.present and context.player_snapshot.title[0] != 0;
    const title = if (session_up)
        std.mem.sliceTo(&context.music_snapshot.title, 0)
    else if (player_up)
        std.mem.sliceTo(&context.player_snapshot.title, 0)
    else
        &.{};
    const artist = if (session_up)
        std.mem.sliceTo(&context.music_snapshot.artist, 0)
    else if (player_up)
        std.mem.sliceTo(&context.player_snapshot.artist, 0)
    else
        &.{};

    context.active_present = session_up or player_up;
    context.active_from_session = session_up;
    context.active_playing = if (session_up) context.music_snapshot.state == .playing else player_up;
    if (context.active_present) {
        copyBytesZ(&context.active_title, title);
        copyBytesZ(&context.active_artist, artist);
        if (!std.mem.eql(u8, title, std.mem.sliceTo(&context.requested_title, 0)) or
            !std.mem.eql(u8, artist, std.mem.sliceTo(&context.requested_artist, 0)))
        {
            copyBytesZ(&context.requested_title, title);
            copyBytesZ(&context.requested_artist, artist);
            context.track_stopwatch_ms = 0;
            context.shown_lyric_text = @splat(0);
            context.replaced_lyric_text = @splat(0);
            context.lyric_line_age_seconds = 1;
            context.lyric_scroll_dip = 0;
            context.replaced_lyric_scroll_dip = 0;
            context.music_wave_accent = .{};
            context.last_wave_artwork_revision = std.math.maxInt(u64);
            if (context.lyrics_provider) |lyrics| lyrics.request(title, artist);
        }
        if (context.active_playing) {
            context.track_stopwatch_ms = std.math.add(i64, context.track_stopwatch_ms, @intCast(elapsed_ms)) catch std.math.maxInt(i64);
        }
        if (session_up) {
            const elapsed = now -| context.last_music_reading_ms;
            context.active_position_ms = MusicSession.trackPositionFor(
                context.music_snapshot.position_ms,
                context.music_snapshot.duration_ms,
                @intCast(@min(elapsed, std.math.maxInt(i64))),
                context.track_stopwatch_ms,
                context.active_playing,
            ).ms;
        } else {
            context.active_position_ms = @max(0, context.track_stopwatch_ms);
        }
    } else {
        context.active_title = @splat(0);
        context.active_artist = @splat(0);
        context.requested_title = @splat(0);
        context.requested_artist = @splat(0);
        context.track_stopwatch_ms = 0;
        context.active_position_ms = 0;
        context.current_lyric_line = .{};
        context.shown_lyric_text = @splat(0);
        context.replaced_lyric_text = @splat(0);
        context.lyric_line_age_seconds = 1;
        context.lyric_scroll_dip = 0;
        context.replaced_lyric_scroll_dip = 0;
        context.music_wave_accent = .{};
        context.last_wave_artwork_revision = std.math.maxInt(u64);
    }
    if (context.active_from_session and context.music_snapshot.artwork_size > 0 and
        context.music_snapshot.artwork_revision != context.last_wave_artwork_revision)
    {
        context.last_wave_artwork_revision = context.music_snapshot.artwork_revision;
        var decoded = WicImage.DecodedImage{};
        const png = context.music_snapshot.artwork[0..@min(context.music_snapshot.artwork_size, context.music_snapshot.artwork.len)];
        if (WicImage.decodeImage(png, &decoded, .artwork) and decoded.pixels != null and decoded.width > 0 and decoded.height > 0) {
            const pixel_count = std.math.mul(usize, @intCast(decoded.width), @intCast(decoded.height)) catch 0;
            const byte_count = std.math.mul(usize, pixel_count, 4) catch 0;
            if (byte_count > 0) context.music_wave_accent = WicImage.accentColourFromArtwork(decoded.pixels.?[0..byte_count], decoded.width, decoded.height) else context.music_wave_accent = .{};
        } else {
            context.music_wave_accent = .{};
        }
        // Build the full-card wash once for each cover revision. The encoded
        // image remains in PaintContext while TextRenderer uploads and caches it.
        context.music_background_png_size = WicImage.makeBlurredBackgroundPng(
            png,
            105,
            59,
            &context.music_background_png,
        );
        context.music_background_revision = if (context.music_background_png_size > 0)
            context.music_snapshot.artwork_revision
        else
            0;
    } else if ((!context.active_from_session or context.music_snapshot.artwork_size == 0) and context.last_wave_artwork_revision != std.math.maxInt(u64)) {
        context.music_wave_accent = .{};
        context.last_wave_artwork_revision = 0;
        context.music_background_png_size = 0;
        context.music_background_revision = 0;
    }
    if (context.lyrics_provider) |lyrics| {
        const lyrics_revision = lyrics.getRevision();
        if (lyrics_revision != context.last_lyrics_revision) {
            context.last_lyrics_revision = lyrics_revision;
            window.invalidate();
        }
    }
    var lyric_line_changed = false;
    var lyric_scroll_animating = false;
    if (context.active_present) {
        context.lyric_line_age_seconds = @min(1, context.lyric_line_age_seconds + dt);
        context.current_lyric_line = .{};
        var next_line: []const u8 = &.{};
        if (context.lyrics_provider) |lyrics| {
            if (lyrics.copyLineAt(context.active_position_ms, &context.current_lyric_line)) {
                next_line = std.mem.sliceTo(&context.current_lyric_line.text, 0);
            }
        }
        const shown_line = std.mem.sliceTo(&context.shown_lyric_text, 0);
        if (Lyrics.lyricLineChanged(next_line, shown_line)) {
            copyBytesZ(&context.replaced_lyric_text, shown_line);
            context.replaced_lyric_scroll_dip = context.lyric_scroll_dip;
            context.lyric_scroll_dip = 0;
            context.lyric_line_age_seconds = 0;
            copyBytesZ(&context.shown_lyric_text, next_line);
            lyric_line_changed = true;
        }
        const line_to_measure = if (next_line.len != 0) next_line else std.mem.sliceTo(&context.active_title, 0);
        const line_box = Motion.boxForState(.music_strip, context.motion.anchor);
        if (context.active_playing and activeNotification(context, now) == null and
            context.text_renderer.trackLineNeedsScroll(line_to_measure, Geometry.width(line_box.rect)))
        {
            context.lyric_scroll_dip += dt * 26;
            lyric_scroll_animating = true;
        }
    }
    const weather_revision = weather_reader.getRevision();
    if (weather_revision != context.last_weather_revision) {
        context.last_weather_revision = weather_revision;
        window.invalidate();
    }
    if (context.active_playing) {
        context.music_wave_phase += @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000 * 1.15;
        if (context.music_wave_phase > 6.2831853 * 64) context.music_wave_phase -= 6.2831853 * 64;
    }
    if (context.active_playing and activeNotification(context, now) == null and now -| context.music_meter_redraw_ms >= 33) {
        context.music_meter_redraw_ms = now;
        window.invalidate();
    }
    if (context.wechat.call_notification_id == 0) {
        const is_music_line = context.active_present and context.active_title[0] != 0;
        const has_notice_line = activeNotification(context, now) != null;
        const placement = StatePolicy.statusPlacementFor(is_music_line or has_notice_line);
        const old_opacity = context.status_strip_opacity;
        context.status_strip_opacity = TaskStripLayout.statusStripFadeStep(context.status_strip_opacity, placement.beside_deck, dt);
        context.status_strip_animating = context.status_strip_opacity > 0.001 and context.status_strip_opacity < 0.999;
        if (@abs(context.status_strip_opacity - old_opacity) > 0.001) window.invalidate();
    } else {
        const old_opacity = context.status_strip_opacity;
        context.status_strip_opacity = TaskStripLayout.statusStripFadeStep(context.status_strip_opacity, true, dt);
        context.status_strip_animating = context.status_strip_opacity > 0.001 and context.status_strip_opacity < 0.999;
        if (@abs(context.status_strip_opacity - old_opacity) > 0.001) window.invalidate();
    }
    if (context.fullscreen_app) {
        _ = context.motion.setTarget(if (hasActiveNotification(context, now)) .notice_strip else .full_bar);
    } else if (context.motion.target() == .full_bar) {
        _ = context.motion.setTarget(if (context.active_present) .music_strip else .collapsed);
    }
    buildMusicCardText(context);
    if (!hasActiveNotification(context, now) and !context.system_panel_pinned and
        !context.sound_page_open and !context.start_page_open and !context.tray_page_open)
    {
        if (context.active_present and context.motion.target() == .collapsed) {
            _ = context.motion.setTarget(.music_strip);
        } else if (!context.active_present and context.motion.target() == .music_strip) {
            _ = context.motion.setTarget(.collapsed);
        }
    }
    const music_second = @divTrunc(context.active_position_ms, 1000);
    if (context.motion.target() == .expanded and context.active_present and music_second != context.last_music_card_second) {
        context.last_music_card_second = music_second;
        window.invalidate();
    }

    var pointer: IslandWindow.Point = undefined;
    const have_pointer = window.pointerPosition(&pointer);
    var right_click_point: IslandWindow.Point = undefined;
    while (window.takeRightClick(&right_click_point)) {
        const local_right = pointToLocalDip(right_click_point, context);
        const notification_active = hasActiveNotification(context, now);
        const card = systemPanelCardBox(context);
        if (!notification_active and context.start_page_open and context.motion.target() == .expanded and context.start_page_state == 0) {
            const layout = CardLayout.startPageFor(card);
            const pin = CardLayout.startPinCellAt(layout, @intCast(context.start_card_text.pin_count), local_right[0], local_right[1]);
            if (pin >= 0) {
                if (context.start_apps) |apps| {
                    const pin_index: usize = @intCast(pin);
                    if (apps.pinAt(pin_index)) |app| {
                        var name_utf8: [512]u8 = undefined;
                        logFormatted("start: unpinning '{s}'", .{CommandLine.wideTextToUtf8(&app.name, &name_utf8)});
                    }
                    if (apps.unpin(pin_index)) {
                        context.start_power_confirm_row = -1;
                        buildStartCardText(context);
                        window.invalidate();
                    }
                }
            }
        } else if (!notification_active and context.tray_page_open and context.motion.target() == .expanded and pointInBox(card, local_right[0], local_right[1])) {
            const cell = CardLayout.trayPageCellAt(card, @intCast(context.tray_page_icon_count), local_right[0], local_right[1]);
            if (cell >= 0 and openTrayMenu(context, @intCast(cell), card)) {
                logFormatted("tray menu: opened for cell {d} ({d} entries)", .{ cell, context.tray_menu_action_count });
                window.invalidate();
            }
        }
    }
    var pressed_point: IslandWindow.Point = undefined;
    if (window.takePress(&pressed_point)) {
        context.pending_press_point = pressed_point;
        if (context.sound_page_open and context.motion.target() == .expanded and !hasActiveNotification(context, now)) {
            const pressed_local = pointToLocalDip(pressed_point, context);
            if (pointInBox(systemPanelCardBox(context), pressed_local[0], pressed_local[1])) {
                const hit = CardLayout.soundPageHitFor(
                    systemPanelCardBox(context),
                    @intCast(context.sound_page_text.device_count),
                    @intCast(context.sound_page_text.mix_count),
                    context.sound_page_scroll,
                    pressed_local[0],
                    pressed_local[1],
                );
                if (hit.target == .mixer_slider) setMixerLevel(context, hit.index, hit.fraction);
            }
        }
    }
    if (have_pointer) {
        const local = pointToLocalDip(pointer, context);
        const task_count = taskButtonCount(context);
        const task_island = TaskStripLayout.rowAnchorWithTray(
            Motion.boxForState(.collapsed, context.motion.anchor),
            if (context.tray_icons) |icons| icons.count() > 0 else false,
        );
        const next_task_hovered = if (task_count > 0)
            TaskStripLayout.taskIconToKeepOpen(task_island, task_count, context.task_hovered_index, local[0], local[1])
        else
            -1;
        var task_animation_changed = next_task_hovered != context.task_hovered_index;
        if (task_animation_changed) context.task_hovered_index = next_task_hovered;
        for (0..task_count) |index| {
            if (TaskStripLayout.controlWashStep(
                &context.task_hover_amount[index],
                &context.task_hover_velocity[index],
                if (@as(i32, @intCast(index)) == context.task_hovered_index) 1 else 0,
                dt,
            )) task_animation_changed = true;
        }
        if (task_animation_changed) window.invalidate();
        updateTaskThumbnailPreview(context, task_island, task_count, now);
        const on_task_row = task_count > 0 and TaskStripLayout.taskRowContains(task_island, task_count, local[0], local[1], 0, 0);
        const resting_state: Motion.IslandState = if (context.active_present) .music_strip else .collapsed;
        const resting = Motion.boxForState(resting_state, context.motion.anchor);
        const notification_active = hasActiveNotification(context, now);
        const interactive_pill = if (notification_active) Motion.boxForState(.notice_strip, context.motion.anchor) else resting;
        const resting_deck = Motion.boxForState(.collapsed, context.motion.anchor);
        const deck_island = if (notification_active)
            Motion.boxForState(.notice_strip, context.motion.anchor)
        else
            Motion.rowAnchorBox(context.motion.current(), resting_deck);
        const on_start_button = TaskStripLayout.startButtonHit(deck_island, local[0], local[1]);
        const on_system_button = TaskStripLayout.systemButtonHit(deck_island, local[0], local[1]);
        const tray_button_visible = if (context.tray_icons) |icons| icons.count() > 0 else false;
        const on_tray_button = tray_button_visible and TaskStripLayout.trayButtonHit(deck_island, local[0], local[1]);
        const on_control = on_start_button or on_system_button or on_tray_button;
        var button_wash_changed = false;
        button_wash_changed = TaskStripLayout.controlWashStep(&context.start_button_wash, &context.start_button_velocity, if (context.forced_start_hover or on_start_button) 1 else 0, dt) or button_wash_changed;
        button_wash_changed = TaskStripLayout.controlWashStep(&context.system_button_wash, &context.system_button_velocity, if (on_system_button) 1 else 0, dt) or button_wash_changed;
        button_wash_changed = TaskStripLayout.controlWashStep(&context.tray_button_wash, &context.tray_button_velocity, if (on_tray_button) 1 else 0, dt) or button_wash_changed;
        const on_pill = pointInBox(interactive_pill, local[0], local[1]) or on_control;
        if (button_wash_changed) window.invalidate();
        hover_animation_active = task_animation_changed or button_wash_changed;
        if (window.takeClick()) {
            const press = context.pending_press_point orelse pointer;
            context.pending_press_point = null;
            const pressed_local = pointToLocalDip(press, context);
            if (context.tray_menu_open) {
                const row = CardLayout.trayMenuRowAt(context.tray_menu_layout, pressed_local[0], pressed_local[1]);
                if (row >= 0 and @as(usize, @intCast(row)) < context.tray_menu_action_count) {
                    const action = context.tray_menu_actions[@intCast(row)];
                    if (action == .quit_application and !context.tray_quit_armed) {
                        context.tray_quit_armed = true;
                        Log.logLine("tray menu: quit armed; click the same row again to confirm");
                    } else {
                        runTrayMenuAction(context, action);
                        closeTrayMenu(context);
                        if (action == .open or action == .close_window or action == .application_menu) dismissSystemPanel(context);
                    }
                } else {
                    closeTrayMenu(context);
                    Log.logLine("tray menu: closed by a click outside its rows");
                }
                window.invalidate();
            } else if (hasActiveNotification(context, now)) {
                if (context.notifications) |store| {
                    const keep_call: ?i64 = if (context.wechat.call_notification_id != 0)
                        context.wechat.call_notification_id
                    else
                        null;
                    const marked = store.markAllReadExcept(keep_call);
                    if (marked > 0) {
                        logFormatted("notifications: {d} marked read (click)", .{marked});
                        _ = context.motion.setTarget(if (on_pill) .hover else resting_state);
                        window.invalidate();
                    }
                }
            } else {
                const notification_active_now = hasActiveNotification(context, now);
                const press_deck = if (notification_active_now)
                    Motion.boxForState(.notice_strip, context.motion.anchor)
                else
                    Motion.rowAnchorBox(context.motion.current(), resting_deck);
                const press_on_start = TaskStripLayout.startButtonHit(press_deck, pressed_local[0], pressed_local[1]);
                const press_on_system = TaskStripLayout.systemButtonHit(press_deck, pressed_local[0], pressed_local[1]);
                const press_on_tray = tray_button_visible and TaskStripLayout.trayButtonHit(press_deck, pressed_local[0], pressed_local[1]);
                if (!notification_active_now and press_on_system) {
                    const close = context.system_panel_pinned and !context.start_page_open and !context.tray_page_open and !context.sound_page_open;
                    closeTrayMenu(context);
                    context.system_panel_pinned = !close;
                    if (!close) context.card_hang = .system_button;
                    context.start_page_open = false;
                    context.tray_page_open = false;
                    context.sound_page_open = false;
                    if (close) _ = context.motion.setTarget(resting_state) else _ = context.motion.setTarget(.expanded);
                    window.invalidate();
                } else if (!notification_active_now and press_on_start) {
                    const close = context.start_page_open;
                    closeTrayMenu(context);
                    context.start_page_open = !close;
                    context.tray_page_open = false;
                    context.sound_page_open = false;
                    context.system_panel_pinned = !close;
                    if (!close) context.card_hang = .start_button;
                    if (close) {
                        _ = context.motion.setTarget(resting_state);
                    } else {
                        context.start_page_state = 0;
                        context.start_power_confirm_row = -1;
                        if (context.start_apps) |apps| _ = apps.refreshList();
                        buildStartCardText(context);
                        _ = context.motion.setTarget(.expanded);
                    }
                    window.invalidate();
                } else if (!notification_active_now and press_on_tray) {
                    const close = context.tray_page_open;
                    closeTrayMenu(context);
                    context.tray_page_open = !close;
                    context.start_page_open = false;
                    context.sound_page_open = false;
                    context.system_panel_pinned = !close;
                    if (!close) context.card_hang = .tray_button;
                    if (close) {
                        _ = context.motion.setTarget(resting_state);
                    } else {
                        if (context.tray_icons) |icons| {
                            _ = icons.refresh(std.heap.page_allocator);
                            context.tray_last_refresh_ms = now;
                        }
                        buildTrayPageText(context);
                        _ = context.motion.setTarget(.expanded);
                    }
                    window.invalidate();
                } else if (!notification_active_now and context.motion.target() == .expanded and musicCardActive(context) and pointInBox(context.motion.current(), pressed_local[0], pressed_local[1])) {
                    const control = CardLayout.musicControlAt(context.motion.current(), pressed_local[0], pressed_local[1]);
                    if (control != .none) {
                        if (context.music_session) |music| {
                            const action: MusicSession.Transport = switch (control) {
                                .previous => .previous,
                                .play_pause => .play_pause,
                                .next => .next,
                                .none => unreachable,
                            };
                            if (!music.requestTransport(action)) Log.logLine("music: transport request could not be sent");
                        } else {
                            Log.logLine("music: transport controls unavailable for the active window-title player");
                        }
                    } else if (pointInBox(interactive_pill, pressed_local[0], pressed_local[1])) {
                        context.system_panel_pinned = true;
                        window.invalidate();
                    }
                } else if (!notification_active_now and context.motion.target() == .expanded and !musicCardActive(context) and pointInBox(systemPanelCardBox(context), pressed_local[0], pressed_local[1])) {
                    if (context.sound_page_open) {
                        _ = handleSoundPageClick(context, pressed_local[0], pressed_local[1]);
                    } else if (context.start_page_open) {
                        _ = handleStartPageClick(context, pressed_local[0], pressed_local[1]);
                    } else if (context.tray_page_open) {
                        _ = handleTrayPageClick(context, pressed_local[0], pressed_local[1]);
                    } else {
                        _ = handleSystemPanelClick(context, pressed_local[0], pressed_local[1]);
                    }
                } else if (task_count > 0 and TaskStripLayout.taskIconUnderPointer(task_island, task_count, pressed_local[0], pressed_local[1]) >= 0) {
                    const task_index: usize = @intCast(TaskStripLayout.taskIconUnderPointer(task_island, task_count, pressed_local[0], pressed_local[1]));
                    const target = context.task_windows.entries[task_index].handle;
                    if (WindowList.foregroundWindow() == target) {
                        if (context.task_windows.minimize(target)) {
                            Log.logLine("task button: minimized the foreground window");
                        } else {
                            Log.logLine("task button: minimizing the foreground window failed");
                        }
                    } else if (context.task_windows.activate(target)) {
                        Log.logLine("task button: activated the selected window");
                    } else {
                        Log.logLine("task button: activating the selected window failed");
                    }
                    context.task_last_refresh_ms = 0;
                    _ = context.task_windows.refresh();
                    window.invalidate();
                } else if (pointInBox(interactive_pill, pressed_local[0], pressed_local[1])) {
                    if (context.motion.target() == .expanded and context.active_present) {
                        context.system_panel_pinned = !context.system_panel_pinned;
                        if (!context.system_panel_pinned) {
                            context.sound_page_open = false;
                            context.start_page_open = false;
                            context.tray_page_open = false;
                        }
                        window.invalidate();
                    } else if (context.motion.target() == .expanded) {
                        context.system_panel_pinned = false;
                        context.sound_page_open = false;
                        context.start_page_open = false;
                        context.tray_page_open = false;
                        _ = context.motion.setTarget(resting_state);
                        window.invalidate();
                    } else if (context.active_present) {
                        context.system_panel_pinned = false;
                        _ = context.motion.setTarget(.expanded);
                        window.invalidate();
                    } else {
                        closeTrayMenu(context);
                        context.system_panel_pinned = true;
                        context.sound_page_open = false;
                        context.start_page_open = false;
                        context.tray_page_open = false;
                        context.card_hang = .system_button;
                        _ = context.motion.setTarget(.expanded);
                        window.invalidate();
                    }
                } else if (context.system_panel_pinned) {
                    context.system_panel_pinned = false;
                    _ = context.motion.setTarget(.collapsed);
                }
            }
        }

        if (context.sound_page_open and context.motion.target() == .expanded and !notification_active) {
            if (window.leftButtonDown() and context.mixer_drag_row >= 0) {
                const hit = CardLayout.soundPageHitFor(
                    systemPanelCardBox(context),
                    @intCast(context.sound_page_text.device_count),
                    @intCast(context.sound_page_text.mix_count),
                    context.sound_page_scroll,
                    local[0],
                    local[1],
                );
                if (hit.target == .mixer_slider and hit.index == context.mixer_drag_row) setMixerLevel(context, hit.index, hit.fraction);
            } else if (!window.leftButtonDown()) {
                context.mixer_drag_row = -1;
            }
            if (pointInBox(systemPanelCardBox(context), local[0], local[1])) {
                const wheel = window.takeWheelNotches();
                if (wheel != 0) {
                    const device_count: i32 = @intCast(context.sound_page_text.device_count);
                    const mix_count: i32 = @intCast(context.sound_page_text.mix_count);
                    context.sound_page_scroll -= @as(f32, @floatFromInt(wheel)) * 60;
                    context.sound_page_scroll = std.math.clamp(context.sound_page_scroll, 0, CardLayout.soundPageScrollLimit(systemPanelCardBox(context), device_count, mix_count));
                    buildSoundPageText(context);
                    window.invalidate();
                }
            }
        }

        if (context.tray_page_open and context.motion.target() == .expanded and !notification_active) {
            const hovered = if (pointInBox(systemPanelCardBox(context), local[0], local[1]))
                CardLayout.trayPageCellAt(systemPanelCardBox(context), @intCast(context.tray_page_icon_count), local[0], local[1])
            else
                -1;
            if (hovered != context.tray_hovered_index) {
                context.tray_hovered_index = hovered;
                window.invalidate();
            }
        } else if (context.tray_hovered_index != -1) {
            context.tray_hovered_index = -1;
        }

        if (context.tray_menu_open and context.tray_page_open and context.motion.target() == .expanded and !notification_active) {
            const hovered = CardLayout.trayMenuRowAt(context.tray_menu_layout, local[0], local[1]);
            if (hovered != context.tray_menu_hovered) {
                context.tray_menu_hovered = hovered;
                window.invalidate();
            }
        } else if (context.tray_menu_open) {
            closeTrayMenu(context);
            window.invalidate();
        }

        if (context.start_page_open and context.motion.target() == .expanded and !notification_active) {
            const card = systemPanelCardBox(context);
            const layout = CardLayout.startPageFor(card);
            const on_card = pointInBox(card, local[0], local[1]);
            const pin_hover = if (on_card and context.start_page_state == 0) CardLayout.startPinCellAt(layout, @intCast(context.start_card_text.pin_count), local[0], local[1]) else -1;
            const picker_hover = if (on_card and context.start_page_state == 1) CardLayout.startPickerRowAt(card, context.start_picker_scroll_row, @intCast(@min(context.start_card_text.list_count, std.math.maxInt(i32))), local[0], local[1]) else -1;
            const power_hover = if (on_card and context.start_page_state == 2) CardLayout.startPowerRowAt(card, local[0], local[1]) else -1;
            const button_hover = on_card and CardLayout.startRectHasPoint(layout.power_button, local[0], local[1]);
            if (pin_hover != context.start_hovered_pin or picker_hover != context.start_hovered_picker_row or power_hover != context.start_hovered_power_row or button_hover != context.start_power_hovered) {
                context.start_hovered_pin = pin_hover;
                context.start_hovered_picker_row = picker_hover;
                context.start_hovered_power_row = power_hover;
                context.start_power_hovered = button_hover;
                buildStartCardText(context);
                window.invalidate();
            }
            if (context.start_page_state == 1 and on_card and CardLayout.startRectHasPoint(layout.grid, local[0], local[1])) {
                const wheel = window.takeWheelNotches();
                if (wheel != 0) {
                    const visible_rows: i32 = @intFromFloat(@max(1, (layout.grid.bottom - layout.grid.top) / CardLayout.start_row_height));
                    const max_scroll = @max(0, @as(i32, @intCast(@min(context.start_card_text.list_count, std.math.maxInt(i32)))) - visible_rows);
                    context.start_picker_scroll_row = std.math.clamp(context.start_picker_scroll_row - wheel, 0, max_scroll);
                    buildStartCardText(context);
                    window.invalidate();
                }
            }
        }

        if (context.motion.target() == .expanded) {
            const current = if (notification_active) notificationCardBox(context) else if (musicCardActive(context)) context.motion.current() else systemPanelCardBox(context);
            const in_current = pointInBox(current, local[0], local[1]);
            if (!context.system_panel_pinned and !on_pill and !on_task_row and !in_current) _ = context.motion.setTarget(resting_state);
        } else if (context.motion.target() == .collapsed and on_pill) {
            _ = context.motion.setTarget(.hover);
        } else if (context.motion.target() == .music_strip and on_pill) {
            _ = context.motion.setTarget(.expanded);
        } else if (context.motion.target() == .hover and !on_pill) {
            _ = context.motion.setTarget(resting_state);
        } else if (context.motion.target() == .notice_strip and
            (context.notifications == null or context.notifications.?.activeDisplay(now) == null))
        {
            _ = context.motion.setTarget(if (on_pill) .hover else .collapsed);
        }
    }

    if (!have_pointer) {
        if (context.thumbnail_preview) |preview| preview.hide();
    }

    if (context.forced_state) |forced| {
        if (context.motion.target() != forced) _ = context.motion.setTarget(forced);
    }
    const shape_animating = context.motion.isAnimating();
    const lyric_roll_animating = context.active_present and context.lyric_line_age_seconds < Lyrics.line_enter_seconds;
    const active_music_meter = context.active_playing and activeNotification(context, now) == null;
    const poll_ms = pointerPollIntervalFor(
        shape_animating or context.status_strip_animating or lyric_scroll_animating or lyric_roll_animating or hover_animation_active,
        context.wechat.call_notification_id != 0,
        active_music_meter,
    );
    window.setPointerPollInterval(poll_ms);
    _ = updateInputRegion(context);
    if (system_status_refreshed or task_refresh_changed or changed_by_motion or shape_animating or context.status_strip_animating or lyric_line_changed or lyric_scroll_animating or lyric_roll_animating or clock_changed) window.invalidate();
}

fn refreshDisplayGeometry(raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    const window = context.window orelse return;
    const hwnd = window.handle() orelse return;
    var monitor = Monitor.queryMonitorForWindow(hwnd);
    const actual_dpi = window.dpi();
    if (actual_dpi != 0) {
        monitor.dpi = actual_dpi;
        monitor.dpi_y = actual_dpi;
    }
    const width_px = Monitor.screenWidth(monitor);
    const height_px = Geometry.dipToPixels(Geometry.window_height_dip, monitor.dpi);
    if (width_px <= 0 or height_px <= 0) return;
    if (Monitor.sameRect(context.monitor_bounds, monitor.screen) and
        Monitor.sameRect(context.monitor_work, monitor.work) and context.monitor == monitor.monitor and
        context.scale == @as(f32, @floatFromInt(monitor.dpi)) / 96.0) return;

    const x = monitor.screen.left;
    const y = monitor.screen.top;
    if (!window.setBounds(x, y, width_px, height_px)) {
        Log.logLine("display change: window bounds could not be updated");
        return;
    }
    context.renderer.shutdown();
    window_width_px = width_px;
    window_height_px = height_px;
    context.window_x = x;
    context.window_y = y;
    context.scale = @as(f32, @floatFromInt(monitor.dpi)) / 96.0;
    context.monitor = monitor.monitor;
    context.monitor_bounds = monitor.screen;
    context.monitor_work = monitor.work;
    context.motion.setAnchor(Motion.anchorForWindow(
        Geometry.pixelsToDip(x, monitor.dpi),
        Geometry.pixelsToDip(y, monitor.dpi),
        Geometry.pixelsToDip(width_px, monitor.dpi),
        Geometry.pixelsToDip(Monitor.taskbarThickness(monitor), monitor.dpi),
    ));
    context.pill.box = context.motion.current();
    if (!context.renderer.initialize(hwnd, @intCast(width_px), @intCast(height_px), context.scale)) {
        Log.logLine("display change: renderer could not be recreated for the new monitor geometry");
        return;
    }
    if (context.app_bar_reclaim) {
        context.bar_thickness_px = Geometry.dipToPixels(Geometry.reserved_bar_height_dip, monitor.dpi);
        if (context.app_bar) |bar| _ = bar.claim(hwnd, .top, context.bar_thickness_px);
    }
    _ = updateInputRegion(context);
    Log.logLine("display change: window and renderer synchronized to monitor geometry");
    window.invalidate();
}

fn maintainShellState(context: ?*anyopaque) callconv(.winapi) void {
    if (context) |opaque_window| {
        const paint_context: *PaintContext = @ptrCast(@alignCast(opaque_window));
        if (paint_context.window) |window| window.invalidate();
    }
    if (!manage_native_taskbar) return;
    _ = native_taskbar.ensureHidden();
    if (release_taskbar_strip) _ = native_taskbar.ensureWorkAreaReleased();
}

fn runSmokeCheck(name: []const u8, exit_code: i32, check: *const fn () bool) ?i32 {
    var line: [192]u8 = undefined;
    const running = std.fmt.bufPrint(&line, "self-test: {s} ...", .{name}) catch return exit_code;
    Log.logAndPrint(running);
    if (check()) {
        const passed = std.fmt.bufPrint(&line, "self-test: {s}: PASS", .{name}) catch return null;
        Log.logAndPrint(passed);
        return null;
    }
    const failed = std.fmt.bufPrint(&line, "self-test: {s}: FAIL", .{name}) catch return exit_code;
    Log.logAndPrint(failed);
    return exit_code;
}

fn runSelfTest() i32 {
    const self_test_com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (self_test_com_result < 0 and self_test_com_result != rpc_e_changed_mode) return 3;
    const self_test_com_initialized = self_test_com_result >= 0;
    defer if (self_test_com_initialized) CoUninitialize();
    if (runSmokeCheck("command-line parsing", 51, CommandLine.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("media source fallback policy", 50, mediaSourcePolicyCheck)) |failure| return failure;
    if (runSmokeCheck("card opening and closing latch", 55, cardTransitionPolicyCheck)) |failure| return failure;
    if (runSmokeCheck("card button anchors", 56, cardAnchorPolicyCheck)) |failure| return failure;
    if (runSmokeCheck("MiniJson", 12, MiniJson.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Notification", 13, Notification.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("DisplayBrightness", 14, DisplayBrightness.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Monitor", 15, Monitor.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("NotificationIcon", 16, NotificationIcon.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("StartMenu", 17, StartMenu.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Log", 18, Log.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("MusicSession", 36, MusicSession.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("ToastStore", 20, ToastStore.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("AppBar", 21, AppBar.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("PlayerWindow", 22, PlayerWindow.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WindowList", 23, WindowList.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Theme", 24, Theme.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WeChatWatch", 25, WeChatWatch.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("ThumbnailPreview", 26, ThumbnailPreview.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("NativeTaskbar", 27, NativeTaskbar.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("SystemStatus", 28, SystemStatus.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("TrayIcons", 29, TrayIcons.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("SysStatusProbe", 30, SysStatusProbe.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("GlassMaterial", 31, GlassMaterial.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WicImage", 32, WicImage.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("music-card background blur", 58, WicImage.backgroundBlurCheck)) |failure| return failure;
    if (runSmokeCheck("SystemToggles", 33, SystemToggles.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("AudioVolume", 34, AudioVolume.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Weather", 35, Weather.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Lyrics", 37, Lyrics.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Lyrics", 50, Lyrics.workerSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("SoundOutput", 38, SoundOutput.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("StartApps", 39, StartApps.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("TrayPress", 40, TrayPress.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Renderer", 41, Renderer.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("per-window DPI awareness", 53, nativeWindowDpiCheck)) |failure| return failure;
    if (runSmokeCheck("animated input region", 54, InputRegion.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("native hit-test policy", 51, nativeHitTestPolicyCheck)) |failure| return failure;
    if (runSmokeCheck("taskbar state restore", 59, Diagnostics.taskbarStateRoundTripCheck)) |failure| return failure;
    if (runSmokeCheck("adaptive frame pacing", 52, framePacingPolicyCheck)) |failure| return failure;
    var test_text_renderer = TextRenderer.TextRenderer{};
    if (!test_text_renderer.initialize()) {
        Log.logAndPrint("self-test: DirectWrite initialization failed");
        return 47;
    }
    defer test_text_renderer.shutdown();
    const widest_status = test_text_renderer.measureStatusLine(
        &.{ 0x5468, 0x4e09 },
        &.{ '1', '2', 0x6708, '2', '8', 0x65e5 },
        &.{ '2', '3', ':', '5', '9' },
        &.{ 0x5f3a, 0x9635, 0x96e8 },
        &.{ '-', '1', '2', 0x00b0 },
        0,
    );
    const no_weather_status = test_text_renderer.measureStatusLine(
        &.{ 0x5468, 0x4e09 },
        &.{ '1', '2', 0x6708, '2', '8', 0x65e5 },
        &.{ '2', '3', ':', '5', '9' },
        &.{},
        &.{},
        -1,
    );
    if (widest_status <= 0 or widest_status > Geometry.pill_width_dip - 16 or
        no_weather_status <= 0 or no_weather_status >= widest_status)
    {
        logFormatted("self-test: clock/status layout invalid: weather={d:.2}, plain={d:.2}", .{ widest_status, no_weather_status });
        return 48;
    }
    var renderer_test_window = IslandWindow.NativeWindow{};
    if (!renderer_test_window.create(0, 0, 220, 36, 0, paintWindow, null, null)) {
        Log.logAndPrint("self-test: compact renderer HWND creation failed");
        return 41;
    }
    const renderer_window_ok = Renderer.nativeWindowCheck(renderer_test_window.handle(), 220, 36, 1, &test_text_renderer, .compact);
    renderer_test_window.destroy();
    if (!renderer_window_ok) {
        logFormatted("self-test: compact renderer GPU/readback check failed during {s}", .{Renderer.last_native_check_failure});
        return 41;
    }
    var renderer_card_test_window = IslandWindow.NativeWindow{};
    if (!renderer_card_test_window.create(0, 0, 520, 280, 0, paintWindow, null, null)) {
        Log.logAndPrint("self-test: card renderer HWND creation failed");
        return 41;
    }
    const renderer_card_ok = Renderer.nativeWindowCheck(renderer_card_test_window.handle(), 520, 280, 1, &test_text_renderer, .card);
    renderer_card_test_window.destroy();
    if (!renderer_card_ok) {
        logFormatted("self-test: card renderer GPU/readback check failed during {s} (HRESULT 0x{X}, background PNG {d} bytes, luminance {d:.2} -> {d:.2})", .{
            Renderer.last_native_check_failure,
            @as(u32, @bitCast(Renderer.last_native_check_hresult)),
            Renderer.last_background_png_length,
            Renderer.last_background_luminance_with,
            Renderer.last_background_luminance_without,
        });
        return 41;
    }
    var diagnostic_checks: [14]Diagnostics.Check = undefined;
    const diagnostic_count = Diagnostics.runChecks(&diagnostic_checks);
    var diagnostic_failures: usize = 0;
    Log.logAndPrint("IslandBar runtime self-test checks:");
    for (diagnostic_checks[0..diagnostic_count]) |check| {
        var line: [160]u8 = undefined;
        const message = std.fmt.bufPrint(&line, "  [{s}] {s}", .{
            if (check.passed) "PASS" else "FAIL",
            check.name,
        }) catch continue;
        Log.logAndPrint(message);
        if (!check.passed) diagnostic_failures += 1;
    }
    if (diagnostic_failures != 0) return 42;
    if (!IslandWindow.smokeCheck()) return 43;
    if (!TextRenderer.smokeCheck()) return 44;
    if (!Setup.smokeCheck()) return 45;
    if (!TaskStripLayout.smokeCheck()) return 46;
    if (!CardLayout.smokeCheck()) return 49;
    const pill = Geometry.pillBox(0.0, 0.0, 1920.0, 0.0);
    if (!Geometry.contains(pill, 960.0, 24.0)) return 7;

    var motion: Motion.Motion = .{};
    motion.setAnchor(Motion.anchorForWindow(0.0, 0.0, 1920.0, 32.0));
    if (!motion.setTarget(.expanded)) return 8;
    if (!motion.tick(0.18)) return 9;
    if (motion.current().rect.bottom <= motion.current().rect.top) return 10;

    const next = StatePolicy.nextShape(.{
        .shape = .music_strip,
        .resting = .music_strip,
        .pointer_inside = true,
        .music_present = true,
        .pointer_on_island = true,
    });
    if (next != .expanded) return 11;

    // Keep the IPC integration probe after the renderer and UI checks. A host
    // policy may reject named-pipe clients even when all local rendering and
    // application behavior checks are still runnable.
    if (runSmokeCheck("NotificationPipe", 19, NotificationPipe.smokeCheck)) |failure| return failure;

    return 0;
}

const MusicPreviewStage = struct {
    state: Motion.IslandState,
    name: []const u8,
    fallback_title: bool = false,
};

const music_preview_stages = [_]MusicPreviewStage{
    .{ .state = .collapsed, .name = "resting pill" },
    .{ .state = .music_strip, .name = "strip + lyric" },
    .{ .state = .music_strip, .name = "strip + title", .fallback_title = true },
    .{ .state = .hover, .name = "hover" },
    .{ .state = .expanded, .name = "card" },
};

const MusicPreviewContext = struct {
    window: *IslandWindow.NativeWindow,
    renderer: *Renderer.DeviceResources,
    text_renderer: *TextRenderer.TextRenderer,
    motion: Motion.Motion,
    music_card: *const TextRenderer.MusicCardText,
    lyric: []const u8,
    stage: usize = 0,
    stage_started_ms: u64 = 0,
    last_tick_ms: u64 = 0,
    started: bool = false,
};

fn paintMusicPreview(window: HWND, raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *MusicPreviewContext = @ptrCast(@alignCast(raw));
    var paint: PaintStruct = undefined;
    if (BeginPaint(window, &paint) == null) return;
    const stage = music_preview_stages[context.stage];
    const music_text = if (stage.state == .music_strip or stage.state == .hover)
        (if (stage.fallback_title) context.music_card.title else context.lyric)
    else
        &.{};
    const pill = Renderer.PillAppearance{
        .box = context.motion.current(),
        .music_text = music_text,
        .music_card = if (stage.state == .expanded) context.music_card else null,
    };
    _ = context.renderer.renderPill(
        pill,
        context.text_renderer,
        if (stage.state == .expanded) .card else .compact,
        .{ .temperature_c = 0, .weather_code = -1 },
    );
    _ = EndPaint(window, &paint);
}

fn musicPreviewStep(raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *MusicPreviewContext = @ptrCast(@alignCast(raw));
    const now = GetTickCount64();
    if (!context.started) {
        context.started = true;
        context.stage_started_ms = now;
        context.last_tick_ms = now;
        _ = context.motion.setTarget(music_preview_stages[0].state);
        Log.logAndPrint("music preview: five shapes, four seconds each");
    }
    const elapsed_ms = now -| context.last_tick_ms;
    context.last_tick_ms = now;
    const dt = @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000.0;
    var redraw = context.motion.tick(dt);
    if (now -| context.stage_started_ms >= 4000) {
        context.stage += 1;
        if (context.stage >= music_preview_stages.len) {
            context.window.destroy();
            return;
        }
        context.stage_started_ms = now;
        _ = context.motion.setTarget(music_preview_stages[context.stage].state);
        logFormatted("  -> {s}", .{music_preview_stages[context.stage].name});
        redraw = true;
    }
    if (redraw or context.motion.isAnimating()) context.window.invalidate();
    context.window.setPointerPollInterval(if (context.motion.isAnimating()) animation_poll_ms else idle_poll_ms);
}

fn runMusicPreview() i32 {
    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (com_result < 0 and com_result != rpc_e_changed_mode) return 1;
    const initialized_com = com_result >= 0;
    defer if (initialized_com) CoUninitialize();

    const monitor = Monitor.queryMonitor(null);
    const width_px = Monitor.screenWidth(monitor);
    const height_px = Geometry.dipToPixels(Geometry.window_height_dip, monitor.dpi);
    if (width_px <= 0 or height_px <= 0) return 1;
    const scale = @as(f32, @floatFromInt(monitor.dpi)) / 96.0;

    var art_pixels: [64 * 64 * 4]u8 = undefined;
    for (0..64) |y| for (0..64) |x| {
        const offset = (y * 64 + x) * 4;
        const band: u8 = if ((x / 8 + y / 8) % 2 == 0) 0 else 28;
        art_pixels[offset + 0] = 190 -| @as(u8, @intCast(x * 2)) +| band;
        art_pixels[offset + 1] = 55 +| @as(u8, @intCast(y * 2)) +| band;
        art_pixels[offset + 2] = 120 +| @as(u8, @intCast((x + y) % 64 * 2)) +| band;
        art_pixels[offset + 3] = 255;
    };
    var artwork_png: [MusicSession.artwork_capacity]u8 = undefined;
    const artwork_len = WicImage.encodeBgraToPng(&art_pixels, 64, 64, &artwork_png);
    var background_png: [MusicSession.artwork_capacity]u8 = undefined;
    const background_len = if (artwork_len > 0)
        WicImage.makeBlurredBackgroundPng(artwork_png[0..artwork_len], 105, 59, &background_png)
    else
        0;
    var icon_png: [MusicSession.artwork_capacity]u8 = undefined;
    var player_path: [260]u16 = @splat(0);
    const player_found = MusicSession.executableFromAppId(&.{ 'Q', 'Q', 'M', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' }, &player_path);
    var icon_len: usize = 0;
    if (player_found) icon_len = MusicSession.fetchAppIconForTest(&player_path, &icon_png);
    if (icon_len == 0) {
        var self_path: [260]u16 = @splat(0);
        const path_len = GetModuleFileNameW(null, &self_path, @intCast(self_path.len));
        if (path_len > 0 and path_len < self_path.len) {
            icon_len = MusicSession.fetchAppIconForTest(self_path[0..path_len], &icon_png);
        }
    }
    logFormatted("music preview: artwork={s}, source icon={s}", .{
        if (artwork_len > 0) "generated" else "unavailable",
        if (icon_len > 0) "loaded" else "unavailable",
    });

    var card = TextRenderer.MusicCardText{
        .title = "东大街",
        .artist = "张超洋",
        .album = "东大街",
        .app = "QQ音乐",
        .playing = true,
        .position_ms = 93000,
        .duration_ms = 340000,
        .progress_fraction = 93000.0 / 340000.0,
        .artwork_png = if (artwork_len > 0) artwork_png[0..artwork_len] else &.{},
        .artwork_revision = 1,
        .background_png = if (background_len > 0) background_png[0..background_len] else &.{},
        .background_revision = if (background_len > 0) 1 else 0,
        .app_icon_png = if (icon_len > 0) icon_png[0..icon_len] else &.{},
        .app_icon_revision = if (icon_len > 0) 1 else 0,
    };
    _ = &card;

    var motion: Motion.Motion = .{};
    motion.setAnchor(Motion.anchorForWindow(
        Geometry.pixelsToDip(monitor.screen.left, monitor.dpi),
        Geometry.pixelsToDip(monitor.screen.top, monitor.dpi),
        Geometry.pixelsToDip(width_px, monitor.dpi),
        Geometry.pixelsToDip(Monitor.taskbarThickness(monitor), monitor.dpi),
    ));

    var window = IslandWindow.NativeWindow{};
    if (!window.create(monitor.screen.left, monitor.screen.top, width_px, height_px, 0, paintMusicPreview, null, null)) return 1;
    defer window.destroy();
    var renderer = Renderer.DeviceResources{};
    if (!renderer.initialize(window.handle(), @intCast(width_px), @intCast(height_px), scale)) return 1;
    defer renderer.shutdown();
    var text_renderer = TextRenderer.TextRenderer{};
    if (!text_renderer.initialize()) return 1;
    defer text_renderer.shutdown();

    var context = MusicPreviewContext{
        .window = &window,
        .renderer = &renderer,
        .text_renderer = &text_renderer,
        .motion = motion,
        .music_card = &card,
        .lyric = "我想要带着你去我的小城市看日落的时候",
    };
    window.callback_context = &context;
    window.setPointerCallback(musicPreviewStep);
    window.show();
    window.invalidate();
    return if (window.messageLoop() == 0) 0 else 1;
}

const DemoContext = struct {
    window: *IslandWindow.NativeWindow,
    renderer: *Renderer.DeviceResources,
    text_renderer: ?*TextRenderer.TextRenderer,
    motion: Motion.Motion,
    stage: usize = 0,
    stage_started_ms: u64 = 0,
    last_tick_ms: u64 = 0,
    started: bool = false,
};

fn paintDemo(window: HWND, raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *DemoContext = @ptrCast(@alignCast(raw));
    var paint: PaintStruct = undefined;
    if (BeginPaint(window, &paint) == null) return;
    const pill = Renderer.PillAppearance{ .box = context.motion.current() };
    _ = context.renderer.renderPill(
        pill,
        context.text_renderer,
        .compact,
        .{ .temperature_c = 0, .weather_code = -1 },
    );
    _ = EndPaint(window, &paint);
    if (context.motion.isAnimating()) _ = context.renderer.waitForCompositorClock(8);
}

fn demoStep(raw_context: ?*anyopaque) callconv(.winapi) void {
    const raw = raw_context orelse return;
    const context: *DemoContext = @ptrCast(@alignCast(raw));
    const now = GetTickCount64();
    const steps = [_]struct { state: Motion.IslandState, duration_ms: u64 }{
        .{ .state = .collapsed, .duration_ms = 1200 },
        .{ .state = .hover, .duration_ms = 1500 },
        .{ .state = .expanded, .duration_ms = 2000 },
        .{ .state = .hover, .duration_ms = 1500 },
        .{ .state = .collapsed, .duration_ms = 1200 },
    };

    if (!context.started) {
        context.started = true;
        context.stage_started_ms = now;
        context.last_tick_ms = now;
        _ = context.motion.setTarget(steps[0].state);
        Log.logAndPrint("IslandBar demo: collapsed -> hover -> expanded -> hover -> collapsed");
        logFormatted("  -> {s} for {d:.1}s", .{ Motion.stateName(steps[0].state), @as(f64, @floatFromInt(steps[0].duration_ms)) / 1000.0 });
    }

    const elapsed_ms = now -| context.last_tick_ms;
    context.last_tick_ms = now;
    const dt = @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000.0;
    var redraw = context.motion.tick(dt);

    if (now -| context.stage_started_ms >= steps[context.stage].duration_ms) {
        context.stage += 1;
        if (context.stage >= steps.len) {
            context.window.destroy();
            return;
        }
        context.stage_started_ms = now;
        _ = context.motion.setTarget(steps[context.stage].state);
        logFormatted("  -> {s} for {d:.1}s", .{
            Motion.stateName(steps[context.stage].state),
            @as(f64, @floatFromInt(steps[context.stage].duration_ms)) / 1000.0,
        });
        redraw = true;
    }

    if (redraw or context.motion.isAnimating()) context.window.invalidate();
    context.window.setPointerPollInterval(if (context.motion.isAnimating()) animation_poll_ms else idle_poll_ms);
}

fn runDemo() i32 {
    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (com_result < 0 and com_result != rpc_e_changed_mode) return 1;
    const initialized_com = com_result >= 0;
    defer if (initialized_com) CoUninitialize();

    const monitor = Monitor.queryMonitor(null);
    const width_px = Monitor.screenWidth(monitor);
    const height_px = Geometry.dipToPixels(Geometry.window_height_dip, monitor.dpi);
    if (width_px <= 0 or height_px <= 0) return 1;
    const scale = @as(f32, @floatFromInt(monitor.dpi)) / 96.0;

    var motion: Motion.Motion = .{};
    motion.setAnchor(Motion.anchorForWindow(
        Geometry.pixelsToDip(monitor.screen.left, monitor.dpi),
        Geometry.pixelsToDip(monitor.screen.top, monitor.dpi),
        Geometry.pixelsToDip(width_px, monitor.dpi),
        Geometry.pixelsToDip(Monitor.taskbarThickness(monitor), monitor.dpi),
    ));

    var window = IslandWindow.NativeWindow{};
    if (!window.create(monitor.screen.left, monitor.screen.top, width_px, height_px, 0, paintDemo, null, null)) return 1;
    defer window.destroy();

    var renderer = Renderer.DeviceResources{};
    if (!renderer.initialize(window.handle(), @intCast(width_px), @intCast(height_px), scale)) return 1;
    defer renderer.shutdown();

    var text_renderer = TextRenderer.TextRenderer{};
    const text_ready = text_renderer.initialize();
    defer if (text_ready) text_renderer.shutdown();

    var context = DemoContext{
        .window = &window,
        .renderer = &renderer,
        .text_renderer = if (text_ready) &text_renderer else null,
        .motion = motion,
    };
    window.callback_context = &context;
    window.setPointerCallback(demoStep);
    window.show();
    window.invalidate();
    const result = window.messageLoop();
    return if (result == 0) 0 else 1;
}

pub fn main() void {
    const options = CommandLine.runtimeOptions();
    const console_status = Log.prepareConsole(options.self_test or options.demo or options.probe_taskbar, options.no_console);
    Log.openLog();
    var console_line: [128]u8 = undefined;
    Log.logLine(console_status.summary(&console_line));

    // Match the C++ startup diagnostic: explain whether UIPI will block
    // messages from this process to Explorer before any taskbar operation is
    // attempted. This check only reads process integrity levels.
    var integrity_probe = NativeTaskbar.NativeTaskbar{};
    _ = integrity_probe.locate();
    const below_shell_integrity = integrity_probe.isBlockedByIntegrity();
    Log.logLine(if (below_shell_integrity)
        "integrity: LOWER than the shell -- synthetic input and window messages aimed at Explorer will be discarded (start the bar from your own shell)"
    else
        "integrity: same as the shell -- this process may act on Explorer");
    integrity_probe.deinit();

    enablePerMonitorV2();
    if (options.help) {
        Log.openLog();
        printHelp();
        Log.closeLog();
        return;
    }
    if (options.demo) {
        Log.openLog();
        const result = runDemo();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.music_preview) {
        Log.openLog();
        const result = runMusicPreview();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.probe_taskbar) {
        Log.openLog();
        const result = Diagnostics.runTaskbarProbe();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.notify) {
        Log.openLog();
        const result = runNotify();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.window_list) {
        Log.openLog();
        const result = runWindowList(options.activate_window);
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.tray_dump) {
        Log.openLog();
        const result = runTrayDump();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.tray_surface) {
        Log.openLog();
        const result = runTraySurface();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.toast_dump) {
        Log.openLog();
        const result = runToastDump(options.toast_limit);
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.tray_press) |index| {
        Log.openLog();
        const result = runTrayPress(index, options.tray_fire, options.tray_right);
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.icon_dump) {
        Log.openLog();
        const result = runIconDump();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.volume_test) {
        Log.openLog();
        const result = runVolumeTest();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.volume_set) |percent| {
        Log.openLog();
        const result = runVolumeSet(percent);
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.lyrics_test) {
        Log.openLog();
        const result = runLyricsTestFromCommandLine(options.lyrics_verbose);
        Log.closeLog();
        ExitProcess(@intCast(result));
    }
    if (options.self_test) {
        Log.openLog();
        const result = runSelfTest();
        Log.closeLog();
        ExitProcess(@intCast(result));
    }

    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    if (com_result < 0 and com_result != rpc_e_changed_mode) ExitProcess(4);
    const initialized_com = com_result >= 0;
    Log.openLog();
    defer Log.closeLog();
    const single_instance = CreateMutexW(null, 1, single_instance_name);
    if (single_instance == null) {
        if (initialized_com) CoUninitialize();
        ExitProcess(5);
    }
    if (GetLastError() == error_already_exists) {
        _ = CloseHandle(single_instance);
        if (initialized_com) CoUninitialize();
        ExitProcess(0);
    }
    defer _ = CloseHandle(single_instance);
    defer if (initialized_com) CoUninitialize();

    if (!options.keep_taskbar and native_taskbar.locate()) {
        _ = native_taskbar.hide();
        manage_native_taskbar = native_taskbar.weHidIt();
    }
    defer native_taskbar.restore();

    var monitor = Monitor.queryMonitor(null);
    var dpi = monitor.dpi;
    window_width_px = Monitor.screenWidth(monitor);
    window_height_px = Geometry.dipToPixels(Geometry.window_height_dip, dpi);
    const width_px = window_width_px;
    var height_px = window_height_px;
    const x = monitor.screen.left;
    const y = monitor.screen.top;

    var motion: Motion.Motion = .{};
    const anchor = Motion.anchorForWindow(
        Geometry.pixelsToDip(x, dpi),
        Geometry.pixelsToDip(y, dpi),
        Geometry.pixelsToDip(Monitor.screenWidth(monitor), dpi),
        Geometry.pixelsToDip(Monitor.taskbarThickness(monitor), dpi),
    );
    motion.setAnchor(anchor);
    if (options.system_panel) _ = motion.setTarget(.expanded);
    if (options.forced_state) |forced| _ = motion.setTarget(forced);

    var app_bar = AppBar.AppBar{};
    defer app_bar.release();

    var window = IslandWindow.NativeWindow{};
    if (!window.create(x, y, width_px, height_px, 0, paintWindow, maintainShellState, @ptrCast(&window))) return;
    defer window.destroy();
    const actual_window_dpi = window.dpi();
    if (actual_window_dpi != 0 and actual_window_dpi != dpi) {
        dpi = actual_window_dpi;
        monitor.dpi = actual_window_dpi;
        monitor.dpi_y = actual_window_dpi;
        height_px = Geometry.dipToPixels(Geometry.window_height_dip, dpi);
        window_height_px = height_px;
        if (!window.setBounds(x, y, width_px, height_px)) return;
        motion.setAnchor(Motion.anchorForWindow(
            Geometry.pixelsToDip(x, dpi),
            Geometry.pixelsToDip(y, dpi),
            Geometry.pixelsToDip(width_px, dpi),
            Geometry.pixelsToDip(Monitor.taskbarThickness(monitor), dpi),
        ));
    }
    window.setAppBar(&app_bar);

    var thumbnail_preview = ThumbnailPreview.ThumbnailPreview{};
    const thumbnail_preview_ready = thumbnail_preview.create(window.handle());
    Log.logLine(if (thumbnail_preview_ready) "thumbnail: task preview ready after 350 ms hover" else "thumbnail: preview window could not be created");
    defer thumbnail_preview.destroy();

    var app_bar_result: AppBar.AppBarResult = .no_window;
    const app_bar_thickness_px = Geometry.dipToPixels(Geometry.reserved_bar_height_dip, dpi);
    if (options.appbar and !options.keep_taskbar) {
        app_bar_result = app_bar.claim(window.handle(), .top, app_bar_thickness_px);
        Log.logLine(if (app_bar_result == .registered) "appbar: reserved the top work-area strip" else "appbar: reservation failed; using a floating bar");
    }
    if (!options.keep_taskbar and manage_native_taskbar and !options.keep_strip and app_bar_result != .registered) {
        const released = native_taskbar.releaseWorkArea();
        release_taskbar_strip = released.released;
        Log.logLine(if (released.released) "taskbar work-area strip released" else "taskbar work-area strip could not be released");
    } else if (options.keep_strip) {
        Log.logLine("taskbar work-area strip retained (--keep-strip)");
    } else if (app_bar_result == .registered) {
        Log.logLine("taskbar work-area strip remains reserved by the AppBar");
    }

    var renderer = Renderer.DeviceResources{};
    if (!renderer.initialize(window.handle(), @intCast(width_px), @intCast(height_px), @as(f32, @floatFromInt(dpi)) / 96.0)) return;
    defer renderer.shutdown();

    var text_renderer = TextRenderer.TextRenderer{};
    if (!text_renderer.initialize()) return;
    defer text_renderer.shutdown();

    var notification_server = NotificationPipe.NotificationServer{};
    const notification_server_started = notification_server.start(NotificationPipe.pipe_name);
    Log.logLine(if (notification_server_started) "notification pipe started" else "notification pipe could not be started");
    defer if (notification_server_started) notification_server.stop();
    var notifications = Notification.Store{};

    const no_media = environmentSwitchEnabled(wide_no_media);
    const no_session = environmentSwitchEnabled(wide_no_session);
    const media_sources = mediaSourceAvailabilityFor(no_media, no_session);
    var music_session = MusicSession.MusicSession{};
    const music_started = media_sources.session and music_session.start();
    Log.logLine(if (music_started)
        "music session worker started"
    else if (no_media)
        "music disabled by ISLANDBAR_NO_MEDIA"
    else if (no_session)
        "music session disabled by ISLANDBAR_NO_SESSION; player-window fallback remains active"
    else
        "music session API unavailable; continuing without music");
    defer if (music_started) {
        Log.logLine("shutdown: stopping music session worker");
        music_session.stop();
        Log.logLine("shutdown: music session worker stopped");
    };

    var lyrics_provider = Lyrics.LyricsProvider{};
    const lyrics_started = lyrics_provider.start();
    Log.logLine(if (lyrics_started) "lyrics worker started" else "lyrics worker unavailable; continuing without lyrics");
    defer {
        Log.logLine("shutdown: stopping lyrics worker");
        lyrics_provider.stop();
        Log.logLine("shutdown: lyrics worker stopped");
    }

    var player_window = PlayerWindow.PlayerWindowWatch{};
    const player_window_started = media_sources.player_window and player_window.start();
    Log.logLine(if (player_window_started)
        "player window fallback started"
    else if (no_media)
        "player window fallback disabled by ISLANDBAR_NO_MEDIA"
    else
        "player window fallback unavailable");
    defer if (player_window_started) {
        Log.logLine("shutdown: stopping player-window worker");
        player_window.stop();
        Log.logLine("shutdown: player-window worker stopped");
    };

    var status_reader = SystemStatus.SystemStatusReader{};
    _ = status_reader.open();
    defer status_reader.close();
    var sampled_system_status = SystemStatus.SystemStatus{};
    status_reader.sample(&sampled_system_status);
    var audio_volume = AudioVolume.AudioVolume{};
    const audio_volume_started = audio_volume.start();
    Log.logLine(if (audio_volume_started) "audio volume worker started" else "audio volume worker unavailable");
    defer audio_volume.stop();
    var initial_volume: f32 = 0;
    _ = audio_volume.get(&initial_volume);
    var sound_output = SoundOutput.SoundOutput{};
    const sound_started = sound_output.start();
    Log.logLine(if (sound_started) "sound output worker started" else "sound output worker unavailable");
    defer {
        Log.logLine("shutdown: stopping sound-output worker");
        sound_output.stop();
        Log.logLine("shutdown: sound-output worker stopped");
    }
    var tray_icons = TrayIcons.TrayIcons{};
    const initial_tray_count = tray_icons.refresh(std.heap.page_allocator);
    Log.logLine(if (initial_tray_count == 0) "tray icon snapshots unavailable or empty" else "tray icon snapshots loaded");
    defer tray_icons.deinit(std.heap.page_allocator);
    var start_apps = StartApps.StartApps{};
    start_apps.loadPins();
    defer start_apps.deinit();
    var account_name: [256]u16 = @splat(0);
    var account_name_size: u32 = @intCast(account_name.len);
    _ = GetUserNameW(&account_name, &account_name_size);
    const start_pin_icon_data = std.heap.page_allocator.alloc(u8, 18 * start_icon_buffer_bytes) catch return;
    defer std.heap.page_allocator.free(start_pin_icon_data);
    var initial_brightness: i32 = 50;
    const initial_brightness_available = DisplayBrightness.readBrightnessPercent(monitor.monitor, &initial_brightness);
    const fullscreen_disabled = environmentSwitchEnabled(wide_no_fullscreen);

    var paint_context = PaintContext{
        .renderer = &renderer,
        .text_renderer = &text_renderer,
        .pill = .{
            .box = motion.current(),
        },
        .motion = motion,
        .window = &window,
        .thumbnail_preview = if (thumbnail_preview_ready) &thumbnail_preview else null,
        .window_x = x,
        .window_y = y,
        .scale = @as(f32, @floatFromInt(dpi)) / 96.0,
        .music_session = if (music_started) &music_session else null,
        .audio_volume = if (audio_volume_started) &audio_volume else null,
        .tray_icons = &tray_icons,
        .tray_last_refresh_ms = GetTickCount64(),
        .start_apps = &start_apps,
        .start_pin_icon_data = start_pin_icon_data,
        .account_name = account_name,
        .sound_output = if (sound_started) &sound_output else null,
        .sound_snapshot = if (sound_started) sound_output.snapshot() else .{},
        .last_sound_revision = if (sound_started) sound_output.revision() else 0,
        .status_reader = &status_reader,
        .monitor = monitor.monitor,
        .monitor_bounds = monitor.screen,
        .monitor_work = monitor.work,
        .app_bar = &app_bar,
        .app_bar_reclaim = app_bar_result == .registered,
        .bar_thickness_px = app_bar_thickness_px,
        .fullscreen_disabled = fullscreen_disabled,
        .last_weather_revision = weather_reader.getRevision(),
        .system_status = sampled_system_status,
        .status_sampled_ms = GetTickCount64(),
        .installed_layout_count = status_reader.layoutCount(),
        .volume_level = initial_volume,
        .volume_muted = audio_volume.isMuted(),
        .brightness_available = initial_brightness_available,
        .brightness_percent = initial_brightness,
        .system_panel_pinned = options.system_panel,
        .forced_start_hover = options.start_hover,
        .forced_state = options.forced_state,
        .lyrics_provider = &lyrics_provider,
        .player_window = if (player_window_started) &player_window else null,
        .notification_server = if (notification_server_started) &notification_server else null,
        .notifications = &notifications,
    };
    _ = paint_context.task_windows.refresh();
    paint_context.task_last_refresh_ms = GetTickCount64();
    buildSystemPanelText(&paint_context);
    buildSoundPageText(&paint_context);
    buildTrayPageText(&paint_context);
    buildStartCardText(&paint_context);
    window.callback_context = &paint_context;
    window.setPointerCallback(pointerStep);
    window.setDisplayChangeCallback(refreshDisplayGeometry);
    window.setHitTestCallback(nativeHitTest);
    window.setCursorHitTestCallback(nativeCursorHitTest);
    window.setWheelHitTestCallback(nativeWheelHitTest);
    _ = updateInputRegion(&paint_context);

    if (!renderer.renderPill(paint_context.pill, &text_renderer, paint_context.clock_style, .{ .temperature_c = 0, .weather_code = -1 })) return;

    var weather_started = false;
    if (!options.offline) {
        weather_started = weather_reader.start();
        if (!weather_started) Log.logLine("weather worker could not be started");
    }
    defer if (weather_started) {
        Log.logLine("shutdown: stopping weather worker");
        weather_reader.stop();
        Log.logLine("shutdown: weather worker stopped");
    };
    window.show();
    const loop_result = window.messageLoop();
    if (loop_result != 0) ExitProcess(6);
}
