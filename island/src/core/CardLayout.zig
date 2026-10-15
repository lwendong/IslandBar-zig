const std = @import("std");
const Geometry = @import("Geometry");

pub const RectF = Geometry.RectF;
pub const RoundedBox = Geometry.RoundedBox;

pub const card_content_top_fraction: f32 = 0.52;
pub const card_content_bottom_fraction: f32 = 0.94;
pub const artwork_size_dip: f32 = 44;
pub const artwork_inset_dip: f32 = 14;
pub const transport_button_dip: f32 = 26;
pub const transport_gap_dip: f32 = 2;
pub const progress_bar_height_dip: f32 = 3;

pub const CardContentLayout = struct {
    content: RectF = .{},
    artwork: RectF = .{},
    text: RectF = .{},
    previous: RectF = .{},
    play_pause: RectF = .{},
    next: RectF = .{},
    progress: RectF = .{},
};

pub fn cardContentFor(card_box: RoundedBox) CardContentLayout {
    const top = card_box.rect.top + Geometry.height(card_box.rect) * card_content_top_fraction;
    const bottom = card_box.rect.top + Geometry.height(card_box.rect) * card_content_bottom_fraction;
    var layout = CardContentLayout{};
    layout.progress = .{
        .left = card_box.rect.left + artwork_inset_dip,
        .right = card_box.rect.right - artwork_inset_dip,
        .top = bottom - progress_bar_height_dip,
        .bottom = bottom,
    };
    layout.content = .{
        .left = card_box.rect.left + artwork_inset_dip,
        .right = card_box.rect.right - artwork_inset_dip,
        .top = top,
        .bottom = layout.progress.top - 4,
    };
    layout.artwork = .{
        .left = layout.content.left,
        .top = layout.content.top,
        .right = layout.content.left + artwork_size_dip,
        .bottom = layout.content.top + artwork_size_dip,
    };
    const row_width = transport_button_dip * 3 + transport_gap_dip * 2;
    const row_left = layout.content.right - row_width;
    const row_top = layout.content.top + (artwork_size_dip - transport_button_dip) * 0.5;
    const row_bottom = row_top + transport_button_dip;
    layout.previous = .{ .left = row_left, .right = row_left + transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.play_pause = .{ .left = layout.previous.right + transport_gap_dip, .right = layout.previous.right + transport_gap_dip + transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.next = .{ .left = layout.play_pause.right + transport_gap_dip, .right = layout.play_pause.right + transport_gap_dip + transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.text = .{ .left = layout.artwork.right + 10, .right = layout.previous.left - 10, .top = layout.content.top, .bottom = layout.content.bottom };
    return layout;
}

pub fn cardLeftFor(anchor_left_dip: f32, card_width_dip: f32, window_width_dip: f32) f32 {
    const margin: f32 = 8;
    var left = anchor_left_dip;
    if (left + card_width_dip > window_width_dip - margin) left = window_width_dip - margin - card_width_dip;
    if (left < margin) left = margin;
    return left;
}

pub fn smokeCheck() bool {
    if (cardLeftFor(510, 300, 520) != 212) return false;
    return true;
}
