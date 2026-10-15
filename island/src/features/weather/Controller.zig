const WeatherData = @import("WeatherData");

pub const stale_after_ms: u64 = 30 * 60 * 1000;

pub const Health = enum { unavailable, fresh, cached, stale };

/// Feature-owned state. The platform reader keeps only its thread-safe
/// transport/cache snapshot; this state is the value used by the application.
pub const State = struct {
    reading: WeatherData.Reading = .{},
    has_reading: bool = false,
    source_revision: u64 = 0,
    last_attempt_succeeded: bool = false,
    last_success_ms: u64 = 0,

    pub fn health(self: State, now_ms: u64) Health {
        if (!self.has_reading) return .unavailable;
        if (now_ms -| self.last_success_ms > stale_after_ms) return .stale;
        return if (self.last_attempt_succeeded) .fresh else .cached;
    }
};

/// Applies one adapter snapshot. Revisions prevent older responses from
/// replacing newer state; success time additionally protects the last-good
/// reading if a service reports a later failed attempt.
pub fn apply(state: *State, source: WeatherData.SourceSnapshot) bool {
    if (source.revision <= state.source_revision) return false;
    state.source_revision = source.revision;
    state.last_attempt_succeeded = source.last_attempt_succeeded;
    if (source.has_reading and source.reading.valid and source.last_success_ms >= state.last_success_ms) {
        state.reading = source.reading;
        state.has_reading = true;
        state.last_success_ms = source.last_success_ms;
    }
    return true;
}

test "newer failures preserve the last good reading and old revisions are ignored" {
    var state = State{};
    try std.testing.expect(apply(&state, .{
        .reading = .{ .temperature_c = 21.4, .weather_code = 2, .valid = true },
        .has_reading = true,
        .revision = 4,
        .last_attempt_succeeded = true,
        .last_success_ms = 100,
    }));
    try std.testing.expect(apply(&state, .{ .revision = 5, .last_success_ms = 100 }));
    try std.testing.expect(!state.last_attempt_succeeded);
    try std.testing.expect(state.has_reading and state.reading.temperature_c == 21.4);
    try std.testing.expect(apply(&state, .{
        .reading = .{ .temperature_c = -8, .weather_code = 71, .valid = true },
        .has_reading = true,
        .revision = 6,
        .last_attempt_succeeded = true,
        .last_success_ms = 90,
    }));
    try std.testing.expect(state.reading.temperature_c == 21.4);
    try std.testing.expect(!apply(&state, .{ .revision = 4 }));
}

test "health marks missing, cached and expired values without erasing cache" {
    var state = State{};
    try std.testing.expectEqual(Health.unavailable, state.health(100));
    _ = apply(&state, .{
        .reading = .{ .temperature_c = 4, .weather_code = 0, .valid = true },
        .has_reading = true,
        .revision = 1,
        .last_attempt_succeeded = true,
        .last_success_ms = 100,
    });
    try std.testing.expectEqual(Health.fresh, state.health(200));
    _ = apply(&state, .{ .revision = 2, .last_success_ms = 100 });
    try std.testing.expectEqual(Health.cached, state.health(200));
    try std.testing.expectEqual(Health.stale, state.health(100 + stale_after_ms + 1));
    try std.testing.expect(state.has_reading);
}

const std = @import("std");
