const std = @import("std");
const Geometry = @import("Geometry");
const SystemPanelPresentation = @import("SystemPanelPresentation");
const CanvasModule = @import("Canvas");
const Slider = @import("Slider");
const BarControlLayout = @import("BarControlLayout");

const Theme = @import("Theme");
const StatusLineWeather = @import("StatusLineWeather");
const WicImage = @import("WicImage");
const GlassMaterial = @import("GlassMaterial");

pub const task_button_count_max: usize = 32;
pub const system_tile_count_max: usize = 6;
pub const feature_icon_cache_count: usize = 58;
const scrolling_line_gutter_dip: f32 = 24;
const d2d_bitmap_interpolation_linear: i32 = 1;

pub fn lineNeedsScrollForWidth(text_width_dip: f32, strip_width_dip: f32) bool {
    return text_width_dip > strip_width_dip - scrolling_line_gutter_dip;
}

pub fn scrollingLineFadeDip(strip_width_dip: f32) f32 {
    if (strip_width_dip <= 0) return 0;
    return @min(20, strip_width_dip * 0.25);
}

pub const ClockStyle = enum(i32) { compact = 0, card = 1 };

/// One application group button on the taskbar row. Window count and the
/// representative live window are carried by the platform-neutral task data.
pub const TaskButton = struct {
    window_id: u64 = 0,
    process_id: u32 = 0,
    process_created_at: u64 = 0,
    window_count: usize = 1,
    title: ?[*:0]const u16 = null,
    window: ?*anyopaque = null,
    icon: ?*anyopaque = null,
    bounds: Geometry.RectF = .{},
    icon_bounds: Geometry.RectF = .{},
    title_bounds: Geometry.RectF = .{},
    hover_progress: f32 = 0,
    active: bool = false,
    visual_opacity: f32 = 1,
    visual_scale: f32 = 1,
    visual_offset_y: f32 = 0,
};

