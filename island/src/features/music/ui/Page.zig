const std = @import("std");
const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const TextRenderer = @import("TextRenderer");
const ThemeTokens = @import("ThemeTokens");

pub const CardControl = enum(i32) { none = 0, previous, play_pause, next };
pub const Action = enum { previous, play_pause, next };

pub const compact_card_content_top_fraction: f32 = 0.52;
pub const compact_card_content_bottom_fraction: f32 = 0.94;
pub const compact_artwork_size_dip: f32 = 44;
pub const compact_artwork_inset_dip: f32 = 14;
pub const compact_transport_button_dip: f32 = 26;
pub const compact_transport_gap_dip: f32 = 2;
pub const compact_progress_bar_height_dip: f32 = 3;

pub const card_pad_dip: f32 = 16;
pub const app_row_height_dip: f32 = 22;
pub const artwork_size_dip: f32 = 96;
pub const gap_after_art_dip: f32 = 18;
pub const time_row_dip: f32 = 16;
pub const progress_bar_dip: f32 = 4;
pub const app_icon_size_dip: f32 = 22;
pub const control_size_dip: f32 = 38;
pub const control_gap_dip: f32 = 32;

pub const CompactLayout = struct {
    content: Geometry.RectF = .{},
    artwork: Geometry.RectF = .{},
    text: Geometry.RectF = .{},
    previous: Geometry.RectF = .{},
    play_pause: Geometry.RectF = .{},
    next: Geometry.RectF = .{},
    progress: Geometry.RectF = .{},
};

pub const CardLayout = struct {
    art_background: Geometry.RectF = .{},
    app_row: Geometry.RectF = .{},
    app_icon: Geometry.RectF = .{},
    app_text: Geometry.RectF = .{},
    app_icon_size: f32 = 0,
    artwork: Geometry.RectF = .{},
    title: Geometry.RectF = .{},
    subtitle: Geometry.RectF = .{},
    elapsed: Geometry.RectF = .{},
    remaining: Geometry.RectF = .{},
    progress: Geometry.RectF = .{},
    controls: Geometry.RectF = .{},
    previous: Geometry.RectF = .{},
    play_pause: Geometry.RectF = .{},
    next: Geometry.RectF = .{},
};

pub const Point = struct { x_px: i32, y_px: i32 };

/// Immutable visual data assembled from Music state and platform snapshots.
/// The Feature UI owns the model and layout; TextRenderer receives only the
/// generic media-card drawing data and resolved geometry.
pub const CardText = struct {
    title: []const u8 = &.{},
    artist: []const u8 = &.{},
    album: []const u8 = &.{},
    app: []const u8 = &.{},
    playing: bool = false,
    position_ms: i64 = 0,
    duration_ms: i64 = 0,
    progress_fraction: f32 = 0,
    artwork_png: []const u8 = &.{},
    artwork_revision: u64 = 0,
    background_png: []const u8 = &.{},
    background_revision: u64 = 0,
    app_icon_png: []const u8 = &.{},
    app_icon_revision: u64 = 0,
};

pub const StripText = struct {
    line: []const u8 = &.{},
    previous_line: []const u8 = &.{},
    scroll_dip: f32 = 0,
    previous_scroll_dip: f32 = 0,
    line_roll: f32 = 1,
    wave_phase: f32 = 0,
    level: f32 = 0,
    level_known: bool = false,
    accent: ThemeTokens.Color = .{ .r = 0.40, .g = 0.80, .b = 0.95, .a = 1 },
};

pub fn drawCard(backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: Geometry.RoundedBox, card: *const CardText, opacity: f32) bool {
    const content = TextRenderer.MediaCardContent{
        .title = card.title,
        .artist = card.artist,
        .album = card.album,
        .app = card.app,
        .playing = card.playing,
        .position_ms = card.position_ms,
        .duration_ms = card.duration_ms,
        .progress_fraction = card.progress_fraction,
        .artwork_png = card.artwork_png,
        .artwork_revision = card.artwork_revision,
        .background_png = card.background_png,
        .background_revision = card.background_revision,
        .app_icon_png = card.app_icon_png,
        .app_icon_revision = card.app_icon_revision,
    };
    return backend.drawMediaCard(draw_context, box, rendererLayout(layoutFor(box)), &content, opacity);
}

pub fn drawStrip(backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: Geometry.RoundedBox, strip: *const StripText, opacity: f32) bool {
    if (strip.level_known) backend.drawAudioWave(draw_context, box, strip.wave_phase, strip.level, strip.accent, opacity);
    if (strip.line.len == 0) return true;
    return backend.drawScrollingLine(draw_context, box, strip.line, strip.scroll_dip, opacity, strip.line_roll, strip.previous_line, strip.previous_scroll_dip);
}

pub fn paintCard(raw_context: ?*anyopaque, backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: *const Geometry.RoundedBox, opacity: f32, _: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    const raw = raw_context orelse return false;
    const card: *const CardText = @ptrCast(@alignCast(raw));
    return drawCard(backend, draw_context, box.*, card, opacity);
}

