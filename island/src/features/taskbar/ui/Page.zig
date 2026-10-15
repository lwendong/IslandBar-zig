const std = @import("std");
const Catalog = @import("TaskbarCatalog");
const Geometry = @import("Geometry");
const Layout = @import("TaskbarLayout");
const Presentation = @import("TaskbarPresentation");
const TextRenderer = @import("TextRenderer");

pub const View = Presentation.View;
pub const TrayIconInput = Presentation.TrayIconInput;
pub const TrayDockIcon = Presentation.TrayDockIcon;
pub const max_tray_icons = Presentation.max_tray_icons;

pub fn buildView(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
) View {
    return buildDockView(island, input, catalog_revision, input.len, Layout.monitorWidthFor(island), false);
}

pub fn buildDockView(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
) View {
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, false, &.{}, 0);
}

pub fn buildDockViewWithTray(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
    tray_icons: []const TrayIconInput,
    tray_catalog_revision: u64,
) View {
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, false, tray_icons, tray_catalog_revision);
}

pub fn buildDockViewWithHover(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
    hovered_id: ?Catalog.WindowId,
    hover_progress_arg: f32,
) View {
    const hover_override = if (hovered_id) |id|
        HoverOverride{ .window_id = id, .progress = hover_progress_arg }
    else
        null;
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, hover_override, false, &.{}, 0);
}

pub fn buildDockViewWithHoverProgress(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
) View {
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, true, &.{}, 0);
}

pub fn buildDockViewWithHoverProgressAndTray(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
    tray_icons: []const TrayIconInput,
    tray_catalog_revision: u64,
) View {
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, true, tray_icons, tray_catalog_revision);
}

const HoverOverride = struct {
    window_id: Catalog.WindowId,
    progress: f32,
};

