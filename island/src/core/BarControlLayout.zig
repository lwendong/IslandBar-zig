const std = @import("std");
const Geometry = @import("Geometry");
const Motion = @import("Motion");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;

pub const start_button_dip: f32 = 38;
pub const start_icon_dip: f32 = 19;
pub const dock_gap_dip: f32 = 12;
pub const control_spring_omega: f32 = 48;
pub const spring_zeta: f32 = 0.8;

pub fn buttonAt(left: f32, island: RoundedBox) RectF {
    const centre_y = (island.rect.top + island.rect.bottom) * 0.5;
    const top = centre_y - start_button_dip * 0.5;
    return .{ .left = left, .top = top, .right = left + start_button_dip, .bottom = top + start_button_dip };
}

pub fn startButtonFor(island: RoundedBox) RectF {
    return buttonAt(island.rect.left - dock_gap_dip - start_button_dip, island);
}

pub fn startButtonHit(island: RoundedBox, x: f32, y: f32) bool {
    return containsRect(startButtonFor(island), x, y);
}

pub fn springStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32, omega: f32) bool {
    return springStepWithDamping(value, velocity, target, dt_seconds, omega, spring_zeta);
}

pub fn springStepWithDamping(
    value: *f32,
    velocity: *f32,
    target: f32,
    dt_seconds: f32,
    omega: f32,
    damping_ratio: f32,
) bool {
    const damping = 2 * damping_ratio * omega;
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

pub const CardHang = enum { overflow_button, start_button, tray_button };

pub fn deckCardAnchorCentre(island: RoundedBox, hang: CardHang, overflow_button: RectF) f32 {
    const button = switch (hang) {
        .overflow_button => overflow_button,
        .start_button => startButtonFor(island),
        .tray_button => overflow_button,
    };
    return (button.left + button.right) * 0.5;
}

fn containsRect(rect: RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

pub fn smokeCheck() bool {
    const island = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 1920, 0));
    const start = startButtonFor(island);
    const overflow = buttonAt(island.rect.right + dock_gap_dip, island);
    if (start.right + dock_gap_dip != island.rect.left or overflow.left != island.rect.right + dock_gap_dip) return false;
    if (deckCardAnchorCentre(island, .start_button, overflow) != (start.left + start.right) * 0.5) return false;
    return deckCardAnchorCentre(island, .overflow_button, overflow) == (overflow.left + overflow.right) * 0.5;
}

test "start and overflow controls stay close to the island" {
    try std.testing.expect(smokeCheck());
}

test "underdamped spring overshoots then settles at its target" {
    var value: f32 = 0;
    var velocity: f32 = 0;
    var overshot = false;
    var peak_value: f32 = 0;
    for (0..120) |_| {
        _ = springStepWithDamping(&value, &velocity, 1, 1.0 / 60.0, 22, 0.52);
        if (value > 1) overshot = true;
        peak_value = @max(peak_value, value);
    }
    try std.testing.expect(overshot);
    try std.testing.expect(peak_value > 1.1);
    try std.testing.expectApproxEqAbs(@as(f32, 1), value, 0.001);
    try std.testing.expectEqual(@as(f32, 0), velocity);
}
