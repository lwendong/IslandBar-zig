/// Pointer-free values exchanged between the Sound Feature and Windows audio adapters.
pub const max_devices: usize = 8;
pub const max_sessions: usize = 10;
pub const icon_bytes: usize = 4096;

pub const DeviceInfo = struct {
    name: [128]u16 = @splat(0),
    id: [256]u16 = @splat(0),
    form_factor: i32 = 0,
    is_default: bool = false,
};

pub const SessionInfo = struct {
    name: [128]u16 = @splat(0),
    source: [260]u16 = @splat(0),
    pid: u32 = 0,
    volume: f32 = 1,
    active: bool = false,
    system: bool = false,
    has_icon: bool = false,
    icon_revision: u64 = 0,
    icon: [icon_bytes]u8 = @splat(0),
    icon_size: usize = 0,
};

pub const Snapshot = struct {
    devices: [max_devices]DeviceInfo = @splat(.{}),
    device_count: usize = 0,
    default_device: ?usize = null,
    default_device_name: [128]u16 = @splat(0),
    sessions: [max_sessions]SessionInfo = @splat(.{}),
    session_count: usize = 0,
    revision: u64 = 0,

    pub fn normalize(self: *Snapshot) void {
        self.device_count = @min(self.device_count, max_devices);
        self.session_count = @min(self.session_count, max_sessions);
        if (self.default_device) |index| if (index >= self.device_count) {
            self.default_device = null;
        };
        for (self.sessions[0..self.session_count]) |*session| session.volume = clamp01(session.volume);
    }

    pub fn sessionIndexForPid(self: *const Snapshot, pid: u32) ?usize {
        for (self.sessions[0..self.session_count], 0..) |session, index| {
            if (session.pid == pid) return index;
        }
        return null;
    }
};

pub const Operation = enum { master_volume, master_mute, session_volume, default_device };

/// Completed worker result. `hresult` is the original Windows status code.
pub const OperationResult = struct {
    token: u64,
    operation: Operation,
    hresult: i32,
};

pub fn succeeded(hresult: i32) bool {
    return hresult >= 0;
}

fn clamp01(value: f32) f32 {
    return if (std.math.isFinite(value)) std.math.clamp(value, 0, 1) else 0;
}

const std = @import("std");

test "sound snapshot clamps counts and finite session values" {
    var snapshot = Snapshot{ .device_count = max_devices + 1, .session_count = max_sessions + 1 };
    snapshot.sessions[0].volume = 2;
    snapshot.sessions[1].volume = std.math.nan(f32);
    snapshot.normalize();
    try std.testing.expectEqual(max_devices, snapshot.device_count);
    try std.testing.expectEqual(max_sessions, snapshot.session_count);
    try std.testing.expectEqual(@as(f32, 1), snapshot.sessions[0].volume);
    try std.testing.expectEqual(@as(f32, 0), snapshot.sessions[1].volume);
}