fn buildDockViewInternal(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
    hover_override: ?HoverOverride,
    use_source_hover_progress: bool,
    tray_input: []const TrayIconInput,
    tray_catalog_revision: u64,
) View {
    const total = @min(input.len, Layout.max_task_icons);
    const visible = @min(visible_count, total);
    var hover_progresses: [Layout.max_task_icons]f32 = @splat(0);
    var requested_extra_total: f32 = 0;
    const base_row_width = @as(f32, @floatFromInt(visible)) * Layout.task_icon_button_dip +
        @as(f32, @floatFromInt(if (visible > 0) visible - 1 else 0)) * Layout.task_icon_gap_dip;
    for (input[0..visible], 0..) |source, index| {
        const raw_progress = if (hover_override) |override|
            (if (source.window_id == override.window_id) override.progress else 0)
        else if (use_source_hover_progress)
            source.hover_progress
        else
            0;
        const progress = std.math.clamp(raw_progress, 0, Layout.task_icon_hover_progress_max);
        hover_progresses[index] = progress;
        requested_extra_total += (Layout.task_icon_hover_width_dip - Layout.task_icon_button_dip) * progress;
    }
    var promoted_tray_count: usize = 0;
    for (tray_input) |icon| if (icon.promoted) {
        promoted_tray_count += 1;
    };
    const tray_count = Layout.trayIconsThatFitForMonitor(monitor_width_dip, visible, promoted_tray_count);
    const tray_width = @as(f32, @floatFromInt(tray_count)) * Layout.tray_icon_button_dip +
        @as(f32, @floatFromInt(if (tray_count > 0) tray_count - 1 else 0)) * Layout.tray_icon_gap_dip;
    const reserved_width = base_row_width + tray_width + (if (tray_count > 0 and visible > 0) Layout.task_tray_gap_dip else 0);
    const available_extra = @max(0, Layout.taskIconAvailableWidthForMonitor(monitor_width_dip) - reserved_width);
    const expansion_scale = if (requested_extra_total > available_extra and requested_extra_total > 0) available_extra / requested_extra_total else 1;
    var view = View{
        .catalog_revision = catalog_revision,
        .island = island,
        .count = visible,
        .hidden_task_count = total - visible,
        .tray_overflow_open = overflow_open,
        .tray_count = tray_count,
    };
    var next_left = island.rect.right + Layout.task_icon_pad_dip;
    for (input[0..visible], 0..) |source, index| {
        var button = source;
        const hover_progress = hover_progresses[index];
        const is_hovered = hover_progress > 0;
        const width = Layout.task_icon_button_dip +
            (Layout.task_icon_hover_width_dip - Layout.task_icon_button_dip) * hover_progress * expansion_scale;
        button.bounds = Layout.taskIconButtonAtWidth(island, next_left, width);
        button.icon_bounds = Layout.taskIconInBox(button.bounds);
        button.title_bounds = Layout.taskIconTitleInBox(button.bounds);
        button.hover_progress = if (is_hovered) hover_progress else 0;
        view.buttons[index] = button;
        view.task_row_bounds = unionBounds(view.task_row_bounds, button.bounds);
        view.row_bounds = unionBounds(view.row_bounds, button.bounds);
        next_left = button.bounds.right + Layout.task_icon_gap_dip;
    }
    var tray_left = if (view.task_row_bounds.right > view.task_row_bounds.left)
        view.task_row_bounds.right + Layout.task_tray_gap_dip
    else
        island.rect.right + Layout.task_icon_pad_dip;
    var inline_tray_count: usize = 0;
    for (tray_input) |source| {
        if (!source.promoted or inline_tray_count >= tray_count) continue;
        const bounds = Layout.trayIconButtonAt(island, tray_left);
        view.tray_icons[inline_tray_count] = .{
            .png = source.png,
            .source_index = source.source_index,
            .fingerprint = source.fingerprint,
            .revision = tray_catalog_revision,
            .bounds = bounds,
            .icon_bounds = Layout.trayIconInBox(bounds),
        };
        view.row_bounds = unionBounds(view.row_bounds, bounds);
        tray_left = bounds.right + Layout.tray_icon_gap_dip;
        inline_tray_count += 1;
    }
    const row_right = if (view.row_bounds.right > view.row_bounds.left) view.row_bounds.right else island.rect.right;
    view.overflow_button_bounds = Layout.overflowButtonFor(island, row_right);
    var hidden_tray_count: usize = 0;
    for (tray_input) |source| {
        if (source.promoted and inline_tray_count > 0) {
            inline_tray_count -= 1;
            continue;
        }
        if (hidden_tray_count >= view.tray_overflow_icons.len) break;
        view.tray_overflow_icons[hidden_tray_count] = .{
            .png = source.png,
            .source_index = source.source_index,
            .fingerprint = source.fingerprint,
            .revision = tray_catalog_revision,
        };
        hidden_tray_count += 1;
    }
    view.tray_overflow_count = hidden_tray_count;
    const overflow_layout = Layout.trayOverflowLayoutFor(island, view.overflow_button_bounds, monitor_width_dip, hidden_tray_count);
    view.tray_overflow_bounds = overflow_layout.panel;
    for (view.tray_overflow_icons[0..hidden_tray_count], 0..) |*icon, index| {
        icon.bounds = Layout.trayOverflowCellAt(overflow_layout, index);
        icon.icon_bounds = Layout.trayOverflowIconInBox(icon.bounds);
    }
    for (input[visible..total], 0..) |source, index| view.hidden_task_ids[index] = source.window_id;
    if (!overflow_open or hidden_tray_count == 0) view.tray_overflow_bounds.rect = .{};
    return view;
}

/// Applies a presentation-time horizontal offset to a task and keeps the row
/// bounds in sync so drawing, pointer hit testing, and the native input region
/// follow the same animated position.
pub fn applyHorizontalOffset(view: *View, window_id: Catalog.WindowId, offset_x: f32) bool {
    for (view.buttons[0..@min(view.count, view.buttons.len)]) |*button| {
        if (button.window_id != window_id) continue;
        translateButtonBounds(button, offset_x);
        view.task_row_bounds = unionBounds(view.task_row_bounds, button.bounds);
        view.row_bounds = unionBounds(view.row_bounds, button.bounds);
        return true;
    }
    return false;
}

fn translateButtonBounds(button: *TextRenderer.TaskButton, offset_x: f32) void {
    button.bounds.left += offset_x;
    button.bounds.right += offset_x;
    button.icon_bounds.left += offset_x;
    button.icon_bounds.right += offset_x;
    button.title_bounds.left += offset_x;
    button.title_bounds.right += offset_x;
}

/// Moves the tray group and its trailing overflow control together while a
/// task removal animation frees horizontal space.
pub fn applyTrayDockOffset(view: *View, offset_x: f32) void {
    if (@abs(offset_x) < 0.001) return;
    for (view.tray_icons[0..@min(view.tray_count, view.tray_icons.len)]) |*icon| {
        translateRectX(&icon.bounds, offset_x);
        translateRectX(&icon.icon_bounds, offset_x);
    }
    translateRectX(&view.overflow_button_bounds, offset_x);
    translateRectX(&view.tray_overflow_bounds.rect, offset_x);
    for (view.tray_overflow_icons[0..@min(view.tray_overflow_count, view.tray_overflow_icons.len)]) |*icon| {
        translateRectX(&icon.bounds, offset_x);
        translateRectX(&icon.icon_bounds, offset_x);
    }

    view.row_bounds = view.task_row_bounds;
    for (view.tray_icons[0..@min(view.tray_count, view.tray_icons.len)]) |icon| {
        view.row_bounds = unionBounds(view.row_bounds, icon.bounds);
    }
}

