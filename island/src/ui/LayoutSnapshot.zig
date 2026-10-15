const std = @import("std");
const Geometry = @import("Geometry");

pub const max_elements = 64;
pub const Bounds = Geometry.RectF;
pub const Clip = Bounds;
pub const HitRegion = Bounds;
pub const ZOrder = i16;
pub const ElementId = enum { button, row, slider, scrollbar };

pub const Transform = struct {
    scale_x: f32 = 1,
    scale_y: f32 = 1,
    translate_x: f32 = 0,
    translate_y: f32 = 0,

    pub fn applyPoint(self: Transform, x: f32, y: f32) [2]f32 {
        return .{ x * self.scale_x + self.translate_x, y * self.scale_y + self.translate_y };
    }

    pub fn inversePoint(self: Transform, x: f32, y: f32) [2]f32 {
        const sx = if (@abs(self.scale_x) < 0.0001) @as(f32, 1) else self.scale_x;
        const sy = if (@abs(self.scale_y) < 0.0001) @as(f32, 1) else self.scale_y;
        return .{ (x - self.translate_x) / sx, (y - self.translate_y) / sy };
    }

    pub fn applyBounds(self: Transform, bounds: Bounds) Bounds {
        const first = self.applyPoint(bounds.left, bounds.top);
        const second = self.applyPoint(bounds.right, bounds.bottom);
        return .{
            .left = @min(first[0], second[0]),
            .top = @min(first[1], second[1]),
            .right = @max(first[0], second[0]),
            .bottom = @max(first[1], second[1]),
        };
    }
};

/// Converts physical screen pixels (including negative monitor coordinates) to client-local DIPs.
pub const ScreenTransform = struct {
    window_left_px: i32 = 0,
    window_top_px: i32 = 0,
    pixels_per_dip: f32 = 1,

    pub fn toClientDip(self: ScreenTransform, screen_x_px: i32, screen_y_px: i32) [2]f32 {
        const scale = @max(self.pixels_per_dip, 0.01);
        return .{
            (@as(f32, @floatFromInt(screen_x_px)) - @as(f32, @floatFromInt(self.window_left_px))) / scale,
            (@as(f32, @floatFromInt(screen_y_px)) - @as(f32, @floatFromInt(self.window_top_px))) / scale,
        };
    }
};

pub const Element = struct {
    id: ElementId = .slider,
    index: i32 = -1,
    bounds: Bounds = .{},
    hit_region: HitRegion = .{},
    z_order: ZOrder = 0,
    visible: bool = false,
    enabled: bool = false,
    content_clipped: bool = true,
};

pub const Hit = struct {
    id: ElementId,
    index: i32,
    bounds: Bounds,
    point_x: f32,
    point_y: f32,
    z_order: ZOrder,
};

