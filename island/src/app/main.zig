const std = @import("std");
const CommandLine = @import("CommandLine");
const Geometry = @import("Geometry");
const InputRegion = @import("InputRegion");
const GlassMaterial = @import("GlassMaterial");
const WicImage = @import("WicImage");
const AppIconService = @import("AppIconService");
const AppBar = @import("AppBar");
const AudioVolume = @import("AudioVolume");
const WeatherService = @import("WeatherService");
const WeatherController = @import("WeatherController");
const WeatherPage = @import("WeatherPage");
const StatusLineWeather = @import("StatusLineWeather");
const MediaService = @import("MediaService");
const MusicController = @import("MusicController");
const MusicPage = @import("MusicPage");
const Lyrics = @import("MusicLyrics");
const LyricsService = @import("LyricsService");
const AudioService = @import("AudioService");
const SoundController = @import("SoundController");
const SoundPage = @import("SoundPage");
const LauncherController = @import("LauncherController");
const LauncherPage = @import("LauncherPage");
const LauncherService = @import("LauncherService");
const TrayCatalog = @import("TrayCatalog");
const TrayController = @import("TrayController");
const TrayPage = @import("TrayPage");
const TrayPress = @import("TrayPress");
const Renderer = @import("Renderer");
const PresentationPolicy = @import("PresentationPolicy");
const Diagnostics = @import("Diagnostics");
const IslandWindow = @import("IslandWindow");
const TextRenderer = @import("TextRenderer");
const InputRouter = @import("InputRouter");
const Setup = @import("Setup");
const Log = @import("Log");
const Motion = @import("Motion");
const PlayerWindow = @import("PlayerWindow");
const SystemService = @import("SystemService");
const MiniJson = @import("MiniJson");
const Monitor = @import("Monitor");
const NativeTaskbar = @import("NativeTaskbar");
const Notification = @import("Notification");
const NotificationIcon = @import("NotificationIcon");
const NotificationInput = @import("NotificationInput");
const NotificationPage = @import("NotificationPage");
const NotificationPipe = @import("NotificationPipe");
const ShellCommand = @import("ShellCommand");
const StatePolicy = @import("StatePolicy");
const SystemController = @import("SystemController");
const SystemPage = @import("SystemPage");
const SystemLayout = @import("SystemLayout");
const SysStatusProbe = @import("SysStatusProbe");
const TaskbarCatalog = @import("TaskbarCatalog");
const TaskbarController = @import("TaskbarController");
const TaskbarLayout = @import("TaskbarLayout");
const TaskbarPage = @import("TaskbarPage");
const ThumbnailAdapter = @import("ThumbnailAdapter");
const ThumbnailLayout = @import("ThumbnailLayout");
const Theme = @import("Theme");
const ToastStore = @import("ToastStore");
const TrayIcons = @import("TrayIcons");
const WindowList = @import("WindowList");
const WeChatWatch = @import("WeChatWatch");
const BarControlLayout = @import("BarControlLayout");
const CardLayout = @import("CardLayout");
const LayoutSnapshot = @import("LayoutSnapshot");
const AppRuntime = @import("AppRuntime");
const AppWindowHost = @import("AppWindowHost");

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
const FileTime = extern struct { low: u32, high: u32 };
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
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
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
extern "kernel32" fn GetProcessTimes(process: HANDLE, creation: *FileTime, exit_time: *FileTime, kernel_time: *FileTime, user_time: *FileTime) callconv(.winapi) i32;
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

const wide_open_verb: [*:0]const u16 = &.{ 'o', 'p', 'e', 'n', 0 };
const wide_explorer: [*:0]const u16 = &.{ 'e', 'x', 'p', 'l', 'o', 'r', 'e', 'r', '.', 'e', 'x', 'e', 0 };
const shutdown_privilege: [*:0]const u16 = &.{ 'S', 'e', 'S', 'h', 'u', 't', 'd', 'o', 'w', 'n', 'P', 'r', 'i', 'v', 'i', 'l', 'e', 'g', 'e', 0 };
const start_icon_buffer_bytes: usize = 16 * 1024;
const uri_sound: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 's', 'o', 'u', 'n', 'd', 0 };
const uri_settings: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 0 };

fn buildSystemPanelText(context: *PaintContext) void {
    var volume: f32 = 0;
    var muted = false;
    if (context.sound_controller) |sound| {
        volume = sound.state.displayedMasterLevel();
        muted = sound.state.displayedMuted();
    }
    SystemPage.build(&context.system_panel_view, &context.system_state, systemPanelCardBox(context), volume, muted);
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
            .exe_path = info.exe_path,
        };
        context.tray_page_icon_count += 1;
    }
    context.tray_page_revision = source.getRevision();
    _ = TrayController.catalogChanged(&context.tray_state, context.tray_page_revision);
    context.tray_card_text.icons = context.tray_page_icons[0..context.tray_page_icon_count];
    context.tray_card_text.title = &.{ 0x6258, 0x76D8 };
}