fn translateRectX(rect: *Geometry.RectF, offset_x: f32) void {
    rect.left += offset_x;
    rect.right += offset_x;
}

pub fn actionAt(view: *const View, x: f32, y: f32) ?Catalog.WindowId {
    for (view.buttons[0..view.count]) |button| {
        if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
    }
    return null;
}

pub fn trayIconAt(view: *const View, x: f32, y: f32) ?Presentation.TrayDockIcon {
    for (view.tray_icons[0..view.tray_count]) |icon| {
        if (contains(icon.bounds, x, y)) return icon;
    }
    return null;
}

pub fn trayOverflowIconAt(view: *const View, x: f32, y: f32) ?Presentation.TrayDockIcon {
    if (!view.tray_overflow_open) return null;
    for (view.tray_overflow_icons[0..@min(view.tray_overflow_count, view.tray_overflow_icons.len)]) |icon| {
        if (contains(icon.bounds, x, y)) return icon;
    }
    return null;
}

pub fn overflowContains(view: *const View, x: f32, y: f32) bool {
    return view.tray_overflow_open and contains(view.tray_overflow_bounds.rect, x, y);
}

pub fn overflowButtonHit(view: *const View, x: f32, y: f32) bool {
    return contains(view.overflow_button_bounds, x, y);
}

/// Keeps the current expansion while the pointer travels through the task row
/// gap, using the same row geometry that was published for drawing and input.
pub fn hoverTarget(view: *const View, current: ?Catalog.WindowId, x: f32, y: f32) ?Catalog.WindowId {
    for (view.buttons[0..view.count]) |button| {
        if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
    }
    if (current) |id| {
        for (view.buttons[0..view.count]) |button| {
            if (button.window_id == id and contains(view.task_row_bounds, x, y)) return current;
        }
    }
    return null;
}

fn unionBounds(a: Geometry.RectF, b: Geometry.RectF) Geometry.RectF {
    if (b.right <= b.left or b.bottom <= b.top) return a;
    if (a.right <= a.left or a.bottom <= a.top) return b;
    return .{ .left = @min(a.left, b.left), .top = @min(a.top, b.top), .right = @max(a.right, b.right), .bottom = @max(a.bottom, b.bottom) };
}

fn contains(rect: Geometry.RectF, x: f32, y: f32) bool {
    return rect.right > rect.left and rect.bottom > rect.top and x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom;
}

test "taskbar page paints and hits the same fixed circular button bounds" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 500, .top = 0, .right = 720, .bottom = 36 }, .radius_x = 18, .radius_y = 18 };
    const title_a = [_:0]u16{'A'};
    const title_b = [_:0]u16{'B'};
    const input = [_]TextRenderer.TaskButton{
        .{ .window_id = 41, .title = &title_a },
        .{ .window_id = 42, .title = &title_b },
    };
    const view = buildView(island, &input, 7);
    const first = view.buttons[0].bounds;
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), actionAt(&view, first.left + 2, first.top + 2));
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), hoverTarget(&view, null, first.left + 2, first.top + 2));
    try std.testing.expect(actionAt(&view, first.right + 2, first.top + 2) == null);
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), hoverTarget(&view, 41, first.right + 1, first.top + 2));
    try std.testing.expect(hoverTarget(&view, 99, first.right + 1, first.top + 2) == null);
    try std.testing.expectEqual(@as(u64, 7), view.catalog_revision);
    try std.testing.expect(view.row_bounds.right >= view.buttons[1].bounds.right);
}