/// Feature supplied content for the reusable media-card drawing primitive.
pub const MediaCardContent = struct {
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

/// Geometry is supplied by the owning Feature UI so draw and hit layout have
/// one authority. TextRenderer only consumes these bounds.
pub const MediaCardLayout = struct {
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

pub const LineRoll = struct {
    previous: ?[*:0]const u8 = null,
    progress: f32 = 1,
    previous_scroll_dip: f32 = 0,
};

pub const IndicatorIcon = enum(i32) {
    input_method = 0,
    network = 1,
    bluetooth = 2,
    volume = 3,
    battery = 4,
    airplane = 5,
    settings = 6,
    accessibility = 7,
    battery_saver = 8,
    captions = 9,
    moon = 10,
    hotspot = 11,
    share = 12,
    output_device = 13,
    wired_display = 14,
    projection = 15,
    headphones = 16,
    display_audio = 17,
    brightness = 18,
};
pub const SystemPanelIcon = IndicatorIcon;
pub const SystemPanelTile = SystemPanelPresentation.Tile;
pub const SystemPanelText = SystemPanelPresentation.View;

pub const TextStyle = enum { small_body, card_title, card_caption, card_heading, card_body, icon, page_title, page_body, page_caption };

pub const CallStripText = struct {
    seconds: i32 = 0,
    level: f32 = 0,
    level_known: bool = false,
    icon_pixels: ?[]const u8 = null,
    icon_width: i32 = 0,
    icon_height: i32 = 0,
    icon_revision: u64 = 0,
};

pub const TextMetrics = struct {
    title_line_height: f32 = 0,
    secondary_line_height: f32 = 0,
    pill_line_height: f32 = 0,
};

const Handle = ?*anyopaque;
const HResult = i32;
const BitmapCache = struct { bitmap: Handle = null, context: Handle = null, revision: u64 = 0, width: i32 = 0, height: i32 = 0 };
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const UnknownVTable = extern struct {
    query_interface: *const fn (*anyopaque, *const Guid, *Handle) callconv(.winapi) HResult,
    add_ref: *const fn (*anyopaque) callconv(.winapi) u32,
    release: *const fn (*anyopaque) callconv(.winapi) u32,
};
const Unknown = extern struct { vtable: *const UnknownVTable };
const D2DColor = extern struct { r: f32, g: f32, b: f32, a: f32 };
const D2DRectF = extern struct { left: f32, top: f32, right: f32, bottom: f32 };
const D2DGradientStop = extern struct { position: f32, color: D2DColor };
const D2DLinearGradientBrushProperties = extern struct { start_point: D2DPointF, end_point: D2DPointF };
const D2DBitmapBrushProperties = extern struct { extend_mode_x: i32, extend_mode_y: i32, interpolation_mode: i32 };
const D2DSizeU = extern struct { width: u32, height: u32 };
const D2DPixelFormat = extern struct { format: i32, alpha_mode: i32 };
const D2DBitmapProperties1 = extern struct {
    pixel_format: D2DPixelFormat,
    dpi_x: f32,
    dpi_y: f32,
    options: u32,
    color_context: Handle,
};
const D2DPointF = extern struct { x: f32, y: f32 };
const D2DMatrix3x2 = extern struct { m11: f32, m12: f32, m21: f32, m22: f32, dx: f32, dy: f32 };
const D2DLayerParameters = extern struct {
    content_bounds: D2DRectF,
    geometric_mask: Handle,
    mask_antialias_mode: i32,
    mask_transform: D2DMatrix3x2,
    opacity: f32,
    opacity_brush: Handle,
    layer_options: i32,
};
const D2DEllipse = extern struct { point: D2DPointF, radius_x: f32, radius_y: f32 };
const D2DRoundedRect = extern struct { rect: D2DRectF, radius_x: f32, radius_y: f32 };
const DWriteTextMetrics = extern struct {
    left: f32,
    top: f32,
    width: f32,
    width_including_trailing_whitespace: f32,
    height: f32,
    layout_width: f32,
    layout_height: f32,
    max_bidi_reordering_depth: u32,
    line_count: u32,
};
const SystemTime = extern struct {
    year: u16,
    month: u16,
    day_of_week: u16,
    day: u16,
    hour: u16,
    minute: u16,
    second: u16,
    milliseconds: u16,
};

extern "dwrite" fn DWriteCreateFactory(factory_type: u32, iid: *const Guid, factory: *Handle) callconv(.winapi) HResult;
extern "kernel32" fn GetLocalTime(time: *SystemTime) callconv(.winapi) void;
extern "kernel32" fn MultiByteToWideChar(code_page: u32, flags: u32, input: [*]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;

const iid_dwrite_factory = Guid{ .data1 = 0xB859EE5A, .data2 = 0xD838, .data3 = 0x4B5B, .data4 = .{ 0xA2, 0xE8, 0x1A, 0xDC, 0x7D, 0x93, 0xDB, 0x48 } };
const font_family_display: [*:0]const u16 = &.{ 'S', 'e', 'g', 'o', 'e', ' ', 'U', 'I', ' ', 'V', 'a', 'r', 'i', 'a', 'b', 'l', 'e', ' ', 'D', 'i', 's', 'p', 'l', 'a', 'y', 0 };
const font_family_text: [*:0]const u16 = &.{ 'S', 'e', 'g', 'o', 'e', ' ', 'U', 'I', ' ', 'V', 'a', 'r', 'i', 'a', 'b', 'l', 'e', ' ', 'T', 'e', 'x', 't', 0 };
const font_family_icons: [*:0]const u16 = &.{ 'S', 'e', 'g', 'o', 'e', ' ', 'M', 'D', 'L', '2', ' ', 'A', 's', 's', 'e', 't', 's', 0 };
const locale_zh_cn: [*:0]const u16 = &.{ 'z', 'h', '-', 'C', 'N', 0 };

/// The clock formats and drawing path used by the pill and expanded card.
/// The factory owns the DirectWrite formats; the caller owns the D2D context.
pub const TextRenderer = struct {
    factory: Handle = null,
    time_format: Handle = null,
    date_format: Handle = null,
    status_time_format: Handle = null,
    status_clock_time_format: Handle = null,
    status_weather_format: Handle = null,
    pill_line_format: Handle = null,
    card_caption_format: Handle = null,
    card_heading_format: Handle = null,
    card_body_format: Handle = null,
    panel_label_format: Handle = null,
    panel_icon_format: Handle = null,
    small_body_format: Handle = null,
    card_title_format: Handle = null,
    page_body_format: Handle = null,
    page_caption_format: Handle = null,
    music_title_format: Handle = null,
    music_subtitle_format: Handle = null,
    music_app_format: Handle = null,
    task_title_format: Handle = null,
    task_active_title_format: Handle = null,
    music_time_format: Handle = null,
    music_glyph_format: Handle = null,
    music_note_format: Handle = null,
    music_artwork_cache: BitmapCache = .{},
    music_background_cache: BitmapCache = .{},
    music_app_icon_cache: BitmapCache = .{},
    call_icon_cache: BitmapCache = .{},
    last_png_bitmap_failure: []const u8 = "",
    last_png_bitmap_hresult: HResult = 0,
    rgba_image_cache: BitmapCache = .{},
    feature_icon_bitmaps: [feature_icon_cache_count]Handle = @splat(null),
    feature_icon_contexts: [feature_icon_cache_count]Handle = @splat(null),
    feature_icon_revisions: [feature_icon_cache_count]u64 = @splat(0),
    feature_icon_fingerprints: [feature_icon_cache_count]u64 = @splat(0),
    grain_bitmap: Handle = null,
    grain_context: Handle = null,
    time_text: [16]u16 = @splat(0),
    date_text: [32]u16 = @splat(0),
    last_hour: u16 = std.math.maxInt(u16),
    last_minute: u16 = std.math.maxInt(u16),
    last_year: u16 = 0,
    last_month: u16 = 0,
    last_day: u16 = 0,

    pub fn initialize(self: *TextRenderer) bool {
        if (self.factory != null) return true;
        if (DWriteCreateFactory(0, &iid_dwrite_factory, &self.factory) < 0 or self.factory == null) {
            self.shutdown();
            return false;
        }
        if (!self.createFormat(font_family_display, 600, 15, &self.time_format) or
            !self.createFormat(font_family_text, 400, 12, &self.date_format) or
            !self.createFormat(font_family_text, 600, 13, &self.status_time_format) or
            !self.createCenteredStatusFormat(font_family_text, 600, 20, &self.status_clock_time_format) or
            !self.createCenteredStatusFormat(font_family_text, 400, 16, &self.status_weather_format) or
            !self.createCenteredPageFormat(700, 11, &self.pill_line_format) or
            !self.createFormat(font_family_text, 400, 11.5, &self.panel_label_format) or
            !self.createFormat(font_family_icons, 400, 18, &self.panel_icon_format) or
            !self.createPageFormat(400, 11.5, &self.small_body_format) or
            !self.createPageFormat(600, 15, &self.card_title_format) or
            !self.createPageFormat(400, 12, &self.page_body_format) or
            !self.createCenteredPageFormat(400, 10.5, &self.page_caption_format) or
            !self.createPageFormat(600, 16, &self.music_title_format) or
            !self.createPageFormat(400, 12, &self.music_subtitle_format) or
            !self.createPageFormat(400, 11, &self.music_app_format) or
            !self.createTaskTitleFormat(&self.task_title_format) or
            !self.createPageFormat(400, 13, &self.task_active_title_format) or
            !self.createPageFormat(400, 10, &self.music_time_format) or
            !self.createCenteredIconFormat(16, &self.music_glyph_format) or
            !self.createCenteredPageFormat(400, 36, &self.music_note_format) or
            !self.createTextStyleFormat(400, 11, false, &self.card_caption_format) or
            !self.createTextStyleFormat(600, 15, false, &self.card_heading_format) or
            !self.createTextStyleFormat(400, 12, true, &self.card_body_format))
        {
            self.shutdown();
            return false;
        }
        self.refresh();
        return true;
    }

    fn createFormat(self: *TextRenderer, family: [*:0]const u16, weight: u32, size: f32, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, family, null, weight, 0, 5, size, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const no_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 2) >= 0 and align_paragraph(out.*.?, 1) >= 0 and no_wrap(out.*.?, 1) >= 0;
    }

    /// Center only the compact island status formats; other UI styles keep
    /// their current paragraph alignment.
    fn createCenteredStatusFormat(self: *TextRenderer, family: [*:0]const u16, weight: u32, size: f32, out: *Handle) bool {
        if (!self.createFormat(family, weight, size, out)) return false;
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        if (align_paragraph(out.*.?, 2) >= 0) return true;
        releaseCom(out);
        return false;
    }

    fn createTextStyleFormat(self: *TextRenderer, weight: u32, size: f32, wrap: bool, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, font_family_text, null, weight, 0, 5, size, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const word_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 0) >= 0 and align_paragraph(out.*.?, 0) >= 0 and
            word_wrap(out.*.?, if (wrap) 0 else 1) >= 0;
    }

    fn createPageFormat(self: *TextRenderer, weight: u32, size: f32, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, font_family_text, null, weight, 0, 5, size, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const no_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 0) >= 0 and align_paragraph(out.*.?, 1) >= 0 and no_wrap(out.*.?, 1) >= 0;
    }

    /// One-line, leading-aligned title; the caller applies a character-level ellipsis.
    fn createTaskTitleFormat(self: *TextRenderer, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, font_family_text, null, 400, 0, 5, 11, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const no_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 0) >= 0 and align_paragraph(out.*.?, 1) >= 0 and no_wrap(out.*.?, 1) >= 0;
    }

    fn createCenteredPageFormat(self: *TextRenderer, weight: u32, size: f32, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, font_family_text, null, weight, 0, 5, size, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const no_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 2) >= 0 and align_paragraph(out.*.?, 1) >= 0 and no_wrap(out.*.?, 1) >= 0;
    }

    fn createCenteredIconFormat(self: *TextRenderer, size: f32, out: *Handle) bool {
        const factory = self.factory orelse return false;
        const create = comMethod(*const fn (*anyopaque, [*:0]const u16, Handle, u32, u32, u32, f32, [*:0]const u16, *Handle) callconv(.winapi) HResult, factory, 15);
        if (create(factory, font_family_icons, null, 400, 0, 5, size, locale_zh_cn, out) < 0 or out.* == null) return false;
        const align_text = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 3);
        const align_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 4);
        const no_wrap = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, out.*.?, 5);
        return align_text(out.*.?, 2) >= 0 and align_paragraph(out.*.?, 1) >= 0 and no_wrap(out.*.?, 1) >= 0;
    }

    /// Releases only D2D/device-dependent bitmaps while keeping DirectWrite
    /// formats and the current business/page snapshots alive for device rebuild.
    pub fn invalidateDeviceResources(self: *TextRenderer) void {
        releaseCom(&self.music_artwork_cache.bitmap);
        releaseCom(&self.music_background_cache.bitmap);
        releaseCom(&self.music_app_icon_cache.bitmap);
        releaseCom(&self.call_icon_cache.bitmap);
        self.music_artwork_cache = .{};
        self.music_background_cache = .{};
        self.music_app_icon_cache = .{};
        self.call_icon_cache = .{};
        for (&self.feature_icon_bitmaps) |*bitmap| releaseCom(bitmap);
        self.feature_icon_contexts = @splat(null);
        self.feature_icon_revisions = @splat(0);
        self.feature_icon_fingerprints = @splat(0);
        releaseCom(&self.grain_bitmap);
        self.grain_context = null;

        releaseCom(&self.rgba_image_cache.bitmap);
        self.rgba_image_cache = .{};
        self.last_png_bitmap_failure = "";
        self.last_png_bitmap_hresult = 0;
    }

    pub fn shutdown(self: *TextRenderer) void {
        self.invalidateDeviceResources();
        releaseCom(&self.card_body_format);
        releaseCom(&self.card_heading_format);
        releaseCom(&self.card_caption_format);
        releaseCom(&self.panel_icon_format);
        releaseCom(&self.panel_label_format);
        releaseCom(&self.card_title_format);
        releaseCom(&self.small_body_format);
        releaseCom(&self.page_caption_format);
        releaseCom(&self.page_body_format);
        releaseCom(&self.music_glyph_format);
        releaseCom(&self.music_note_format);
        releaseCom(&self.music_time_format);
        releaseCom(&self.music_app_format);
        releaseCom(&self.task_active_title_format);
        releaseCom(&self.task_title_format);
        releaseCom(&self.music_subtitle_format);
        releaseCom(&self.music_title_format);
        releaseCom(&self.status_weather_format);
        releaseCom(&self.status_clock_time_format);
        releaseCom(&self.pill_line_format);
        releaseCom(&self.status_time_format);
        releaseCom(&self.date_format);
        releaseCom(&self.time_format);
        releaseCom(&self.factory);
        self.time_text = @splat(0);
        self.date_text = @splat(0);
        self.last_hour = std.math.maxInt(u16);
        self.last_minute = std.math.maxInt(u16);
        self.last_year = 0;
        self.last_month = 0;
        self.last_day = 0;
    }

    /// Paints one independently floating island surface.
    pub fn drawPillSurface(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, shadow_box_arg: ?Geometry.RoundedBox, opacity_arg: f32) void {
        _ = shadow_box_arg;
        const context = context_arg orelse return;
        if (opacity_arg <= 0.001 or Geometry.width(box.rect) <= 0 or Geometry.height(box.rect) <= 0) return;
        const theme = Theme.currentTheme();
        var adapter = MaterialAdapter{ .owner = self, .context = context };
        const ops = materialDrawOps(&adapter);
        const shape = materialShape(box);
        GlassMaterial.drawSoftShadow(ops, shape, theme.shadow, 10);
        fillRounded(context, .{ .rect = toD2DRect(box.rect), .radius_x = box.radius_x, .radius_y = box.radius_y }, .{
            .r = theme.pill_bottom.r,
            .g = theme.pill_bottom.g,
            .b = theme.pill_bottom.b,
            .a = theme.pill_bottom.a * std.math.clamp(opacity_arg, 0, 1),
        });
    }

    pub fn drawFullscreenMorphSurface(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, fill_opacity_arg: f32, shadow_opacity_arg: f32) void {
        _ = self;
        const context = context_arg orelse return;
        if (Geometry.width(box.rect) <= 0 or Geometry.height(box.rect) <= 0) return;
        const theme = Theme.currentTheme();
        const shadow_opacity = theme.shadow * std.math.clamp(shadow_opacity_arg, 0, 1) * 0.55;
        if (shadow_opacity > 0.001) {
            fillRounded(context, .{
                .rect = .{
                    .left = box.rect.left - 1,
                    .top = box.rect.top + 2,
                    .right = box.rect.right + 1,
                    .bottom = box.rect.bottom + 3,
                },
                .radius_x = box.radius_x + 1,
                .radius_y = box.radius_y + 1,
            }, .{ .r = 0, .g = 0, .b = 0, .a = shadow_opacity });
        }
        fillRounded(context, .{ .rect = toD2DRect(box.rect), .radius_x = box.radius_x, .radius_y = box.radius_y }, .{
            .r = theme.pill_bottom.r,
            .g = theme.pill_bottom.g,
            .b = theme.pill_bottom.b,
            .a = theme.pill_bottom.a * std.math.clamp(fill_opacity_arg, 0, 1),
        });
    }

    /// Paints the common card material used by system, music, tray, Start,
    /// feature, and notification cards.
    pub fn drawCardSurface(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, opacity_arg: f32) void {
        const context = context_arg orelse return;
        if (opacity_arg <= 0.001 or Geometry.width(box.rect) <= 0 or Geometry.height(box.rect) <= 0) return;
        const theme = Theme.currentTheme();
        var adapter = MaterialAdapter{ .owner = self, .context = context };
        const ops = materialDrawOps(&adapter);
        const shape = materialShape(box);
        const shadow_clip = D2DRectF{
            .left = box.rect.left - 22,
            .top = box.rect.top,
            .right = box.rect.right + 22,
            .bottom = box.rect.bottom + 22,
        };
        const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, context, 45);
        const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 46);
        push_clip(context, &shadow_clip, 0);
        GlassMaterial.drawSoftShadow(ops, shape, theme.shadow, 12);
        pop_clip(context);
        fillRounded(context, .{ .rect = toD2DRect(box.rect), .radius_x = box.radius_x, .radius_y = box.radius_y }, .{
            .r = theme.card_fill.r,
            .g = theme.card_fill.g,
            .b = theme.card_fill.b,
            .a = theme.card_fill.a * std.math.clamp(opacity_arg, 0, 1),
        });
    }

    /// Generic feature-page text primitive; page-specific layout stays with its Feature UI.
    pub fn drawLabel(self: *TextRenderer, context_arg: Handle, style: TextStyle, text: []const u16, bounds: Geometry.RectF, color: Theme.Color) bool {
        const context = context_arg orelse return false;
        const format = switch (style) {
            .small_body => self.small_body_format,
            .card_title => self.card_title_format,
            .card_caption => self.card_caption_format,
            .card_heading => self.card_heading_format,
            .card_body => self.card_body_format,
            .icon => self.panel_icon_format orelse self.page_caption_format,
            .page_title => self.status_time_format,
            .page_body => self.page_body_format,
            .page_caption => self.page_caption_format,
        } orelse return false;
        drawTextWithColor(context, format, text, asD2D(color), toD2DRect(bounds));
        return true;
    }

    /// Converts UTF-8 into a bounded temporary UTF-16 buffer, then uses the same generic text styles.
    pub fn drawUtf8Label(self: *TextRenderer, context: Handle, style: TextStyle, text: []const u8, bounds: Geometry.RectF, color: Theme.Color) bool {
        var wide: [1024]u16 = @splat(0);
        const count = utf8ToWide(text, &wide);
        return self.drawLabel(context, style, wide[0..count], bounds, color);
    }

    pub fn fillRoundedRect(self: *TextRenderer, context_arg: Handle, bounds: Geometry.RectF, radius_x: f32, radius_y: f32, color: Theme.Color) void {
        _ = self;
        if (context_arg) |context| fillRounded(context, .{ .rect = toD2DRect(bounds), .radius_x = radius_x, .radius_y = radius_y }, asD2D(color));
    }

    pub fn drawFeatureLine(self: *TextRenderer, context_arg: Handle, from: [2]f32, to: [2]f32, color: Theme.Color, thickness: f32) void {
        _ = self;
        if (context_arg) |context| drawLine(context, .{ .x = from[0], .y = from[1] }, .{ .x = to[0], .y = to[1] }, asD2D(color), thickness);
    }

    pub fn drawCenteredIconGlyph(self: *TextRenderer, context_arg: Handle, glyph: u16, bounds: Geometry.RectF, opacity: f32) bool {
        const context = context_arg orelse return false;
        const format = self.music_glyph_format orelse return false;
        const text: [2]u16 = .{ glyph, 0 };
        drawTextWithColor(context, format, &text, asD2D(Theme.themeInk(opacity)), toD2DRect(bounds));
        return true;
    }

    pub fn pushClip(self: *TextRenderer, context_arg: Handle, clip: Geometry.RectF) void {
        _ = self;
        if (context_arg) |context| {
            const rect = toD2DRect(clip);
            const push = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, context, 45);
            push(context, &rect, 0);
        }
    }

    pub fn popClip(self: *TextRenderer, context_arg: Handle) void {
        _ = self;
        if (context_arg) |context| {
            const pop = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 46);
            pop(context);
        }
    }

    pub fn drawSlider(self: *TextRenderer, context: Handle, bounds: Geometry.RectF, view: Slider.ViewModel, opacity: f32) bool {
        _ = self;
        if (context == null) return false;
        const canvas = CanvasModule.Canvas{ .context = context, .fill_rounded_rect_fn = canvasFillRoundedRect, .fill_ellipse_fn = canvasFillEllipse };
        Slider.paint(&canvas, bounds, view, opacity);
        return true;
    }

    pub fn drawPngIcon(self: *TextRenderer, context_arg: Handle, cache_index: usize, png: []const u8, revision: u64, bounds: Geometry.RectF, opacity: f32) bool {
        const context = context_arg orelse return false;
        const bitmap = self.featureIconBitmap(context, cache_index, png, revision) orelse return false;
        const draw = comMethod(*const fn (*anyopaque, *anyopaque, *const D2DRectF, f32, i32, ?*const D2DRectF) callconv(.winapi) void, context, 26);
        const destination = toD2DRect(bounds);
        draw(context, bitmap, &destination, opacity, d2d_bitmap_interpolation_linear, null);
        return true;
    }

    /// Draws caller-owned premultiplied BGRA pixels through a generic, device-bound image cache.
    pub fn drawRgbaImage(self: *TextRenderer, context_arg: Handle, pixels: ?[]const u8, width: i32, height: i32, revision: u64, bounds: Geometry.RectF, opacity: f32) bool {
        const context = context_arg orelse return false;
        const bitmap = self.rawPixelBitmap(context, &self.rgba_image_cache, pixels, width, height, revision) orelse return pixels == null;
        const draw = comMethod(*const fn (*anyopaque, *anyopaque, *const D2DRectF, f32, i32, ?*const D2DRectF) callconv(.winapi) void, context, 26);
        const destination = toD2DRect(bounds);
        draw(context, bitmap, &destination, std.math.clamp(opacity, 0, 1), d2d_bitmap_interpolation_linear, null);
        return true;
    }

    pub fn clearPngIcon(self: *TextRenderer, cache_index: usize) void {
        if (cache_index >= self.feature_icon_bitmaps.len) return;
        releaseCom(&self.feature_icon_bitmaps[cache_index]);
        self.feature_icon_contexts[cache_index] = null;
        self.feature_icon_revisions[cache_index] = 0;
        self.feature_icon_fingerprints[cache_index] = 0;
    }

    fn featureIconBitmap(self: *TextRenderer, context: *anyopaque, index: usize, png: []const u8, revision: u64) ?*anyopaque {
        if (index >= self.feature_icon_bitmaps.len or png.len == 0) return null;
        const fingerprint = imageFingerprint(png);
        if (self.feature_icon_contexts[index] == context and self.feature_icon_bitmaps[index] != null and self.feature_icon_revisions[index] == revision and self.feature_icon_fingerprints[index] == fingerprint) return self.feature_icon_bitmaps[index];
        if (self.feature_icon_contexts[index] != context) releaseCom(&self.feature_icon_bitmaps[index]);
        var decoded = WicImage.DecodedImage{};
        if (!WicImage.decodeImage(png, &decoded, .icon) or decoded.width <= 0 or decoded.height <= 0) return self.feature_icon_bitmaps[index];
        const properties = D2DBitmapProperties1{ .pixel_format = .{ .format = 87, .alpha_mode = 1 }, .dpi_x = 96, .dpi_y = 96, .options = 0, .color_context = null };
        const bitmap_size = D2DSizeU{ .width = @intCast(decoded.width), .height = @intCast(decoded.height) };
        const stride: u32 = @intCast(@as(u64, @intCast(decoded.width)) * 4);
        var bitmap: Handle = null;
        const create = comMethod(*const fn (*anyopaque, D2DSizeU, ?[*]const u8, u32, *const D2DBitmapProperties1, *Handle) callconv(.winapi) HResult, context, 4);
        if (create(context, bitmap_size, decoded.pixels, stride, &properties, &bitmap) < 0 or bitmap == null) return self.feature_icon_bitmaps[index];
        releaseCom(&self.feature_icon_bitmaps[index]);
        self.feature_icon_bitmaps[index] = bitmap;
        self.feature_icon_contexts[index] = context;
        self.feature_icon_revisions[index] = revision;
        self.feature_icon_fingerprints[index] = fingerprint;
        return bitmap;
    }

    pub fn drawClock(self: *TextRenderer, context: Handle, box: Geometry.RoundedBox, style: ClockStyle, opacity_arg: f32) bool {
        if (context == null or self.factory == null or self.time_format == null) return false;
        self.refresh();

        const opacity = @max(0, @min(1, opacity_arg));
        const ink = Theme.themeInk(opacity);
        const color = D2DColor{ .r = ink.r, .g = ink.g, .b = ink.b, .a = ink.a };
        var brush: Handle = null;
        const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context.?, 8);
        if (create_brush(context.?, &color, null, &brush) < 0 or brush == null) return false;
        defer releaseCom(&brush);

        const rect = box.rect;
        if (style == .compact) {
            drawText(context.?, self.time_format.?, &self.time_text, brush.?, .{ .left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom });
        } else {
            const half = (rect.bottom - rect.top) * 0.5;
            drawText(context.?, self.time_format.?, &self.time_text, brush.?, .{ .left = rect.left, .top = rect.top + half * 0.06, .right = rect.right, .bottom = rect.top + half * 0.56 });
            drawText(context.?, self.date_format.?, &self.date_text, brush.?, .{ .left = rect.left, .top = rect.top + half * 0.50, .right = rect.right, .bottom = rect.top + half * 0.88 });
        }
        return true;
    }

    /// Draws UTF-8 track text in the pill using the same centered DirectWrite
    /// format as the status line. The input is bounded and converted without
    /// splitting a multibyte character.
    pub fn drawInlineText(self: *TextRenderer, context: Handle, box: Geometry.RoundedBox, text: []const u8, opacity_arg: f32) bool {
        if (context == null or self.factory == null or self.status_time_format == null or text.len == 0) return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01) return true;

        var wide: [512]u16 = @splat(0);
        var byte_count = @min(text.len, 512);
        var wide_count: i32 = 0;
        while (byte_count > 0) : (byte_count -= 1) {
            wide_count = MultiByteToWideChar(65001, 8, text.ptr, @intCast(byte_count), &wide, wide.len);
            if (wide_count > 0) break;
        }
        if (wide_count <= 0) return false;

        const ink = Theme.themeInk(opacity);
        const color = D2DColor{ .r = ink.r, .g = ink.g, .b = ink.b, .a = ink.a };
        var brush: Handle = null;
        const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context.?, 8);
        if (create_brush(context.?, &color, null, &brush) < 0 or brush == null) return false;
        defer releaseCom(&brush);
        const rect = box.rect;
        drawText(context.?, self.status_time_format.?, wide[0..@intCast(wide_count)], brush.?, .{
            .left = rect.left + 8,
            .top = rect.top,
            .right = @max(rect.left + 8, rect.right - 8),
            .bottom = rect.bottom,
        });
        return true;
    }

    /// Draws the pill's one-line track or lyric label. Long lines scroll in a
    /// seamless loop; changing lyric lines roll upward through a one-line clip.
    pub fn drawScrollingLine(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, text: []const u8, scroll_dip: f32, opacity_arg: f32, roll_progress_arg: f32, previous: []const u8, previous_scroll_dip: f32) bool {
        const context = context_arg orelse return false;
        if (self.factory == null or text.len == 0) return false;
        const format = self.pill_line_format orelse self.status_time_format orelse return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01) return true;

        var wide: [512]u16 = @splat(0);
        const count = utf8ToWide(text, &wide);
        if (count == 0) return false;
        const width = box.rect.right - box.rect.left;
        const height = box.rect.bottom - box.rect.top;
        if (width <= 0 or height <= 0) return true;
        var pill_mask = pushRoundedMask(context, box);
        defer popRoundedMask(context, &pill_mask);
        const measured = self.metrics();
        const line_height = if (measured.pill_line_height > 1) measured.pill_line_height else 16;
        const mid_y = (box.rect.top + box.rect.bottom) * 0.5;
        const line_clip_half = line_height * 0.5 + 1;
        const clip = D2DRectF{
            .left = box.rect.left + @min(10, width * 0.12),
            .top = mid_y - line_clip_half,
            .right = box.rect.right - @min(10, width * 0.12),
            .bottom = mid_y + line_clip_half,
        };
        const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, context, 45);
        const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 46);
        push_clip(context, &clip, 0);
        defer pop_clip(context);

        const ink = Theme.themeInk(opacity);
        var brush: Handle = null;
        const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context, 8);
        const color = asD2D(ink);
        if (create_brush(context, &color, null, &brush) < 0 or brush == null) return false;
        defer releaseCom(&brush);
        var end_fade = createScrollingLineFadeBrush(context, box.rect, opacity);
        defer releaseCom(&end_fade);

        const text_width = measureTextWidth(self.factory.?, format, wide[0..count]);
        const progress = std.math.clamp(roll_progress_arg, 0, 1);
        const entering_y = (1 - progress) * line_height;
        const leaving_y = progress * line_height;
        if (progress < 1 and previous.len != 0) {
            var old_wide: [512]u16 = @splat(0);
            const old_count = utf8ToWide(previous, &old_wide);
            if (old_count != 0) drawScrollingLineRun(context, format, brush.?, old_wide[0..old_count], measureTextWidth(self.factory.?, format, old_wide[0..old_count]), width, box.rect.left, mid_y - leaving_y, previous_scroll_dip, line_height, box.rect, end_fade);
        }
        drawScrollingLineRun(context, format, brush.?, wide[0..count], text_width, width, box.rect.left, mid_y + entering_y, scroll_dip, line_height, box.rect, end_fade);
        return true;
    }

    /// Uses the drawing format itself to decide whether the line needs the
    /// marquee, keeping the frame loop and renderer on the same threshold.
    pub fn scrollingLineNeedsScroll(self: *TextRenderer, text: []const u8, strip_width: f32) bool {
        if (self.factory == null or text.len == 0) return false;
        const format = self.pill_line_format orelse self.status_time_format orelse return false;
        var wide: [512]u16 = @splat(0);
        const count = utf8ToWide(text, &wide);
        if (count == 0) return false;
        return lineNeedsScrollForWidth(measureTextWidth(self.factory.?, format, wide[0..count]), strip_width);
    }

    /// Paints the live music level behind the lyric as a filled, continuously
    /// moving ribbon. The amplitude and envelope are shared with diagnostics.
    pub fn drawAudioWave(_: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, phase: f32, level_arg: f32, accent: Theme.Color, opacity_arg: f32) void {
        const context = context_arg orelse return;
        const width = box.rect.right - box.rect.left;
        const height = box.rect.bottom - box.rect.top;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (height <= 4 or width <= 8 or opacity <= 0.01 or accent.a <= 0) return;
        var pill_mask = pushRoundedMask(context, box);
        defer popRoundedMask(context, &pill_mask);
        const level = std.math.clamp(level_arg, 0, 1);
        const mid_y = (box.rect.top + box.rect.bottom) * 0.5;
        const scale = (0.32 + 0.68 * level) * (height * 0.5 - 1);
        const clip = D2DRectF{ .left = box.rect.left + 3, .top = box.rect.top, .right = box.rect.right - 3, .bottom = box.rect.bottom };
        const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, context, 45);
        const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 46);
        push_clip(context, &clip, 0);
        defer pop_clip(context);

        var factory: Handle = null;
        const get_factory = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) void, context, 3);
        get_factory(context, &factory);
        if (factory == null) return;
        defer releaseCom(&factory);

        var path: Handle = null;
        const create_path = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, factory.?, 10);
        if (create_path(factory.?, &path) < 0 or path == null) return;
        defer releaseCom(&path);
        var sink: Handle = null;
        const open = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) HResult, path.?, 17);
        if (open(path.?, &sink) < 0 or sink == null) return;
        defer releaseCom(&sink);
        const begin = comMethod(*const fn (*anyopaque, D2DPointF, i32) callconv(.winapi) void, sink.?, 5);
        const add_line = comMethod(*const fn (*anyopaque, D2DPointF) callconv(.winapi) void, sink.?, 10);
        const end = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) void, sink.?, 8);
        const close = comMethod(*const fn (*anyopaque) callconv(.winapi) HResult, sink.?, 9);
        const steps: i32 = 48;
        begin(sink.?, .{ .x = box.rect.left, .y = mid_y - audioWaveEnvelope(0, steps, phase) * scale }, 0);
        for (1..@as(usize, @intCast(steps)) + 1) |i| {
            const step: i32 = @intCast(i);
            const x = box.rect.left + width * @as(f32, @floatFromInt(step)) / @as(f32, @floatFromInt(steps));
            add_line(sink.?, .{ .x = x, .y = mid_y - audioWaveEnvelope(step, steps, phase) * scale });
        }
        var i = steps;
        while (i >= 0) : (i -= 1) {
            const x = box.rect.left + width * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            add_line(sink.?, .{ .x = x, .y = mid_y + audioWaveEnvelope(i, steps, phase) * scale });
        }
        end(sink.?, 1);
        if (close(sink.?) < 0) return;

        const stops = [_]D2DGradientStop{
            .{ .position = 0, .color = .{ .r = accent.r, .g = accent.g, .b = accent.b, .a = opacity * 0.75 } },
            .{ .position = 0.5, .color = .{ .r = accent.r, .g = accent.g, .b = accent.b, .a = opacity * 0.35 } },
            .{ .position = 1, .color = .{ .r = accent.r, .g = accent.g, .b = accent.b, .a = opacity * 0.75 } },
        };
        var collection: Handle = null;
        const create_collection = comMethod(*const fn (*anyopaque, [*]const D2DGradientStop, u32, i32, i32, *Handle) callconv(.winapi) HResult, context, 9);
        if (create_collection(context, &stops, stops.len, 0, 0, &collection) < 0 or collection == null) return;
        defer releaseCom(&collection);
        const properties = D2DLinearGradientBrushProperties{
            .start_point = .{ .x = box.rect.left, .y = box.rect.top },
            .end_point = .{ .x = box.rect.left, .y = box.rect.bottom },
        };
        var brush: Handle = null;
        const create_brush = comMethod(*const fn (*anyopaque, *const D2DLinearGradientBrushProperties, ?*const anyopaque, *anyopaque, *Handle) callconv(.winapi) HResult, context, 10);
        if (create_brush(context, &properties, null, collection.?, &brush) < 0 or brush == null) return;
        defer releaseCom(&brush);
        const fill = comMethod(*const fn (*anyopaque, *anyopaque, *anyopaque, Handle) callconv(.winapi) void, context, 23);
        fill(context, path.?, brush.?, null);
    }

    /// Draws a value-only SystemPanel presentation using the feature-provided shared layout.
    pub fn drawSystemPanel(self: *TextRenderer, context: Handle, box: Geometry.RoundedBox, panel: *const SystemPanelText, opacity_arg: f32) bool {
        if (context == null or self.panel_label_format == null or self.panel_icon_format == null) return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01) return true;
        const layout = panel.layout;
        const theme = Theme.currentTheme();
        self.drawCardSurface(context.?, box, opacity);

        for (0..@intCast(layout.tile_count)) |index| {
            const tile = panel.tiles[index];
            const rect = layout.tiles[index];
            const rounded = D2DRoundedRect{ .rect = .{ .left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom }, .radius_x = 8, .radius_y = 8 };
            if (tile.on) {
                const accent = theme.tokens.accent;
                fillRounded(context.?, rounded, .{ .r = accent.r, .g = accent.g, .b = accent.b, .a = accent.a * 0.97 * opacity });
            } else {
                fillRounded(context.?, rounded, asD2D(Theme.themeInk(0.055 * opacity)));
            }

            const glyph = [_]u16{ indicatorGlyph(@fromBackingInt(@intCast(tile.icon)), tile.icon_value), 0 };
            if (glyph[0] != 0) drawTextWithColor(context.?, self.panel_icon_format.?, &glyph, asD2D(Theme.themeInk(0.98 * opacity)), toD2DRect(layout.tile_icons[index]));

            if (tile.chevron) {
                const chevron = [_]u16{ 0xE76C, 0 };
                const chevron_box = Geometry.RectF{ .left = rect.right - 30, .right = rect.right - 8, .top = rect.top + 10, .bottom = rect.bottom - 10 };
                drawTextWithColor(context.?, self.panel_icon_format.?, &chevron, asD2D(Theme.themeInk(0.72 * opacity)), toD2DRect(chevron_box));
            }

            const caption = tile.state_text orelse tile.label;
            if (caption) |text| {
                drawTextWithColor(context.?, self.panel_label_format.?, std.mem.span(text), asD2D(Theme.themeInk(0.94 * opacity)), toD2DRect(layout.tile_labels[index]));
            }
        }

        for (0..@intCast(layout.slider_count)) |index| {
            const track = layout.sliders[index];
            const center_y = (track.top + track.bottom) * 0.5;
            const brightness = index == 1;
            var fraction = if (brightness) panel.brightness else panel.volume;
            fraction = std.math.clamp(fraction, 0, 1);
            if (!brightness and panel.muted) fraction = 0;
            const icon: SystemPanelIcon = if (brightness) .brightness else .volume;
            const glyph = [_]u16{ indicatorGlyph(icon, if (brightness) @intFromFloat(fraction * 100) else if (panel.muted) 0 else @intFromFloat(fraction * 100)), 0 };
            const icon_rect = if (brightness) layout.brightness_icon else layout.speaker_icon;
            if (glyph[0] != 0) drawTextWithColor(context.?, self.panel_icon_format.?, &glyph, asD2D(Theme.themeInk(0.94 * opacity)), toD2DRect(icon_rect));
            const track_rect = D2DRoundedRect{ .rect = .{ .left = track.left, .top = center_y - 2, .right = track.right, .bottom = center_y + 2 }, .radius_x = 2, .radius_y = 2 };
            fillRounded(context.?, track_rect, asD2D(Theme.themeInk(0.22 * opacity)));
            const handle_x = track.left + (track.right - track.left) * fraction;
            if (handle_x > track.left) fillRounded(context.?, .{ .rect = .{ .left = track.left, .top = center_y - 2, .right = handle_x, .bottom = center_y + 2 }, .radius_x = 2, .radius_y = 2 }, asD2D(theme.tokens.accent));
            fillEllipse(context.?, .{ .point = .{ .x = handle_x, .y = center_y }, .radius_x = 6.5 + 2 * std.math.clamp(panel.slider_emphasis[index], 0, 1), .radius_y = 6.5 + 2 * std.math.clamp(panel.slider_emphasis[index], 0, 1) }, asD2D(Theme.themeInk(0.96 * opacity)));
            if ((if (brightness) panel.show_brightness_percent else panel.show_volume_percent)) {
                var percentage: [8]u16 = @splat(0);
                const value = @as(u32, @intFromFloat(@round(fraction * 100)));
                var ascii: [8]u8 = undefined;
                const rendered = std.fmt.bufPrint(&ascii, "{d}%", .{value}) catch &.{};
                for (rendered, 0..) |byte, char_index| percentage[char_index] = byte;
                drawTextWithColor(context.?, self.panel_label_format.?, &percentage, asD2D(Theme.themeInk(0.9 * opacity)), .{ .left = handle_x - 22, .right = handle_x + 22, .top = track.top - 14, .bottom = track.top });
            }
        }

        const gear = [_]u16{ indicatorGlyph(.settings, 0), 0 };
        drawTextWithColor(context.?, self.panel_icon_format.?, &gear, asD2D(Theme.themeInk(0.8 * opacity)), toD2DRect(layout.gear_button));
        if (layout.page_dot_count > 0) {
            for (0..@intCast(layout.page_dot_count)) |index| {
                const dot = layout.page_dots[index];
                fillEllipse(context.?, .{ .point = .{ .x = (dot.left + dot.right) * 0.5, .y = (dot.top + dot.bottom) * 0.5 }, .radius_x = (dot.right - dot.left) * 0.5, .radius_y = (dot.bottom - dot.top) * 0.5 }, asD2D(Theme.themeInk(if (@as(i32, @intCast(index)) == panel.page_index) 0.95 * opacity else 0.35 * opacity)));
            }
            const up = [_]u16{ 0xE70E, 0 };
            const down = [_]u16{ 0xE70D, 0 };
            drawTextWithColor(context.?, self.panel_icon_format.?, &up, asD2D(Theme.themeInk(0.72 * opacity)), toD2DRect(layout.page_up));
            drawTextWithColor(context.?, self.panel_icon_format.?, &down, asD2D(Theme.themeInk(0.72 * opacity)), toD2DRect(layout.page_down));
        }
        return true;
    }

    /// Draws the sender, title, and wrapped body of a notification into the
    /// expanded island surface. All incoming text is UTF-8 from the named pipe.
    /// Draws the expanded media card from the same layout used by its hit tests.
    /// Artwork and the player icon are cached per D2D context and revision so a
    /// redraw does not upload the same image to the GPU on every frame.
    pub fn drawMediaCard(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, layout: MediaCardLayout, card: *const MediaCardContent, opacity_arg: f32) bool {
        const context = context_arg orelse return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01 or (card.title.len == 0 and card.artist.len == 0)) return true;
        self.last_png_bitmap_failure = "";
        self.last_png_bitmap_hresult = 0;
        const theme = Theme.currentTheme();
        self.drawCardSurface(context, box, opacity);

        var title: [256]u16 = @splat(0);
        var artist: [256]u16 = @splat(0);
        var album: [256]u16 = @splat(0);
        var app: [192]u16 = @splat(0);
        const title_len = utf8ToWide(card.title, &title);
        const artist_len = utf8ToWide(card.artist, &artist);
        const album_len = utf8ToWide(card.album, &album);
        const app_len = utf8ToWide(card.app, &app);
        _ = title_len;
        _ = app_len;

        const primary = D2DColor{ .r = 1, .g = 1, .b = 1, .a = opacity };
        const secondary = D2DColor{ .r = 0.90, .g = 0.92, .b = 0.96, .a = 0.88 * opacity };
        const accent = D2DColor{ .r = theme.tokens.accent.r, .g = theme.tokens.accent.g, .b = theme.tokens.accent.b, .a = opacity };

        {
            var artwork_mask = pushRoundedMask(context, .{ .rect = layout.artwork, .radius_x = 8, .radius_y = 8 });
            defer popRoundedMask(context, &artwork_mask);
            if (self.musicPngBitmap(context, &self.music_artwork_cache, card.artwork_png, card.artwork_revision, .artwork)) |bitmap| {
                const width = @as(f32, @floatFromInt(self.music_artwork_cache.width));
                const height = @as(f32, @floatFromInt(self.music_artwork_cache.height));
                if (width > 0 and height > 0) {
                    const side = Geometry.width(layout.artwork);
                    const scale = @max(side / width, side / height);
                    const drawn_width = width * scale;
                    const drawn_height = height * scale;
                    const centre_x = (layout.artwork.left + layout.artwork.right) * 0.5;
                    const centre_y = (layout.artwork.top + layout.artwork.bottom) * 0.5;
                    drawMusicBitmap(context, bitmap, .{
                        .left = centre_x - drawn_width * 0.5,
                        .top = centre_y - drawn_height * 0.5,
                        .right = centre_x + drawn_width * 0.5,
                        .bottom = centre_y + drawn_height * 0.5,
                    }, opacity, 1);
                }
            } else {
                fillRounded(context, .{ .rect = toD2DRect(layout.artwork), .radius_x = 8, .radius_y = 8 }, asD2D(Theme.themeInk(0.09 * opacity)));
                if (self.music_note_format) |format| drawTextWithColor(context, format, &.{ 0x266a, 0 }, secondary, toD2DRect(layout.artwork));
            }
        }
        if (self.musicPngBitmap(context, &self.music_app_icon_cache, card.app_icon_png, card.app_icon_revision, .icon)) |bitmap| {
            drawMusicBitmap(context, bitmap, layout.app_icon, opacity, 1);
        } else {
            const center = D2DEllipse{ .point = .{ .x = (layout.app_icon.left + layout.app_icon.right) * 0.5, .y = (layout.app_icon.top + layout.app_icon.bottom) * 0.5 }, .radius_x = layout.app_icon_size * 0.5, .radius_y = layout.app_icon_size * 0.5 };
            fillEllipse(context, center, accent);
        }
        const app_text: []const u16 = if (app[0] != 0) &app else &.{ 'M', 'e', 'd', 'i', 'a', 0 };
        if (self.music_app_format) |format| drawTextWithColor(context, format, app_text, secondary, toD2DRect(layout.app_text));
        if (self.music_title_format) |format| drawTextWithColor(context, format, &title, primary, toD2DRect(layout.title));

        var subtitle_bytes: [640]u8 = undefined;
        var subtitle_wide: [320]u16 = @splat(0);
        const subtitle = if (artist_len != 0 and album_len != 0 and !std.mem.eql(u16, artist[0..artist_len], album[0..album_len]))
            std.fmt.bufPrint(&subtitle_bytes, "{s} · {s}", .{ card.artist, card.album }) catch ""
        else if (artist_len != 0)
            card.artist
        else
            card.app;
        _ = utf8ToWide(subtitle, &subtitle_wide);
        if (self.music_subtitle_format) |format| drawTextWithColor(context, format, &subtitle_wide, secondary, toD2DRect(layout.subtitle));

        var elapsed_bytes: [24]u8 = undefined;
        var total_bytes: [24]u8 = undefined;
        var elapsed_wide: [24]u16 = @splat(0);
        var total_wide: [24]u16 = @splat(0);
        const elapsed_len = formatPosition(card.position_ms, &elapsed_bytes);
        const total_len = if (card.duration_ms > 0) formatPosition(card.duration_ms, &total_bytes) else 0;
        _ = utf8ToWide(elapsed_bytes[0..elapsed_len], &elapsed_wide);
        if (total_len > 0) {
            _ = utf8ToWide(total_bytes[0..total_len], &total_wide);
        } else {
            const unknown_time = [_]u16{ '-', '-', ':', '-', '-' };
            @memcpy(total_wide[0..5], &unknown_time);
        }
        const progress = std.math.clamp(card.progress_fraction, 0, 1);
        if (self.music_time_format) |format| {
            drawTextWithColor(context, format, &elapsed_wide, secondary, toD2DRect(layout.elapsed));
            drawTextWithColor(context, format, &total_wide, secondary, toD2DRect(layout.remaining));
        }

        const bar_left = layout.elapsed.right + 6;
        const bar_right = layout.remaining.left - 6;
        if (bar_right > bar_left + 8) {
            fillRounded(context, .{ .rect = .{ .left = bar_left, .top = layout.progress.top, .right = bar_right, .bottom = layout.progress.bottom }, .radius_x = 2, .radius_y = 2 }, asD2D(Theme.themeInk(0.22 * opacity)));
            const filled = bar_left + (bar_right - bar_left) * progress;
            if (filled > bar_left + 1) fillRounded(context, .{ .rect = .{ .left = bar_left, .top = layout.progress.top, .right = filled, .bottom = layout.progress.bottom }, .radius_x = 2, .radius_y = 2 }, accent);
        }

        const center_y = (layout.controls.top + layout.controls.bottom) * 0.5;
        const play_center_x = (layout.play_pause.left + layout.play_pause.right) * 0.5;
        const play_radius = (layout.play_pause.right - layout.play_pause.left) * 0.5;
        fillEllipse(context, .{ .point = .{ .x = play_center_x, .y = center_y }, .radius_x = play_radius, .radius_y = play_radius }, .{ .r = accent.r, .g = accent.g, .b = accent.b, .a = 0.32 * opacity });
        if (self.music_glyph_format) |format| {
            const previous: [2]u16 = .{ 0xe892, 0 };
            const play_pause: [2]u16 = .{ if (card.playing) 0xe769 else 0xe768, 0 };
            const next: [2]u16 = .{ 0xe893, 0 };
            const previous_box = D2DRectF{ .left = layout.previous.left, .top = center_y - 14, .right = layout.previous.right, .bottom = center_y + 14 };
            const play_box = D2DRectF{ .left = layout.play_pause.left, .top = center_y - 14, .right = layout.play_pause.right, .bottom = center_y + 14 };
            const next_box = D2DRectF{ .left = layout.next.left, .top = center_y - 14, .right = layout.next.right, .bottom = center_y + 14 };
            drawTextWithColor(context, format, &previous, primary, previous_box);
            drawTextWithColor(context, format, &play_pause, primary, play_box);
            drawTextWithColor(context, format, &next, primary, next_box);
        }
        return true;
    }

    /// Draws the application-group row from the Feature UI's presented
    /// geometry. TextRenderer does not calculate taskbar layout.
    pub fn drawTaskIcons(
        self: *TextRenderer,
        context_arg: Handle,
        buttons: []const TaskButton,
        opacity_arg: f32,
    ) bool {
        const context = context_arg orelse return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        const count = buttons.len;
        if (count == 0 or opacity <= 0.01) return true;

        for (buttons[0..count]) |button| {
            const button_opacity = opacity * std.math.clamp(button.visual_opacity, 0, 1);
            if (button_opacity <= 0.005) continue;
            const box = transformTaskRect(button.bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
            if (box.right <= box.left or box.bottom <= box.top) continue;
            const side = @min(box.right - box.left, box.bottom - box.top);
            const rounded = D2DRoundedRect{
                .rect = toD2DRect(box),
                .radius_x = side * 0.5,
                .radius_y = side * 0.5,
            };
            const hover = @max(button.hover_progress, 0);
            const hover_effect = @min(hover, 1);

            fillRounded(context, rounded, .{ .r = 0.055, .g = 0.067, .b = 0.084, .a = button_opacity });
            if (button.active) {
                fillRounded(context, rounded, .{ .r = 0.29, .g = 0.60, .b = 0.98, .a = 0.11 * button_opacity });
            }
            if (hover > 0.01) {
                fillRounded(context, rounded, .{ .r = 0.29, .g = 0.60, .b = 0.98, .a = 0.10 * button_opacity * hover_effect });
            }

            if (button.icon) |icon| {
                drawMusicBitmap(context, icon, transformTaskRect(button.icon_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y), button_opacity, 0);
            }
            if (button.window_count > 1) drawWindowStackMark(context, transformTaskRect(button.icon_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y), button_opacity);

            if (button.title) |task_title| {
                const title_bounds = transformTaskRect(button.title_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
                const title_width = title_bounds.right - title_bounds.left;
                const title_opacity = std.math.clamp((title_width - 16) / 32, 0, 1) * button_opacity;
                if (task_title[0] != 0 and title_opacity > 0.01 and button.title_bounds.right > button.title_bounds.left) {
                    const color = D2DColor{
                        .r = 0.94,
                        .g = 0.95,
                        .b = 0.98,
                        .a = title_opacity,
                    };
                    drawTaskTitle(self, context, std.mem.span(task_title), button.active, color, title_bounds, @max(12, self.metrics().secondary_line_height));
                }
            }

            if (button.active) {
                const indicator_width = @max(16, box.right - box.left - 22 * button.visual_scale);
                const indicator_left = box.left + 11 * button.visual_scale;
                const indicator = D2DRoundedRect{
                    .rect = .{ .left = indicator_left, .top = box.bottom + 2 * button.visual_scale, .right = indicator_left + indicator_width, .bottom = box.bottom + 5 * button.visual_scale },
                    .radius_x = 1.5 * button.visual_scale,
                    .radius_y = 1.5 * button.visual_scale,
                };
                fillRounded(context, indicator, .{ .r = 0.28, .g = 0.64, .b = 1, .a = 0.98 * button_opacity });
            }
        }
        return true;
    }

    fn transformTaskRect(rect: Geometry.RectF, button: Geometry.RectF, scale: f32, offset_x: f32, offset_y: f32) Geometry.RectF {
        const safe_scale = @max(0, scale);
        const centre_x = (button.left + button.right) * 0.5;
        const centre_y = (button.top + button.bottom) * 0.5;
        return .{
            .left = centre_x + (rect.left - centre_x) * safe_scale + offset_x,
            .top = centre_y + (rect.top - centre_y) * safe_scale + offset_y,
            .right = centre_x + (rect.right - centre_x) * safe_scale + offset_x,
            .bottom = centre_y + (rect.bottom - centre_y) * safe_scale + offset_y,
        };
    }

    /// Draws the independently floating overflow surface, its retained system
    /// entries, and the task buttons that do not fit in the top row.
    pub fn drawTaskOverflow(
        self: *TextRenderer,
        context_arg: Handle,
        box: Geometry.RoundedBox,
        buttons: []const TaskButton,
        system_entry: Geometry.RectF,
        tray_entry: Geometry.RectF,
        system_hover: f32,
        tray_hover: f32,
        opacity_arg: f32,
    ) bool {
        const context = context_arg orelse return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01 or Geometry.width(box.rect) <= 0) return true;
        self.drawCardSurface(context, box, opacity);

        const title = [_]u16{ 0x66f4, 0x591a, 0x4efb, 0x52a1 };
        if (self.small_body_format) |format| {
            drawTextWithColor(context, format, &title, .{ .r = 0.95, .g = 0.96, .b = 0.98, .a = 0.94 * opacity }, .{
                .left = box.rect.left + 14,
                .top = box.rect.top + 10,
                .right = box.rect.left + 120,
                .bottom = box.rect.top + 31,
            });
        }

        self.drawOverflowAction(context, system_entry, true, system_hover, opacity);
        self.drawOverflowAction(context, tray_entry, false, tray_hover, opacity);

        const line_height = @max(12, self.metrics().secondary_line_height);
        for (buttons) |button| {
            const button_opacity = opacity * std.math.clamp(button.visual_opacity, 0, 1);
            if (button_opacity <= 0.005) continue;
            const bounds = transformTaskRect(button.bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
            if (bounds.right <= bounds.left or bounds.bottom <= bounds.top) continue;
            const tile = D2DRoundedRect{ .rect = toD2DRect(bounds), .radius_x = 12, .radius_y = 12 };
            fillRounded(context, tile, .{ .r = 0.08, .g = 0.093, .b = 0.112, .a = button_opacity });
            if (button.active) fillRounded(context, tile, .{ .r = 0.20, .g = 0.38, .b = 0.60, .a = 0.38 * button_opacity });
            if (button.icon) |icon| {
                const icon_box = transformTaskRect(button.icon_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
                drawMusicBitmap(context, icon, icon_box, button_opacity, 1);
            }
            const icon_box = transformTaskRect(button.icon_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
            if (button.window_count > 1) drawWindowStackMark(context, icon_box, button_opacity);
            if (button.title) |task_title| {
                if (task_title[0] != 0) {
                    const title_bounds = transformTaskRect(button.title_bounds, button.bounds, button.visual_scale, 0, button.visual_offset_y);
                    drawTaskTitle(self, context, std.mem.span(task_title), button.active, .{
                        .r = 0.89,
                        .g = 0.90,
                        .b = 0.93,
                        .a = 0.9 * button_opacity,
                    }, title_bounds, line_height);
                }
            }
        }
        return true;
    }

    fn drawOverflowAction(self: *TextRenderer, context: *anyopaque, bounds: Geometry.RectF, system: bool, hover: f32, opacity: f32) void {
        if (bounds.right <= bounds.left or bounds.bottom <= bounds.top) return;
        const shape = D2DRoundedRect{ .rect = toD2DRect(bounds), .radius_x = 7, .radius_y = 7 };
        fillRounded(context, shape, .{ .r = 0.08, .g = 0.093, .b = 0.112, .a = opacity });
        if (hover > 0.01) fillRounded(context, shape, .{ .r = 0.29, .g = 0.60, .b = 0.98, .a = 0.12 * opacity * std.math.clamp(hover, 0, 1) });
        const cx = (bounds.left + bounds.right) * 0.5;
        const cy = bounds.top + 11;
        const ink = D2DColor{ .r = 0.86, .g = 0.89, .b = 0.94, .a = 0.94 * opacity };
        if (system) {
            fillEllipse(context, .{ .point = .{ .x = cx, .y = cy }, .radius_x = 4.1, .radius_y = 4.1 }, ink);
            fillEllipse(context, .{ .point = .{ .x = cx, .y = cy }, .radius_x = 1.7, .radius_y = 1.7 }, .{ .r = 0.055, .g = 0.067, .b = 0.084, .a = opacity });
            for (0..4) |index| {
                const dx: f32 = if (index % 2 == 0) 7 else 0;
                const dy: f32 = if (index % 2 == 1) 7 else 0;
                const sign_x: f32 = if (index == 1 or index == 2) -1 else 1;
                const sign_y: f32 = if (index >= 2) -1 else 1;
                drawLine(context, .{ .x = cx + dx * sign_x, .y = cy + dy * sign_y }, .{ .x = cx + (dx + 2) * sign_x, .y = cy + (dy + 2) * sign_y }, ink, 2);
            }
        } else {
            for (0..3) |index| {
                const offset = (@as(f32, @floatFromInt(index)) - 1) * 5;
                fillEllipse(context, .{ .point = .{ .x = cx + offset, .y = cy }, .radius_x = 1.7, .radius_y = 1.7 }, ink);
            }
        }
        const label: []const u16 = if (system) &.{ 0x8bbe, 0x7f6e } else &.{ 0x6258, 0x76d8 };
        drawTaskTitle(self, context, label, false, ink, .{
            .left = bounds.left + 1,
            .top = bounds.top + 17,
            .right = bounds.right - 1,
            .bottom = bounds.bottom - 1,
        }, 13);
    }

    fn musicPngBitmap(self: *TextRenderer, context: *anyopaque, cache: *BitmapCache, png: []const u8, revision: u64, slot: WicImage.DecodeSlot) ?*anyopaque {
        if (png.len == 0) {
            releaseCom(&cache.bitmap);
            cache.context = context;
            cache.revision = 0;
            return null;
        }
        if (cache.context == context and cache.bitmap != null and cache.revision == revision) return cache.bitmap;
        if (cache.context != context) releaseCom(&cache.bitmap);
        var decoded = WicImage.DecodedImage{};
        if (!WicImage.decodeImage(png, &decoded, slot) or decoded.width <= 0 or decoded.height <= 0) {
            releaseCom(&cache.bitmap);
            cache.context = context;
            cache.revision = revision;
            self.last_png_bitmap_failure = "WIC decode failed";
            return null;
        }
        const properties = D2DBitmapProperties1{ .pixel_format = .{ .format = 87, .alpha_mode = 1 }, .dpi_x = 96, .dpi_y = 96, .options = 0, .color_context = null };
        const size = D2DSizeU{ .width = @intCast(decoded.width), .height = @intCast(decoded.height) };
        const stride: u32 = @intCast(@as(u64, @intCast(decoded.width)) * 4);
        var bitmap: Handle = null;
        const create = comMethod(*const fn (*anyopaque, D2DSizeU, ?[*]const u8, u32, *const D2DBitmapProperties1, *Handle) callconv(.winapi) HResult, context, 4);
        const create_hr = create(context, size, decoded.pixels, stride, &properties, &bitmap);
        if (create_hr < 0 or bitmap == null) {
            releaseCom(&cache.bitmap);
            cache.context = context;
            cache.revision = revision;
            self.last_png_bitmap_failure = "D2D CreateBitmap failed";
            self.last_png_bitmap_hresult = create_hr;
            return null;
        }
        releaseCom(&cache.bitmap);
        cache.bitmap = bitmap;
        cache.context = context;
        cache.revision = revision;
        cache.width = decoded.width;
        cache.height = decoded.height;
        return bitmap;
    }

    fn drawMusicBitmap(context: *anyopaque, bitmap: *anyopaque, rect: Geometry.RectF, opacity: f32, interpolation: i32) void {
        const draw = comMethod(*const fn (*anyopaque, *anyopaque, *const D2DRectF, f32, i32, ?*const D2DRectF, ?*const anyopaque) callconv(.winapi) void, context, 26);
        const target = toD2DRect(rect);
        draw(context, bitmap, &target, opacity, interpolation, null, null);
    }

    pub fn drawCallStrip(self: *TextRenderer, context_arg: Handle, box: Geometry.RoundedBox, call: CallStripText, opacity_arg: f32) void {
        const context = context_arg orelse return;
        const height = box.rect.bottom - box.rect.top;
        if (height <= 0) return;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01) return;
        const center_y = (box.rect.top + box.rect.bottom) * 0.5;
        const avatar_side = @max(1, height - 13);
        const avatar_left = box.rect.left + 16;
        const avatar_top = center_y - avatar_side * 0.5;
        if (self.rawPixelBitmap(context, &self.call_icon_cache, call.icon_pixels, call.icon_width, call.icon_height, call.icon_revision)) |bitmap| {
            drawMusicBitmap(context, bitmap, .{
                .left = avatar_left,
                .top = avatar_top,
                .right = avatar_left + avatar_side,
                .bottom = avatar_top + avatar_side,
            }, opacity, 1);
        } else {
            fillEllipse(context, .{
                .point = .{ .x = avatar_left + avatar_side * 0.5, .y = center_y },
                .radius_x = avatar_side * 0.5,
                .radius_y = avatar_side * 0.5,
            }, .{ .r = 0.35, .g = 0.35, .b = 0.38, .a = 0.95 * opacity });
        }

        var timer: [16]u16 = @splat(0);
        callTimerText(call.seconds, &timer);
        if (self.small_body_format) |format| {
            const set_paragraph = comMethod(*const fn (*anyopaque, i32) callconv(.winapi) HResult, format, 4);
            _ = set_paragraph(format, 1);
            defer _ = set_paragraph(format, 1);
            drawTextWithColor(context, format, &timer, .{
                .r = 0.188,
                .g = 0.820,
                .b = 0.345,
                .a = 0.98 * opacity,
            }, .{
                .left = avatar_left + avatar_side + 10,
                .top = box.rect.top,
                .right = avatar_left + avatar_side + 100,
                .bottom = box.rect.bottom,
            });
        }

        const bar_count: usize = 12;
        const bar_width: f32 = 3;
        const bar_gap: f32 = 2;
        const meter_width = @as(f32, @floatFromInt(bar_count)) * bar_width + @as(f32, @floatFromInt(bar_count - 1)) * bar_gap;
        const meter_left = box.rect.right - 16 - meter_width;
        const max_bar_height = @max(4, height - 14);
        const level = if (call.level_known) call.level else 0;
        for (0..bar_count) |index| {
            const fraction = callBarFraction(@intCast(index), @intCast(bar_count), level);
            const bar_height = 4 + fraction * (max_bar_height - 4);
            const left = meter_left + @as(f32, @floatFromInt(index)) * (bar_width + bar_gap);
            fillRounded(context, .{
                .rect = .{
                    .left = left,
                    .top = center_y - bar_height * 0.5,
                    .right = left + bar_width,
                    .bottom = center_y + bar_height * 0.5,
                },
                .radius_x = bar_width * 0.5,
                .radius_y = bar_width * 0.5,
            }, .{
                .r = 0.98,
                .g = 0.72,
                .b = 0.20,
                .a = (0.35 + 0.60 * fraction) * opacity,
            });
        }
    }

    fn rawPixelBitmap(_: *TextRenderer, context: *anyopaque, cache: *BitmapCache, pixels_arg: ?[]const u8, width: i32, height: i32, revision: u64) ?*anyopaque {
        const pixels = pixels_arg orelse {
            releaseCom(&cache.bitmap);
            cache.* = .{ .context = context };
            return null;
        };
        if (width <= 0 or height <= 0) return null;
        const pixel_count = @mulWithOverflow(@as(usize, @intCast(width)), @as(usize, @intCast(height)));
        if (pixel_count[1] != 0) return null;
        const byte_count = @mulWithOverflow(pixel_count[0], 4);
        if (byte_count[1] != 0 or pixels.len < byte_count[0]) return null;
        if (cache.context == context and cache.bitmap != null and cache.revision == revision and cache.width == width and cache.height == height) return cache.bitmap;
        if (cache.context != context) releaseCom(&cache.bitmap);

        const properties = D2DBitmapProperties1{ .pixel_format = .{ .format = 87, .alpha_mode = 1 }, .dpi_x = 96, .dpi_y = 96, .options = 0, .color_context = null };
        const size = D2DSizeU{ .width = @intCast(width), .height = @intCast(height) };
        const stride: u32 = @intCast(@as(u64, @intCast(width)) * 4);
        var bitmap: Handle = null;
        const create = comMethod(*const fn (*anyopaque, D2DSizeU, ?[*]const u8, u32, *const D2DBitmapProperties1, *Handle) callconv(.winapi) HResult, context, 4);
        if (create(context, size, pixels.ptr, stride, &properties, &bitmap) < 0 or bitmap == null) {
            releaseCom(&cache.bitmap);
            cache.context = context;
            cache.revision = revision;
            cache.width = width;
            cache.height = height;
            return null;
        }
        releaseCom(&cache.bitmap);
        cache.bitmap = bitmap;
        cache.context = context;
        cache.revision = revision;
        cache.width = width;
        cache.height = height;
        return bitmap;
    }

    /// Draws the pill's complete clock/weather status run. Text measurement and drawing use the same
    /// ordered pieces and spacing, matching the C++ renderer's centered layout.
    pub fn drawStatusLine(self: *TextRenderer, context: Handle, box: Geometry.RoundedBox, opacity_arg: f32, weather: StatusLineWeather.View) bool {
        if (context == null or self.factory == null or box.rect.right <= box.rect.left) return false;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        if (opacity <= 0.01) return true;
        self.refresh();
        if (self.status_clock_time_format == null or self.status_weather_format == null) return false;

        const run = buildStatusRun(self, zSlice(&self.time_text), &weather);
        const pieces = run.pieces;
        const count = run.count;
        if (count == 0) return true;
        const rect = box.rect;
        var x = rect.left + ((rect.right - rect.left) - run.width) * 0.5;
        if (x < rect.left + 8) x = rect.left + 8;
        // DirectWrite status formats and the weather mark share one vertical
        // center, leaving the row ready for additional items later.
        const mark_center_y = (rect.top + rect.bottom) * 0.5;
        const content_clip = D2DRectF{ .left = rect.left + 8, .top = rect.top, .right = rect.right - 8, .bottom = rect.bottom };
        if (content_clip.right <= content_clip.left) return true;
        const push_clip = comMethod(*const fn (*anyopaque, *const D2DRectF, i32) callconv(.winapi) void, context.?, 45);
        const pop_clip = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context.?, 46);
        push_clip(context.?, &content_clip, 0);
        defer pop_clip(context.?);
        for (pieces[0..count]) |piece| {
            if (piece.divider) {
                const color = D2DColor{ .r = 0.43, .g = 0.48, .b = 0.56, .a = 0.86 * opacity };
                drawLine(context.?, .{ .x = x + 0.5, .y = mark_center_y - 12 }, .{ .x = x + 0.5, .y = mark_center_y + 12 }, color, 1.2);
            } else if (piece.mark != .none) {
                drawStatusMark(context.?, .{ .left = x, .top = mark_center_y - piece.width * 0.5, .right = x + piece.width, .bottom = mark_center_y + piece.width * 0.5 }, piece.mark, opacity);
            } else if (piece.text.len != 0 and piece.format != null) {
                const color = D2DColor{ .r = piece.luminance, .g = piece.luminance, .b = piece.luminance, .a = opacity };
                var brush: Handle = null;
                const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context.?, 8);
                if (create_brush(context.?, &color, null, &brush) >= 0 and brush != null) {
                    defer releaseCom(&brush);
                    drawText(context.?, piece.format.?, piece.text, brush.?, .{ .left = x, .top = rect.top, .right = x + piece.width, .bottom = rect.bottom });
                }
            }
            x += piece.width + piece.after;
        }
        return true;
    }

    /// Draws the Windows mark on the Start control, sharing BarControlLayout's
    /// button rectangle with the hit test.
    pub fn drawStartButton(_: *TextRenderer, context_arg: Handle, island: Geometry.RoundedBox, wash_arg: f32, open: bool, opacity_arg: f32) void {
        const context = context_arg orelse return;
        const box = BarControlLayout.startButtonFor(island);
        if (box.right <= box.left or opacity_arg <= 0.01) return;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        const wash = if (open) @as(f32, 1) else std.math.clamp(wash_arg, 0, 1);
        const button = D2DRoundedRect{ .rect = toD2DRect(box), .radius_x = BarControlLayout.start_button_dip * 0.5, .radius_y = BarControlLayout.start_button_dip * 0.5 };
        fillRounded(context, button, .{ .r = 0.055, .g = 0.067, .b = 0.084, .a = opacity });
        if (wash > 0.01) fillRounded(context, button, .{ .r = 0.29, .g = 0.60, .b = 0.98, .a = 0.13 * opacity * wash });
        const side = BarControlLayout.start_icon_dip;
        const centre_x = (box.left + box.right) * 0.5;
        const centre_y = (box.top + box.bottom) * 0.5;
        const left = centre_x - side * 0.5;
        const top = centre_y - side * 0.5;
        const pane = (side - 2.5) * 0.5;
        const ink = D2DColor{ .r = 0.92, .g = 0.94, .b = 0.98, .a = 0.95 * opacity };
        for ([4]D2DRectF{
            .{ .left = left, .top = top, .right = left + pane, .bottom = top + pane },
            .{ .left = left + pane + 2.5, .top = top, .right = left + side, .bottom = top + pane },
            .{ .left = left, .top = top + pane + 2.5, .right = left + pane, .bottom = top + side },
            .{ .left = left + pane + 2.5, .top = top + pane + 2.5, .right = left + side, .bottom = top + side },
        }) |rect| {
            fillRounded(context, .{ .rect = rect, .radius_x = 1.5, .radius_y = 1.5 }, ink);
        }
    }

    /// Draws the standalone overflow chevron at the end of the compact dock.
    pub fn drawOverflowButton(_: *TextRenderer, context_arg: Handle, box: Geometry.RectF, wash_arg: f32, open: bool, opacity_arg: f32) void {
        const context = context_arg orelse return;
        if (box.right <= box.left or opacity_arg <= 0.01) return;
        const opacity = std.math.clamp(opacity_arg, 0, 1);
        const wash = if (open) @as(f32, 1) else std.math.clamp(wash_arg, 0, 1);
        const diameter = @min(box.right - box.left, box.bottom - box.top);
        const rounded = D2DRoundedRect{ .rect = toD2DRect(box), .radius_x = diameter * 0.5, .radius_y = diameter * 0.5 };
        fillRounded(context, rounded, .{ .r = 0.055, .g = 0.067, .b = 0.084, .a = opacity });
        if (wash > 0.01) fillRounded(context, rounded, .{ .r = 0.29, .g = 0.60, .b = 0.98, .a = 0.15 * opacity * wash });
        const ink = D2DColor{ .r = 0.96, .g = 0.97, .b = 0.99, .a = 0.96 * opacity };
        const cx = (box.left + box.right) * 0.5;
        const cy = (box.top + box.bottom) * 0.5;
        const half_width: f32 = 4;
        const half_height: f32 = 2.4;
        const tip_y = if (open) cy - half_height else cy + half_height;
        const wing_y = if (open) cy + half_height else cy - half_height;
        drawLine(context, .{ .x = cx - half_width, .y = wing_y }, .{ .x = cx, .y = tip_y }, ink, 1.6);
        drawLine(context, .{ .x = cx, .y = tip_y }, .{ .x = cx + half_width, .y = wing_y }, ink, 1.6);
    }

    /// Measures the exact run used by drawStatusLine, for parity checks and width constraints.
    pub fn measureStatusLine(self: *TextRenderer, time: []const u16, weather: StatusLineWeather.View) f32 {
        if (self.factory == null or self.status_clock_time_format == null or self.status_weather_format == null) return 0;
        return buildStatusRun(self, time, &weather).width;
    }

    pub fn metrics(self: *TextRenderer) TextMetrics {
        if (self.factory == null) return .{};
        const probe = [_]u16{ 0x4e00, 0x4e8c, 0x4e09, ' ', 'A', 'g' };
        return .{
            .title_line_height = if (self.music_title_format) |format| measureTextHeight(self.factory.?, format, &probe) else 0,
            .secondary_line_height = if (self.task_title_format) |format| measureTextHeight(self.factory.?, format, &probe) else 0,
            .pill_line_height = if (self.pill_line_format) |format| measureTextHeight(self.factory.?, format, &probe) else 0,
        };
    }

    fn refresh(self: *TextRenderer) void {
        var now: SystemTime = undefined;
        GetLocalTime(&now);
        if (self.last_hour != now.hour or self.last_minute != now.minute) {
            self.last_hour = now.hour;
            self.last_minute = now.minute;
            self.time_text = @splat(0);
            self.time_text[0] = '0' + now.hour / 10;
            self.time_text[1] = '0' + now.hour % 10;
            self.time_text[2] = ':';
            self.time_text[3] = '0' + now.minute / 10;
            self.time_text[4] = '0' + now.minute % 10;
        }
        if (self.last_year == now.year and self.last_month == now.month and self.last_day == now.day) return;
        self.last_year = now.year;
        self.last_month = now.month;
        self.last_day = now.day;
        self.date_text = @splat(0);
        const weekdays = [_][2]u16{
            .{ 0x5468, 0x65e5 }, .{ 0x5468, 0x4e00 }, .{ 0x5468, 0x4e8c },
            .{ 0x5468, 0x4e09 }, .{ 0x5468, 0x56db }, .{ 0x5468, 0x4e94 },
            .{ 0x5468, 0x516d },
        };
        const weekday = weekdays[if (now.day_of_week < 7) now.day_of_week else 0];
        var day_text: [24]u16 = @splat(0);
        var cursor: usize = 0;
        appendNumber24(&day_text, &cursor, now.month);
        day_text[cursor] = 0x6708;
        cursor += 1;
        appendNumber24(&day_text, &cursor, now.day);
        day_text[cursor] = 0x65e5;
        self.date_text = @splat(0);
        self.date_text[0] = weekday[0];
        self.date_text[1] = weekday[1];
        self.date_text[2] = 0x3001;
        cursor = 3;
        for (day_text) |unit| {
            if (unit == 0) break;
            self.date_text[cursor] = unit;
            cursor += 1;
        }
    }
};

