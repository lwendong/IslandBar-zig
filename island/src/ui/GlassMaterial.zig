const ThemeModule = @import("Theme");

pub const noise_size: usize = 256;
const noise_bytes = noise_size * noise_size * 4;

pub const Color = ThemeModule.Color;
pub const RectF = extern struct { left: f32, top: f32, right: f32, bottom: f32 };
pub const RoundedRect = extern struct {
    rect: RectF,
    radius_x: f32,
    radius_y: f32,
};

/// Drawing operations are supplied by the renderer's Direct2D adapter. Keeping the material
/// math here also lets the deterministic texture and the draw parameters run independently.
pub const DrawOps = struct {
    context: ?*anyopaque = null,
    fill_rounded: *const fn (?*anyopaque, RoundedRect, Color) callconv(.c) void,
    vertical_gradient: *const fn (?*anyopaque, RoundedRect, Color, Color, f32, bool) callconv(.c) void,
    rim_gradient: *const fn (?*anyopaque, RoundedRect, Color, Color, f32) callconv(.c) void,
    grain: *const fn (?*anyopaque, RoundedRect, [*]const u8, usize, f32) callconv(.c) void,
};

var pixels: [noise_bytes]u8 = undefined;
var pixels_ready = false;
var smoke_fill_calls: usize = 0;
var smoke_gradient_calls: usize = 0;
var smoke_rim_calls: usize = 0;
var smoke_grain_calls: usize = 0;

fn buildNoise() void {
    if (pixels_ready) return;

    var state: u32 = 0x9E3779B9;
    var i: usize = 0;
    while (i < noise_size * noise_size) : (i += 1) {
        state ^= state << 13;
        state ^= state >> 17;
        state ^= state << 5;
        const grey: u8 = @intCast(112 + state % 32);
        const offset = i * 4;
        pixels[offset + 0] = grey;
        pixels[offset + 1] = grey;
        pixels[offset + 2] = grey;
        pixels[offset + 3] = 255;
    }
    pixels_ready = true;
}

pub fn noiseSize() usize {
    return noise_size;
}

/// Returns the module-owned 256x256 opaque BGRA grain texture.
pub fn noisePixels() []const u8 {
    buildNoise();
    return &pixels;
}

pub fn drawSoftShadow(ops: DrawOps, shape: RoundedRect, opacity_arg: f32, spread_dip: f32) void {
    if (opacity_arg <= 0.001 or spread_dip <= 0.01 or !valid(shape)) return;

    const steps: f32 = 6.0;
    const step_dip = spread_dip / steps;
    var step: i32 = 6;
    while (step >= 1) : (step -= 1) {
        const step_f: f32 = @floatFromInt(step);
        const grow = step_dip * step_f;
        const t = step_f / steps;
        const alpha = opacity_arg * (1.0 - t) * (1.0 - t) / steps * 2.2;
        if (alpha <= 0.001) continue;

        const grown = RoundedRect{
            .rect = .{
                .left = shape.rect.left - grow,
                .top = shape.rect.top - grow,
                .right = shape.rect.right + grow,
                .bottom = shape.rect.bottom + grow,
            },
            .radius_x = shape.radius_x + grow * 0.6,
            .radius_y = shape.radius_y + grow * 0.6,
        };
        ops.fill_rounded(ops.context, grown, color(0, 0, 0, alpha));
    }
}

