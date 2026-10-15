const std = @import("std");
const Geometry = @import("Geometry");
const LayoutSnapshot = @import("LayoutSnapshot");
const LauncherCatalog = @import("LauncherCatalog");
const LauncherController = @import("LauncherController");
const TextRenderer = @import("TextRenderer");
const Theme = @import("Theme");

pub const columns: i32 = 6;
pub const rows: i32 = 3;
pub const cell_width: f32 = 76;
pub const cell_height: f32 = 50;
pub const cell_gap: f32 = 4;
pub const footer_height: f32 = 46;
pub const avatar_size: f32 = 28;
pub const power_size: f32 = 30;
pub const row_height: f32 = 34;
pub const power_row_width: f32 = 168;
pub const max_pins: usize = 18;

pub const Layout = struct {
    grid: Geometry.RectF = .{},
    footer: Geometry.RectF = .{},
    avatar: Geometry.RectF = .{},
    power_button: Geometry.RectF = .{},
    valid: bool = false,
};

pub const View = struct {
    layout: Layout = .{},
    snapshot: LayoutSnapshot.Snapshot = .{},
    page: LauncherController.Page = .pins,
    scroll_row: i32 = 0,
    pin_count: i32 = 0,
    app_count: i32 = 0,
};

pub const CardText = struct {
    view: View = .{},
    pins: []const LauncherCatalog.App = &.{},
    pin_icons: []const ?[]const u8 = &.{},
    pin_icon_sizes: []const usize = &.{},
    pin_icon_revision: u64 = 0,
    list: []const LauncherCatalog.App = &.{},
    hovered_pin: i32 = -1,
    hovered_picker_row: i32 = -1,
    hovered_power_row: i32 = -1,
    power_button_hovered: bool = false,
    pin_washes: []const f32 = &.{},
    row_washes: []const f32 = &.{},
    power_washes: []const f32 = &.{},
    power_confirm_row: i32 = -1,
    account_name: []const u16 = &.{},
};

pub const Action = union(enum) {
    open_apps,
    toggle_power,
    launch_pinned: struct { index: usize, frame_generation: u64 },
    pin_app: usize,
    power_row: i32,
};

pub const Hover = struct {
    pin: i32 = -1,
    picker_row: i32 = -1,
    power_row: i32 = -1,
    power_button: bool = false,
};

pub fn layoutFor(card: Geometry.RoundedBox) Layout {
    var layout = Layout{};
    const pad: f32 = 16;
    if (Geometry.width(card.rect) < pad * 2 + 1 or Geometry.height(card.rect) < footer_height + pad * 2 + 1) return layout;
    layout.footer = .{
        .left = card.rect.left + pad,
        .right = card.rect.right - pad,
        .bottom = card.rect.bottom - pad,
        .top = card.rect.bottom - pad - footer_height,
    };
    const inner_width = Geometry.width(card.rect) - pad * 2;
    const grid_width = intFloat(columns) * cell_width + intFloat(columns - 1) * cell_gap;
    layout.grid = .{
        .left = card.rect.left + pad + (inner_width - grid_width) * 0.5,
        .right = card.rect.left + pad + (inner_width - grid_width) * 0.5 + grid_width,
        .top = card.rect.top + pad,
        .bottom = layout.footer.top - 10,
    };
    const footer_center_y = (layout.footer.top + layout.footer.bottom) * 0.5;
    layout.avatar = .{
        .left = layout.footer.left,
        .right = layout.footer.left + avatar_size,
        .top = footer_center_y - avatar_size * 0.5,
        .bottom = footer_center_y + avatar_size * 0.5,
    };
    layout.power_button = .{
        .left = layout.footer.right - power_size,
        .right = layout.footer.right,
        .top = footer_center_y - power_size * 0.5,
        .bottom = footer_center_y + power_size * 0.5,
    };
    layout.valid = true;
    return layout;
}

