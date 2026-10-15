const std = @import("std");
const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const SoundAudio = @import("SoundAudio");
const SoundController = @import("SoundController");
const MixerSlider = @import("MixerSlider");
const ThemeTokens = @import("ThemeTokens");
const TextRenderer = @import("TextRenderer");

pub const max_devices = SoundAudio.max_devices;
pub const max_sessions = SoundAudio.max_sessions;
pub const spatial_row_count = 2;
pub const max_mix_rows = max_sessions + 1;
const spatial_row_count_i32: i32 = @intCast(spatial_row_count);

pub const header_height_dip: f32 = 40;
pub const footer_height_dip: f32 = 34;
pub const section_height_dip: f32 = 28;
pub const device_row_height_dip: f32 = 40;
pub const spatial_row_height_dip: f32 = 34;
pub const mixer_row_height_dip: f32 = 36;
pub const indent_dip: f32 = 14;

pub const spatial_index_base: i32 = 1000;
pub const button_back: i32 = 0;
pub const button_mixer_settings: i32 = 1;
pub const button_footer: i32 = 2;

const wide_title: [*:0]const u16 = &.{ 0x58F0, 0x97F3, 0x8F93, 0x51FA, 0 };
const wide_device_label: [*:0]const u16 = &.{ 0x8F93, 0x51FA, 0x8BBE, 0x5907, 0 };
const wide_spatial_label: [*:0]const u16 = &.{ 0x7A7A, 0x95F4, 0x97F3, 0x6548, 0 };
const wide_mixer_label: [*:0]const u16 = &.{ 0x97F3, 0x91CF, 0x5408, 0x6210, 0x5668, 0 };
const wide_footer: [*:0]const u16 = &.{ 0x66F4, 0x591A, 0x97F3, 0x91CF, 0x8BBE, 0x7F6E, 0 };
const wide_off: [*:0]const u16 = &.{ 0x5173, 0 };
const wide_sonic: [*:0]const u16 = &.{ 0x7528, 0x4E8E, 0x8033, 0x673A, 0x7684, ' ', 'W', 'i', 'n', 'd', 'o', 'w', 's', ' ', 'S', 'o', 'n', 'i', 'c', 0 };
const wide_output_device: [*:0]const u16 = &.{ 'O', 'u', 't', 'p', 'u', 't', ' ', 'd', 'e', 'v', 'i', 'c', 'e', 0 };

pub const LocalState = struct {
    scroll: f32 = 0,
    hovered: ?Interaction = null,
    pressed: ?Interaction = null,

    pub fn setHovered(self: *LocalState, target: ?Interaction) void {
        self.hovered = target;
    }

    pub fn setPressed(self: *LocalState, target: ?Interaction) void {
        self.pressed = target;
    }
};

pub const Interaction = struct { id: LayoutSnapshot.ElementId, index: i32 };
pub const Point = struct { x_px: i32, y_px: i32 };

pub const Value = struct {
    confirmed: f32 = 0,
    displayed: f32 = 0,
    muted: bool = false,
    pending: bool = false,
};

