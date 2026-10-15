const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");
const StatePolicy = @import("StatePolicy");
const CardLayout = @import("CardLayout");
const IslandWindow = @import("IslandWindow");
const Lyrics = @import("MusicLyrics");
const LyricsService = @import("LyricsService");
const MiniJson = @import("MiniJson");
const Monitor = @import("Monitor");
const MediaService = @import("MediaService");
const Notification = @import("Notification");
const Renderer = @import("Renderer");
const TextRenderer = @import("TextRenderer");
const Theme = @import("Theme");
const WicImage = @import("WicImage");
const Log = @import("Log");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const RECT = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const SidAndAttributes = extern struct { sid: ?*anyopaque, attributes: DWORD };
const TokenMandatoryLabel = extern struct { label: SidAndAttributes };
const AppBarData = extern struct { size: DWORD, window: HANDLE, callback_message: DWORD, edge: DWORD, rect: RECT, data: isize };

extern "user32" fn FindWindowW(class_name: [*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "user32" fn GetWindowRect(window: HANDLE, rect: *RECT) callconv(.winapi) BOOL;
extern "user32" fn IsWindowVisible(window: HANDLE) callconv(.winapi) BOOL;
extern "user32" fn GetWindowThreadProcessId(window: HANDLE, process_id: *DWORD) callconv(.winapi) DWORD;
extern "user32" fn ShowWindow(window: HANDLE, command: i32) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPos(window: HANDLE, insert_after: HANDLE, x: i32, y: i32, width: i32, height: i32, flags: DWORD) callconv(.winapi) BOOL;
extern "user32" fn GetWindowLongPtrW(window: HANDLE, index: i32) callconv(.winapi) isize;
extern "user32" fn SetWindowLongPtrW(window: HANDLE, index: i32, value: isize) callconv(.winapi) isize;
extern "user32" fn SetLayeredWindowAttributes(window: HANDLE, color_key: u32, alpha: u8, flags: DWORD) callconv(.winapi) BOOL;
extern "user32" fn GetDC(window: HANDLE) callconv(.winapi) HANDLE;
extern "user32" fn ReleaseDC(window: HANDLE, dc: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) DWORD;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn GetCurrentProcess() callconv(.winapi) HANDLE;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "advapi32" fn OpenProcessToken(process: HANDLE, access: DWORD, token: *HANDLE) callconv(.winapi) BOOL;
extern "advapi32" fn GetTokenInformation(token: HANDLE, info_class: i32, buffer: [*]u8, buffer_size: DWORD, returned: *DWORD) callconv(.winapi) BOOL;
extern "advapi32" fn GetSidSubAuthorityCount(sid: ?*anyopaque) callconv(.winapi) ?*u8;
extern "advapi32" fn GetSidSubAuthority(sid: ?*anyopaque, index: DWORD) callconv(.winapi) ?*DWORD;
extern "shell32" fn SHAppBarMessage(message: DWORD, data: *AppBarData) callconv(.winapi) usize;
extern "gdi32" fn GetPixel(dc: HANDLE, x: i32, y: i32) callconv(.winapi) u32;

const FALSE: BOOL = 0;
const process_query_limited_information: DWORD = 0x1000;
const token_query: DWORD = 0x0008;
const token_integrity_level: i32 = 25;
const gwl_exstyle: i32 = -20;
const ws_ex_layered: isize = 0x00080000;
const sw_hide: i32 = 0;
const sw_show: i32 = 5;
const lwa_alpha: DWORD = 0x2;
const swp_hidewindow: DWORD = 0x0080;
const swp_showwindow: DWORD = 0x0040;
const swp_nomove: DWORD = 0x0002;
const swp_nosize: DWORD = 0x0001;
const swp_nozorder: DWORD = 0x0004;
const swp_noactivate: DWORD = 0x0010;
const swp_framechanged: DWORD = 0x0020;
const abm_getstate: DWORD = 0x00000004;
const abm_setstate: DWORD = 0x0000000a;
const abs_alwaysontop: isize = 0x00000002;
const abs_autohide: isize = 0x00000001;
const clr_invalid: u32 = 0xffffffff;

pub const Check = struct { name: []const u8, passed: bool };

pub const TraceRect = struct { left: f32 = 0, top: f32 = 0, right: f32 = 0, bottom: f32 = 0 };

/// Opt-in, allocation-free interaction trace. Coordinates are client-local DIPs.
pub const UiTraceEvent = struct {
    operation_id: u64 = 0,
    element: []const u8 = "-",
    element_index: i32 = -1,
    layout_generation: u64 = 0,
    action: []const u8 = "-",
    result: []const u8 = "-",
    hresult: i32 = 0,
    state_revision: u64 = 0,
    renderer_generation: u64 = 0,
    frame_duration_ms: u64 = 0,
    dpi: u32 = 96,
    screen_origin_x_px: i32 = 0,
    screen_origin_y_px: i32 = 0,
    pixels_per_dip: f32 = 1,
    bounds: TraceRect = .{},
    hit_region: TraceRect = .{},
    surface_clip: TraceRect = .{},
    content_clip: TraceRect = .{},
};

pub fn formatUiTrace(output: []u8, event: UiTraceEvent) []const u8 {
    return std.fmt.bufPrint(
        output,
        "ui-trace op={d} element={s}[{d}] layout={d} action={s} result={s} hresult=0x{x} state_rev={d} render_gen={d} frame_ms={d} dpi={d} coord=client_dip origin_px=({d},{d}) scale={d:.3} bounds=({d:.1},{d:.1},{d:.1},{d:.1}) hit=({d:.1},{d:.1},{d:.1},{d:.1}) surface_clip=({d:.1},{d:.1},{d:.1},{d:.1}) content_clip=({d:.1},{d:.1},{d:.1},{d:.1})",
        .{
            event.operation_id,       event.element,            event.element_index,      event.layout_generation,   event.action,            event.result,           @as(u32, @bitCast(event.hresult)), event.state_revision,      event.renderer_generation, event.frame_duration_ms, event.dpi,
            event.screen_origin_x_px, event.screen_origin_y_px, event.pixels_per_dip,     event.bounds.left,         event.bounds.top,        event.bounds.right,     event.bounds.bottom,               event.hit_region.left,     event.hit_region.top,      event.hit_region.right,  event.hit_region.bottom,
            event.surface_clip.left,  event.surface_clip.top,   event.surface_clip.right, event.surface_clip.bottom, event.content_clip.left, event.content_clip.top, event.content_clip.right,          event.content_clip.bottom,
        },
    ) catch "";
}

pub fn logUiTrace(enabled: bool, event: UiTraceEvent) void {
    if (!enabled) return;
    var buffer: [768]u8 = undefined;
    const line = formatUiTrace(&buffer, event);
    if (line.len != 0) Log.logLine(line);
}

test "UI trace includes operation, layout, result, coordinates and resource generations" {
    var buffer: [768]u8 = undefined;
    const line = formatUiTrace(&buffer, .{
        .operation_id = 42,
        .element = "slider",
        .element_index = 3,
        .layout_generation = 9,
        .action = "adjust.drag",
        .result = "queued",
        .renderer_generation = 5,
        .dpi = 144,
    });
    try std.testing.expect(std.mem.indexOf(u8, line, "op=42") != null);
    try std.testing.expect(std.mem.indexOf(u8, line, "element=slider[3] layout=9") != null);
    try std.testing.expect(std.mem.indexOf(u8, line, "action=adjust.drag result=queued") != null);
    try std.testing.expect(std.mem.indexOf(u8, line, "render_gen=5") != null);
    try std.testing.expect(std.mem.indexOf(u8, line, "dpi=144 coord=client_dip") != null);
}

fn geometryCheck() bool {
    const pill = Geometry.pillBox(0, 0, 1920, 0);
    const centre_x = (pill.rect.left + pill.rect.right) * 0.5;
    const centre_y = (pill.rect.top + pill.rect.bottom) * 0.5;
    const diagonal = pill.radius_x / @sqrt(@as(f32, 2));
    const corner_left = pill.rect.left + pill.radius_x;
    const corner_right = pill.rect.right - pill.radius_x;
    const corner_top = pill.rect.top + pill.radius_y;
    const corner_bottom = pill.rect.bottom - pill.radius_y;
    const epsilon: f32 = 0.05;
    const square = Geometry.RoundedBox{
        .rect = .{ .left = 0, .top = 0, .right = 100, .bottom = 50 },
        .radius_x = 0,
        .radius_y = 0,
    };
    return Geometry.contains(pill, centre_x, centre_y) and
        !Geometry.contains(pill, pill.rect.left - 1, centre_y) and
        !Geometry.contains(pill, pill.rect.right + 1, centre_y) and
        !Geometry.contains(pill, centre_x, pill.rect.top - 1) and
        !Geometry.contains(pill, centre_x, pill.rect.bottom + 1) and
        !Geometry.contains(pill, pill.rect.left, pill.rect.top) and
        Geometry.contains(pill, corner_left - diagonal + epsilon, corner_top - diagonal + epsilon) and
        !Geometry.contains(pill, corner_left - diagonal - epsilon, corner_top - diagonal - epsilon) and
        Geometry.contains(pill, corner_right + diagonal - epsilon, corner_top - diagonal + epsilon) and
        Geometry.contains(pill, corner_left - diagonal + epsilon, corner_bottom + diagonal - epsilon) and
        !Geometry.contains(pill, corner_right + diagonal + epsilon, corner_bottom + diagonal + epsilon) and
        Geometry.containsWithTolerance(pill, pill.rect.left - 1, centre_y, Geometry.hit_tolerance_dip) and
        !Geometry.containsWithTolerance(pill, pill.rect.left - Geometry.hit_tolerance_dip - 2, centre_y, Geometry.hit_tolerance_dip) and
        Geometry.contains(square, 50, 25) and Geometry.contains(square, 0.5, 0.5) and
        !Geometry.contains(square, 100.5, 25);
}

fn motionCheck() bool {
    var motion: Motion.Motion = .{};
    const anchor = Motion.anchorForWindow(0, 0, 1920, 32);
    motion.setAnchor(anchor);
    const collapsed = Motion.boxForState(.collapsed, anchor);
    const hover = Motion.boxForState(.hover, anchor);
    const strip = Motion.boxForState(.music_strip, anchor);
    const expanded = Motion.boxForState(.expanded, anchor);
    if (!near(Geometry.width(collapsed.rect), 220, 0.01) or
        !near(Geometry.height(collapsed.rect), 36, 0.01) or
        !near(Geometry.width(hover.rect), 220, 0.01) or
        !near(Geometry.height(hover.rect), 36, 0.01) or
        !near(Geometry.width(strip.rect), 220, 0.01) or
        !near(Geometry.width(expanded.rect), 520, 0.01) or
        !near(Geometry.height(expanded.rect), 280, 0.01) or
        !near(collapsed.radius_x, 18, 0.01) or !near(hover.radius_x, 18, 0.01) or
        !near(expanded.radius_x, Motion.card_radius_dip, 0.01) or
        !near(collapsed.rect.top, expanded.rect.top, 0.01) or
        expanded.rect.bottom <= collapsed.rect.bottom or
        Motion.easeOutCubic(0.5) <= 0.5 or
        !near(Motion.easeInOutCubic(0), 0, 0.0001) or
        !near(Motion.easeInOutCubic(0.5), 0.5, 0.0001) or
        !near(Motion.easeInOutCubic(1), 1, 0.0001) or
        !near(Motion.easeInOutCubic(0.25) + Motion.easeInOutCubic(0.75), 1, 0.0001) or
        Motion.easeInOutCubic(-1) != 0 or Motion.easeInOutCubic(2) != 1 or
        !near(Motion.transitionSeconds(.collapsed, .expanded, .{}), 0.36, 0.001) or
        !near(Motion.transitionSeconds(.expanded, .collapsed, .{}), 0.24, 0.001)) return false;

    const states = [_]Motion.IslandState{ .collapsed, .hover, .expanded, .music_strip, .full_bar, .notice_strip };
    const progress_values = [_]f32{ 0, 0.25, 0.5, 0.75, 1 };
    for (states) |from| {
        for (states) |to| {
            for (progress_values) |progress| {
                if (!near(Motion.curveFor(from, to)(progress), Motion.easeOutCubic(progress), 0.0001)) return false;
            }
        }
    }

    const midpoint = Motion.lerpBox(collapsed, expanded, 0.5);
    const low = Motion.lerpBox(collapsed, expanded, -5);
    const high = Motion.lerpBox(collapsed, expanded, 5);
    if (!near(Geometry.width(midpoint.rect), 370, 0.1) or
        !Motion.sameBox(low, collapsed) or !Motion.sameBox(high, expanded)) return false;
    if (!motion.setTarget(.expanded) or !motion.tick(0.18) or
        Geometry.width(motion.current().rect) <= Geometry.width(collapsed.rect)) return false;
    _ = motion.tick(0.18);
    if (motion.isAnimating() or !Motion.sameBox(motion.current(), expanded)) return false;
    if (!motion.setTarget(.collapsed)) return false;
    _ = motion.tick(0.24);
    return !motion.isAnimating() and Motion.sameBox(motion.current(), collapsed);
}

fn near(a: f32, b: f32, tolerance: f32) bool {
    return @abs(a - b) <= tolerance;
}

fn pointerPolicyCheck() bool {
    const Case = struct { context: StatePolicy.PointerContext, expected: Motion.IslandState };
    const cases = [_]Case{
        .{ .context = .{ .shape = .collapsed, .resting = .collapsed, .pointer_inside = true, .pointer_on_island = true }, .expected = .hover },
        .{ .context = .{ .shape = .music_strip, .resting = .music_strip, .pointer_inside = true, .music_present = true, .pointer_on_island = true }, .expected = .expanded },
        .{ .context = .{ .shape = .hover, .resting = .music_strip, .pointer_inside = true, .music_present = true, .pointer_on_island = true }, .expected = .expanded },
        .{ .context = .{ .shape = .hover, .resting = .music_strip }, .expected = .music_strip },
        .{ .context = .{ .shape = .hover, .resting = .collapsed }, .expected = .collapsed },
        .{ .context = .{ .shape = .expanded, .resting = .music_strip }, .expected = .music_strip },
        .{ .context = .{ .shape = .collapsed, .resting = .collapsed, .notification_active = true }, .expected = .notice_strip },
        .{ .context = .{ .shape = .hover, .resting = .music_strip, .pointer_inside = true, .notification_active = true, .music_present = true, .pointer_on_island = true }, .expected = .notice_strip },
        .{ .context = .{ .shape = .collapsed, .resting = .music_strip }, .expected = .music_strip },
        .{ .context = .{ .shape = .music_strip, .resting = .collapsed }, .expected = .collapsed },
        .{ .context = .{ .shape = .music_strip, .resting = .music_strip }, .expected = .music_strip },
        .{ .context = .{ .shape = .expanded, .resting = .collapsed, .pointer_inside = true, .pointer_on_island = true }, .expected = .hover },
        .{ .context = .{ .shape = .expanded, .resting = .music_strip, .pointer_inside = true, .music_present = true, .pointer_on_island = true }, .expected = .expanded },
        .{ .context = .{ .shape = .expanded, .resting = .collapsed, .pointer_inside = true, .system_panel_open = true }, .expected = .expanded },
        .{ .context = .{ .shape = .expanded, .resting = .collapsed, .pointer_inside = true, .system_panel_open = true, .notification_active = true }, .expected = .expanded },
        .{ .context = .{ .shape = .music_strip, .resting = .music_strip, .pointer_inside = true, .music_present = true, .icon_count = 8, .hovered_icon = 3, .pointer_on_deck = true }, .expected = .music_strip },
    };
    for (cases, 0..) |case, index| {
        const actual = StatePolicy.nextShape(case.context);
        if (actual != case.expected) {
            probeLog("pointer policy case {d}: expected {s}, got {s}", .{
                index,
                Motion.stateName(case.expected),
                Motion.stateName(actual),
            });
            return false;
        }
    }
    return true;
}

fn collectModuleChecks() [14]Check {
    return .{
        .{ .name = "pill geometry", .passed = geometryCheck() },
        .{ .name = "motion transition", .passed = motionCheck() },
        .{ .name = "pointer state policy", .passed = pointerPolicyCheck() },
        .{ .name = "card layout", .passed = CardLayout.smokeCheck() },
        .{ .name = "lyrics parser and timeline", .passed = Lyrics.smokeCheck() },
        .{ .name = "LRC worker", .passed = LyricsService.workerSmokeCheck() },
        .{ .name = "image codec", .passed = WicImage.smokeCheck() },
        .{ .name = "accent colour", .passed = Theme.smokeCheck() },
        .{ .name = "JSON and notification parsing", .passed = MiniJson.smokeCheck() and Notification.smokeCheck() },
        .{ .name = "monitor metrics", .passed = Monitor.smokeCheck() },
        .{ .name = "media timeline policy", .passed = MediaService.smokeCheck() },
        .{ .name = "window and click-through", .passed = IslandWindow.smokeCheck() },
        .{ .name = "composition renderer", .passed = Renderer.smokeCheck() },
        .{ .name = "clock text layout", .passed = TextRenderer.smokeCheck() },
    };
}

/// Copies the complete self-test matrix into caller-owned storage and returns
/// the number of checks copied. A short output slice receives a safe prefix.
pub fn runChecks(out: []Check) usize {
    const checks = collectModuleChecks();
    const count = @min(out.len, checks.len);
    @memcpy(out[0..count], checks[0..count]);
    return count;
}

/// Retained for callers that need only the platform-independent policy checks.
pub fn runPureChecks(out: []Check) usize {
    if (out.len == 0) return 0;
    out[0] = .{ .name = "pill geometry", .passed = geometryCheck() };
    if (out.len == 1) return 1;
    out[1] = .{ .name = "motion transition", .passed = motionCheck() };
    if (out.len == 2) return 2;
    out[2] = .{ .name = "pointer state policy", .passed = pointerPolicyCheck() };
    return 3;
}

pub fn smokeCheck() bool {
    const checks = collectModuleChecks();
    for (checks) |check| if (!check.passed) return false;
    return true;
}

fn probeLog(comptime format: []const u8, args: anytype) void {
    var buffer: [768]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, format, args) catch return;
    Log.logAndPrintAscii(line);
}

fn integrityLabel(pid: DWORD, output: []u8) []const u8 {
    const process = OpenProcess(process_query_limited_information, FALSE, pid) orelse return "unavailable";
    defer _ = CloseHandle(process);
    var token: HANDLE = null;
    if (OpenProcessToken(process, token_query, &token) == FALSE) return "token denied";
    defer _ = CloseHandle(token);
    var buffer: [256]u8 align(8) = @splat(0);
    var returned: DWORD = 0;
    if (GetTokenInformation(token, token_integrity_level, &buffer, buffer.len, &returned) == FALSE) return "?";
    const mandatory: *const TokenMandatoryLabel = @ptrCast(@alignCast(&buffer));
    const sid = mandatory.label.sid orelse return "?";
    const count_ptr = GetSidSubAuthorityCount(sid) orelse return "?";
    if (count_ptr.* == 0) return "?";
    const rid_ptr = GetSidSubAuthority(sid, @as(DWORD, count_ptr.*) - 1) orelse return "?";
    const rid = rid_ptr.*;
    const name = if (rid < 0x1000) "untrusted" else if (rid < 0x2000) "low" else if (rid < 0x2100) "medium" else if (rid < 0x3000) "medium-plus" else if (rid < 0x4000) "high" else "system";
    return std.fmt.bufPrint(output, "{s} (0x{X})", .{ name, rid }) catch "?";
}

/// Reissues the current AppBar state and confirms the shell reports the same
/// flags afterward. This exercises the restore route without changing the
/// user's setting.
pub fn taskbarStateRoundTripCheck() bool {
    var current = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = 0 };
    const original = SHAppBarMessage(abm_getstate, &current);
    var restore = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = @bitCast(original) };
    _ = SHAppBarMessage(abm_setstate, &restore);
    Sleep(100);
    var confirmed = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = 0 };
    return SHAppBarMessage(abm_getstate, &confirmed) == original;
}

