const std = @import("std");

pub const Guid = extern struct {
    data1: u32 = 0,
    data2: u16 = 0,
    data3: u16 = 0,
    data4: [8]u8 = @splat(0),
};

/// Snapshot value for one notification-area icon. The platform fills the live
/// registration locator; Feature/UI code never receives HWND or COM pointers.
pub const Icon = struct {
    name: [96]u16 = @splat(0),
    png: []const u8 = &.{},
    promoted: bool = false,
    uid: u32 = 0,
    has_uid: bool = false,
    has_guid: bool = false,
    guid: Guid = .{},
    exe_path: [512]u16 = @splat(0),
};

/// Ties a UI hit to one catalog revision and a stable registration fingerprint.
pub const Identity = struct {
    revision: u64 = 0,
    index: u16 = 0,
    fingerprint: u64 = 0,
    window_instance: ?WindowInstance = null,
};

/// A specific process/window observed by the App when it opens the icon menu.
/// The process creation timestamp prevents a reused PID from receiving an old action.
pub const WindowInstance = struct {
    process_id: u32 = 0,
    window_handle: usize = 0,
    process_created_at: u64 = 0,
};

pub fn identityFor(icon: *const Icon, revision: u64, index: usize) Identity {
    var hash: u64 = 14695981039346656037;
    for (icon.name) |unit| hash = (hash ^ unit) *% 1099511628211;
    for (icon.exe_path) |unit| hash = (hash ^ unit) *% 1099511628211;
    hash = (hash ^ icon.uid) *% 1099511628211;
    hash = (hash ^ @intFromBool(icon.has_uid)) *% 1099511628211;
    hash = (hash ^ @intFromBool(icon.has_guid)) *% 1099511628211;
    if (icon.has_guid) {
        hash = (hash ^ icon.guid.data1) *% 1099511628211;
        hash = (hash ^ icon.guid.data2) *% 1099511628211;
        hash = (hash ^ icon.guid.data3) *% 1099511628211;
        for (icon.guid.data4) |byte| hash = (hash ^ byte) *% 1099511628211;
    }
    return .{ .revision = revision, .index = @intCast(index), .fingerprint = hash };
}

pub fn identityMatches(identity: Identity, icon: *const Icon, revision: u64, index: usize) bool {
    return identity.revision == revision and identity.index == index and
        identity.fingerprint == identityFor(icon, revision, index).fingerprint;
}

test "tray identity is tied to catalog revision, index and registration values" {
    const icon = Icon{ .uid = 4, .has_uid = true, .name = [_]u16{'A'} ++ @as([95]u16, @splat(0)) };
    const identity = identityFor(&icon, 8, 2);
    try std.testing.expect(identityMatches(identity, &icon, 8, 2));
    try std.testing.expect(!identityMatches(identity, &icon, 9, 2));
    try std.testing.expect(!identityMatches(identity, &icon, 8, 3));
    var replacement = icon;
    replacement.uid = 5;
    try std.testing.expect(!identityMatches(identity, &replacement, 8, 2));
}
