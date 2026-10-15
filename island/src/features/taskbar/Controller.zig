const std = @import("std");
const Catalog = @import("TaskbarCatalog");

pub const State = struct {
    snapshot: Catalog.Snapshot = .{},
    hovered_id: ?Catalog.WindowId = null,
    hover_generation: u64 = 0,
    hover_amounts: [Catalog.max_windows]f32 = @splat(0),
    hover_velocities: [Catalog.max_windows]f32 = @splat(0),

    pub fn updateSnapshot(self: *State, snapshot: Catalog.Snapshot) bool {
        if (snapshot.count > snapshot.entries.len) return false;
        if (snapshot.revision == self.snapshot.revision) return false;
        const previous = self.snapshot;
        var next_amounts: [Catalog.max_windows]f32 = @splat(0);
        var next_velocities: [Catalog.max_windows]f32 = @splat(0);
        for (snapshot.entries[0..snapshot.count], 0..) |entry, next_index| {
            for (previous.entries[0..previous.count], 0..) |old_entry, old_index| {
                if (old_entry.id != entry.id) continue;
                next_amounts[next_index] = self.hover_amounts[old_index];
                next_velocities[next_index] = self.hover_velocities[old_index];
                break;
            }
        }
        self.snapshot = snapshot;
        self.hover_amounts = next_amounts;
        self.hover_velocities = next_velocities;
        if (self.hovered_id) |id| {
            if (self.snapshot.find(id) == null) {
                self.hovered_id = null;
                self.hover_generation +%= 1;
            }
        }
        return true;
    }

    pub fn hoverAmount(self: *const State, id: Catalog.WindowId) f32 {
        for (self.snapshot.entries[0..self.snapshot.count], 0..) |entry, index| {
            if (entry.id == id) return self.hover_amounts[index];
        }
        return 0;
    }

    pub fn stepHover(self: *State, dt_seconds: f32) bool {
        var changed = false;
        for (self.snapshot.entries[0..self.snapshot.count], 0..) |entry, index| {
            if (springStep(&self.hover_amounts[index], &self.hover_velocities[index], if (self.hovered_id == entry.id) 1 else 0, dt_seconds)) changed = true;
        }
        return changed;
    }

    pub fn setHover(self: *State, id: ?Catalog.WindowId) bool {
        if (id) |wanted| {
            if (self.snapshot.find(wanted) == null) return false;
        }
        if (self.hovered_id == id) return false;
        self.hovered_id = id;
        self.hover_generation +%= 1;
        return true;
    }

    pub fn action(self: *const State, id: Catalog.WindowId, presented_revision: u64) ?Catalog.Action {
        if (presented_revision != self.snapshot.revision) return null;
        if (self.snapshot.find(id) == null) return null;
        const request = Catalog.Request{ .id = id, .catalog_revision = presented_revision };
        return if (self.snapshot.foreground_id == id) .{ .minimize = request } else .{ .activate = request };
    }
};

fn springStep(value: *f32, velocity: *f32, target: f32, dt_seconds: f32) bool {
    const omega: f32 = 48;
    const zeta: f32 = 0.8;
    const damping = 2 * zeta * omega;
    var remaining = std.math.clamp(dt_seconds, 0, 0.1);
    while (remaining > 0) {
        const h = @min(remaining, 1.0 / 240.0);
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

pub fn smokeCheck() bool {
    var state = State{};
    var snapshot = Catalog.Snapshot{ .revision = 1, .count = 2, .foreground_id = 1 };
    snapshot.entries[0] = .{ .id = 1, .process_id = 5, .process_created_at = 100 };
    snapshot.entries[1] = .{ .id = 2, .process_id = 5, .process_created_at = 100 };
    if (!state.updateSnapshot(snapshot)) return false;
    if (state.action(1, 1) == null or state.action(2, 1) == null or state.action(2, 0) != null) return false;
    return true;
}

test "taskbar actions use stable identity and reject a stale presented revision" {
    var state = State{};
    var first = Catalog.Snapshot{ .revision = 7, .count = 2, .foreground_id = 10 };
    first.entries[0] = .{ .id = 10, .process_id = 42, .process_created_at = 100 };
    first.entries[1] = .{ .id = 11, .process_id = 42, .process_created_at = 100 };
    try std.testing.expect(state.updateSnapshot(first));
    try std.testing.expect(std.meta.activeTag(state.action(10, 7).?) == .minimize);
    try std.testing.expect(std.meta.activeTag(state.action(11, 7).?) == .activate);
    try std.testing.expect(state.action(11, 6) == null);

    var reordered = Catalog.Snapshot{ .revision = 8, .count = 2, .foreground_id = 10 };
    reordered.entries[0] = first.entries[1];
    reordered.entries[1] = first.entries[0];
    try std.testing.expect(state.updateSnapshot(reordered));
    try std.testing.expect(state.action(11, 7) == null);
    try std.testing.expectEqual(@as(Catalog.WindowId, 11), state.snapshot.entries[0].id);
}

test "taskbar hover clears when a stable window identity disappears" {
    var state = State{};
    var first = Catalog.Snapshot{ .revision = 1, .count = 1 };
    first.entries[0] = .{ .id = 3, .process_id = 8, .process_created_at = 33 };
    try std.testing.expect(state.updateSnapshot(first));
    try std.testing.expect(state.setHover(3));
    const next = Catalog.Snapshot{ .revision = 2 };
    try std.testing.expect(state.updateSnapshot(next));
    try std.testing.expect(state.hovered_id == null);
    try std.testing.expect(!state.setHover(3));
}

test "taskbar hover animation follows the same window through catalog reordering" {
    var state = State{};
    var first = Catalog.Snapshot{ .revision = 1, .count = 2 };
    first.entries[0] = .{ .id = 4, .process_id = 2, .process_created_at = 10 };
    first.entries[1] = .{ .id = 5, .process_id = 2, .process_created_at = 10 };
    try std.testing.expect(state.updateSnapshot(first));
    try std.testing.expect(state.setHover(5));
    _ = state.stepHover(0.05);
    const amount = state.hoverAmount(5);
    var reordered = Catalog.Snapshot{ .revision = 2, .count = 2 };
    reordered.entries[0] = first.entries[1];
    reordered.entries[1] = first.entries[0];
    try std.testing.expect(state.updateSnapshot(reordered));
    try std.testing.expectEqual(amount, state.hoverAmount(5));
    try std.testing.expectEqual(@as(f32, 0), state.hoverAmount(4));
}
