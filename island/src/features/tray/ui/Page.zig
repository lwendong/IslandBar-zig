const std = @import("std");
const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const TextRenderer = @import("TextRenderer");
const Theme = @import("Theme");
const TrayCatalog = @import("TrayCatalog");
const TrayController = @import("TrayController");

pub const max_icons = 24;
pub const columns_default: i32 = 5;
pub const cell_size_default: f32 = 48;
pub const cell_gap: f32 = 6;
pub const max_columns: i32 = 8;
pub const min_cell_size: f32 = 38;
pub const max_cell_size: f32 = 68;
pub const menu_width: f32 = 176;
pub const menu_row_height: f32 = 30;
pub const menu_padding: f32 = 6;

pub const Layout = struct {
    title: Geometry.RectF = .{},
    cells: [max_icons]Geometry.RectF = @splat(.{}),
    count: i32 = 0,
    columns: i32 = 0,
};

pub const MenuLayout = struct {
    box: Geometry.RectF = .{},
    rows: [TrayController.max_menu_entries]Geometry.RectF = @splat(.{}),
    count: i32 = 0,
};

pub const View = struct {
    layout: Layout = .{},
    menu: MenuLayout = .{},
    snapshot: LayoutSnapshot.Snapshot = .{},
    revision: u64 = 0,
};

pub const CardText = struct {
    view: View = .{},
    title: []const u16 = &.{},
    icons: []const TrayCatalog.Icon = &.{},
    hovered_icon: i32 = -1,
    menu_actions: []const TrayController.MenuAction = &.{},
    hovered_menu_row: i32 = -1,
    quit_armed: bool = false,
};

pub const Action = union(enum) {
    icon: usize,
    menu_row: usize,
    back,
    outside,
};

pub const Hover = struct { icon: i32 = -1, menu_row: i32 = -1 };

fn intFloat(value: i32) f32 {
    return @floatFromInt(value);
}

pub fn layoutFor(card: Geometry.RoundedBox, icon_count_arg: i32) Layout {
    var layout = Layout{};
    const icon_count = @max(0, @min(icon_count_arg, @as(i32, @intCast(max_icons))));
    layout.count = icon_count;
    layout.title = .{ .left = card.rect.left + 16, .right = card.rect.right - 16, .top = card.rect.top + 6, .bottom = card.rect.top + 32 };
    if (icon_count == 0) return layout;

    const width = Geometry.width(card.rect);
    const available_width = width - 32;
    const available_height = Geometry.height(card.rect) - 52;
    var columns: i32 = @min(columns_default, icon_count);
    var cell = cell_size_default;
    if (icon_count > 1) {
        var best_columns: i32 = 0;
        var best_cell: f32 = 0;
        var candidate = columns_default;
        while (candidate <= max_columns) : (candidate += 1) {
            const rows = @divTrunc(icon_count + candidate - 1, candidate);
            const by_width = (available_width - intFloat(candidate - 1) * cell_gap) / intFloat(candidate);
            const by_height = (available_height - intFloat(rows - 1) * cell_gap) / intFloat(rows);
            const candidate_cell = @min(cell_size_default, @min(by_width, by_height));
            if (candidate_cell >= cell_size_default - 0.01) {
                best_columns = candidate;
                best_cell = cell_size_default;
                break;
            }
            if (best_columns == 0 and candidate_cell >= min_cell_size - 0.01) {
                best_columns = candidate;
                best_cell = candidate_cell;
            }
            if (candidate == max_columns and best_columns == 0) {
                best_columns = candidate;
                best_cell = candidate_cell;
            }
        }
        if (best_columns > 0) {
            columns = @min(best_columns, icon_count);
            cell = best_cell;
        }
    }
    cell = @max(1, cell);
    layout.columns = columns;
    const rows = @divTrunc(icon_count + columns - 1, columns);
    const by_width = (available_width - intFloat(columns - 1) * cell_gap) / intFloat(columns);
    const by_height = (available_height - intFloat(rows - 1) * cell_gap) / intFloat(rows);
    cell = @max(cell, @min(max_cell_size, @min(by_width, by_height)));
    const grid_width = intFloat(columns) * cell + intFloat(columns - 1) * cell_gap;
    const grid_height = intFloat(rows) * cell + intFloat(rows - 1) * cell_gap;
    const left = card.rect.left + (width - grid_width) * 0.5;
    const top = card.rect.top + 42 + (available_height - grid_height) * 0.5;
    for (0..@intCast(icon_count)) |index| {
        const row_index: i32 = @intCast(index);
        const x = left + intFloat(@rem(row_index, columns)) * (cell + cell_gap);
        const y = top + intFloat(@divTrunc(row_index, columns)) * (cell + cell_gap);
        layout.cells[index] = .{ .left = x, .right = x + cell, .top = y, .bottom = y + cell };
    }
    return layout;
}