pub fn pinCellFor(layout: Layout, index: i32) Geometry.RectF {
    if (!layout.valid or index < 0 or index >= columns * rows) return .{};
    const column = @rem(index, columns);
    const row = @divTrunc(index, columns);
    const left = layout.grid.left + intFloat(column) * (cell_width + cell_gap);
    const top = layout.grid.top + intFloat(row) * (cell_height + cell_gap);
    return .{ .left = left, .top = top, .right = left + cell_width, .bottom = top + cell_height };
}

pub fn pickerRowFor(layout: Layout, row_on_screen: i32) Geometry.RectF {
    if (!layout.valid or row_on_screen < 0) return .{};
    const top = layout.grid.top + intFloat(row_on_screen) * row_height;
    return .{ .left = layout.grid.left, .right = layout.grid.right, .top = top, .bottom = top + row_height };
}

pub fn powerRowFor(layout: Layout, index: i32) Geometry.RectF {
    if (!layout.valid or index < 0 or index >= 5) return .{};
    const bottom = layout.footer.top - 8 - intFloat(index) * row_height;
    return .{ .left = layout.power_button.right - power_row_width, .right = layout.power_button.right, .top = bottom - row_height, .bottom = bottom };
}

pub fn pinCellAt(layout: Layout, count: i32, x: f32, y: f32) i32 {
    if (!layout.valid or !contains(layout.grid, x, y)) return -1;
    const column = @as(i32, @intFromFloat((x - layout.grid.left) / (cell_width + cell_gap)));
    const row = @as(i32, @intFromFloat((y - layout.grid.top) / (cell_height + cell_gap)));
    if (column < 0 or column >= columns or row < 0 or row >= rows) return -1;
    const index = row * columns + column;
    if (index >= @min(count, columns * rows)) return -1;
    return if (contains(pinCellFor(layout, index), x, y)) index else -1;
}

pub fn pickerRowAt(layout: Layout, scroll_row: i32, count: i32, x: f32, y: f32) i32 {
    if (!layout.valid or !contains(layout.grid, x, y)) return -1;
    const visible_rows: i32 = @intFromFloat(@max(0, (layout.grid.bottom - layout.grid.top) / row_height));
    var visible: i32 = 0;
    while (visible <= visible_rows) : (visible += 1) {
        const index = scroll_row + visible;
        if (index < 0 or index >= count) break;
        const row = pickerRowFor(layout, visible);
        if (row.bottom > layout.grid.bottom) break;
        if (contains(row, x, y)) return index;
    }
    return -1;
}

pub fn powerRowAt(layout: Layout, x: f32, y: f32) i32 {
    for (0..5) |index| if (contains(powerRowFor(layout, @intCast(index)), x, y)) return @intCast(index);
    return -1;
}

pub fn buildView(card: Geometry.RoundedBox, page: LauncherController.Page, pin_count: i32, app_count: i32, scroll_row: i32, reveal_dip: f32, generation: u64) View {
    const layout = layoutFor(card);
    var view = View{ .layout = layout, .page = page, .scroll_row = scroll_row, .pin_count = pin_count, .app_count = app_count };
    if (!layout.valid) return view;
    var surface_clip = card.rect;
    surface_clip.bottom = @min(surface_clip.bottom, surface_clip.top + @max(0, reveal_dip));
    const snapshot = LayoutSnapshot.Snapshot{
        .generation = generation,
        .valid = surface_clip.bottom > surface_clip.top,
        .surface_clip = surface_clip,
        .content_clip = LayoutSnapshot.intersection(surface_clip, layout.grid),
    };
    view.snapshot = snapshot;
    if (!view.snapshot.valid) return view;
    _ = view.snapshot.append(.{ .id = .button, .index = -2, .bounds = layout.power_button, .hit_region = layout.power_button, .z_order = 4, .visible = true, .enabled = true, .content_clipped = false });
    switch (page) {
        .pins => {
            _ = view.snapshot.append(.{ .id = .button, .index = -1, .bounds = layout.grid, .hit_region = layout.grid, .z_order = 0, .visible = true, .enabled = true });
            const count = @min(@max(0, pin_count), @as(i32, columns * rows));
            for (0..@intCast(count)) |index| {
                const cell = pinCellFor(layout, @intCast(index));
                _ = view.snapshot.append(.{ .id = .button, .index = @intCast(index), .bounds = cell, .hit_region = cell, .z_order = 2, .visible = true, .enabled = true });
            }
        },
        .apps => {
            const visible_rows: i32 = @intFromFloat(@max(0, (layout.grid.bottom - layout.grid.top) / row_height));
            for (0..@intCast(visible_rows + 1)) |visible| {
                const index = scroll_row + @as(i32, @intCast(visible));
                if (index < 0 or index >= app_count) break;
                const row = pickerRowFor(layout, @intCast(visible));
                if (row.bottom > layout.grid.bottom) break;
                _ = view.snapshot.append(.{ .id = .row, .index = index, .bounds = row, .hit_region = row, .z_order = 2, .visible = true, .enabled = true });
            }
        },
        .power => {
            for (0..5) |index| {
                const row = powerRowFor(layout, @intCast(index));
                _ = view.snapshot.append(.{ .id = .row, .index = @intCast(index), .bounds = row, .hit_region = row, .z_order = 2, .visible = true, .enabled = true, .content_clipped = false });
            }
        },
    }
    return view;
}