test "hover expansion shares animated bounds with task hits and moves following buttons" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 810, .top = 8, .right = 1110, .bottom = 56 }, .radius_x = 24, .radius_y = 24 };
    const title_a = [_:0]u16{'A'};
    const title_b = [_:0]u16{'B'};
    const title_c = [_:0]u16{'C'};
    const input = [_]TextRenderer.TaskButton{
        .{ .window_id = 41, .title = &title_a },
        .{ .window_id = 42, .title = &title_b },
        .{ .window_id = 43, .title = &title_c },
    };
    const compact = buildView(island, &input, 9);
    const expanded = buildDockViewWithHover(island, &input, 9, 3, 1920, false, 42, 1);
    const hovered = expanded.buttons[1];
    try std.testing.expectApproxEqAbs(Layout.task_icon_hover_width_dip, hovered.bounds.right - hovered.bounds.left, 0.001);
    try std.testing.expectApproxEqAbs(compact.buttons[1].icon_bounds.left, hovered.icon_bounds.left, 0.001);
    try std.testing.expect(hovered.title_bounds.right > hovered.title_bounds.left);
    try std.testing.expectApproxEqAbs(hovered.bounds.right + Layout.task_icon_gap_dip, expanded.buttons[2].bounds.left, 0.001);
    try std.testing.expectApproxEqAbs(expanded.row_bounds.right + Layout.dock_gap_dip, expanded.overflow_button_bounds.left, 0.001);
    const label_x = (hovered.title_bounds.left + hovered.title_bounds.right) * 0.5;
    const label_y = (hovered.title_bounds.top + hovered.title_bounds.bottom) * 0.5;
    try std.testing.expectEqual(@as(?Catalog.WindowId, 42), actionAt(&expanded, label_x, label_y));
    try std.testing.expectEqual(@as(?Catalog.WindowId, 42), hoverTarget(&expanded, null, label_x, label_y));

    const capped = buildDockViewWithHover(island, &input, 9, 3, 1920, false, 42, 1.16);
    try std.testing.expectApproxEqAbs(Layout.task_icon_hover_width_dip, capped.buttons[1].bounds.right - capped.buttons[1].bounds.left, 0.01);
}

test "tray overflow contains hidden tray icons without task or navigation entries" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 500, .top = 8, .right = 800, .bottom = 56 }, .radius_x = 24, .radius_y = 24 };
    const title_a = [_:0]u16{'A'};
    const title_b = [_:0]u16{'B'};
    const title_c = [_:0]u16{'C'};
    const input = [_]TextRenderer.TaskButton{
        .{ .window_id = 41, .title = &title_a },
        .{ .window_id = 42, .title = &title_b },
        .{ .window_id = 43, .title = &title_c },
    };
    const tray_input = [_]TrayIconInput{
        .{ .source_index = 7, .fingerprint = 70, .promoted = true },
        .{ .source_index = 8, .fingerprint = 80, .promoted = false },
    };
    const view = buildDockViewWithTray(island, &input, 9, 2, 1600, true, &tray_input, 4);
    try std.testing.expectEqual(@as(usize, 2), view.count);
    try std.testing.expectEqual(@as(usize, 1), view.hidden_task_count);
    try std.testing.expectEqual(@as(usize, 1), view.tray_count);
    try std.testing.expectEqual(@as(usize, 1), view.tray_overflow_count);
    const hidden_tray_icon = view.tray_overflow_icons[0];
    const icon_center_x = (hidden_tray_icon.bounds.left + hidden_tray_icon.bounds.right) * 0.5;
    const icon_center_y = (hidden_tray_icon.bounds.top + hidden_tray_icon.bounds.bottom) * 0.5;
    try std.testing.expectEqual(@as(?u16, 8), (trayOverflowIconAt(&view, icon_center_x, icon_center_y) orelse return error.HiddenTrayIconNotHit).source_index);
    try std.testing.expect(actionAt(&view, icon_center_x, icon_center_y) == null);
    try std.testing.expect(overflowContains(&view, view.tray_overflow_bounds.rect.left + 2, view.tray_overflow_bounds.rect.top + 2));
}

test "dock row and overflow control stay compact on wide monitors" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 1770, .top = 8, .right = 2070, .bottom = 56 }, .radius_x = 24, .radius_y = 24 };
    const title = [_:0]u16{'A'};
    var input: [Layout.max_task_icons]TextRenderer.TaskButton = @splat(.{});
    for (&input, 0..) |*button, index| {
        button.window_id = index + 1;
        button.title = &title;
    }

    const view = buildDockView(island, &input, 9, Layout.max_visible_task_icons, 3840, false);
    try std.testing.expectEqual(Layout.max_visible_task_icons, view.count);
    try std.testing.expectEqual(Layout.max_task_icons - Layout.max_visible_task_icons, view.hidden_task_count);
    try std.testing.expectApproxEqAbs(Layout.dock_gap_dip + view.row_bounds.right, view.overflow_button_bounds.left, 0.001);
    try std.testing.expect(view.overflow_button_bounds.right < 3000);

    const empty = buildDockView(island, &.{}, 10, 0, 3840, false);
    try std.testing.expectApproxEqAbs(island.rect.right + Layout.task_icon_pad_dip, empty.overflow_button_bounds.left, 0.001);
}
