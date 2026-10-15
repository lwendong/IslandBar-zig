const Geometry = @import("Geometry");
const TextRenderer = @import("TextRenderer");

/// Immutable values for one successfully presented application-window row.
/// The Feature produces this snapshot; common rendering and input code consume it.
pub const View = struct {
    catalog_revision: u64 = 0,
    frame_generation: u64 = 0,
    island: Geometry.RoundedBox = .{ .rect = .{} },
    row_bounds: Geometry.RectF = .{},
    buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    count: usize = 0,
};
