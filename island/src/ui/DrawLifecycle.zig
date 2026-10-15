const std = @import("std");

/// Pure state for one D2D target/draw pair. A failed EndDraw still closes the
/// draw phase so callers can detach the target and rebuild device resources.
pub const Stage = enum { detached, target_attached, drawing };

pub const DrawLifecycle = struct {
    stage: Stage = .detached,

    pub fn attachTarget(self: *DrawLifecycle) bool {
        if (self.stage != .detached) return false;
        self.stage = .target_attached;
        return true;
    }

    pub fn beginDrawing(self: *DrawLifecycle) bool {
        if (self.stage != .target_attached) return false;
        self.stage = .drawing;
        return true;
    }

    pub fn finishDrawing(self: *DrawLifecycle, hresult: i32) bool {
        if (self.stage != .drawing) return false;
        self.stage = .target_attached;
        return hresult >= 0;
    }

    pub fn detachTarget(self: *DrawLifecycle) bool {
        if (self.stage != .target_attached) return false;
        self.stage = .detached;
        return true;
    }
};

pub fn isDeviceLossHresult(hresult: i32) bool {
    const code: u32 = @bitCast(hresult);
    return switch (code) {
        0x887A0005, // DXGI_ERROR_DEVICE_REMOVED
        0x887A0006, // DXGI_ERROR_DEVICE_HUNG
        0x887A0007, // DXGI_ERROR_DEVICE_RESET
        0x887A0020, // DXGI_ERROR_DRIVER_INTERNAL_ERROR
        0x8899000C, // D2DERR_RECREATE_TARGET
        => true,
        else => false,
    };
}

test "draw lifecycle closes drawing and detaches after a device loss" {
    var lifecycle = DrawLifecycle{};
    try std.testing.expect(lifecycle.attachTarget());
    try std.testing.expect(lifecycle.beginDrawing());
    const device_removed: i32 = @bitCast(@as(u32, 0x887A0005));
    try std.testing.expect(!lifecycle.finishDrawing(device_removed));
    try std.testing.expectEqual(Stage.target_attached, lifecycle.stage);
    try std.testing.expect(lifecycle.detachTarget());
    try std.testing.expectEqual(Stage.detached, lifecycle.stage);
}

test "successful frame also completes before its target is detached" {
    var lifecycle = DrawLifecycle{};
    try std.testing.expect(lifecycle.attachTarget());
    try std.testing.expect(!lifecycle.attachTarget());
    try std.testing.expect(lifecycle.beginDrawing());
    try std.testing.expect(lifecycle.finishDrawing(0));
    try std.testing.expectEqual(Stage.target_attached, lifecycle.stage);
    try std.testing.expect(lifecycle.detachTarget());
    try std.testing.expectEqual(Stage.detached, lifecycle.stage);
}

test "device recovery only classifies known graphics loss results" {
    const device_reset: i32 = @bitCast(@as(u32, 0x887A0007));
    const recreate_target: i32 = @bitCast(@as(u32, 0x8899000C));
    try std.testing.expect(isDeviceLossHresult(device_reset));
    try std.testing.expect(isDeviceLossHresult(recreate_target));
    try std.testing.expect(!isDeviceLossHresult(-2147467259));
    try std.testing.expect(!isDeviceLossHresult(0));
}
