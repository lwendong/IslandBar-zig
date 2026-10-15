const Geometry = @import("Geometry");
const ThemeTokens = @import("ThemeTokens");

pub const RoundedRect = struct {
    rect: Geometry.RectF,
    radius_x: f32,
    radius_y: f32,
};

pub const Ellipse = struct {
    center_x: f32,
    center_y: f32,
    radius_x: f32,
    radius_y: f32,
};

pub const Canvas = struct {
    context: ?*anyopaque,
    fill_rounded_rect_fn: *const fn (?*anyopaque, *const RoundedRect, *const ThemeTokens.Color) callconv(.c) void,
    fill_ellipse_fn: *const fn (?*anyopaque, *const Ellipse, *const ThemeTokens.Color) callconv(.c) void,

    pub fn fillRoundedRect(self: *const Canvas, rounded: RoundedRect, color: ThemeTokens.Color) void {
        self.fill_rounded_rect_fn(self.context, &rounded, &color);
    }

    pub fn fillEllipse(self: *const Canvas, ellipse: Ellipse, color: ThemeTokens.Color) void {
        self.fill_ellipse_fn(self.context, &ellipse, &color);
    }
};
