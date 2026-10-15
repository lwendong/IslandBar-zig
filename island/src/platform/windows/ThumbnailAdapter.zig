const std = @import("std");
const ThumbnailContract = @import("ThumbnailContract");

pub const radius_dip: f32 = 18;

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

pub const Rect = ThumbnailContract.Rect;
pub const Size = ThumbnailContract.Size;
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

pub const ThumbnailPlacement = ThumbnailContract.Placement;

extern "kernel32" fn GetModuleHandleW(module_name: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
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
extern "dwmapi" fn DwmSetWindowAttribute(window: HWND, attribute: DWORD, value: *const anyopaque, size: DWORD) callconv(.winapi) i32;

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
const gclp_hicon: i32 = -14;
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
const dwmwa_window_corner_preference: DWORD = 33;
const dwmcp_round: i32 = 2;
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
const title_refresh_interval_ms: u64 = 120;

const thumbnail_class_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', 'T', 'h', 'u', 'm', 'b', 'n', 'a', 'i', 'l', 0 };
const window_name: [*:0]const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', ' ', 'p', 'r', 'e', 'v', 'i', 'e', 'w', 0 };
const face_name: [*:0]const u16 = &.{ 'S', 'e', 'g', 'o', 'e', ' ', 'U', 'I', ' ', 'V', 'a', 'r', 'i', 'a', 'b', 'l', 'e', ' ', 'T', 'e', 'x', 't', 0 };

fn sameRect(a: Rect, b: Rect) bool {
    return a.left == b.left and a.top == b.top and a.right == b.right and a.bottom == b.bottom;
}

fn sameSize(a: Size, b: Size) bool {
    return a.cx == b.cx and a.cy == b.cy;
}

fn rectRelativeTo(rect: Rect, origin: Rect) Rect {
    return .{
        .left = rect.left - origin.left,
        .top = rect.top - origin.top,
        .right = rect.right - origin.left,
        .bottom = rect.bottom - origin.top,
    };
}

fn rgb(red: u8, green: u8, blue: u8) DWORD {
    return @as(DWORD, red) | (@as(DWORD, green) << 8) | (@as(DWORD, blue) << 16);
}

pub const ThumbnailAdapter = struct {
    hwnd: HWND = null,
    source: HWND = null,
    thumbnail: HTHUMBNAIL = null,
    dwm_round_corners: bool = false,
    region_set: bool = false,
    thumbnail_dirty: bool = true,
    chrome_dirty: bool = true,
    source_size: Size = .{ .cx = 0, .cy = 0 },
    placed_source_size: Size = .{ .cx = 0, .cy = 0 },
    card: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    header: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    picture: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    title: [256]u16 = @splat(0),
    title_refreshed_ms: u64 = 0,
    title_refresh_initialized: bool = false,
    icon: HICON = null,
    visible: bool = false,
    last_result: i64 = 0,
    refusals: i32 = 0,

    pub fn create(self: *ThumbnailAdapter, owner: HWND) bool {
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
        self.dwm_round_corners = false;
        if (self.hwnd) |window| {
            const preference = dwmcp_round;
            self.dwm_round_corners = DwmSetWindowAttribute(window, dwmwa_window_corner_preference, @ptrCast(&preference), @sizeOf(i32)) >= 0;
        }
        return self.hwnd != null;
    }

    pub fn destroy(self: *ThumbnailAdapter) void {
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
        self.dwm_round_corners = false;
        self.region_set = false;
        self.thumbnail_dirty = true;
        self.chrome_dirty = true;
        self.source_size = .{ .cx = 0, .cy = 0 };
        self.placed_source_size = .{ .cx = 0, .cy = 0 };
        self.header = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    }

    pub fn ready(self: *const ThumbnailAdapter) bool {
        return self.hwnd != null;
    }

    fn refreshTitle(self: *ThumbnailAdapter, source: HWND) void {
        const now = GetTickCount64();
        if (self.title_refresh_initialized and now -| self.title_refreshed_ms < title_refresh_interval_ms) return;
        self.title_refresh_initialized = true;
        self.title_refreshed_ms = now;

        var updated: [256]u16 = @splat(0);
        _ = GetWindowTextW(source, &updated, @intCast(updated.len));
        if (!std.mem.eql(u16, &self.title, &updated)) {
            self.title = updated;
            self.chrome_dirty = true;
        }
    }

    pub fn begin(self: *ThumbnailAdapter, source: HWND) Size {
        const window = self.hwnd orelse return .{ .cx = 0, .cy = 0 };
        if (source == null or IsWindow(source) == 0) return .{ .cx = 0, .cy = 0 };
        if (self.source != source or self.thumbnail == null) {
            self.thumbnail_dirty = true;
            self.chrome_dirty = true;
            self.placed_source_size = .{ .cx = 0, .cy = 0 };
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
            self.title_refresh_initialized = false;
            var class_icon = GetClassLongPtrW(source, gclp_hiconsm);
            if (class_icon == 0) class_icon = GetClassLongPtrW(source, gclp_hicon);
            self.icon = if (class_icon == 0) null else @ptrFromInt(class_icon);
        }
        self.refreshTitle(source);
        self.source_size = .{ .cx = 0, .cy = 0 };
        if (self.thumbnail) |thumbnail| _ = DwmQueryThumbnailSourceSize(thumbnail, &self.source_size);
        return self.source_size;
    }

    pub fn place(self: *ThumbnailAdapter, placement: *const ThumbnailPlacement) bool {
        const window = self.hwnd orelse return false;
        const thumbnail = self.thumbnail orelse return false;
        if (!placement.valid) return false;
        const card_changed = !sameRect(self.card, placement.card);
        const was_visible = self.visible;
        const previous_card_size = Size{
            .cx = self.card.right - self.card.left,
            .cy = self.card.bottom - self.card.top,
        };
        const next_card_size = Size{
            .cx = placement.card.right - placement.card.left,
            .cy = placement.card.bottom - placement.card.top,
        };
        const card_size_changed = !sameSize(previous_card_size, next_card_size);
        const previous_header = rectRelativeTo(self.header, self.card);
        const next_header = rectRelativeTo(placement.header, placement.card);
        const header_changed = !sameRect(previous_header, next_header);
        const previous_destination = rectRelativeTo(self.picture, self.card);
        const next_destination = rectRelativeTo(placement.picture, placement.card);
        const destination_changed = !sameRect(previous_destination, next_destination);
        const source_size_changed = !sameSize(self.placed_source_size, self.source_size);
        const update_thumbnail = self.thumbnail_dirty or destination_changed or source_size_changed or !was_visible;
        const repaint_chrome = self.chrome_dirty or card_size_changed or header_changed or destination_changed;
        self.card = placement.card;
        self.header = placement.header;
        self.picture = placement.picture;
        const card_width = next_card_size.cx;
        const card_height = next_card_size.cy;
        if (!self.dwm_round_corners and (!self.region_set or card_size_changed)) {
            const header_height_px = placement.header.bottom - placement.header.top;
            const corner_diameter_px = @max(1, @as(i32, @intFromFloat(@round(@as(f32, @floatFromInt(header_height_px)) * (radius_dip * 2 / 38)))));
            if (CreateRoundRectRgn(0, 0, card_width + 1, card_height + 1, corner_diameter_px, corner_diameter_px)) |region| {
                self.region_set = SetWindowRgn(window, region, 1) != 0;
            }
        }
        if (card_changed or !was_visible) {
            const topmost: HWND = @ptrFromInt(std.math.maxInt(usize));
            _ = SetWindowPos(window, topmost, self.card.left, self.card.top, card_width, card_height, swp_noactivate | swp_showwindow);
        }
        self.visible = true;
        if (repaint_chrome) _ = InvalidateRect(window, null, 0);
        if (update_thumbnail) {
            var properties = ThumbnailProperties{
                .flags = dwm_tnp_rectdestination | dwm_tnp_rectsource | dwm_tnp_opacity | dwm_tnp_visible,
                .destination = next_destination,
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
            self.placed_source_size = self.source_size;
            self.thumbnail_dirty = false;
        }
        self.chrome_dirty = false;
        return true;
    }

    pub fn hide(self: *ThumbnailAdapter) void {
        const window = self.hwnd orelse return;
        if (!self.visible) return;
        _ = ShowWindow(window, sw_hide);
        self.visible = false;
    }

    fn paintCard(self: *ThumbnailAdapter, dc: HDC) void {
        if (dc == null) return;
        const window = self.hwnd orelse return;
        var client = Rect{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
        _ = GetClientRect(window, &client);
        const picture_top = self.picture.top - self.card.top;
        const picture_bottom = self.picture.bottom - self.card.top;
        const picture_left = self.picture.left - self.card.left;
        const picture_right = self.picture.right - self.card.left;
        const header = rectRelativeTo(self.header, self.card);
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
        const header_brush = CreateSolidBrush(rgb(24, 26, 32));
        if (header_brush) |brush| {
            if (header.bottom > header.top) _ = FillRect(dc, &header, brush);
            _ = DeleteObject(brush);
        }
        const header_height = header.bottom - header.top;
        const icon_size = @min(22, @max(16, @divTrunc(header_height, 2)));
        const header_padding = @max(10, @divTrunc(header_height, 3));
        var text_left = header.left + header_padding;
        if (self.icon) |icon| {
            const icon_top = header.top + @divTrunc(header_height - icon_size, 2);
            _ = DrawIconEx(dc, header.left + header_padding, icon_top, icon, icon_size, icon_size, 0, null, di_normal);
            text_left += icon_size + @max(8, @divTrunc(header_height, 4));
        }
        if (self.title[0] != 0 and text_left < header.right - header_padding) {
            _ = SetBkMode(dc, transparent);
            _ = SetTextColor(dc, rgb(238, 241, 248));
            const font_height: i32 = @max(14, @divTrunc(header_height * 14, 38));
            const font = CreateFontW(-font_height, 0, 0, 0, 500, 0, 0, 0, default_char_set, out_default_precision, clip_default_precision, cleartype_quality, default_pitch, face_name);
            const old_font = if (font != null) SelectObject(dc, font) else null;
            var text_rect = Rect{ .left = text_left, .top = header.top, .right = header.right - header_padding, .bottom = header.bottom };
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
                const self: *ThumbnailAdapter = @ptrFromInt(@as(usize, @bitCast(value)));
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

comptime {
    if (false) {
        var preview = ThumbnailAdapter{};
        _ = preview.create(null);
        _ = preview.begin(null);
        _ = preview.place(&ThumbnailPlacement{});
        preview.hide();
        preview.destroy();
    }
}
