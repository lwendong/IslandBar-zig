const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const TextRenderer = @import("TextRenderer");

pub const PaintFn = *const fn (
    ?*anyopaque,
    *TextRenderer.TextRenderer,
    ?*anyopaque,
    *const Geometry.RoundedBox,
    f32,
    ?*const LayoutSnapshot.Snapshot,
) callconv(.c) bool;

/// Generic callback used by the renderer to host a feature-owned page.
pub const Painter = struct {
    context: ?*anyopaque = null,
    paint_fn: PaintFn,
};