pub const Snapshot = struct {
    generation: u64 = 0,
    /// Feature data generation used to build this layout, such as a device/session topology.
    data_generation: u64 = 0,
    valid: bool = false,
    transform: Transform = .{},
    screen_transform: ScreenTransform = .{},
    /// Bounds used to clip the full page while its reveal animation is running.
    surface_clip: Clip = .{},
    /// The page content viewport, intersected with surface_clip.
    content_clip: Clip = .{},
    elements: [max_elements]Element = @splat(.{}),
    count: usize = 0,

    pub fn append(self: *Snapshot, element: Element) bool {
        if (self.count >= self.elements.len) return false;
        self.elements[self.count] = element;
        self.count += 1;
        return true;
    }

    pub fn boundsFor(self: *const Snapshot, id: ElementId, index: i32) ?Bounds {
        if (!self.valid) return null;
        for (self.elements[0..self.count]) |element| {
            if (element.id == id and element.index == index and element.visible) return self.transform.applyBounds(element.bounds);
        }
        return null;
    }

    pub fn renderSurfaceClip(self: *const Snapshot) Bounds {
        return self.transform.applyBounds(self.surface_clip);
    }

    pub fn renderContentClip(self: *const Snapshot) Bounds {
        return self.transform.applyBounds(self.content_clip);
    }

    pub fn hitTestLocalDip(self: *const Snapshot, x: f32, y: f32) ?Hit {
        if (!self.valid) return null;
        const logical = self.transform.inversePoint(x, y);
        if (!contains(self.surface_clip, logical[0], logical[1])) return null;

        var found: ?Hit = null;
        for (self.elements[0..self.count]) |element| {
            const clip = if (element.content_clipped) self.content_clip else self.surface_clip;
            if (!contains(clip, logical[0], logical[1])) continue;
            if (!element.visible or !element.enabled or !contains(element.hit_region, logical[0], logical[1])) continue;
            if (found == null or element.z_order >= found.?.z_order) {
                found = .{
                    .id = element.id,
                    .index = element.index,
                    .bounds = self.transform.applyBounds(element.bounds),
                    .point_x = x,
                    .point_y = y,
                    .z_order = element.z_order,
                };
            }
        }
        return found;
    }

    pub fn hitTestScreenPixels(self: *const Snapshot, screen_x_px: i32, screen_y_px: i32) ?Hit {
        const local = self.screen_transform.toClientDip(screen_x_px, screen_y_px);
        return self.hitTestLocalDip(local[0], local[1]);
    }
};

pub fn intersection(a: Bounds, b: Bounds) Bounds {
    const left = @max(a.left, b.left);
    const top = @max(a.top, b.top);
    return .{ .left = left, .top = top, .right = @max(left, @min(a.right, b.right)), .bottom = @max(top, @min(a.bottom, b.bottom)) };
}

fn contains(bounds: Bounds, x: f32, y: f32) bool {
    return x >= bounds.left and x <= bounds.right and y >= bounds.top and y <= bounds.bottom;
}

/// Publish a candidate only after its frame completed successfully.
pub fn publishAfterSuccessfulFrame(presented: *Snapshot, candidate: Snapshot, render_succeeded: bool) void {
    if (render_succeeded) presented.* = candidate;
}

test "content and animated surface clips constrain hits" {
    var snapshot = Snapshot{ .valid = true, .surface_clip = .{ .left = 0, .top = 0, .right = 80, .bottom = 30 }, .content_clip = .{ .left = 0, .top = 10, .right = 80, .bottom = 30 } };
    try std.testing.expect(snapshot.append(.{ .index = 0, .bounds = .{ .left = 10, .top = 15, .right = 70, .bottom = 35 }, .hit_region = .{ .left = 10, .top = 15, .right = 70, .bottom = 35 }, .visible = true, .enabled = true }));
    try std.testing.expect(snapshot.hitTestLocalDip(20, 20) != null);
    try std.testing.expect(snapshot.hitTestLocalDip(20, 9) == null);
    try std.testing.expect(snapshot.hitTestLocalDip(20, 31) == null);
}

test "surface controls remain hittable outside the content viewport" {
    var snapshot = Snapshot{ .valid = true, .surface_clip = .{ .left = 0, .top = 0, .right = 80, .bottom = 80 }, .content_clip = .{ .left = 0, .top = 20, .right = 80, .bottom = 60 } };
    try std.testing.expect(snapshot.append(.{ .id = .button, .index = 0, .bounds = .{ .left = 5, .top = 5, .right = 20, .bottom = 15 }, .hit_region = .{ .left = 5, .top = 5, .right = 20, .bottom = 15 }, .visible = true, .enabled = true, .content_clipped = false }));
    try std.testing.expect(snapshot.hitTestLocalDip(10, 10) != null);
    try std.testing.expect(snapshot.hitTestLocalDip(10, 70) == null);
}