pub fn paintStrip(raw_context: ?*anyopaque, backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: *const Geometry.RoundedBox, opacity: f32, _: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    const raw = raw_context orelse return false;
    const strip: *const StripText = @ptrCast(@alignCast(raw));
    return drawStrip(backend, draw_context, box.*, strip, opacity);
}

fn rendererLayout(layout: CardLayout) TextRenderer.MediaCardLayout {
    return .{
        .art_background = layout.art_background,
        .app_row = layout.app_row,
        .app_icon = layout.app_icon,
        .app_text = layout.app_text,
        .app_icon_size = layout.app_icon_size,
        .artwork = layout.artwork,
        .title = layout.title,
        .subtitle = layout.subtitle,
        .elapsed = layout.elapsed,
        .remaining = layout.remaining,
        .progress = layout.progress,
        .controls = layout.controls,
        .previous = layout.previous,
        .play_pause = layout.play_pause,
        .next = layout.next,
    };
}

pub fn compactLayoutFor(card_box: Geometry.RoundedBox) CompactLayout {
    const top = card_box.rect.top + Geometry.height(card_box.rect) * compact_card_content_top_fraction;
    const bottom = card_box.rect.top + Geometry.height(card_box.rect) * compact_card_content_bottom_fraction;
    var layout = CompactLayout{};
    layout.progress = .{
        .left = card_box.rect.left + compact_artwork_inset_dip,
        .right = card_box.rect.right - compact_artwork_inset_dip,
        .top = bottom - compact_progress_bar_height_dip,
        .bottom = bottom,
    };
    layout.content = .{
        .left = card_box.rect.left + compact_artwork_inset_dip,
        .right = card_box.rect.right - compact_artwork_inset_dip,
        .top = top,
        .bottom = layout.progress.top - 4,
    };
    layout.artwork = .{
        .left = layout.content.left,
        .top = layout.content.top,
        .right = layout.content.left + compact_artwork_size_dip,
        .bottom = layout.content.top + compact_artwork_size_dip,
    };
    const row_width = compact_transport_button_dip * 3 + compact_transport_gap_dip * 2;
    const row_left = layout.content.right - row_width;
    const row_top = layout.content.top + (compact_artwork_size_dip - compact_transport_button_dip) * 0.5;
    const row_bottom = row_top + compact_transport_button_dip;
    layout.previous = .{ .left = row_left, .right = row_left + compact_transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.play_pause = .{ .left = layout.previous.right + compact_transport_gap_dip, .right = layout.previous.right + compact_transport_gap_dip + compact_transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.next = .{ .left = layout.play_pause.right + compact_transport_gap_dip, .right = layout.play_pause.right + compact_transport_gap_dip + compact_transport_button_dip, .top = row_top, .bottom = row_bottom };
    layout.text = .{ .left = layout.artwork.right + 10, .right = layout.previous.left - 10, .top = layout.content.top, .bottom = layout.content.bottom };
    return layout;
}

pub fn layoutFor(box: Geometry.RoundedBox) CardLayout {
    var layout = CardLayout{};
    const pad = card_pad_dip;
    layout.art_background = box.rect;
    const bottom = box.rect.bottom - pad;
    layout.controls = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = bottom - control_size_dip, .bottom = bottom };
    layout.progress = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = layout.controls.top - 10 - progress_bar_dip, .bottom = layout.controls.top - 10 };
    layout.elapsed = .{ .left = layout.progress.left, .right = layout.progress.left + 56, .top = layout.progress.top - 4 - time_row_dip, .bottom = layout.progress.top - 4 };
    layout.remaining = .{ .left = layout.progress.right - 56, .right = layout.progress.right, .top = layout.elapsed.top, .bottom = layout.elapsed.bottom };
    layout.app_row = .{ .left = box.rect.left + pad, .right = box.rect.right - pad, .top = box.rect.top + pad, .bottom = box.rect.top + pad + app_row_height_dip };
    const row_centre_y = (layout.app_row.top + layout.app_row.bottom) * 0.5;
    layout.app_icon_size = app_icon_size_dip;
    layout.app_icon = .{ .left = layout.app_row.left, .right = layout.app_row.left + layout.app_icon_size, .top = row_centre_y - layout.app_icon_size * 0.5, .bottom = row_centre_y + layout.app_icon_size * 0.5 };
    layout.app_text = .{ .left = layout.app_icon.right + 10, .right = layout.app_row.right, .top = layout.app_row.top, .bottom = layout.app_row.bottom };
    layout.artwork = .{ .left = box.rect.left + pad, .right = box.rect.left + pad + artwork_size_dip, .top = layout.app_row.bottom + 8, .bottom = layout.app_row.bottom + 8 + artwork_size_dip };
    layout.title = .{ .left = layout.artwork.right + gap_after_art_dip, .right = box.rect.right - pad, .top = layout.artwork.top + 16, .bottom = layout.artwork.top + 44 };
    layout.subtitle = .{ .left = layout.title.left, .right = layout.title.right, .top = layout.title.bottom + 2, .bottom = layout.title.bottom + 22 };
    const group_width = control_size_dip * 3 + control_gap_dip * 2;
    const group_left = (box.rect.left + box.rect.right) * 0.5 - group_width * 0.5;
    layout.previous = .{ .left = group_left, .right = group_left + control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    layout.play_pause = .{ .left = layout.previous.right + control_gap_dip, .right = layout.previous.right + control_gap_dip + control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    layout.next = .{ .left = layout.play_pause.right + control_gap_dip, .right = layout.play_pause.right + control_gap_dip + control_size_dip, .top = layout.controls.top, .bottom = layout.controls.bottom };
    return layout;
}

pub fn buildLayoutSnapshot(box: Geometry.RoundedBox, generation: u64, transform: LayoutSnapshot.ScreenTransform, reveal_dip: f32) LayoutSnapshot.Snapshot {
    const layout = layoutFor(box);
    var clip = box.rect;
    clip.bottom = @min(clip.bottom, clip.top + @max(0, reveal_dip));
    var snapshot = LayoutSnapshot.Snapshot{
        .generation = generation,
        .valid = true,
        .screen_transform = transform,
        .surface_clip = clip,
        .content_clip = clip,
    };
    appendButton(&snapshot, 0, layout.previous);
    appendButton(&snapshot, 1, layout.play_pause);
    appendButton(&snapshot, 2, layout.next);
    return snapshot;
}

fn appendButton(snapshot: *LayoutSnapshot.Snapshot, index: i32, bounds: Geometry.RectF) void {
    _ = snapshot.append(.{
        .id = .button,
        .index = index,
        .bounds = bounds,
        .hit_region = bounds,
        .visible = bounds.right > bounds.left and bounds.bottom > bounds.top,
        .enabled = true,
        .content_clipped = false,
    });
}

pub fn actionAt(snapshot: *const LayoutSnapshot.Snapshot, point: Point) ?Action {
    const hit = snapshot.hitTestScreenPixels(point.x_px, point.y_px) orelse return null;
    if (hit.id != .button) return null;
    return switch (hit.index) {
        0 => .previous,
        1 => .play_pause,
        2 => .next,
        else => null,
    };
}

pub fn controlAt(layout: CompactLayout, x: f32, y: f32) CardControl {
    if (contains(layout.previous, x, y)) return .previous;
    if (contains(layout.play_pause, x, y)) return .play_pause;
    if (contains(layout.next, x, y)) return .next;
    return .none;
}

pub fn cardControlAt(layout: CardLayout, x: f32, y: f32) CardControl {
    if (contains(layout.previous, x, y)) return .previous;
    if (contains(layout.play_pause, x, y)) return .play_pause;
    if (contains(layout.next, x, y)) return .next;
    return .none;
}

fn contains(rect: Geometry.RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

test "music UI preserves compact and expanded card geometry" {
    const box = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 520, .bottom = 280 }, .radius_x = 18, .radius_y = 18 };
    const compact = compactLayoutFor(box);
    try std.testing.expectEqual(@as(f32, 44), compact.artwork.right - compact.artwork.left);
    try std.testing.expectEqual(@as(f32, 26), compact.play_pause.right - compact.play_pause.left);
    const card = layoutFor(box);
    try std.testing.expectEqual(@as(f32, 96), card.artwork.right - card.artwork.left);
    try std.testing.expectEqual(@as(f32, 38), card.play_pause.right - card.play_pause.left);
    try std.testing.expectEqual(CardControl.play_pause, cardControlAt(card, card.play_pause.left + 1, card.play_pause.top + 1));
}

test "music card controls use the last presented layout snapshot" {
    const box = Geometry.RoundedBox{ .rect = .{ .left = 100, .top = 30, .right = 620, .bottom = 310 }, .radius_x = 18, .radius_y = 18 };
    const screen = LayoutSnapshot.ScreenTransform{ .window_left_px = 50, .window_top_px = 10, .pixels_per_dip = 1.25 };
    const snapshot = buildLayoutSnapshot(box, 19, screen, Geometry.height(box.rect));
    const play = layoutFor(box).play_pause;
    const x_px: i32 = @intFromFloat(@round(50 + (play.left + play.right) * 0.5 * 1.25));
    const y_px: i32 = @intFromFloat(@round(10 + (play.top + play.bottom) * 0.5 * 1.25));
    try std.testing.expectEqual(Action.play_pause, actionAt(&snapshot, .{ .x_px = x_px, .y_px = y_px }).?);
    try std.testing.expect(actionAt(&snapshot, .{ .x_px = 50, .y_px = 10 }) == null);
    const partially_revealed = buildLayoutSnapshot(box, 20, screen, 20);
    try std.testing.expect(actionAt(&partially_revealed, .{ .x_px = x_px, .y_px = y_px }) == null);
}