/// Read-only Sound data consumed by layout, hit testing and drawing.
pub const ViewModel = struct {
    state: *const SoundController.State,
    scroll: f32 = 0,
    tokens: ThemeTokens.Tokens,

    pub fn deviceCount(self: *const ViewModel) usize {
        return @min(self.state.output.device_count, max_devices);
    }

    pub fn mixCount(self: *const ViewModel) usize {
        return @min(self.state.output.session_count, max_sessions) + 1;
    }

    pub fn value(self: *const ViewModel, row: usize) ?Value {
        if (row == 0) return .{
            .confirmed = self.state.master_level,
            .displayed = self.state.displayedMasterLevel(),
            .muted = self.state.displayedMuted(),
            .pending = self.state.optimistic_master_level != null or self.state.optimistic_master_muted != null,
        };
        const session_index = row - 1;
        if (session_index >= self.state.output.session_count) return null;
        const session = self.state.output.sessions[session_index];
        var pending = false;
        if (self.state.pending) |action| switch (action.action) {
            .set_session_volume => |request| pending = request.pid == session.pid,
            else => {},
        };
        return .{
            .confirmed = session.volume,
            .displayed = self.state.displayedSessionLevel(session.pid, session.volume),
            .muted = false,
            .pending = pending,
        };
    }

    pub fn slider(self: *const ViewModel, row: usize) ?@import("Slider").ViewModel {
        const current = self.value(row) orelse return null;
        return MixerSlider.viewModel(current.displayed, current.muted, self.tokens);
    }

    pub fn rowLabel(self: *const ViewModel, row: usize) ?[]const u16 {
        if (row == 0) {
            if (self.state.output.default_device_name[0] != 0) return std.mem.sliceTo(&self.state.output.default_device_name, 0);
            return std.mem.span(wide_output_device);
        }
        const session_index = row - 1;
        if (session_index >= self.state.output.session_count) return null;
        return std.mem.sliceTo(&self.state.output.sessions[session_index].name, 0);
    }

    pub fn rowIcon(self: *const ViewModel, row: usize) ?struct { png: []const u8, revision: u64 } {
        if (row == 0) return null;
        const session_index = row - 1;
        if (session_index >= self.state.output.session_count) return null;
        const session = &self.state.output.sessions[session_index];
        if (session.icon_size == 0) return null;
        return .{ .png = session.icon[0..@min(session.icon_size, session.icon.len)], .revision = session.icon_revision };
    }
};

pub const Layout = struct {
    back_button: Geometry.RectF = .{},
    title: Geometry.RectF = .{},
    header_rule: Geometry.RectF = .{},
    device_label: Geometry.RectF = .{},
    device_rows: [max_devices]Geometry.RectF = @splat(.{}),
    device_icons: [max_devices]Geometry.RectF = @splat(.{}),
    device_labels: [max_devices]Geometry.RectF = @splat(.{}),
    device_marks: [max_devices]Geometry.RectF = @splat(.{}),
    spatial_label: Geometry.RectF = .{},
    spatial_rows: [spatial_row_count]Geometry.RectF = @splat(.{}),
    spatial_marks: [spatial_row_count]Geometry.RectF = @splat(.{}),
    spatial_labels: [spatial_row_count]Geometry.RectF = @splat(.{}),
    mixer_label: Geometry.RectF = .{},
    mixer_gear: Geometry.RectF = .{},
    mixer_rows: [max_mix_rows]Geometry.RectF = @splat(.{}),
    mixer_icons: [max_mix_rows]Geometry.RectF = @splat(.{}),
    mixer_tracks: [max_mix_rows]Geometry.RectF = @splat(.{}),
    footer: Geometry.RectF = .{},
    footer_rule: Geometry.RectF = .{},
    scroll_track: Geometry.RectF = .{},
    scroll_thumb: Geometry.RectF = .{},
    viewport: Geometry.RectF = .{},
    device_count: usize = 0,
    mix_count: usize = 0,
    content_height: f32 = 0,
    scroll: f32 = 0,
};

fn shiftRect(rect: *Geometry.RectF, distance: f32) void {
    rect.top -= distance;
    rect.bottom -= distance;
}