pub fn actionAt(view: *const View, x: f32, y: f32) ?Action {
    const hit = view.snapshot.hitTestLocalDip(x, y) orelse return null;
    if (hit.id == .button) {
        if (hit.index == -2) return .toggle_power;
        if (hit.index >= 0) return .{ .launch_pinned = .{ .index = @intCast(hit.index), .frame_generation = view.snapshot.generation } };
        if (hit.index == -1 and !isCellGap(view.layout, x, y)) return .open_apps;
    } else if (hit.id == .row) {
        return switch (view.page) {
            .apps => .{ .pin_app = @intCast(hit.index) },
            .power => .{ .power_row = hit.index },
            .pins => null,
        };
    }
    return null;
}

pub fn hoverIndex(view: *const View, x: f32, y: f32) i32 {
    if (actionAt(view, x, y)) |action| return switch (action) {
        .launch_pinned => |request| @intCast(request.index),
        .pin_app => |index| @intCast(index),
        .power_row => |index| index,
        else => -1,
    };
    return -1;
}

pub fn hoverAt(view: *const View, x: f32, y: f32) Hover {
    var hover = Hover{};
    if (actionAt(view, x, y)) |action| switch (action) {
        .launch_pinned => |request| hover.pin = @intCast(request.index),
        .pin_app => |index| hover.picker_row = @intCast(index),
        .power_row => |index| hover.power_row = index,
        .toggle_power => hover.power_button = true,
        .open_apps => {},
    };
    return hover;
}

pub fn inPickerViewport(view: *const View, x: f32, y: f32) bool {
    return view.page == .apps and view.snapshot.valid and contains(view.layout.grid, x, y) and contains(view.snapshot.surface_clip, x, y);
}

fn isCellGap(layout: Layout, x: f32, y: f32) bool {
    if (!contains(layout.grid, x, y)) return false;
    const dx = x - layout.grid.left;
    const dy = y - layout.grid.top;
    const column = @as(i32, @intFromFloat(dx / (cell_width + cell_gap)));
    const row = @as(i32, @intFromFloat(dy / (cell_height + cell_gap)));
    const within_x = @mod(dx, cell_width + cell_gap);
    const within_y = @mod(dy, cell_height + cell_gap);
    return (column < columns - 1 and within_x >= cell_width) or (row < rows - 1 and within_y >= cell_height);
}

