const std = @import("std");

pub const max_width_dip: f32 = 260;
pub const max_height_dip: f32 = 160;
pub const gap_dip: f32 = 10;
pub const pad_dip: f32 = 8;
pub const title_dip: f32 = 22;
pub const radius_dip: f32 = 12;

const HANDLE = ?*anyopaque;
const HWND = HANDLE;
const HDC = HANDLE;
const HICON = HANDLE;
const HBRUSH = HANDLE;
const HGDIOBJ = HANDLE;
const HRGN = HANDLE;
const HINSTANCE = HANDLE;
const HTHUMBNAIL = HANDLE;
const BOOL = i32;
const UINT = u32;
const DWORD = u32;
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;
const WindowProc = *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT;

pub const Rect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
pub const Size = extern struct { cx: i32, cy: i32 };
const PaintStruct = extern struct {
    hdc: HDC,
    erase: BOOL,
    paint: Rect,
    restore: BOOL,
    update: BOOL,
    reserved: [32]u8,
};
const CreateStructW = extern struct {
    create_params: ?*anyopaque,
    instance: HINSTANCE,
    menu: HANDLE,
    parent: HWND,
    cy: i32,
    cx: i32,
    y: i32,
    x: i32,
    style: i32,
    name: ?[*:0]const u16,
    class_name: ?[*:0]const u16,
    extended_style: DWORD,
};
const WindowClassExW = extern struct {
    size: UINT,
    style: UINT,
    window_proc: WindowProc,
    class_extra: i32,
    window_extra: i32,
    instance: HINSTANCE,
    icon: HICON,
    cursor: HANDLE,
    background: HBRUSH,
    menu_name: ?[*:0]const u16,
    class_name: [*:0]const u16,
    small_icon: HICON,
};
const ThumbnailProperties = extern struct {
    flags: DWORD,
    destination: Rect,
    source: Rect,
    opacity: u8,
    visible: BOOL,
    source_client_area_only: BOOL,
};

pub const ThumbnailPlacement = struct {
    card: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    picture: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    valid: bool = false,
};

