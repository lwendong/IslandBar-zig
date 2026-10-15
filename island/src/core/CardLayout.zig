const std = @import("std");
const Geometry = @import("Geometry");
const TaskStripLayout = @import("TaskStripLayout");

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

pub const CardControl = enum(i32) { none = 0, previous, play_pause, next };
pub const CardOwner = enum(i32) { none = 0, system_panel, notification, music };

pub const tray_page_columns: i32 = 5;
pub const tray_page_cell_dip: f32 = 48;
pub const tray_page_cell_gap_dip: f32 = 6;
pub const tray_page_max_columns: i32 = 8;
pub const tray_page_min_cell_dip: f32 = 38;
pub const tray_page_max_cell_dip: f32 = 68;

pub const TrayPageLayout = struct {
    title: RectF = .{},
    cells: [TaskStripLayout.max_tray_icons]RectF = @splat(.{}),
    count: i32 = 0,
    columns: i32 = 0,
};

fn minInt(a: i32, b: i32) i32 {
    return @min(a, b);
}

fn intFloat(value: i32) f32 {
    return @floatFromInt(value);
}

pub fn trayPageFor(card: RoundedBox, icon_count_arg: i32) TrayPageLayout {
    var layout = TrayPageLayout{};
    const icon_count = @max(0, @min(icon_count_arg, @as(i32, @intCast(TaskStripLayout.max_tray_icons))));
    layout.count = icon_count;
    const card_width = Geometry.width(card.rect);
    const title_height: f32 = 34;
    layout.title = .{
        .left = card.rect.left + 16,
        .right = card.rect.right - 16,
        .top = card.rect.top + 6,
        .bottom = card.rect.top + 6 + title_height - 8,
    };
    if (icon_count == 0) return layout;

    const card_height = Geometry.height(card.rect);
    const available_width = card_width - 32;
    const available_height = card_height - title_height - 18;
    var columns = minInt(tray_page_columns, icon_count);
    var cell = tray_page_cell_dip;

    if (icon_count > 1) {
        var best_columns: i32 = 0;
        var best_cell: f32 = 0;
        var candidate = tray_page_columns;
        while (candidate <= tray_page_max_columns) : (candidate += 1) {
            const rows = @divTrunc(icon_count + candidate - 1, candidate);
            const by_width = (available_width - intFloat(candidate - 1) * tray_page_cell_gap_dip) / intFloat(candidate);
            const by_height = (available_height - intFloat(rows - 1) * tray_page_cell_gap_dip) / intFloat(rows);
            var candidate_cell = tray_page_cell_dip;
            if (by_width < candidate_cell) candidate_cell = by_width;
            if (by_height < candidate_cell) candidate_cell = by_height;

            const full_size = candidate_cell >= tray_page_cell_dip - 0.01;
            const pressable = candidate_cell >= tray_page_min_cell_dip - 0.01;
            if (full_size) {
                best_columns = candidate;
                best_cell = tray_page_cell_dip;
                break;
            }
            if (best_columns == 0 and pressable) {
                best_columns = candidate;
                best_cell = candidate_cell;
            }
            if (candidate == tray_page_max_columns and best_columns == 0) {
                best_columns = candidate;
                best_cell = candidate_cell;
            }
        }
        if (best_columns > 0) {
            columns = minInt(best_columns, icon_count);
            cell = best_cell;
        }
    }
    if (cell < 1) cell = 1;
    layout.columns = columns;

    const rows = @divTrunc(icon_count + columns - 1, columns);
    const by_width = (available_width - intFloat(columns - 1) * tray_page_cell_gap_dip) / intFloat(columns);
    const by_height = (available_height - intFloat(rows - 1) * tray_page_cell_gap_dip) / intFloat(rows);
    var grown = @min(by_width, by_height);
    if (grown > tray_page_max_cell_dip) grown = tray_page_max_cell_dip;
    if (grown > cell) cell = grown;

    const grid_width = intFloat(columns) * cell + intFloat(columns - 1) * tray_page_cell_gap_dip;
    const grid_height = intFloat(rows) * cell + intFloat(rows - 1) * tray_page_cell_gap_dip;
    const left = card.rect.left + (card_width - grid_width) * 0.5;
    const top = card.rect.top + title_height + 8 + (available_height - grid_height) * 0.5;

    for (0..@intCast(icon_count)) |index| {
        const i: i32 = @intCast(index);
        const column = @rem(i, columns);
        const row = @divTrunc(i, columns);
        const x = left + intFloat(column) * (cell + tray_page_cell_gap_dip);
        const y = top + intFloat(row) * (cell + tray_page_cell_gap_dip);
        layout.cells[index] = .{ .left = x, .top = y, .right = x + cell, .bottom = y + cell };
    }
    return layout;
}

pub fn trayPageCellAt(card: RoundedBox, icon_count: i32, x: f32, y: f32) i32 {
    const layout = trayPageFor(card, icon_count);
    for (0..@intCast(layout.count)) |index| {
        const cell = layout.cells[index];
        if (x >= cell.left and x <= cell.right and y >= cell.top and y <= cell.bottom) return @intCast(index);
    }
    return -1;
}

