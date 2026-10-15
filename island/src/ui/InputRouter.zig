const std = @import("std");
const LayoutSnapshot = @import("LayoutSnapshot");

pub const SliderPhase = enum { press, drag };

pub const Action = union(enum) {
    none,
    adjust: struct {
        element_id: LayoutSnapshot.ElementId,
        element_index: i32,
        fraction: f32,
        phase: SliderPhase,
        frame_generation: u64,
    },
    release: struct {
        element_id: LayoutSnapshot.ElementId,
        element_index: i32,
        frame_generation: u64,
    },
};

pub const Event = union(enum) {
    press: Point,
    move: struct { point: Point, button_down: bool },
    release,
    cancel,
};

pub const Point = struct { x_px: i32, y_px: i32 };
pub const Capture = struct { element_id: LayoutSnapshot.ElementId, element_index: i32, frame_generation: u64, data_generation: u64 };

pub const Router = struct {
    capture: ?Capture = null,

    pub fn capturedIndex(self: *const Router) ?i32 {
        return if (self.capture) |capture| capture.element_index else null;
    }

    pub fn route(self: *Router, event: Event, presented: *const LayoutSnapshot.Snapshot) Action {
        switch (event) {
            .press => |point| {
                self.capture = null;
                const hit = presented.hitTestScreenPixels(point.x_px, point.y_px) orelse return .none;
                if (hit.id != .slider or hit.index < 0 or
                    boundsWidth(hit.bounds) <= 0 or boundsHeight(hit.bounds) <= 0) return .none;
                self.capture = .{ .element_id = hit.id, .element_index = hit.index, .frame_generation = presented.generation, .data_generation = presented.data_generation };
                return .{ .adjust = .{
                    .element_id = hit.id,
                    .element_index = hit.index,
                    .fraction = fractionFor(hit),
                    .phase = .press,
                    .frame_generation = presented.generation,
                } };
            },
            .move => |move| {
                if (!move.button_down) {
                    self.capture = null;
                    return .none;
                }
                const capture = self.capture orelse return .none;
                if (presented.data_generation != capture.data_generation) {
                    self.capture = null;
                    return .none;
                }
                const hit = presented.hitTestScreenPixels(move.point.x_px, move.point.y_px) orelse return .none;
                if (hit.id != capture.element_id or hit.index != capture.element_index or
                    boundsWidth(hit.bounds) <= 0 or boundsHeight(hit.bounds) <= 0) return .none;
                return .{ .adjust = .{
                    .element_id = hit.id,
                    .element_index = hit.index,
                    .fraction = fractionFor(hit),
                    .phase = .drag,
                    .frame_generation = presented.generation,
                } };
            },
            .release => {
                const capture = self.capture orelse return .none;
                self.capture = null;
                return .{ .release = .{
                    .element_id = capture.element_id,
                    .element_index = capture.element_index,
                    .frame_generation = capture.frame_generation,
                } };
            },
            .cancel => {
                self.capture = null;
                return .none;
            },
        }
    }
};

fn fractionFor(hit: LayoutSnapshot.Hit) f32 {
    const width = boundsWidth(hit.bounds);
    return if (width > 0) @max(0, @min(1, (hit.point_x - hit.bounds.left) / width)) else 0;
}

fn boundsWidth(bounds: LayoutSnapshot.Bounds) f32 {
    return bounds.right - bounds.left;
}

fn boundsHeight(bounds: LayoutSnapshot.Bounds) f32 {
    return bounds.bottom - bounds.top;
}

fn expectNone(action: Action) !void {
    try std.testing.expect(std.meta.activeTag(action) == .none);
}

test "press and release produce one volume action" {
    var snapshot = testSnapshot(5, .{ .left = 100, .top = 40, .right = 200, .bottom = 70 });
    var router = Router{};
    const pressed = router.route(.{ .press = .{ .x_px = 150, .y_px = 55 } }, &snapshot);
    try std.testing.expect(std.meta.activeTag(pressed) == .adjust);
    try std.testing.expectEqual(@as(f32, 0.5), pressed.adjust.fraction);
    const released = router.route(.release, &snapshot);
    try std.testing.expect(std.meta.activeTag(released) == .release);
    try std.testing.expectEqual(@as(u64, 5), released.release.frame_generation);
    try std.testing.expect(router.capture == null);
}

test "drag follows the latest presented frame and keeps the captured element" {
    var router = Router{};
    var first = testSnapshot(10, .{ .left = 100, .top = 40, .right = 200, .bottom = 70 });
    _ = router.route(.{ .press = .{ .x_px = 120, .y_px = 55 } }, &first);
    var next = testSnapshot(11, .{ .left = 120, .top = 40, .right = 220, .bottom = 70 });
    const dragged = router.route(.{ .move = .{ .point = .{ .x_px = 195, .y_px = 55 }, .button_down = true } }, &next);
    try std.testing.expectEqual(@as(u64, 11), dragged.adjust.frame_generation);
    try std.testing.expectEqual(SliderPhase.drag, dragged.adjust.phase);
    try std.testing.expectEqual(@as(f32, 0.75), dragged.adjust.fraction);
    try std.testing.expectEqual(@as(i32, 0), dragged.adjust.element_index);
}