/// Runs the reversible native-taskbar access probe. Like the C++ tool, it
/// always attempts to restore the taskbar rectangle and visibility before exit.
pub fn runTaskbarProbe() i32 {
    probeLog("IslandBar native-taskbar probe", .{});
    probeLog("-----------------------------------------------", .{});
    const tray_class: [*:0]const u16 = &.{ 'S', 'h', 'e', 'l', 'l', '_', 'T', 'r', 'a', 'y', 'W', 'n', 'd', 0 };
    const tray = FindWindowW(tray_class, null) orelse {
        probeLog("  Shell_TrayWnd not found -- nothing to hide on this desktop", .{});
        return 0;
    };

    var before = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    _ = GetWindowRect(tray, &before);
    probeLog("  Shell_TrayWnd {X} visible={d} rect={d},{d} {d}x{d}", .{ @intFromPtr(tray), @intFromBool(IsWindowVisible(tray) != FALSE), before.left, before.top, before.right - before.left, before.bottom - before.top });
    var tray_pid: DWORD = 0;
    _ = GetWindowThreadProcessId(tray, &tray_pid);
    probeLog("  owned by pid {d}", .{tray_pid});
    const probe = OpenProcess(process_query_limited_information, FALSE, tray_pid);
    if (probe) |process| _ = CloseHandle(process);
    probeLog("  OpenProcess(QUERY_LIMITED) -> {s} (err {d})", .{ if (probe != null) "allowed" else "DENIED", if (probe != null) 0 else GetLastError() });

    var ours_buffer: [64]u8 = undefined;
    var theirs_buffer: [64]u8 = undefined;
    const ours = integrityLabel(GetCurrentProcessId(), &ours_buffer);
    const theirs = integrityLabel(tray_pid, &theirs_buffer);
    probeLog("  integrity: island_bar = {s}, taskbar = {s}", .{ ours, theirs });

    const show_result = ShowWindow(tray, sw_hide);
    Sleep(150);
    const hidden_by_show = IsWindowVisible(tray) == FALSE;
    probeLog("  [{s}] ShowWindow(SW_HIDE) returned={d} visible={d}", .{ if (hidden_by_show) " OK " else "FAIL", @intFromBool(show_result != FALSE), @intFromBool(IsWindowVisible(tray) != FALSE) });
    var any_worked = hidden_by_show;

    if (!hidden_by_show) {
        const pos_result = SetWindowPos(tray, null, 0, 0, 0, 0, swp_hidewindow | swp_nomove | swp_nosize | swp_nozorder | swp_noactivate);
        Sleep(150);
        const hidden_by_pos = IsWindowVisible(tray) == FALSE;
        probeLog("  [{s}] SetWindowPos(SWP_HIDEWINDOW) returned={d} visible={d}", .{ if (hidden_by_pos) " OK " else "FAIL", @intFromBool(pos_result != FALSE), @intFromBool(IsWindowVisible(tray) != FALSE) });
        any_worked = any_worked or hidden_by_pos;
    }

    if (!any_worked) {
        var moved = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
        const move_result = SetWindowPos(tray, null, before.left, -400, before.right - before.left, before.bottom - before.top, swp_nozorder | swp_noactivate);
        Sleep(200);
        _ = GetWindowRect(tray, &moved);
        const off_screen = moved.bottom <= 0;
        probeLog("  [{s}] SetWindowPos(off-screen) returned={d} rect top={d}", .{ if (off_screen) " OK " else "FAIL", @intFromBool(move_result != FALSE), moved.top });
        _ = SetWindowPos(tray, null, before.left, before.top, before.right - before.left, before.bottom - before.top, swp_nozorder | swp_noactivate);
        Sleep(150);

        const old_style = GetWindowLongPtrW(tray, gwl_exstyle);
        const style_result = SetWindowLongPtrW(tray, gwl_exstyle, old_style | ws_ex_layered);
        const alpha_result = SetLayeredWindowAttributes(tray, 0, 0, lwa_alpha);
        Sleep(200);
        const screen_dc = GetDC(null);
        var pixel = clr_invalid;
        if (screen_dc) |dc| {
            pixel = GetPixel(dc, before.left + 4, before.top + 4);
            _ = ReleaseDC(null, dc);
        }
        const transparent = alpha_result != FALSE;
        probeLog("  [{s}] SetLayeredWindowAttributes(alpha 0) layered={d} alpha={d} pixel=0x{X}", .{ if (transparent) " OK " else "FAIL", @intFromBool(style_result != 0), @intFromBool(alpha_result != FALSE), pixel });
        _ = SetWindowLongPtrW(tray, gwl_exstyle, old_style);
        _ = SetWindowPos(tray, null, 0, 0, 0, 0, swp_nomove | swp_nosize | swp_nozorder | swp_noactivate | swp_framechanged);
        any_worked = any_worked or transparent;
    }

    var current = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = 0 };
    const state_before = SHAppBarMessage(abm_getstate, &current);
    var set_state = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = abs_autohide | abs_alwaysontop };
    const set_result = SHAppBarMessage(abm_setstate, &set_state);
    Sleep(400);
    var after = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = 0 };
    const state_after = SHAppBarMessage(abm_getstate, &after);
    const autohide_applied = (@as(u32, @truncate(state_after)) & @as(u32, @intCast(abs_autohide))) != 0;
    probeLog("  ABM_GETSTATE before=0x{X} after=0x{X} ABM_SETSTATE returned={d}", .{ state_before, state_after, set_result });
    probeLog("  [{s}] ABM_SETSTATE(ABS_AUTOHIDE) applied", .{if (autohide_applied) " OK " else "FAIL"});

    // ABM_SETSTATE changes a user-wide shell preference. Restore exactly the
    // state captured above before this diagnostic exits; leaving auto-hide on
    // after a probe would silently change the user's taskbar behavior.
    var restore_state = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = @bitCast(state_before) };
    const restore_result = SHAppBarMessage(abm_setstate, &restore_state);
    Sleep(400);
    var confirmed_state = AppBarData{ .size = @sizeOf(AppBarData), .window = null, .callback_message = 0, .edge = 0, .rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 }, .data = 0 };
    const state_restored = SHAppBarMessage(abm_getstate, &confirmed_state) == state_before;
    probeLog("  [{s}] ABM_SETSTATE restored original state 0x{X} (returned={d})", .{ if (state_restored) " OK " else "FAIL", state_before, restore_result });

    _ = ShowWindow(tray, sw_show);
    _ = SetWindowPos(tray, null, before.left, before.top, before.right - before.left, before.bottom - before.top, swp_showwindow | swp_nozorder | swp_noactivate);
    Sleep(200);
    var restored = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    _ = GetWindowRect(tray, &restored);
    const back = IsWindowVisible(tray) != FALSE;
    probeLog("  [{s}] restored: visible={d} rect={d},{d} {d}x{d}", .{ if (back) " OK " else "FAIL", @intFromBool(back), restored.left, restored.top, restored.right - restored.left, restored.bottom - restored.top });
    probeLog("-----------------------------------------------", .{});
    if (!back) {
        probeLog("RESULT: FAIL - the taskbar could not be restored", .{});
        return 2;
    }
    if (!state_restored) {
        probeLog("RESULT: FAIL - the taskbar's original auto-hide state could not be restored", .{});
        return 3;
    }
    if (!any_worked) {
        probeLog("RESULT: FAIL - this process cannot hide the taskbar", .{});
        probeLog("  The shell may be at a higher integrity level; run this outside any sandbox.", .{});
        return 1;
    }
    probeLog("RESULT: PASS - this process can hide the taskbar", .{});
    return 0;
}