pub fn menuFor(card: Geometry.RoundedBox, x: f32, y: f32, entry_count_arg: i32) MenuLayout {
    var layout = MenuLayout{};
    const count = @max(0, @min(entry_count_arg, @as(i32, @intCast(TrayController.max_menu_entries))));
    layout.count = count;
    if (count == 0) return layout;
    const height = intFloat(count) * menu_row_height + menu_padding * 2;
    var left = x + 6;
    var top = y + 6;
    if (left + menu_width > card.rect.right - 4) left = x - 6 - menu_width;
    if (top + height > card.rect.bottom - 4) top = y - 6 - height;
    left = @max(card.rect.left + 4, @min(left, card.rect.right - 4 - menu_width));
    top = @max(card.rect.top + 4, @min(top, card.rect.bottom - 4 - height));
    layout.box = .{ .left = left, .right = left + menu_width, .top = top, .bottom = top + height };
    for (0..@intCast(count)) |index| {
        const row_top = top + menu_padding + @as(f32, @floatFromInt(index)) * menu_row_height;
        layout.rows[index] = .{ .left = left + menu_padding, .right = left + menu_width - menu_padding, .top = row_top, .bottom = row_top + menu_row_height };
    }
    return layout;
}

pub fn buildView(card: Geometry.RoundedBox, icon_count: usize, revision: u64, menu: MenuLayout) View {
    const layout = layoutFor(card, @intCast(@min(icon_count, max_icons)));
    var snapshot = LayoutSnapshot.Snapshot{
        .generation = revision,
        .data_generation = revision,
        .valid = true,
        .surface_clip = card.rect,
        .content_clip = card.rect,
    };
    for (layout.cells[0..@intCast(layout.count)], 0..) |bounds, index| {
        _ = snapshot.append(.{ .id = .button, .index = @intCast(index), .bounds = bounds, .hit_region = bounds, .visible = true, .enabled = true });
    }
    const back = Geometry.RectF{ .left = card.rect.left, .right = card.rect.left + 48, .top = card.rect.top, .bottom = card.rect.top + 34 };
    _ = snapshot.append(.{ .id = .button, .index = -1, .bounds = back, .hit_region = back, .z_order = 4, .visible = true, .enabled = true, .content_clipped = false });
    for (menu.rows[0..@intCast(menu.count)], 0..) |bounds, index| {
        _ = snapshot.append(.{ .id = .row, .index = @intCast(index), .bounds = bounds, .hit_region = bounds, .z_order = 8, .visible = true, .enabled = true, .content_clipped = false });
    }
    return .{ .layout = layout, .menu = menu, .snapshot = snapshot, .revision = revision };
}

pub fn actionAt(view: *const View, x: f32, y: f32) ?Action {
    const hit = view.snapshot.hitTestLocalDip(x, y) orelse return null;
    return switch (hit.id) {
        .button => if (hit.index < 0) .back else .{ .icon = @intCast(hit.index) },
        .row => .{ .menu_row = @intCast(hit.index) },
        else => null,
    };
}

pub fn hoverAt(view: *const View, x: f32, y: f32) Hover {
    const hit = view.snapshot.hitTestLocalDip(x, y) orelse return .{};
    return switch (hit.id) {
        .button => .{ .icon = if (hit.index >= 0) hit.index else -1 },
        .row => .{ .icon = -1, .menu_row = hit.index },
        else => .{},
    };
}

fn menuLabel(action: TrayController.MenuAction, armed: bool) []const u16 {
    return switch (action) {
        .open => &.{ 0x6253, 0x5f00 },
        .activate_window => &.{ 0x663e, 0x793a, 0x7a97, 0x53e3 },
        .open_location => &.{ 0x6253, 0x5f00, 0x6587, 0x4ef6, 0x4f4d, 0x7f6e },
        .close_window => &.{ 0x5173, 0x95ed, 0x7a97, 0x53e3 },
        .quit_application => if (armed) &.{ 0x518d, 0x70b9, 0x4e00, 0x6b21, 0xff1a, 0x7ed3, 0x675f, 0x5e94, 0x7528 } else &.{ 0x7ed3, 0x675f, 0x5e94, 0x7528 },
        .application_menu => &.{ 0x5e94, 0x7528, 0x81ea, 0x5df1, 0x7684, 0x83dc, 0x5355, 0x2026 },
    };
}