test "route chooses the highest z-order hit" {
    var snapshot = LayoutSnapshot.Snapshot{ .generation = 6, .valid = true, .surface_clip = .{ .left = 0, .top = 0, .right = 30, .bottom = 30 }, .content_clip = .{ .left = 0, .top = 0, .right = 30, .bottom = 30 } };
    const region = LayoutSnapshot.Bounds{ .left = 5, .top = 5, .right = 20, .bottom = 20 };
    try std.testing.expect(snapshot.append(.{ .index = 0, .bounds = region, .hit_region = region, .z_order = 1, .visible = true, .enabled = true }));
    try std.testing.expect(snapshot.append(.{ .index = 1, .bounds = region, .hit_region = region, .z_order = 4, .visible = true, .enabled = true }));
    var router = Router{};
    const action = router.route(.{ .press = .{ .x_px = 10, .y_px = 10 } }, &snapshot);
    try std.testing.expect(std.meta.activeTag(action) == .adjust);
    try std.testing.expectEqual(@as(i32, 1), action.adjust.element_index);
}

test "clipped, gap, zero-size, and out-of-bounds presses do not capture" {
    var router = Router{};
    var clipped = testSnapshot(1, .{ .left = 0, .top = 0, .right = 20, .bottom = 20 });
    clipped.content_clip = .{ .left = 0, .top = 0, .right = 10, .bottom = 10 };
    try expectNone(router.route(.{ .press = .{ .x_px = 15, .y_px = 5 } }, &clipped));
    try std.testing.expect(router.capture == null);

    var gap = LayoutSnapshot.Snapshot{ .valid = true, .generation = 2, .surface_clip = .{ .left = 0, .top = 0, .right = 40, .bottom = 20 }, .content_clip = .{ .left = 0, .top = 0, .right = 40, .bottom = 20 } };
    try std.testing.expect(gap.append(.{ .index = 0, .bounds = .{ .left = 0, .top = 0, .right = 10, .bottom = 10 }, .hit_region = .{ .left = 0, .top = 0, .right = 10, .bottom = 10 }, .visible = true, .enabled = true }));
    try std.testing.expect(gap.append(.{ .index = 1, .bounds = .{ .left = 20, .top = 0, .right = 30, .bottom = 10 }, .hit_region = .{ .left = 20, .top = 0, .right = 30, .bottom = 10 }, .visible = true, .enabled = true }));
    try expectNone(router.route(.{ .press = .{ .x_px = 15, .y_px = 5 } }, &gap));

    var zero = testSnapshot(3, .{ .left = 8, .top = 8, .right = 8, .bottom = 16 });
    try expectNone(router.route(.{ .press = .{ .x_px = 8, .y_px = 12 } }, &zero));
    try expectNone(router.route(.{ .press = .{ .x_px = 250, .y_px = 55 } }, &clipped));
}

test "cancel and fast re-press do not retain the old frame capture" {
    var router = Router{};
    var first = testSnapshot(4, .{ .left = 100, .top = 40, .right = 200, .bottom = 70 });
    _ = router.route(.{ .press = .{ .x_px = 150, .y_px = 55 } }, &first);
    _ = router.route(.cancel, &first);
    try std.testing.expect(router.capture == null);
    try expectNone(router.route(.{ .move = .{ .point = .{ .x_px = 150, .y_px = 55 }, .button_down = true } }, &first));
    var reversed = testSnapshot(5, .{ .left = 120, .top = 40, .right = 220, .bottom = 70 });
    const pressed = router.route(.{ .press = .{ .x_px = 170, .y_px = 55 } }, &reversed);
    try std.testing.expectEqual(@as(u64, 5), pressed.adjust.frame_generation);
}

test "data generation changes cancel captured slider targets" {
    var router = Router{};
    var first = testSnapshot(20, .{ .left = 100, .top = 40, .right = 200, .bottom = 70 });
    first.data_generation = 4;
    const pressed = router.route(.{ .press = .{ .x_px = 120, .y_px = 55 } }, &first);
    try std.testing.expect(std.meta.activeTag(pressed) == .adjust);
    var replacement = testSnapshot(21, .{ .left = 100, .top = 40, .right = 200, .bottom = 70 });
    replacement.data_generation = 5;
    try expectNone(router.route(.{ .move = .{ .point = .{ .x_px = 140, .y_px = 55 }, .button_down = true } }, &replacement));
    try std.testing.expect(router.capture == null);
}

fn testSnapshot(generation: u64, bounds: LayoutSnapshot.Bounds) LayoutSnapshot.Snapshot {
    var snapshot = LayoutSnapshot.Snapshot{
        .generation = generation,
        .valid = true,
        .surface_clip = .{ .left = 0, .top = 0, .right = 300, .bottom = 120 },
        .content_clip = .{ .left = 0, .top = 0, .right = 300, .bottom = 120 },
    };
    _ = snapshot.append(.{
        .id = .slider,
        .index = 0,
        .bounds = bounds,
        .hit_region = bounds,
        .z_order = 1,
        .visible = true,
        .enabled = true,
    });
    return snapshot;
}
