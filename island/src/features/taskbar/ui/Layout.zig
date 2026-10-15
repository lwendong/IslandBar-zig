const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");
const BarLayout = @import("BarControlLayout");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;
pub const max_task_icons: usize = 20;
pub const task_icon_button_dip: f32 = 30;
pub const task_icon_size_dip: f32 = 20;
pub const task_icon_gap_dip: f32 = 4;
pub const task_icon_pad_dip: f32 = 8;
pub const task_title_min_width_dip: f32 = 44;
pub const task_wide_button_dip: f32 = 132;
pub const row_right_margin_dip: f32 = 8;
pub const task_icon_appear_seconds: f32 = 0.22;
pub const row_spring_omega: f32 = 32;
pub const spring_zeta: f32 = 0.8;

pub const TaskIconRow = struct { left: f32 = 0, top: f32 = 0, bottom: f32 = 0, valid: bool = false };

pub fn rowButtonAt(row_left: f32, centre_y: f32, widths: []const f32, index: usize) RectF {
    if (index >= widths.len) return .{};
    var x = row_left;
    for (widths[0..index]) |width| x += width + task_icon_gap_dip;
    return .{ .left = x, .top = centre_y - task_icon_button_dip * 0.5, .right = x + widths[index], .bottom = centre_y + task_icon_button_dip * 0.5 };
}

pub fn taskIconsThatFitInWidth(available_width_dip: f32) usize {
    const slot = task_icon_button_dip + task_icon_gap_dip;
    const open_extra = task_wide_button_dip - task_icon_button_dip;
    const room = available_width_dip - open_extra + task_icon_gap_dip;
    if (room <= 0) return 0;
    return @min(max_task_icons, @as(usize, @intFromFloat(room / slot)));
}

pub fn taskIconsThatFitForMonitor(monitor_width_dip: f32, wanted: usize) usize {
    if (wanted == 0) return 0;
    const island_right = monitor_width_dip * 0.5 + Motion.collapsed_width_dip * 0.5;
    const available = monitor_width_dip - island_right - task_icon_pad_dip - row_right_margin_dip;
    if (available <= 0) return 0;
    return @min(wanted, @max(1, taskIconsThatFitInWidth(available)));
}

pub fn rowRightEdgeDip(row_left: f32, widths: []const f32) f32 {
    var right = row_left;
    for (widths, 0..) |width, index| {
        right += width;
        if (index + 1 < widths.len) right += task_icon_gap_dip;
    }
    return right;
}

pub fn rowWidths(task_count: usize, output: []f32) usize {
    const count = @min(task_count, output.len);
    @memset(output[0..count], task_icon_button_dip);
    return count;
}

pub fn rowAnchorWithTray(island: RoundedBox, tray_button_shown: bool) RoundedBox {
    if (!tray_button_shown) return island;
    var result = island;
    result.rect.right += BarLayout.trayButtonReservedDip();
    return result;
}

pub fn taskRowFor(island: RoundedBox, count: usize, _: f32, _: f32) TaskIconRow {
    if (count == 0) return .{};
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    const top = centre_y - task_icon_button_dip * 0.5;
    return .{ .left = island.rect.right + task_icon_pad_dip, .top = top, .bottom = top + task_icon_button_dip, .valid = true };
}

pub fn taskIconButtonAtAmounts(island: RoundedBox, index: usize, count: usize, amounts: []const f32, _: f32, _: f32) RectF {
    if (index >= count or index >= max_task_icons or count == 0 or amounts.len < count) return .{};
    const row = taskRowFor(island, count, 0, 0);
    if (!row.valid) return .{};
    var left = row.left;
    for (0..index) |i| left += buttonWidth(amounts[i]) + task_icon_gap_dip;
    return .{ .left = left, .top = row.top, .right = left + buttonWidth(amounts[index]), .bottom = row.bottom };
}

pub fn taskIconButtonAt(island: RoundedBox, index: usize, count: usize, hovered_index: i32, hovered_amount: f32, card_left_dip: f32, card_width_dip: f32) RectF {
    if (count == 0 or count > max_task_icons or index >= count) return .{};
    var amounts: [max_task_icons]f32 = @splat(0);
    if (hovered_index >= 0 and hovered_index < count) amounts[@intCast(hovered_index)] = std.math.clamp(hovered_amount, 0, 1);
    return taskIconButtonAtAmounts(island, index, count, &amounts, card_left_dip, card_width_dip);
}

pub fn taskIconInBox(button: RectF) RectF {
    if (button.right <= button.left) return .{};
    const centre_y = (button.top + button.bottom) * 0.5;
    const left = button.left + (task_icon_button_dip - task_icon_size_dip) * 0.5;
    const top = centre_y - task_icon_size_dip * 0.5;
    return .{ .left = left, .top = top, .right = left + task_icon_size_dip, .bottom = top + task_icon_size_dip };
}

