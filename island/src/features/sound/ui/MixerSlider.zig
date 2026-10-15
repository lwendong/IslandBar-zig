const Slider = @import("Slider");
const ThemeTokens = @import("ThemeTokens");

pub fn viewModel(volume: f32, muted: bool, tokens: ThemeTokens.Tokens) Slider.ViewModel {
    return .{
        .fraction = if (muted or !std.math.isFinite(volume)) 0 else std.math.clamp(volume, 0, 1),
        .style = .{
            .track_height = 4,
            .track_radius = 2,
            .thumb_radius_x = 6,
            .thumb_radius_y = 6,
            .track_color = ThemeTokens.withAlpha(tokens.ink, 0.22),
            .fill_color = ThemeTokens.withOpacity(tokens.accent, 0.95),
            .thumb_color = ThemeTokens.withAlpha(tokens.ink, 0.96),
        },
    };
}

const std = @import("std");

test "mixer slider maps muted and active values to shared UI style" {
    const tokens = ThemeTokens.Tokens{
        .accent = .{ .r = 0.1, .g = 0.4, .b = 0.8, .a = 0.6 },
        .ink = .{ .r = 0.9, .g = 0.9, .b = 0.9, .a = 0.8 },
    };
    const active = viewModel(0.7, false, tokens);
    try std.testing.expectApproxEqAbs(@as(f32, 0.7), active.fraction, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.57), active.style.fill_color.a, 0.0001);
    try std.testing.expectEqual(@as(f32, 0.22), active.style.track_color.a);
    try std.testing.expectEqual(@as(f32, 0.96), active.style.thumb_color.a);
    try std.testing.expectEqual(@as(f32, 0), viewModel(0.7, true, tokens).fraction);
    try std.testing.expectEqual(@as(f32, 1), viewModel(2, false, tokens).fraction);
}