pub fn paint(context_arg: ?*anyopaque, backend: *TextRenderer.TextRenderer, draw_context: ?*anyopaque, box: *const Geometry.RoundedBox, reveal: f32, snapshot: ?*const LayoutSnapshot.Snapshot) callconv(.c) bool {
    const context = context_arg orelse return false;
    const data: *const CardText = @ptrCast(@alignCast(context));
    const d2d = draw_context orelse return false;
    const view = if (snapshot) |value| View{ .layout = data.view.layout, .snapshot = value.*, .page = data.view.page, .scroll_row = data.view.scroll_row, .pin_count = data.view.pin_count, .app_count = data.view.app_count } else data.view;
    return paintPage(backend, d2d, box.*, data, view, reveal);
}

fn paintPage(backend: *TextRenderer.TextRenderer, context: ?*anyopaque, box: Geometry.RoundedBox, text: *const CardText, view: View, opacity_arg: f32) bool {
    if (context == null or !view.layout.valid) return false;
    const opacity = std.math.clamp(opacity_arg, 0, 1);
    if (opacity <= 0.01) return true;
    const layout = view.layout;
    backend.drawCardSurface(context, box, opacity);
    const ink = Theme.themeInk(0.92 * opacity);
    const dim = Theme.themeInk(0.50 * opacity);
    const line = Theme.themeInk(0.07 * opacity);
    const warm = Theme.Color{ .r = 1, .g = 0.72, .b = 0.35, .a = 0.95 * opacity };

    if (view.page == .power) {
        const labels = [_][]const u16{ &.{ 0x9501, 0x5B9A }, &.{ 0x7761, 0x7720 }, &.{ 0x6CE8, 0x9500 }, &.{ 0x91CD, 0x542F }, &.{ 0x5173, 0x673A } };
        const armed = &[_]u16{ 0x518D, 0x70B9, 0x4E00, 0x6B21, 0x786E, 0x8BA4 };
        for (0..5) |index| {
            const row = powerRowFor(layout, @intCast(index));
            const amount = if (index < text.power_washes.len) text.power_washes[index] else if (text.hovered_power_row == @as(i32, @intCast(index))) @as(f32, 1) else 0;
            if (amount > 0.01) backend.fillRoundedRect(context, row, 8, 8, Theme.themeInk(0.12 * amount * opacity));
            const label = if (text.power_confirm_row == @as(i32, @intCast(index))) armed[0..] else labels[index];
            _ = backend.drawLabel(context, .page_body, label, .{ .left = row.left + 10, .top = row.top, .right = row.right - 10, .bottom = row.bottom }, if (text.power_confirm_row == @as(i32, @intCast(index))) warm else ink);
        }
    } else if (view.page == .apps) {
        const app_count: i32 = @intCast(@min(text.list.len, @as(usize, @intCast(@max(0, view.app_count)))));
        const visible_rows: i32 = @intFromFloat(@max(0, (layout.grid.bottom - layout.grid.top) / row_height));
        backend.pushClip(context, layout.grid);
        for (0..@intCast(visible_rows + 1)) |visible| {
            const index = view.scroll_row + @as(i32, @intCast(visible));
            if (index < 0 or index >= app_count) break;
            const row = pickerRowFor(layout, @intCast(visible));
            if (row.bottom > layout.grid.bottom) break;
            const hovered = text.hovered_picker_row == index;
            const amount = if (@as(usize, @intCast(index)) < text.row_washes.len) text.row_washes[@intCast(index)] else if (hovered) @as(f32, 1) else 0;
            if (amount > 0.01) backend.fillRoundedRect(context, row, 8, 8, Theme.themeInk(0.12 * amount * opacity));
            const app = text.list[@intCast(index)];
            _ = backend.drawLabel(context, .page_body, std.mem.sliceTo(&app.name, 0), .{ .left = row.left + 10, .top = row.top, .right = row.right - 84, .bottom = row.bottom }, ink);
            if (isPinned(text.pins, app)) _ = backend.drawLabel(context, .page_caption, &.{ 0x5DF2, 0x56FA, 0 }, .{ .left = row.right - 74, .top = row.top, .right = row.right - 10, .bottom = row.bottom }, dim);
        }
        backend.popClip(context);
        if (app_count > 0) {
            const grid_height = layout.grid.bottom - layout.grid.top;
            const visible_fraction = @as(f32, @floatFromInt(visible_rows + 1)) / @as(f32, @floatFromInt(app_count));
            const bar_height = @max(24, grid_height * visible_fraction);
            const max_row = @as(f32, @floatFromInt(@max(1, app_count - (visible_rows + 1))));
            const travelled = layout.grid.top + (grid_height - bar_height) * (@as(f32, @floatFromInt(@max(0, view.scroll_row))) / max_row);
            backend.fillRoundedRect(context, .{ .left = layout.grid.right + 6, .top = travelled, .right = layout.grid.right + 9, .bottom = travelled + bar_height }, 1.5, 1.5, line);
        }
    } else {
        const pin_count = @min(@min(text.pins.len, @as(usize, @intCast(@max(0, view.pin_count)))), max_pins);
        for (0..pin_count) |index| {
            const cell = pinCellFor(layout, @intCast(index));
            const amount = if (index < text.pin_washes.len) text.pin_washes[index] else if (text.hovered_pin == @as(i32, @intCast(index))) @as(f32, 1) else 0;
            if (amount > 0.01) backend.fillRoundedRect(context, cell, 10, 10, Theme.themeInk(0.12 * amount * opacity));
            const icon_box = Geometry.RectF{ .left = (cell.left + cell.right) * 0.5 - 14, .right = (cell.left + cell.right) * 0.5 + 14, .top = cell.top + 5, .bottom = cell.top + 33 };
            const png = if (index < text.pin_icons.len) text.pin_icons[index] else null;
            const icon_size = if (index < text.pin_icon_sizes.len) text.pin_icon_sizes[index] else 0;
            if (png) |bytes| {
                if (icon_size > 0 and icon_size <= bytes.len and backend.drawPngIcon(context, 16 + index, bytes[0..icon_size], text.pin_icon_revision, icon_box, opacity)) {} else {
                    backend.clearPngIcon(16 + index);
                    backend.fillRoundedRect(context, icon_box, 6, 6, line);
                }
            } else {
                backend.clearPngIcon(16 + index);
                backend.fillRoundedRect(context, icon_box, 6, 6, line);
            }
            _ = backend.drawLabel(context, .page_caption, std.mem.sliceTo(&text.pins[index].name, 0), .{ .left = cell.left + 2, .top = icon_box.bottom + 1, .right = cell.right - 2, .bottom = cell.bottom }, ink);
        }
        if (pin_count == 0) {
            const centre_x = (layout.grid.left + layout.grid.right) * 0.5;
            const centre_y = (layout.grid.top + layout.grid.bottom) * 0.5;
            _ = backend.drawLabel(context, .page_caption, &.{ '+', 0 }, .{ .left = centre_x - 16, .top = centre_y - 36, .right = centre_x + 16, .bottom = centre_y - 4 }, warm);
            _ = backend.drawLabel(context, .page_caption, &.{ 0x70B9, 0x8FD9, 0x91CC, 0x6DFB, 0x52A0, 0x5E94, 0x7528, 0 }, .{ .left = layout.grid.left, .top = centre_y, .right = layout.grid.right, .bottom = centre_y + 28 }, dim);
        }
    }

    backend.drawFeatureLine(context, .{ layout.footer.left, layout.footer.top }, .{ layout.footer.right, layout.footer.top }, line, 1);
    if (view.page == .apps) {
        var footer: [96]u16 = @splat(0);
        var ascii: [64]u8 = undefined;
        const rendered = std.fmt.bufPrint(&ascii, "All apps: {d} · wheel to scroll", .{view.app_count}) catch &.{};
        for (rendered, 0..) |byte, index| footer[index] = byte;
        _ = backend.drawLabel(context, .page_body, &footer, .{ .left = layout.footer.left, .top = layout.footer.top, .right = layout.power_button.left - 8, .bottom = layout.footer.bottom }, dim);
    } else if (text.account_name.len != 0) {
        _ = backend.drawLabel(context, .page_body, text.account_name, .{ .left = layout.avatar.right + 10, .top = layout.footer.top, .right = layout.power_button.left - 10, .bottom = layout.footer.bottom }, ink);
    }
    const power_amount = if (text.power_washes.len > 0) text.power_washes[0] else if (text.power_button_hovered or view.page == .power) @as(f32, 1) else 0;
    if (power_amount > 0.01) backend.fillRoundedRect(context, layout.power_button, 8, 8, Theme.themeInk(0.12 * power_amount * opacity));
    if (view.page == .apps) {
        _ = backend.drawLabel(context, .page_caption, &.{ 0x00D7, 0 }, layout.power_button, ink);
    } else {
        _ = backend.drawLabel(context, .icon, &.{ 0xE7E8, 0 }, layout.power_button, dim);
    }
    return true;
}