pub fn drawSurfaceLighting(ops: DrawOps, shape: RoundedRect, theme: *const ThemeModule.Theme, opacity_arg: f32) void {
    if (opacity_arg <= 0.01 or !valid(shape) or theme.gloss <= 0.001) return;
    const height = shape.rect.bottom - shape.rect.top;
    const width = shape.rect.right - shape.rect.left;
    if (height < 6 or width < 6) return;

    const top_band = @min(height * 0.45, 20.0);
    const bottom_band = @min(height * 0.35, 26.0);
    ops.vertical_gradient(ops.context, shape, themeInk(theme, theme.gloss * 1.25 * opacity_arg), themeInk(theme, 0), top_band, true);
    ops.vertical_gradient(ops.context, shape, color(0, 0, 0, 0), color(0, 0, 0, theme.gloss * 0.6 * opacity_arg), bottom_band, false);

    const inset: f32 = 1.0;
    const inner = RoundedRect{
        .rect = .{
            .left = shape.rect.left + inset,
            .top = shape.rect.top + inset,
            .right = shape.rect.right - inset,
            .bottom = shape.rect.bottom - inset,
        },
        .radius_x = @max(0, shape.radius_x - inset),
        .radius_y = @max(0, shape.radius_y - inset),
    };
    ops.rim_gradient(ops.context, inner, themeInk(theme, theme.gloss * 0.95 * opacity_arg), themeInk(theme, theme.gloss * 0.10 * opacity_arg), 1.0);
}

pub fn drawGrain(ops: DrawOps, shape: RoundedRect, opacity_arg: f32) void {
    if (opacity_arg <= 0.001 or !valid(shape)) return;
    const data = noisePixels();
    ops.grain(ops.context, shape, data.ptr, noise_size, opacity_arg);
}

fn valid(shape: RoundedRect) bool {
    return shape.rect.right > shape.rect.left and shape.rect.bottom > shape.rect.top;
}

fn color(r: f32, g: f32, b: f32, a: f32) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

fn themeInk(theme: *const ThemeModule.Theme, alpha: f32) Color {
    return .{ .r = theme.tokens.ink.r, .g = theme.tokens.ink.g, .b = theme.tokens.ink.b, .a = alpha };
}

pub fn smokeCheck() bool {
    const data = noisePixels();
    if (data.len != noise_bytes) return false;

    // Pin the first generated texel and every pixel's opaque alpha, catching seed, channel,
    // and texture-layout drift without depending on a graphics device.
    if (data[0] != 137 or data[1] != 137 or data[2] != 137 or data[3] != 255) return false;
    var i: usize = 3;
    while (i < data.len) : (i += 4) {
        if (data[i] != 255 or data[i - 3] < 112 or data[i - 3] > 143) return false;
    }
    smoke_fill_calls = 0;
    smoke_gradient_calls = 0;
    smoke_rim_calls = 0;
    smoke_grain_calls = 0;
    const ops = DrawOps{
        .fill_rounded = smokeFill,
        .vertical_gradient = smokeGradient,
        .rim_gradient = smokeRim,
        .grain = smokeGrain,
    };
    const shape = RoundedRect{
        .rect = .{ .left = 0, .top = 0, .right = 120, .bottom = 40 },
        .radius_x = 20,
        .radius_y = 20,
    };
    drawSoftShadow(ops, shape, 1.0, 6.0);
    drawSurfaceLighting(ops, shape, ThemeModule.currentTheme(), 1.0);
    drawGrain(ops, shape, 0.03);
    return smoke_fill_calls == 5 and smoke_gradient_calls == 2 and smoke_rim_calls == 1 and smoke_grain_calls == 1;
}

fn smokeFill(context: ?*anyopaque, shape: RoundedRect, ink: Color) callconv(.c) void {
    _ = context;
    _ = shape;
    _ = ink;
    smoke_fill_calls += 1;
}

fn smokeGradient(context: ?*anyopaque, shape: RoundedRect, from: Color, to: Color, band: f32, from_top: bool) callconv(.c) void {
    _ = context;
    _ = shape;
    _ = from;
    _ = to;
    _ = band;
    _ = from_top;
    smoke_gradient_calls += 1;
}

fn smokeRim(context: ?*anyopaque, shape: RoundedRect, from: Color, to: Color, width: f32) callconv(.c) void {
    _ = context;
    _ = shape;
    _ = from;
    _ = to;
    _ = width;
    smoke_rim_calls += 1;
}

fn smokeGrain(context: ?*anyopaque, shape: RoundedRect, data: [*]const u8, size: usize, opacity: f32) callconv(.c) void {
    _ = context;
    _ = shape;
    _ = opacity;
    if (data[0] == 137 and size == noise_size) smoke_grain_calls += 1;
}
