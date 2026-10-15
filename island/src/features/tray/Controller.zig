const std = @import("std");
const TrayCatalog = @import("TrayCatalog");

pub const max_menu_entries = 6;
pub const MenuAction = enum { open, activate_window, open_location, close_window, quit_application, application_menu };

pub const State = struct {
    page_open: bool = false,
    menu_open: bool = false,
    catalog_revision: u64 = 0,
    selected: ?TrayCatalog.Identity = null,
    hovered_icon: i32 = -1,
    hovered_menu_row: i32 = -1,
    menu_actions: [max_menu_entries]MenuAction = @splat(.open),
    menu_count: usize = 0,
    quit_armed: bool = false,
};

pub const Effect = union(enum) {
    press_icon: TrayCatalog.Identity,
    menu_action: struct { target: TrayCatalog.Identity, action: MenuAction },
};

pub fn catalogChanged(state: *State, revision: u64) bool {
    if (state.catalog_revision == revision) return false;
    state.catalog_revision = revision;
    state.menu_open = false;
    state.selected = null;
    state.menu_count = 0;
    state.hovered_icon = -1;
    state.hovered_menu_row = -1;
    state.quit_armed = false;
    return true;
}

pub fn openPage(state: *State, revision: u64) void {
    _ = catalogChanged(state, revision);
    state.page_open = true;
}

pub fn closePage(state: *State) void {
    state.page_open = false;
    closeMenu(state);
    state.hovered_icon = -1;
}

pub fn closeMenu(state: *State) void {
    state.menu_open = false;
    state.selected = null;
    state.menu_count = 0;
    state.hovered_menu_row = -1;
    state.quit_armed = false;
}

pub fn openMenu(state: *State, target: TrayCatalog.Identity, icon: *const TrayCatalog.Icon, revision: u64, has_window: bool) bool {
    if (!TrayCatalog.identityMatches(target, icon, revision, @as(usize, target.index))) return false;
    _ = catalogChanged(state, revision);
    state.selected = target;
    state.menu_count = appendMenuActions(&state.menu_actions, has_window, icon.exe_path[0] != 0);
    state.menu_open = state.menu_count > 0;
    state.hovered_menu_row = -1;
    state.quit_armed = false;
    return state.menu_open;
}

pub fn pressIcon(state: *State, target: TrayCatalog.Identity, icon: *const TrayCatalog.Icon, revision: u64) ?Effect {
    if (!state.page_open or !TrayCatalog.identityMatches(target, icon, revision, @as(usize, target.index))) return null;
    return .{ .press_icon = target };
}

pub fn activateMenuRow(state: *State, row: usize, icon: *const TrayCatalog.Icon, revision: u64) ?Effect {
    const target = state.selected orelse return null;
    if (!state.page_open or !state.menu_open or row >= state.menu_count or
        !TrayCatalog.identityMatches(target, icon, revision, @as(usize, target.index)))
    {
        closeMenu(state);
        return null;
    }
    const action = state.menu_actions[row];
    if (action == .quit_application and !state.quit_armed) {
        state.quit_armed = true;
        return null;
    }
    state.quit_armed = false;
    return .{ .menu_action = .{ .target = target, .action = action } };
}

fn appendMenuActions(out: []MenuAction, has_window: bool, has_path: bool) usize {
    if (out.len == 0) return 0;
    var count: usize = 0;
    out[count] = .open;
    count += 1;
    if (has_window and count < out.len) {
        out[count] = .activate_window;
        count += 1;
    }
    if (has_path and count < out.len) {
        out[count] = .open_location;
        count += 1;
    }
    if (has_window and count < out.len) {
        out[count] = .close_window;
        count += 1;
    }
    if (count < out.len) {
        out[count] = .quit_application;
        count += 1;
    }
    if (count < out.len) {
        out[count] = .application_menu;
        count += 1;
    }
    return count;
}

test "tray menu identities expire when catalog changes" {
    const icon = TrayCatalog.Icon{ .uid = 4, .has_uid = true, .exe_path = [_]u16{'x'} ++ @as([511]u16, @splat(0)) };
    var state = State{};
    openPage(&state, 10);
    const identity = TrayCatalog.identityFor(&icon, 10, 0);
    try std.testing.expect(openMenu(&state, identity, &icon, 10, true));
    try std.testing.expect(catalogChanged(&state, 11));
    try std.testing.expect(!state.menu_open and state.selected == null and !state.quit_armed);
    try std.testing.expect(pressIcon(&state, identity, &icon, 11) == null);
}

test "tray quit requires the existing two-click confirmation" {
    const icon = TrayCatalog.Icon{ .uid = 4, .has_uid = true, .exe_path = [_]u16{'x'} ++ @as([511]u16, @splat(0)) };
    var state = State{};
    openPage(&state, 10);
    const identity = TrayCatalog.identityFor(&icon, 10, 0);
    try std.testing.expect(openMenu(&state, identity, &icon, 10, true));
    const quit_row = state.menu_count - 2;
    try std.testing.expect(activateMenuRow(&state, quit_row, &icon, 10) == null);
    try std.testing.expect(state.quit_armed);
    const effect = activateMenuRow(&state, quit_row, &icon, 10).?;
    try std.testing.expectEqual(MenuAction.quit_application, effect.menu_action.action);
}

test "menu action retains the process and window instance selected when opened" {
    const icon = TrayCatalog.Icon{ .uid = 4, .has_uid = true, .exe_path = [_]u16{'x'} ++ @as([511]u16, @splat(0)) };
    var state = State{};
    openPage(&state, 10);
    var identity = TrayCatalog.identityFor(&icon, 10, 0);
    identity.window_instance = .{ .process_id = 123, .window_handle = 456, .process_created_at = 789 };
    try std.testing.expect(openMenu(&state, identity, &icon, 10, true));
    const effect = activateMenuRow(&state, 1, &icon, 10).?;
    try std.testing.expectEqual(MenuAction.activate_window, effect.menu_action.action);
    try std.testing.expectEqual(identity.window_instance.?, effect.menu_action.target.window_instance.?);
}
