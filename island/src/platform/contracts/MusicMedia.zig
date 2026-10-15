/// Pointer-free music data exchanged between the Music feature and Windows media services.
pub const PlaybackState = enum(i32) { closed = 0, stopped = 1, paused = 2, playing = 3, unknown = 4 };
pub const Transport = enum { play_pause, previous, next };
pub const TrackPosition = struct { ms: i64 = 0, from_session: bool = false };

pub const title_capacity: usize = 192;
pub const artist_capacity: usize = 128;
pub const album_capacity: usize = 160;
pub const app_capacity: usize = 64;
pub const app_name_capacity: usize = 128;
pub const artwork_capacity: usize = 32 * 1024;

pub const Snapshot = struct {
    present: bool = false,
    state: PlaybackState = .closed,
    title: [title_capacity]u8 = @splat(0),
    artist: [artist_capacity]u8 = @splat(0),
    album: [album_capacity]u8 = @splat(0),
    app: [app_capacity]u8 = @splat(0),
    position_ms: i64 = 0,
    duration_ms: i64 = 0,
    artwork: [artwork_capacity]u8 = @splat(0),
    artwork_size: usize = 0,
    artwork_revision: u64 = 0,
    app_name: [app_name_capacity]u8 = @splat(0),
    icon: [artwork_capacity]u8 = @splat(0),
    icon_size: usize = 0,
    icon_revision: u64 = 0,
};

pub fn text(bytes: []const u8) []const u8 {
    return bytes[0 .. @import("std").mem.indexOfScalar(u8, bytes, 0) orelse bytes.len];
}