pub const tray_menu_width_dip: f32 = 176;
pub const tray_menu_row_dip: f32 = 30;
pub const tray_menu_pad_dip: f32 = 6;
pub const max_tray_menu_entries: usize = 6;

pub const TrayMenuAction = enum(i32) { open = 0, activate_window, open_location, close_window, quit_application, application_menu };
pub const TrayMenuFacts = struct { has_window: bool = false, has_exe_path: bool = false };
pub const TrayMenuLayout = struct {
    box: RectF = .{},
    rows: [max_tray_menu_entries]RectF = @splat(.{}),
    count: i32 = 0,
};

const label_open = [_:0]u16{ 0x6253, 0x5f00 };
const label_activate = [_:0]u16{ 0x663e, 0x793a, 0x7a97, 0x53e3 };
const label_open_location = [_:0]u16{ 0x6253, 0x5f00, 0x6587, 0x4ef6, 0x4f4d, 0x7f6e };
const label_close = [_:0]u16{ 0x5173, 0x95ed, 0x7a97, 0x53e3 };
const label_quit = [_:0]u16{ 0x7ed3, 0x675f, 0x5e94, 0x7528 };
const label_app_menu = [_:0]u16{ 0x5e94, 0x7528, 0x81ea, 0x5df1, 0x7684, 0x83dc, 0x5355, 0x2026 };
const label_quit_armed = [_:0]u16{ 0x518d, 0x70b9, 0x4e00, 0x6b21, 0xff1a, 0x7ed3, 0x675f, 0x5e94, 0x7528 };

pub fn trayMenuLabel(action: TrayMenuAction) [:0]const u16 {
    return switch (action) {
        .open => &label_open,
        .activate_window => &label_activate,
        .open_location => &label_open_location,
        .close_window => &label_close,
        .quit_application => &label_quit,
        .application_menu => &label_app_menu,
    };
}

pub fn trayMenuArmedLabel(action: TrayMenuAction) [:0]const u16 {
    return if (action == .quit_application) &label_quit_armed else trayMenuLabel(action);
}

pub fn trayMenuEntriesFor(facts: TrayMenuFacts, out: []TrayMenuAction) usize {
    if (out.len == 0) return 0;
    var count: usize = 0;
    out[count] = .open;
    count += 1;
    if (facts.has_window and count < out.len) {
        out[count] = .activate_window;
        count += 1;
    }
    if (facts.has_exe_path and count < out.len) {
        out[count] = .open_location;
        count += 1;
    }
    if (facts.has_window and count < out.len) {
        out[count] = .close_window;
        count += 1;
    }
    if (count < out.len) {
        out[count] = .quit_application;
        count += 1;
    }
    if (count < out.len) {
        out[count] = .application_menu;
        count += 1;
    }
    return count;
}

pub fn trayMenuFor(card: RoundedBox, x: f32, y: f32, entry_count_arg: i32) TrayMenuLayout {
    var layout = TrayMenuLayout{};
    const entry_count = @max(0, @min(entry_count_arg, @as(i32, @intCast(max_tray_menu_entries))));
    layout.count = entry_count;
    if (entry_count == 0) return layout;

    const height = intFloat(entry_count) * tray_menu_row_dip + tray_menu_pad_dip * 2;
    var left = x + 6;
    var top = y + 6;
    if (left + tray_menu_width_dip > card.rect.right - 4) left = x - 6 - tray_menu_width_dip;
    if (top + height > card.rect.bottom - 4) top = y - 6 - height;
    if (left < card.rect.left + 4) left = card.rect.left + 4;
    if (left + tray_menu_width_dip > card.rect.right - 4) left = card.rect.right - 4 - tray_menu_width_dip;
    if (top < card.rect.top + 4) top = card.rect.top + 4;
    if (top + height > card.rect.bottom - 4) top = card.rect.bottom - 4 - height;
    layout.box = .{ .left = left, .right = left + tray_menu_width_dip, .top = top, .bottom = top + height };
    for (0..@intCast(entry_count)) |index| {
        const row_index: f32 = @floatFromInt(index);
        const row_top = top + tray_menu_pad_dip + row_index * tray_menu_row_dip;
        layout.rows[index] = .{
            .left = left + tray_menu_pad_dip,
            .right = left + tray_menu_width_dip - tray_menu_pad_dip,
            .top = row_top,
            .bottom = row_top + tray_menu_row_dip,
        };
    }
    return layout;
}

pub fn trayMenuRowAt(layout: TrayMenuLayout, x: f32, y: f32) i32 {
    for (0..@intCast(layout.count)) |index| {
        const row = layout.rows[index];
        if (x >= row.left and x <= row.right and y >= row.top and y <= row.bottom) return @intCast(index);
    }
    return -1;
}

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

