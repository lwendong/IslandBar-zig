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
    frame_generation: u64,
    card_left_dip: f32,
    card_width_dip: f32,
    hovered_id: ?Catalog.WindowId,
) View {
    var view = View{
        .catalog_revision = catalog_revision,
        .frame_generation = frame_generation,
        .island = island,
        .count = @min(input.len, Layout.max_task_icons),
    };
    if (view.count == 0) return view;
    var amounts: [Layout.max_task_icons]f32 = @splat(0);
    for (input[0..view.count], 0..) |button, index| amounts[index] = std.math.clamp(button.hover_amount, 0, 1);
    for (input[0..view.count], 0..) |source, index| {
        var button = source;
        button.bounds = Layout.taskIconButtonAtAmounts(island, index, view.count, &amounts, card_left_dip, card_width_dip);
        button.icon_bounds = Layout.taskIconInBox(button.bounds);
        button.title_bounds = if (hovered_id == button.window_id)
            Layout.taskTitleAtAmounts(island, index, view.count, &amounts, @intCast(index), card_left_dip, card_width_dip)
        else
            .{};
        if (button.title_bounds.right - button.title_bounds.left < Layout.task_title_min_width_dip) button.title_bounds = .{};
        view.buttons[index] = button;
        view.row_bounds = unionBounds(view.row_bounds, button.bounds);
    }
    return view;
}

pub fn actionAt(view: *const View, x: f32, y: f32) ?Catalog.WindowId {
    for (view.buttons[0..view.count]) |button| {
        if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
    }
    return null;
}

/// Keeps the current expansion while the pointer travels through the task row
/// gap, using the same row geometry that was published for drawing and input.
pub fn hoverTarget(view: *const View, current: ?Catalog.WindowId, x: f32, y: f32) ?Catalog.WindowId {
    for (view.buttons[0..view.count]) |button| {
        if (button.window_id != 0 and contains(button.bounds, x, y)) return button.window_id;
    }
    if (current != null and contains(view.row_bounds, x, y)) return current;
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

test "taskbar page paints and hits the same animated button bounds" {
    const island = Geometry.RoundedBox{ .rect = .{ .left = 500, .top = 0, .right = 720, .bottom = 36 }, .radius_x = 18, .radius_y = 18 };
    const title_a = [_:0]u16{'A'};
    const title_b = [_:0]u16{'B'};
    const input = [_]TextRenderer.TaskButton{
        .{ .window_id = 41, .title = &title_a, .hover_amount = 0 },
        .{ .window_id = 42, .title = &title_b, .hover_amount = 0 },
    };
    const view = buildView(island, &input, 7, 9, 0, 0, null);
    const first = view.buttons[0].bounds;
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), actionAt(&view, first.left + 2, first.top + 2));
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), hoverTarget(&view, null, first.left + 2, first.top + 2));
    try std.testing.expect(actionAt(&view, first.right + 2, first.top + 2) == null);
    try std.testing.expectEqual(@as(?Catalog.WindowId, 41), hoverTarget(&view, 41, first.right + 1, first.top + 2));
    try std.testing.expectEqual(@as(u64, 7), view.catalog_revision);
    try std.testing.expectEqual(@as(u64, 9), view.frame_generation);
    try std.testing.expect(view.row_bounds.right >= view.buttons[1].bounds.right);
}
