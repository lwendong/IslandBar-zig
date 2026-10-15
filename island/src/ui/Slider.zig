const std = @import("std");
const CanvasModule = @import("Canvas");
const Geometry = @import("Geometry");
const ThemeTokens = @import("ThemeTokens");

pub const Style = struct {
    track_height: f32 = 4,
    track_radius: f32 = 2,
    thumb_radius_x: f32 = 6,
    thumb_radius_y: f32 = 6,
    track_color: ThemeTokens.Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    fill_color: ThemeTokens.Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    thumb_color: ThemeTokens.Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
};

/// Read-only input to the paint primitive. The owner computes value and style.
pub const ViewModel = struct {
    fraction: f32 = 0,
    style: Style = .{},
};

pub fn paint(canvas: *const CanvasModule.Canvas, bounds: Geometry.RectF, model: ViewModel, opacity_arg: f32) void {
    const width = Geometry.width(bounds);
    if (!(width > 0) or !(bounds.bottom > bounds.top)) return;

    const fraction = if (std.math.isFinite(model.fraction)) std.math.clamp(model.fraction, 0, 1) else 0;
    const opacity = if (std.math.isFinite(opacity_arg)) std.math.clamp(opacity_arg, 0, 1) else 0;
    const center_y = (bounds.top + bounds.bottom) * 0.5;
    const handle_x = bounds.left + width * fraction;
    const track_top = center_y - model.style.track_height * 0.5;
    const track_bottom = center_y + model.style.track_height * 0.5;

    canvas.fillRoundedRect(.{
        .rect = .{ .left = bounds.left, .top = track_top, .right = bounds.right, .bottom = track_bottom },
        .radius_x = model.style.track_radius,
        .radius_y = model.style.track_radius,
    }, ThemeTokens.withOpacity(model.style.track_color, opacity));

    if (fraction > 0.001) {
        canvas.fillRoundedRect(.{
            .rect = .{ .left = bounds.left, .top = track_top, .right = handle_x, .bottom = track_bottom },
            .radius_x = model.style.track_radius,
            .radius_y = model.style.track_radius,
        }, ThemeTokens.withOpacity(model.style.fill_color, opacity));
    }

    canvas.fillEllipse(.{
        .center_x = handle_x,
        .center_y = center_y,
        .radius_x = model.style.thumb_radius_x,
        .radius_y = model.style.thumb_radius_y,
    }, ThemeTokens.withOpacity(model.style.thumb_color, opacity));
}

test "slider paint emits track fill and thumb at the clamped value" {
    const TestCanvas = struct {
        rounded: [2]CanvasModule.RoundedRect = undefined,
        rounded_colors: [2]ThemeTokens.Color = undefined,
        rounded_count: usize = 0,
        ellipse: CanvasModule.Ellipse = undefined,
        ellipse_color: ThemeTokens.Color = undefined,
        ellipse_count: usize = 0,

        fn fillRounded(raw: ?*anyopaque, rect: *const CanvasModule.RoundedRect, color: *const ThemeTokens.Color) callconv(.c) void {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.rounded[self.rounded_count] = rect.*;
            self.rounded_colors[self.rounded_count] = color.*;
            self.rounded_count += 1;
        }

        fn fillEllipse(raw: ?*anyopaque, ellipse: *const CanvasModule.Ellipse, color: *const ThemeTokens.Color) callconv(.c) void {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.ellipse = ellipse.*;
            self.ellipse_color = color.*;
            self.ellipse_count += 1;
        }
    };

    var recorder = TestCanvas{};
    const canvas = CanvasModule.Canvas{
        .context = &recorder,
        .fill_rounded_rect_fn = TestCanvas.fillRounded,
        .fill_ellipse_fn = TestCanvas.fillEllipse,
    };
    const color = ThemeTokens.Color{ .r = 0.2, .g = 0.3, .b = 0.4, .a = 1 };
    const model = ViewModel{ .fraction = 1.5, .style = .{
        .track_height = 4,
        .track_radius = 2,
        .thumb_radius_x = 6,
        .thumb_radius_y = 6,
        .track_color = color,
        .fill_color = color,
        .thumb_color = color,
    } };

    paint(&canvas, .{ .left = 10, .right = 110, .top = 20, .bottom = 40 }, model, 0.5);
    try @import("std").testing.expectEqual(@as(usize, 2), recorder.rounded_count);
    try @import("std").testing.expectEqual(@as(usize, 1), recorder.ellipse_count);
    try @import("std").testing.expectEqual(@as(f32, 110), recorder.rounded[1].rect.right);
    try @import("std").testing.expectEqual(@as(f32, 110), recorder.ellipse.center_x);
    try @import("std").testing.expectEqual(@as(f32, 0.5), recorder.ellipse_color.a);
}

test "slider paint skips fill at zero and ignores zero-size bounds" {
    const TestCanvas = struct {
        rounded_count: usize = 0,
        ellipse_count: usize = 0,
        fn fillRounded(raw: ?*anyopaque, _: *const CanvasModule.RoundedRect, _: *const ThemeTokens.Color) callconv(.c) void {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.rounded_count += 1;
        }
        fn fillEllipse(raw: ?*anyopaque, _: *const CanvasModule.Ellipse, _: *const ThemeTokens.Color) callconv(.c) void {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.ellipse_count += 1;
        }
    };
    var recorder = TestCanvas{};
    const canvas = CanvasModule.Canvas{ .context = &recorder, .fill_rounded_rect_fn = TestCanvas.fillRounded, .fill_ellipse_fn = TestCanvas.fillEllipse };
    const model = ViewModel{ .fraction = 0, .style = .{
        .track_height = 4,
        .track_radius = 2,
        .thumb_radius_x = 6,
        .thumb_radius_y = 6,
        .track_color = .{ .r = 1, .g = 1, .b = 1, .a = 0.2 },
        .fill_color = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
        .thumb_color = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
    } };
    paint(&canvas, .{ .left = 10, .right = 110, .top = 20, .bottom = 40 }, model, 1);
    try @import("std").testing.expectEqual(@as(usize, 1), recorder.rounded_count);
    try @import("std").testing.expectEqual(@as(usize, 1), recorder.ellipse_count);
    paint(&canvas, .{ .left = 10, .right = 10, .top = 20, .bottom = 40 }, model, 1);
    try @import("std").testing.expectEqual(@as(usize, 1), recorder.rounded_count);
    try @import("std").testing.expectEqual(@as(usize, 1), recorder.ellipse_count);
}
