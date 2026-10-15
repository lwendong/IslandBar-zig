const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");
const BarLayout = @import("BarControlLayout");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;
pub const max_task_icons: usize = 20;
pub const max_visible_task_icons: usize = max_task_icons;
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
pub const tray_overflow_icon_side_dip: f32 = tray_icon_button_dip;
pub const tray_overflow_icon_gap_dip: f32 = tray_icon_gap_dip;
pub const tray_overflow_panel_padding_dip: f32 = 8;
pub const tray_overflow_grid_columns: usize = 6;

pub fn monitorWidthFor(island: RoundedBox) f32 {
    return @max(0, island.rect.left + island.rect.right);
}

pub const TrayOverflowLayout = struct {
    panel: RoundedBox = .{ .rect = .{} },
    grid_top: f32 = 0,
    columns: usize = 0,
};

pub fn overflowButtonFor(island: RoundedBox, row_right: f32) RectF {
    return smallDockButtonAt(island, row_right + dock_gap_dip);
}

pub fn trayOverflowLayoutFor(island: RoundedBox, arrow: RectF, monitor_width_dip: f32, hidden_count: usize) TrayOverflowLayout {
    if (hidden_count == 0) return .{};
    var columns = @min(hidden_count, tray_overflow_grid_columns);
    const max_panel_width = @max(
        tray_overflow_icon_side_dip + tray_overflow_panel_padding_dip * 2,
        monitor_width_dip - row_right_margin_dip * 2,
    );
    while (columns > 1) : (columns -= 1) {
        const candidate_width = @as(f32, @floatFromInt(columns)) * tray_overflow_icon_side_dip +
            @as(f32, @floatFromInt(columns - 1)) * tray_overflow_icon_gap_dip +
            tray_overflow_panel_padding_dip * 2;
        if (candidate_width <= max_panel_width) break;
    }
    const panel_width = @as(f32, @floatFromInt(columns)) * tray_overflow_icon_side_dip +
        @as(f32, @floatFromInt(columns - 1)) * tray_overflow_icon_gap_dip +
        tray_overflow_panel_padding_dip * 2;
    const max_left = @max(row_right_margin_dip, monitor_width_dip - row_right_margin_dip - panel_width);
    const left = std.math.clamp(arrow.right - panel_width, row_right_margin_dip, max_left);
    const top = island.rect.bottom + 10;
    const rows = (hidden_count + columns - 1) / columns;
    const grid_height = @as(f32, @floatFromInt(rows)) * tray_overflow_icon_side_dip +
        @as(f32, @floatFromInt(rows - 1)) * tray_overflow_icon_gap_dip;
    const bottom = top + tray_overflow_panel_padding_dip * 2 + grid_height;
    const grid_top = top + tray_overflow_panel_padding_dip;
    return .{
        .panel = .{
            .rect = .{ .left = left, .top = top, .right = left + panel_width, .bottom = bottom },
            .radius_x = 14,
            .radius_y = 14,
        },
        .grid_top = grid_top,
        .columns = columns,
    };
}

pub fn trayOverflowCellAt(layout: TrayOverflowLayout, index: usize) RectF {
    if (layout.panel.rect.right <= layout.panel.rect.left) return .{};
    const row = index / layout.columns;
    const column = index % layout.columns;
    const x = layout.panel.rect.left + tray_overflow_panel_padding_dip + @as(f32, @floatFromInt(column)) * (tray_overflow_icon_side_dip + tray_overflow_icon_gap_dip);
    const y = layout.grid_top + @as(f32, @floatFromInt(row)) * (tray_overflow_icon_side_dip + tray_overflow_icon_gap_dip);
    return .{ .left = x, .top = y, .right = x + tray_overflow_icon_side_dip, .bottom = y + tray_overflow_icon_side_dip };
}

pub fn trayOverflowIconInBox(button: RectF) RectF {
    const side = @min(tray_icon_size_dip, @min(button.right - button.left, button.bottom - button.top));
    const left = (button.left + button.right - side) * 0.5;
    const top = (button.top + button.bottom - side) * 0.5;
    return .{ .left = left, .top = top, .right = left + side, .bottom = top + side };
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
    return smallDockButtonAt(island, left);
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

fn smallDockButtonAt(island: RoundedBox, left: f32) RectF {
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    const top = centre_y - tray_icon_button_dip * 0.5;
    return .{
        .left = left,
        .top = top,
        .right = left + tray_icon_button_dip,
        .bottom = top + tray_icon_button_dip,
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