fn drawTaskTitle(self: *TextRenderer, context: *anyopaque, text: []const u16, active: bool, color: D2DColor, box: Geometry.RectF, line_height: f32) void {
    const factory = self.factory orelse return;
    const format = (if (active) self.task_active_title_format else self.task_title_format) orelse return;
    const width = box.right - box.left;
    if (width <= 0) return;

    var visible: [512]u16 = undefined;
    var visible_length: usize = @min(text.len, visible.len - 1);
    if (visible_length < text.len and visible_length > 0 and isHighSurrogate(text[visible_length - 1])) {
        visible_length -= 1;
    }
    const source_was_truncated = visible_length < text.len;
    const needs_ellipsis = source_was_truncated or measureTextWidth(factory, format, text[0..visible_length]) > width;
    if (needs_ellipsis) {
        var low: usize = 0;
        var high: usize = visible_length;
        var best: usize = 0;
        var candidate: [512]u16 = undefined;
        while (low <= high) {
            const midpoint = low + (high - low) / 2;
            const boundary = safeUtf16PrefixLength(text, midpoint);
            @memcpy(candidate[0..boundary], text[0..boundary]);
            candidate[boundary] = 0x2026;
            const candidate_width = measureTextWidth(factory, format, candidate[0 .. boundary + 1]);
            if (candidate_width <= width) {
                best = @max(best, boundary);
                low = midpoint + 1;
            } else {
                if (boundary == 0) break;
                high = boundary - 1;
            }
        }
        @memcpy(visible[0..best], text[0..best]);
        visible[best] = 0x2026;
        visible_length = best + 1;
    } else {
        @memcpy(visible[0..visible_length], text[0..visible_length]);
    }

    const rect = D2DRectF{
        .left = box.left,
        .top = (box.top + box.bottom - line_height) * 0.5,
        .right = box.right,
        .bottom = (box.top + box.bottom + line_height) * 0.5,
    };
    drawTextWithColorClipped(context, format, visible[0..visible_length], color, rect);
}

