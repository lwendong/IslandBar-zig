const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");
const BarLayout = @import("BarControlLayout");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;
pub const max_task_icons: usize = 20;
pub const max_visible_task_icons: usize = 5;
pub const task_icon_button_dip: f32 = 38;
pub const task_icon_size_dip: f32 = 26;
pub const task_icon_hover_width_dip: f32 = 148;
pub const task_icon_hover_progress_max: f32 = 1;
pub const task_icon_gap_dip: f32 = 8;
pub const task_icon_pad_dip: f32 = 12;
pub const tray_icon_button_dip: f32 = 24;
pub const tray_icon_size_dip: f32 = 16;
pub const tray_icon_gap_dip: f32 = 3;
pub const task_tray_gap_dip: f32 = 10;
pub const max_visible_tray_icons: usize = 24;
pub const dock_gap_dip: f32 = BarLayout.dock_gap_dip;
pub const row_right_margin_dip: f32 = 20;
pub const overflow_panel_width_dip: f32 = 272;
pub const overflow_panel_padding_dip: f32 = 12;
pub const overflow_header_height_dip: f32 = 30;
pub const overflow_entry_height_dip: f32 = 34;
pub const overflow_grid_top_gap_dip: f32 = 10;
pub const overflow_tile_width_dip: f32 = 50;
pub const overflow_tile_height_dip: f32 = 62;
pub const overflow_tile_gap_x_dip: f32 = 6;
pub const overflow_tile_gap_y_dip: f32 = 4;
pub const overflow_grid_columns: usize = 4;

pub fn monitorWidthFor(island: RoundedBox) f32 {
    return @max(0, island.rect.left + island.rect.right);
}

pub const OverflowLayout = struct {
    panel: RoundedBox = .{ .rect = .{} },
    system_entry: RectF = .{},
    tray_entry: RectF = .{},
    grid_top: f32 = 0,
    tile_width: f32 = overflow_tile_width_dip,
};

pub fn overflowButtonFor(island: RoundedBox, row_right: f32) RectF {
    return BarLayout.buttonAt(row_right + dock_gap_dip, island);
}

pub fn overflowLayoutFor(island: RoundedBox, arrow: RectF, monitor_width_dip: f32, hidden_count: usize) OverflowLayout {
    const panel_width = @min(overflow_panel_width_dip, @max(180, monitor_width_dip - row_right_margin_dip * 2));
    const left = @max(row_right_margin_dip, arrow.right - panel_width);
    const top = island.rect.bottom + 10;
    const pad = overflow_panel_padding_dip;
    const entry_top = top + pad + overflow_header_height_dip + 6;
    const entry_width = (panel_width - pad * 2 - 8) * 0.5;
    const grid_top = entry_top + overflow_entry_height_dip + overflow_grid_top_gap_dip;
    const rows = if (hidden_count == 0) 0 else (hidden_count + overflow_grid_columns - 1) / overflow_grid_columns;
    const grid_height = if (rows == 0) @as(f32, 0) else @as(f32, @floatFromInt(rows)) * overflow_tile_height_dip + @as(f32, @floatFromInt(rows - 1)) * overflow_tile_gap_y_dip;
    const bottom = grid_top + grid_height + pad;
    const tile_width = @min(overflow_tile_width_dip, (panel_width - pad * 2 - @as(f32, @floatFromInt(overflow_grid_columns - 1)) * overflow_tile_gap_x_dip) / @as(f32, @floatFromInt(overflow_grid_columns)));
    return .{
        .panel = .{
            .rect = .{ .left = left, .top = top, .right = left + panel_width, .bottom = bottom },
            .radius_x = 18,
            .radius_y = 18,
        },
        .system_entry = .{ .left = left + pad, .top = entry_top, .right = left + pad + entry_width, .bottom = entry_top + overflow_entry_height_dip },
        .tray_entry = .{ .left = left + pad + entry_width + 8, .top = entry_top, .right = left + panel_width - pad, .bottom = entry_top + overflow_entry_height_dip },
        .grid_top = grid_top,
        .tile_width = tile_width,
    };
}

