const std = @import("std");
const Catalog = @import("TaskbarCatalog");

pub const State = struct {
    snapshot: Catalog.Snapshot = .{},
    hovered_id: ?Catalog.WindowId = null,

    pub fn updateSnapshot(self: *State, snapshot: Catalog.Snapshot) bool {
        if (snapshot.count > snapshot.entries.len) return false;
        if (snapshot.revision == self.snapshot.revision) return false;
        self.snapshot = snapshot;
        if (self.hovered_id) |id| {
            if (self.snapshot.find(id) == null) {
                self.hovered_id = null;
            }
        }
        return true;
    }

    pub fn setHover(self: *State, id: ?Catalog.WindowId) bool {
        if (id) |wanted| {
            if (self.snapshot.find(wanted) == null) return false;
        }
        if (self.hovered_id == id) return false;
        self.hovered_id = id;
        return true;
    }

    pub fn action(self: *const State, id: Catalog.WindowId, presented_revision: u64) ?Catalog.Action {
        if (presented_revision != self.snapshot.revision) return null;
        const entry = self.snapshot.find(id) orelse return null;
        const request = Catalog.Request{ .id = id, .catalog_revision = presented_revision };
        return if (self.snapshot.foreground_id == id and entry.window_count <= 1)
            .{ .minimize = request }
        else
            .{ .activate = request };
    }
};

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

test "taskbar hover follows the same window through catalog reordering" {
    var state = State{};
    var first = Catalog.Snapshot{ .revision = 1, .count = 2 };
    first.entries[0] = .{ .id = 4, .process_id = 2, .process_created_at = 10 };
    first.entries[1] = .{ .id = 5, .process_id = 2, .process_created_at = 10 };
    try std.testing.expect(state.updateSnapshot(first));
    try std.testing.expect(state.setHover(5));
    var reordered = Catalog.Snapshot{ .revision = 2, .count = 2 };
    reordered.entries[0] = first.entries[1];
    reordered.entries[1] = first.entries[0];
    try std.testing.expect(state.updateSnapshot(reordered));
    try std.testing.expectEqual(@as(?Catalog.WindowId, 5), state.hovered_id);
}
