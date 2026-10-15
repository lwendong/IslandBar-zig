const Geometry = @import("Geometry");
const TextRenderer = @import("TextRenderer");

pub const max_tray_icons: usize = 24;

/// App-assembled data for a notification-area icon. The UI receives a PNG
/// and stable source identity without depending on the Tray Feature.
pub const TrayIconInput = struct {
    png: []const u8 = &.{},
    source_index: u16 = 0,
    fingerprint: u64 = 0,
};

pub const TrayDockIcon = struct {
    png: []const u8 = &.{},
    source_index: u16 = 0,
    fingerprint: u64 = 0,
    revision: u64 = 0,
    bounds: Geometry.RectF = .{},
    icon_bounds: Geometry.RectF = .{},
};

/// Immutable values for one successfully presented dock row. TaskbarPage owns
/// its geometry; App supplies value-only task and tray data.
pub const View = struct {
    catalog_revision: u64 = 0,
    island: Geometry.RoundedBox = .{ .rect = .{} },
    row_bounds: Geometry.RectF = .{},
    task_row_bounds: Geometry.RectF = .{},
    buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    count: usize = 0,
    tray_icons: [max_tray_icons]TrayDockIcon = @splat(.{}),
    tray_count: usize = 0,
    overflow_button_bounds: Geometry.RectF = .{},
    overflow_bounds: Geometry.RoundedBox = .{ .rect = .{} },
    overflow_open: bool = false,
    overflow_buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    overflow_count: usize = 0,
    exit_buttons: [20]TextRenderer.TaskButton = @splat(.{}),
    exit_count: usize = 0,
    system_entry_bounds: Geometry.RectF = .{},
    tray_entry_bounds: Geometry.RectF = .{},
};