pub fn overflowTaskButtonAt(layout: OverflowLayout, index: usize) RectF {
    if (layout.panel.rect.right <= layout.panel.rect.left) return .{};
    const row = index / overflow_grid_columns;
    const column = index % overflow_grid_columns;
    const x = layout.panel.rect.left + overflow_panel_padding_dip + @as(f32, @floatFromInt(column)) * (layout.tile_width + overflow_tile_gap_x_dip);
    const y = layout.grid_top + @as(f32, @floatFromInt(row)) * (overflow_tile_height_dip + overflow_tile_gap_y_dip);
    return .{ .left = x, .top = y, .right = x + layout.tile_width, .bottom = y + overflow_tile_height_dip };
}

pub fn overflowTaskIconInBox(button: RectF) RectF {
    const side = @min(32, @min(button.right - button.left, button.bottom - button.top - 24));
    const left = (button.left + button.right - side) * 0.5;
    return .{ .left = left, .top = button.top + 4, .right = left + side, .bottom = button.top + 4 + side };
}

pub fn overflowTaskTitleAt(button: RectF) RectF {
    return .{ .left = button.left + 1, .top = button.top + 37, .right = button.right - 1, .bottom = button.bottom - 2 };
}

pub fn taskIconsThatFitForMonitor(monitor_width_dip: f32, wanted: usize) usize {
    if (wanted == 0) return 0;
    const available = taskIconAvailableWidthForMonitor(monitor_width_dip);
    if (available < task_icon_button_dip) return 0;
    const slot = task_icon_button_dip + task_icon_gap_dip;
    const fit_count: usize = @intFromFloat((available + task_icon_gap_dip) / slot);
    return @min(@min(wanted, max_visible_task_icons), fit_count);
}

pub fn trayIconsThatFitForMonitor(monitor_width_dip: f32, visible_task_count: usize, wanted: usize) usize {
    if (wanted == 0) return 0;
    const task_width = @as(f32, @floatFromInt(visible_task_count)) * task_icon_button_dip +
        @as(f32, @floatFromInt(if (visible_task_count > 0) visible_task_count - 1 else 0)) * task_icon_gap_dip;
    const available = @max(0, taskIconAvailableWidthForMonitor(monitor_width_dip) - task_width -
        (if (visible_task_count > 0) task_tray_gap_dip else 0));
    if (available < tray_icon_button_dip) return 0;
    const slot = tray_icon_button_dip + tray_icon_gap_dip;
    const fit_count: usize = @intFromFloat((available + tray_icon_gap_dip) / slot);
    return @min(@min(wanted, max_visible_tray_icons), fit_count);
}

pub fn taskIconHoverWidthForMonitor(monitor_width_dip: f32, count: usize, progress_arg: f32) f32 {
    if (count == 0) return task_icon_button_dip;
    const base_width = @as(f32, @floatFromInt(count)) * task_icon_button_dip +
        @as(f32, @floatFromInt(count - 1)) * task_icon_gap_dip;
    const available_extra = @max(0, taskIconAvailableWidthForMonitor(monitor_width_dip) - base_width);
    const wanted_extra = task_icon_hover_width_dip - task_icon_button_dip;
    return task_icon_button_dip + @min(wanted_extra * std.math.clamp(progress_arg, 0, task_icon_hover_progress_max), available_extra);
}

pub fn taskIconAvailableWidthForMonitor(monitor_width_dip: f32) f32 {
    const island_right = monitor_width_dip * 0.5 + Motion.collapsed_width_dip * 0.5;
    const row_left = island_right + task_icon_pad_dip;
    const row_right = monitor_width_dip - row_right_margin_dip - BarLayout.start_button_dip - dock_gap_dip;
    return row_right - row_left;
}

