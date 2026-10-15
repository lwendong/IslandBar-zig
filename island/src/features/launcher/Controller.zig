const std = @import("std");
const LauncherCatalog = @import("LauncherCatalog");

pub const Page = enum { pins, apps, power };
pub const max_pins: usize = 18;

pub const State = struct {
    page: Page = .pins,
    picker_scroll_row: i32 = 0,
    selected_index: i32 = -1,
    power_confirm_row: i32 = -1,
    launch_generation: u64 = 0,
    pending_launch_generation: ?u64 = null,
    last_launch_frame_generation: ?u64 = null,
    last_launch: ?LauncherCatalog.LaunchResult = null,
};

pub const Action = union(enum) {
    open_apps,
    toggle_power,
    close,
    scroll_picker: struct { wheel: i32, max_row: i32 },
    launch_pinned: struct { index: usize, frame_generation: u64 },
    pin_app: usize,
    power_row: i32,
};

pub const Effect = union(enum) {
    refresh_index,
    launch_app: struct { app: LauncherCatalog.App, generation: u64 },
    pin_app: LauncherCatalog.App,
    run_power_action: i32,
};

/// Applies Launcher intent and returns the one platform effect, if any.
/// The index and confirmation state are owned here; Windows calls stay in App.
pub fn reduce(state: *State, action: Action, pins: []const LauncherCatalog.App, apps: []const LauncherCatalog.App) ?Effect {
    switch (action) {
        .open_apps => {
            state.page = .apps;
            state.picker_scroll_row = 0;
            state.power_confirm_row = -1;
            return .refresh_index;
        },
        .toggle_power => {
            state.page = if (state.page == .power) .pins else .power;
            state.power_confirm_row = -1;
            return null;
        },
        .close => {
            state.page = .pins;
            state.power_confirm_row = -1;
            return null;
        },
        .scroll_picker => |scroll| {
            if (state.page != .apps) return null;
            state.picker_scroll_row = std.math.clamp(state.picker_scroll_row - scroll.wheel, 0, @max(0, scroll.max_row));
            return null;
        },
        .launch_pinned => |request| {
            if (state.page != .pins or state.pending_launch_generation != null or request.index >= pins.len) return null;
            if (state.last_launch_frame_generation == request.frame_generation) return null;
            state.last_launch_frame_generation = request.frame_generation;
            return beginLaunch(state, pins[request.index]);
        },
        .pin_app => |index| {
            if (state.page != .apps or index >= apps.len) return null;
            state.selected_index = @intCast(index);
            return .{ .pin_app = apps[index] };
        },
        .power_row => |index| {
            if (state.page != .power or index < 0 or index >= 5) return null;
            if (index >= 2 and state.power_confirm_row != index) {
                state.power_confirm_row = index;
                return null;
            }
            state.power_confirm_row = -1;
            return .{ .run_power_action = index };
        },
    }
}

fn beginLaunch(state: *State, app: LauncherCatalog.App) Effect {
    state.launch_generation +%= 1;
    state.pending_launch_generation = state.launch_generation;
    state.selected_index = -1;
    state.last_launch = null;
    return .{ .launch_app = .{ .app = app, .generation = state.launch_generation } };
}

/// A duplicate or stale completion cannot release a newer launch request.
pub fn completeLaunch(state: *State, generation: u64, result: LauncherCatalog.LaunchResult) bool {
    if (state.pending_launch_generation == null or state.pending_launch_generation.? != generation) return false;
    state.pending_launch_generation = null;
    state.last_launch = result;
    return true;
}

test "Launcher controller owns page selection, scroll, confirmation, and launch result" {
    var state = State{};
    var first = LauncherCatalog.App{};
    first.name[0] = 'A';
    first.target[0] = 'a';
    var second = LauncherCatalog.App{};
    second.name[0] = 'B';
    second.target[0] = 'b';
    var pins = [_]LauncherCatalog.App{first};
    var apps = [_]LauncherCatalog.App{ first, second };
    const open_effect = reduce(&state, .open_apps, &pins, &apps).?;
    try std.testing.expect(std.meta.activeTag(open_effect) == .refresh_index);
    _ = reduce(&state, .{ .scroll_picker = .{ .wheel = -4, .max_row = 2 } }, &pins, &apps);
    try std.testing.expectEqual(@as(i32, 2), state.picker_scroll_row);
    const pin_effect = reduce(&state, .{ .pin_app = 1 }, &pins, &apps).?;
    try std.testing.expectEqual(@as(i32, 1), state.selected_index);
    try std.testing.expectEqual(@as(u16, 'B'), pin_effect.pin_app.name[0]);

    _ = reduce(&state, .close, &pins, &apps);
    const launch = reduce(&state, .{ .launch_pinned = .{ .index = 0, .frame_generation = 7 } }, &pins, &apps).?;
    const generation = launch.launch_app.generation;
    try std.testing.expect(reduce(&state, .{ .launch_pinned = .{ .index = 0, .frame_generation = 7 } }, &pins, &apps) == null);
    try std.testing.expect(!completeLaunch(&state, generation -% 1, .{ .succeeded = true }));
    try std.testing.expect(completeLaunch(&state, generation, .{ .succeeded = false, .shell_code = 5 }));
    try std.testing.expectEqual(@as(i32, 5), state.last_launch.?.shell_code);
    try std.testing.expect(reduce(&state, .{ .launch_pinned = .{ .index = 0, .frame_generation = 8 } }, &pins, &apps) != null);
}

test "irreversible power rows require the existing second confirmation" {
    var state = State{ .page = .power };
    const apps: []const LauncherCatalog.App = &.{};
    try std.testing.expect(reduce(&state, .{ .power_row = 3 }, apps, apps) == null);
    try std.testing.expectEqual(@as(i32, 3), state.power_confirm_row);
    try std.testing.expectEqual(@as(i32, 3), reduce(&state, .{ .power_row = 3 }, apps, apps).?.run_power_action);
    try std.testing.expectEqual(@as(i32, -1), state.power_confirm_row);
}
