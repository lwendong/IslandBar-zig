const std = @import("std");
const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const PagePainter = @import("PagePainter");
const TextRenderer = @import("TextRenderer");
const Theme = @import("Theme");

pub const View = struct {
    app: []const u8 = &.{},
    title: []const u8 = &.{},
    body: []const u8 = &.{},
    icon_pixels: ?[]const u8 = null,
    icon_width: i32 = 0,
    icon_height: i32 = 0,
    icon_revision: u64 = 0,
};

pub const CardLayout = struct {
    clock: Geometry.RoundedBox,
    divider_y: f32,
    icon: ?Geometry.RectF = null,
    app: ?Geometry.RectF = null,
    title: ?Geometry.RectF = null,
    body: ?Geometry.RectF = null,
};

pub fn layoutFor(box: Geometry.RoundedBox, view: View) CardLayout {
    const rect = box.rect;
    const card_height = rect.bottom - rect.top;
    var clock_box = box;
    clock_box.rect.bottom = rect.top + card_height * 0.46;
    const has_icon = view.icon_pixels != null and view.icon_width > 0 and view.icon_height > 0;
    const show_icon = has_icon and (view.app.len != 0 or view.title.len != 0);
    const left = rect.left + 18;
    const text_left = left + if (show_icon) @as(f32, 26) else 0;
    const right = @max(text_left, rect.right - 18);
    var y = rect.top + card_height * 0.52;
    var result = CardLayout{ .clock = clock_box, .divider_y = rect.top + card_height * 0.49 };
    if (view.app.len != 0) {
        result.app = .{ .left = text_left, .top = y, .right = right, .bottom = y + 22 };
        if (show_icon) result.icon = .{ .left = left, .top = y + 1, .right = left + 18, .bottom = y + 19 };
        y += 28;
    }
    if (view.title.len != 0) {
        result.title = .{ .left = text_left, .top = y, .right = right, .bottom = y + 28 };
        if (view.app.len == 0 and show_icon) result.icon = .{ .left = left, .top = y + 3, .right = left + 18, .bottom = y + 21 };
        y += 34;
    }
    if (view.body.len != 0 and rect.bottom - 14 > y) {
        result.body = .{ .left = text_left, .top = y, .right = right, .bottom = rect.bottom - 14 };
    }
    return result;
}

pub fn painter(view: *const View) PagePainter.Painter {
    return .{ .context = @constCast(view), .paint_fn = paint };
}

fn paint(context: ?*anyopaque, text: *TextRenderer.TextRenderer, d2d: ?*anyopaque, box: *const Geometry.RoundedBox, opacity: f32, snapshot: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    _ = snapshot;
    const raw = context orelse return false;
    const view: *const View = @ptrCast(@alignCast(raw));
    const target = d2d orelse return false;
    if (box.rect.right <= box.rect.left or box.rect.bottom <= box.rect.top) return false;
    const layout = layoutFor(box.*, view.*);
    text.drawCardSurface(target, box.*, opacity);
    if (!text.drawClock(target, layout.clock, .card, opacity)) return false;
    const accent = Theme.currentTheme().tokens.accent;
    text.drawFeatureLine(target, .{ box.rect.left + 18, layout.divider_y }, .{ box.rect.right - 18, layout.divider_y }, .{
        .r = accent.r,
        .g = accent.g,
        .b = accent.b,
        .a = accent.a * 0.45 * opacity,
    }, 1);
    const ink = Theme.themeInk(opacity);
    if (layout.icon) |bounds| {
        if (!text.drawRgbaImage(target, view.icon_pixels, view.icon_width, view.icon_height, view.icon_revision, bounds, opacity)) return false;
    }
    if (layout.app) |bounds| if (!text.drawUtf8Label(target, .card_caption, view.app, bounds, ink)) return false;
    if (layout.title) |bounds| if (!text.drawUtf8Label(target, .card_heading, view.title, bounds, ink)) return false;
    if (layout.body) |bounds| if (!text.drawUtf8Label(target, .card_body, view.body, bounds, ink)) return false;
    return true;
}

test "notification card keeps the existing clock, divider and message geometry" {
    const box = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 300, .bottom = 360 }, .radius_x = 16, .radius_y = 16 };
    const layout = layoutFor(box, .{ .app = "app", .title = "title", .body = "body", .icon_pixels = &.{0}, .icon_width = 1, .icon_height = 1 });
    try std.testing.expectApproxEqAbs(@as(f32, 165.6), layout.clock.rect.bottom, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 176.4), layout.divider_y, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 187.2), layout.app.?.top, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 215.2), layout.title.?.top, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 249.2), layout.body.?.top, 0.01);
    try std.testing.expectEqual(@as(f32, 18), Geometry.width(layout.icon.?));
}