pub fn taskTitleAtAmounts(island: RoundedBox, index: usize, count: usize, amounts: []const f32, hovered_index: i32, card_left_dip: f32, card_width_dip: f32) RectF {
    if (hovered_index < 0 or index != hovered_index) return .{};
    const button = taskIconButtonAtAmounts(island, index, count, amounts, card_left_dip, card_width_dip);
    if (button.right <= button.left) return .{};
    const icon = taskIconInBox(button);
    return .{ .left = icon.right + 8, .top = button.top, .right = button.right - task_icon_pad_dip, .bottom = button.bottom };
}

pub fn taskRowWidthDip(count: usize, hovered_index: i32) f32 {
    if (count == 0) return 0;
    const shown = @min(count, max_task_icons);
    var total: f32 = 0;
    for (0..shown) |i| {
        total += if (hovered_index >= 0 and i == hovered_index) task_wide_button_dip else task_icon_button_dip;
        if (i + 1 < shown) total += task_icon_gap_dip;
    }
    return total;
}

pub fn taskIconHit(island: RoundedBox, count: usize, hovered_index: i32, hovered_amount: f32, x: f32, y: f32) i32 {
    const shown = @min(count, max_task_icons);
    for (0..shown) |i| if (containsRect(taskIconButtonAt(island, i, shown, hovered_index, hovered_amount, 0, 0), x, y)) return @intCast(i);
    return -1;
}

pub fn taskIconUnderPointer(island: RoundedBox, count: usize, x: f32, y: f32) i32 {
    return taskIconHit(island, count, -1, 0, x, y);
}

pub fn taskRowContains(island: RoundedBox, count: usize, x: f32, y: f32, card_left_dip: f32, card_width_dip: f32) bool {
    if (count == 0 or count > max_task_icons) return false;
    const row = taskRowFor(island, count, card_left_dip, card_width_dip);
    if (!row.valid or y < row.top or y > row.bottom) return false;
    const last = count - 1;
    const resting = taskIconButtonAt(island, last, count, -1, 0, 0, 0).right;
    const wide = taskIconButtonAt(island, last, count, @intCast(last), 1, 0, 0).right;
    return x >= row.left and x <= @max(resting, wide);
}

pub fn taskIconToKeepOpen(island: RoundedBox, count: usize, current: i32, x: f32, y: f32) i32 {
    if (count == 0) return -1;
    const arrived = taskIconUnderPointer(island, count, x, y);
    if (arrived >= 0) return arrived;
    if (current >= 0 and taskRowContains(island, count, x, y, 0, 0)) return current;
    return -1;
}

pub fn taskIconAppearStep(amount_arg: f32, arriving: bool, dt_seconds: f32) f32 {
    const dt = std.math.clamp(dt_seconds, 0, 0.1);
    const target: f32 = if (arriving) 1 else 0;
    const step = dt / task_icon_appear_seconds;
    if (amount_arg < target) return @min(target, amount_arg + step);
    if (amount_arg > target) return @max(target, amount_arg - step);
    return amount_arg;
}

pub fn rowOpenStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32) bool {
    const damping = 2 * spring_zeta * row_spring_omega;
    const substep: f32 = 1.0 / 240.0;
    var remaining = std.math.clamp(dt_seconds, 0, 0.1);
    while (remaining > 0) {
        const h = @min(remaining, substep);
        const displacement = value.* - target;
        const acceleration = -row_spring_omega * row_spring_omega * displacement - damping * velocity.*;
        velocity.* += acceleration * h;
        value.* += velocity.* * h;
        remaining -= h;
    }
    const moving = @abs(value.* - target) > 0.001 or @abs(velocity.*) > 0.002;
    if (!moving) {
        value.* = target;
        velocity.* = 0;
    }
    return moving;
}

fn buttonWidth(amount_arg: f32) f32 {
    const amount = std.math.clamp(amount_arg, 0, 1);
    return task_icon_button_dip + (task_wide_button_dip - task_icon_button_dip) * amount;
}

fn containsRect(rect: RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

test "taskbar layout preserves animated row geometry and hit gaps" {
    const island = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 1920, 0));
    const row = rowAnchorWithTray(island, true);
    var amounts = [_]f32{ 0, 0, 0 };
    const first = taskIconButtonAtAmounts(row, 0, amounts.len, &amounts, 0, 0);
    const second = taskIconButtonAtAmounts(row, 1, amounts.len, &amounts, 0, 0);
    try std.testing.expectApproxEqAbs(first.right + task_icon_gap_dip, second.left, 0.001);
    try std.testing.expectEqual(@as(i32, 0), taskIconUnderPointer(row, amounts.len, first.left + 1, first.top + 1));
    try std.testing.expectEqual(@as(i32, -1), taskIconUnderPointer(row, amounts.len, first.right + 1, first.top + 1));
    amounts[0] = 1;
    const wide = taskIconButtonAtAmounts(row, 0, amounts.len, &amounts, 0, 0);
    try std.testing.expectApproxEqAbs(task_wide_button_dip, wide.right - wide.left, 0.001);
    try std.testing.expectEqual(@as(usize, 20), taskIconsThatFitForMonitor(3840, 20));
}