pub fn layoutFor(card: Geometry.RoundedBox, model: *const ViewModel, scroll_arg: f32) Layout {
    var layout = Layout{};
    const device_count = @min(model.deviceCount(), max_devices);
    const mix_count = @min(model.mixCount(), max_mix_rows);
    layout.device_count = device_count;
    layout.mix_count = mix_count;

    const left = card.rect.left + indent_dip;
    const right = card.rect.right - indent_dip;
    layout.header_rule = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.top + header_height_dip - 1, .bottom = card.rect.top + header_height_dip };
    const back_size: f32 = 26;
    const header_centre = card.rect.top + (header_height_dip - 1) * 0.5;
    layout.back_button = .{ .left = left, .right = left + back_size, .top = header_centre - back_size * 0.5, .bottom = header_centre + back_size * 0.5 };
    layout.title = .{ .left = left + back_size + 8, .right = right, .top = card.rect.top + 2, .bottom = card.rect.top + header_height_dip - 3 };
    layout.footer_rule = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.bottom - footer_height_dip, .bottom = card.rect.bottom - footer_height_dip + 1 };
    layout.footer = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.bottom - footer_height_dip, .bottom = card.rect.bottom };
    layout.viewport = .{ .left = card.rect.left, .right = card.rect.right, .top = card.rect.top + header_height_dip, .bottom = card.rect.bottom - footer_height_dip };

    const content_top = layout.viewport.top;
    const content_right = right - 6;
    var y = content_top;
    layout.device_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + section_height_dip };
    y += section_height_dip;
    for (0..device_count) |index| {
        const row = Geometry.RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + device_row_height_dip };
        layout.device_rows[index] = row;
        layout.device_marks[index] = .{ .left = card.rect.left + 3, .right = card.rect.left + 6, .top = y + 9, .bottom = y + device_row_height_dip - 9 };
        const icon_side: f32 = 20;
        const row_centre = (row.top + row.bottom) * 0.5;
        layout.device_icons[index] = .{ .left = left + 8, .right = left + 8 + icon_side, .top = row_centre - icon_side * 0.5, .bottom = row_centre + icon_side * 0.5 };
        layout.device_labels[index] = .{ .left = left + 8 + icon_side + 10, .right = content_right, .top = row.top, .bottom = row.bottom };
        y += device_row_height_dip;
    }
    layout.spatial_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + section_height_dip };
    y += section_height_dip;
    for (0..spatial_row_count) |index| {
        const row = Geometry.RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + spatial_row_height_dip };
        layout.spatial_rows[index] = row;
        layout.spatial_marks[index] = .{ .left = card.rect.left + 3, .right = card.rect.left + 6, .top = y + 7, .bottom = y + spatial_row_height_dip - 7 };
        layout.spatial_labels[index] = .{ .left = left + 8, .right = content_right, .top = row.top, .bottom = row.bottom };
        y += spatial_row_height_dip;
    }
    layout.mixer_label = .{ .left = left, .right = content_right, .top = y, .bottom = y + section_height_dip };
    const gear_side: f32 = 20;
    layout.mixer_gear = .{ .left = content_right - gear_side, .right = content_right, .top = y + (section_height_dip - gear_side) * 0.5, .bottom = y + (section_height_dip + gear_side) * 0.5 };
    y += section_height_dip;
    for (0..mix_count) |index| {
        const row = Geometry.RectF{ .left = card.rect.left, .right = content_right, .top = y, .bottom = y + mixer_row_height_dip };
        layout.mixer_rows[index] = row;
        const icon_side: f32 = 22;
        const row_centre = (row.top + row.bottom) * 0.5;
        layout.mixer_icons[index] = .{ .left = left + 6, .right = left + 6 + icon_side, .top = row_centre - icon_side * 0.5, .bottom = row_centre + icon_side * 0.5 };
        layout.mixer_tracks[index] = .{ .left = left + 6 + icon_side + 14, .right = content_right, .top = y, .bottom = y + mixer_row_height_dip };
        y += mixer_row_height_dip;
    }
    layout.content_height = y - content_top;

    const viewport_height = layout.viewport.bottom - layout.viewport.top;
    const limit = @max(0, layout.content_height - viewport_height);
    const scroll = @max(0, @min(scroll_arg, limit));
    layout.scroll = scroll;
    if (scroll != 0) {
        shiftRect(&layout.device_label, scroll);
        for (0..device_count) |index| {
            shiftRect(&layout.device_rows[index], scroll);
            shiftRect(&layout.device_icons[index], scroll);
            shiftRect(&layout.device_labels[index], scroll);
            shiftRect(&layout.device_marks[index], scroll);
        }
        shiftRect(&layout.spatial_label, scroll);
        for (0..spatial_row_count) |index| {
            shiftRect(&layout.spatial_rows[index], scroll);
            shiftRect(&layout.spatial_marks[index], scroll);
            shiftRect(&layout.spatial_labels[index], scroll);
        }
        shiftRect(&layout.mixer_label, scroll);
        shiftRect(&layout.mixer_gear, scroll);
        for (0..mix_count) |index| {
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

pub fn scrollLimit(card: Geometry.RoundedBox, model: *const ViewModel) f32 {
    const probe = layoutFor(card, model, 0);
    return @max(0, probe.content_height - Geometry.height(probe.viewport));
}

pub fn draw(backend: *TextRenderer.TextRenderer, context: ?*anyopaque, card: Geometry.RoundedBox, model: *const ViewModel, snapshot: ?*const LayoutSnapshot.Snapshot, opacity_arg: f32) bool {
    if (context == null) return false;
    const opacity = std.math.clamp(opacity_arg, 0, 1);
    if (opacity <= 0.01) return true;
    const layout = layoutFor(card, model, model.scroll);
    const ink = ThemeTokens.withOpacity(model.tokens.ink, opacity);
    const muted_ink = ThemeTokens.withOpacity(model.tokens.ink, 0.80 * opacity);
    const faint_ink = ThemeTokens.withOpacity(model.tokens.ink, 0.10 * opacity);
    backend.drawCardSurface(context, card, opacity);
    backend.drawFeatureLine(context, .{ layout.header_rule.left, layout.header_rule.top }, .{ layout.header_rule.right, layout.header_rule.top }, faint_ink, 1);
    backend.drawFeatureLine(context, .{ layout.footer_rule.left, layout.footer_rule.top }, .{ layout.footer_rule.right, layout.footer_rule.top }, faint_ink, 1);

    const back = [_]u16{ 0xE72B, 0 };
    _ = backend.drawLabel(context, .icon, &back, layout.back_button, ink);
    _ = backend.drawLabel(context, .card_title, std.mem.span(wide_title), layout.title, ink);
    const footer_box = Geometry.RectF{ .left = layout.footer.left + indent_dip, .top = layout.footer.top, .right = layout.footer.right - indent_dip, .bottom = layout.footer.bottom };
    _ = backend.drawLabel(context, .small_body, std.mem.span(wide_footer), footer_box, muted_ink);

    const content_clip = if (snapshot) |frame| frame.renderContentClip() else layout.viewport;
    backend.pushClip(context, content_clip);
    _ = backend.drawLabel(context, .small_body, std.mem.span(wide_device_label), layout.device_label, muted_ink);
    for (0..layout.device_count) |index| {
        const device = &model.state.output.devices[index];
        const row = layout.device_rows[index];
        if (device.is_default) {
            backend.fillRoundedRect(context, row, 0, 0, ThemeTokens.withOpacity(model.tokens.ink, 0.07 * opacity));
            backend.fillRoundedRect(context, layout.device_marks[index], 1.5, 1.5, ThemeTokens.withOpacity(model.tokens.accent, 0.95 * opacity));
        }
        const glyph: u16 = switch (device.form_factor) {
            3, 5 => TextRenderer.indicatorGlyph(.headphones, 0),
            4, 6, 8, 10 => TextRenderer.indicatorGlyph(.display_audio, 0),
            else => TextRenderer.indicatorGlyph(.volume, 1),
        };
        const icon_text = [_]u16{ glyph, 0 };
        _ = backend.drawLabel(context, .icon, &icon_text, layout.device_icons[index], ink);
        _ = backend.drawLabel(context, .small_body, std.mem.sliceTo(&device.name, 0), layout.device_labels[index], if (device.is_default) ink else muted_ink);
    }

    _ = backend.drawLabel(context, .small_body, std.mem.span(wide_spatial_label), layout.spatial_label, muted_ink);
    for (0..spatial_row_count) |index| {
        const text = if (index == 0) wide_off else wide_sonic;
        if (index == 0) backend.fillRoundedRect(context, layout.spatial_marks[index], 1.5, 1.5, ThemeTokens.withOpacity(model.tokens.accent, 0.95 * opacity));
        _ = backend.drawLabel(context, .small_body, std.mem.span(text), layout.spatial_labels[index], if (index == 0) ink else muted_ink);
    }

    _ = backend.drawLabel(context, .small_body, std.mem.span(wide_mixer_label), layout.mixer_label, muted_ink);
    const gear = [_]u16{ TextRenderer.indicatorGlyph(.settings, 0), 0 };
    _ = backend.drawLabel(context, .icon, &gear, layout.mixer_gear, muted_ink);
    for (0..layout.mix_count) |index| {
        const icon_box = layout.mixer_icons[index];
        if (model.rowIcon(index)) |icon| {
            if (!backend.drawPngIcon(context, index, icon.png, icon.revision, icon_box, opacity)) drawFallbackMixerIcon(backend, context, index, icon_box, ink);
        } else {
            backend.clearPngIcon(index);
            drawFallbackMixerIcon(backend, context, index, icon_box, ink);
        }
        const track = if (snapshot) |frame|
            (frame.boundsFor(.slider, @intCast(index)) orelse return false)
        else
            layout.mixer_tracks[index];
        const slider = model.slider(index) orelse return false;
        if (!backend.drawSlider(context, track, slider, opacity)) return false;
    }
    backend.popClip(context);

    backend.fillRoundedRect(context, layout.scroll_track, 1.5, 1.5, ThemeTokens.withOpacity(model.tokens.ink, 0.10 * opacity));
    backend.fillRoundedRect(context, layout.scroll_thumb, 1.5, 1.5, ThemeTokens.withOpacity(model.tokens.ink, 0.34 * opacity));
    return true;
}

fn drawFallbackMixerIcon(backend: *TextRenderer.TextRenderer, context: ?*anyopaque, index: usize, bounds: Geometry.RectF, color: ThemeTokens.Color) void {
    const glyph: u16 = if (index == 0) TextRenderer.indicatorGlyph(.volume, 1) else TextRenderer.indicatorGlyph(.settings, 0);
    const text = [_]u16{ glyph, 0 };
    _ = backend.drawLabel(context, .icon, &text, bounds, color);
}

pub fn buildLayoutSnapshot(card: Geometry.RoundedBox, model: *const ViewModel, reveal: f32, frame_generation: u64, screen_transform: LayoutSnapshot.ScreenTransform) LayoutSnapshot.Snapshot {
    var snapshot = LayoutSnapshot.Snapshot{
        .generation = frame_generation,
        .data_generation = model.state.topology_generation,
        .screen_transform = screen_transform,
    };
    if (reveal <= 0.5) return snapshot;
    const layout = layoutFor(card, model, model.scroll);
    var revealed = card.rect;
    revealed.bottom = @min(card.rect.bottom, card.rect.top + reveal);
    snapshot.surface_clip = LayoutSnapshot.intersection(card.rect, revealed);
    snapshot.content_clip = LayoutSnapshot.intersection(layout.viewport, snapshot.surface_clip);
    snapshot.valid = true;
    appendElement(&snapshot, .button, button_back, layout.back_button, false);
    appendElement(&snapshot, .button, button_mixer_settings, layout.mixer_gear, true);
    appendElement(&snapshot, .button, button_footer, layout.footer, false);
    appendElement(&snapshot, .scrollbar, 0, layout.scroll_track, true);
    for (0..layout.device_count) |index| appendElement(&snapshot, .row, @intCast(index), layout.device_rows[index], true);
    for (0..spatial_row_count) |index| appendElement(&snapshot, .row, spatial_index_base + @as(i32, @intCast(index)), layout.spatial_rows[index], true);
    for (0..layout.mix_count) |index| appendElement(&snapshot, .slider, @intCast(index), layout.mixer_tracks[index], true);
    return snapshot;
}

fn appendElement(snapshot: *LayoutSnapshot.Snapshot, id: LayoutSnapshot.ElementId, index: i32, bounds: Geometry.RectF, content_clipped: bool) void {
    _ = snapshot.append(.{ .id = id, .index = index, .bounds = bounds, .hit_region = bounds, .z_order = 10, .visible = true, .enabled = true, .content_clipped = content_clipped });
}

pub const Action = union(enum) {
    none,
    back,
    select_default_device: SoundController.Action,
    set_volume: SoundController.Action,
    spatial: i32,
    open_settings,
    scroll_by: f32,
};

pub fn actionAt(model: *const ViewModel, card: Geometry.RoundedBox, presented: *const LayoutSnapshot.Snapshot, screen_point: Point) Action {
    const hit = presented.hitTestScreenPixels(screen_point.x_px, screen_point.y_px) orelse return .none;
    return actionForHit(model, card, presented, hit.id, hit.index, hit.bounds, hit.point_x, hit.point_y);
}

pub fn interactionAt(presented: *const LayoutSnapshot.Snapshot, screen_point: Point) ?Interaction {
    const hit = presented.hitTestScreenPixels(screen_point.x_px, screen_point.y_px) orelse return null;
    return .{ .id = hit.id, .index = hit.index };
}

pub fn volumeAction(model: *const ViewModel, presented: *const LayoutSnapshot.Snapshot, row: i32, fraction_arg: f32) ?SoundController.Action {
    if (!presented.valid or presented.data_generation != model.state.topology_generation or row < 0 or @as(usize, @intCast(row)) >= model.mixCount()) return null;
    const fraction = if (std.math.isFinite(fraction_arg)) std.math.clamp(fraction_arg, 0, 1) else 0;
    if (row == 0) return .{ .set_master_volume = fraction };
    const session_index: usize = @intCast(row - 1);
    if (session_index >= model.state.output.session_count) return null;
    return .{ .set_session_volume = .{ .pid = model.state.output.sessions[session_index].pid, .level = fraction, .topology_generation = presented.data_generation } };
}

fn actionForHit(model: *const ViewModel, card: Geometry.RoundedBox, presented: *const LayoutSnapshot.Snapshot, id: LayoutSnapshot.ElementId, index: i32, bounds: Geometry.RectF, point_x: f32, point_y: f32) Action {
    switch (id) {
        .button => return switch (index) {
            button_back => .back,
            button_mixer_settings, button_footer => .open_settings,
            else => .none,
        },
        .row => {
            if (index >= 0 and index < @as(i32, @intCast(max_devices))) {
                if (presented.data_generation != model.state.topology_generation) return .none;
                const device_index: usize = @intCast(index);
                if (device_index >= model.state.output.device_count) return .none;
                const device = model.state.output.devices[device_index];
                if (device.is_default) return .none;
                return .{ .select_default_device = .{ .select_default_device = .{ .id = device.id, .topology_generation = presented.data_generation } } };
            }
            if (index >= spatial_index_base and index < spatial_index_base + spatial_row_count_i32) return .{ .spatial = index - spatial_index_base };
            return .none;
        },
        .slider => {
            const width = Geometry.width(bounds);
            const fraction = if (width > 0) std.math.clamp((point_x - bounds.left) / width, 0, 1) else 0;
            if (volumeAction(model, presented, index, fraction)) |action| return .{ .set_volume = action };
            return .none;
        },
        .scrollbar => {
            const layout = layoutFor(card, model, model.scroll);
            if (point_y < layout.scroll_thumb.top) return .{ .scroll_by = -140 };
            if (point_y > layout.scroll_thumb.bottom) return .{ .scroll_by = 140 };
            return .{ .scroll_by = 0 };
        },
    }
}

test "sound UI distinguishes confirmed and optimistic mixer values" {
    var state = SoundController.State{ .master_available = true, .master_level = 0.35, .optimistic_master_level = 0.7, .output = .{ .session_count = 1 } };
    state.output.sessions[0] = .{ .pid = 42, .volume = 0.2 };
    const model = ViewModel{ .state = &state, .tokens = .{ .accent = .{ .r = 1, .g = 1, .b = 1, .a = 1 }, .ink = .{ .r = 1, .g = 1, .b = 1, .a = 1 } } };
    const master = model.value(0).?;
    try std.testing.expectEqual(@as(f32, 0.35), master.confirmed);
    try std.testing.expectEqual(@as(f32, 0.7), master.displayed);
    try std.testing.expect(master.pending);
    try std.testing.expectEqual(@as(f32, 0.2), model.value(1).?.confirmed);
}

test "sound page layout preserves scroll geometry and mixer hit bounds" {
    var state = SoundController.State{ .output = .{ .device_count = 2, .session_count = 4 } };
    state.output.devices[0].is_default = true;
    const model = ViewModel{ .state = &state, .tokens = .{ .accent = .{ .r = 1, .g = 1, .b = 1, .a = 1 }, .ink = .{ .r = 1, .g = 1, .b = 1, .a = 1 } } };
    const card = Geometry.RoundedBox{ .rect = .{ .left = 100, .top = 20, .right = 420, .bottom = 420 }, .radius_x = 12, .radius_y = 12 };
    const layout = layoutFor(card, &model, 1000);
    try std.testing.expectEqual(@as(usize, 2), layout.device_count);
    try std.testing.expectEqual(@as(usize, 5), layout.mix_count);
    try std.testing.expectEqual(scrollLimit(card, &model), layout.scroll);
    const snapshot = buildLayoutSnapshot(card, &model, 400, 1, .{});
    const track = layoutFor(card, &model, 0).mixer_tracks[0];
    const point = snapshot.hitTestLocalDip((track.left + track.right) * 0.5, (track.top + track.bottom) * 0.5);
    try std.testing.expect(point != null);
    try std.testing.expectEqual(LayoutSnapshot.ElementId.slider, point.?.id);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), (point.?.point_x - point.?.bounds.left) / (point.?.bounds.right - point.?.bounds.left), 0.01);
}

