const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;

pub const start_button_dip: f32 = 30;
pub const start_icon_dip: f32 = 20;
pub const control_gap_dip: f32 = 4;
pub const control_pad_dip: f32 = 8;
pub const status_strip_width_dip: f32 = 268;
pub const status_strip_height_dip: f32 = 26;
pub const status_strip_gap_dip: f32 = 10;
pub const status_strip_pad_dip: f32 = 8;
pub const status_strip_fade_seconds: f32 = 0.20;
pub const control_spring_omega: f32 = 48;
pub const spring_zeta: f32 = 0.8;
pub const tray_icon_dip: f32 = 30;
pub const tray_picture_dip: f32 = 16;
pub const tray_gap_dip: f32 = 2;
pub const tray_right_margin_dip: f32 = 6;
pub const max_tray_icons: usize = 24;

pub fn deckRight(island: RoundedBox) f32 {
    return island.rect.left - control_pad_dip;
}

pub fn deckButtonFor(island: RoundedBox, index: i32) RectF {
    const right = deckRight(island) - @as(f32, @floatFromInt(index)) * (start_button_dip + control_gap_dip);
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

pub fn controlWashStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32) bool {
    return springStep(value, velocity, target, dt_seconds, control_spring_omega);
}

pub fn trayButtonFor(island: RoundedBox) RectF {
    const left = island.rect.right + control_pad_dip;
    const top = (island.rect.top + island.rect.bottom) * 0.5 - tray_icon_dip * 0.5;
    return .{ .left = left, .top = top, .right = left + tray_icon_dip, .bottom = top + tray_icon_dip };
}

pub fn trayButtonHit(island: RoundedBox, x: f32, y: f32) bool {
    return containsRect(trayButtonFor(island), x, y);
}

pub fn trayButtonReservedDip() f32 {
    return tray_icon_dip + control_gap_dip * 2;
}

pub fn barClusterFor(island: RoundedBox, tray_button_shown: bool) RoundedBox {
    const left = systemButtonFor(island).left - control_gap_dip;
    const right = (if (tray_button_shown) trayButtonFor(island).right else island.rect.right) + control_gap_dip;
    const radius = (island.rect.bottom - island.rect.top) * 0.5;
    return .{
        .rect = .{ .left = left, .top = island.rect.top, .right = right, .bottom = island.rect.bottom },
        .radius_x = radius,
        .radius_y = radius,
    };
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

fn containsRect(rect: RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

pub fn smokeCheck() bool {
    const island = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 1920, 0));
    const start = startButtonFor(island);
    const system = systemButtonFor(island);
    const tray = trayButtonFor(island);
    if (start.right >= island.rect.left or system.right >= start.left) return false;
    if (tray.left != island.rect.right + control_pad_dip or !trayButtonHit(island, tray.left, tray.top)) return false;
    const cluster = barClusterFor(island, true);
    if (cluster.rect.left >= system.left or cluster.rect.right <= tray.right) return false;
    if (deckCardAnchorCentre(island, .start_button) != (start.left + start.right) * 0.5) return false;
    if (statusStripFor(island).rect.right >= system.left) return false;
    return trayButtonReservedDip() == tray_icon_dip + control_gap_dip * 2 and statusStripFadeStep(0, true, 0.1) == 0.5;
}

test "bar controls keep their island-relative hit and paint geometry" {
    try std.testing.expect(smokeCheck());
}
