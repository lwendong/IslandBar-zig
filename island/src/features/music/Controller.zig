const std = @import("std");
const Media = @import("MusicMedia");
const Lyrics = @import("MusicLyrics");

pub const Action = enum { previous, play_pause, next };
pub const TrackPosition = Media.TrackPosition;

pub const FallbackPlayer = struct {
    present: bool = false,
    title: []const u8 = &.{},
    artist: []const u8 = &.{},
};

pub const State = struct {
    media: Media.Snapshot = .{},
    active_title: [Media.title_capacity]u8 = @splat(0),
    active_artist: [Media.artist_capacity]u8 = @splat(0),
    active_present: bool = false,
    active_playing: bool = false,
    active_from_session: bool = false,
    active_position_ms: i64 = 0,
    track_stopwatch_ms: i64 = 0,
    track_generation: u64 = 0,
    requested_title: [Media.title_capacity]u8 = @splat(0),
    requested_artist: [Media.artist_capacity]u8 = @splat(0),
    lyrics: Lyrics.Lyrics = .{},
    lyrics_generation: u64 = 0,
    has_lyrics: bool = false,

    /// Applies the latest media sources and reports when the active track changed.
    pub fn update(
        self: *State,
        media: Media.Snapshot,
        fallback: FallbackPlayer,
        elapsed_ms: i64,
        since_media_reading_ms: i64,
    ) bool {
        self.media = media;
        const session_up = media.present and Media.text(&media.title).len != 0;
        const player_up = !session_up and fallback.present and fallback.title.len != 0;
        const title = if (session_up) Media.text(&media.title) else if (player_up) fallback.title else &.{};
        const artist = if (session_up) Media.text(&media.artist) else if (player_up) fallback.artist else &.{};

        self.active_present = session_up or player_up;
        self.active_from_session = session_up;
        self.active_playing = if (session_up) media.state == .playing else player_up;

        if (!self.active_present) {
            const had_track = Media.text(&self.requested_title).len != 0;
            self.active_title = @splat(0);
            self.active_artist = @splat(0);
            self.requested_title = @splat(0);
            self.requested_artist = @splat(0);
            self.track_stopwatch_ms = 0;
            self.active_position_ms = 0;
            self.lyrics = .{};
            self.has_lyrics = false;
            if (had_track) self.track_generation +%= 1;
            return false;
        }

        const changed = !std.mem.eql(u8, title, Media.text(&self.requested_title)) or
            !std.mem.eql(u8, artist, Media.text(&self.requested_artist));
        if (changed) {
            copyBytesZ(&self.requested_title, title);
            copyBytesZ(&self.requested_artist, artist);
            self.track_stopwatch_ms = 0;
            self.track_generation +%= 1;
            self.lyrics = .{};
            self.has_lyrics = false;
        }
        copyBytesZ(&self.active_title, title);
        copyBytesZ(&self.active_artist, artist);

        if (self.active_playing) self.track_stopwatch_ms = std.math.add(i64, self.track_stopwatch_ms, elapsed_ms) catch std.math.maxInt(i64);
        if (session_up) {
            self.active_position_ms = trackPositionFor(
                media.position_ms,
                media.duration_ms,
                since_media_reading_ms,
                self.track_stopwatch_ms,
                self.active_playing,
            ).ms;
        } else {
            self.active_position_ms = @max(0, self.track_stopwatch_ms);
        }
        return changed;
    }

    pub fn acceptsAsyncResult(self: *const State, generation: u64) bool {
        return generation == self.track_generation;
    }

    pub fn acceptLyrics(self: *State, result: Lyrics.Lyrics, generation: u64) bool {
        if (!self.acceptsAsyncResult(generation)) return false;
        self.lyrics = result;
        self.lyrics_generation = generation;
        self.has_lyrics = !result.empty();
        return true;
    }

    pub fn lyricAt(self: *const State, position_ms: i64, output: *Lyrics.LyricLine) bool {
        if (!self.has_lyrics or self.lyrics_generation != self.track_generation) return false;
        const index = self.lyrics.lineAt(position_ms) orelse return false;
        output.* = self.lyrics.lines[index];
        return output.text[0] != 0;
    }
};

