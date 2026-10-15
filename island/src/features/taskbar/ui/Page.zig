const std = @import("std");
const Catalog = @import("TaskbarCatalog");
const Geometry = @import("Geometry");
const Layout = @import("TaskbarLayout");
const Presentation = @import("TaskbarPresentation");
const TextRenderer = @import("TextRenderer");

pub const View = Presentation.View;

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
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, false);
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
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, hover_override, false);
}

pub fn buildDockViewWithHoverProgress(
    island: Geometry.RoundedBox,
    input: []const TextRenderer.TaskButton,
    catalog_revision: u64,
    visible_count: usize,
    monitor_width_dip: f32,
    overflow_open: bool,
) View {
    return buildDockViewInternal(island, input, catalog_revision, visible_count, monitor_width_dip, overflow_open, null, true);
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
    const available_extra = @max(0, Layout.taskIconAvailableWidthForMonitor(monitor_width_dip) - base_row_width);
    const expansion_scale = if (requested_extra_total > available_extra and requested_extra_total > 0)
        available_extra / requested_extra_total
    else
        1;
    var view = View{
        .catalog_revision = catalog_revision,
        .island = island,
        .count = visible,
        .overflow_count = total - visible,
        .overflow_open = overflow_open,
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
        view.row_bounds = unionBounds(view.row_bounds, button.bounds);
        next_left = button.bounds.right + Layout.task_icon_gap_dip;
    }
    const row_right = if (view.row_bounds.right > view.row_bounds.left) view.row_bounds.right else island.rect.right;
    view.overflow_button_bounds = Layout.overflowButtonFor(island, row_right);
    const overflow_layout = Layout.overflowLayoutFor(island, view.overflow_button_bounds, monitor_width_dip, total - visible);
    view.overflow_bounds = overflow_layout.panel;
    view.system_entry_bounds = overflow_layout.system_entry;
    view.tray_entry_bounds = overflow_layout.tray_entry;
    for (input[visible..total], 0..) |source, index| {
        var button = source;
        button.hover_progress = 0;
        button.bounds = Layout.overflowTaskButtonAt(overflow_layout, index);
        button.icon_bounds = Layout.overflowTaskIconInBox(button.bounds);
        button.title_bounds = Layout.overflowTaskTitleAt(button.bounds);
        view.overflow_buttons[index] = button;
    }
    if (!overflow_open) view.overflow_bounds.rect = .{};
    return view;
}

pub fn actionAt(view: *const View, x: f32, y: f32) ?Catalog.WindowId {
    for (view.buttons[0..view.count]) |button| {
        if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
    }
    if (view.overflow_open) {
        for (view.overflow_buttons[0..view.overflow_count]) |button| {
            if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
        }
    }
    return null;
}

pub fn overflowContains(view: *const View, x: f32, y: f32) bool {
    return view.overflow_open and contains(view.overflow_bounds.rect, x, y);
}

pub fn systemEntryHit(view: *const View, x: f32, y: f32) bool {
    return view.overflow_open and contains(view.system_entry_bounds, x, y);
}

pub fn trayEntryHit(view: *const View, x: f32, y: f32) bool {
    return view.overflow_open and contains(view.tray_entry_bounds, x, y);
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
            if (button.window_id == id and contains(view.row_bounds, x, y)) return current;
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

test "task overflow publishes popup bounds and keeps hidden windows actionable" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 500, .top = 8, .right = 800, .bottom = 56 }, .radius_x = 24, .radius_y = 24 };
    const title_a = [_:0]u16{'A'};
    const title_b = [_:0]u16{'B'};
    const title_c = [_:0]u16{'C'};
    const input = [_]TextRenderer.TaskButton{
        .{ .window_id = 41, .title = &title_a },
        .{ .window_id = 42, .title = &title_b },
        .{ .window_id = 43, .title = &title_c },
    };
    const view = buildDockView(island, &input, 9, 2, 1600, true);
    try std.testing.expectEqual(@as(usize, 2), view.count);
    try std.testing.expectEqual(@as(usize, 1), view.overflow_count);
    const hidden = view.overflow_buttons[0];
    try std.testing.expectEqual(@as(?Catalog.WindowId, 43), actionAt(&view, (hidden.bounds.left + hidden.bounds.right) * 0.5, (hidden.bounds.top + hidden.bounds.bottom) * 0.5));
    try std.testing.expect(systemEntryHit(&view, (view.system_entry_bounds.left + view.system_entry_bounds.right) * 0.5, (view.system_entry_bounds.top + view.system_entry_bounds.bottom) * 0.5));
    try std.testing.expect(trayEntryHit(&view, (view.tray_entry_bounds.left + view.tray_entry_bounds.right) * 0.5, (view.tray_entry_bounds.top + view.tray_entry_bounds.bottom) * 0.5));
    try std.testing.expect(overflowContains(&view, view.overflow_bounds.rect.left + 2, view.overflow_bounds.rect.top + 2));
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
    try std.testing.expectEqual(Layout.max_task_icons - Layout.max_visible_task_icons, view.overflow_count);
    try std.testing.expectApproxEqAbs(Layout.dock_gap_dip + view.row_bounds.right, view.overflow_button_bounds.left, 0.001);
    try std.testing.expect(view.overflow_button_bounds.right < 3000);

    const empty = buildDockView(island, &.{}, 10, 0, 3840, false);
    try std.testing.expectApproxEqAbs(island.rect.right + Layout.task_icon_pad_dip, empty.overflow_button_bounds.left, 0.001);
}