fn isHighSurrogate(unit: u16) bool {
    return unit >= 0xD800 and unit <= 0xDBFF;
}

fn isLowSurrogate(unit: u16) bool {
    return unit >= 0xDC00 and unit <= 0xDFFF;
}

fn safeUtf16PrefixLength(text: []const u16, requested: usize) usize {
    const boundary = @min(requested, text.len);
    if (boundary > 0 and boundary < text.len and
        isHighSurrogate(text[boundary - 1]) and isLowSurrogate(text[boundary]))
    {
        return boundary - 1;
    }
    return boundary;
}

const StatusPiece = struct {
    text: []const u16 = &.{},
    format: Handle = null,
    mark: StatusLineWeather.Mark = .none,
    divider: bool = false,
    width: f32 = 0,
    after: f32 = 0,
    luminance: f32 = 0,
};

const StatusRun = struct {
    pieces: [max_status_pieces]StatusPiece = @splat(.{}),
    count: usize = 0,
    width: f32 = 0,
};

const max_status_pieces = 12;

fn buildStatusRun(self: *TextRenderer, time: []const u16, weather: *const StatusLineWeather.View) StatusRun {
    var run = StatusRun{};
    pushStatusText(&run.pieces, &run.count, self, time, self.status_clock_time_format, 14, 0.99);
    if (run.count < run.pieces.len) {
        run.pieces[run.count] = .{ .divider = true, .width = 1, .after = 14 };
        run.count += 1;
    }
    const mark = weather.mark;
    if (mark != .none and run.count < run.pieces.len) {
        run.pieces[run.count] = .{ .mark = mark, .width = 20, .after = 6 };
        run.count += 1;
    }
    // The run stores slices into weather. Keep the caller-owned view alive for
    // the duration of drawing instead of pointing into a by-value helper copy.
    pushStatusText(&run.pieces, &run.count, self, zSlice(&weather.sky), self.status_weather_format, 4, 0.92);
    pushStatusText(&run.pieces, &run.count, self, zSlice(&weather.temperature), self.status_weather_format, 0, 0.80);
    for (run.pieces[0..run.count]) |piece| run.width += piece.width + piece.after;
    return run;
}

