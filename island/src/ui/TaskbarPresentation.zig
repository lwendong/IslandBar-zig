const Geometry = @import("Geometry");
const TextRenderer = @import("TextRenderer");

/// Immutable values for one successfully presented application-group row.
/// The Feature produces this snapshot; common rendering and input code consume it.
pub const View = struct {
    catalog_revision: u64 = 0,
    island: Geometry.RoundedBox = .{ .rect = .{} },
    row_bounds: Geometry.RectF = .{},
    buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    count: usize = 0,
    overflow_button_bounds: Geometry.RectF = .{},
    overflow_bounds: Geometry.RoundedBox = .{ .rect = .{} },
    overflow_open: bool = false,
    overflow_buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    overflow_count: usize = 0,
    system_entry_bounds: Geometry.RectF = .{},
    tray_entry_bounds: Geometry.RectF = .{},
};