fn rectContains(rect: RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

pub fn controlAt(card_box: RoundedBox, x: f32, y: f32) CardControl {
    const layout = cardContentFor(card_box);
    if (rectContains(layout.previous, x, y)) return .previous;
    if (rectContains(layout.play_pause, x, y)) return .play_pause;
    if (rectContains(layout.next, x, y)) return .next;
    return .none;
}

pub fn hitsTransportButton(card_box: RoundedBox, x: f32, y: f32) bool {
    return controlAt(card_box, x, y) != .none;
}

pub fn lyricNeedsScroll(text_width_dip: f32, strip_width_dip: f32) bool {
    return text_width_dip > strip_width_dip - 24;
}

pub fn lyricEndFadeDip(strip_width_dip: f32) f32 {
    if (strip_width_dip <= 0) return 0;
    return @min(20, strip_width_dip * 0.25);
}

pub const music_card_pad_dip: f32 = 16;
pub const music_app_row_height_dip: f32 = 22;
pub const music_artwork_size_dip: f32 = 96;
pub const music_gap_after_art_dip: f32 = 18;
pub const music_time_row_dip: f32 = 16;
pub const music_progress_bar_dip: f32 = 4;
pub const music_app_icon_size_dip: f32 = 22;
pub const music_control_size_dip: f32 = 38;
pub const music_control_gap_dip: f32 = 32;

pub const MusicCardLayout = struct {
    art_background: RectF = .{},
    app_row: RectF = .{},
    app_icon: RectF = .{},
    app_text: RectF = .{},
    app_icon_size: f32 = 0,
    artwork: RectF = .{},
    title: RectF = .{},
    subtitle: RectF = .{},
    elapsed: RectF = .{},
    remaining: RectF = .{},
    progress: RectF = .{},
    controls: RectF = .{},
    previous: RectF = .{},
    play_pause: RectF = .{},
    next: RectF = .{},
};

pub fn cardLeftFor(anchor_left_dip: f32, card_width_dip: f32, window_width_dip: f32) f32 {
    const margin: f32 = 8;
    var left = anchor_left_dip;
    if (left + card_width_dip > window_width_dip - margin) left = window_width_dip - margin - card_width_dip;
    if (left < margin) left = margin;
    return left;
}

pub const PanelLevel = enum { tiles, sound, tray, start };

pub fn nextPanelLevel(held: PanelLevel, card_up: bool, panel_wanted: bool, tray_wanted: bool, sound_wanted: bool, start_wanted: bool) PanelLevel {
    if (!card_up) return .tiles;
    if (!panel_wanted) return held;
    if (tray_wanted) return .tray;
    if (sound_wanted) return .sound;
    if (start_wanted) return .start;
    return .tiles;
}

pub fn levelAnswersInput(showing: PanelLevel, controls: PanelLevel) bool {
    return showing == controls;
}

pub fn systemButtonShowsOpen(level: PanelLevel) bool {
    return level == .tiles or level == .sound;
}

pub fn trayButtonShowsOpen(level: PanelLevel) bool {
    return level == .tray;
}

pub fn startButtonShowsOpen(level: PanelLevel) bool {
    return level == .start;
}

pub const ControlLit = struct { system: bool = false, tray: bool = false, start: bool = false };

pub fn controlLitFor(level: PanelLevel, card_up: bool) ControlLit {
    if (!card_up) return .{};
    return .{
        .system = systemButtonShowsOpen(level),
        .tray = trayButtonShowsOpen(level),
        .start = startButtonShowsOpen(level),
    };
}

pub const start_columns: i32 = 6;
pub const start_rows: i32 = 3;
pub const start_cell_width: f32 = 76;
pub const start_cell_height: f32 = 50;
pub const start_cell_gap: f32 = 4;
pub const start_footer_dip: f32 = 46;
pub const start_avatar_dip: f32 = 28;
pub const start_power_dip: f32 = 30;
pub const start_row_height: f32 = 34;
pub const start_power_row_width: f32 = 168;

pub const StartPageLayout = struct {
    grid: RectF = .{},
    footer: RectF = .{},
    avatar: RectF = .{},
    power_button: RectF = .{},
    valid: bool = false,
};

pub fn startPageFor(card: RoundedBox) StartPageLayout {
    var layout = StartPageLayout{};
    const pad: f32 = 16;
    if (Geometry.width(card.rect) < pad * 2 + 1 or Geometry.height(card.rect) < start_footer_dip + pad * 2 + 1) return layout;

    layout.footer = .{
        .left = card.rect.left + pad,
        .right = card.rect.right - pad,
        .bottom = card.rect.bottom - pad,
        .top = card.rect.bottom - pad - start_footer_dip,
    };
    const inner_width = Geometry.width(card.rect) - pad * 2;
    const grid_width = intFloat(start_columns) * start_cell_width + intFloat(start_columns - 1) * start_cell_gap;
    layout.grid = .{
        .left = card.rect.left + pad + (inner_width - grid_width) * 0.5,
        .right = card.rect.left + pad + (inner_width - grid_width) * 0.5 + grid_width,
        .top = card.rect.top + pad,
        .bottom = layout.footer.top - 10,
    };
    const footer_center_y = (layout.footer.top + layout.footer.bottom) * 0.5;
    layout.avatar = .{
        .left = layout.footer.left,
        .right = layout.footer.left + start_avatar_dip,
        .top = footer_center_y - start_avatar_dip * 0.5,
        .bottom = footer_center_y + start_avatar_dip * 0.5,
    };
    layout.power_button = .{
        .left = layout.footer.right - start_power_dip,
        .right = layout.footer.right,
        .top = footer_center_y - start_power_dip * 0.5,
        .bottom = footer_center_y + start_power_dip * 0.5,
    };
    layout.valid = true;
    return layout;
}

pub fn startPinCapacity() i32 {
    return start_columns * start_rows;
}

pub fn startPinCellFor(layout: StartPageLayout, index: i32) RectF {
    if (!layout.valid or index < 0) return .{};
    const column = @rem(index, start_columns);
    const row = @divTrunc(index, start_columns);
    const left = layout.grid.left + intFloat(column) * (start_cell_width + start_cell_gap);
    const top = layout.grid.top + intFloat(row) * (start_cell_height + start_cell_gap);
    return .{ .left = left, .top = top, .right = left + start_cell_width, .bottom = top + start_cell_height };
}

pub fn startPickerRowFor(card: RoundedBox, row_on_screen: i32) RectF {
    const layout = startPageFor(card);
    if (!layout.valid or row_on_screen < 0) return .{};
    const top = layout.grid.top + intFloat(row_on_screen) * start_row_height;
    return .{ .left = layout.grid.left, .right = layout.grid.right, .top = top, .bottom = top + start_row_height };
}

pub fn startPowerRowFor(card: RoundedBox, index: i32) RectF {
    const layout = startPageFor(card);
    if (!layout.valid or index < 0) return .{};
    const bottom = layout.footer.top - 8 - intFloat(index) * start_row_height;
    return .{ .left = layout.power_button.right - start_power_row_width, .right = layout.power_button.right, .top = bottom - start_row_height, .bottom = bottom };
}

pub fn startRectHasPoint(rect: RectF, x: f32, y: f32) bool {
    return rectContains(rect, x, y);
}

pub fn startCardAsksForFrame(target: i32, index: i32, scroll: i32, last_target: i32, last_index: i32, last_scroll: i32) bool {
    return target != last_target or index != last_index or scroll != last_scroll;
}

pub fn startPinCellAt(layout: StartPageLayout, count_arg: i32, x: f32, y: f32) i32 {
    if (!layout.valid or !rectContains(layout.grid, x, y)) return -1;
    const column: i32 = @intFromFloat((x - layout.grid.left) / (start_cell_width + start_cell_gap));
    const row: i32 = @intFromFloat((y - layout.grid.top) / (start_cell_height + start_cell_gap));
    if (column < 0 or column >= start_columns or row < 0 or row >= start_rows) return -1;
    const index = row * start_columns + column;
    return if (index < @min(count_arg, startPinCapacity())) index else -1;
}

pub fn startPickerRowAt(card: RoundedBox, scroll_row: i32, count: i32, x: f32, y: f32) i32 {
    const layout = startPageFor(card);
    if (!layout.valid) return -1;
    const rows_on_screen: i32 = @intFromFloat((layout.grid.bottom - layout.grid.top) / start_row_height);
    var visible: i32 = 0;
    while (visible <= rows_on_screen) : (visible += 1) {
        const index = scroll_row + visible;
        if (index < 0 or index >= count) break;
        const row = startPickerRowFor(card, visible);
        if (row.bottom > layout.grid.bottom) break;
        if (rectContains(row, x, y)) return index;
    }
    return -1;
}

pub fn startPowerRowAt(card: RoundedBox, x: f32, y: f32) i32 {
    for (0..5) |index| if (rectContains(startPowerRowFor(card, @intCast(index)), x, y)) return @intCast(index);
    return -1;
}

pub const system_tile_height_dip: f32 = 46;
pub const system_tile_gap_dip: f32 = 8;
pub const system_tile_max_height_dip: f32 = 76;
pub const system_tile_columns: i32 = 3;
pub const system_tile_rows: i32 = 2;
pub const max_system_tiles: i32 = system_tile_columns * system_tile_rows;
pub const max_system_panel_tiles: i32 = 3 * max_system_tiles;

pub const SystemPanelLayout = struct {
    tiles: [max_system_tiles]RectF = @splat(.{}),
    tile_icons: [max_system_tiles]RectF = @splat(.{}),
    tile_labels: [max_system_tiles]RectF = @splat(.{}),
    sliders: [2]RectF = @splat(.{}),
    speaker_icon: RectF = .{},
    brightness_icon: RectF = .{},
    volume_button: RectF = .{},
    gear_button: RectF = .{},
    page_dots: [4]RectF = @splat(.{}),
    page_up: RectF = .{},
    page_down: RectF = .{},
    page_dot_count: i32 = 0,
    page_index: i32 = 0,
    tile_count: i32 = 0,
    slider_count: i32 = 0,
};

pub fn systemPanelFor(box: RoundedBox, tile_count_arg: i32, slider_count_arg: i32, paging: bool, page_index: i32, page_count_arg: i32) SystemPanelLayout {
    var layout = SystemPanelLayout{};
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
    layout.gear_button = .{
        .left = right - gear_size,
        .right = right,
        .top = box.rect.bottom - pad - gear_size,
        .bottom = box.rect.bottom - pad,
    };

    const slider_height: f32 = 22;
    const slider_gap: f32 = 8;
    for (0..@intCast(slider_count)) |offset| {
        const i = slider_count - 1 - @as(i32, @intCast(offset));
        const bottom = layout.gear_button.top - slider_gap - intFloat(slider_count - 1 - i) * (slider_height + slider_gap);
        layout.sliders[@intCast(i)] = .{
            .left = left + 26,
            .right = if (i == 0) right - device_button_width - 6 else right,
            .top = bottom - slider_height,
            .bottom = bottom,
        };
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

pub const SystemPanelTarget = enum { none, tile, page_up, page_down, gear, volume_device, speaker, slider };
pub const SystemPanelHit = struct { target: SystemPanelTarget = .none, index: i32 = -1, fraction: f32 = 0 };

fn validRectContains(rect: RectF, x: f32, y: f32) bool {
    return rect.right > rect.left and rect.bottom > rect.top and rectContains(rect, x, y);
}

pub fn systemPanelHitFor(card: RoundedBox, tile_count: i32, slider_count: i32, page_index: i32, page_count: i32, x: f32, y: f32) SystemPanelHit {
    var hit = SystemPanelHit{};
    const paging = page_count > 1;
    const layout = systemPanelFor(card, tile_count, slider_count, paging, page_index, page_count);
    for (0..@intCast(layout.tile_count)) |index| {
        if (validRectContains(layout.tiles[index], x, y)) return .{ .target = .tile, .index = @intCast(index) };
    }
    if (paging and validRectContains(layout.page_up, x, y)) return .{ .target = .page_up };
    if (paging and validRectContains(layout.page_down, x, y)) return .{ .target = .page_down };
    if (validRectContains(layout.volume_button, x, y)) return .{ .target = .volume_device };
    if (validRectContains(layout.speaker_icon, x, y)) return .{ .target = .speaker };
    for (0..@intCast(layout.slider_count)) |index| {
        const track = layout.sliders[index];
        if (x >= track.left and x <= track.right and y >= track.top and y <= track.bottom) {
            const width = track.right - track.left;
            const fraction = if (width > 0) @max(0, @min(1, (x - track.left) / width)) else 0;
            return .{ .target = .slider, .index = @intCast(index), .fraction = fraction };
        }
    }
    if (validRectContains(layout.gear_button, x, y)) hit.target = .gear;
    return hit;
}

pub fn systemTileAt(card: RoundedBox, tile_count: i32, x: f32, y: f32) i32 {
    const hit = systemPanelHitFor(card, tile_count, 1, 0, 1, x, y);
    return if (hit.target == .tile) hit.index else -1;
}

pub const max_sound_devices: usize = 8;
pub const max_sound_sessions: usize = 10;
pub const sound_spatial_rows: usize = 2;
pub const max_sound_mix_rows: usize = max_sound_sessions + 1;
pub const sound_header_height_dip: f32 = 40;
pub const sound_footer_height_dip: f32 = 34;
pub const sound_section_height_dip: f32 = 28;
pub const sound_device_row_height_dip: f32 = 40;
pub const sound_spatial_row_height_dip: f32 = 34;
pub const sound_mixer_row_height_dip: f32 = 36;
pub const sound_indent_dip: f32 = 14;

pub const SoundPageLayout = struct {
    back_button: RectF = .{},
    title: RectF = .{},
    header_rule: RectF = .{},
    device_label: RectF = .{},
    device_rows: [max_sound_devices]RectF = @splat(.{}),
    device_icons: [max_sound_devices]RectF = @splat(.{}),
    device_labels: [max_sound_devices]RectF = @splat(.{}),
    device_marks: [max_sound_devices]RectF = @splat(.{}),
    spatial_label: RectF = .{},
    spatial_rows: [sound_spatial_rows]RectF = @splat(.{}),
    spatial_marks: [sound_spatial_rows]RectF = @splat(.{}),
    spatial_labels: [sound_spatial_rows]RectF = @splat(.{}),
    mixer_label: RectF = .{},
    mixer_gear: RectF = .{},
    mixer_rows: [max_sound_mix_rows]RectF = @splat(.{}),
    mixer_icons: [max_sound_mix_rows]RectF = @splat(.{}),
    mixer_tracks: [max_sound_mix_rows]RectF = @splat(.{}),
    footer: RectF = .{},
    footer_rule: RectF = .{},
    scroll_track: RectF = .{},
    scroll_thumb: RectF = .{},
    viewport: RectF = .{},
    device_count: i32 = 0,
    session_count: i32 = 0,
    content_height: f32 = 0,
    scroll: f32 = 0,
};

fn shiftRect(rect: *RectF, distance: f32) void {
    rect.top -= distance;
    rect.bottom -= distance;
}

pub fn soundPageFor(card: RoundedBox, device_count_arg: i32, mixer_row_count_arg: i32, scroll_arg: f32) SoundPageLayout {
    var layout = SoundPageLayout{};
    const device_count = @max(0, @min(device_count_arg, @as(i32, @intCast(max_sound_devices))));
    const mixer_row_count = @max(0, @min(mixer_row_count_arg, @as(i32, @intCast(max_sound_mix_rows))));
    layout.device_count = device_count;
    layout.session_count = mixer_row_count;

    const left = card.rect.left + sound_indent_dip;
    const right = card.rect.right - sound_indent_dip;
    layout.header_rule = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.top + sound_header_height_dip - 1, .bottom = card.rect.top + sound_header_height_dip };
    const back_size: f32 = 26;
    const header_centre = card.rect.top + (sound_header_height_dip - 1) * 0.5;
    layout.back_button = .{ .left = left, .right = left + back_size, .top = header_centre - back_size * 0.5, .bottom = header_centre + back_size * 0.5 };
    layout.title = .{ .left = left + back_size + 8, .right = right, .top = card.rect.top + 2, .bottom = card.rect.top + sound_header_height_dip - 3 };
    layout.footer_rule = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.bottom - sound_footer_height_dip, .bottom = card.rect.bottom - sound_footer_height_dip + 1 };
    layout.footer = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.bottom - sound_footer_height_dip, .bottom = card.rect.bottom };
    layout.viewport = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.top + sound_header_height_dip, .bottom = card.rect.bottom - sound_footer_height_dip };

    const content_top = layout.viewport.top;
    const content_right = right - 6;
    var y = content_top;
    layout.device_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + sound_section_height_dip };
    y += sound_section_height_dip;
    for (0..@intCast(device_count)) |index| {
        const row = RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + sound_device_row_height_dip };
        layout.device_rows[index] = row;
        layout.device_marks[index] = .{ .left = card.rect.left + 3, .right = card.rect.left + 6, .top = y + 9, .bottom = y + sound_device_row_height_dip - 9 };
        const icon_side: f32 = 20;
        const row_centre = (row.top + row.bottom) * 0.5;
        layout.device_icons[index] = .{ .left = left + 8, .right = left + 8 + icon_side, .top = row_centre - icon_side * 0.5, .bottom = row_centre + icon_side * 0.5 };
        layout.device_labels[index] = .{ .left = left + 8 + icon_side + 10, .right = content_right, .top = row.top, .bottom = row.bottom };
        y += sound_device_row_height_dip;
    }
    layout.spatial_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + sound_section_height_dip };
    y += sound_section_height_dip;
    for (0..sound_spatial_rows) |index| {
        const row = RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + sound_spatial_row_height_dip };
        layout.spatial_rows[index] = row;
        layout.spatial_marks[index] = .{ .left = card.rect.left + 3, .right = card.rect.left + 6, .top = y + 7, .bottom = y + sound_spatial_row_height_dip - 7 };
        layout.spatial_labels[index] = .{ .left = left + 8, .right = content_right, .top = row.top, .bottom = row.bottom };
        y += sound_spatial_row_height_dip;
    }
    layout.mixer_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + sound_section_height_dip };
    const gear_side: f32 = 20;
    layout.mixer_gear = .{ .left = content_right - gear_side, .right = content_right, .top = y + (sound_section_height_dip - gear_side) * 0.5, .bottom = y + (sound_section_height_dip + gear_side) * 0.5 };
    y += sound_section_height_dip;
    for (0..@intCast(mixer_row_count)) |index| {
        const row = RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + sound_mixer_row_height_dip };
        layout.mixer_rows[index] = row;
        const icon_side: f32 = 22;
        const row_centre = (row.top + row.bottom) * 0.5;
        layout.mixer_icons[index] = .{ .left = left + 6, .right = left + 6 + icon_side, .top = row_centre - icon_side * 0.5, .bottom = row_centre + icon_side * 0.5 };
        layout.mixer_tracks[index] = .{ .left = left + 6 + icon_side + 14, .right = content_right, .top = y, .bottom = y + sound_mixer_row_height_dip };
        y += sound_mixer_row_height_dip;
    }
    layout.content_height = y - content_top;

    const viewport_height = layout.viewport.bottom - layout.viewport.top;
    const limit = @max(0, layout.content_height - viewport_height);
    const scroll = @max(0, @min(scroll_arg, limit));
    layout.scroll = scroll;
    if (scroll != 0) {
        shiftRect(&layout.device_label, scroll);
        for (0..@intCast(device_count)) |index| {
            shiftRect(&layout.device_rows[index], scroll);
            shiftRect(&layout.device_icons[index], scroll);
            shiftRect(&layout.device_labels[index], scroll);
            shiftRect(&layout.device_marks[index], scroll);
        }
        shiftRect(&layout.spatial_label, scroll);
        for (0..sound_spatial_rows) |index| {
            shiftRect(&layout.spatial_rows[index], scroll);
            shiftRect(&layout.spatial_marks[index], scroll);
            shiftRect(&layout.spatial_labels[index], scroll);
        }
        shiftRect(&layout.mixer_label, scroll);
        shiftRect(&layout.mixer_gear, scroll);
        for (0..@intCast(mixer_row_count)) |index| {
            shiftRect(&layout.mixer_rows[index], scroll);
            shiftRect(&layout.mixer_icons[index], scroll);
            shiftRect(&layout.mixer_tracks[index], scroll);
        }
    }

    const bar_width: f32 = 3;
    layout.scroll_track = .{ .left = card.rect.right - 6, .right = card.rect.right - 6 + bar_width, .top = layout.viewport.top, .bottom = layout.viewport.bottom };
    const track_height = layout.scroll_track.bottom - layout.scroll_track.top;
    const fraction = if (layout.content_height > 0) viewport_height / layout.content_height else 1;
    var thumb_height = track_height * @min(fraction, 1);
    if (thumb_height < 28) thumb_height = 28;
    if (thumb_height > track_height) thumb_height = track_height;
    const travel = track_height - thumb_height;
    const position = if (limit > 0) (layout.scroll / limit) * travel else 0;
    layout.scroll_thumb = .{ .left = layout.scroll_track.left, .right = layout.scroll_track.right, .top = layout.scroll_track.top + position, .bottom = layout.scroll_track.top + position + thumb_height };
    return layout;
}