fn pushStatusText(pieces: *[max_status_pieces]StatusPiece, count: *usize, self: *TextRenderer, text: []const u16, format: Handle, after: f32, luminance: f32) void {
    if (text.len == 0 or format == null or count.* >= pieces.len) return;
    const width = measureTextWidth(self.factory.?, format.?, text);
    if (width <= 0) return;
    pieces[count.*] = .{ .text = text, .format = format, .width = width, .after = after, .luminance = luminance };
    count.* += 1;
}

fn measureTextWidth(factory: *anyopaque, format: *anyopaque, text: []const u16) f32 {
    if (text.len == 0) return 0;
    const create_layout = comMethod(*const fn (*anyopaque, [*]const u16, u32, *anyopaque, f32, f32, *Handle) callconv(.winapi) HResult, factory, 18);
    var layout: Handle = null;
    if (create_layout(factory, text.ptr, @intCast(text.len), format, 8192, 512, &layout) < 0 or layout == null) return 0;
    defer releaseCom(&layout);
    const get_metrics = comMethod(*const fn (*anyopaque, *DWriteTextMetrics) callconv(.winapi) HResult, layout.?, 60);
    var metrics: DWriteTextMetrics = undefined;
    if (get_metrics(layout.?, &metrics) < 0) return 0;
    return metrics.width;
}