pub fn paint(context_arg: ?*anyopaque, backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: *const Geometry.RoundedBox, reveal: f32, snapshot: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    _ = snapshot;
    const context = context_arg orelse return false;
    const d2d = draw_context orelse return false;
    const text: *const CardText = @ptrCast(@alignCast(context));
    const opacity = std.math.clamp(reveal, 0, 1);
    if (opacity <= 0.01) return true;
    backend.drawCardSurface(d2d, box.*, opacity);
    _ = backend.drawLabel(d2d, .page_title, text.title, text.view.layout.title, Theme.themeInk(0.88 * opacity));
    for (text.view.layout.cells[0..@intCast(text.view.layout.count)], 0..) |cell, index| {
        const rounded = Theme.Color{ .r = 0, .g = 0, .b = 0, .a = 0.28 * opacity };
        backend.fillRoundedRect(d2d, cell, 10, 10, rounded);
        backend.strokeRoundedRect(d2d, cell, 10, 10, Theme.themeInk(0.13 * opacity), 1);
        if (text.hovered_icon == @as(i32, @intCast(index))) backend.fillRoundedRect(d2d, cell, 10, 10, Theme.themeInk(0.16 * opacity));
        if (index >= text.icons.len) continue;
        const icon = text.icons[index];
        const side = std.math.clamp((cell.right - cell.left) * 0.5, 22, 34);
        const cx = (cell.left + cell.right) * 0.5;
        const cy = (cell.top + cell.bottom) * 0.5;
        const icon_rect = Geometry.RectF{ .left = cx - side * 0.5, .right = cx + side * 0.5, .top = cy - side * 0.5, .bottom = cy + side * 0.5 };
        _ = backend.drawPngIcon(d2d, 34 + index, icon.png, text.view.revision, icon_rect, opacity);
    }
    if (text.view.menu.count > 0) {
        const menu = text.view.menu;
        backend.fillRoundedRect(d2d, menu.box, 10, 10, .{ .r = 0.13, .g = 0.13, .b = 0.16, .a = 0.99 * opacity });
        backend.strokeRoundedRect(d2d, menu.box, 10, 10, .{ .r = 1, .g = 1, .b = 1, .a = 0.12 * opacity }, 1);
        for (menu.rows[0..@intCast(menu.count)], 0..) |row, index| {
            if (text.hovered_menu_row == @as(i32, @intCast(index))) backend.fillRoundedRect(d2d, row, 6, 6, .{ .r = 1, .g = 1, .b = 1, .a = 0.16 * opacity });
            if (index < text.menu_actions.len) _ = backend.drawLabel(d2d, .page_body, menuLabel(text.menu_actions[index], text.quit_armed and text.menu_actions[index] == .quit_application), .{ .left = row.left + 8, .top = row.top, .right = row.right - 8, .bottom = row.bottom }, .{ .r = 0.90, .g = 0.91, .b = 0.95, .a = 0.94 * opacity });
        }
    }
    return true;
}

test "tray view uses the same clipped snapshot for icon and menu hit actions" {
    const card = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 420, .bottom = 240 }, .radius_x = 16, .radius_y = 16 };
    const menu = menuFor(card, 350, 180, 2);
    const view = buildView(card, 6, 17, menu);
    try std.testing.expectEqual(@as(u64, 17), view.snapshot.data_generation);
    try std.testing.expectEqual(@as(usize, 0), switch (actionAt(&view, view.layout.cells[0].left + 2, view.layout.cells[0].top + 2).?) {
        .icon => |index| index,
        else => 99,
    });
    try std.testing.expect(actionAt(&view, view.layout.cells[0].right + 2, view.layout.cells[0].top + 2) == null);
    try std.testing.expectEqual(@as(usize, 0), switch (actionAt(&view, menu.rows[0].left + 1, menu.rows[0].top + 1).?) {
        .menu_row => |index| index,
        else => 99,
    });
    try std.testing.expectEqual(Action.back, actionAt(&view, card.rect.left + 20, card.rect.top + 10).?);
}
