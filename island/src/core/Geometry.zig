pub const dip_per_inch: f32 = 96.0;

pub const window_height_dip: f32 = 520.0;
pub const pill_width_dip: f32 = 300.0;
pub const pill_height_dip: f32 = 48.0;
pub const corner_radius_dip: f32 = 24.0;
pub const pill_top_margin_dip: f32 = 8.0;
pub const reserved_bar_height_dip: f32 = pill_top_margin_dip + pill_height_dip;
pub const hit_tolerance_dip: f32 = 2.0;

pub const RectF = struct {
    left: f32 = 0.0,
    top: f32 = 0.0,
    right: f32 = 0.0,
    bottom: f32 = 0.0,
};

pub const RoundedBox = struct {
    rect: RectF,
    radius_x: f32 = 0.0,
    radius_y: f32 = 0.0,
};

pub fn pixelsToDip(pixels: i32, dpi: u32) f32 {
    const effective_dpi: f32 = @floatFromInt(if (dpi == 0) 96 else dpi);
    return @as(f32, @floatFromInt(pixels)) * dip_per_inch / effective_dpi;
}

pub fn dipToPixels(dip: f32, dpi: u32) i32 {
    const effective_dpi: f32 = @floatFromInt(if (dpi == 0) 96 else dpi);
    return @intFromFloat(@round(dip * effective_dpi / dip_per_inch));
}

pub fn width(rect: RectF) f32 {
    return rect.right - rect.left;
}

pub fn height(rect: RectF) f32 {
    return rect.bottom - rect.top;
}

pub fn pillBox(origin_x: f32, origin_y: f32, monitor_width_dip: f32, work_top_dip: f32) RoundedBox {
    const left = monitor_width_dip * 0.5 - pill_width_dip * 0.5 - origin_x;
    const top = work_top_dip + pill_top_margin_dip - origin_y;
    return .{
        .rect = .{
            .left = left,
            .top = top,
            .right = left + pill_width_dip,
            .bottom = top + pill_height_dip,
        },
        .radius_x = corner_radius_dip,
        .radius_y = corner_radius_dip,
    };
}

pub fn contains(box: RoundedBox, x: f32, y: f32) bool {
    const r = box.rect;
    if (x < r.left or x > r.right or y < r.top or y > r.bottom) return false;

    const rx = @min(box.radius_x, width(r) * 0.5);
    const ry = @min(box.radius_y, height(r) * 0.5);

    var dx: f32 = 0.0;
    var dy: f32 = 0.0;
    var in_corner_band = false;

    if (x < r.left + rx) {
        dx = r.left + rx - x;
        in_corner_band = true;
    } else if (x > r.right - rx) {
        dx = x - (r.right - rx);
        in_corner_band = true;
    }

    if (y < r.top + ry) {
        dy = r.top + ry - y;
    } else if (y > r.bottom - ry) {
        dy = y - (r.bottom - ry);
    } else {
        return !in_corner_band or dx <= rx;
    }

    if (!in_corner_band) return true;
    if (rx <= 0.0 or ry <= 0.0) return true;

    const nx = dx / rx;
    const ny = dy / ry;
    return nx * nx + ny * ny <= 1.0;
}

pub fn containsWithTolerance(box: RoundedBox, x: f32, y: f32, tolerance: f32) bool {
    var grown = box;
    grown.rect.left -= tolerance;
    grown.rect.top -= tolerance;
    grown.rect.right += tolerance;
    grown.rect.bottom += tolerance;
    grown.radius_x += tolerance;
    grown.radius_y += tolerance;
    return contains(grown, x, y);
}
