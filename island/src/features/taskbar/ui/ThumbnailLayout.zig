const Contract = @import("ThumbnailContract");

pub const max_width_dip: f32 = 260;
pub const max_height_dip: f32 = 160;
pub const gap_dip: f32 = 10;
pub const pad_dip: f32 = 8;
pub const title_dip: f32 = 22;
pub const radius_dip: f32 = 12;

pub const Rect = Contract.Rect;
pub const Placement = Contract.Placement;

fn roundPixel(value: f32) i32 {
    return @intFromFloat(@round(value));
}

/// Places the aspect-preserving DWM image card within the monitor bounds.
pub fn thumbnailBoxFor(source_width_px: i32, source_height_px: i32, icon_box_px: Rect, monitor_px: Rect, scale_arg: f32) Placement {
    var placement = Placement{};
    const scale = if (scale_arg <= 0) 1 else scale_arg;
    const slot_width = max_width_dip * scale;
    const slot_height = max_height_dip * scale;
    const pad = pad_dip * scale;
    const title = title_dip * scale;
    const card_width = slot_width + pad * 2;
    const card_height = slot_height + pad * 2 + title;
    var width = slot_width;
    var height = slot_height;
    if (source_width_px > 0 and source_height_px > 0) {
        const aspect = @as(f32, @floatFromInt(source_width_px)) / @as(f32, @floatFromInt(source_height_px));
        width = slot_width;
        height = width / aspect;
        if (height > slot_height) {
            height = slot_height;
            width = height * aspect;
        }
        if (width < 1) width = 1;
        if (height < 1) height = 1;
    }
    const center_x = (@as(f32, @floatFromInt(icon_box_px.left)) + @as(f32, @floatFromInt(icon_box_px.right))) * 0.5;
    var left = center_x - card_width * 0.5;
    var top = @as(f32, @floatFromInt(icon_box_px.bottom)) + gap_dip * scale;
    const monitor_left: f32 = @floatFromInt(monitor_px.left);
    const monitor_right: f32 = @floatFromInt(monitor_px.right);
    const monitor_top: f32 = @floatFromInt(monitor_px.top);
    const monitor_bottom: f32 = @floatFromInt(monitor_px.bottom);
    if (left + card_width > monitor_right) left = monitor_right - card_width;
    if (left < monitor_left) left = monitor_left;
    if (top + card_height > monitor_bottom) top = monitor_bottom - card_height;
    if (top < monitor_top) top = monitor_top;
    placement.card = .{
        .left = @intFromFloat(left),
        .top = @intFromFloat(top),
        .right = @intFromFloat(left + card_width),
        .bottom = @intFromFloat(top + card_height),
    };
    const slot_left = @as(f32, @floatFromInt(placement.card.left)) + pad;
    const slot_top = @as(f32, @floatFromInt(placement.card.top)) + pad + title;
    placement.picture.left = roundPixel(slot_left + (slot_width - width) * 0.5);
    placement.picture.top = roundPixel(slot_top + (slot_height - height) * 0.5);
    placement.picture.right = placement.picture.left + roundPixel(width);
    placement.picture.bottom = placement.picture.top + roundPixel(height);
    placement.valid = placement.card.right > placement.card.left and placement.card.bottom > placement.card.top and placement.picture.right > placement.picture.left and placement.picture.bottom > placement.picture.top;
    return placement;
}

pub fn smokeCheck() bool {
    const icon = Rect{ .left = 900, .top = 20, .right = 924, .bottom = 44 };
    const monitor = Rect{ .left = 0, .top = 0, .right = 1920, .bottom = 1080 };
    const preview = thumbnailBoxFor(1920, 1080, icon, monitor, 1);
    if (!preview.valid) return false;
    if (preview.card.right - preview.card.left != 276 or preview.card.bottom - preview.card.top != 198) return false;
    const image_width = preview.picture.right - preview.picture.left;
    const image_height = preview.picture.bottom - preview.picture.top;
    if (@abs(@as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height)) - 16.0 / 9.0) > 0.02) return false;
    if (preview.card.left < monitor.left or preview.card.right > monitor.right) return false;
    const edge = thumbnailBoxFor(1, 9000, .{ .left = 0, .top = 0, .right = 16, .bottom = 20 }, monitor, 1);
    if (!edge.valid or edge.picture.right <= edge.picture.left) return false;
    return thumbnailBoxFor(640, 480, icon, monitor, 0).valid;
}

test "thumbnail layout preserves aspect ratio and monitor bounds" {
    try @import("std").testing.expect(smokeCheck());
}