fn measureTextHeight(factory: *anyopaque, format: *anyopaque, text: []const u16) f32 {
    const create_layout = comMethod(*const fn (*anyopaque, [*]const u16, u32, *anyopaque, f32, f32, *Handle) callconv(.winapi) HResult, factory, 18);
    var layout: Handle = null;
    if (create_layout(factory, text.ptr, @intCast(text.len), format, 4096, 4096, &layout) < 0 or layout == null) return 0;
    defer releaseCom(&layout);
    const get_metrics = comMethod(*const fn (*anyopaque, *DWriteTextMetrics) callconv(.winapi) HResult, layout.?, 60);
    var measured: DWriteTextMetrics = undefined;
    if (get_metrics(layout.?, &measured) < 0) return 0;
    return measured.height;
}

fn drawScrollingLineRun(context: *anyopaque, format: *anyopaque, brush: *anyopaque, text: []const u16, text_width: f32, box_width: f32, box_left: f32, center_y: f32, scroll_dip: f32, line_height: f32, box: Geometry.RectF, end_fade: Handle) void {
    const inset = @min(@as(f32, 10), box_width * 0.12);
    const available = @max(0, box_width - inset * 2);
    const draw_at = struct {
        fn call(ctx: *anyopaque, fmt: *anyopaque, ink: *anyopaque, line: []const u16, width: f32, x: f32, y: f32, line_height_px: f32) void {
            const rect = D2DRectF{ .left = x, .top = y - line_height_px * 0.5, .right = x + @max(width + 4, 1), .bottom = y + line_height_px * 0.5 };
            drawText(ctx, fmt, line, ink, rect);
        }
    }.call;
    if (!lineNeedsScrollForWidth(text_width, available)) {
        draw_at(context, format, brush, text, text_width, box_left + (box_width - text_width) * 0.5, center_y, line_height);
        return;
    }
    if (end_fade) |fade_brush| {
        const parameters = D2DLayerParameters{
            .content_bounds = toD2DRect(box),
            .geometric_mask = null,
            .mask_antialias_mode = 0,
            .mask_transform = .{ .m11 = 1, .m12 = 0, .m21 = 0, .m22 = 1, .dx = 0, .dy = 0 },
            .opacity = 1,
            .opacity_brush = fade_brush,
            .layer_options = 0,
        };
        const push = comMethod(*const fn (*anyopaque, *const D2DLayerParameters, Handle) callconv(.winapi) void, context, 40);
        push(context, &parameters, null);
    }
    defer if (end_fade != null) {
        const pop = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 41);
        pop(context);
    };
    const stride = text_width + 40;
    if (stride <= 0) return;
    const offset = @rem(@max(scroll_dip, 0), stride);
    const start = box_left + inset;
    draw_at(context, format, brush, text, text_width, start - offset, center_y, line_height);
    draw_at(context, format, brush, text, text_width, start - offset + stride, center_y, line_height);
    if (offset > 0) draw_at(context, format, brush, text, text_width, start - offset - stride, center_y, line_height);
}

