const std = @import("std");
const Geometry = @import("Geometry");
const Controller = @import("SystemController");
const StatusContract = @import("SystemStatusContract");
const Layout = @import("SystemLayout");
const Presentation = @import("SystemPanelPresentation");
const TextRenderer = @import("TextRenderer");
const Theme = @import("Theme");

const wifi: [*:0]const u16 = &.{ 'W', 'i', '-', 'F', 'i', 0 };
const bluetooth: [*:0]const u16 = &.{ 'B', 'l', 'u', 'e', 't', 'o', 'o', 't', 'h', 0 };
const airplane: [*:0]const u16 = &.{ 0x98de, 0x884c, 0x6a21, 0x5f0f, 0 };
const accessibility: [*:0]const u16 = &.{ 0x8f85, 0x52a9, 0x529f, 0x80fd, 0 };
const battery_saver: [*:0]const u16 = &.{ 0x8282, 0x80fd, 0x6a21, 0x5f0f, 0 };
const captions: [*:0]const u16 = &.{ 0x5b9e, 0x65f6, 0x5b57, 0x5e55, 0 };
const night_light: [*:0]const u16 = &.{ 0x591c, 0x95f4, 0x6a21, 0x5f0f, 0 };
const hotspot: [*:0]const u16 = &.{ 0x79fb, 0x52a8, 0x70ed, 0x70b9, 0 };
const nearby: [*:0]const u16 = &.{ 0x5c31, 0x8fd1, 0x5171, 0x4eab, 0 };
const wired_display: [*:0]const u16 = &.{ 0x6709, 0x7ebf, 0x663e, 0x793a, 0x5668, 0 };
const projection: [*:0]const u16 = &.{ 0x6295, 0x5f71, 0 };
const appearance: [*:0]const u16 = &.{ 0x5916, 0x89c2, 0 };
const battery: [*:0]const u16 = &.{ 'B', 'a', 't', 't', 'e', 'r', 'y', 0 };
const available: [*:0]const u16 = &.{ 0x53ef, 0x7528, 0 };
const not_connected: [*:0]const u16 = &.{ 0x672a, 0x8fde, 0x63a5, 0 };
const off: [*:0]const u16 = &.{ 0x5173, 0 };
const tray_page: [*:0]const u16 = &.{ 0x6258, 0x76D8, 0 };
const start_page: [*:0]const u16 = &.{ 0x5F00, 0x59CB, 0 };
const on: [*:0]const u16 = &.{ 0x5f00, 0 };
const disabled: [*:0]const u16 = &.{ 0x5df2, 0x5173, 0x95ed, 0 };

pub const View = struct {
    presentation: Presentation.View = .{},
    actions: [6]Controller.Action = @splat(.none),
    action_count: usize = 0,
    input_language_label: [8]u16 = @splat(0),
    battery_label: [8]u16 = @splat(0),
    theme_name: [33]u16 = @splat(0),
};

const FeatureTile = struct { render: Presentation.Tile = .{}, action: Controller.Action = .none };

fn add(tiles: *[Layout.max_system_panel_tiles]FeatureTile, count: *usize, label: ?[*:0]const u16, state: ?[*:0]const u16, glyph: TextRenderer.IndicatorIcon, value: i32, is_on: bool, chevron: bool, action: Controller.Action) void {
    if (count.* >= tiles.len) return;
    tiles[count.*] = .{ .render = .{ .label = label, .state_text = state, .icon = @backingInt(glyph), .icon_value = value, .on = is_on, .chevron = chevron }, .action = action };
    count.* += 1;
}