extern "kernel32" fn GetModuleHandleW(module_name: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "user32" fn RegisterClassExW(window_class: *const WindowClassExW) callconv(.winapi) u16;
extern "user32" fn CreateWindowExW(ex_style: DWORD, class_name: [*:0]const u16, window_name: [*:0]const u16, style: DWORD, x: i32, y: i32, width: i32, height: i32, parent: HWND, menu: HANDLE, instance: HINSTANCE, parameter: ?*anyopaque) callconv(.winapi) HWND;
extern "user32" fn DestroyWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn IsWindow(window: HWND) callconv(.winapi) BOOL;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPos(window: HWND, after: HWND, x: i32, y: i32, width: i32, height: i32, flags: UINT) callconv(.winapi) BOOL;
extern "user32" fn SetWindowRgn(window: HWND, region: HRGN, redraw: BOOL) callconv(.winapi) i32;
extern "user32" fn InvalidateRect(window: HWND, rect: ?*const Rect, erase: BOOL) callconv(.winapi) BOOL;
extern "user32" fn GetWindowTextW(window: HWND, text: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn SendMessageTimeoutW(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM, flags: UINT, timeout: UINT, result: *usize) callconv(.winapi) LRESULT;
extern "user32" fn GetClassLongPtrW(window: HWND, index: i32) callconv(.winapi) usize;
extern "user32" fn GetClientRect(window: HWND, rect: *Rect) callconv(.winapi) BOOL;
extern "user32" fn DrawIconEx(dc: HDC, x: i32, y: i32, icon: HICON, width: i32, height: i32, step: UINT, brush: HBRUSH, flags: UINT) callconv(.winapi) BOOL;
extern "user32" fn DrawTextW(dc: HDC, text: [*:0]const u16, count: i32, rect: *Rect, format: UINT) callconv(.winapi) i32;
extern "user32" fn SetWindowLongPtrW(window: HWND, index: i32, value: isize) callconv(.winapi) isize;
extern "user32" fn GetWindowLongPtrW(window: HWND, index: i32) callconv(.winapi) isize;
extern "user32" fn LoadCursorW(instance: HINSTANCE, cursor_name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "user32" fn BeginPaint(window: HWND, paint: *PaintStruct) callconv(.winapi) HDC;
extern "user32" fn EndPaint(window: HWND, paint: *const PaintStruct) callconv(.winapi) BOOL;
extern "user32" fn DefWindowProcW(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT;
extern "gdi32" fn CreateRoundRectRgn(left: i32, top: i32, right: i32, bottom: i32, ellipse_width: i32, ellipse_height: i32) callconv(.winapi) HRGN;
extern "gdi32" fn CreateSolidBrush(color: DWORD) callconv(.winapi) HBRUSH;
extern "gdi32" fn DeleteObject(object: HGDIOBJ) callconv(.winapi) BOOL;
extern "gdi32" fn FillRect(dc: HDC, rect: *const Rect, brush: HBRUSH) callconv(.winapi) i32;
extern "gdi32" fn SetBkMode(dc: HDC, mode: i32) callconv(.winapi) i32;
extern "gdi32" fn SetTextColor(dc: HDC, color: DWORD) callconv(.winapi) DWORD;
extern "gdi32" fn CreateFontW(height: i32, width: i32, escapement: i32, orientation: i32, weight: i32, italic: DWORD, underline: DWORD, strikeout: DWORD, char_set: DWORD, output_precision: DWORD, clip_precision: DWORD, quality: DWORD, pitch_and_family: DWORD, face: [*:0]const u16) callconv(.winapi) HANDLE;
extern "gdi32" fn SelectObject(dc: HDC, object: HGDIOBJ) callconv(.winapi) HGDIOBJ;
extern "dwmapi" fn DwmRegisterThumbnail(destination: HWND, source: HWND, thumbnail: *HTHUMBNAIL) callconv(.winapi) i32;
extern "dwmapi" fn DwmUnregisterThumbnail(thumbnail: HTHUMBNAIL) callconv(.winapi) i32;
extern "dwmapi" fn DwmQueryThumbnailSourceSize(thumbnail: HTHUMBNAIL, size: *Size) callconv(.winapi) i32;
extern "dwmapi" fn DwmUpdateThumbnailProperties(thumbnail: HTHUMBNAIL, properties: *const ThumbnailProperties) callconv(.winapi) i32;

const ws_ex_topmost: DWORD = 0x00000008;
const ws_ex_toolwindow: DWORD = 0x00000080;
const ws_ex_noactivate: DWORD = 0x08000000;
const ws_popup: DWORD = 0x80000000;
const cs_v_redraw: UINT = 0x0001;
const cs_h_redraw: UINT = 0x0002;
const error_class_already_exists: DWORD = 1410;
const wm_nccreate: UINT = 0x0081;
const wm_erasebkgnd: UINT = 0x0014;
const wm_paint: UINT = 0x000f;
const wm_nchittest: UINT = 0x0084;
const wm_geticon: UINT = 0x007f;
const icon_big: WPARAM = 1;
const icon_small2: WPARAM = 2;
const smto_abortifhung: UINT = 0x0002;
const gclp_hiconsm: i32 = -34;
const gwlp_userdata: i32 = -21;
const httransparent: LRESULT = -1;
const sw_hide: i32 = 0;
const swp_noactivate: UINT = 0x0010;
const swp_showwindow: UINT = 0x0040;
const dwm_tnp_rectdestination: DWORD = 0x00000001;
const dwm_tnp_rectsource: DWORD = 0x00000002;
const dwm_tnp_opacity: DWORD = 0x00000004;
const dwm_tnp_visible: DWORD = 0x00000008;
const dt_left: UINT = 0;
const dt_vcenter: UINT = 0x00000004;
const dt_singleline: UINT = 0x00000020;
const dt_end_ellipsis: UINT = 0x00008000;
const transparent: i32 = 1;
const fw_normal: i32 = 400;
const default_char_set: DWORD = 1;
const out_default_precision: DWORD = 0;
const clip_default_precision: DWORD = 0;
const cleartype_quality: DWORD = 5;
const default_pitch: DWORD = 0;
const di_normal: UINT = 0x0003;

const thumbnail_class_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', 'T', 'h', 'u', 'm', 'b', 'n', 'a', 'i', 'l', 0 };
const window_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', ' ', 'p', 'r', 'e', 'v', 'i', 'e', 'w', 0 };
const face_name: [*:0]const u16 = &.{ 'S', 'e', 'g', 'o', 'e', ' ', 'U', 'I', ' ', 'V', 'a', 'r', 'i', 'a', 'b', 'l', 'e', ' ', 'T', 'e', 'x', 't', 0 };

fn rgb(red: u8, green: u8, blue: u8) DWORD {
    return @as(DWORD, red) | (@as(DWORD, green) << 8) | (@as(DWORD, blue) << 16);
}

fn roundPixel(value: f32) i32 {
    return @intFromFloat(@round(value));
}

/// Computes a fixed-size card and an aspect-preserving thumbnail placement in screen pixels.
pub fn thumbnailBoxFor(source_width_px: i32, source_height_px: i32, icon_box_px: Rect, monitor_px: Rect, scale_arg: f32) ThumbnailPlacement {
    var placement = ThumbnailPlacement{};
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

pub const ThumbnailPreview = struct {
    hwnd: HWND = null,
    source: HWND = null,
    thumbnail: HTHUMBNAIL = null,
    source_size: Size = .{ .cx = 0, .cy = 0 },
    card: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    picture: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    title: [256]u16 = @splat(0),
    icon: HICON = null,
    visible: bool = false,
    last_result: i64 = 0,
    refusals: i32 = 0,

    pub fn create(self: *ThumbnailPreview, owner: HWND) bool {
        if (self.hwnd != null) return true;
        const instance = GetModuleHandleW(null);
        var window_class = WindowClassExW{
            .size = @sizeOf(WindowClassExW),
            .style = cs_h_redraw | cs_v_redraw,
            .window_proc = &windowProc,
            .class_extra = 0,
            .window_extra = 0,
            .instance = instance,
            .icon = null,
            .cursor = LoadCursorW(null, @ptrFromInt(32512)),
            .background = null,
            .menu_name = null,
            .class_name = thumbnail_class_name,
            .small_icon = null,
        };
        if (RegisterClassExW(&window_class) == 0 and GetLastError() != error_class_already_exists) return false;
        const style = ws_ex_topmost | ws_ex_noactivate | ws_ex_toolwindow;
        self.hwnd = CreateWindowExW(style, thumbnail_class_name, window_name, ws_popup, 0, 0, 1, 1, owner, null, instance, self);
        return self.hwnd != null;
    }

    pub fn destroy(self: *ThumbnailPreview) void {
        if (self.thumbnail) |thumbnail| {
            _ = DwmUnregisterThumbnail(thumbnail);
            self.thumbnail = null;
        }
        if (self.hwnd) |window| {
            _ = DestroyWindow(window);
            self.hwnd = null;
        }
        self.source = null;
        self.visible = false;
    }

    pub fn ready(self: *const ThumbnailPreview) bool {
        return self.hwnd != null;
    }

    pub fn begin(self: *ThumbnailPreview, source: HWND) Size {
        const window = self.hwnd orelse return .{ .cx = 0, .cy = 0 };
        if (source == null or IsWindow(source) == 0) return .{ .cx = 0, .cy = 0 };
        if (self.source != source or self.thumbnail == null) {
            if (self.thumbnail) |thumbnail| {
                _ = DwmUnregisterThumbnail(thumbnail);
                self.thumbnail = null;
            }
            const result = DwmRegisterThumbnail(window, source, &self.thumbnail);
            self.last_result = result;
            if (result < 0 or self.thumbnail == null) {
                self.thumbnail = null;
                self.source = null;
                self.source_size = .{ .cx = 0, .cy = 0 };
                self.refusals += 1;
                return self.source_size;
            }
            self.source = source;
            self.title = @splat(0);
            _ = GetWindowTextW(source, &self.title, @intCast(self.title.len));
            var result_icon: usize = 0;
            if (SendMessageTimeoutW(source, wm_geticon, icon_small2, 0, smto_abortifhung, 100, &result_icon) == 0) result_icon = 0;
            self.icon = if (result_icon == 0) null else @ptrFromInt(result_icon);
            if (self.icon == null and SendMessageTimeoutW(source, wm_geticon, icon_big, 0, smto_abortifhung, 100, &result_icon) != 0 and result_icon != 0) self.icon = @ptrFromInt(result_icon);
            if (self.icon == null) {
                const class_icon = GetClassLongPtrW(source, gclp_hiconsm);
                if (class_icon != 0) self.icon = @ptrFromInt(class_icon);
            }
        }
        self.source_size = .{ .cx = 0, .cy = 0 };
        if (self.thumbnail) |thumbnail| _ = DwmQueryThumbnailSourceSize(thumbnail, &self.source_size);
        return self.source_size;
    }

    pub fn place(self: *ThumbnailPreview, placement: *const ThumbnailPlacement) bool {
        const window = self.hwnd orelse return false;
        const thumbnail = self.thumbnail orelse return false;
        if (!placement.valid) return false;
        self.card = placement.card;
        self.picture = placement.picture;
        const card_width = self.card.right - self.card.left;
        const card_height = self.card.bottom - self.card.top;
        if (CreateRoundRectRgn(0, 0, card_width + 1, card_height + 1, @intFromFloat(radius_dip * 2), @intFromFloat(radius_dip * 2))) |region| {
            _ = SetWindowRgn(window, region, 1);
        }
        const topmost: HWND = @ptrFromInt(std.math.maxInt(usize));
        _ = SetWindowPos(window, topmost, self.card.left, self.card.top, card_width, card_height, swp_noactivate | swp_showwindow);
        self.visible = true;
        _ = InvalidateRect(window, null, 1);
        var properties = ThumbnailProperties{
            .flags = dwm_tnp_rectdestination | dwm_tnp_rectsource | dwm_tnp_opacity | dwm_tnp_visible,
            .destination = .{ .left = self.picture.left - self.card.left, .top = self.picture.top - self.card.top, .right = self.picture.right - self.card.left, .bottom = self.picture.bottom - self.card.top },
            .source = .{ .left = 0, .top = 0, .right = self.source_size.cx, .bottom = self.source_size.cy },
            .opacity = 255,
            .visible = 1,
            .source_client_area_only = 0,
        };
        const result = DwmUpdateThumbnailProperties(thumbnail, &properties);
        self.last_result = result;
        if (result < 0) {
            self.refusals += 1;
            _ = ShowWindow(window, sw_hide);
            self.visible = false;
            return false;
        }
        return true;
    }

    pub fn hide(self: *ThumbnailPreview) void {
        const window = self.hwnd orelse return;
        if (!self.visible) return;
        _ = ShowWindow(window, sw_hide);
        self.visible = false;
    }

    fn paintCard(self: *ThumbnailPreview, dc: HDC) void {
        if (dc == null) return;
        const window = self.hwnd orelse return;
        var client = Rect{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
        _ = GetClientRect(window, &client);
        const picture_top = self.picture.top - self.card.top;
        const picture_bottom = self.picture.bottom - self.card.top;
        const picture_left = self.picture.left - self.card.left;
        const picture_right = self.picture.right - self.card.left;
        const card_brush = CreateSolidBrush(rgb(18, 18, 22));
        if (card_brush) |brush| {
            const bands = [_]Rect{
                .{ .left = client.left, .top = client.top, .right = client.right, .bottom = picture_top },
                .{ .left = client.left, .top = picture_bottom, .right = client.right, .bottom = client.bottom },
                .{ .left = client.left, .top = picture_top, .right = picture_left, .bottom = picture_bottom },
                .{ .left = picture_right, .top = picture_top, .right = client.right, .bottom = picture_bottom },
            };
            for (&bands) |*band| {
                if (band.right > band.left and band.bottom > band.top) _ = FillRect(dc, band, brush);
            }
            _ = DeleteObject(brush);
        }
        const line_brush = CreateSolidBrush(rgb(56, 56, 66));
        if (line_brush) |brush| {
            var divider = Rect{ .left = client.left, .top = picture_top - 1, .right = client.right, .bottom = picture_top };
            if (divider.bottom > divider.top) _ = FillRect(dc, &divider, brush);
            _ = DeleteObject(brush);
        }
        const icon_size = 16;
        var text_left: i32 = 10;
        if (self.icon) |icon| {
            _ = DrawIconEx(dc, 10, @divTrunc(picture_top - icon_size, 2), icon, icon_size, icon_size, 0, null, di_normal);
            text_left = 34;
        }
        if (self.title[0] != 0 and text_left < client.right - 16) {
            _ = SetBkMode(dc, transparent);
            _ = SetTextColor(dc, rgb(214, 219, 228));
            const font = CreateFontW(-13, 0, 0, 0, fw_normal, 0, 0, 0, default_char_set, out_default_precision, clip_default_precision, cleartype_quality, default_pitch, face_name);
            const old_font = if (font != null) SelectObject(dc, font) else null;
            var text_rect = Rect{ .left = text_left, .top = 0, .right = client.right - 12, .bottom = picture_top };
            _ = DrawTextW(dc, @ptrCast(&self.title), -1, &text_rect, dt_left | dt_vcenter | dt_singleline | dt_end_ellipsis);
            if (font) |object| {
                if (old_font) |old| _ = SelectObject(dc, old);
                _ = DeleteObject(object);
            }
        }
    }
};

fn windowProc(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    switch (message) {
        wm_nccreate => {
            const create: *const CreateStructW = @ptrFromInt(@as(usize, @bitCast(lparam)));
            const self_ptr = create.create_params orelse return 0;
            _ = SetWindowLongPtrW(window, gwlp_userdata, @bitCast(@intFromPtr(self_ptr)));
        },
        wm_erasebkgnd => return 1,
        wm_paint => {
            var paint = std.mem.zeroes(PaintStruct);
            const dc = BeginPaint(window, &paint);
            const value = GetWindowLongPtrW(window, gwlp_userdata);
            if (value != 0) {
                const self: *ThumbnailPreview = @ptrFromInt(@as(usize, @bitCast(value)));
                self.paintCard(dc);
            }
            _ = EndPaint(window, &paint);
            return 0;
        },
        wm_nchittest => return httransparent,
        else => {},
    }
    return DefWindowProcW(window, message, wparam, lparam);
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
    const invalid_scale = thumbnailBoxFor(640, 480, icon, monitor, 0);
    return invalid_scale.valid;
}

comptime {
    if (false) {
        var preview = ThumbnailPreview{};
        _ = preview.create(null);
        _ = preview.begin(null);
        _ = preview.place(&ThumbnailPlacement{});
        preview.hide();
        preview.destroy();
    }
}
