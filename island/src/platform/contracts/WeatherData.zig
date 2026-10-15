/// Values crossing the weather platform adapter boundary. No handles, pointers,
/// UI strings, or platform-specific types are exposed here.
pub const Reading = struct {
    temperature_c: f64 = 0,
    weather_code: i32 = -1,
    valid: bool = false,
};

/// A stable copy of the adapter's latest attempt and last known good cache.
/// `revision` advances for both successful and failed attempts.
pub const SourceSnapshot = struct {
    reading: Reading = .{},
    has_reading: bool = false,
    revision: u64 = 0,
    last_attempt_succeeded: bool = false,
    last_success_ms: u64 = 0,
};
