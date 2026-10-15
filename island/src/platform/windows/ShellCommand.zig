const std = @import("std");

pub const StartMenuResult = enum { sent, input_blocked, no_input, sent_through_legacy, activated_app };
pub const StartMenuRoute = enum { send_input_ctrl_esc, send_input_held, keybd_event_ctrl_esc, keybd_event_win, activate_start_app };
pub fn openUri(uri: [*:0]const u16) bool {
    const opened = ShellExecuteW(null, null, uri, null, null, shownormal);
    return @intFromPtr(opened) > 32;
}

const HWND = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const WORD = u16;
const DWORD = u32;

const MouseInput = extern struct { dx: i32, dy: i32, mouse_data: DWORD, flags: DWORD, time: DWORD, extra: usize };
const KeyboardInput = extern struct { vk: WORD, scan: WORD, flags: DWORD, time: DWORD, extra: usize };
const HardwareInput = extern struct { message: DWORD, param_low: WORD, param_high: WORD };
const InputData = extern union { mouse: MouseInput, keyboard: KeyboardInput, hardware: HardwareInput };
const Input = extern struct { kind: DWORD, data: InputData };

extern "user32" fn GetAsyncKeyState(key: i32) callconv(.winapi) i16;
extern "user32" fn MapVirtualKeyW(code: DWORD, map_type: DWORD) callconv(.winapi) DWORD;
extern "user32" fn SendInput(count: DWORD, input: *const Input, input_size: i32) callconv(.winapi) DWORD;
extern "user32" fn keybd_event(key: u8, scan: u8, flags: DWORD, extra: usize) callconv(.winapi) void;
extern "user32" fn GetForegroundWindow() callconv(.winapi) HWND;
extern "user32" fn GetClassNameW(window: HWND, class_name: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn VkKeyScanW(character: u16) callconv(.winapi) i16;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "shell32" fn ShellExecuteW(window: HWND, operation: ?[*:0]const u16, file: [*:0]const u16, parameters: ?[*:0]const u16, directory: ?[*:0]const u16, show_command: i32) callconv(.winapi) HINSTANCE;
extern "kernel32" fn OutputDebugStringW(text: [*:0]const u16) callconv(.winapi) void;

const vk_control: WORD = 0x11;
const vk_escape: WORD = 0x1b;
const vk_lwin: WORD = 0x5b;
const vk_shift: i32 = 0x10;
const vk_menu: i32 = 0x12;
const vk_lbutton: i32 = 0x01;
const input_keyboard: DWORD = 1;
const keyevent_keyup: DWORD = 0x0002;
const map_vk_to_scan: DWORD = 0;
const shownormal: i32 = 1;
const hold_ms: DWORD = 40;
const key_state_down: i16 = @bitCast(@as(u16, 0x8000));

const start_app: [*:0]const u16 = &.{
    's', 'h', 'e', 'l', 'l', ':', 'A', 'p', 'p', 's', 'F', 'o', 'l', 'd', 'e', 'r', '\\',
    'M', 'i', 'c', 'r', 'o', 's', 'o', 'f', 't', '.', 'W', 'i', 'n', 'd', 'o', 'w', 's',
    '.', 'S', 't', 'a', 'r', 't', 'M', 'e', 'n', 'u', 'E', 'x', 'p', 'e', 'r', 'i', 'e',
    'n', 'c', 'e', 'H', 'o', 's', 't', '_', 'c', 'w', '5', 'n', '1', 'h', '2', 't', 'x',
    'y', 'e', 'w', 'y', '!', 'A', 'p', 'p', 0,
};
const start_host_class: [*:0]const u16 = &.{
    'X', 'a', 'm', 'l', 'E', 'x', 'p', 'l', 'o', 'r', 'e', 'r', 'H', 'o', 's', 't', 'I', 's',
    'l', 'a', 'n', 'd', 'W', 'i', 'n', 'd', 'o', 'w', 0,
};

var route: StartMenuRoute = .send_input_held;

fn debug(text: [*:0]const u16) void {
    OutputDebugStringW(text);
}

fn debugAscii(comptime format: []const u8, args: anytype) void {
    var narrow: [256]u8 = undefined;
    const formatted = std.fmt.bufPrint(&narrow, format, args) catch return;
    var wide: [257]u16 = @splat(0);
    for (formatted, 0..) |byte, index| wide[index] = byte;
    OutputDebugStringW(@ptrCast(&wide));
}

fn sendKeyLegacy(vk: WORD, up: bool) void {
    keybd_event(@intCast(vk), 0, if (up) keyevent_keyup else 0, 0);
}

fn sendKey(vk: WORD, up: bool) bool {
    const input = Input{
        .kind = input_keyboard,
        .data = .{ .keyboard = .{
            .vk = vk,
            .scan = @intCast(MapVirtualKeyW(vk, map_vk_to_scan)),
            .flags = if (up) keyevent_keyup else 0,
            .time = 0,
            .extra = 0,
        } },
    };
    return SendInput(1, &input, @sizeOf(Input)) == 1;
}

pub fn startMenuResultName(result: StartMenuResult) []const u16 {
    return switch (result) {
        .sent => &.{ 's', 'e', 'n', 't' },
        .input_blocked => &.{ 'i', 'n', 'p', 'u', 't', ' ', 'b', 'l', 'o', 'c', 'k', 'e', 'd' },
        .no_input => &.{ 'i', 'n', 'p', 'u', 't', ' ', 'r', 'e', 'f', 'u', 's', 'e', 'd' },
        .sent_through_legacy => &.{ 's', 'e', 'n', 't', ' ', '(', 'k', 'e', 'y', 'b', 'd', '_', 'e', 'v', 'e', 'n', 't', ')' },
        .activated_app => &.{ 'a', 's', 'k', 'e', 'd', ' ', 't', 'h', 'e', ' ', 's', 'h', 'e', 'l', 'l', ' ', 't', 'o', ' ', 'a', 'c', 't', 'i', 'v', 'a', 't', 'e', ' ', 'i', 't' },
    };
}

pub fn startMenuRouteName(value: StartMenuRoute) []const u16 {
    return switch (value) {
        .send_input_ctrl_esc => &.{ 'S', 'e', 'n', 'd', 'I', 'n', 'p', 'u', 't', ' ', 'C', 't', 'r', 'l', '+', 'E', 's', 'c' },
        .send_input_held => &.{ 'S', 'e', 'n', 'd', 'I', 'n', 'p', 'u', 't', ' ', 'C', 't', 'r', 'l', '+', 'E', 's', 'c', ' ', 'h', 'e', 'l', 'd' },
        .keybd_event_ctrl_esc => &.{ 'k', 'e', 'y', 'b', 'd', '_', 'e', 'v', 'e', 'n', 't', ' ', 'C', 't', 'r', 'l', '+', 'E', 's', 'c' },
        .keybd_event_win => &.{ 'k', 'e', 'y', 'b', 'd', '_', 'e', 'v', 'e', 'n', 't', ' ', 'W', 'i', 'n' },
        .activate_start_app => &.{ 'a', 'c', 't', 'i', 'v', 'a', 't', 'e', ' ', 'S', 't', 'a', 'r', 't', 'M', 'e', 'n', 'u', 'E', 'x', 'p', 'e', 'r', 'i', 'e', 'n', 'c', 'e' },
    };
}

pub fn setStartMenuRoute(value: StartMenuRoute) void {
    route = value;
}

pub fn currentStartMenuRoute() StartMenuRoute {
    return route;
}

fn keyIsDown(key: i32) bool {
    return (GetAsyncKeyState(key) & key_state_down) != 0;
}

fn classMatches(window: HWND, expected: [*:0]const u16) bool {
    var class_name: [64]u16 = @splat(0);
    const length = GetClassNameW(window, &class_name, class_name.len);
    if (length <= 0) return false;
    const actual = class_name[0..@intCast(length)];
    var expected_length: usize = 0;
    while (expected[expected_length] != 0) : (expected_length += 1) {}
    return std.mem.eql(u16, actual, expected[0..expected_length]);
}

pub fn toggleStartMenu() StartMenuResult {
    const ctrl_already = keyIsDown(vk_control);
    const shift_already = keyIsDown(vk_shift);
    const alt_already = keyIsDown(vk_menu);
    const win_already = keyIsDown(vk_lwin);
    const lmb_down = keyIsDown(vk_lbutton);
    if (shift_already) _ = sendKey(vk_shift, true);
    if (alt_already) _ = sendKey(vk_menu, true);
    if (win_already) _ = sendKey(vk_lwin, true);
    if (ctrl_already) _ = sendKey(vk_control, true);
    debugAscii("IslandBar start menu modifiers: ctrl={d} shift={d} alt={d} win={d} lmb={d}\n", .{
        @intFromBool(ctrl_already), @intFromBool(shift_already), @intFromBool(alt_already), @intFromBool(win_already), @intFromBool(lmb_down),
    });

    var ctrl_down = false;
    var esc_down = false;
    var esc_up = false;
    var ctrl_up = false;
    switch (route) {
        .send_input_ctrl_esc => {
            ctrl_down = sendKey(vk_control, false);
            esc_down = sendKey(vk_escape, false);
            esc_up = sendKey(vk_escape, true);
            ctrl_up = sendKey(vk_control, true);
        },
        .send_input_held => {
            ctrl_down = sendKey(vk_control, false);
            esc_down = sendKey(vk_escape, false);
            Sleep(hold_ms);
            esc_up = sendKey(vk_escape, true);
            ctrl_up = sendKey(vk_control, true);
        },
        .keybd_event_ctrl_esc => {
            sendKeyLegacy(vk_control, false);
            sendKeyLegacy(vk_escape, false);
            Sleep(hold_ms);
            sendKeyLegacy(vk_escape, true);
            sendKeyLegacy(vk_control, true);
            return .sent_through_legacy;
        },
        .keybd_event_win => {
            sendKeyLegacy(vk_lwin, false);
            Sleep(hold_ms);
            sendKeyLegacy(vk_lwin, true);
            return .sent_through_legacy;
        },
        .activate_start_app => {
            const foreground = GetForegroundWindow();
            if (foreground != null and classMatches(foreground, start_host_class)) {
                sendKeyLegacy(vk_escape, false);
                Sleep(hold_ms);
                sendKeyLegacy(vk_escape, true);
                debug("IslandBar Start menu was foreground; sent Escape\n");
                return .sent_through_legacy;
            }
            const opened = ShellExecuteW(null, null, start_app, null, null, shownormal);
            const code = @intFromPtr(opened);
            debugAscii("IslandBar Start app activation returned {d}\n", .{code});
            return if (code > 32) .activated_app else .input_blocked;
        },
    }

    if (!ctrl_down and !esc_down and !esc_up and !ctrl_up) {
        debugAscii("IslandBar SendInput refused every key; error={d}\n", .{GetLastError()});
        return .input_blocked;
    }
    if (!esc_down or !esc_up) debugAscii("IslandBar Escape send incomplete: down={d} up={d}\n", .{ @intFromBool(esc_down), @intFromBool(esc_up) });
    if (!ctrl_up) _ = sendKey(vk_control, true);
    if (!esc_up) _ = sendKey(vk_escape, true);
    if (!ctrl_down or !ctrl_up or !esc_down or !esc_up) return .no_input;
    debug("IslandBar Ctrl+Esc was sent\n");
    return .sent;
}

fn clearModifiers() void {
    if (keyIsDown(vk_shift)) _ = sendKey(vk_shift, true);
    if (keyIsDown(vk_menu)) _ = sendKey(vk_menu, true);
    if (keyIsDown(vk_control)) _ = sendKey(vk_control, true);
}

pub fn sendWindowsKeyChord(letter: u16) bool {
    if (letter == 0) return false;
    clearModifiers();
    const mapped = VkKeyScanW(letter);
    const key: WORD = @truncate(@as(u16, @bitCast(mapped)));
    if (key == 0 or key == 0xff) return false;
    sendKeyLegacy(vk_lwin, false);
    sendKeyLegacy(key, false);
    Sleep(hold_ms);
    sendKeyLegacy(key, true);
    sendKeyLegacy(vk_lwin, true);
    debugAscii("IslandBar Win+{c} chord sent (keybd_event)\n", .{@as(u8, @intCast(letter))});
    return true;
}

pub fn sendWindowsCtrlKeyChord(letter: u16) bool {
    if (letter == 0) return false;
    clearModifiers();
    const mapped = VkKeyScanW(letter);
    const key: WORD = @truncate(@as(u16, @bitCast(mapped)));
    if (key == 0 or key == 0xff) return false;
    sendKeyLegacy(vk_lwin, false);
    sendKeyLegacy(vk_control, false);
    sendKeyLegacy(key, false);
    Sleep(hold_ms);
    sendKeyLegacy(key, true);
    sendKeyLegacy(vk_control, true);
    sendKeyLegacy(vk_lwin, true);
    debugAscii("IslandBar Win+Ctrl+{c} chord sent (keybd_event)\n", .{@as(u8, @intCast(letter))});
    return true;
}

pub fn smokeCheck() bool {
    if (false) {
        _ = toggleStartMenu();
        _ = sendWindowsKeyChord('P');
        _ = sendWindowsCtrlKeyChord('L');
    }
    return currentStartMenuRoute() == .send_input_held and startMenuResultName(.sent).len == 4 and
        startMenuRouteName(.activate_start_app).len > 10;
}
