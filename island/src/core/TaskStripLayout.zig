const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;

pub const task_icon_button_dip: f32 = 30;
pub const task_icon_size_dip: f32 = 20;
pub const task_icon_gap_dip: f32 = 4;
pub const task_icon_pad_dip: f32 = 8;
pub const task_title_min_width_dip: f32 = 44;
pub const task_wide_button_dip: f32 = 132;
pub const max_task_icons: usize = 20;
pub const row_right_margin_dip: f32 = 8;
pub const row_left_margin_dip: f32 = 16;
pub const start_button_dip: f32 = task_icon_button_dip;
pub const start_icon_dip: f32 = task_icon_size_dip;
pub const task_icon_appear_seconds: f32 = 0.22;
pub const status_strip_width_dip: f32 = 268;
pub const status_strip_height_dip: f32 = 26;
pub const status_strip_gap_dip: f32 = 10;
pub const status_strip_pad_dip: f32 = 8;
pub const status_strip_fade_seconds: f32 = 0.20;
pub const row_spring_omega: f32 = 32;
pub const control_spring_omega: f32 = 48;
pub const spring_zeta: f32 = 0.8;
pub const tray_icon_dip: f32 = 30;
pub const tray_picture_dip: f32 = 16;
pub const tray_gap_dip: f32 = 2;
pub const tray_right_margin_dip: f32 = 6;
pub const max_tray_icons: usize = 24;

pub const TaskIconRow = struct {
    left: f32 = 0,
    top: f32 = 0,
    bottom: f32 = 0,
    valid: bool = false,
};

pub fn rowButtonAt(row_left: f32, centre_y: f32, widths: []const f32, index: usize) RectF {
    if (index >= widths.len) return .{};
    var x = row_left;
    for (widths[0..index]) |width| x += width + task_icon_gap_dip;
    return .{
        .left = x,
        .top = centre_y - task_icon_button_dip * 0.5,
        .right = x + widths[index],
        .bottom = centre_y + task_icon_button_dip * 0.5,
    };
}

pub fn deckRight(island: RoundedBox) f32 {
    return island.rect.left - task_icon_pad_dip;
}

pub fn deckButtonFor(island: RoundedBox, index: i32) RectF {
    const right = deckRight(island) - @as(f32, @floatFromInt(index)) * (start_button_dip + task_icon_gap_dip);
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    const top = centre_y - start_button_dip * 0.5;
    return .{ .left = right - start_button_dip, .top = top, .right = right, .bottom = top + start_button_dip };
}

pub fn startButtonFor(island: RoundedBox) RectF {
    return deckButtonFor(island, 0);
}

pub fn systemButtonFor(island: RoundedBox) RectF {
    return deckButtonFor(island, 1);
}

pub fn systemButtonHit(island: RoundedBox, x: f32, y: f32) bool {
    return containsRect(systemButtonFor(island), x, y);
}

pub fn startButtonHit(island: RoundedBox, x: f32, y: f32) bool {
    return containsRect(startButtonFor(island), x, y);
}

pub fn rowAvailableWidthDip(monitor_width_dip: f32, row_left: f32) f32 {
    return @max(0, monitor_width_dip - row_right_margin_dip - row_left);
}

pub fn taskIconsThatFitInWidth(available_width_dip: f32) usize {
    const slot = task_icon_button_dip + task_icon_gap_dip;
    const open_extra = task_wide_button_dip - task_icon_button_dip;
    const room = available_width_dip - open_extra + task_icon_gap_dip;
    if (room <= 0) return 0;
    return @min(max_task_icons, @as(usize, @intFromFloat(room / slot)));
}