pub fn build(view: *View, state: *Controller.State, box: Geometry.RoundedBox, volume: f32, muted: bool) void {
    var all: [Layout.max_system_panel_tiles]FeatureTile = @splat(.{});
    var count: usize = 0;
    const status = &state.status;
    const network_state = if (!status.wifi_radio_on) disabled else switch (status.network) {
        .none => disabled,
        .disconnected => not_connected,
        .connected => available,
    };
    add(&all, &count, wifi, network_state, .network, @backingInt(status.signal), status.wifi_radio_on, false, .toggle_wifi);
    add(&all, &count, bluetooth, if (status.bluetooth_on) not_connected else off, .bluetooth, @intFromBool(status.bluetooth_on), status.bluetooth_on, false, .toggle_bluetooth);
    add(&all, &count, airplane, null, .airplane, 0, !status.wifi_radio_on and !status.bluetooth_on, false, .toggle_radio);
    add(&all, &count, accessibility, null, .accessibility, 0, false, true, .{ .open_settings = .accessibility });
    add(&all, &count, battery_saver, if (status.battery_saver_on) on else off, .battery_saver, 0, status.battery_saver_on, false, .{ .open_settings = .battery });
    add(&all, &count, captions, if (status.live_captions_on) on else off, .captions, 0, status.live_captions_on, false, .toggle_live_captions);
    add(&all, &count, night_light, if (status.night_light_on) on else off, .moon, 0, status.night_light_on, false, .toggle_night_light);
    add(&all, &count, hotspot, null, .hotspot, 0, false, false, .{ .open_settings = .hotspot });
    add(&all, &count, nearby, null, .share, 0, false, false, .{ .open_settings = .nearby });
    add(&all, &count, wired_display, null, .wired_display, 0, false, true, .{ .open_settings = .display });
    add(&all, &count, projection, null, .projection, 0, false, true, .projection_modes);
    if (shouldDrawInputMethod(status, state.installed_layout_count)) {
        inputMethodLabel(status.input_language_id, &view.input_language_label);
        add(&all, &count, @ptrCast(&view.input_language_label), null, .input_method, 0, true, false, .{ .open_settings = .typing });
    }
    @memset(&view.theme_name, 0);
    const current_name = &Theme.currentTheme().name;
    const current_name_len = std.mem.indexOfScalar(u16, current_name, 0) orelse current_name.len;
    const name_len = @min(current_name_len, view.theme_name.len - 1);
    @memcpy(view.theme_name[0..name_len], current_name[0..name_len]);
    add(&all, &count, appearance, @ptrCast(&view.theme_name), .settings, 0, false, false, .cycle_theme);
    if (shouldDrawBattery(status)) {
        var ascii: [8]u8 = undefined;
        const value = std.fmt.bufPrint(&ascii, "{d}%", .{status.battery_percent}) catch &.{};
        @memset(&view.battery_label, 0);
        for (value, 0..) |byte, index| view.battery_label[index] = byte;
        add(&all, &count, battery, @ptrCast(&view.battery_label), .battery, status.battery_percent, status.on_ac_power or status.battery_percent > 20, false, .{ .open_settings = .battery });
    }
    add(&all, &count, tray_page, null, .share, 0, false, false, .open_tray_page);
    add(&all, &count, start_page, null, .settings, 0, false, false, .open_start_page);

    const per_page: usize = @intCast(Layout.max_system_tiles);
    const page_count: i32 = @intCast(@max(1, (count + per_page - 1) / per_page));
    state.panel_page = @mod(state.panel_page, page_count);
    const page = state.panel_page;
    const first = @as(usize, @intCast(page)) * per_page;
    const copied = @min(per_page, count - first);
    view.presentation = .{
        .page_index = page,
        .page_count = page_count,
        .tile_count = copied,
        .volume = std.math.clamp(volume, 0, 1),
        .muted = muted,
        .has_brightness = state.brightness_available,
        .brightness = @as(f32, @floatFromInt(state.brightness_percent)) / 100,
    };
    view.action_count = copied;
    for (0..copied) |index| {
        view.presentation.tiles[index] = all[first + index].render;
        view.actions[index] = all[first + index].action;
    }
    view.presentation.layout = Layout.systemPanelFor(box, @intCast(copied), if (state.brightness_available) 2 else 1, page_count > 1, page, page_count);
}

pub fn updateLayout(view: *View, box: Geometry.RoundedBox) void {
    view.presentation.layout = Layout.systemPanelFor(box, @intCast(view.presentation.tile_count), if (view.presentation.has_brightness) 2 else 1, view.presentation.page_count > 1, view.presentation.page_index, view.presentation.page_count);
}

pub fn hitFor(view: *const View, x: f32, y: f32) Layout.Hit {
    return Layout.hitFor(view.presentation.layout, x, y);
}

pub fn actionAt(view: *const View, tile_index: i32) ?Controller.Action {
    if (tile_index < 0 or tile_index >= view.action_count) return null;
    return view.actions[@intCast(tile_index)];
}