fn createScrollingLineFadeBrush(context: *anyopaque, box: Geometry.RectF, opacity_arg: f32) Handle {
    const width = box.right - box.left;
    if (width <= 1) return null;
    const fade_dip = scrollingLineFadeDip(width);
    const fade_fraction = fade_dip / width;
    if (fade_fraction <= 0.001) return null;
    const solid = std.math.clamp(opacity_arg, 0, 1);
    const stops = [_]D2DGradientStop{
        .{ .position = 0, .color = .{ .r = 0, .g = 0, .b = 0, .a = 0 } },
        .{ .position = fade_fraction, .color = .{ .r = solid, .g = solid, .b = solid, .a = solid } },
        .{ .position = 1 - fade_fraction, .color = .{ .r = solid, .g = solid, .b = solid, .a = solid } },
        .{ .position = 1, .color = .{ .r = 0, .g = 0, .b = 0, .a = 0 } },
    };
    var collection: Handle = null;
    const create_collection = comMethod(*const fn (*anyopaque, [*]const D2DGradientStop, u32, i32, i32, *Handle) callconv(.winapi) HResult, context, 9);
    if (create_collection(context, &stops, stops.len, 0, 0, &collection) < 0 or collection == null) return null;
    defer releaseCom(&collection);
    const properties = D2DLinearGradientBrushProperties{
        .start_point = .{ .x = box.left, .y = (box.top + box.bottom) * 0.5 },
        .end_point = .{ .x = box.right, .y = (box.top + box.bottom) * 0.5 },
    };
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DLinearGradientBrushProperties, ?*const anyopaque, *anyopaque, *Handle) callconv(.winapi) HResult, context, 10);
    if (create_brush(context, &properties, null, collection.?, &brush) < 0) return null;
    return brush;
}

fn zSlice(buffer: []const u16) []const u16 {
    const end = std.mem.indexOfScalar(u16, buffer, 0) orelse buffer.len;
    return buffer[0..end];
}

fn utf8ToWide(input: []const u8, output: []u16) usize {
    if (output.len < 2 or input.len == 0) return 0;
    var byte_count = @min(input.len, 4096);
    while (byte_count > 0) : (byte_count -= 1) {
        const converted = MultiByteToWideChar(65001, 8, input.ptr, @intCast(byte_count), output.ptr, @intCast(@min(output.len - 1, std.math.maxInt(i32))));
        if (converted > 0) {
            const count: usize = @intCast(converted);
            output[count] = 0;
            return count;
        }
    }
    output[0] = 0;
    return 0;
}

fn wideEqualIgnoreCase(left: []const u16, right: []const u16) bool {
    const a = std.mem.sliceTo(left, 0);
    const b = std.mem.sliceTo(right, 0);
    if (a.len != b.len) return false;
    for (a, b) |x, y| {
        const lower_x = if (x >= 'A' and x <= 'Z') x + ('a' - 'A') else x;
        const lower_y = if (y >= 'A' and y <= 'Z') y + ('a' - 'A') else y;
        if (lower_x != lower_y) return false;
    }
    return true;
}

fn appendNumber24(output: *[24]u16, cursor: *usize, value: u16) void {
    if (value >= 10) output[cursor.*] = '0' + value / 10;
    if (value >= 10) cursor.* += 1;
    output[cursor.*] = '0' + value % 10;
    cursor.* += 1;
}

fn drawStatusMark(context: *anyopaque, box: D2DRectF, mark: StatusLineWeather.Mark, opacity: f32) void {
    if (mark == .none or opacity <= 0) return;
    const cx = (box.left + box.right) * 0.5;
    const cy = (box.top + box.bottom) * 0.5;
    const blue = D2DColor{ .r = 0.46, .g = 0.71, .b = 1.0, .a = 0.96 * opacity };
    const sun_color = D2DColor{ .r = 0.99, .g = 0.78, .b = 0.35, .a = 0.98 * opacity };
    const light_color = D2DColor{ .r = 0.66, .g = 0.86, .b = 1.0, .a = opacity };
    switch (mark) {
        .none => {},
        .sun => drawSun(context, cx, cy, 0, 0, 4.6, sun_color),
        .sun_cloud => {
            drawSun(context, cx, cy, -3.4, -3.0, 3.6, sun_color);
            drawCloud(context, cx + 1.0, cy + 1.4, 0.92, blue);
        },
        .cloud => drawCloud(context, cx, cy + 0.4, 1, blue),
        .fog => {
            const bars = [_]D2DRoundedRect{
                .{ .rect = .{ .left = cx - 5, .top = cy - 3.4, .right = cx + 4, .bottom = cy - 1.6 }, .radius_x = 0.9, .radius_y = 0.9 },
                .{ .rect = .{ .left = cx - 6, .top = cy - 0.9, .right = cx + 6, .bottom = cy + 0.9 }, .radius_x = 0.9, .radius_y = 0.9 },
                .{ .rect = .{ .left = cx - 4, .top = cy + 1.6, .right = cx + 5, .bottom = cy + 3.4 }, .radius_x = 0.9, .radius_y = 0.9 },
            };
            for (bars) |bar| fillRounded(context, bar, .{ .r = light_color.r, .g = light_color.g, .b = light_color.b, .a = 0.90 * opacity });
        },
        .rain => {
            drawCloud(context, cx, cy - 1.4, 0.95, blue);
            for (0..3) |i| {
                const x = cx - 2.6 + @as(f32, @floatFromInt(i)) * 2.8;
                drawLine(context, .{ .x = x, .y = cy + 2 }, .{ .x = x - 1.4, .y = cy + 5.6 }, .{ .r = light_color.r, .g = light_color.g, .b = light_color.b, .a = 0.92 * opacity }, 1.5);
            }
        },
        .snow => {
            drawCloud(context, cx, cy - 1.4, 0.95, blue);
            const snow_color = D2DColor{ .r = light_color.r, .g = light_color.g, .b = light_color.b, .a = 0.95 * opacity };
            for (0..3) |i| {
                const x = cx - 2.6 + @as(f32, @floatFromInt(i)) * 2.8;
                fillEllipse(context, .{ .point = .{ .x = x - 0.7, .y = cy + 3.8 }, .radius_x = 1.1, .radius_y = 1.1 }, snow_color);
            }
        },
        .thunder => {
            drawCloud(context, cx, cy - 1.4, 0.95, blue);
            const bolt = D2DColor{ .r = light_color.r, .g = light_color.g, .b = light_color.b, .a = 0.98 * opacity };
            drawLine(context, .{ .x = cx - 0.4, .y = cy + 2.0 }, .{ .x = cx + 1.4, .y = cy + 3.4 }, bolt, 1.6);
            drawLine(context, .{ .x = cx + 1.4, .y = cy + 3.4 }, .{ .x = cx - 0.6, .y = cy + 3.8 }, bolt, 1.6);
            drawLine(context, .{ .x = cx - 0.6, .y = cy + 3.8 }, .{ .x = cx + 0.6, .y = cy + 6.0 }, bolt, 1.6);
        },
    }
}

fn drawSun(context: *anyopaque, cx: f32, cy: f32, offset_x: f32, offset_y: f32, radius: f32, color: D2DColor) void {
    const center = D2DPointF{ .x = cx + offset_x, .y = cy + offset_y };
    fillEllipse(context, .{ .point = center, .radius_x = radius, .radius_y = radius }, color);
    for (0..8) |i| {
        const angle = @as(f32, @floatFromInt(i)) * 3.14159265 / 4.0;
        const inner = radius + 1.1;
        const outer = radius + 2.6;
        drawLine(context, .{ .x = center.x + @cos(angle) * inner, .y = center.y + @sin(angle) * inner }, .{ .x = center.x + @cos(angle) * outer, .y = center.y + @sin(angle) * outer }, color, 1.2);
    }
}

fn drawCloud(context: *anyopaque, cx: f32, cy: f32, scale: f32, color: D2DColor) void {
    fillEllipse(context, .{ .point = .{ .x = cx - 3.2 * scale, .y = cy - 0.2 * scale }, .radius_x = 3.2 * scale, .radius_y = 3.0 * scale }, color);
    fillEllipse(context, .{ .point = .{ .x = cx + 0.6 * scale, .y = cy - 1.6 * scale }, .radius_x = 3.8 * scale, .radius_y = 3.6 * scale }, color);
    fillEllipse(context, .{ .point = .{ .x = cx + 4.0 * scale, .y = cy - 0.4 * scale }, .radius_x = 2.6 * scale, .radius_y = 2.4 * scale }, color);
    const rounded = D2DRoundedRect{ .rect = .{ .left = cx - 4.6 * scale, .top = cy - 0.6 * scale, .right = cx + 5.6 * scale, .bottom = cy + 2.2 * scale }, .radius_x = 1.4, .radius_y = 1.4 };
    fillRounded(context, rounded, color);
}

fn fillEllipse(context: *anyopaque, ellipse: D2DEllipse, color: D2DColor) void {
    withBrush(context, color, struct {
        fn call(ctx: *anyopaque, brush: *anyopaque, value: *const D2DEllipse) void {
            const f = comMethod(*const fn (*anyopaque, *const D2DEllipse, *anyopaque) callconv(.winapi) void, ctx, 21);
            f(ctx, value, brush);
        }
    }.call, &ellipse);
}

fn fillRounded(context: *anyopaque, rounded: D2DRoundedRect, color: D2DColor) void {
    withBrush(context, color, struct {
        fn call(ctx: *anyopaque, brush: *anyopaque, value: *const D2DRoundedRect) void {
            const f = comMethod(*const fn (*anyopaque, *const D2DRoundedRect, *anyopaque) callconv(.winapi) void, ctx, 19);
            f(ctx, value, brush);
        }
    }.call, &rounded);
}

fn drawWindowStackMark(context: *anyopaque, icon: Geometry.RectF, opacity: f32) void {
    const icon_side = @min(icon.right - icon.left, icon.bottom - icon.top);
    if (icon_side <= 0) return;
    const side = @min(8.5, @max(6.5, icon_side * 0.30));
    const offset = side * 0.27;
    const left = icon.right - side - 0.4;
    const top = icon.bottom - side - 0.4;
    const back = D2DRoundedRect{
        .rect = .{ .left = left - offset * 2, .top = top - offset * 2, .right = left + side - offset * 2, .bottom = top + side - offset * 2 },
        .radius_x = 1.5,
        .radius_y = 1.5,
    };
    const middle = D2DRoundedRect{
        .rect = .{ .left = left - offset, .top = top - offset, .right = left + side - offset, .bottom = top + side - offset },
        .radius_x = 1.5,
        .radius_y = 1.5,
    };
    const front = D2DRoundedRect{ .rect = .{ .left = left, .top = top, .right = left + side, .bottom = top + side }, .radius_x = 1.5, .radius_y = 1.5 };
    fillRounded(context, back, .{ .r = 0.92, .g = 0.95, .b = 1, .a = opacity });
    fillRounded(context, middle, .{ .r = 0.07, .g = 0.09, .b = 0.13, .a = opacity });
    fillRounded(context, front, .{ .r = 0.24, .g = 0.57, .b = 0.97, .a = opacity });
    fillRounded(context, .{
        .rect = .{ .left = left + side * 0.25, .top = top + side * 0.43, .right = left + side * 0.75, .bottom = top + side * 0.58 },
        .radius_x = 0.5,
        .radius_y = 0.5,
    }, .{ .r = 1, .g = 1, .b = 1, .a = 0.96 * opacity });
}

fn canvasFillRoundedRect(raw: ?*anyopaque, rounded: *const CanvasModule.RoundedRect, color: *const Theme.Color) callconv(.c) void {
    const context = raw orelse return;
    fillRounded(context, .{
        .rect = toD2DRect(rounded.rect),
        .radius_x = rounded.radius_x,
        .radius_y = rounded.radius_y,
    }, asD2D(color.*));
}

fn canvasFillEllipse(raw: ?*anyopaque, ellipse: *const CanvasModule.Ellipse, color: *const Theme.Color) callconv(.c) void {
    const context = raw orelse return;
    fillEllipse(context, .{
        .point = .{ .x = ellipse.center_x, .y = ellipse.center_y },
        .radius_x = ellipse.radius_x,
        .radius_y = ellipse.radius_y,
    }, asD2D(color.*));
}

fn pushRoundedMask(context: *anyopaque, box: Geometry.RoundedBox) Handle {
    var factory: Handle = null;
    const get_factory = comMethod(*const fn (*anyopaque, *Handle) callconv(.winapi) void, context, 3);
    get_factory(context, &factory);
    if (factory == null) return null;
    defer releaseCom(&factory);
    var geometry: Handle = null;
    const create = comMethod(*const fn (*anyopaque, *const D2DRoundedRect, *Handle) callconv(.winapi) HResult, factory.?, 6);
    const rounded = D2DRoundedRect{ .rect = toD2DRect(box.rect), .radius_x = box.radius_x, .radius_y = box.radius_y };
    if (create(factory.?, &rounded, &geometry) < 0 or geometry == null) return null;
    const parameters = D2DLayerParameters{
        .content_bounds = toD2DRect(box.rect),
        .geometric_mask = geometry,
        .mask_antialias_mode = 0,
        .mask_transform = .{ .m11 = 1, .m12 = 0, .m21 = 0, .m22 = 1, .dx = 0, .dy = 0 },
        .opacity = 1,
        .opacity_brush = null,
        .layer_options = 0,
    };
    const push = comMethod(*const fn (*anyopaque, *const D2DLayerParameters, Handle) callconv(.winapi) void, context, 40);
    push(context, &parameters, null);
    return geometry;
}

fn popRoundedMask(context: *anyopaque, geometry: *Handle) void {
    if (geometry.* == null) return;
    const pop = comMethod(*const fn (*anyopaque) callconv(.winapi) void, context, 41);
    pop(context);
    releaseCom(geometry);
}

fn asD2D(color: Theme.Color) D2DColor {
    return .{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
}

fn toD2DRect(rect: Geometry.RectF) D2DRectF {
    return .{ .left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom };
}

fn drawTextWithColor(context: *anyopaque, format: *anyopaque, text: []const u16, color: D2DColor, rect: D2DRectF) void {
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context, 8);
    if (create_brush(context, &color, null, &brush) < 0 or brush == null) return;
    defer releaseCom(&brush);
    drawText(context, format, text, brush.?, rect);
}

fn drawTextWithColorClipped(context: *anyopaque, format: *anyopaque, text: []const u16, color: D2DColor, rect: D2DRectF) void {
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context, 8);
    if (create_brush(context, &color, null, &brush) < 0 or brush == null) return;
    defer releaseCom(&brush);
    const draw = comMethod(*const fn (*anyopaque, [*]const u16, u32, *anyopaque, *const D2DRectF, *anyopaque, u32, i32) callconv(.winapi) void, context, 27);
    draw(context, text.ptr, @intCast(text.len), format, &rect, brush.?, 1, 2);
}