pub fn soundPageScrollLimit(card: RoundedBox, device_count: i32, mixer_row_count: i32) f32 {
    const probe = soundPageFor(card, device_count, mixer_row_count, 0);
    return @max(0, probe.content_height - Geometry.height(probe.viewport));
}

pub const SoundPageTarget = enum { none, back, device, spatial, mixer_slider, mixer_gear, footer, scrollbar };
pub const SoundPageHit = struct { target: SoundPageTarget = .none, index: i32 = -1, fraction: f32 = 0 };

pub fn soundPageHitFor(card: RoundedBox, device_count: i32, mixer_row_count: i32, scroll: f32, x: f32, y: f32) SoundPageHit {
    const layout = soundPageFor(card, device_count, mixer_row_count, scroll);
    if (validRectContains(layout.back_button, x, y)) return .{ .target = .back };
    if (validRectContains(layout.footer, x, y)) return .{ .target = .footer };
    if (validRectContains(layout.mixer_gear, x, y)) return .{ .target = .mixer_gear };
    if (validRectContains(layout.scroll_track, x, y)) return .{ .target = .scrollbar };
    const view = layout.viewport;
    if (x < view.left or x > view.right or y < view.top or y > view.bottom) return .{};
    for (0..@intCast(layout.device_count)) |index| if (validRectContains(layout.device_rows[index], x, y)) return .{ .target = .device, .index = @intCast(index) };
    for (0..sound_spatial_rows) |index| if (validRectContains(layout.spatial_rows[index], x, y)) return .{ .target = .spatial, .index = @intCast(index) };
    for (0..@intCast(layout.session_count)) |index| {
        const track = layout.mixer_tracks[index];
        if (validRectContains(track, x, y)) {
            const width = track.right - track.left;
            return .{ .target = .mixer_slider, .index = @intCast(index), .fraction = if (width > 0) @max(0, @min(1, (x - track.left) / width)) else 0 };
        }
    }
    return .{};
}