pub fn settingsUri(page: Controller.SettingsPage) [*:0]const u16 {
    return switch (page) {
        .accessibility => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'e', 'a', 's', 'e', 'o', 'f', 'a', 'c', 'c', 'e', 's', 's', 0 },
        .battery => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'b', 'a', 't', 't', 'e', 'r', 'y', 's', 'a', 'v', 'e', 'r', 0 },
        .hotspot => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 't', 'w', 'o', 'r', 'k', '-', 'm', 'o', 'b', 'i', 'l', 'e', 'h', 'o', 't', 's', 'p', 'o', 't', 0 },
        .nearby => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'e', 'a', 'r', 'b', 'y', '-', 's', 'h', 'a', 'r', 'i', 'n', 'g', 0 },
        .display => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'd', 'i', 's', 'p', 'l', 'a', 'y', 0 },
        .typing => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 't', 'y', 'p', 'i', 'n', 'g', 0 },
        .general => &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 0 },
    };
}

pub fn shouldDrawInputMethod(status: *const StatusContract.Snapshot, installed_layout_count: i32) bool {
    return status.input_language_id != 0 and installed_layout_count > 1;
}

pub fn shouldDrawBattery(status: *const StatusContract.Snapshot) bool {
    return status.battery_present and status.battery_percent >= 0 and status.battery_percent <= 100;
}

pub fn inputMethodLabel(language_id: u16, output: []u16) void {
    if (output.len < 2) return;
    @memset(output, 0);
    const primary = language_id & 0x03ff;
    const label: ?[]const u16 = switch (primary) {
        0x04 => &.{0x4E2D},
        0x11 => &.{0x3042},
        0x12 => &.{0xD55C},
        0x09 => &.{ 'E', 'N' },
        0x07 => &.{ 'D', 'E' },
        0x0c => &.{ 'F', 'R' },
        0x0a => &.{ 'E', 'S' },
        0x10 => &.{ 'I', 'T' },
        0x16 => &.{ 'P', 'T' },
        0x19 => &.{ 'R', 'U' },
        else => null,
    };
    if (label) |value| {
        const copied = @min(value.len, output.len - 1);
        @memcpy(output[0..copied], value[0..copied]);
    } else {
        const digits = "0123456789ABCDEF";
        const byte: u8 = @truncate(language_id);
        output[0] = digits[byte >> 4];
        output[1] = digits[byte & 0x0f];
    }
}

test "System page preserves visible tile order and status labels" {
    var state = Controller.State{ .status = .{ .wifi_radio_on = false, .battery_present = true, .battery_percent = 74, .input_language_id = 0x0804 }, .installed_layout_count = 2 };
    var view = View{};
    const box = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    build(&view, &state, box, 0.4, true);
    try std.testing.expectEqual(@as(usize, 6), view.presentation.tile_count);
    try std.testing.expectEqual(@as(i32, 3), view.presentation.page_count);
    try std.testing.expect(view.presentation.tiles[0].label.?[0] == 'W');
    try std.testing.expectEqual(Controller.Action.toggle_wifi, view.actions[0]);
    state.panel_page = 2;
    build(&view, &state, box, 0.4, true);
    try std.testing.expectEqual(@as(i32, 2), view.presentation.page_index);
    try std.testing.expectEqual(Controller.Action.open_tray_page, view.actions[2]);
    try std.testing.expectEqual(Controller.Action.open_start_page, view.actions[3]);
}

test "brightness capability absent removes only its slider" {
    var state = Controller.State{};
    var view = View{};
    const box = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    build(&view, &state, box, 0.5, false);
    try std.testing.expect(!view.presentation.has_brightness);
    try std.testing.expectEqual(@as(i32, 1), view.presentation.layout.slider_count);
}

test "system capability rows and keyboard labels stay local to the page" {
    var state = Controller.State{ .status = .{ .input_language_id = 0x0804 }, .installed_layout_count = 1 };
    var view = View{};
    const box = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    build(&view, &state, box, 0, false);
    try std.testing.expect(!shouldDrawInputMethod(&state.status, state.installed_layout_count));
    state.installed_layout_count = 2;
    build(&view, &state, box, 0, false);
    try std.testing.expect(shouldDrawInputMethod(&state.status, state.installed_layout_count));
    try std.testing.expectEqual(@as(u16, 0x4E2D), view.input_language_label[0]);
    try std.testing.expectEqual(@as(u16, 0), view.input_language_label[1]);
    try std.testing.expect(!shouldDrawBattery(&state.status));
    state.status.battery_present = true;
    state.status.battery_percent = 100;
    try std.testing.expect(shouldDrawBattery(&state.status));
    state.status.battery_percent = 101;
    try std.testing.expect(!shouldDrawBattery(&state.status));
}