fn drawLine(context: *anyopaque, from: D2DPointF, to: D2DPointF, color: D2DColor, width: f32) void {
    const draw = comMethod(*const fn (*anyopaque, D2DPointF, D2DPointF, *anyopaque, f32, Handle) callconv(.winapi) void, context, 15);
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context, 8);
    if (create_brush(context, &color, null, &brush) < 0 or brush == null) return;
    defer releaseCom(&brush);
    draw(context, from, to, brush.?, width, null);
}

fn withBrush(context: *anyopaque, color: D2DColor, comptime callback: anytype, value: anytype) void {
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DColor, Handle, *Handle) callconv(.winapi) HResult, context, 8);
    if (create_brush(context, &color, null, &brush) < 0 or brush == null) return;
    defer releaseCom(&brush);
    callback(context, brush.?, value);
}

fn drawText(context: *anyopaque, format: *anyopaque, text: []const u16, brush: *anyopaque, rect: D2DRectF) void {
    var length: u32 = 0;
    while (length < text.len and text[length] != 0) : (length += 1) {}
    const draw = comMethod(*const fn (*anyopaque, [*]const u16, u32, *anyopaque, *const D2DRectF, *anyopaque, u32, i32) callconv(.winapi) void, context, 27);
    draw(context, text.ptr, length, format, &rect, brush, 0, 0);
}

fn releaseCom(object: *Handle) void {
    if (object.*) |raw| {
        const unknown: *Unknown = @ptrCast(@alignCast(raw));
        _ = unknown.vtable.release(raw);
        object.* = null;
    }
}

fn comMethod(comptime T: type, object: *anyopaque, index: usize) T {
    const header: *const extern struct { vtable: [*]const ?*anyopaque } = @ptrCast(@alignCast(object));
    return @ptrCast(header.vtable[index] orelse unreachable);
}

const MaterialAdapter = struct { owner: *TextRenderer, context: *anyopaque };

fn materialDrawOps(adapter: *MaterialAdapter) GlassMaterial.DrawOps {
    return .{
        .context = @ptrCast(adapter),
        .fill_rounded = materialFill,
        .vertical_gradient = materialGradient,
        .rim_gradient = materialRim,
        .grain = materialGrain,
    };
}

fn materialShape(box: Geometry.RoundedBox) GlassMaterial.RoundedRect {
    return .{
        .rect = .{ .left = box.rect.left, .top = box.rect.top, .right = box.rect.right, .bottom = box.rect.bottom },
        .radius_x = box.radius_x,
        .radius_y = box.radius_y,
    };
}

fn materialD2DShape(shape: GlassMaterial.RoundedRect) D2DRoundedRect {
    return .{
        .rect = .{ .left = shape.rect.left, .top = shape.rect.top, .right = shape.rect.right, .bottom = shape.rect.bottom },
        .radius_x = shape.radius_x,
        .radius_y = shape.radius_y,
    };
}

fn materialColor(color: Theme.Color) GlassMaterial.Color {
    return .{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
}

fn adapterFrom(raw: ?*anyopaque) ?*MaterialAdapter {
    const context = raw orelse return null;
    return @ptrCast(@alignCast(context));
}

fn materialFill(raw: ?*anyopaque, shape: GlassMaterial.RoundedRect, color: GlassMaterial.Color) callconv(.c) void {
    const adapter = adapterFrom(raw) orelse return;
    fillRounded(adapter.context, materialD2DShape(shape), .{ .r = color.r, .g = color.g, .b = color.b, .a = color.a });
}

fn createMaterialGradient(context: *anyopaque, shape: GlassMaterial.RoundedRect, from: GlassMaterial.Color, to: GlassMaterial.Color, start_y: f32, end_y: f32) Handle {
    const stops = [_]D2DGradientStop{
        .{ .position = 0, .color = .{ .r = from.r, .g = from.g, .b = from.b, .a = from.a } },
        .{ .position = 1, .color = .{ .r = to.r, .g = to.g, .b = to.b, .a = to.a } },
    };
    var collection: Handle = null;
    const create_collection = comMethod(*const fn (*anyopaque, [*]const D2DGradientStop, u32, i32, i32, *Handle) callconv(.winapi) HResult, context, 9);
    if (create_collection(context, &stops, 2, 0, 0, &collection) < 0 or collection == null) return null;
    defer releaseCom(&collection);
    const properties = D2DLinearGradientBrushProperties{
        .start_point = .{ .x = shape.rect.left, .y = start_y },
        .end_point = .{ .x = shape.rect.left, .y = end_y },
    };
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, *const D2DLinearGradientBrushProperties, ?*const anyopaque, *anyopaque, *Handle) callconv(.winapi) HResult, context, 10);
    if (create_brush(context, &properties, null, collection.?, &brush) < 0) return null;
    return brush;
}

fn fillWithBrush(context: *anyopaque, shape: GlassMaterial.RoundedRect, brush: *anyopaque) void {
    const rounded = materialD2DShape(shape);
    const fill = comMethod(*const fn (*anyopaque, *const D2DRoundedRect, *anyopaque) callconv(.winapi) void, context, 19);
    fill(context, &rounded, brush);
}

fn materialGradient(raw: ?*anyopaque, shape: GlassMaterial.RoundedRect, from: GlassMaterial.Color, to: GlassMaterial.Color, band: f32, from_top: bool) callconv(.c) void {
    const adapter = adapterFrom(raw) orelse return;
    const start_y = if (from_top) shape.rect.top else shape.rect.bottom - band;
    const end_y = if (from_top) shape.rect.top + band else shape.rect.bottom;
    var brush: Handle = createMaterialGradient(adapter.context, shape, from, to, start_y, end_y);
    if (brush == null) return;
    defer releaseCom(&brush);
    fillWithBrush(adapter.context, shape, brush.?);
}

fn materialRim(raw: ?*anyopaque, shape: GlassMaterial.RoundedRect, from: GlassMaterial.Color, to: GlassMaterial.Color, width: f32) callconv(.c) void {
    const adapter = adapterFrom(raw) orelse return;
    var brush: Handle = createMaterialGradient(adapter.context, shape, from, to, shape.rect.top, shape.rect.bottom);
    if (brush == null) return;
    defer releaseCom(&brush);
    const rounded = materialD2DShape(shape);
    const draw = comMethod(*const fn (*anyopaque, *const D2DRoundedRect, *anyopaque, f32, Handle) callconv(.winapi) void, adapter.context, 20);
    draw(adapter.context, &rounded, brush.?, width, null);
}

fn materialGrain(raw: ?*anyopaque, shape: GlassMaterial.RoundedRect, pixels: [*]const u8, size: usize, opacity: f32) callconv(.c) void {
    const adapter = adapterFrom(raw) orelse return;
    const context = adapter.context;
    if (adapter.owner.grain_context != context) {
        releaseCom(&adapter.owner.grain_bitmap);
        adapter.owner.grain_context = context;
    }
    if (adapter.owner.grain_bitmap == null) {
        const bitmap_size = D2DSizeU{ .width = @intCast(size), .height = @intCast(size) };
        const properties = D2DBitmapProperties1{
            .pixel_format = .{ .format = 87, .alpha_mode = 3 },
            .dpi_x = 96,
            .dpi_y = 96,
            .options = 0,
            .color_context = null,
        };
        const create_bitmap = comMethod(*const fn (*anyopaque, D2DSizeU, ?[*]const u8, u32, *const D2DBitmapProperties1, *Handle) callconv(.winapi) HResult, context, 4);
        if (create_bitmap(context, bitmap_size, pixels, @intCast(size * 4), &properties, &adapter.owner.grain_bitmap) < 0) return;
    }
    const bitmap_properties = D2DBitmapBrushProperties{ .extend_mode_x = 1, .extend_mode_y = 1, .interpolation_mode = 1 };
    var brush: Handle = null;
    const create_brush = comMethod(*const fn (*anyopaque, Handle, *const D2DBitmapBrushProperties, ?*const anyopaque, *Handle) callconv(.winapi) HResult, context, 7);
    if (create_brush(context, adapter.owner.grain_bitmap, &bitmap_properties, null, &brush) < 0 or brush == null) return;
    defer releaseCom(&brush);
    const set_opacity = comMethod(*const fn (*anyopaque, f32) callconv(.winapi) void, brush.?, 4);
    set_opacity(brush.?, opacity);
    fillWithBrush(context, shape, brush.?);
}

pub fn callTimerText(seconds_arg: i32, output: []u16) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const seconds: u32 = @intCast(@max(0, seconds_arg));
    const hours = seconds / 3600;
    const minutes = (seconds % 3600) / 60;
    const secs = seconds % 60;
    var ascii: [24]u8 = undefined;
    const text = if (hours > 0)
        (std.fmt.bufPrint(&ascii, "{d}:{d:0>2}:{d:0>2}", .{ hours, minutes, secs }) catch return)
    else
        (std.fmt.bufPrint(&ascii, "{d:0>2}:{d:0>2}", .{ minutes, secs }) catch return);
    const count = @min(text.len, output.len - 1);
    for (text[0..count], 0..) |unit, index| output[index] = unit;
}

const bar_pattern = [_]f32{ 0.30, 0.52, 0.78, 0.96, 0.72, 0.46, 0.60, 0.88, 1.00, 0.66, 0.40, 0.24 };

pub fn callBarFraction(index_arg: i32, count: i32, level_arg: f32) f32 {
    if (count <= 0) return 0;
    const index = std.math.clamp(index_arg, 0, count - 1);
    const level = std.math.clamp(level_arg, 0, 1);
    const shape = bar_pattern[@intCast(@mod(index, @as(i32, @intCast(bar_pattern.len))))];
    return @min(1, shape * (0.18 + 0.82 * level));
}

pub fn audioWaveEnvelope(step: i32, steps: i32, phase: f32) f32 {
    if (steps <= 0) return 0;
    const t = @as(f32, @floatFromInt(step)) / @as(f32, @floatFromInt(steps));
    const swell = 0.5 + 0.5 * @sin(t * 6.2831853 + phase);
    const ripple = 0.5 + 0.5 * @sin(t * 25.1327412 - phase * 1.7);
    return std.math.clamp(0.62 * swell + 0.38 * ripple, 0, 1);
}

fn imageFingerprint(bytes: []const u8) u64 {
    var hash: u64 = 14695981039346656037;
    for (bytes) |byte| {
        hash ^= byte;
        hash *%= 1099511628211;
    }
    return hash;
}

test "scrolling line threshold and fade preserve the existing strip geometry" {
    try std.testing.expect(!lineNeedsScrollForWidth(100, 124));
    try std.testing.expect(lineNeedsScrollForWidth(101, 124));
    try std.testing.expectEqual(@as(f32, 10), scrollingLineFadeDip(40));
    try std.testing.expectEqual(@as(f32, 20), scrollingLineFadeDip(120));
    try std.testing.expectEqual(@as(f32, 0), scrollingLineFadeDip(0));
}

test "feature image cache identity includes bytes as well as revision" {
    try std.testing.expectEqual(imageFingerprint("icon-a"), imageFingerprint("icon-a"));
    try std.testing.expect(imageFingerprint("icon-a") != imageFingerprint("icon-b"));
}

pub fn indicatorGlyph(icon: IndicatorIcon, value: i32) u16 {
    return switch (icon) {
        .input_method, .output_device => 0,
        .network => 0xE701,
        .bluetooth => 0xE702,
        .volume => if (value == 0) 0xE74F else 0xE767,
        .brightness => 0xE706,
        .battery => if (value <= 10) 0xE850 else if (value <= 30) 0xE851 else if (value <= 60) 0xE852 else if (value <= 90) 0xE853 else 0xE83F,
        .airplane => 0xE709,
        .settings => 0xE713,
        .accessibility => 0xE776,
        .battery_saver => 0xE8BE,
        .captions, .wired_display, .display_audio => 0xE7F4,
        .moon => 0xE708,
        .hotspot => 0xE704,
        .share => 0xE72D,
        .projection => 0xE7C4,
        .headphones => 0xE7F6,
    };
}

/// Retained for callers that format a millisecond position rather than elapsed seconds.
pub fn formatPosition(milliseconds: i64, output: []u8) usize {
    if (output.len == 0) return 0;
    const total_seconds: u64 = @intCast(@max(0, @divTrunc(milliseconds, 1000)));
    const hours = total_seconds / 3600;
    const minutes = (total_seconds % 3600) / 60;
    const seconds = total_seconds % 60;
    const rendered = if (hours > 0)
        std.fmt.bufPrint(output, "{d}:{d:0>2}:{d:0>2}", .{ hours, minutes, seconds }) catch return 0
    else
        std.fmt.bufPrint(output, "{d:0>2}:{d:0>2}", .{ minutes, seconds }) catch return 0;
    return rendered.len;
}

pub fn smokeCheck() bool {
    const utf16_probe = [_]u16{ 'A', 0xD83D, 0xDE80, 'B' };
    if (safeUtf16PrefixLength(&utf16_probe, 2) != 1 or
        safeUtf16PrefixLength(&utf16_probe, 3) != 3) return false;

    var timer: [16]u16 = @splat(0xFFFF);
    callTimerText(61, &timer);
    if (!std.mem.eql(u16, timer[0..5], &.{ '0', '1', ':', '0', '1' }) or timer[5] != 0) return false;
    callTimerText(3661, &timer);
    if (!std.mem.eql(u16, timer[0..7], &.{ '1', ':', '0', '1', ':', '0', '1' }) or timer[7] != 0) return false;
    callTimerText(-1, &timer);
    if (!std.mem.eql(u16, timer[0..5], &.{ '0', '0', ':', '0', '0' })) return false;
    return callBarFraction(99, 12, 1) <= 1 and callBarFraction(3, 12, 0) > 0 and
        @abs(audioWaveEnvelope(0, 16, 0.4) - audioWaveEnvelope(16, 16, 0.4)) < 0.0001 and
        indicatorGlyph(.volume, 0) == 0xE74F and indicatorGlyph(.battery, 10) == 0xE850 and
        indicatorGlyph(.battery, 100) == 0xE83F and indicatorGlyph(.output_device, 0) == 0;
}

comptime {
    _ = Geometry.RectF;
}