pub fn transportFor(action: Action) Media.Transport {
    return switch (action) {
        .previous => .previous,
        .play_pause => .play_pause,
        .next => .next,
    };
}

pub fn projectedPositionMs(position_ms: i64, duration_ms: i64, elapsed_ms: i64, playing: bool) i64 {
    if (!playing or position_ms <= 0 or duration_ms <= 0 or elapsed_ms <= 0) return position_ms;
    const projected = std.math.add(i64, position_ms, elapsed_ms) catch duration_ms;
    return @min(projected, duration_ms);
}

pub fn sessionReportsTimeline(position_ms: i64, duration_ms: i64) bool {
    return position_ms > 0 or duration_ms > 0;
}

pub fn trackPositionFor(position_ms: i64, duration_ms: i64, since_reading_ms: i64, stopwatch_ms: i64, playing: bool) TrackPosition {
    if (sessionReportsTimeline(position_ms, duration_ms)) return .{
        .ms = projectedPositionMs(position_ms, duration_ms, since_reading_ms, playing),
        .from_session = true,
    };
    return .{ .ms = @max(0, stopwatch_ms), .from_session = false };
}

fn copyBytesZ(destination: []u8, source: []const u8) void {
    @memset(destination, 0);
    const count = @min(source.len, destination.len - 1);
    @memcpy(destination[0..count], source[0..count]);
}

test "music state prefers GSMTC and projects its timeline" {
    var state = State{};
    var media = Media.Snapshot{ .present = true, .state = .playing, .position_ms = 1000, .duration_ms = 5000 };
    @memcpy(media.title[0.."session title".len], "session title");
    @memcpy(media.artist[0.."session artist".len], "session artist");
    const changed = state.update(media, .{ .present = true, .title = "window title" }, 16, 500);
    try std.testing.expect(changed);
    try std.testing.expect(state.active_from_session);
    try std.testing.expectEqualStrings("session title", Media.text(&state.active_title));
    try std.testing.expectEqual(@as(i64, 1500), state.active_position_ms);
    try std.testing.expect(state.acceptsAsyncResult(state.track_generation));
    try std.testing.expect(!state.acceptsAsyncResult(state.track_generation -% 1));
}

test "music state resets on track changes and falls back to window titles" {
    var state = State{};
    const media = Media.Snapshot{};
    try std.testing.expect(state.update(media, .{ .present = true, .title = "first", .artist = "artist" }, 10, 0));
    try std.testing.expectEqual(@as(u64, 1), state.track_generation);
    try std.testing.expectEqual(@as(i64, 10), state.active_position_ms);
    try std.testing.expect(!state.update(media, .{ .present = true, .title = "first", .artist = "artist" }, 10, 0));
    try std.testing.expect(state.update(media, .{ .present = true, .title = "second", .artist = "artist" }, 10, 0));
    try std.testing.expectEqual(@as(u64, 2), state.track_generation);
    const old_generation = state.track_generation;
    var old_lyrics = Lyrics.Lyrics{};
    _ = Lyrics.parseLrc("[00:00.00]old", &old_lyrics);
    try std.testing.expect(state.acceptLyrics(old_lyrics, old_generation));
    try std.testing.expect(state.has_lyrics);
    try std.testing.expect(state.update(media, .{ .present = true, .title = "third", .artist = "artist" }, 10, 0));
    try std.testing.expect(!state.acceptLyrics(old_lyrics, old_generation));
    try std.testing.expect(!state.has_lyrics);
    try std.testing.expectEqual(@as(i64, 10), state.active_position_ms);
    _ = state.update(.{}, .{}, 16, 0);
    try std.testing.expect(!state.active_present);
    try std.testing.expectEqual(@as(i64, 0), state.active_position_ms);
    try std.testing.expect(!state.acceptsAsyncResult(old_generation + 1));
}