test "stale sound page snapshots cannot target a replacement session" {
    var state = SoundController.State{ .topology_generation = 2, .output = .{ .session_count = 1 } };
    state.output.sessions[0].pid = 99;
    const model = ViewModel{ .state = &state, .tokens = .{ .accent = .{ .r = 1, .g = 1, .b = 1, .a = 1 }, .ink = .{ .r = 1, .g = 1, .b = 1, .a = 1 } } };
    const snapshot = LayoutSnapshot.Snapshot{ .valid = true, .data_generation = 1 };
    try std.testing.expect(volumeAction(&model, &snapshot, 1, 0.8) == null);
}

test "sound page snapshots map device, slider, and scrollbar actions" {
    var state = SoundController.State{ .topology_generation = 7, .output = .{ .device_count = 2 } };
    state.output.devices[0].is_default = true;
    state.output.devices[1].id[0] = 'B';
    var model = ViewModel{ .state = &state, .tokens = .{ .accent = .{ .r = 1, .g = 1, .b = 1, .a = 1 }, .ink = .{ .r = 1, .g = 1, .b = 1, .a = 1 } } };
    const card = Geometry.RoundedBox{ .rect = .{ .left = 100, .top = 20, .right = 420, .bottom = 420 }, .radius_x = 12, .radius_y = 12 };
    var presented = buildLayoutSnapshot(card, &model, 400, 1, .{});
    const device = layoutFor(card, &model, 0).device_rows[1];
    switch (actionAt(&model, card, &presented, .{ .x_px = @intFromFloat((device.left + device.right) * 0.5), .y_px = @intFromFloat((device.top + device.bottom) * 0.5) })) {
        .select_default_device => |wrapper| switch (wrapper) {
            .select_default_device => |request| {
                try std.testing.expectEqual(@as(u16, 'B'), request.id[0]);
                try std.testing.expectEqual(@as(u64, 7), request.topology_generation);
            },
            else => return error.WrongSoundAction,
        },
        else => return error.WrongPageAction,
    }

    state.output.device_count = 0;
    presented = buildLayoutSnapshot(card, &model, 400, 2, .{});
    const master_track = layoutFor(card, &model, 0).mixer_tracks[0];
    switch (actionAt(&model, card, &presented, .{ .x_px = @intFromFloat((master_track.left + master_track.right) * 0.5), .y_px = @intFromFloat((master_track.top + master_track.bottom) * 0.5) })) {
        .set_volume => |sound_action| switch (sound_action) {
            .set_master_volume => |fraction| try std.testing.expectApproxEqAbs(@as(f32, 0.5), fraction, 0.01),
            else => return error.WrongSoundAction,
        },
        else => return error.WrongPageAction,
    }

    state.output.device_count = max_devices;
    state.output.session_count = max_sessions;
    model.scroll = 0;
    presented = buildLayoutSnapshot(card, &model, 400, 3, .{});
    const track = layoutFor(card, &model, 0).scroll_track;
    switch (actionAt(&model, card, &presented, .{ .x_px = @intFromFloat((track.left + track.right) * 0.5), .y_px = @intFromFloat(track.bottom - 1) })) {
        .scroll_by => |distance| try std.testing.expectEqual(@as(f32, 140), distance),
        else => return error.WrongPageAction,
    }
}
