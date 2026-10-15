const WeatherData = @import("WeatherData");
const WeatherController = @import("WeatherController");
const StatusLineWeather = @import("StatusLineWeather");

pub fn buildView(state: WeatherController.State) StatusLineWeather.View {
    if (!state.has_reading or !state.reading.valid) return .{};
    var view = StatusLineWeather.View{ .mark = markForCode(state.reading.weather_code) };
    if (weatherWordForCode(state.reading.weather_code)) |word| {
        var cursor: usize = 0;
        appendWide(&view.sky, &cursor, word);
    }
    var temperature_cursor: usize = 0;
    appendTemperature(&view.temperature, &temperature_cursor, state.reading.temperature_c);
    return view;
}

pub fn weatherLineFor(reading: WeatherData.Reading, output: []u16) void {
    if (output.len == 0) return;
    output[0] = 0;
    if (!reading.valid) return;
    var cursor: usize = 0;
    if (weatherWordForCode(reading.weather_code)) |word| {
        appendWide(output, &cursor, word);
        appendWideUnit(output, &cursor, ' ');
    }
    appendTemperature(output, &cursor, reading.temperature_c);
}

pub fn markForCode(code: i32) StatusLineWeather.Mark {
    return switch (code) {
        0, 1 => .sun,
        2 => .sun_cloud,
        3 => .cloud,
        45, 48 => .fog,
        51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82 => .rain,
        71, 73, 75, 77, 85, 86 => .snow,
        95, 96, 99 => .thunder,
        else => .none,
    };
}

fn weatherWordForCode(code: i32) ?[]const u16 {
    return switch (code) {
        0, 1 => &.{0x6674},
        2 => &.{ 0x591A, 0x4E91 },
        3 => &.{0x9634},
        45, 48 => &.{0x96FE},
        51, 53, 61 => &.{ 0x5C0F, 0x96E8 },
        55, 63 => &.{ 0x4E2D, 0x96E8 },
        56, 57, 66, 67 => &.{ 0x51BB, 0x96E8 },
        65 => &.{ 0x5927, 0x96E8 },
        71 => &.{ 0x5C0F, 0x96EA },
        73 => &.{ 0x4E2D, 0x96EA },
        75 => &.{ 0x5927, 0x96EA },
        77 => &.{ 0x7C73, 0x96EA },
        80, 81 => &.{ 0x9635, 0x96E8 },
        82 => &.{ 0x5F3A, 0x9635, 0x96E8 },
        85, 86 => &.{ 0x9635, 0x96EA },
        95 => &.{ 0x96F7, 0x9635, 0x96E8 },
        96, 99 => &.{ 0x51B0, 0x96F9 },
        else => null,
    };
}

fn appendWide(output: []u16, cursor: *usize, text: []const u16) void {
    for (text) |unit| appendWideUnit(output, cursor, unit);
}

fn appendWideUnit(output: []u16, cursor: *usize, unit: u16) void {
    if (cursor.* + 1 >= output.len) return;
    output[cursor.*] = unit;
    cursor.* += 1;
    output[cursor.*] = 0;
}

fn appendTemperature(output: []u16, cursor: *usize, temperature_c: f64) void {
    const degrees: i32 = @intFromFloat(@round(temperature_c));
    var digits: [16]u8 = undefined;
    const text = std.fmt.bufPrint(&digits, "{d}", .{degrees}) catch return;
    for (text) |byte| appendWideUnit(output, cursor, byte);
    appendWideUnit(output, cursor, 0x00B0);
}

test "weather display contribution preserves localized labels and rounded Celsius" {
    var state = WeatherController.State{ .reading = .{ .temperature_c = -1.2, .weather_code = 61, .valid = true }, .has_reading = true };
    const view = buildView(state);
    try std.testing.expectEqual(StatusLineWeather.Mark.rain, view.mark);
    try std.testing.expectEqualSlices(u16, std.mem.sliceTo(&view.sky, 0), &.{ 0x5C0F, 0x96E8 });
    try std.testing.expectEqualSlices(u16, std.mem.sliceTo(&view.temperature, 0), &.{ '-', '1', 0x00B0 });
    var line: [32]u16 = @splat(0);
    weatherLineFor(state.reading, &line);
    try std.testing.expectEqualSlices(u16, std.mem.sliceTo(&line, 0), &.{ 0x5C0F, 0x96E8, ' ', '-', '1', 0x00B0 });
    state.has_reading = false;
    try std.testing.expectEqual(StatusLineWeather.View{}, buildView(state));
}

test "unknown weather code retains temperature but omits unknown label and mark" {
    const reading = WeatherData.Reading{ .temperature_c = 21.6, .weather_code = 999, .valid = true };
    const view = buildView(.{ .reading = reading, .has_reading = true });
    try std.testing.expectEqual(StatusLineWeather.Mark.none, view.mark);
    try std.testing.expectEqualSlices(u16, std.mem.sliceTo(&view.sky, 0), &.{});
    try std.testing.expectEqualSlices(u16, std.mem.sliceTo(&view.temperature, 0), &.{ '2', '2', 0x00B0 });
}

const std = @import("std");
