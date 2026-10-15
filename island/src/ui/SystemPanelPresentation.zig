const Geometry = @import("Geometry");

/// Render-only value model. It carries no System Feature action or platform API.
pub const Tile = struct {
    label: ?[*:0]const u16 = null,
    state_text: ?[*:0]const u16 = null,
    icon: i32 = 1,
    icon_value: i32 = 0,
    on: bool = false,
    chevron: bool = false,
};

pub const Layout = struct {
    tiles: [6]Geometry.RectF = @splat(.{}),
    tile_icons: [6]Geometry.RectF = @splat(.{}),
    tile_labels: [6]Geometry.RectF = @splat(.{}),
    sliders: [2]Geometry.RectF = @splat(.{}),
    speaker_icon: Geometry.RectF = .{},
    brightness_icon: Geometry.RectF = .{},
    volume_button: Geometry.RectF = .{},
    gear_button: Geometry.RectF = .{},
    page_dots: [4]Geometry.RectF = @splat(.{}),
    page_up: Geometry.RectF = .{},
    page_down: Geometry.RectF = .{},
    page_dot_count: i32 = 0,
    page_index: i32 = 0,
    tile_count: i32 = 0,
    slider_count: i32 = 0,
};

pub const View = struct {
    tiles: [6]Tile = @splat(.{}),
    tile_count: usize = 0,
    page_index: i32 = 0,
    page_count: i32 = 1,
    volume: f32 = 0,
    muted: bool = false,
    show_volume_percent: bool = false,
    has_brightness: bool = false,
    brightness: f32 = 0,
    show_brightness_percent: bool = false,
    slider_emphasis: [2]f32 = .{ 0, 0 },
    layout: Layout = .{},
};