pub fn taskIconButtonAt(island: RoundedBox, index: usize, count: usize) RectF {
    if (count == 0 or count > max_task_icons or index >= count) return .{};
    const left = island.rect.right + task_icon_pad_dip + @as(f32, @floatFromInt(index)) * (task_icon_button_dip + task_icon_gap_dip);
    return taskIconButtonAtWidth(island, left, task_icon_button_dip);
}

pub fn taskIconButtonAtWidth(island: RoundedBox, left: f32, width: f32) RectF {
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    return .{
        .left = left,
        .top = centre_y - task_icon_button_dip * 0.5,
        .right = left + @max(task_icon_button_dip, width),
        .bottom = centre_y + task_icon_button_dip * 0.5,
    };
}

pub fn taskIconInBox(button: RectF) RectF {
    if (button.right <= button.left) return .{};
    const centre_y = (button.top + button.bottom) * 0.5;
    const left = button.left + (task_icon_button_dip - task_icon_size_dip) * 0.5;
    const top = centre_y - task_icon_size_dip * 0.5;
    return .{ .left = left, .top = top, .right = left + task_icon_size_dip, .bottom = top + task_icon_size_dip };
}

pub fn taskIconTitleInBox(button: RectF) RectF {
    const icon_left = button.left + (task_icon_button_dip - task_icon_size_dip) * 0.5;
    const left = icon_left + task_icon_size_dip + 8;
    return .{ .left = left, .top = button.top, .right = button.right - 8, .bottom = button.bottom };
}

pub fn trayIconButtonAt(island: RoundedBox, left: f32) RectF {
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    return .{
        .left = left,
        .top = centre_y - tray_icon_button_dip * 0.5,
        .right = left + tray_icon_button_dip,
        .bottom = centre_y + tray_icon_button_dip * 0.5,
    };
}

pub fn trayIconInBox(button: RectF) RectF {
    const centre_x = (button.left + button.right) * 0.5;
    const centre_y = (button.top + button.bottom) * 0.5;
    return .{
        .left = centre_x - tray_icon_size_dip * 0.5,
        .top = centre_y - tray_icon_size_dip * 0.5,
        .right = centre_x + tray_icon_size_dip * 0.5,
        .bottom = centre_y + tray_icon_size_dip * 0.5,
    };
}

test "taskbar layout keeps circular buttons at a fixed size with consistent gaps" {
    const island = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 1920, 0));
    const first = taskIconButtonAt(island, 0, 3);
    const second = taskIconButtonAt(island, 1, 3);
    try std.testing.expectApproxEqAbs(first.right + task_icon_gap_dip, second.left, 0.001);
    try std.testing.expectApproxEqAbs(task_icon_button_dip, first.right - first.left, 0.001);
    try std.testing.expectApproxEqAbs(task_icon_button_dip, first.bottom - first.top, 0.001);
    try std.testing.expectApproxEqAbs(first.left + (task_icon_button_dip - task_icon_size_dip) * 0.5, taskIconInBox(first).left, 0.001);
    try std.testing.expectEqual(max_visible_task_icons, taskIconsThatFitForMonitor(3840, 20));
    try std.testing.expectEqual(@as(usize, 2), taskIconsThatFitForMonitor(640, 5));
    try std.testing.expectEqual(@as(usize, 1), taskIconsThatFitForMonitor(560, 5));
}

test "task hover width uses available dock space and preserves the base circle" {
    try std.testing.expectApproxEqAbs(task_icon_button_dip, taskIconHoverWidthForMonitor(1920, 5, 0), 0.001);
    try std.testing.expectApproxEqAbs(task_icon_hover_width_dip, taskIconHoverWidthForMonitor(1920, 5, 1), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 96), taskIconHoverWidthForMonitor(1024, 5, 1), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 48), taskIconHoverWidthForMonitor(560, 1, 1), 0.001);
}