fn buildStartCardText(context: *PaintContext) void {
    const apps = context.start_apps orelse {
        context.start_card_text = .{};
        return;
    };
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
        .pin_icons = context.start_pin_icons[0..pin_count],
        .pin_icon_sizes = context.start_pin_icon_sizes[0..pin_count],
        .pin_icon_revision = apps.iconRevision(),
        .list = apps.list.items,
        .hovered_pin = context.start_card_text.hovered_pin,
        .hovered_picker_row = context.start_card_text.hovered_picker_row,
        .hovered_power_row = context.start_card_text.hovered_power_row,
        .power_button_hovered = context.start_card_text.power_button_hovered,
        .power_confirm_row = context.launcher_state.power_confirm_row,
        .account_name = std.mem.sliceTo(&context.account_name, 0),
    };
    context.last_start_icon_revision = apps.iconRevision();
}
fn paintClock(window: HWND, weather_state: ?*const WeatherController.State) void {
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
    if (weather_state) |state| WeatherPage.weatherLineFor(state.reading, &weather_line);
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
const wide_ui_trace: [*:0]const u16 = &.{ 'I', 'S', 'L', 'A', 'N', 'D', 'B', 'A', 'R', '_', 'T', 'R', 'A', 'C', 'E', '_', 'U', 'I', 0 };
fn runNotify() i32 {
    var notification = NotificationInput.Message{};
    var title: [NotificationInput.title_capacity * 4]u8 = undefined;
    var body: [NotificationInput.body_capacity * 4]u8 = undefined;
    var app: [NotificationInput.app_name_capacity * 4]u8 = undefined;
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
    if (!MediaService.executableFromAppId(app_id_wide[0..app_id_length], &executable)) {
        logFormatted("icon dump: '{s}' did not resolve to an executable", .{app_id_utf8});
        return 1;
    }
    var executable_utf8: [1024]u8 = undefined;
    logFormatted("icon dump: resolved to {s}", .{CommandLine.wideTextToUtf8(&executable, &executable_utf8)});

    var png: [MediaService.artwork_capacity]u8 = undefined;
    const png_size = AppIconService.fetchFileIconPng(&executable, &png);
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
    var report = LyricsService.LyricsFetchReport{};
    var reason: [384]u8 = @splat(0);
    const ok = LyricsService.fetchLyricsVerbose(title, artist, 10_000, &lyrics, &reason, &report);
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

fn dumpLyricAttempt(name: []const u8, attempt: *const LyricsService.FetchAttempt) void {
    logFormatted("  {s} search: HTTP {d}  {s}", .{ name, attempt.search_status, std.mem.sliceTo(&attempt.search_url, 0) });
    if (attempt.search_body[0] != 0) logFormatted("    <- {s}", .{std.mem.sliceTo(&attempt.search_body, 0)[0..@min(400, std.mem.sliceTo(&attempt.search_body, 0).len)]});
    logFormatted("  {s} lyric : HTTP {d}  {s}", .{ name, attempt.lyric_status, std.mem.sliceTo(&attempt.lyric_url, 0) });
    if (attempt.lyric_body[0] != 0) logFormatted("    <- {s}", .{std.mem.sliceTo(&attempt.lyric_body, 0)[0..@min(400, std.mem.sliceTo(&attempt.lyric_body, 0).len)]});
    logFormatted("  {s} verdict: {s}", .{ name, if (attempt.verdict[0] != 0) std.mem.sliceTo(&attempt.verdict, 0) else "(nothing recorded)" });
}

fn dispatchSoundAction(context: *PaintContext, action: SoundController.Action) SoundController.Dispatch {
    const controller = context.sound_controller orelse return .unavailable;
    return controller.dispatch(action, GetTickCount64());
}

const TaskHoverMotion = struct {
    window_id: TaskbarCatalog.WindowId = 0,
    progress: f32 = 0,
    velocity: f32 = 0,
};

const TaskIconTransitionKind = enum { appear, move, disappear };
const TaskIconTransition = struct {
    window_id: TaskbarCatalog.WindowId = 0,
    started_ms: u64 = 0,
    kind: TaskIconTransitionKind = .appear,
    from_offset_x: f32 = 0,
    button: TextRenderer.TaskButton = .{},
};

const task_icon_transition_duration_ms: u64 = 180;
const max_task_icon_transitions: usize = TaskbarLayout.max_task_icons * 2;

const PaintContext = struct {
    renderer: *Renderer.DeviceResources,
    renderer_generation: u64 = 0,
    last_graphics_recovery_ms: u64 = 0,
    last_frame_duration_ms: u64 = 0,
    render_failure_active: bool = false,
    last_render_failure_stage: []const u8 = "",
    last_render_failure_hresult: u32 = 0,
    last_render_failure_tag1: u64 = 0,
    last_render_failure_tag2: u64 = 0,
    render_retry_at_ms: u64 = 0,
    render_retry_delay_ms: u64 = 250,
    trace_ui_enabled: bool = false,
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
    taskbar_state: TaskbarController.State = .{},
    task_hover_motions: [TaskbarLayout.max_task_icons]TaskHoverMotion = @splat(.{}),
    task_hover_leave_deadline_ms: u64 = 0,
    task_icon_transitions: [max_task_icon_transitions]TaskIconTransition = @splat(.{}),
    task_icon_transition_count: usize = 0,
    task_icon_transition_revision: ?u64 = null,
    task_icon_transition_deadline_ms: u64 = 0,
    tray_dock_shift_started_ms: u64 = 0,
    tray_dock_shift_from_x: f32 = 0,
    candidate_taskbar_snapshot: TaskbarCatalog.Snapshot = .{},
    candidate_taskbar_view: TaskbarPage.View = .{},
    presented_taskbar_view: TaskbarPage.View = .{},
    task_overflow_open: bool = false,
    task_last_refresh_ms: u64 = 0,
    task_buttons: [Renderer.max_task_buttons]TextRenderer.TaskButton = @splat(.{}),
    thumbnail_preview: ?*ThumbnailAdapter.ThumbnailAdapter = null,
    thumbnail_target_id: ?TaskbarCatalog.WindowId = null,
    thumbnail_target_since_ms: u64 = 0,
    thumbnail_reported_refusals: i32 = 0,
    music_session: ?*MediaService.MusicSession = null,
    sound_controller: ?*SoundController.Controller = null,
    sound_ports: ?*AppRuntime.SoundPortContext = null,
    weather_reader: ?*WeatherService.WeatherReader = null,
    weather_state: WeatherController.State = .{},
    status_reader: ?*SystemService.StatusReader = null,
    monitor: Monitor.HMONITOR = null,
    monitor_bounds: Monitor.Rect = .{},
    monitor_work: Monitor.Rect = .{},
    app_bar: ?*AppBar.AppBar = null,
    app_bar_reclaim: bool = false,
    bar_thickness_px: i32 = 0,
    fullscreen_app: bool = false,
    fullscreen_candidate: ?bool = null,
    fullscreen_candidate_samples: u8 = 0,
    fullscreen_last_poll_ms: u64 = 0,
    fullscreen_disabled: bool = false,
    fullscreen_morph_progress: f32 = 0,
    fullscreen_morph_from: f32 = 0,
    fullscreen_morph_target: f32 = 0,
    fullscreen_morph_started_ms: u64 = 0,
    fullscreen_morph_source_box: Geometry.RoundedBox = .{ .rect = .{} },
    last_weather_revision: u64 = 0,
    music_wave_phase: f32 = 0,
    music_wave_accent: MediaService.ArtworkAccent = .{},
    last_wave_artwork_revision: u64 = std.math.maxInt(u64),
    music_meter_redraw_ms: u64 = 0,
    system_state: SystemController.State = .{},
    status_sampled_ms: u64 = 0,
    system_panel_pinned: bool = false,
    presentation: PresentationPolicy.State = .{},
    card_hang: BarControlLayout.CardHang = .overflow_button,
    forced_state: ?Motion.IslandState = null,
    system_panel_view: SystemPage.View = .{},
    tray_icons: ?*TrayIcons.TrayIcons = null,
    tray_page_icons: [TrayPage.max_icons]TrayCatalog.Icon = @splat(.{}),
    tray_page_icon_count: usize = 0,
    tray_page_revision: u64 = 0,
    tray_last_refresh_ms: u64 = 0,
    tray_state: TrayController.State = .{},
    tray_card_text: TrayPage.CardText = .{},
    candidate_tray_view: TrayPage.View = .{},
    presented_tray_view: TrayPage.View = .{},
    start_apps: ?*LauncherService.StartApps = null,
    start_page_open: bool = false,
    launcher_state: LauncherController.State = .{},

    start_button_wash: f32 = 0,
    start_button_velocity: f32 = 0,
    system_button_wash: f32 = 0,
    system_button_velocity: f32 = 0,
    tray_button_wash: f32 = 0,
    tray_button_velocity: f32 = 0,
    tray_entry_wash: f32 = 0,
    tray_entry_velocity: f32 = 0,
    forced_start_hover: bool = false,
    start_pin_icons: [18]?[]const u8 = @splat(null),
    start_pin_icon_sizes: [18]usize = @splat(0),
    start_pin_icon_data: []u8 = &.{},
    start_card_text: LauncherPage.CardText = .{},
    candidate_launcher_layout: LauncherPage.View = .{},
    presented_launcher_layout: LauncherPage.View = .{},
    last_start_icon_revision: u64 = 0,
    account_name: [256]u16 = @splat(0),
    sound_page_open: bool = false,
    sound_page_state: SoundPage.LocalState = .{},
    candidate_sound_layout: LayoutSnapshot.Snapshot = .{},
    presented_sound_layout: LayoutSnapshot.Snapshot = .{},
    candidate_music_layout: LayoutSnapshot.Snapshot = .{},
    presented_music_layout: LayoutSnapshot.Snapshot = .{},
    layout_snapshot_generation: u64 = 0,
    input_router: InputRouter.Router = .{},
    pending_press_point: ?IslandWindow.Point = null,
    pending_press_action_handled: bool = false,
    lyrics_provider: ?*LyricsService.LyricsProvider = null,
    player_window: ?*PlayerWindow.PlayerWindowWatch = null,
    notification_server: ?*NotificationPipe.NotificationServer = null,
    notifications: ?*Notification.Store = null,
    notification_shown: Notification.Notification = .{},
    have_notification_shown: bool = false,
    notification_card_view: NotificationPage.View = .{},
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
    music_state: MusicController.State = .{},
    player_snapshot: PlayerWindow.PlayerWindowInfo = .{},
    last_music_revision: u64 = 0,
    last_player_revision: i64 = 0,
    last_lyrics_revision: u64 = 0,
    last_music_reading_ms: u64 = 0,
    music_card_text: MusicPage.CardText = .{},
    music_strip_text: MusicPage.StripText = .{},
    music_background_png: [MediaService.artwork_capacity]u8 = @splat(0),
    music_background_png_size: usize = 0,
    music_background_revision: u64 = 0,
    last_music_card_second: i64 = -1,
    current_lyric_line: Lyrics.LyricLine = .{},
    shown_lyric_text: [Lyrics.line_capacity]u8 = @splat(0),
    replaced_lyric_text: [Lyrics.line_capacity]u8 = @splat(0),
    lyric_line_age_seconds: f32 = 1,
    lyric_scroll_dip: f32 = 0,
    replaced_lyric_scroll_dip: f32 = 0,
};

const animation_poll_ms: u32 = 16;
const task_hover_poll_ms: u32 = 10;
const task_hover_idle_poll_ms: u32 = 24;
const task_window_refresh_fallback_ms: u64 = 500;
const fullscreen_morph_duration_ms: u64 = 360;
const fullscreen_morph_poll_ms: u32 = 8;
const task_hover_expand_omega: f32 = 20;
const task_hover_retract_omega: f32 = 16;
const task_hover_spring_damping: f32 = 1;
const task_hover_leave_delay_ms: u64 = 140;
const music_poll_ms: u32 = 33;
const call_poll_ms: u32 = 50;
const idle_poll_ms: u32 = 100;

fn pointerPollIntervalFor(animation_active: bool, task_hover_active: bool, task_hover_present: bool, call_active: bool, music_active: bool) u32 {
    if (task_hover_active) return task_hover_poll_ms;
    if (task_hover_present) return task_hover_idle_poll_ms;
    if (animation_active) return animation_poll_ms;
    if (call_active) return call_poll_ms;
    if (music_active) return music_poll_ms;
    return idle_poll_ms;
}

fn framePacingPolicyCheck() bool {
    return pointerPollIntervalFor(true, false, false, true, true) == animation_poll_ms and
        pointerPollIntervalFor(true, true, false, true, true) == task_hover_poll_ms and
        pointerPollIntervalFor(false, false, true, true, true) == task_hover_idle_poll_ms and
        pointerPollIntervalFor(false, false, false, true, true) == call_poll_ms and
        pointerPollIntervalFor(false, false, false, false, true) == music_poll_ms and
        pointerPollIntervalFor(false, false, false, false, false) == idle_poll_ms;
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
    const open = PresentationPolicy.next(.{}, .{
        .card_up = true,
        .card_wanted = true,
        .music_present = true,
        .panel_wanted = true,
        .tray_wanted = true,
    });
    const closing = PresentationPolicy.next(open, .{ .card_up = true });
    const closed = PresentationPolicy.next(closing, .{});
    return open.card_owner == .system_panel and open.panel_level == .tray and
        closing.card_owner == .system_panel and closing.panel_level == .tray and
        closed.card_owner == .none and closed.panel_level == .tiles;
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
    context.presented_taskbar_view = TaskbarPage.buildDockView(resting, &.{}, 0, 0, 2560, false);
    const overflow_button = context.presented_taskbar_view.overflow_button_bounds;
    const system = systemPanelCardBox(&context);
    const system_centre = BarControlLayout.deckCardAnchorCentre(resting, .overflow_button, overflow_button);
    if (@abs((system.rect.left + system.rect.right) * 0.5 - system_centre) > 0.01) return false;

    context.card_hang = .tray_button;
    const tray = systemPanelCardBox(&context);
    const tray_centre = BarControlLayout.deckCardAnchorCentre(resting, .tray_button, overflow_button);
    if (@abs((tray.rect.left + tray.rect.right) * 0.5 - tray_centre) > 0.01) return false;
    context.card_hang = .start_button;
    const start = systemPanelCardBox(&context);
    const start_centre = BarControlLayout.deckCardAnchorCentre(resting, .start_button, overflow_button);
    if (@abs((start.rect.left + start.rect.right) * 0.5 - start_centre) > 0.01) return false;

    context.card_hang = .tray_button;
    TrayController.closePage(&context.tray_state);
    const closing_tray = systemPanelCardBox(&context);
    return @abs(closing_tray.rect.left - tray.rect.left) < 0.01 and
        @abs((closing_tray.rect.left + closing_tray.rect.right) * 0.5 - tray_centre) < 0.01;
}

fn taskHoverProgressFor(context: *const PaintContext, window_id: TaskbarCatalog.WindowId) f32 {
    for (context.task_hover_motions) |motion| {
        if (motion.window_id == window_id) return motion.progress;
    }
    return 0;
}

fn syncTaskbarSnapshot(context: *PaintContext) bool {
    if (context.taskbar_state.snapshot.revision == context.task_windows.revision) return false;
    context.task_windows.snapshot(&context.candidate_taskbar_snapshot);
    return context.taskbar_state.updateSnapshot(context.candidate_taskbar_snapshot);
}

fn visibleTaskButton(view: *const TaskbarPage.View, window_id: TaskbarCatalog.WindowId) ?TextRenderer.TaskButton {
    if (window_id == 0) return null;
    for (view.buttons[0..@min(view.count, view.buttons.len)]) |button| {
        if (button.window_id == window_id) return button;
    }
    if (view.overflow_open) {
        for (view.overflow_buttons[0..@min(view.overflow_count, view.overflow_buttons.len)]) |button| {
            if (button.window_id == window_id) return button;
        }
    }
    return null;
}

fn taskButtonInLayout(view: *const TaskbarPage.View, window_id: TaskbarCatalog.WindowId) bool {
    if (window_id == 0) return false;
    for (view.buttons[0..@min(view.count, view.buttons.len)]) |button| {
        if (button.window_id == window_id) return true;
    }
    for (view.overflow_buttons[0..@min(view.overflow_count, view.overflow_buttons.len)]) |button| {
        if (button.window_id == window_id) return true;
    }
    return false;
}

fn addTaskIconTransition(context: *PaintContext, transition: TaskIconTransition) void {
    if (context.task_icon_transition_count >= context.task_icon_transitions.len) return;
    context.task_icon_transitions[context.task_icon_transition_count] = transition;
    context.task_icon_transition_count += 1;
}

fn setTaskButtonVisual(button: *TextRenderer.TaskButton, opacity: f32, scale: f32, offset_y: f32) void {
    button.visual_opacity = std.math.clamp(opacity, 0, 1);
    button.visual_scale = @max(0, scale);
    button.visual_offset_y = offset_y;
}

fn applyTaskButtonVisual(view: *TaskbarPage.View, window_id: TaskbarCatalog.WindowId, opacity: f32, scale: f32, offset_y: f32) bool {
    for (view.buttons[0..@min(view.count, view.buttons.len)]) |*button| {
        if (button.window_id != window_id) continue;
        setTaskButtonVisual(button, opacity, scale, offset_y);
        return true;
    }
    for (view.overflow_buttons[0..@min(view.overflow_count, view.overflow_buttons.len)]) |*button| {
        if (button.window_id != window_id) continue;
        setTaskButtonVisual(button, opacity, scale, offset_y);
        return true;
    }
    return false;
}

fn smoothTaskTransition(value: f32) f32 {
    const t = std.math.clamp(value, 0, 1);
    return t * t * (3 - 2 * t);
}

fn easeOutTaskMovement(value: f32) f32 {
    const remaining = 1 - std.math.clamp(value, 0, 1);
    return 1 - remaining * remaining * remaining;
}

fn prepareTaskIconTransitions(context: *PaintContext, view: *TaskbarPage.View, now: u64) void {
    if (context.task_icon_transition_revision == null or context.task_icon_transition_revision.? != view.catalog_revision) {
        context.task_icon_transition_count = 0;
        const previous = &context.presented_taskbar_view;
        context.tray_dock_shift_started_ms = 0;
        context.tray_dock_shift_from_x = 0;
        if (view.count < previous.count and view.tray_count > 0 and previous.tray_count > 0) {
            const old_tray = previous.tray_icons[0];
            const new_tray = view.tray_icons[0];
            if (old_tray.source_index == new_tray.source_index and old_tray.fingerprint == new_tray.fingerprint) {
                const offset_x = old_tray.bounds.left - new_tray.bounds.left;
                if (offset_x > 0.5) {
                    context.tray_dock_shift_started_ms = now;
                    context.tray_dock_shift_from_x = offset_x;
                }
            }
        }
        for (previous.buttons[0..@min(previous.count, previous.buttons.len)]) |button| {
            if (taskButtonInLayout(view, button.window_id)) continue;
            var fading = button;
            fading.title = null;
            fading.active = false;
            fading.hover_progress = 0;
            fading.visual_opacity = 1;
            fading.visual_scale = 1;
            fading.visual_offset_y = 0;
            addTaskIconTransition(context, .{ .window_id = button.window_id, .started_ms = now, .kind = .disappear, .button = fading });
        }
        if (previous.overflow_open and view.overflow_open) {
            for (previous.overflow_buttons[0..@min(previous.overflow_count, previous.overflow_buttons.len)]) |button| {
                if (taskButtonInLayout(view, button.window_id)) continue;
                var fading = button;
                fading.title = null;
                fading.active = false;
                fading.hover_progress = 0;
                fading.visual_opacity = 1;
                fading.visual_scale = 1;
                fading.visual_offset_y = 0;
                addTaskIconTransition(context, .{ .window_id = button.window_id, .started_ms = now, .kind = .disappear, .button = fading });
            }
        }
        for (view.buttons[0..@min(view.count, view.buttons.len)]) |button| {
            if (visibleTaskButton(previous, button.window_id)) |old_button| {
                if (@abs(old_button.bounds.top - button.bounds.top) < 2) {
                    const offset_x = old_button.bounds.left - button.bounds.left;
                    if (@abs(offset_x) > 0.5) addTaskIconTransition(context, .{
                        .window_id = button.window_id,
                        .started_ms = now,
                        .kind = .move,
                        .from_offset_x = offset_x,
                    });
                }
            } else {
                addTaskIconTransition(context, .{ .window_id = button.window_id, .started_ms = now, .kind = .appear });
            }
        }
        if (view.overflow_open) {
            for (view.overflow_buttons[0..@min(view.overflow_count, view.overflow_buttons.len)]) |button| {
                if (visibleTaskButton(previous, button.window_id)) |old_button| {
                    if (@abs(old_button.bounds.top - button.bounds.top) < 2) {
                        const offset_x = old_button.bounds.left - button.bounds.left;
                        if (@abs(offset_x) > 0.5) addTaskIconTransition(context, .{
                            .window_id = button.window_id,
                            .started_ms = now,
                            .kind = .move,
                            .from_offset_x = offset_x,
                        });
                    }
                } else {
                    addTaskIconTransition(context, .{ .window_id = button.window_id, .started_ms = now, .kind = .appear });
                }
            }
        }
        context.task_icon_transition_revision = view.catalog_revision;
        context.task_icon_transition_deadline_ms = if (context.task_icon_transition_count > 0)
            now + task_icon_transition_duration_ms
        else
            0;
    }

    view.exit_count = 0;
    var active_count: usize = 0;
    for (context.task_icon_transitions[0..context.task_icon_transition_count]) |transition| {
        const elapsed = now -| transition.started_ms;
        const progress = @min(1, @as(f32, @floatFromInt(elapsed)) / @as(f32, @floatFromInt(task_icon_transition_duration_ms)));
        if (progress >= 1) continue;
        const eased = smoothTaskTransition(progress);
        switch (transition.kind) {
            .appear => {
                if (!applyTaskButtonVisual(view, transition.window_id, eased, 0.82 + 0.18 * eased, 4 * (1 - eased))) continue;
            },
            .move => {
                const movement = easeOutTaskMovement(progress);
                if (!TaskbarPage.applyHorizontalOffset(view, transition.window_id, transition.from_offset_x * (1 - movement))) continue;
            },
            .disappear => {
                if (view.exit_count >= view.exit_buttons.len) continue;
                var fading = transition.button;
                setTaskButtonVisual(&fading, 1 - eased, 1 - 0.32 * eased, -4 * eased);
                view.exit_buttons[view.exit_count] = fading;
                view.exit_count += 1;
            },
        }
        context.task_icon_transitions[active_count] = transition;
        active_count += 1;
    }
    context.task_icon_transition_count = active_count;
    if (active_count == 0) context.task_icon_transition_deadline_ms = 0;
    if (context.tray_dock_shift_started_ms != 0) {
        const elapsed = now -| context.tray_dock_shift_started_ms;
        const progress = @min(1, @as(f32, @floatFromInt(elapsed)) / @as(f32, @floatFromInt(task_icon_transition_duration_ms)));
        TaskbarPage.applyTrayDockOffset(view, context.tray_dock_shift_from_x * (1 - smoothTaskTransition(progress)));
        if (progress >= 1) {
            context.tray_dock_shift_started_ms = 0;
            context.tray_dock_shift_from_x = 0;
        }
    }
}

fn reportRenderFailure(
    context: *PaintContext,
    stage: []const u8,
    hresult: u32,
    tag1: u64,
    tag2: u64,
    retry_stage: []const u8,
    retry_hresult: u32,
    retry_tag1: u64,
    retry_tag2: u64,
    retry_succeeded: bool,
) void {
    if (context.render_failure_active and
        context.last_render_failure_hresult == hresult and
        context.last_render_failure_tag1 == tag1 and
        context.last_render_failure_tag2 == tag2 and
        std.mem.eql(u8, context.last_render_failure_stage, stage)) return;
    context.render_failure_active = true;
    context.last_render_failure_stage = stage;
    context.last_render_failure_hresult = hresult;
    context.last_render_failure_tag1 = tag1;
    context.last_render_failure_tag2 = tag2;
    logFormatted(
        "renderer: frame failed at {s} (HRESULT=0x{x}, D2D tag={s}:{d}); retry {s} at {s} (HRESULT=0x{x}, D2D tag={s}:{d})",
        .{
            stage,
            hresult,
            Renderer.renderTagName(tag1),
            tag2,
            if (retry_succeeded) "succeeded" else "failed",
            retry_stage,
            retry_hresult,
            Renderer.renderTagName(retry_tag1),
            retry_tag2,
        },
    );
}

fn syncRendererTextResources(context: *PaintContext) void {
    if (context.renderer.generation == context.renderer_generation) return;
    context.text_renderer.invalidateDeviceResources();
    context.renderer_generation = context.renderer.generation;
}

fn paintWindow(window: HWND, context: ?*anyopaque) callconv(.winapi) void {
    const opaque_context = context orelse {
        paintClock(window, null);
        return;
    };
    const paint_context: *PaintContext = @ptrCast(@alignCast(opaque_context));
    const frame_started_ms = GetTickCount64();
    defer paint_context.last_frame_duration_ms = GetTickCount64() -| frame_started_ms;
    var paint: PaintStruct = undefined;
    if (BeginPaint(window, &paint) == null) return;
    _ = syncTaskbarSnapshot(paint_context);
    paint_context.candidate_tray_view = .{};
    const weather_view = WeatherPage.buildView(paint_context.weather_state);
    var pill = paint_context.pill;
    pill.line_text_mode = .scrolling;
    pill.content_card_painter = null;
    pill.content_card_box = null;
    pill.content_card_reveal = 0;
    pill.box = paint_context.motion.current();
    const now = GetTickCount64();
    const active_notification = activeNotification(paint_context, now);
    const outer_card_up = paint_context.motion.target() == .expanded or paint_context.motion.visibleFromState() == .expanded;
    const panel_wanted = paint_context.system_panel_pinned or paint_context.sound_page_open or
        paint_context.start_page_open or paint_context.tray_state.page_open;
    paint_context.presentation = PresentationPolicy.next(paint_context.presentation, .{
        .card_up = outer_card_up,
        .card_wanted = paint_context.motion.target() == .expanded,
        .notification_active = active_notification != null,
        .music_present = paint_context.music_state.active_present,
        .panel_wanted = panel_wanted,
        .tray_wanted = paint_context.tray_state.page_open,
        .sound_wanted = paint_context.sound_page_open,
        .start_wanted = paint_context.start_page_open,
    });
    if (paint_context.presentation.card_owner == .notification) {
        if (active_notification) |notification| {
            paint_context.notification_shown = notification.*;
            paint_context.have_notification_shown = true;
        }
    } else {
        paint_context.have_notification_shown = false;
    }
    const resting_state: Motion.IslandState = if (paint_context.music_state.active_present) .music_strip else .collapsed;
    pill.resting_pill = Motion.boxForState(resting_state, paint_context.motion.anchor);
    pill.resting_state = resting_state;
    pill.music_present = paint_context.music_state.active_present;
    pill.music_card_open = paint_context.presentation.card_owner == .music;
    paint_context.music_strip_text.wave_phase = paint_context.music_wave_phase;
    paint_context.music_strip_text.accent = .{ .r = paint_context.music_wave_accent.r, .g = paint_context.music_wave_accent.g, .b = paint_context.music_wave_accent.b, .a = 1 };
    paint_context.music_strip_text.level = 0;
    if (paint_context.sound_controller) |sound| {
        paint_context.music_strip_text.level = sound.state.master_peak;
        paint_context.music_strip_text.level_known = sound.state.master_available;
    } else {
        paint_context.music_strip_text.level_known = false;
    }
    pill.lyric_scroll_dip = paint_context.lyric_scroll_dip;
    pill.lyric_line_roll = Lyrics.lyricLineRollFor(paint_context.lyric_line_age_seconds);
    pill.lyric_line_prev = std.mem.sliceTo(&paint_context.replaced_lyric_text, 0);
    pill.lyric_line_prev_scroll_dip = paint_context.replaced_lyric_scroll_dip;
    pill.fullscreen_progress = paint_context.fullscreen_morph_progress;
    pill.status_weather = weather_view;
    if (active_notification) |notification| {
        pill.line_text_mode = .static;
        pill.box = Motion.boxForState(.notice_strip, paint_context.motion.anchor);
        if (notification.id == callNotificationId(paint_context)) {
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
                        AppIconService.fetchFileIconPng,
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
            const level = if (paint_context.sound_controller) |sound| sound.state.master_peak else 0;
            const level_known = if (paint_context.sound_controller) |sound| sound.state.master_available else false;
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
            const icon_request = notification.toInput();
            if (NotificationIcon.notificationIconSource(&icon_request, &icon_source)) {
                if (NotificationIcon.loadNotificationIconPixels(
                    &icon_source,
                    &paint_context.notification_icon_pixels,
                    &paint_context.notification_icon_width,
                    &paint_context.notification_icon_height,
                    AppIconService.fetchFileIconPng,
                )) |byte_count| {
                    paint_context.notification_icon_size = byte_count;
                }
            }
        }
        const message = if (notification.title[0] != 0)
            std.mem.sliceTo(&notification.title, 0)
        else
            std.mem.sliceTo(&notification.body, 0);
        pill.line_text = message;
    } else if (paint_context.music_state.active_present) {
        const lyric = std.mem.sliceTo(&paint_context.shown_lyric_text, 0);
        pill.line_text = if (lyric.len != 0) lyric else std.mem.sliceTo(&paint_context.music_state.active_title, 0);
    }
    paint_context.music_strip_text.line = if (active_notification == null) pill.line_text else &.{};
    paint_context.music_strip_text.previous_line = std.mem.sliceTo(&paint_context.replaced_lyric_text, 0);
    paint_context.music_strip_text.scroll_dip = paint_context.lyric_scroll_dip;
    paint_context.music_strip_text.line_roll = Lyrics.lyricLineRollFor(paint_context.lyric_line_age_seconds);
    paint_context.music_strip_text.previous_scroll_dip = paint_context.replaced_lyric_scroll_dip;
    pill.feature_strip_painter = .{ .context = @ptrCast(&paint_context.music_strip_text), .paint_fn = MusicPage.paintStrip };
    if ((active_notification != null or (paint_context.presentation.card_owner == .notification and paint_context.have_notification_shown)) and
        paint_context.notification_icon_size != 0)
    {
        const displayed = if (active_notification) |notification| notification else &paint_context.notification_shown;
        paint_context.notification_card_view = .{
            .app = std.mem.sliceTo(&displayed.app, 0),
            .title = std.mem.sliceTo(&displayed.title, 0),
            .body = std.mem.sliceTo(&displayed.body, 0),
            .icon_pixels = paint_context.notification_icon_pixels[0..paint_context.notification_icon_size],
            .icon_width = paint_context.notification_icon_width,
            .icon_height = paint_context.notification_icon_height,
            .icon_revision = paint_context.notification_icon_revision,
        };
    } else {
        const displayed = if (active_notification) |notification| notification else if (paint_context.have_notification_shown) &paint_context.notification_shown else null;
        if (displayed) |notification| {
            paint_context.notification_card_view = .{
                .app = std.mem.sliceTo(&notification.app, 0),
                .title = std.mem.sliceTo(&notification.title, 0),
                .body = std.mem.sliceTo(&notification.body, 0),
            };
        } else {
            paint_context.notification_card_view = .{};
        }
    }
    const notice_active = active_notification != null;
    if (outer_card_up) {
        const reveal = Motion.outerCardRevealDip(Geometry.height(paint_context.motion.current().rect));
        switch (paint_context.presentation.card_owner) {
            .none => {},
            .notification => {
                if (!notice_active) pill.box = Motion.boxForState(.collapsed, paint_context.motion.anchor);
                if (paint_context.have_notification_shown) {
                    pill.content_card_painter = NotificationPage.painter(&paint_context.notification_card_view);
                    pill.content_card_box = notificationCardBox(paint_context);
                    pill.content_card_reveal = reveal;
                }
            },
            .music => {
                pill.box = paint_context.motion.current();
                pill.feature_page_painter = .{ .context = @ptrCast(&paint_context.music_card_text), .paint_fn = MusicPage.paintCard };
                pill.feature_page_box = pill.box;
                pill.feature_page_reveal = reveal;
            },
            .system_panel => {
                pill.box = if (notice_active)
                    Motion.boxForState(.notice_strip, paint_context.motion.anchor)
                else
                    Motion.boxForState(.collapsed, paint_context.motion.anchor);
                const card = systemPanelCardBox(paint_context);
                switch (paint_context.presentation.panel_level) {
                    .sound => {
                        pill.feature_page_painter = .{ .context = @ptrCast(paint_context), .paint_fn = paintSoundPage };
                        pill.feature_page_box = card;
                        pill.feature_page_reveal = reveal;
                    },
                    .start => {
                        pill.feature_page_painter = .{ .context = @ptrCast(&paint_context.start_card_text), .paint_fn = LauncherPage.paint };
                        pill.feature_page_box = card;
                        pill.feature_page_reveal = reveal;
                    },
                    .tray => {
                        const menu = if (paint_context.tray_state.menu_open and paint_context.tray_state.selected != null) blk: {
                            const selected = paint_context.tray_state.selected.?;
                            const cell_index: usize = selected.index;
                            if (cell_index < paint_context.tray_page_icon_count) {
                                const tray_layout = TrayPage.layoutFor(card, @intCast(paint_context.tray_page_icon_count));
                                const cell = tray_layout.cells[cell_index];
                                break :blk TrayPage.menuFor(card, cell.right, cell.bottom, @intCast(paint_context.tray_state.menu_count));
                            }
                            break :blk TrayPage.MenuLayout{};
                        } else TrayPage.MenuLayout{};
                        paint_context.candidate_tray_view = TrayPage.buildView(card, paint_context.tray_page_icon_count, paint_context.tray_page_revision, menu);
                        paint_context.tray_card_text.view = paint_context.candidate_tray_view;
                        paint_context.tray_card_text.icons = paint_context.tray_page_icons[0..paint_context.tray_page_icon_count];
                        paint_context.tray_card_text.hovered_icon = paint_context.tray_state.hovered_icon;
                        paint_context.tray_card_text.menu_actions = paint_context.tray_state.menu_actions[0..paint_context.tray_state.menu_count];
                        paint_context.tray_card_text.hovered_menu_row = paint_context.tray_state.hovered_menu_row;
                        paint_context.tray_card_text.quit_armed = paint_context.tray_state.quit_armed;
                        pill.feature_page_painter = .{ .context = @ptrCast(&paint_context.tray_card_text), .paint_fn = TrayPage.paint };
                        pill.feature_page_box = card;
                        pill.feature_page_reveal = reveal;
                    },
                    .tiles => {
                        SystemPage.updateLayout(&paint_context.system_panel_view, card);
                        pill.system_panel = &paint_context.system_panel_view.presentation;
                        pill.system_panel_box = card;
                        pill.system_panel_reveal = reveal;
                    },
                }
            },
        }
    }
    const task_count = taskButtonCount(paint_context);
    @memset(&paint_context.task_buttons, .{});
    for (paint_context.taskbar_state.snapshot.entries[0..task_count], 0..) |*entry, index| {
        paint_context.task_buttons[index] = .{
            .window_id = entry.id,
            .process_id = entry.process_id,
            .process_created_at = entry.process_created_at,
            .window_count = entry.window_count,
            .title = @ptrCast(&entry.title),
            .window = paint_context.task_windows.handleForTaskGroup(entry.id),
            .active = entry.id == paint_context.taskbar_state.snapshot.foreground_id,
            .hover_progress = taskHoverProgressFor(paint_context, entry.id),
        };
    }
    const resting_deck = Motion.boxForState(.collapsed, paint_context.motion.anchor);
    const deck_island = Motion.rowAnchorBox(pill.box, resting_deck);
    pill.deck_box = deck_island;
    const active_theme = Theme.currentTheme();
    pill.fill = .{ active_theme.pill_bottom.r, active_theme.pill_bottom.g, active_theme.pill_bottom.b, active_theme.pill_bottom.a };
    pill.start_hover = paint_context.start_button_wash;
    const panel_controls_lit = PresentationPolicy.controlLitFor(paint_context.presentation, outer_card_up);
    pill.start_open = panel_controls_lit.start;
    pill.tray_hover = paint_context.tray_button_wash;
    pill.tray_open = paint_context.task_overflow_open;
    pill.system_hover = paint_context.system_button_wash;
    pill.tray_entry_hover = paint_context.tray_entry_wash;
    const task_island = deck_island;
    const monitor_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(paint_context.scale, 0.01);
    var tray_dock_icons: [TaskbarPage.max_tray_icons]TaskbarPage.TrayIconInput = @splat(.{});
    var tray_dock_icon_count: usize = 0;
    var tray_dock_revision: u64 = 0;
    if (paint_context.tray_icons) |icons| {
        tray_dock_revision = icons.getRevision();
        for (0..icons.count()) |index| {
            if (tray_dock_icon_count >= tray_dock_icons.len) break;
            const icon = icons.at(index) orelse continue;
            // Windows marks icons that belong in the notification area as promoted;
            // unpromoted icons remain available from the existing tray flyout.
            if (!icon.promoted) continue;
            const identity = TrayCatalog.identityFor(icon, tray_dock_revision, index);
            tray_dock_icons[tray_dock_icon_count] = .{
                .png = icon.png,
                .source_index = identity.index,
                .fingerprint = identity.fingerprint,
            };
            tray_dock_icon_count += 1;
        }
    }
    paint_context.candidate_taskbar_view = TaskbarPage.buildDockViewWithHoverProgressAndTray(
        task_island,
        paint_context.task_buttons[0..task_count],
        paint_context.candidate_taskbar_snapshot.revision,
        TaskbarLayout.taskIconsThatFitForMonitor(monitor_width_dip, task_count),
        monitor_width_dip,
        paint_context.task_overflow_open,
        tray_dock_icons[0..tray_dock_icon_count],
        tray_dock_revision,
    );
    prepareTaskIconTransitions(paint_context, &paint_context.candidate_taskbar_view, frame_started_ms);
    if (paint_context.task_icon_transition_deadline_ms != 0) {
        const morph_animating = @abs(paint_context.fullscreen_morph_progress - paint_context.fullscreen_morph_target) > 0.0001;
        if (paint_context.window) |native_window| native_window.setPointerPollInterval(if (morph_animating) fullscreen_morph_poll_ms else animation_poll_ms);
    }
    pill.taskbar_view = &paint_context.candidate_taskbar_view;
    paint_context.candidate_sound_layout = buildSoundLayoutSnapshot(paint_context, pill);
    paint_context.candidate_music_layout = buildMusicLayoutSnapshot(paint_context, pill);
    paint_context.candidate_launcher_layout = buildLauncherLayoutSnapshot(paint_context, pill);
    if (paint_context.candidate_tray_view.snapshot.valid) paint_context.tray_card_text.view = paint_context.candidate_tray_view;
    if (paint_context.candidate_launcher_layout.snapshot.valid) paint_context.start_card_text.view = paint_context.candidate_launcher_layout;
    pill.feature_layout_snapshot = if (paint_context.candidate_music_layout.valid)
        &paint_context.candidate_music_layout
    else if (paint_context.candidate_sound_layout.valid)
        &paint_context.candidate_sound_layout
    else if (paint_context.candidate_tray_view.snapshot.valid)
        &paint_context.candidate_tray_view.snapshot
    else if (paint_context.candidate_launcher_layout.snapshot.valid)
        &paint_context.candidate_launcher_layout.snapshot
    else
        null;
    pill.fullscreen_source_box = paint_context.fullscreen_morph_source_box;
    if (!paint_context.renderer.isReady()) _ = recoverGraphicsDevice(paint_context, GetTickCount64());
    syncRendererTextResources(paint_context);
    const first_rendered = paint_context.renderer.renderPill(pill, paint_context.text_renderer, .compact);
    var rendered = first_rendered;
    if (!first_rendered) {
        const first_failure_stage = if (Renderer.last_render_pill_failure.len > 0)
            Renderer.last_render_pill_failure
        else
            "unclassified render failure";
        const first_failure_hresult: u32 = @bitCast(Renderer.last_render_pill_hresult);
        const first_failure_tag1 = Renderer.last_render_pill_tag1;
        const first_failure_tag2 = Renderer.last_render_pill_tag2;
        if (paint_context.renderer.lastFailureIsDeviceLoss()) {
            _ = recoverGraphicsDevice(paint_context, GetTickCount64());
        }
        syncRendererTextResources(paint_context);
        rendered = paint_context.renderer.renderPill(pill, paint_context.text_renderer, .compact);
        const retry_failure_stage = if (rendered)
            "render succeeded"
        else if (Renderer.last_render_pill_failure.len > 0)
            Renderer.last_render_pill_failure
        else
            "unclassified render failure";
        const retry_failure_hresult: u32 = if (rendered) 0 else @bitCast(Renderer.last_render_pill_hresult);
        const retry_failure_tag1 = Renderer.last_render_pill_tag1;
        const retry_failure_tag2 = Renderer.last_render_pill_tag2;
        reportRenderFailure(
            paint_context,
            first_failure_stage,
            first_failure_hresult,
            first_failure_tag1,
            first_failure_tag2,
            retry_failure_stage,
            retry_failure_hresult,
            retry_failure_tag1,
            retry_failure_tag2,
            rendered,
        );
        if (!rendered) {
            const retry_now = GetTickCount64();
            paint_context.render_retry_at_ms = retry_now +| paint_context.render_retry_delay_ms;
            paint_context.render_retry_delay_ms = @min(paint_context.render_retry_delay_ms * 2, 2000);
            if (paint_context.renderer.lastFailureIsDeviceLoss()) _ = recoverGraphicsDevice(paint_context, retry_now);
        }
    }
    if (rendered) {
        paint_context.render_failure_active = false;
        paint_context.last_render_failure_stage = "";
        paint_context.last_render_failure_hresult = 0;
        paint_context.last_render_failure_tag1 = 0;
        paint_context.last_render_failure_tag2 = 0;
        paint_context.render_retry_at_ms = 0;
        paint_context.render_retry_delay_ms = 250;
    }
    if (rendered and !paint_context.fullscreen_app and paint_context.fullscreen_morph_progress <= 0.0001) {
        paint_context.fullscreen_morph_source_box = pill.box;
    }
    LayoutSnapshot.publishAfterSuccessfulFrame(&paint_context.presented_sound_layout, paint_context.candidate_sound_layout, rendered);
    LayoutSnapshot.publishAfterSuccessfulFrame(&paint_context.presented_music_layout, paint_context.candidate_music_layout, rendered);
    if (rendered) paint_context.presented_launcher_layout = paint_context.candidate_launcher_layout;
    if (rendered) paint_context.presented_tray_view = paint_context.candidate_tray_view;
    if (rendered) paint_context.presented_taskbar_view = paint_context.candidate_taskbar_view;
    if (!rendered and paint_context.renderer.lastFailureIsDeviceLoss()) _ = recoverGraphicsDevice(paint_context, GetTickCount64());
    _ = EndPaint(window, &paint);
    _ = updateInputRegion(paint_context);
    if ((paint_context.motion.isAnimating() and !fullscreenPresentationActive(paint_context)) or
        @abs(paint_context.fullscreen_morph_progress - paint_context.fullscreen_morph_target) > 0.0001)
    {
        _ = paint_context.renderer.waitForCompositorClock(8);
    }
}

fn taskButtonCount(context: *const PaintContext) usize {
    return @min(context.taskbar_state.snapshot.count, TaskbarLayout.max_task_icons);
}

fn activateTaskWindow(context: *PaintContext, id: TaskbarCatalog.WindowId, window: *IslandWindow.NativeWindow) void {
    if (context.taskbar_state.action(id, context.presented_taskbar_view.catalog_revision)) |action| {
        switch (action) {
            .minimize => |request| Log.logLine(if (context.task_windows.minimizeIdentity(request)) "task button: minimized the foreground window" else "task button: minimizing the foreground window failed or target became stale"),
            .activate => |request| Log.logLine(if (context.task_windows.activateIdentity(request)) "task button: activated the selected window" else "task button: activation failed or target became stale"),
        }
    } else {
        Log.logLine("task button: stale presented window identity was discarded");
    }
    context.task_overflow_open = false;
    context.task_last_refresh_ms = 0;
    _ = context.task_windows.refresh();
    context.task_windows.snapshot(&context.candidate_taskbar_snapshot);
    _ = context.taskbar_state.updateSnapshot(context.candidate_taskbar_snapshot);
    window.invalidate();
}

fn updateTaskThumbnailPreview(context: *PaintContext, now: u64) void {
    const preview = context.thumbnail_preview orelse return;
    const wanted_id = context.taskbar_state.hovered_id;
    if (wanted_id != context.thumbnail_target_id) {
        context.thumbnail_target_id = wanted_id;
        context.thumbnail_target_since_ms = now;
    }
    const rested = wanted_id != null and now -| context.thumbnail_target_since_ms >= 350;
    const follow = wanted_id != null and preview.visible;
    const card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    var shown = false;
    if ((rested or follow) and !card_up and !context.fullscreen_app) {
        if (wanted_id) |id| {
            const request = TaskbarCatalog.Request{ .id = id, .catalog_revision = context.presented_taskbar_view.catalog_revision };
            if (context.task_windows.handleForIdentity(request)) |target| {
                var presented_button: ?TextRenderer.TaskButton = null;
                for (context.presented_taskbar_view.buttons[0..context.presented_taskbar_view.count]) |button| {
                    if (button.window_id == id) {
                        presented_button = button;
                        break;
                    }
                }
                if (presented_button) |button| {
                    const monitor = context.monitor_bounds;
                    const icon_px = ThumbnailLayout.Rect{
                        .left = monitor.left + @as(i32, @intFromFloat(@round(button.bounds.left * context.scale))),
                        .top = monitor.top + @as(i32, @intFromFloat(@round(button.bounds.top * context.scale))),
                        .right = monitor.left + @as(i32, @intFromFloat(@round(button.bounds.right * context.scale))),
                        .bottom = monitor.top + @as(i32, @intFromFloat(@round(button.bounds.bottom * context.scale))),
                    };
                    const source_size = preview.begin(target);
                    const placement = ThumbnailLayout.thumbnailBoxFor(
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
        }
    }
    if (!shown) preview.hide();
}

fn pointInBox(box: Geometry.RoundedBox, x: f32, y: f32) bool {
    return Geometry.containsWithTolerance(box, x, y, Geometry.hit_tolerance_dip);
}

fn taskbarRowContains(view: TaskbarPage.View, x: f32, y: f32) bool {
    const bounds = view.row_bounds;
    return bounds.right > bounds.left and bounds.bottom > bounds.top and
        x >= bounds.left and x <= bounds.right and y >= bounds.top and y <= bounds.bottom;
}

fn soundPageViewModel(context: *const PaintContext) ?SoundPage.ViewModel {
    const sound = context.sound_controller orelse return null;
    return .{ .state = &sound.state, .scroll = context.sound_page_state.scroll, .tokens = Theme.currentTheme().tokens };
}

fn paintSoundPage(raw_context: ?*anyopaque, backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, card: *const Geometry.RoundedBox, opacity: f32, snapshot: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    const model = soundPageViewModel(context) orelse return false;
    return SoundPage.draw(backend, draw_context, card.*, &model, snapshot, opacity);
}

fn buildSoundLayoutSnapshot(context: *PaintContext, pill: Renderer.PillAppearance) LayoutSnapshot.Snapshot {
    context.layout_snapshot_generation +%= 1;
    const transform = LayoutSnapshot.ScreenTransform{
        .window_left_px = context.window_x,
        .window_top_px = context.window_y,
        .pixels_per_dip = context.scale,
    };
    const card = pill.feature_page_box orelse return .{ .generation = context.layout_snapshot_generation, .screen_transform = transform };
    const model = soundPageViewModel(context) orelse return .{ .generation = context.layout_snapshot_generation, .screen_transform = transform };
    return SoundPage.buildLayoutSnapshot(card, &model, pill.feature_page_reveal, context.layout_snapshot_generation, transform);
}

fn buildMusicLayoutSnapshot(context: *PaintContext, pill: Renderer.PillAppearance) LayoutSnapshot.Snapshot {
    if (context.presentation.card_owner != .music) return .{};
    context.layout_snapshot_generation +%= 1;
    const transform = LayoutSnapshot.ScreenTransform{
        .window_left_px = context.window_x,
        .window_top_px = context.window_y,
        .pixels_per_dip = context.scale,
    };
    const card = pill.feature_page_box orelse return .{ .generation = context.layout_snapshot_generation, .screen_transform = transform };
    return MusicPage.buildLayoutSnapshot(card, context.layout_snapshot_generation, transform, pill.feature_page_reveal);
}

fn buildLauncherLayoutSnapshot(context: *PaintContext, pill: Renderer.PillAppearance) LauncherPage.View {
    if (!context.start_page_open or context.presentation.panel_level != .start) return .{};
    context.layout_snapshot_generation +%= 1;
    const card = pill.feature_page_box orelse return .{};
    const apps = context.start_apps;
    const pin_count = if (apps) |service| service.pinCount() else 0;
    const app_count = if (apps) |service| service.listCount() else 0;
    var view = LauncherPage.buildView(card, context.launcher_state.page, pin_count, app_count, context.launcher_state.picker_scroll_row, pill.feature_page_reveal, context.layout_snapshot_generation);
    view.snapshot.screen_transform = .{ .window_left_px = context.window_x, .window_top_px = context.window_y, .pixels_per_dip = context.scale };
    return view;
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
    const hang: BarControlLayout.CardHang = if (context.start_page_open)
        .start_button
    else if (context.tray_state.page_open)
        .tray_button
    else
        context.card_hang;
    const centre = BarControlLayout.deckCardAnchorCentre(resting, hang, overflowButtonBoundsFor(context, resting));
    const left = CardLayout.cardLeftFor(centre - Motion.expanded_width_dip * 0.5, Motion.expanded_width_dip, screen_width_dip);
    return Motion.placedCardFor(resting, left);
}

fn overflowButtonBoundsFor(context: *const PaintContext, island: Geometry.RoundedBox) Geometry.RectF {
    const presented = context.presented_taskbar_view.overflow_button_bounds;
    if (presented.right > presented.left) return presented;
    return TaskbarLayout.overflowButtonFor(island, island.rect.right);
}

fn updateInputRegion(context: *PaintContext) bool {
    const window = context.window orelse return false;
    if (context.fullscreen_app and context.fullscreen_morph_progress >= 0.999) {
        const circle = Motion.fullscreenCircleBox(context.motion.anchor).rect;
        const edge_padding = 2.0;
        const region = IslandWindow.Rect{
            .left = @intFromFloat(@floor((circle.left - edge_padding) * context.scale)),
            .top = @intFromFloat(@floor((circle.top - edge_padding) * context.scale)),
            .right = @intFromFloat(@ceil((circle.right + edge_padding) * context.scale)),
            .bottom = @intFromFloat(@ceil((circle.bottom + edge_padding) * context.scale)),
        };
        const ok = window.setInputRegion(region);
        if (!ok) Log.logLine("fullscreen circle input region could not be updated");
        return ok;
    }
    const card_up = (context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded) and context.presentation.card_owner != .none;
    const card = switch (context.presentation.card_owner) {
        .notification => notificationCardBox(context),
        .music => Motion.placedCardFor(Motion.boxForState(.collapsed, context.motion.anchor), CardLayout.cardLeftFor(
            context.motion.anchor.center_x - Motion.expanded_width_dip * 0.5,
            Motion.expanded_width_dip,
            @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01),
        )),
        .none, .system_panel => systemPanelCardBox(context),
    };
    const region = InputRegion.forFrame(.{
        .monitor_width_dip = @as(f32, @floatFromInt(window_width_px)) / @max(context.scale, 0.01),
        .dpi = @intFromFloat(context.scale * Geometry.dip_per_inch),
        .state = context.motion.target(),
        .anchor = context.motion.anchor,
        .current = context.motion.current(),
        .card_up = card_up,
        .card_left_dip = if (card_up) card.rect.left else 0,
        .task_row_bounds = context.presented_taskbar_view.row_bounds,
        .overflow_button_bounds = overflowButtonBoundsFor(context, Motion.boxForState(.collapsed, context.motion.anchor)),
        .overflow_bounds = context.presented_taskbar_view.overflow_bounds.rect,
    });
    const ok = window.setInputRegion(.{ .left = region.left, .top = region.top, .right = region.right, .bottom = region.bottom });
    if (!ok) Log.logLine("window input region could not be updated");
    return ok;
}

fn sampleSystemStatus(context: *PaintContext, now: u64) bool {
    var refreshed = false;
    if (SystemService.takeRadioOutcome()) |outcome| {
        const verdict = if (outcome.succeeded) "as asked" else "NOT as asked";
        const refused = if (outcome.hresult != 0) " (radio call refused or failed)" else "";
        if (outcome.wifi_asked and outcome.bluetooth_asked) {
            logFormatted("radios: Wi-Fi {s}, Bluetooth {s} -- {s}{s}", .{ if (outcome.wifi_now) "on" else "off", if (outcome.bluetooth_now) "on" else "off", verdict, refused });
        } else if (outcome.wifi_asked) {
            logFormatted("radios: Wi-Fi {s} -- {s}{s}", .{ if (outcome.wifi_now) "on" else "off", verdict, refused });
        } else {
            logFormatted("radios: Bluetooth {s} -- {s}{s}", .{ if (outcome.bluetooth_now) "on" else "off", verdict, refused });
        }
        sampleSystemSnapshot(context);
        context.status_sampled_ms = GetTickCount64();
        refreshed = true;
    }
    if (SystemService.takeNightLightOutcome()) |outcome| {
        logFormatted("night light: asked for {s}; it is now {s} ({s})", .{ if (outcome.wanted) "on" else "off", if (outcome.state_after) "on" else "off", if (outcome.state_after == outcome.wanted and outcome.succeeded) "it took" else "IT DID NOT CHANGE" });
        sampleSystemSnapshot(context);
        context.status_sampled_ms = GetTickCount64();
        refreshed = true;
    }
    if (context.status_sampled_ms == 0 or now -| context.status_sampled_ms >= 2000) {
        if (context.status_reader != null) sampleSystemSnapshot(context);
        var brightness = context.system_state.brightness_percent;
        const brightness_available = SystemService.readBrightness(context.monitor, &brightness);
        context.system_state.updateBrightness(brightness_available, brightness);
        context.status_sampled_ms = now;
        refreshed = true;
    }
    if (context.sound_controller) |sound| {
        if (context.sound_ports) |ports| {
            if (ports.audio_volume) |volume| {
                var level = sound.state.master_level;
                _ = volume.get(&level);
                var peak = sound.state.master_peak;
                _ = volume.peak(&peak);
                sound.updateMaster(volume.available(), level, volume.isMuted(), peak, volume.getRevision());
                while (volume.takeResult()) |result| {
                    const disposition = sound.applyResult(result);
                    traceSoundResult(context, result.token, @tagName(result.operation), @tagName(disposition), result.hresult);
                }
            }
            if (ports.audio_service) |service| {
                const before = sound.state.revision;
                sound.updateOutput(service.snapshot());
                while (service.takeResult()) |result| {
                    const disposition = sound.applyResult(result);
                    traceSoundResult(context, result.token, @tagName(result.operation), @tagName(disposition), result.hresult);
                }
                if (sound.state.revision != before) refreshed = true;
            }
        }
        if (sound.expire(now)) refreshed = true;
    }
    buildSystemPanelText(context);
    return refreshed;
}

fn sampleSystemSnapshot(context: *PaintContext) void {
    if (context.status_reader) |reader| {
        var snapshot = context.system_state.status;
        reader.sample(&snapshot);
        context.system_state.updateStatus(snapshot, reader.layoutCount());
    }
}

fn handleSystemPanelClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const hit = SystemPage.hitFor(&context.system_panel_view, local_x, local_y);
    switch (hit.target) {
        .page_up => context.system_state.advancePage(-1, context.system_panel_view.presentation.page_count),
        .page_down => context.system_state.advancePage(1, context.system_panel_view.presentation.page_count),
        .speaker => {
            if (context.sound_controller) |sound| _ = dispatchSoundAction(context, .{ .set_master_muted = !sound.state.displayedMuted() });
        },
        .volume_device => {
            context.sound_page_open = true;
            TrayController.closePage(&context.tray_state);
            context.start_page_open = false;
            context.card_hang = .overflow_button;
            context.sound_page_state.scroll = 0;
        },
        .gear => _ = ShellCommand.openUri(uri_settings),
        .slider => {
            if (hit.index == 0) {
                _ = dispatchSoundAction(context, .{ .set_master_volume = hit.fraction });
            } else if (hit.index == 1 and context.system_state.brightness_available) {
                var landed: i32 = context.system_state.brightness_percent;
                const wanted: i32 = @intFromFloat(@round(hit.fraction * 100));
                const succeeded = SystemService.setBrightness(context.monitor, wanted, &landed);
                context.system_state.confirmBrightness(succeeded, landed);
            }
        },
        .tile => {
            const action = SystemPage.actionAt(&context.system_panel_view, hit.index) orelse return false;
            switch (action) {
                .open_settings => |target| _ = ShellCommand.openUri(SystemPage.settingsUri(target)),
                .open_sound_page => {
                    context.sound_page_open = true;
                    TrayController.closePage(&context.tray_state);
                    context.start_page_open = false;
                    context.card_hang = .overflow_button;
                    context.sound_page_state.scroll = 0;
                },
                .open_tray_page => {
                    TrayController.openPage(&context.tray_state, context.tray_page_revision);
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
                    TrayController.closePage(&context.tray_state);
                    context.card_hang = .start_button;
                    context.launcher_state.page = .pins;
                    context.launcher_state.power_confirm_row = -1;
                    if (context.start_apps) |apps| _ = apps.refreshList();
                    buildStartCardText(context);
                },
                .toggle_live_captions => logFormatted("live captions: Win+Ctrl+L queued={d}", .{@intFromBool(SystemService.toggleLiveCaptions())}),
                .cycle_theme => _ = Theme.cycleTheme(Log.logLine),
                .toggle_wifi => {
                    const on = !context.system_state.status.wifi_radio_on;
                    const started = SystemService.requestRadios(true, false, on);
                    logFormatted("Wi-Fi radio: asked to switch {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_bluetooth => {
                    const on = !context.system_state.status.bluetooth_on;
                    const started = SystemService.requestRadios(false, true, on);
                    logFormatted("Bluetooth radio: asked to switch {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_radio => {
                    const on = !(context.system_state.status.wifi_radio_on or context.system_state.status.bluetooth_on);
                    const started = SystemService.requestRadios(true, true, on);
                    logFormatted("airplane mode: asked for Wi-Fi and Bluetooth {s}; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .toggle_night_light => {
                    const on = !context.system_state.status.night_light_on;
                    const started = SystemService.requestNightLight(on);
                    logFormatted("night light: asked to switch {s} through Settings; worker started={d}", .{ if (on) "on" else "off", @intFromBool(started) });
                },
                .projection_modes => _ = ShellCommand.sendWindowsKeyChord('P'),
                .none => return false,
            }
        },
        .none => return false,
    }
    _ = sampleSystemStatus(context, 0);
    if (context.window) |window| window.invalidate();
    return true;
}

fn setMixerLevel(context: *PaintContext, row: i32, fraction_arg: f32) SoundController.Dispatch {
    const model = soundPageViewModel(context) orelse return .unavailable;
    const action = SoundPage.volumeAction(&model, &context.presented_sound_layout, row, fraction_arg) orelse return .stale_target;
    return dispatchSoundAction(context, action);
}

fn traceInputAction(
    context: *PaintContext,
    element_id: LayoutSnapshot.ElementId,
    element_index: i32,
    layout_generation: u64,
    action_name: []const u8,
    dispatch: ?SoundController.Dispatch,
) void {
    if (!context.trace_ui_enabled) return;
    const sound = context.sound_controller orelse return;
    var operation_id: u64 = 0;
    switch (dispatch orelse .unavailable) {
        .queued, .duplicate => if (sound.state.pending) |pending| {
            operation_id = pending.token;
        },
        .failed => if (sound.state.last_error) |failure| {
            operation_id = failure.token;
        },
        else => {},
    }
    var bounds = Diagnostics.TraceRect{};
    var hit_region = Diagnostics.TraceRect{};
    for (context.presented_sound_layout.elements[0..context.presented_sound_layout.count]) |element| {
        if (element.id != element_id or element.index != element_index) continue;
        bounds = .{ .left = element.bounds.left, .top = element.bounds.top, .right = element.bounds.right, .bottom = element.bounds.bottom };
        hit_region = .{ .left = element.hit_region.left, .top = element.hit_region.top, .right = element.hit_region.right, .bottom = element.hit_region.bottom };
        break;
    }
    const snapshot = context.presented_sound_layout;
    var hresult: i32 = 0;
    if (sound.state.last_error) |failure| if (failure.token == operation_id) {
        hresult = failure.hresult;
    };
    Diagnostics.logUiTrace(true, .{
        .operation_id = operation_id,
        .element = @tagName(element_id),
        .element_index = element_index,
        .layout_generation = layout_generation,
        .action = action_name,
        .result = if (dispatch) |value| @tagName(value) else "released",
        .hresult = hresult,
        .state_revision = sound.state.revision,
        .renderer_generation = context.renderer_generation,
        .frame_duration_ms = context.last_frame_duration_ms,
        .dpi = @intFromFloat(context.scale * 96),
        .screen_origin_x_px = snapshot.screen_transform.window_left_px,
        .screen_origin_y_px = snapshot.screen_transform.window_top_px,
        .pixels_per_dip = snapshot.screen_transform.pixels_per_dip,
        .bounds = bounds,
        .hit_region = hit_region,
        .surface_clip = .{ .left = snapshot.surface_clip.left, .top = snapshot.surface_clip.top, .right = snapshot.surface_clip.right, .bottom = snapshot.surface_clip.bottom },
        .content_clip = .{ .left = snapshot.content_clip.left, .top = snapshot.content_clip.top, .right = snapshot.content_clip.right, .bottom = snapshot.content_clip.bottom },
    });
}

fn traceSoundResult(context: *PaintContext, token: u64, operation: []const u8, disposition: []const u8, hresult: i32) void {
    if (!context.trace_ui_enabled) return;
    const sound_revision = if (context.sound_controller) |sound| sound.state.revision else 0;
    Diagnostics.logUiTrace(true, .{
        .operation_id = token,
        .element = "sound",
        .action = operation,
        .result = disposition,
        .hresult = hresult,
        .state_revision = sound_revision,
        .renderer_generation = context.renderer_generation,
        .frame_duration_ms = context.last_frame_duration_ms,
        .dpi = @intFromFloat(context.scale * 96),
    });
}

fn dispatchInputAction(context: *PaintContext, action: InputRouter.Action) void {
    switch (action) {
        .adjust => |value| {
            if (value.phase == .press) context.sound_page_state.setPressed(.{ .id = value.element_id, .index = value.element_index });
            if (value.element_id == .slider) {
                const dispatch = setMixerLevel(context, value.element_index, value.fraction);
                traceInputAction(context, value.element_id, value.element_index, value.frame_generation, @tagName(value.phase), dispatch);
            }
        },
        .release => |value| {
            context.sound_page_state.setPressed(null);
            traceInputAction(context, value.element_id, value.element_index, value.frame_generation, "release", null);
        },
        .none => {},
    }
}

fn handleSoundPageClick(context: *PaintContext, local_x: f32, local_y: f32, point: IslandWindow.Point, slider_press_already_handled: bool) bool {
    const card = systemPanelCardBox(context);
    _ = local_x;
    _ = local_y;
    const model = soundPageViewModel(context) orelse return false;
    const screen_point = SoundPage.Point{ .x_px = point.x, .y_px = point.y };
    const action = SoundPage.actionAt(&model, card, &context.presented_sound_layout, screen_point);
    switch (action) {
        .back => {
            context.sound_page_open = false;
            _ = context.input_router.route(.cancel, &context.presented_sound_layout);
        },
        .select_default_device => |sound_action| _ = dispatchSoundAction(context, sound_action),
        .set_volume => |sound_action| {
            if (!slider_press_already_handled) {
                _ = dispatchSoundAction(context, sound_action);
                _ = context.input_router.route(.release, &context.presented_sound_layout);
            }
        },
        .spatial => |index| logFormatted("sound page: spatial sound row {d} has no public read/write API", .{index}),
        .open_settings => {
            _ = ShellCommand.openUri(uri_sound);
            context.sound_page_open = false;
            _ = context.input_router.route(.cancel, &context.presented_sound_layout);
            _ = context.motion.setTarget(.collapsed);
        },
        .scroll_by => |distance| {
            context.sound_page_state.scroll = std.math.clamp(context.sound_page_state.scroll + distance, 0, SoundPage.scrollLimit(card, &model));
        },
        .none => return false,
    }
    if (context.window) |window| window.invalidate();
    return true;
}

fn trayPressWorker(request: TrayPress.Request, right_click: bool) void {
    const com_result = CoInitializeEx(null, 0);
    if (com_result < 0) {
        Log.logLine("tray icon click: COM initialization failed");
        return;
    }
    defer CoUninitialize();
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

fn sameImagePath(a_arg: []const u16, b_arg: []const u16) bool {
    const a = std.mem.sliceTo(a_arg, 0);
    const b = std.mem.sliceTo(b_arg, 0);
    if (a.len == 0 or a.len != b.len) return false;
    for (a, b) |left, right| {
        const lower_left = if (left >= 'A' and left <= 'Z') left + ('a' - 'A') else left;
        const lower_right = if (right >= 'A' and right <= 'Z') right + ('a' - 'A') else right;
        if (lower_left != lower_right) return false;
    }
    return true;
}

fn processImagePath(process_id: DWORD) ?[512]u16 {
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
    defer _ = CloseHandle(process);
    var path: [512]u16 = @splat(0);
    var length: DWORD = @intCast(path.len);
    if (QueryFullProcessImageNameW(process, 0, &path, &length) == 0 or length == 0) return null;
    path[@min(length, @as(DWORD, @intCast(path.len - 1)))] = 0;
    return path;
}

fn processCreatedAt(process_id: DWORD) ?u64 {
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
    defer _ = CloseHandle(process);
    var created = FileTime{ .low = 0, .high = 0 };
    var exited = FileTime{ .low = 0, .high = 0 };
    var kernel = FileTime{ .low = 0, .high = 0 };
    var user = FileTime{ .low = 0, .high = 0 };
    if (GetProcessTimes(process, &created, &exited, &kernel, &user) == 0) return null;
    return (@as(u64, created.high) << 32) | created.low;
}

fn windowInstanceForImage(context: *PaintContext, image: []const u16) ?TrayCatalog.WindowInstance {
    if (std.mem.sliceTo(image, 0).len == 0) return null;
    for (context.task_windows.entries[0..context.task_windows.count]) |entry| {
        const path = processImagePath(entry.process_id) orelse continue;
        if (!sameImagePath(&path, image)) continue;
        const window = entry.handle orelse continue;
        const created = processCreatedAt(entry.process_id) orelse continue;
        return .{ .process_id = entry.process_id, .window_handle = @intFromPtr(window), .process_created_at = created };
    }
    return null;
}

fn trayMenuFactsFor(context: *PaintContext, cell: usize) ?TrayCatalog.WindowInstance {
    const icons = context.tray_icons orelse return null;
    if (cell >= icons.count()) return null;
    const path = icons.exePathAt(cell) orelse return null;
    return windowInstanceForImage(context, path);
}

fn windowForIdentity(context: *PaintContext, identity: TrayCatalog.Identity) ?HWND {
    const icon = trayIconForIdentity(context, identity) orelse return null;
    const instance = identity.window_instance orelse return null;
    if (instance.process_id == 0 or instance.window_handle == 0) return null;
    const window: HWND = @ptrFromInt(instance.window_handle);
    if (IsWindow(window) == 0) return null;
    var current_pid: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &current_pid);
    if (current_pid != instance.process_id or processCreatedAt(current_pid) != instance.process_created_at) return null;
    const path = processImagePath(current_pid) orelse return null;
    if (!sameImagePath(&path, &icon.exe_path)) return null;
    return window;
}

fn terminateTrayProcess(context: *PaintContext, identity: TrayCatalog.Identity) bool {
    const window = windowForIdentity(context, identity) orelse return false;
    _ = window;
    const instance = identity.window_instance orelse return false;
    const process = OpenProcess(process_terminate | process_query_limited_information, 0, instance.process_id) orelse return false;
    defer _ = CloseHandle(process);
    var created = FileTime{ .low = 0, .high = 0 };
    var exited = FileTime{ .low = 0, .high = 0 };
    var kernel = FileTime{ .low = 0, .high = 0 };
    var user = FileTime{ .low = 0, .high = 0 };
    if (GetProcessTimes(process, &created, &exited, &kernel, &user) == 0) return false;
    const created_at = (@as(u64, created.high) << 32) | created.low;
    if (created_at != instance.process_created_at) return false;
    return TerminateProcess(process, 0) != 0;
}

fn startTrayPress(context: *PaintContext, cell: usize, right_click: bool) void {
    const icons = context.tray_icons orelse return;
    const icon = icons.at(cell) orelse return;
    const identity = TrayCatalog.identityFor(icon, icons.getRevision(), cell);
    startTrayPressIdentity(context, identity, right_click);
}

fn trayIconForIdentity(context: *PaintContext, identity: TrayCatalog.Identity) ?*const TrayCatalog.Icon {
    const icons = context.tray_icons orelse return null;
    if (identity.revision != icons.getRevision() or identity.index >= icons.count()) return null;
    const icon = icons.at(identity.index) orelse return null;
    if (!TrayCatalog.identityMatches(identity, icon, icons.getRevision(), identity.index)) return null;
    return icon;
}

fn startTrayPressIdentity(context: *PaintContext, identity: TrayCatalog.Identity, right_click: bool) void {
    const icon = trayIconForIdentity(context, identity) orelse {
        Log.logLine("tray icon click: stale registration identity was discarded");
        return;
    };
    const request = makeTrayPressRequest(icon, &icon.exe_path);
    if (std.Thread.spawn(.{}, trayPressWorker, .{ request, right_click })) |thread| {
        thread.detach();
    } else |_| {
        Log.logLine("tray icon click worker could not start");
    }
}

fn trayDockIdentity(icon: TaskbarPage.TrayDockIcon) TrayCatalog.Identity {
    return .{ .revision = icon.revision, .index = icon.source_index, .fingerprint = icon.fingerprint };
}

fn closeTrayMenu(context: *PaintContext) void {
    TrayController.closeMenu(&context.tray_state);
}

fn dismissSystemPanel(context: *PaintContext) void {
    context.system_panel_pinned = false;
    context.sound_page_open = false;
    context.start_page_open = false;
    TrayController.closePage(&context.tray_state);
    closeTrayMenu(context);
    _ = context.input_router.route(.cancel, &context.presented_sound_layout);
    _ = context.motion.setTarget(if (context.music_state.active_present) .music_strip else .collapsed);
}

fn openTrayMenu(context: *PaintContext, cell: usize, card: Geometry.RoundedBox) bool {
    const icons = context.tray_icons orelse return false;
    if (cell >= icons.count()) return false;
    const page = TrayPage.layoutFor(card, @intCast(context.tray_page_icon_count));
    if (cell >= @as(usize, @intCast(page.count))) return false;
    const icon = icons.at(cell) orelse return false;
    var identity = TrayCatalog.identityFor(icon, icons.getRevision(), cell);
    identity.window_instance = trayMenuFactsFor(context, cell);
    if (!TrayController.openMenu(&context.tray_state, identity, icon, icons.getRevision(), identity.window_instance != null)) return false;
    const icon_cell = page.cells[cell];
    const menu = TrayPage.menuFor(card, icon_cell.right, icon_cell.bottom, @intCast(context.tray_state.menu_count));
    context.tray_card_text.view = TrayPage.buildView(card, context.tray_page_icon_count, icons.getRevision(), menu);
    if (menu.count == 0) closeTrayMenu(context);
    return context.tray_state.menu_open;
}

fn handleTrayMenuClick(context: *PaintContext, local_x: f32, local_y: f32) void {
    const hit = TrayPage.actionAt(&context.presented_tray_view, local_x, local_y);
    const row: usize = if (hit) |action| switch (action) {
        .menu_row => |index| index,
        else => {
            closeTrayMenu(context);
            Log.logLine("tray menu: closed by a click outside its rows");
            return;
        },
    } else {
        closeTrayMenu(context);
        Log.logLine("tray menu: closed by a click outside its rows");
        return;
    };
    const selected = context.tray_state.selected orelse {
        closeTrayMenu(context);
        return;
    };
    const icon = trayIconForIdentity(context, selected) orelse {
        closeTrayMenu(context);
        return;
    };
    if (row >= context.tray_state.menu_count) {
        closeTrayMenu(context);
        return;
    }
    const menu_action = context.tray_state.menu_actions[row];
    const was_quit_armed = context.tray_state.quit_armed;
    if (TrayController.activateMenuRow(&context.tray_state, row, icon, context.tray_page_revision)) |effect| {
        switch (effect) {
            .press_icon => |identity| startTrayPressIdentity(context, identity, false),
            .menu_action => |request| runTrayMenuAction(context, request.target, request.action),
        }
        closeTrayMenu(context);
        if (menu_action == .open or menu_action == .close_window or menu_action == .application_menu) dismissSystemPanel(context);
    } else if (!was_quit_armed and context.tray_state.quit_armed) {
        Log.logLine("tray menu: quit armed; click the same row again to confirm");
    } else {
        closeTrayMenu(context);
    }
}

fn runTrayMenuAction(context: *PaintContext, identity: TrayCatalog.Identity, action: TrayController.MenuAction) void {
    const icon = trayIconForIdentity(context, identity) orelse {
        Log.logLine("tray menu: stale registration identity was discarded");
        closeTrayMenu(context);
        return;
    };
    const path = std.mem.sliceTo(&icon.exe_path, 0);
    const image = wideBasename(path);
    switch (action) {
        .open => startTrayPressIdentity(context, identity, false),
        .application_menu => startTrayPressIdentity(context, identity, true),
        .activate_window => {
            const target = windowForIdentity(context, identity);
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
            const target = windowForIdentity(context, identity) orelse return;
            const closed = PostMessageW(target, wm_close, 0, 0) != 0;
            Log.logLine(if (closed) "tray menu: asked the selected application window to close" else "tray menu: selected application window refused close");
        },
        .quit_application => {
            const ended = terminateTrayProcess(context, identity);
            Log.logLine(if (ended) "tray menu: ended the confirmed application process instance" else "tray menu: confirmed process instance is stale or could not be ended");
        },
    }
}

fn handleTrayPageClick(context: *PaintContext, local_x: f32, local_y: f32) bool {
    const action = TrayPage.actionAt(&context.presented_tray_view, local_x, local_y) orelse return false;
    switch (action) {
        .icon => |index| {
            const icons = context.tray_icons orelse return false;
            if (index >= icons.count()) return false;
            const icon = icons.at(index) orelse return false;
            const identity = TrayCatalog.identityFor(icon, icons.getRevision(), index);
            if (TrayController.pressIcon(&context.tray_state, identity, icon, icons.getRevision()) == null) return false;
            startTrayPressIdentity(context, identity, false);
            dismissSystemPanel(context);
        },
        .back => {
            TrayController.closePage(&context.tray_state);
            closeTrayMenu(context);
        },
        .menu_row => return false,
        .outside => return false,
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
    if (!context.start_page_open) return false;
    const page_action = LauncherPage.actionAt(&context.presented_launcher_layout, local_x, local_y) orelse return false;
    const service = context.start_apps orelse return false;
    const action: LauncherController.Action = switch (page_action) {
        .open_apps => .open_apps,
        .toggle_power => .toggle_power,
        .launch_pinned => |request| .{ .launch_pinned = .{
            .index = request.index,
            .frame_generation = request.frame_generation,
        } },
        .pin_app => |index| .{ .pin_app = index },
        .power_row => |index| .{ .power_row = index },
    };
    const effect = LauncherController.reduce(&context.launcher_state, action, service.pins.items, service.list.items);
    if (effect) |operation| switch (operation) {
        .refresh_index => {
            const count = service.refreshList();
            if (count == 0) Log.logLine("launcher: AppsFolder enumeration returned no entries");
        },
        .launch_app => |request| {
            const result = LauncherService.launchStartApp(@ptrCast(&request.app.target));
            if (LauncherController.completeLaunch(&context.launcher_state, request.generation, result)) {
                logFormatted("launcher: launch result={d}; ShellExecute code={d}", .{ @intFromBool(result.succeeded), result.shell_code });
                if (result.succeeded) {
                    context.start_page_open = false;
                    _ = context.motion.setTarget(.collapsed);
                }
            }
        },
        .pin_app => |app| {
            const added = service.pin(std.mem.sliceTo(&app.target, 0), std.mem.sliceTo(&app.name, 0));
            logFormatted("launcher: pin result={d}", .{@intFromBool(added)});
            if (added) context.launcher_state.page = .pins;
        },
        .run_power_action => |row| {
            const success = runPowerAction(row);
            if (success or row >= 2) {
                context.start_page_open = false;
                _ = context.motion.setTarget(.collapsed);
            }
        },
    };
    buildStartCardText(context);
    if (context.window) |window| window.invalidate();
    return true;
}

fn hasActiveNotification(context: *const PaintContext, now: u64) bool {
    return activeNotification(context, now) != null;
}

fn activeNotification(context: *const PaintContext, now: u64) ?*const Notification.Notification {
    const store = context.notifications orelse return null;
    return store.activeDisplayWithFallback(now, callNotificationId(context));
}

fn callNotificationId(context: *const PaintContext) i64 {
    const store = context.notifications orelse return 0;
    return store.sourceNotificationId(.wechat_call, 1) orelse 0;
}

fn consumeNotificationEvents(context: *PaintContext, events: []const NotificationInput.Event, now: u64) usize {
    const store = context.notifications orelse return 0;
    var changed: usize = 0;
    for (events) |event| switch (event) {
        .message => |message| {
            const result = store.ingest(message, now);
            if (result.inserted) {
                logFormatted("notification: [{s}] {s}", .{
                    if (result.notification.app[0] != 0) std.mem.sliceTo(&result.notification.app, 0) else "?",
                    if (result.notification.title[0] != 0) std.mem.sliceTo(&result.notification.title, 0) else std.mem.sliceTo(&result.notification.body, 0),
                });
                changed += 1;
            }
        },
        .dismiss_source => {
            if (store.apply(event, now)) changed += 1;
        },
    };
    if (changed > 0) {
        _ = context.motion.setTarget(.notice_strip);
        if (context.window) |window| window.invalidate();
    }
    return changed;
}

fn musicCardActive(context: *const PaintContext) bool {
    return context.music_state.active_present and !context.system_panel_pinned and
        !context.sound_page_open and !context.start_page_open and !context.tray_state.page_open;
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
    const info = &context.music_state.media;
    const lyric_duration = if (context.lyrics_provider) |provider|
        if (provider.current()) |lyrics| lyrics.track_duration_ms else 0
    else
        0;
    const duration = if (context.music_state.active_from_session and info.duration_ms > 0) info.duration_ms else lyric_duration;
    const app_name = if (context.music_state.active_from_session and info.app_name[0] != 0)
        std.mem.sliceTo(&info.app_name, 0)
    else if (context.music_state.active_from_session)
        std.mem.sliceTo(&info.app, 0)
    else
        "Media";
    const artwork = if (context.music_state.active_from_session and info.artwork_size > 0)
        info.artwork[0..@min(info.artwork_size, info.artwork.len)]
    else
        &.{};
    const app_icon = if (context.music_state.active_from_session and info.icon_size > 0)
        info.icon[0..@min(info.icon_size, info.icon.len)]
    else
        &.{};
    const fraction: f32 = if (duration > 0)
        @as(f32, @floatFromInt(@min(context.music_state.active_position_ms, duration))) / @as(f32, @floatFromInt(duration))
    else
        0;
    context.music_card_text = .{
        .title = std.mem.sliceTo(&context.music_state.active_title, 0),
        .artist = std.mem.sliceTo(&context.music_state.active_artist, 0),
        .album = if (context.music_state.active_from_session) std.mem.sliceTo(&info.album, 0) else &.{},
        .app = app_name,
        .playing = context.music_state.active_playing,
        .position_ms = context.music_state.active_position_ms,
        .duration_ms = duration,
        .progress_fraction = fraction,
        .artwork_png = artwork,
        .artwork_revision = info.artwork_revision,
        .background_png = if (context.music_state.active_from_session and context.music_background_png_size > 0)
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

fn fullscreenPresentationActive(context: *const PaintContext) bool {
    return context.fullscreen_app or context.fullscreen_morph_progress > 0.001;
}

fn nativeHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    if (fullscreenPresentationActive(context)) return false;
    const local = pointToLocalDip(point, context);
    const notification_active = hasActiveNotification(context, GetTickCount64());
    if (notification_active) {
        const strip = Motion.boxForState(.notice_strip, context.motion.anchor);
        if (pointInBox(strip, local[0], local[1])) return true;
    }
    const outer_card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    if (outer_card_up) switch (context.presentation.card_owner) {
        .notification => if (pointInBox(notificationCardBox(context), local[0], local[1])) return true,
        .system_panel => if (pointInBox(systemPanelCardBox(context), local[0], local[1])) return true,
        .music => if (pointInBox(context.motion.current(), local[0], local[1])) return true,
        .none => {},
    };
    if (notification_active) return false;
    if (taskbarRowContains(context.presented_taskbar_view, local[0], local[1]) or
        TaskbarPage.overflowContains(&context.presented_taskbar_view, local[0], local[1])) return true;
    const resting_deck = Motion.boxForState(.collapsed, context.motion.anchor);
    const deck_island = if (hasActiveNotification(context, GetTickCount64()))
        Motion.boxForState(.notice_strip, context.motion.anchor)
    else
        Motion.rowAnchorBox(context.motion.current(), resting_deck);
    if (BarControlLayout.startButtonHit(deck_island, local[0], local[1]) or
        TaskbarPage.overflowButtonHit(&context.presented_taskbar_view, local[0], local[1])) return true;
    const current = context.motion.current();
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    return pointInBox(current, local[0], local[1]) or pointInBox(resting, local[0], local[1]);
}

fn nativeWheelHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    if (fullscreenPresentationActive(context)) return false;
    if (context.motion.target() != .expanded or hasActiveNotification(context, GetTickCount64())) return false;
    if (!context.sound_page_open and !(context.start_page_open and context.launcher_state.page == .apps)) return false;
    const local = pointToLocalDip(point, context);
    return pointInBox(systemPanelCardBox(context), local[0], local[1]);
}

fn nativeCursorHitTest(point: IslandWindow.Point, raw_context: ?*anyopaque) callconv(.winapi) bool {
    const raw = raw_context orelse return false;
    const context: *PaintContext = @ptrCast(@alignCast(raw));
    if (fullscreenPresentationActive(context)) return false;
    const local = pointToLocalDip(point, context);
    const notification_active = hasActiveNotification(context, GetTickCount64());
    const resting = Motion.boxForState(.collapsed, context.motion.anchor);
    const deck = if (notification_active)
        Motion.boxForState(.notice_strip, context.motion.anchor)
    else
        Motion.rowAnchorBox(context.motion.current(), resting);
    if (BarControlLayout.startButtonHit(deck, local[0], local[1]) or
        TaskbarPage.overflowButtonHit(&context.presented_taskbar_view, local[0], local[1]) or
        TaskbarPage.systemEntryHit(&context.presented_taskbar_view, local[0], local[1]) or
        TaskbarPage.trayEntryHit(&context.presented_taskbar_view, local[0], local[1])) return true;

    if (TaskbarPage.actionAt(&context.presented_taskbar_view, local[0], local[1]) != null) return true;
    if (TaskbarPage.trayIconAt(&context.presented_taskbar_view, local[0], local[1]) != null) return true;

    const outer_card_up = context.motion.target() == .expanded or context.motion.visibleFromState() == .expanded;
    if (!outer_card_up) return false;
    switch (context.presentation.card_owner) {
        .none, .notification => return false,
        .music => return MusicPage.actionAt(&context.presented_music_layout, .{ .x_px = point.x, .y_px = point.y }) != null,
        .system_panel => switch (context.presentation.panel_level) {
            .sound => {
                return SoundPage.interactionAt(&context.presented_sound_layout, .{ .x_px = point.x, .y_px = point.y }) != null;
            },
            .tray => {
                return TrayPage.actionAt(&context.presented_tray_view, local[0], local[1]) != null;
            },
            .start => {
                return LauncherPage.actionAt(&context.presented_launcher_layout, local[0], local[1]) != null;
            },
            .tiles => {
                const hit = SystemPage.hitFor(&context.system_panel_view, local[0], local[1]);
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
    context.presented_taskbar_view = TaskbarPage.buildView(pill, &.{}, 0);
    const centre = IslandWindow.Point{ .x = 960, .y = 24 };
    if (!nativeHitTest(centre, @ptrCast(&context))) return false;
    if (nativeHitTest(.{ .x = 300, .y = 100 }, @ptrCast(&context))) return false;
    const start = BarControlLayout.startButtonFor(pill);
    if (!nativeHitTest(.{
        .x = @intFromFloat((start.left + start.right) * 0.5),
        .y = @intFromFloat((start.top + start.bottom) * 0.5),
    }, @ptrCast(&context))) return false;
    if (!context.motion.setTarget(.expanded)) return false;
    _ = context.motion.tick(0.36);
    context.presentation.card_owner = .system_panel;
    if (!nativeHitTest(pointAtDipRectCenter(systemPanelCardBox(&context).rect), @ptrCast(&context))) return false;
    if (nativeHitTest(.{ .x = 300, .y = 100 }, @ptrCast(&context))) return false;
    const deck = Motion.rowAnchorBox(context.motion.current(), Motion.boxForState(.collapsed, context.motion.anchor));
    const start_button = BarControlLayout.startButtonFor(deck);
    if (!nativeCursorHitTest(pointAtDipRectCenter(start_button), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(context.presented_taskbar_view.overflow_button_bounds), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat(start_button.right + 1), .y = @intFromFloat((start_button.top + start_button.bottom) * 0.5) }, @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = 960, .y = 100 }, @ptrCast(&context))) return false;

    context.task_windows.count = 3;
    context.taskbar_state.snapshot.count = 3;
    const task_count = taskButtonCount(&context);
    const task_island = deck;
    var task_test_buttons: [3]TextRenderer.TaskButton = @splat(.{});
    for (&task_test_buttons, 0..) |*button, index| button.window_id = index + 1;
    context.presented_taskbar_view = TaskbarPage.buildDockView(task_island, &task_test_buttons, 1, task_test_buttons.len, 1920, false);
    const task_button = context.presented_taskbar_view.buttons[1].bounds;
    if (task_count == 0 or !nativeCursorHitTest(pointAtDipRectCenter(task_button), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat(task_button.right + TaskbarLayout.task_icon_gap_dip * 0.5), .y = @intFromFloat((task_button.top + task_button.bottom) * 0.5) }, @ptrCast(&context))) return false;

    context.music_state.active_present = true;
    context.presentation.card_owner = .music;
    const music_layout = MusicPage.layoutFor(context.motion.current());
    if (!nativeCursorHitTest(pointAtDipRectCenter(music_layout.play_pause), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(music_layout.previous), @ptrCast(&context)) or
        !nativeCursorHitTest(pointAtDipRectCenter(music_layout.next), @ptrCast(&context)) or
        nativeCursorHitTest(pointAtDipRectCenter(music_layout.title), @ptrCast(&context))) return false;
    context.music_state.active_present = false;

    context.start_page_open = true;
    context.presentation.card_owner = .system_panel;
    context.presentation.panel_level = .start;
    const start_card = systemPanelCardBox(&context);
    context.presented_launcher_layout = LauncherPage.buildView(start_card, context.launcher_state.page, 18, 0, 0, Geometry.height(start_card.rect), 1);
    const start_layout = LauncherPage.layoutFor(start_card);
    if (!nativeCursorHitTest(pointAtDipRectCenter(start_layout.power_button), @ptrCast(&context)) or
        nativeCursorHitTest(.{ .x = @intFromFloat((start_card.rect.left + start_card.rect.right) * 0.5), .y = @intFromFloat(start_card.rect.top + 8) }, @ptrCast(&context))) return false;
    context.start_page_open = false;

    var sound_controller = SoundController.Controller{};
    context.sound_controller = &sound_controller;
    context.sound_page_open = true;
    context.presentation.panel_level = .sound;
    const sound_card = systemPanelCardBox(&context);
    const sound_model = soundPageViewModel(&context).?;
    const sound_layout = SoundPage.layoutFor(sound_card, &sound_model, 0);
    context.presented_sound_layout = SoundPage.buildLayoutSnapshot(sound_card, &sound_model, Geometry.height(sound_card.rect), 1, .{});
    if (!nativeCursorHitTest(pointAtDipRectCenter(sound_layout.back_button), @ptrCast(&context)) or
        nativeCursorHitTest(pointAtDipRectCenter(sound_layout.title), @ptrCast(&context))) return false;
    context.sound_page_open = false;
    context.sound_controller = null;

    TrayController.openPage(&context.tray_state, context.tray_page_revision);
    context.presentation.panel_level = .tray;
    context.tray_page_icon_count = 1;
    const tray_card = systemPanelCardBox(&context);
    context.presented_tray_view = TrayPage.buildView(tray_card, 1, context.tray_page_revision, .{});
    const tray_layout = TrayPage.layoutFor(tray_card, 1);
    if (!nativeCursorHitTest(pointAtDipRectCenter(tray_layout.cells[0]), @ptrCast(&context))) return false;
    TrayController.closePage(&context.tray_state);

    context.system_panel_pinned = true;
    context.presentation.panel_level = .tiles;
    context.system_panel_view.presentation.tile_count = 1;
    context.system_panel_view.presentation.page_count = 1;
    context.system_panel_view.presentation.has_brightness = false;
    const panel_layout = SystemLayout.systemPanelFor(systemPanelCardBox(&context), 1, 1, false, 0, 1);
    context.system_panel_view.presentation.layout = panel_layout;
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
    if (context.render_retry_at_ms != 0 and now >= context.render_retry_at_ms) {
        context.render_retry_at_ms = 0;
        window.invalidate();
    }
    const elapsed_ms = if (context.last_tick_ms == 0) 0 else now -| context.last_tick_ms;
    context.last_tick_ms = now;
    const dt = @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000;
    const fullscreen_morph_active = context.fullscreen_morph_progress > 0.0001 or context.fullscreen_morph_target > 0.0001;
    const changed_by_motion = if (fullscreen_morph_active) false else context.motion.tick(dt);
    var hover_animation_active = false;
    var task_hover_animation_active = false;
    var local_time: SystemTime = undefined;
    GetLocalTime(&local_time);
    const clock_changed = local_time.second != context.last_clock_second;
    context.last_clock_second = local_time.second;
    if (context.fullscreen_last_poll_ms == 0 or now -| context.fullscreen_last_poll_ms >= 250) {
        context.fullscreen_last_poll_ms = now;
        const probe = if (context.fullscreen_disabled)
            Monitor.FullscreenProbe{}
        else
            Monitor.probeFullScreenApp(context.monitor_bounds);
        const measured = probe.detected;
        if (measured == context.fullscreen_app) {
            context.fullscreen_candidate = null;
            context.fullscreen_candidate_samples = 0;
        } else {
            const candidate_matches = if (context.fullscreen_candidate) |candidate| candidate == measured else false;
            if (!candidate_matches) {
                context.fullscreen_candidate = measured;
                context.fullscreen_candidate_samples = 1;
                logFormatted(
                    "fullscreen probe: candidate={s}, hwnd=0x{x}, pid={d}, class='{s}', rect=({d},{d})-({d},{d}), visible={d}, minimized={d}, zoomed={d}, reason={s}",
                    .{
                        if (measured) "fullscreen" else "normal",
                        probe.hwnd,
                        probe.process_id,
                        probe.class_name[0..probe.class_name_len],
                        probe.window_rect.left,
                        probe.window_rect.top,
                        probe.window_rect.right,
                        probe.window_rect.bottom,
                        @intFromBool(probe.visible),
                        @intFromBool(probe.minimized),
                        @intFromBool(probe.zoomed),
                        @tagName(probe.reason),
                    },
                );
            } else {
                context.fullscreen_candidate_samples = @min(context.fullscreen_candidate_samples +| 1, 2);
            }
            if (context.fullscreen_candidate_samples >= 2) {
                context.fullscreen_app = measured;
                context.fullscreen_candidate = null;
                context.fullscreen_candidate_samples = 0;
                context.fullscreen_morph_from = context.fullscreen_morph_progress;
                context.fullscreen_morph_target = if (measured) 1 else 0;
                context.fullscreen_morph_started_ms = now;
                logFormatted("fullscreen: state stabilized as {s}", .{if (measured) "fullscreen" else "normal"});
                if (context.app_bar) |bar| {
                    if (measured and bar.registered) {
                        bar.release();
                    } else if (!measured and context.app_bar_reclaim and !bar.registered and context.bar_thickness_px > 0) {
                        _ = bar.claim(window.handle(), .top, context.bar_thickness_px);
                    }
                }
                if (measured) {
                    if (context.input_router.capturedIndex() != null) _ = context.input_router.route(.cancel, &context.presented_sound_layout);
                    context.pending_press_point = null;
                    context.pending_press_action_handled = false;
                }
                window.invalidate();
            }
        }
    }
    const previous_fullscreen_morph = context.fullscreen_morph_progress;
    const fullscreen_morph_elapsed_ms = now -| context.fullscreen_morph_started_ms;
    const fullscreen_morph_time = std.math.clamp(
        @as(f32, @floatFromInt(fullscreen_morph_elapsed_ms)) / @as(f32, @floatFromInt(fullscreen_morph_duration_ms)),
        0,
        1,
    );
    context.fullscreen_morph_progress = context.fullscreen_morph_from +
        (context.fullscreen_morph_target - context.fullscreen_morph_from) * fullscreen_morph_time;
    if (fullscreen_morph_time >= 1) context.fullscreen_morph_progress = context.fullscreen_morph_target;
    const fullscreen_morph_animating = fullscreen_morph_time < 1 and context.fullscreen_morph_from != context.fullscreen_morph_target;
    if (@abs(context.fullscreen_morph_progress - previous_fullscreen_morph) > 0.0001) window.invalidate();
    var task_refresh_changed = syncTaskbarSnapshot(context);
    if (context.task_last_refresh_ms == 0 or now -| context.task_last_refresh_ms >= task_window_refresh_fallback_ms) {
        context.task_last_refresh_ms = now;
        const previous_count = context.task_windows.count;
        const previous_foreground = context.task_windows.foreground;
        const previous_revision = context.task_windows.revision;
        var previous_handles: [WindowList.max_task_windows]?*anyopaque = @splat(null);
        for (context.task_windows.entries, 0..) |entry, index| previous_handles[index] = entry.handle;
        _ = context.task_windows.refresh();
        const snapshot_changed = syncTaskbarSnapshot(context);
        task_refresh_changed = task_refresh_changed or snapshot_changed or previous_count != context.task_windows.count or previous_foreground != context.task_windows.foreground or previous_revision != context.task_windows.revision;
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
                if (context.tray_state.page_open) window.invalidate();
            }
            if (tray_changed) {
                if (context.tray_state.menu_open) closeTrayMenu(context);
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
            _ = store;
            var incoming = NotificationInput.Message{};
            while (server.take(&incoming)) {
                _ = consumeNotificationEvents(context, &.{.{ .message = incoming }}, now);
            }
        }
    }

    if (context.notifications != null) {
        if (now -| context.wechat_last_poll_ms >= 500) {
            context.wechat_last_poll_ms = now;
            var events: [2]NotificationInput.Event = undefined;
            const event_count = context.wechat.poll(&events, now);
            if (consumeNotificationEvents(context, events[0..event_count], now) > 0) {
                logFormatted("wechat: {d} window announcement(s) so far", .{context.wechat.announcementCount()});
            }
        }
        if (context.sound_controller != null and now -| context.wechat_last_sound_poll_ms >= 200) {
            context.wechat_last_sound_poll_ms = now;
            const snapshot = context.sound_controller.?.state.output;
            var wechat_session_active = false;
            var wechat_session_count: i32 = 0;
            for (snapshot.sessions[0..@min(snapshot.session_count, snapshot.sessions.len)]) |session| {
                if (!WeChatWatch.isWeChatProcess(session.pid)) continue;
                wechat_session_count += 1;
                wechat_session_active = wechat_session_active or session.active;
            }
            var events: [1]NotificationInput.Event = undefined;
            const event_count = context.wechat.pollSound(
                &events,
                WeChatWatch.anyWeChatProcessRunning(),
                wechat_session_active,
                wechat_session_count,
                now,
            );
            _ = consumeNotificationEvents(context, events[0..event_count], now);
        }
    }
    if (callNotificationId(context) != 0 and now -| context.call_meter_redraw_ms >= 50) {
        context.call_meter_redraw_ms = now;
        window.invalidate();
    }

    if (context.music_session) |music| {
        const music_revision = music.getRevision();
        if (music_revision != context.last_music_revision) {
            context.last_music_revision = music_revision;
            context.last_music_reading_ms = now;
            music.snapshot(&context.music_state.media);
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

    const fallback_up = context.player_snapshot.present and context.player_snapshot.title[0] != 0;
    const fallback = if (fallback_up) MusicController.FallbackPlayer{
        .present = true,
        .title = std.mem.sliceTo(&context.player_snapshot.title, 0),
        .artist = std.mem.sliceTo(&context.player_snapshot.artist, 0),
    } else MusicController.FallbackPlayer{};
    const since_media_reading = now -| context.last_music_reading_ms;
    const track_changed = context.music_state.update(
        context.music_state.media,
        fallback,
        @intCast(@min(elapsed_ms, std.math.maxInt(i64))),
        @intCast(@min(since_media_reading, std.math.maxInt(i64))),
    );
    if (track_changed) {
        context.shown_lyric_text = @splat(0);
        context.replaced_lyric_text = @splat(0);
        context.lyric_line_age_seconds = 1;
        context.lyric_scroll_dip = 0;
        context.replaced_lyric_scroll_dip = 0;
        context.music_wave_accent = .{};
        context.last_wave_artwork_revision = std.math.maxInt(u64);
        if (context.lyrics_provider) |lyrics| {
            lyrics.request(
                std.mem.sliceTo(&context.music_state.active_title, 0),
                std.mem.sliceTo(&context.music_state.active_artist, 0),
                context.music_state.track_generation,
            );
        }
    }
    if (!context.music_state.active_present) {
        context.current_lyric_line = .{};
        context.shown_lyric_text = @splat(0);
        context.replaced_lyric_text = @splat(0);
        context.lyric_line_age_seconds = 1;
        context.lyric_scroll_dip = 0;
        context.replaced_lyric_scroll_dip = 0;
        context.music_wave_accent = .{};
        context.last_wave_artwork_revision = std.math.maxInt(u64);
    }
    if (context.music_state.active_from_session and context.music_state.media.artwork_size > 0 and
        context.music_state.media.artwork_revision != context.last_wave_artwork_revision)
    {
        context.last_wave_artwork_revision = context.music_state.media.artwork_revision;
        const png = context.music_state.media.artwork[0..@min(context.music_state.media.artwork_size, context.music_state.media.artwork.len)];
        const prepared = MediaService.prepareArtwork(png, &context.music_background_png);
        context.music_wave_accent = prepared.accent;
        context.music_background_png_size = prepared.background_size;
        context.music_background_revision = if (context.music_background_png_size > 0)
            context.music_state.media.artwork_revision
        else
            0;
    } else if ((!context.music_state.active_from_session or context.music_state.media.artwork_size == 0) and context.last_wave_artwork_revision != std.math.maxInt(u64)) {
        context.music_wave_accent = .{};
        context.last_wave_artwork_revision = 0;
        context.music_background_png_size = 0;
        context.music_background_revision = 0;
    }
    if (context.lyrics_provider) |lyrics| {
        const lyrics_revision = lyrics.getRevision();
        if (lyrics_revision != context.last_lyrics_revision) {
            context.last_lyrics_revision = lyrics_revision;
            var lyrics_snapshot = Lyrics.Lyrics{};
            var result_generation: u64 = 0;
            if (lyrics.snapshot(&lyrics_snapshot, &result_generation)) {
                _ = context.music_state.acceptLyrics(lyrics_snapshot, result_generation);
            }
            window.invalidate();
        }
    }
    var lyric_line_changed = false;
    var lyric_scroll_animating = false;
    if (context.music_state.active_present) {
        context.lyric_line_age_seconds = @min(1, context.lyric_line_age_seconds + dt);
        context.current_lyric_line = .{};
        var next_line: []const u8 = &.{};
        if (context.music_state.lyricAt(context.music_state.active_position_ms, &context.current_lyric_line)) next_line = std.mem.sliceTo(&context.current_lyric_line.text, 0);
        const shown_line = std.mem.sliceTo(&context.shown_lyric_text, 0);
        if (Lyrics.lyricLineChanged(next_line, shown_line)) {
            copyBytesZ(&context.replaced_lyric_text, shown_line);
            context.replaced_lyric_scroll_dip = context.lyric_scroll_dip;
            context.lyric_scroll_dip = 0;
            context.lyric_line_age_seconds = 0;
            copyBytesZ(&context.shown_lyric_text, next_line);
            lyric_line_changed = true;
        }
        const line_to_measure = if (next_line.len != 0) next_line else std.mem.sliceTo(&context.music_state.active_title, 0);
        const line_box = Motion.boxForState(.music_strip, context.motion.anchor);
        if (context.music_state.active_playing and activeNotification(context, now) == null and
            context.text_renderer.scrollingLineNeedsScroll(line_to_measure, Geometry.width(line_box.rect)))
        {
            context.lyric_scroll_dip += dt * 26;
            lyric_scroll_animating = true;
        }
    }
    if (context.weather_reader) |weather_reader| {
        if (weather_reader.getSnapshot()) |source_snapshot| {
            if (WeatherController.apply(&context.weather_state, source_snapshot)) {
                context.last_weather_revision = source_snapshot.revision;
                window.invalidate();
            }
        }
    }
    if (context.music_state.active_playing) {
        context.music_wave_phase += @as(f32, @floatFromInt(@min(elapsed_ms, 100))) / 1000 * 1.15;
        if (context.music_wave_phase > 6.2831853 * 64) context.music_wave_phase -= 6.2831853 * 64;
    }
    if (context.music_state.active_playing and activeNotification(context, now) == null and now -| context.music_meter_redraw_ms >= 33) {
        context.music_meter_redraw_ms = now;
        window.invalidate();
    }
    if (!context.fullscreen_app and context.motion.target() == .full_bar) {
        _ = context.motion.setTarget(if (context.music_state.active_present) .music_strip else .collapsed);
    }
    buildMusicCardText(context);
    if (!hasActiveNotification(context, now) and !context.system_panel_pinned and
        !context.sound_page_open and !context.start_page_open and !context.tray_state.page_open)
    {
        if (context.music_state.active_present and context.motion.target() == .collapsed) {
            _ = context.motion.setTarget(.music_strip);
        } else if (!context.music_state.active_present and context.motion.target() == .music_strip) {
            _ = context.motion.setTarget(.collapsed);
        }
    }
    const music_second = @divTrunc(context.music_state.active_position_ms, 1000);
    if (context.motion.target() == .expanded and context.music_state.active_present and music_second != context.last_music_card_second) {
        context.last_music_card_second = music_second;
        window.invalidate();
    }

    var pointer: IslandWindow.Point = undefined;
    const have_pointer = !fullscreenPresentationActive(context) and window.pointerPosition(&pointer);
    var pointer_on_task_row = false;
    var right_click_point: IslandWindow.Point = undefined;
    while (window.takeRightClick(&right_click_point)) {
        if (fullscreenPresentationActive(context)) continue;
        const local_right = pointToLocalDip(right_click_point, context);
        const notification_active = hasActiveNotification(context, now);
        const card = systemPanelCardBox(context);
        if (TaskbarPage.trayIconAt(&context.presented_taskbar_view, local_right[0], local_right[1])) |dock_icon| {
            startTrayPressIdentity(context, trayDockIdentity(dock_icon), true);
        } else if (!notification_active and context.start_page_open and context.motion.target() == .expanded and context.launcher_state.page == .pins) {
            const hit = LauncherPage.actionAt(&context.presented_launcher_layout, local_right[0], local_right[1]);
            const pin: i32 = if (hit) |action| switch (action) {
                .launch_pinned => |request| @intCast(request.index),
                else => -1,
            } else -1;
            if (pin >= 0) {
                if (context.start_apps) |apps| {
                    const pin_index: usize = @intCast(pin);
                    if (apps.pinAt(pin_index)) |app| {
                        var name_utf8: [512]u8 = undefined;
                        logFormatted("start: unpinning '{s}'", .{CommandLine.wideTextToUtf8(&app.name, &name_utf8)});
                    }
                    if (apps.unpin(pin_index)) {
                        context.launcher_state.power_confirm_row = -1;
                        buildStartCardText(context);
                        window.invalidate();
                    }
                }
            }
        } else if (!notification_active and context.tray_state.page_open and context.motion.target() == .expanded and pointInBox(card, local_right[0], local_right[1])) {
            const action = TrayPage.actionAt(&context.presented_tray_view, local_right[0], local_right[1]);
            const cell: ?usize = if (action) |hit| switch (hit) {
                .icon => |index| index,
                else => null,
            } else null;
            if (cell) |index| if (openTrayMenu(context, index, card)) {
                logFormatted("tray menu: opened for cell {d} ({d} entries)", .{ index, context.tray_state.menu_count });
                window.invalidate();
            };
        }
    }
    var pressed_point: IslandWindow.Point = undefined;
    if (window.takePress(&pressed_point) and !fullscreenPresentationActive(context)) {
        context.pending_press_point = pressed_point;
        context.pending_press_action_handled = false;
        if (context.sound_page_open and context.motion.target() == .expanded and !hasActiveNotification(context, now)) {
            const action = context.input_router.route(.{ .press = .{ .x_px = pressed_point.x, .y_px = pressed_point.y } }, &context.presented_sound_layout);
            context.pending_press_action_handled = if (std.meta.activeTag(action) == .adjust) action.adjust.phase == .press else false;
            dispatchInputAction(context, action);
        }
    }
    if (have_pointer) {
        const local = pointToLocalDip(pointer, context);
        const task_count = taskButtonCount(context);
        const next_task_hovered = if (task_count > 0)
            TaskbarPage.hoverTarget(&context.presented_taskbar_view, context.taskbar_state.hovered_id, local[0], local[1])
        else
            null;
        var effective_task_hovered = next_task_hovered;
        if (next_task_hovered != null) {
            context.task_hover_leave_deadline_ms = 0;
        } else if (context.taskbar_state.hovered_id) |current_hovered| {
            if (context.task_hover_leave_deadline_ms == 0) {
                context.task_hover_leave_deadline_ms = now + task_hover_leave_delay_ms;
            }
            if (now < context.task_hover_leave_deadline_ms) {
                effective_task_hovered = current_hovered;
            } else {
                context.task_hover_leave_deadline_ms = 0;
            }
        } else {
            context.task_hover_leave_deadline_ms = 0;
        }
        const hover_target_changed = context.taskbar_state.setHover(effective_task_hovered);
        var task_hover_visual_changed = false;
        var task_hover_animating = false;
        var visible_hover_ids: [TaskbarLayout.max_task_icons]TaskbarCatalog.WindowId = @splat(0);
        const visible_hover_count = @min(context.presented_taskbar_view.count, visible_hover_ids.len);
        for (context.presented_taskbar_view.buttons[0..visible_hover_count], 0..) |button, index| {
            visible_hover_ids[index] = button.window_id;
        }
        for (&context.task_hover_motions) |*motion| {
            if (motion.window_id == 0) continue;
            var still_visible = false;
            for (visible_hover_ids[0..visible_hover_count]) |window_id| {
                if (window_id == motion.window_id) {
                    still_visible = true;
                    break;
                }
            }
            if (!still_visible) motion.* = .{};
        }
        for (context.presented_taskbar_view.buttons[0..visible_hover_count]) |button| {
            if (button.window_id == 0) continue;
            var motion_slot: ?*TaskHoverMotion = null;
            for (&context.task_hover_motions) |*motion| {
                if (motion.window_id == button.window_id) {
                    motion_slot = motion;
                    break;
                }
            }
            var motion_created = false;
            if (motion_slot == null) {
                for (&context.task_hover_motions) |*motion| {
                    if (motion.window_id == 0) {
                        motion.* = .{ .window_id = button.window_id };
                        motion_slot = motion;
                        motion_created = true;
                        break;
                    }
                }
            }
            const hover_motion = motion_slot orelse continue;
            const target: f32 = if (context.taskbar_state.hovered_id == button.window_id) 1 else 0;
            const previous_progress = hover_motion.progress;
            const hover_dt: f32 = if (hover_target_changed or motion_created) 0 else dt;
            if (hover_target_changed and
                ((target > hover_motion.progress and hover_motion.velocity < 0) or
                    (target < hover_motion.progress and hover_motion.velocity > 0)))
            {
                hover_motion.velocity = 0;
            }
            const omega = if (target > hover_motion.progress) task_hover_expand_omega else task_hover_retract_omega;
            const animating = BarControlLayout.springStepWithDamping(
                &hover_motion.progress,
                &hover_motion.velocity,
                target,
                hover_dt,
                omega,
                task_hover_spring_damping,
            );
            if (hover_motion.progress > TaskbarLayout.task_icon_hover_progress_max) {
                hover_motion.progress = TaskbarLayout.task_icon_hover_progress_max;
                hover_motion.velocity = 0;
            }
            if (@abs(hover_motion.progress - previous_progress) > 0.0001) task_hover_visual_changed = true;
            task_hover_animating = animating or task_hover_animating;
            if (!animating and target == 0 and hover_motion.progress == 0) hover_motion.* = .{};
        }
        updateTaskThumbnailPreview(context, now);
        const on_task_row = taskbarRowContains(context.presented_taskbar_view, local[0], local[1]);
        pointer_on_task_row = on_task_row;
        const resting_state: Motion.IslandState = if (context.music_state.active_present) .music_strip else .collapsed;
        const resting = Motion.boxForState(resting_state, context.motion.anchor);
        const notification_active = hasActiveNotification(context, now);
        const interactive_pill = if (notification_active) Motion.boxForState(.notice_strip, context.motion.anchor) else resting;
        const resting_deck = Motion.boxForState(.collapsed, context.motion.anchor);
        const deck_island = if (notification_active)
            Motion.boxForState(.notice_strip, context.motion.anchor)
        else
            Motion.rowAnchorBox(context.motion.current(), resting_deck);
        const on_start_button = BarControlLayout.startButtonHit(deck_island, local[0], local[1]);
        const on_system_button = TaskbarPage.systemEntryHit(&context.presented_taskbar_view, local[0], local[1]);
        const on_tray_button = TaskbarPage.trayEntryHit(&context.presented_taskbar_view, local[0], local[1]);
        const on_overflow_button = TaskbarPage.overflowButtonHit(&context.presented_taskbar_view, local[0], local[1]);
        const on_control = on_start_button or on_system_button or on_tray_button or on_overflow_button;
        var button_wash_changed = false;
        button_wash_changed = BarControlLayout.controlWashStep(&context.start_button_wash, &context.start_button_velocity, if (context.forced_start_hover or on_start_button) 1 else 0, dt) or button_wash_changed;
        button_wash_changed = BarControlLayout.controlWashStep(&context.system_button_wash, &context.system_button_velocity, if (on_system_button) 1 else 0, dt) or button_wash_changed;
        button_wash_changed = BarControlLayout.controlWashStep(&context.tray_entry_wash, &context.tray_entry_velocity, if (on_tray_button) 1 else 0, dt) or button_wash_changed;
        button_wash_changed = BarControlLayout.controlWashStep(&context.tray_button_wash, &context.tray_button_velocity, if (on_overflow_button) 1 else 0, dt) or button_wash_changed;
        const on_pill = pointInBox(interactive_pill, local[0], local[1]) or on_control;
        if (button_wash_changed or task_hover_animating or task_hover_visual_changed) window.invalidate();
        task_hover_animation_active = task_hover_animating or task_hover_visual_changed or context.task_hover_leave_deadline_ms != 0;
        hover_animation_active = button_wash_changed or task_hover_animation_active;
        if (window.takeClick() and !fullscreenPresentationActive(context)) {
            const press = context.pending_press_point orelse pointer;
            const released_action = context.input_router.route(.release, &context.presented_sound_layout);
            dispatchInputAction(context, released_action);
            const slider_press_already_handled = context.pending_press_action_handled or std.meta.activeTag(released_action) == .release;
            context.pending_press_point = null;
            context.pending_press_action_handled = false;
            const pressed_local = pointToLocalDip(press, context);
            if (context.tray_state.menu_open) {
                handleTrayMenuClick(context, pressed_local[0], pressed_local[1]);
                window.invalidate();
            } else if (TaskbarPage.trayIconAt(&context.presented_taskbar_view, pressed_local[0], pressed_local[1])) |dock_icon| {
                startTrayPressIdentity(context, trayDockIdentity(dock_icon), false);
            } else if (hasActiveNotification(context, now)) {
                if (context.notifications) |store| {
                    const call_id = callNotificationId(context);
                    const keep_call: ?i64 = if (call_id != 0)
                        call_id
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
                const press_on_start = BarControlLayout.startButtonHit(press_deck, pressed_local[0], pressed_local[1]);
                const press_on_system = TaskbarPage.systemEntryHit(&context.presented_taskbar_view, pressed_local[0], pressed_local[1]);
                const press_on_tray = TaskbarPage.trayEntryHit(&context.presented_taskbar_view, pressed_local[0], pressed_local[1]);
                const press_on_overflow = TaskbarPage.overflowButtonHit(&context.presented_taskbar_view, pressed_local[0], pressed_local[1]);
                if (!notification_active_now and press_on_system) {
                    context.task_overflow_open = false;
                    const close = context.system_panel_pinned and !context.start_page_open and !context.tray_state.page_open and !context.sound_page_open;
                    closeTrayMenu(context);
                    context.system_panel_pinned = !close;
                    if (!close) context.card_hang = .overflow_button;
                    context.start_page_open = false;
                    TrayController.closePage(&context.tray_state);
                    context.sound_page_open = false;
                    if (close) _ = context.motion.setTarget(resting_state) else _ = context.motion.setTarget(.expanded);
                    window.invalidate();
                } else if (!notification_active_now and press_on_start) {
                    context.task_overflow_open = false;
                    const close = context.start_page_open;
                    closeTrayMenu(context);
                    context.start_page_open = !close;
                    TrayController.closePage(&context.tray_state);
                    context.sound_page_open = false;
                    context.system_panel_pinned = !close;
                    if (!close) context.card_hang = .start_button;
                    if (close) {
                        _ = context.motion.setTarget(resting_state);
                    } else {
                        context.launcher_state.page = .pins;
                        context.launcher_state.power_confirm_row = -1;
                        if (context.start_apps) |apps| _ = apps.refreshList();
                        buildStartCardText(context);
                        _ = context.motion.setTarget(.expanded);
                    }
                    window.invalidate();
                } else if (!notification_active_now and press_on_tray) {
                    context.task_overflow_open = false;
                    const close = context.tray_state.page_open;
                    closeTrayMenu(context);
                    if (close) TrayController.closePage(&context.tray_state) else TrayController.openPage(&context.tray_state, context.tray_page_revision);
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
                } else if (!notification_active_now and press_on_overflow) {
                    context.task_overflow_open = !context.task_overflow_open;
                    if (context.task_overflow_open) {
                        closeTrayMenu(context);
                        context.system_panel_pinned = false;
                        context.start_page_open = false;
                        context.sound_page_open = false;
                        TrayController.closePage(&context.tray_state);
                        if (!context.music_state.active_present) _ = context.motion.setTarget(resting_state);
                    }
                    window.invalidate();
                } else if (TaskbarPage.actionAt(&context.presented_taskbar_view, pressed_local[0], pressed_local[1])) |id| {
                    activateTaskWindow(context, id, window);
                } else if (TaskbarPage.overflowContains(&context.presented_taskbar_view, pressed_local[0], pressed_local[1])) {
                    // Keep clicks on the popover surface from reaching a page underneath it.
                } else if (!notification_active_now and musicCardActive(context)) {
                    const action = MusicPage.actionAt(&context.presented_music_layout, .{ .x_px = press.x, .y_px = press.y });
                    if (action) |music_action| {
                        if (context.music_session) |music| {
                            const controller_action: MusicController.Action = switch (music_action) {
                                .previous => .previous,
                                .play_pause => .play_pause,
                                .next => .next,
                            };
                            if (!music.requestTransport(MusicController.transportFor(controller_action))) Log.logLine("music: transport request could not be sent");
                        } else {
                            Log.logLine("music: transport controls unavailable for the active window-title player");
                        }
                    } else if (pointInBox(interactive_pill, pressed_local[0], pressed_local[1])) {
                        context.system_panel_pinned = true;
                        window.invalidate();
                    }
                } else if (!notification_active_now and context.motion.target() == .expanded and !musicCardActive(context) and pointInBox(systemPanelCardBox(context), pressed_local[0], pressed_local[1])) {
                    if (context.sound_page_open) {
                        _ = handleSoundPageClick(context, pressed_local[0], pressed_local[1], press, slider_press_already_handled);
                    } else if (context.start_page_open) {
                        _ = handleStartPageClick(context, pressed_local[0], pressed_local[1]);
                    } else if (context.tray_state.page_open) {
                        _ = handleTrayPageClick(context, pressed_local[0], pressed_local[1]);
                    } else {
                        _ = handleSystemPanelClick(context, pressed_local[0], pressed_local[1]);
                    }
                } else if (pointInBox(interactive_pill, pressed_local[0], pressed_local[1])) {
                    if (context.motion.target() == .expanded and context.music_state.active_present) {
                        context.system_panel_pinned = !context.system_panel_pinned;
                        if (!context.system_panel_pinned) {
                            context.sound_page_open = false;
                            context.start_page_open = false;
                            TrayController.closePage(&context.tray_state);
                        }
                        window.invalidate();
                    } else if (context.motion.target() == .expanded) {
                        context.system_panel_pinned = false;
                        context.sound_page_open = false;
                        context.start_page_open = false;
                        TrayController.closePage(&context.tray_state);
                        _ = context.motion.setTarget(resting_state);
                        window.invalidate();
                    } else if (context.music_state.active_present) {
                        context.system_panel_pinned = false;
                        _ = context.motion.setTarget(.expanded);
                        window.invalidate();
                    } else {
                        closeTrayMenu(context);
                        context.system_panel_pinned = true;
                        context.sound_page_open = false;
                        context.start_page_open = false;
                        TrayController.closePage(&context.tray_state);
                        context.card_hang = .overflow_button;
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
            const hovered_sound = if (pointInBox(systemPanelCardBox(context), local[0], local[1]))
                SoundPage.interactionAt(&context.presented_sound_layout, .{ .x_px = pointer.x, .y_px = pointer.y })
            else
                null;
            context.sound_page_state.setHovered(hovered_sound);
            if (window.leftButtonDown() and context.input_router.capturedIndex() != null) {
                const action = context.input_router.route(.{ .move = .{
                    .point = .{ .x_px = pointer.x, .y_px = pointer.y },
                    .button_down = true,
                } }, &context.presented_sound_layout);
                dispatchInputAction(context, action);
            } else if (!window.leftButtonDown()) {
                _ = context.input_router.route(.cancel, &context.presented_sound_layout);
            }
            if (pointInBox(systemPanelCardBox(context), local[0], local[1])) {
                const wheel = window.takeWheelNotches();
                if (wheel != 0) {
                    const card = systemPanelCardBox(context);
                    if (soundPageViewModel(context)) |model| context.sound_page_state.scroll = std.math.clamp(context.sound_page_state.scroll - @as(f32, @floatFromInt(wheel)) * 60, 0, SoundPage.scrollLimit(card, &model));
                    window.invalidate();
                }
            }
        } else {
            if (context.input_router.capturedIndex() != null) _ = context.input_router.route(.cancel, &context.presented_sound_layout);
            context.sound_page_state.setHovered(null);
            context.sound_page_state.setPressed(null);
        }

        if (context.tray_state.page_open and context.motion.target() == .expanded and !notification_active) {
            const hover: TrayPage.Hover = if (pointInBox(systemPanelCardBox(context), local[0], local[1]))
                TrayPage.hoverAt(&context.presented_tray_view, local[0], local[1])
            else
                .{};
            if (hover.icon != context.tray_state.hovered_icon) {
                context.tray_state.hovered_icon = hover.icon;
                window.invalidate();
            }
        } else if (context.tray_state.hovered_icon != -1) {
            context.tray_state.hovered_icon = -1;
        }

        if (context.tray_state.menu_open and context.tray_state.page_open and context.motion.target() == .expanded and !notification_active) {
            const hover = TrayPage.hoverAt(&context.presented_tray_view, local[0], local[1]);
            if (hover.menu_row != context.tray_state.hovered_menu_row) {
                context.tray_state.hovered_menu_row = hover.menu_row;
                window.invalidate();
            }
        } else if (context.tray_state.menu_open) {
            closeTrayMenu(context);
            window.invalidate();
        }

        if (context.start_page_open and context.motion.target() == .expanded and !notification_active) {
            const hover = LauncherPage.hoverAt(&context.presented_launcher_layout, local[0], local[1]);
            if (hover.pin != context.start_card_text.hovered_pin or hover.picker_row != context.start_card_text.hovered_picker_row or hover.power_row != context.start_card_text.hovered_power_row or hover.power_button != context.start_card_text.power_button_hovered) {
                context.start_card_text.hovered_pin = hover.pin;
                context.start_card_text.hovered_picker_row = hover.picker_row;
                context.start_card_text.hovered_power_row = hover.power_row;
                context.start_card_text.power_button_hovered = hover.power_button;
                buildStartCardText(context);
                window.invalidate();
            }
            if (LauncherPage.inPickerViewport(&context.presented_launcher_layout, local[0], local[1])) {
                const wheel = window.takeWheelNotches();
                if (wheel != 0) {
                    const visible_rows: i32 = @intFromFloat(@max(1, (context.presented_launcher_layout.layout.grid.bottom - context.presented_launcher_layout.layout.grid.top) / LauncherPage.row_height));
                    const max_scroll = @max(0, @as(i32, @intCast(@min(context.start_card_text.view.app_count, std.math.maxInt(i32)))) - visible_rows);
                    if (context.start_apps) |service| {
                        _ = LauncherController.reduce(&context.launcher_state, .{ .scroll_picker = .{ .wheel = wheel, .max_row = max_scroll } }, service.pins.items, service.list.items);
                        buildStartCardText(context);
                        window.invalidate();
                    }
                }
            }
        }

        if (!fullscreenPresentationActive(context)) {
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
    }

    if (!have_pointer) {
        if (context.thumbnail_preview) |preview| preview.hide();
    }

    if (context.forced_state) |forced| {
        if (context.motion.target() != forced) _ = context.motion.setTarget(forced);
    }
    const task_icon_transition_pending = context.task_icon_transition_deadline_ms != 0;
    const task_icon_transition_animating = task_icon_transition_pending and now < context.task_icon_transition_deadline_ms;
    if (task_icon_transition_pending and !task_icon_transition_animating) context.task_icon_transition_deadline_ms = 0;
    const shape_animating = (context.motion.isAnimating() and !fullscreenPresentationActive(context)) or fullscreen_morph_animating;
    const lyric_roll_animating = context.music_state.active_present and context.lyric_line_age_seconds < Lyrics.line_enter_seconds;
    const active_music_meter = context.music_state.active_playing and activeNotification(context, now) == null;
    const poll_ms = if (fullscreen_morph_animating)
        fullscreen_morph_poll_ms
    else
        pointerPollIntervalFor(
            shape_animating or lyric_scroll_animating or lyric_roll_animating or hover_animation_active or task_icon_transition_animating,
            task_hover_animation_active,
            pointer_on_task_row,
            callNotificationId(context) != 0,
            active_music_meter,
        );
    window.setPointerPollInterval(poll_ms);
    _ = updateInputRegion(context);
    if (system_status_refreshed or task_refresh_changed or changed_by_motion or shape_animating or fullscreen_morph_animating or lyric_line_changed or lyric_scroll_animating or lyric_roll_animating or clock_changed or task_icon_transition_pending) window.invalidate();
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
    context.text_renderer.invalidateDeviceResources();
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
    context.renderer_generation = context.renderer.generation;
    if (context.app_bar_reclaim) {
        context.bar_thickness_px = Geometry.dipToPixels(Geometry.reserved_bar_height_dip, monitor.dpi);
        if (context.app_bar) |bar| _ = bar.claim(hwnd, .top, context.bar_thickness_px);
    }
    _ = updateInputRegion(context);
    Log.logLine("display change: window and renderer synchronized to monitor geometry");
    window.invalidate();
}

fn rebuildGraphicsResources(
    renderer: *Renderer.DeviceResources,
    text_renderer: *TextRenderer.TextRenderer,
    hwnd: HWND,
    width_px: i32,
    height_px: i32,
    scale: f32,
) bool {
    if (width_px <= 0 or height_px <= 0) return false;
    text_renderer.invalidateDeviceResources();
    renderer.shutdown();
    return renderer.initialize(hwnd, @intCast(width_px), @intCast(height_px), scale);
}

fn recoverGraphicsDevice(context: *PaintContext, now_ms: u64) bool {
    if (context.last_graphics_recovery_ms != 0 and now_ms -| context.last_graphics_recovery_ms < 1000) return false;
    context.last_graphics_recovery_ms = now_ms;
    const window = context.window orelse return false;
    const hwnd = window.handle() orelse return false;
    if (!rebuildGraphicsResources(context.renderer, context.text_renderer, hwnd, window_width_px, window_height_px, context.scale)) {
        context.renderer_generation = context.renderer.generation;
        Log.logLine("renderer: graphics-device rebuild failed; a later paint may retry");
        return false;
    }
    context.renderer_generation = context.renderer.generation;
    window.invalidate();
    Log.logLine("renderer: graphics-device resources rebuilt; UI snapshots retained");
    return true;
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

fn notificationIconSmokeCheck() bool {
    return NotificationIcon.smokeCheck(AppIconService.fetchFileIconPng);
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
    if (runSmokeCheck("NotificationInput", 60, NotificationInput.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("DisplayBrightness", 14, SystemService.brightnessSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("Monitor", 15, Monitor.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("NotificationIcon", 16, notificationIconSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("StartMenu", 17, ShellCommand.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Log", 18, Log.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("MusicSession", 36, MediaService.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("ToastStore", 20, ToastStore.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("AppBar", 21, AppBar.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("PlayerWindow", 22, PlayerWindow.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WindowList", 23, WindowList.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Theme", 24, Theme.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WeChatWatch", 25, WeChatWatch.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("ThumbnailLayout", 26, ThumbnailLayout.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("NativeTaskbar", 27, NativeTaskbar.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("SystemStatus", 28, SystemService.statusSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("TrayIcons", 29, TrayIcons.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("SysStatusProbe", 30, SysStatusProbe.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("GlassMaterial", 31, GlassMaterial.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("WicImage", 32, WicImage.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("music-card background blur", 58, WicImage.backgroundBlurCheck)) |failure| return failure;
    if (runSmokeCheck("SystemToggles", 33, SystemService.togglesSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("AudioVolume", 34, AudioVolume.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Weather source", 35, WeatherService.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Lyrics", 37, Lyrics.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("Lyrics", 50, LyricsService.workerSmokeCheck)) |failure| return failure;
    if (runSmokeCheck("AudioService", 38, AudioService.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("StartApps", 39, LauncherService.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("TrayPress", 40, TrayPress.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("TaskbarCatalog", 61, TaskbarCatalog.smokeCheck)) |failure| return failure;
    if (runSmokeCheck("TaskbarController", 62, TaskbarController.smokeCheck)) |failure| return failure;
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
    var sample_weather = StatusLineWeather.View{ .mark = .sun };
    @memcpy(sample_weather.sky[0..3], &[_]u16{ 0x5f3a, 0x9635, 0x96e8 });
    @memcpy(sample_weather.temperature[0..4], &[_]u16{ '-', '1', '2', 0x00b0 });
    const widest_status = test_text_renderer.measureStatusLine(&.{ '2', '3', ':', '5', '9' }, sample_weather);
    const no_weather_status = test_text_renderer.measureStatusLine(&.{ '2', '3', ':', '5', '9' }, .{});
    if (widest_status <= 0 or widest_status > Geometry.pill_width_dip - 16 or
        no_weather_status <= 0 or no_weather_status >= widest_status)
    {
        logFormatted("self-test: clock/status layout invalid: weather={d:.2}, plain={d:.2}", .{ widest_status, no_weather_status });
        return 48;
    }
    var renderer_test_window = IslandWindow.NativeWindow{};
    if (!renderer_test_window.create(0, 0, @intFromFloat(Geometry.pill_width_dip), @intFromFloat(Geometry.pill_height_dip), 0, paintWindow, null, null)) {
        Log.logAndPrint("self-test: compact renderer HWND creation failed");
        return 41;
    }
    const renderer_window_ok = Renderer.nativeWindowCheck(renderer_test_window.handle(), @intFromFloat(Geometry.pill_width_dip), @intFromFloat(Geometry.pill_height_dip), 1, &test_text_renderer, .compact);
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
    if (!BarControlLayout.smokeCheck()) return 46;
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
    music_card: *const MusicPage.CardText,
    music_strip: MusicPage.StripText = .{},
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
    context.music_strip.line = music_text;
    const pill = Renderer.PillAppearance{
        .box = context.motion.current(),
        .line_text = music_text,
        .music_present = stage.state == .music_strip or stage.state == .hover,
        .resting_state = if (stage.state == .music_strip or stage.state == .hover) .music_strip else .collapsed,
        .resting_pill = context.motion.current(),
        .feature_strip_painter = .{ .context = @ptrCast(&context.music_strip), .paint_fn = MusicPage.paintStrip },
        .feature_page_painter = if (stage.state == .expanded) .{ .context = @ptrCast(@constCast(context.music_card)), .paint_fn = MusicPage.paintCard } else null,
        .feature_page_box = if (stage.state == .expanded) context.motion.current() else null,
        .feature_page_reveal = if (stage.state == .expanded) Geometry.height(context.motion.current().rect) else 0,
    };
    _ = context.renderer.renderPill(
        pill,
        context.text_renderer,
        if (stage.state == .expanded) .card else .compact,
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
    var artwork_png: [MediaService.artwork_capacity]u8 = undefined;
    const artwork_len = WicImage.encodeBgraToPng(&art_pixels, 64, 64, &artwork_png);
    var background_png: [MediaService.artwork_capacity]u8 = undefined;
    const background_len = if (artwork_len > 0)
        WicImage.makeBlurredBackgroundPng(artwork_png[0..artwork_len], 105, 59, &background_png)
    else
        0;
    var icon_png: [MediaService.artwork_capacity]u8 = undefined;
    var player_path: [260]u16 = @splat(0);
    const player_found = MediaService.executableFromAppId(&.{ 'Q', 'Q', 'M', 'u', 's', 'i', 'c', '.', 'e', 'x', 'e' }, &player_path);
    var icon_len: usize = 0;
    if (player_found) icon_len = AppIconService.fetchFileIconPng(&player_path, &icon_png);
    if (icon_len == 0) {
        var self_path: [260]u16 = @splat(0);
        const path_len = GetModuleFileNameW(null, &self_path, @intCast(self_path.len));
        if (path_len > 0 and path_len < self_path.len) {
            icon_len = AppIconService.fetchFileIconPng(self_path[0..path_len], &icon_png);
        }
    }
    logFormatted("music preview: artwork={s}, source icon={s}", .{
        if (artwork_len > 0) "generated" else "unavailable",
        if (icon_len > 0) "loaded" else "unavailable",
    });

    var card = MusicPage.CardText{
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

    var host = AppWindowHost.WindowHost{};
    defer host.destroy();
    if (!host.initialize(options.appbar, options.keep_taskbar, paintWindow, maintainShellState)) return;
    const monitor = host.monitor;
    const dpi = host.dpi;
    window_width_px = host.width_px;
    window_height_px = host.height_px;
    const width_px = host.width_px;
    const height_px = host.height_px;
    const x = host.x;
    const y = host.y;
    const window: *IslandWindow.NativeWindow = &host.window;

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

    var thumbnail_preview = ThumbnailAdapter.ThumbnailAdapter{};
    const thumbnail_preview_ready = thumbnail_preview.create(window.handle());
    Log.logLine(if (thumbnail_preview_ready) "thumbnail: task preview ready after 350 ms hover" else "thumbnail: preview window could not be created");
    defer thumbnail_preview.destroy();

    if (!options.keep_taskbar and manage_native_taskbar and !options.keep_strip and host.app_bar_result != .registered) {
        const released = native_taskbar.releaseWorkArea();
        release_taskbar_strip = released.released;
        Log.logLine(if (released.released) "taskbar work-area strip released" else "taskbar work-area strip could not be released");
    } else if (options.keep_strip) {
        Log.logLine("taskbar work-area strip retained (--keep-strip)");
    } else if (host.app_bar_result == .registered) {
        Log.logLine("taskbar work-area strip remains reserved by the AppBar");
    }

    var renderer = Renderer.DeviceResources{ .fetch_app_icon_png = AppIconService.fetchFileIconPng };
    if (!renderer.initialize(window.handle(), @intCast(width_px), @intCast(height_px), @as(f32, @floatFromInt(dpi)) / 96.0)) return;
    defer renderer.shutdown();

    var text_renderer = TextRenderer.TextRenderer{};
    if (!text_renderer.initialize()) return;
    defer text_renderer.shutdown();

    const no_media = environmentSwitchEnabled(wide_no_media);
    const no_session = environmentSwitchEnabled(wide_no_session);
    const media_sources = mediaSourceAvailabilityFor(no_media, no_session);
    var runtime = AppRuntime.Runtime{};
    runtime.startBackground(media_sources.session, media_sources.player_window, no_media, no_session, AppIconService.fetchFileIconPng);
    defer runtime.stop();
    var notifications = Notification.Store{};
    var sound_controller = SoundController.Controller{ .port = AppRuntime.soundControllerPort(&runtime.sound_ports) };
    runtime.initializeSoundController(&sound_controller);
    _ = runtime.initializeShellResources(std.heap.page_allocator);
    var account_name: [256]u16 = @splat(0);
    var account_name_size: u32 = @intCast(account_name.len);
    _ = GetUserNameW(&account_name, &account_name_size);
    const start_pin_icon_data = std.heap.page_allocator.alloc(u8, 18 * start_icon_buffer_bytes) catch return;
    defer std.heap.page_allocator.free(start_pin_icon_data);
    var initial_brightness: i32 = 50;
    const initial_brightness_available = SystemService.readBrightness(monitor.monitor, &initial_brightness);
    const fullscreen_disabled = environmentSwitchEnabled(wide_no_fullscreen);

    var paint_context = PaintContext{
        .renderer = &renderer,
        .renderer_generation = renderer.generation,
        .text_renderer = &text_renderer,
        .pill = .{
            .box = motion.current(),
        },
        .motion = motion,
        .window = window,
        .thumbnail_preview = if (thumbnail_preview_ready) &thumbnail_preview else null,
        .window_x = x,
        .window_y = y,
        .scale = @as(f32, @floatFromInt(dpi)) / 96.0,
        .music_session = if (runtime.music_started) &runtime.music_session else null,
        .sound_controller = &sound_controller,
        .sound_ports = &runtime.sound_ports,
        .weather_reader = &runtime.weather_reader,
        .tray_icons = &runtime.tray_icons,
        .tray_last_refresh_ms = GetTickCount64(),
        .start_apps = &runtime.start_apps,
        .start_pin_icon_data = start_pin_icon_data,
        .account_name = account_name,
        .status_reader = &runtime.status_reader,
        .monitor = monitor.monitor,
        .monitor_bounds = monitor.screen,
        .monitor_work = monitor.work,
        .app_bar = &host.app_bar,
        .app_bar_reclaim = host.app_bar_result == .registered,
        .bar_thickness_px = host.bar_thickness_px,
        .fullscreen_disabled = fullscreen_disabled,
        .trace_ui_enabled = environmentSwitchEnabled(wide_ui_trace),
        .last_weather_revision = 0,
        .system_state = .{
            .status = runtime.sampled_system_status,
            .installed_layout_count = runtime.status_reader.layoutCount(),
            .brightness_available = initial_brightness_available,
            .brightness_percent = initial_brightness,
        },
        .status_sampled_ms = GetTickCount64(),
        .system_panel_pinned = options.system_panel,
        .forced_start_hover = options.start_hover,
        .forced_state = options.forced_state,
        .lyrics_provider = &runtime.lyrics_provider,
        .player_window = if (runtime.player_window_started) &runtime.player_window else null,
        .notification_server = if (runtime.notification_server_started) &runtime.notification_server else null,
        .notifications = &notifications,
    };
    _ = paint_context.task_windows.refresh();
    _ = syncTaskbarSnapshot(&paint_context);
    const task_events_tracked = paint_context.task_windows.startEventTracking(window.handle());
    defer paint_context.task_windows.stopEventTracking();
    Log.logLine(if (task_events_tracked) "taskbar: tracking Windows window events" else "taskbar: event tracking unavailable; using refresh fallback");
    paint_context.task_last_refresh_ms = GetTickCount64();
    buildSystemPanelText(&paint_context);
    buildTrayPageText(&paint_context);
    buildStartCardText(&paint_context);
    window.callback_context = &paint_context;
    window.setPointerCallback(pointerStep);
    window.setDisplayChangeCallback(refreshDisplayGeometry);
    window.setHitTestCallback(nativeHitTest);
    window.setCursorHitTestCallback(nativeCursorHitTest);
    window.setWheelHitTestCallback(nativeWheelHitTest);
    _ = updateInputRegion(&paint_context);

    if (!renderer.renderPill(paint_context.pill, &text_renderer, paint_context.clock_style)) {
        if (!renderer.lastFailureIsDeviceLoss() or
            !rebuildGraphicsResources(&renderer, &text_renderer, window.handle(), width_px, height_px, paint_context.scale)) return;
        paint_context.renderer_generation = renderer.generation;
        if (!renderer.renderPill(paint_context.pill, &text_renderer, paint_context.clock_style)) return;
    }

    runtime.startWeather(!options.offline);
    defer runtime.stopWeather();
    window.show();
    const loop_result = host.messageLoop();
    if (loop_result != 0) ExitProcess(6);
}