pub fn taskIconsThatFit(available_width_dip: f32) usize {
    return taskIconsThatFitInWidth(available_width_dip);
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

pub fn islandBoxFor(monitor_width_dip: f32, pill_width_dip: f32, pill_height_dip: f32) RoundedBox {
    const left = monitor_width_dip * 0.5 - pill_width_dip * 0.5;
    const top = Geometry.pill_top_margin_dip;
    const radius = @min(pill_height_dip * 0.5, pill_width_dip * 0.5);
    return .{
        .rect = .{ .left = left, .top = top, .right = left + pill_width_dip, .bottom = top + pill_height_dip },
        .radius_x = radius,
        .radius_y = radius,
    };
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

pub fn taskIconAtInButton(island: RoundedBox, index: usize, count: usize) RectF {
    return taskIconInBox(taskIconButtonAt(island, index, count, -1, 0, 0, 0));
}

pub fn taskTitleAtAmounts(island: RoundedBox, index: usize, count: usize, amounts: []const f32, hovered_index: i32, card_left_dip: f32, card_width_dip: f32) RectF {
    if (hovered_index < 0 or index != hovered_index) return .{};
    const button = taskIconButtonAtAmounts(island, index, count, amounts, card_left_dip, card_width_dip);
    if (button.right <= button.left) return .{};
    const icon = taskIconInBox(button);
    return .{ .left = icon.right + 8, .top = button.top, .right = button.right - task_icon_pad_dip, .bottom = button.bottom };
}

pub fn taskIconAt(island: RoundedBox, index: usize, count: usize, hovered_index: i32, hovered_amount: f32) RectF {
    return taskIconInBox(taskIconButtonAt(island, index, count, hovered_index, hovered_amount, 0, 0));
}

pub fn taskTitleAt(island: RoundedBox, index: usize, count: usize, hovered_index: i32, hovered_amount: f32, card_left_dip: f32, card_width_dip: f32) RectF {
    if (hovered_index < 0 or index != hovered_index) return .{};
    const button = taskIconButtonAt(island, index, count, hovered_index, hovered_amount, card_left_dip, card_width_dip);
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
    const amount = amount_arg;
    const target: f32 = if (arriving) 1 else 0;
    const step = dt / task_icon_appear_seconds;
    if (amount < target) return @min(target, amount + step);
    if (amount > target) return @max(target, amount - step);
    return amount;
}

pub fn statusStripFor(island: RoundedBox) RoundedBox {
    const system = systemButtonFor(island);
    const right = system.left - status_strip_gap_dip;
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    return .{
        .rect = .{ .left = right - status_strip_width_dip, .top = centre_y - status_strip_height_dip * 0.5, .right = right, .bottom = centre_y + status_strip_height_dip * 0.5 },
        .radius_x = status_strip_height_dip * 0.5,
        .radius_y = status_strip_height_dip * 0.5,
    };
}

pub fn statusStripFadeStep(amount: f32, wanted: bool, dt_seconds: f32) f32 {
    return approachStep(amount, wanted, dt_seconds, status_strip_fade_seconds);
}

pub fn springStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32, omega: f32) bool {
    const damping = 2 * spring_zeta * omega;
    const substep: f32 = 1.0 / 240.0;
    var remaining = std.math.clamp(dt_seconds, 0, 0.1);
    while (remaining > 0) {
        const h = @min(remaining, substep);
        const displacement = value.* - target;
        const acceleration = -omega * omega * displacement - damping * velocity.*;
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

pub fn rowOpenStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32) bool {
    return springStep(value, velocity, target, dt_seconds, row_spring_omega);
}

pub fn controlWashStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32) bool {
    return springStep(value, velocity, target, dt_seconds, control_spring_omega);
}

pub fn trayButtonFor(island: RoundedBox) RectF {
    const left = island.rect.right + task_icon_pad_dip;
    const top = (island.rect.top + island.rect.bottom) * 0.5 - tray_icon_dip * 0.5;
    return .{ .left = left, .top = top, .right = left + tray_icon_dip, .bottom = top + tray_icon_dip };
}

pub fn trayButtonHit(island: RoundedBox, x: f32, y: f32) bool {
    return containsRect(trayButtonFor(island), x, y);
}

pub fn trayButtonReservedDip() f32 {
    return tray_icon_dip + task_icon_gap_dip * 2;
}

pub fn barClusterFor(island: RoundedBox, tray_button_shown: bool) RoundedBox {
    const left = systemButtonFor(island).left - task_icon_gap_dip;
    const right = (if (tray_button_shown) trayButtonFor(island).right else island.rect.right) + task_icon_gap_dip;
    const radius = (island.rect.bottom - island.rect.top) * 0.5;
    return .{
        .rect = .{ .left = left, .top = island.rect.top, .right = right, .bottom = island.rect.bottom },
        .radius_x = radius,
        .radius_y = radius,
    };
}

pub fn rowAnchorWithTray(island: RoundedBox, tray_button_shown: bool) RoundedBox {
    if (!tray_button_shown) return island;
    var result = island;
    result.rect.right += trayButtonReservedDip();
    return result;
}

pub const CardHang = enum { system_button, start_button, tray_button };

pub fn deckCardAnchorCentre(island: RoundedBox, hang: CardHang) f32 {
    const button = switch (hang) {
        .system_button => systemButtonFor(island),
        .start_button => startButtonFor(island),
        .tray_button => trayButtonFor(island),
    };
    return (button.left + button.right) * 0.5;
}

fn approachStep(amount: f32, wanted: bool, dt_seconds: f32, duration: f32) f32 {
    const dt = std.math.clamp(dt_seconds, 0, 0.1);
    const step = dt / duration;
    const target: f32 = if (wanted) 1 else 0;
    if (amount < target) return @min(target, amount + step);
    if (amount > target) return @max(target, amount - step);
    return amount;
}

fn buttonWidth(amount_arg: f32) f32 {
    const amount = std.math.clamp(amount_arg, 0, 1);
    return task_icon_button_dip + (task_wide_button_dip - task_icon_button_dip) * amount;
}

fn containsRect(rect: RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

pub fn smokeCheck() bool {
    const island = islandBoxFor(1920, 220, 36);
    const first = taskIconButtonAt(island, 0, 3, -1, 0, 0, 0);
    const second = taskIconButtonAt(island, 1, 3, -1, 0, 0, 0);
    const opened = taskIconButtonAt(island, 0, 3, 0, 1, 0, 0);
    if (first.left != island.rect.right + task_icon_pad_dip or second.left != first.right + task_icon_gap_dip) return false;
    if (opened.right - opened.left != task_wide_button_dip) return false;
    if (taskIconHit(island, 3, 0, 1, opened.left + 2, opened.top + 2) != 0) return false;
    if (taskIconUnderPointer(island, 3, first.left + 2, (first.top + first.bottom) * 0.5) != 0) return false;
    if (!taskRowContains(island, 3, opened.right - 1, opened.top + 1, 0, 0)) return false;
    if (taskIconToKeepOpen(island, 3, 0, opened.right - 1, opened.top + 1) != 0) return false;
    if (taskIconsThatFitInWidth(0) != 0 or taskIconsThatFitInWidth(1000) > max_task_icons) return false;
    const step = @as(f32, 0.1) / task_icon_appear_seconds;
    if (taskIconAppearStep(0, true, 0.1) != step or taskIconAppearStep(1, false, 0.1) != 1 - step) return false;
    const tray = trayButtonFor(island);
    if (tray.left != island.rect.right + task_icon_pad_dip or !trayButtonHit(island, tray.left, tray.top)) return false;
    if (rowAnchorWithTray(island, true).rect.right - island.rect.right != trayButtonReservedDip()) return false;
    if (deckCardAnchorCentre(island, .start_button) != (startButtonFor(island).left + startButtonFor(island).right) * 0.5) return false;
    if (statusStripFor(island).rect.right >= systemButtonFor(island).left) return false;
    if (taskIconsThatFitForMonitor(1920, 100) == 0 or taskIconsThatFitForMonitor(1920, 0) != 0) return false;
    return statusStripFadeStep(0, true, 0.1) == 0.5 and taskIconsThatFitForMonitor(1920, 100) <= max_task_icons;
}