pub fn musicCardFor(box: RoundedBox) MusicCardLayout {
    var layout = MusicCardLayout{};
    const pad = music_card_pad_dip;
    layout.art_background = box.rect;
    const bottom = box.rect.bottom - pad;
    layout.controls = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = bottom - music_control_size_dip, .bottom = bottom };
    layout.progress = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = layout.controls.top - 10 - music_progress_bar_dip, .bottom = layout.controls.top - 10 };
    layout.elapsed = .{ .left = layout.progress.left, .right = layout.progress.left + 56, .top = layout.progress.top - 4 - music_time_row_dip, .bottom = layout.progress.top - 4 };
    layout.remaining = .{ .left = layout.progress.right - 56, .right = layout.progress.right, .top = layout.elapsed.top, .bottom = layout.elapsed.bottom };
    layout.app_row = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = box.rect.top + pad, .bottom = box.rect.top + pad + music_app_row_height_dip };
    const row_centre_y = (layout.app_row.top + layout.app_row.bottom) * 0.5;
    layout.app_icon_size = music_app_icon_size_dip;
    layout.app_icon = .{ .left = layout.app_row.left, .right = layout.app_row.left + layout.app_icon_size, .top = row_centre_y - layout.app_icon_size * 0.5, .bottom = row_centre_y + layout.app_icon_size * 0.5 };
    layout.app_text = .{ .left = layout.app_icon.right + 10, .right = layout.app_row.right, .top = layout.app_row.top, .bottom = layout.app_row.bottom };
    layout.artwork = .{ .left = box.rect.left + pad, .right = box.rect.left + pad + music_artwork_size_dip, .top = layout.app_row.bottom + 8, .bottom = layout.app_row.bottom + 8 + music_artwork_size_dip };
    layout.title = .{ .left = layout.artwork.right + music_gap_after_art_dip, .right = box.rect.right - pad, .top = layout.artwork.top + 16, .bottom = layout.artwork.top + 44 };
    layout.subtitle = .{ .left = layout.title.left, .right = layout.title.right, .top = layout.title.bottom + 2, .bottom = layout.title.bottom + 22 };
    const group_width = music_control_size_dip * 3 + music_control_gap_dip * 2;
    const group_left = (box.rect.left + box.rect.right) * 0.5 - group_width * 0.5;
    layout.previous = .{ .left = group_left, .right = group_left + music_control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    layout.play_pause = .{ .left = layout.previous.right + music_control_gap_dip, .right = layout.previous.right + music_control_gap_dip + music_control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    layout.next = .{ .left = layout.play_pause.right + music_control_gap_dip, .right = layout.play_pause.right + music_control_gap_dip + music_control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    return layout;
}

pub fn musicControlAt(box: RoundedBox, x: f32, y: f32) CardControl {
    const layout = musicCardFor(box);
    if (rectContains(layout.previous, x, y)) return .previous;
    if (rectContains(layout.play_pause, x, y)) return .play_pause;
    if (rectContains(layout.next, x, y)) return .next;
    return .none;
}

pub fn smokeCheck() bool {
    const card = RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    const tray = trayPageFor(card, 16);
    if (tray.count != 16 or tray.columns < 5 or tray.columns > tray_page_max_columns) return false;
    for (tray.cells[0..16]) |cell| {
        if (cell.left < card.rect.left or cell.right > card.rect.right or cell.top < card.rect.top or cell.bottom > card.rect.bottom) return false;
    }
    var actions: [max_tray_menu_entries]TrayMenuAction = undefined;
    const action_count = trayMenuEntriesFor(.{ .has_window = true, .has_exe_path = true }, &actions);
    if (action_count != 6 or actions[5] != .application_menu) return false;
    const menu = trayMenuFor(card, 500, 260, @intCast(action_count));
    if (menu.count != 6 or trayMenuRowAt(menu, menu.rows[5].left + 1, menu.rows[5].top + 1) != 5) return false;
    if (!hitsTransportButton(card, cardContentFor(card).play_pause.left + 1, cardContentFor(card).play_pause.top + 1)) return false;
    if (!lyricNeedsScroll(300, 268) or lyricEndFadeDip(40) != 10) return false;
    if (trayMenuLabel(.open).len == 0 or trayMenuArmedLabel(.quit_application).len == trayMenuLabel(.quit_application).len) return false;
    if (cardLeftFor(510, 300, 520) != 212) return false;
    if (nextPanelLevel(.tray, true, false, false, false, false) != .tray or nextPanelLevel(.tray, false, true, false, false, false) != .tiles) return false;
    if (!levelAnswersInput(.sound, .sound) or levelAnswersInput(.sound, .tray)) return false;
    const lit = controlLitFor(.start, true);
    if (lit.system or lit.tray or !lit.start or controlLitFor(.tiles, false).system) return false;

    const start = startPageFor(card);
    if (!start.valid or startPinCapacity() != 18) return false;
    const pin = startPinCellFor(start, 0);
    if (!rectContains(pin, pin.left + 1, pin.top + 1) or startPinCellAt(start, 18, pin.left + 1, pin.top + 1) != 0) return false;
    if (!rectContains(startPickerRowFor(card, 0), startPickerRowFor(card, 0).left + 1, startPickerRowFor(card, 0).top + 1)) return false;
    if (startPickerRowAt(card, 2, 10, start.grid.left + 2, start.grid.top + 2) != 2) return false;
    if (!rectContains(startPowerRowFor(card, 0), startPowerRowFor(card, 0).left + 1, startPowerRowFor(card, 0).top + 1) or startPowerRowAt(card, startPowerRowFor(card, 0).left + 1, startPowerRowFor(card, 0).top + 1) != 0) return false;
    if (!startCardAsksForFrame(1, 2, 3, 1, 2, 2) or startCardAsksForFrame(1, 2, 3, 1, 2, 3)) return false;

    const panel = systemPanelFor(card, 6, 2, true, 0, 3);
    if (panel.tile_count != 6 or panel.slider_count != 2 or panel.page_dot_count != 3) return false;
    const tile_hit = systemPanelHitFor(card, 6, 2, 0, 3, panel.tiles[0].left + 1, panel.tiles[0].top + 1);
    if (tile_hit.target != .tile or tile_hit.index != 0 or systemTileAt(card, 6, panel.tiles[0].left + 1, panel.tiles[0].top + 1) != 0) return false;
    const slider_hit = systemPanelHitFor(card, 6, 2, 0, 1, panel.sliders[0].left + Geometry.width(panel.sliders[0]) * 0.5, (panel.sliders[0].top + panel.sliders[0].bottom) * 0.5);
    if (slider_hit.target != .slider or slider_hit.index != 0 or @abs(slider_hit.fraction - 0.5) > 0.01) return false;

    const sound = soundPageFor(card, 2, 4, 1_000);
    if (sound.device_count != 2 or sound.session_count != 4 or sound.scroll != soundPageScrollLimit(card, 2, 4) or sound.scroll <= 0) return false;
    if (soundPageHitFor(card, 2, 4, 0, sound.back_button.left + 1, sound.back_button.top + 1).target != .back) return false;
    const sound_at_top = soundPageFor(card, 2, 4, 0);
    const mix_track = sound_at_top.mixer_tracks[0];
    const mix_hit = soundPageHitFor(card, 2, 4, 80, (mix_track.left + mix_track.right) * 0.5, (mix_track.top + mix_track.bottom) * 0.5 - 80);
    if (mix_hit.target != .mixer_slider or mix_hit.index != 0 or @abs(mix_hit.fraction - 0.5) > 0.01) return false;

    const music = musicCardFor(card);
    if (music.artwork.right - music.artwork.left != music_artwork_size_dip or musicControlAt(card, music.play_pause.left + 1, music.play_pause.top + 1) != .play_pause) return false;
    return true;
}