test "gaps, invisible elements and disabled elements do not hit" {
    var snapshot = Snapshot{ .valid = true, .surface_clip = .{ .left = 0, .top = 0, .right = 40, .bottom = 20 }, .content_clip = .{ .left = 0, .top = 0, .right = 40, .bottom = 20 } };
    try std.testing.expect(snapshot.append(.{ .index = 0, .bounds = .{ .left = 0, .top = 0, .right = 10, .bottom = 10 }, .hit_region = .{ .left = 0, .top = 0, .right = 10, .bottom = 10 }, .visible = true, .enabled = true }));
    try std.testing.expect(snapshot.append(.{ .index = 1, .bounds = .{ .left = 20, .top = 0, .right = 30, .bottom = 10 }, .hit_region = .{ .left = 20, .top = 0, .right = 30, .bottom = 10 }, .visible = true, .enabled = false }));
    try std.testing.expect(snapshot.append(.{ .index = 2, .bounds = .{ .left = 30, .top = 0, .right = 40, .bottom = 10 }, .hit_region = .{ .left = 30, .top = 0, .right = 40, .bottom = 10 } }));
    try std.testing.expect(snapshot.hitTestLocalDip(15, 5) == null);
    try std.testing.expect(snapshot.hitTestLocalDip(25, 5) == null);
    try std.testing.expect(snapshot.hitTestLocalDip(35, 5) == null);
}

test "highest z order wins overlapping hit regions" {
    var snapshot = Snapshot{ .valid = true, .surface_clip = .{ .left = 0, .top = 0, .right = 30, .bottom = 30 }, .content_clip = .{ .left = 0, .top = 0, .right = 30, .bottom = 30 } };
    const region = Bounds{ .left = 5, .top = 5, .right = 20, .bottom = 20 };
    try std.testing.expect(snapshot.append(.{ .index = 1, .bounds = region, .hit_region = region, .z_order = 1, .visible = true, .enabled = true }));
    try std.testing.expect(snapshot.append(.{ .index = 2, .bounds = region, .hit_region = region, .z_order = 4, .visible = true, .enabled = true }));
    try std.testing.expectEqual(@as(i32, 2), snapshot.hitTestLocalDip(10, 10).?.index);
}

test "animation transform is shared by drawing bounds and hit testing" {
    var snapshot = Snapshot{ .valid = true, .transform = .{ .scale_x = 1.5, .scale_y = 2, .translate_x = 10, .translate_y = -4 }, .surface_clip = .{ .left = 0, .top = 0, .right = 20, .bottom = 20 }, .content_clip = .{ .left = 0, .top = 0, .right = 20, .bottom = 20 } };
    const region = Bounds{ .left = 2, .top = 3, .right = 12, .bottom = 13 };
    try std.testing.expect(snapshot.append(.{ .index = 3, .bounds = region, .hit_region = region, .visible = true, .enabled = true }));
    const drawn = snapshot.boundsFor(.slider, 3).?;
    try std.testing.expectEqual(@as(f32, 13), drawn.left);
    try std.testing.expectEqual(@as(f32, 2), drawn.top);
    try std.testing.expectEqual(@as(i32, 3), snapshot.hitTestLocalDip(20, 10).?.index);
    try std.testing.expect(snapshot.hitTestLocalDip(10, 10) == null);
}

test "screen pixels map to client DIPs on negative-origin high-DPI displays" {
    const transform = ScreenTransform{ .window_left_px = -1920, .window_top_px = -40, .pixels_per_dip = 1.25 };
    const local = transform.toClientDip(-1800, 10);
    try std.testing.expectEqual(@as(f32, 96), local[0]);
    try std.testing.expectEqual(@as(f32, 40), local[1]);
}

test "failed frames do not replace the last presented snapshot" {
    var presented = Snapshot{ .generation = 7, .valid = true };
    const candidate = Snapshot{ .generation = 8, .valid = true };
    publishAfterSuccessfulFrame(&presented, candidate, false);
    try std.testing.expectEqual(@as(u64, 7), presented.generation);
    publishAfterSuccessfulFrame(&presented, candidate, true);
    try std.testing.expectEqual(@as(u64, 8), presented.generation);
}
