const Geometry = @import("Geometry");
const Presentation = @import("SystemPanelPresentation");

pub const system_tile_gap_dip: f32 = 8;
pub const system_tile_max_height_dip: f32 = 76;
pub const system_tile_columns: i32 = 3;
pub const system_tile_rows: i32 = 2;
pub const max_system_tiles: i32 = system_tile_columns * system_tile_rows;
pub const max_system_panel_tiles: i32 = 3 * max_system_tiles;

pub const Target = enum { none, tile, page_up, page_down, gear, volume_device, speaker, slider };
pub const Hit = struct { target: Target = .none, index: i32 = -1, fraction: f32 = 0 };
pub const Panel = Presentation.Layout;

fn intFloat(value: i32) f32 {
    return @floatFromInt(value);
}

fn rectContains(rect: Geometry.RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

fn validRectContains(rect: Geometry.RectF, x: f32, y: f32) bool {
    return rect.right > rect.left and rect.bottom > rect.top and rectContains(rect, x, y);
}

pub fn systemPanelFor(box: Geometry.RoundedBox, tile_count_arg: i32, slider_count_arg: i32, paging: bool, page_index: i32, page_count_arg: i32) Panel {
    var layout = Panel{};
    const tile_count = @max(0, @min(tile_count_arg, max_system_tiles));
    const slider_count = @max(0, @min(slider_count_arg, 2));
    layout.tile_count = tile_count;
    layout.slider_count = slider_count;

    const pad: f32 = 14;
    const left = box.rect.left + pad;
    const right = box.rect.right - pad;
    const paging_width: f32 = if (paging) 20 else 0;
    const grid_right = right - paging_width;
    const inner_width = grid_right - left;
    const device_button_width: f32 = 40;
    const gear_size: f32 = 28;
    layout.gear_button = .{ .left = right - gear_size, .right = right, .top = box.rect.bottom - pad - gear_size, .bottom = box.rect.bottom - pad };

    const slider_height: f32 = 22;
    const slider_gap: f32 = 8;
    for (0..@intCast(slider_count)) |offset| {
        const i = slider_count - 1 - @as(i32, @intCast(offset));
        const bottom = layout.gear_button.top - slider_gap - intFloat(slider_count - 1 - i) * (slider_height + slider_gap);
        layout.sliders[@intCast(i)] = .{ .left = left + 26, .right = if (i == 0) right - device_button_width - 6 else right, .top = bottom - slider_height, .bottom = bottom };
    }

    if (slider_count > 0) {
        const centre_y = (layout.sliders[0].top + layout.sliders[0].bottom) * 0.5;
        layout.speaker_icon = .{ .left = left, .right = left + 20, .top = centre_y - 10, .bottom = centre_y + 10 };
        layout.volume_button = .{ .left = right - device_button_width, .right = right, .top = centre_y - 12, .bottom = centre_y + 12 };
    }
    if (slider_count > 1) {
        const centre_y = (layout.sliders[1].top + layout.sliders[1].bottom) * 0.5;
        layout.brightness_icon = .{ .left = left, .right = left + 20, .top = centre_y - 10, .bottom = centre_y + 10 };
    }

    const rows = @divTrunc(tile_count + system_tile_columns - 1, system_tile_columns);
    if (rows > 0) {
        const grid_bottom = (if (slider_count > 0) layout.sliders[0].top else layout.gear_button.top) - 10;
        const grid_top = box.rect.top + pad;
        const available = grid_bottom - grid_top;
        if (paging) {
            const centre_y = (grid_top + grid_bottom) * 0.5;
            const dot_radius: f32 = 2.5;
            const dot_gap: f32 = 9;
            const page_count = @max(0, page_count_arg);
            const dots = @min(page_count, 4);
            layout.page_dot_count = dots;
            layout.page_index = page_index;
            const dots_top = centre_y - (intFloat(dots - 1) * dot_gap) * 0.5;
            const column_centre_x = grid_right + paging_width * 0.5;
            for (0..@intCast(dots)) |index| {
                const cy = dots_top + @as(f32, @floatFromInt(index)) * dot_gap;
                layout.page_dots[index] = .{ .left = column_centre_x - dot_radius, .right = column_centre_x + dot_radius, .top = cy - dot_radius, .bottom = cy + dot_radius };
            }
            const arrow: f32 = 14;
            layout.page_up = .{ .left = column_centre_x - arrow * 0.5, .right = column_centre_x + arrow * 0.5, .top = dots_top - 6 - arrow, .bottom = dots_top - 6 };
            layout.page_down = .{ .left = layout.page_up.left, .right = layout.page_up.right, .top = dots_top + intFloat(dots - 1) * dot_gap + 6, .bottom = dots_top + intFloat(dots - 1) * dot_gap + 6 + arrow };
        }
        var tile_height = (available - intFloat(rows - 1) * system_tile_gap_dip) / intFloat(rows);
        if (tile_height < 20) tile_height = 20;
        if (tile_height > system_tile_max_height_dip) tile_height = system_tile_max_height_dip;
        const tile_width = (inner_width - intFloat(system_tile_columns - 1) * system_tile_gap_dip) / intFloat(system_tile_columns);
        const caption_height: f32 = 18;
        const caption_gap: f32 = 5;
        const box_height = tile_height - caption_height - caption_gap;
        for (0..@intCast(tile_count)) |index| {
            const i32_index: i32 = @intCast(index);
            const row = @divTrunc(i32_index, system_tile_columns);
            const column = @rem(i32_index, system_tile_columns);
            const tile_left = left + intFloat(column) * (tile_width + system_tile_gap_dip);
            const slot_top = grid_top + intFloat(row) * (tile_height + system_tile_gap_dip);
            layout.tiles[index] = .{ .left = tile_left, .right = tile_left + tile_width, .top = slot_top, .bottom = slot_top + box_height };
            const glyph_size: f32 = 20;
            const box_centre_y = (layout.tiles[index].top + layout.tiles[index].bottom) * 0.5;
            layout.tile_icons[index] = .{ .left = tile_left + 12, .right = tile_left + 12 + glyph_size, .top = box_centre_y - glyph_size * 0.5, .bottom = box_centre_y + glyph_size * 0.5 };
            layout.tile_labels[index] = .{ .left = tile_left, .right = tile_left + tile_width, .top = layout.tiles[index].bottom + caption_gap, .bottom = slot_top + tile_height };
        }
    }
    return layout;
}

pub fn hitFor(layout: Panel, x: f32, y: f32) Hit {
    for (0..@intCast(layout.tile_count)) |index| if (validRectContains(layout.tiles[index], x, y)) return .{ .target = .tile, .index = @intCast(index) };
    const paging = layout.page_dot_count > 0;
    if (paging and validRectContains(layout.page_up, x, y)) return .{ .target = .page_up };
    if (paging and validRectContains(layout.page_down, x, y)) return .{ .target = .page_down };
    if (validRectContains(layout.volume_button, x, y)) return .{ .target = .volume_device };
    if (validRectContains(layout.speaker_icon, x, y)) return .{ .target = .speaker };
    for (0..@intCast(layout.slider_count)) |index| {
        const track = layout.sliders[index];
        if (x >= track.left and x <= track.right and y >= track.top and y <= track.bottom) {
            const width = track.right - track.left;
            return .{ .target = .slider, .index = @intCast(index), .fraction = if (width > 0) @max(0, @min(1, (x - track.left) / width)) else 0 };
        }
    }
    return if (validRectContains(layout.gear_button, x, y)) .{ .target = .gear } else .{};
}

test "system panel layout and hit geometry share tile and slider bounds" {
    const card = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    const panel = systemPanelFor(card, 6, 2, true, 0, 3);
    try @import("std").testing.expectEqual(@as(i32, 6), panel.tile_count);
    try @import("std").testing.expectEqual(@as(i32, 2), panel.slider_count);
    try @import("std").testing.expectEqual(@as(i32, 3), panel.page_dot_count);
    const tile = hitFor(panel, panel.tiles[0].left + 1, panel.tiles[0].top + 1);
    try @import("std").testing.expect(tile.target == .tile and tile.index == 0);
    const track = panel.sliders[0];
    const slider = hitFor(panel, track.left + Geometry.width(track) * 0.5, (track.top + track.bottom) * 0.5);
    try @import("std").testing.expect(slider.target == .slider and slider.index == 0);
    try @import("std").testing.expectApproxEqAbs(@as(f32, 0.5), slider.fraction, 0.01);
    const gap = hitFor(panel, panel.tiles[0].right + 2, panel.tiles[0].top + 1);
    try @import("std").testing.expect(gap.target == .none);
}