fn isPinned(pins: []const LauncherCatalog.App, app: LauncherCatalog.App) bool {
    for (pins) |pin| if (wideEqualIgnoreCase(std.mem.sliceTo(&pin.target, 0), std.mem.sliceTo(&app.target, 0))) return true;
    return false;
}

fn wideEqualIgnoreCase(left: []const u16, right: []const u16) bool {
    if (left.len != right.len) return false;
    for (left, right) |a, b| {
        const lower_a = if (a >= 'A' and a <= 'Z') a + ('a' - 'A') else a;
        const lower_b = if (b >= 'A' and b <= 'Z') b + ('a' - 'A') else b;
        if (lower_a != lower_b) return false;
    }
    return true;
}

fn contains(rect: Geometry.RectF, x: f32, y: f32) bool {
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

fn intFloat(value: i32) f32 {
    return @floatFromInt(value);
}

test "Launcher page hit targets exclude gutters and clipped content" {
    const card = Geometry.RoundedBox{ .rect = .{ .left = 20, .top = 10, .right = 520, .bottom = 330 }, .radius_x = 20, .radius_y = 20 };
    const layout = layoutFor(card);
    const first = pinCellFor(layout, 0);
    try std.testing.expectEqual(@as(i32, 0), pinCellAt(layout, 18, first.left + 4, first.top + 4));
    try std.testing.expectEqual(@as(i32, -1), pinCellAt(layout, 18, first.right + 1, first.top + 4));
    try std.testing.expectEqual(@as(i32, -1), pinCellAt(layout, 18, first.left + 4, first.bottom + 1));
    const gaps = buildView(card, .pins, 18, 0, 0, Geometry.height(card.rect), 3);
    try std.testing.expect(actionAt(&gaps, first.left + 4, first.top + 4).?.launch_pinned.index == 0);
    try std.testing.expect(actionAt(&gaps, first.right + 1, first.top + 4) == null);
    try std.testing.expect(actionAt(&gaps, first.left + 4, first.bottom + 1) == null);

    const hidden = buildView(card, .pins, 18, 0, 0, 0, 1);
    try std.testing.expect(actionAt(&hidden, first.left + 4, first.top + 4) == null);
    const revealed = buildView(card, .pins, 18, 0, 0, 38, 2);
    try std.testing.expect(actionAt(&revealed, first.left + 4, first.top + 4) != null);
    try std.testing.expectEqual(@as(i32, -1), pinCellAt(layout, 0, first.left + 4, first.top + 4));
}

test "Launcher page list rows and gutters map to the displayed absolute index" {
    const card = Geometry.RoundedBox{ .rect = .{ .left = 0, .top = 0, .right = 500, .bottom = 340 }, .radius_x = 20, .radius_y = 20 };
    const view = buildView(card, .apps, 0, 100, 7, 400, 9);
    const row = pickerRowFor(view.layout, 0);
    const action = actionAt(&view, row.left + 2, row.top + 2).?;
    try std.testing.expectEqual(@as(usize, 7), action.pin_app);
    try std.testing.expect(actionAt(&view, view.layout.grid.right + 1, row.top + 2) == null);
    try std.testing.expect(actionAt(&view, row.left + 2, view.layout.grid.bottom + 1) == null);
}
