const std = @import("std");

pub const max_windows: usize = 32;
pub const title_capacity: usize = 128;
pub const WindowId = u64;

/// Platform-neutral window instance facts. The native HWND remains private to
/// WindowService; callers use this stable id to request an action.
pub const Entry = struct {
    id: WindowId = 0,
    process_id: u32 = 0,
    process_created_at: u64 = 0,
    iconic: bool = false,
    title: [title_capacity]u16 = @splat(0),
};

pub const Snapshot = struct {
    entries: [max_windows]Entry = @splat(.{}),
    count: usize = 0,
    revision: u64 = 0,
    foreground_id: WindowId = 0,

    pub fn find(self: *const Snapshot, id: WindowId) ?*const Entry {
        if (id == 0) return null;
        for (self.entries[0..@min(self.count, self.entries.len)]) |*entry| {
            if (entry.id == id) return entry;
        }
        return null;
    }
};

pub const Request = struct {
    id: WindowId,
    catalog_revision: u64,
};

pub const Action = union(enum) {
    activate: Request,
    minimize: Request,
};

pub fn smokeCheck() bool {
    var snapshot = Snapshot{ .revision = 3, .count = 2 };
    snapshot.entries[0] = .{ .id = 11, .process_id = 7, .process_created_at = 100 };
    snapshot.entries[1] = .{ .id = 12, .process_id = 7, .process_created_at = 100 };
    return snapshot.find(11) != null and snapshot.find(0) == null and snapshot.find(99) == null;
}

test "taskbar catalog distinguishes windows in one process and bounds snapshots" {
    var snapshot = Snapshot{ .count = max_windows + 1 };
    snapshot.entries[0] = .{ .id = 1, .process_id = 9, .process_created_at = 20 };
    snapshot.entries[1] = .{ .id = 2, .process_id = 9, .process_created_at = 20 };
    try std.testing.expect(snapshot.find(2) != null);
    try std.testing.expect(snapshot.find(3) == null);
}
