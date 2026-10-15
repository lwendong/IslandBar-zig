/// Shared, renderer-independent colour values used by UI style modules.
/// Theme selection and persistence live in Theme.zig.
pub const Color = extern struct { r: f32, g: f32, b: f32, a: f32 };

/// Reusable colour tokens. Feature UI owns its component-specific style values.
pub const Tokens = struct {
    accent: Color,
    ink: Color,
};

pub fn withOpacity(value: Color, opacity_arg: f32) Color {
    const opacity = clamp01(opacity_arg);
    return .{ .r = value.r, .g = value.g, .b = value.b, .a = clamp01(value.a) * opacity };
}

pub fn withAlpha(value: Color, alpha_arg: f32) Color {
    return .{ .r = value.r, .g = value.g, .b = value.b, .a = clamp01(alpha_arg) };
}

fn clamp01(value: f32) f32 {
    return @max(0, @min(1, value));
}

test "token opacity preserves RGB and clamps alpha" {
    const source = Color{ .r = 0.2, .g = 0.4, .b = 0.6, .a = 0.8 };
    const result = withOpacity(source, 0.5);
    try @import("std").testing.expectEqual(source.r, result.r);
    try @import("std").testing.expectEqual(source.g, result.g);
    try @import("std").testing.expectEqual(source.b, result.b);
    try @import("std").testing.expectEqual(@as(f32, 0.4), result.a);
    try @import("std").testing.expectEqual(@as(f32, 0.8), withOpacity(source, 2).a);
    try @import("std").testing.expectEqual(@as(f32, 0), withOpacity(source, -1).a);
}
