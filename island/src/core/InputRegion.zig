const Geometry = @import("Geometry");
const Motion = @import("Motion");
const BarControlLayout = @import("BarControlLayout");

pub const Region = struct { left: i32, top: i32, right: i32, bottom: i32 };

pub const Frame = struct {
    monitor_width_dip: f32,
    dpi: u32,
    state: Motion.IslandState,
    anchor: Motion.IslandAnchor,
    current: Geometry.RoundedBox,
    card_up: bool = false,
    card_left_dip: f32 = 0,
    task_row_bounds: Geometry.RectF = .{},
    status_strip_width_dip: f32 = 0,
    tray_icon_count: i32 = 0,
};

/// Returns the pixel bounds needed to admit the shapes painted in one frame.
/// The window remains monitor-sized; this smaller region keeps unused space
/// out of the shell's hit-test path while covering animated cards and rows.
pub fn forFrame(frame: Frame) Region {
    const dpi = if (frame.dpi == 0) 96 else frame.dpi;
    const scale = @as(f32, @floatFromInt(dpi)) / Geometry.dip_per_inch;
    const target_island = Motion.boxForState(frame.state, frame.anchor);
    const shape = if (Geometry.width(frame.current.rect) > 0) frame.current else target_island;
    const resting = Motion.boxForState(.collapsed, frame.anchor);
    const card_top = resting.rect.bottom + Motion.card_top_gap_dip;
    const card_bottom = card_top + Motion.expanded_height_dip;

    var left = shape.rect.left;
    var right = shape.rect.right;
    if (frame.card_up) {
        left = @min(left, frame.card_left_dip);
        right = @max(right, frame.card_left_dip + Motion.expanded_width_dip);
    }

    const tray_visible = frame.tray_icon_count > 0;
    const cluster = BarControlLayout.barClusterFor(target_island, tray_visible);
    left = @min(left, cluster.rect.left);

    if (frame.status_strip_width_dip > 0) {
        left = @min(left, BarControlLayout.statusStripFor(target_island).rect.left);
    }
    left = @max(0, left);

    const has_task_row = frame.task_row_bounds.right > frame.task_row_bounds.left and
        frame.task_row_bounds.bottom > frame.task_row_bounds.top;
    if (has_task_row) {
        left = @min(left, frame.task_row_bounds.left);
        right = @max(right, frame.task_row_bounds.right);
    }

    var bottom = if (frame.card_up) card_bottom else shape.rect.bottom;
    if (has_task_row) bottom = @max(bottom, frame.task_row_bounds.bottom);
    bottom += 2;

    var region = Region{
        .left = @intFromFloat(left * scale),
        .top = 0,
        .right = @intFromFloat(right * scale),
        .bottom = @intFromFloat(bottom * scale),
    };
    if (region.right <= region.left) region.right = region.left + 1;
    if (region.bottom <= region.top) region.bottom = region.top + 1;
    return region;
}

pub fn smokeCheck() bool {
    const anchor = Motion.anchorForWindow(0, 0, 1920, 0);
    const resting = Motion.boxForState(.collapsed, anchor);
    const rest_region = forFrame(.{
        .monitor_width_dip = 1920,
        .dpi = 96,
        .state = .collapsed,
        .anchor = anchor,
        .current = resting,
        .task_row_bounds = .{ .left = 1078, .top = 9, .right = 1180, .bottom = 39 },
    });
    if (rest_region.left < 0 or rest_region.top != 0 or rest_region.right <= rest_region.left or
        rest_region.right >= 1920 or rest_region.left > Geometry.dipToPixels(resting.rect.left, 96) or
        rest_region.right < Geometry.dipToPixels(resting.rect.right, 96) or
        rest_region.bottom <= 0 or rest_region.bottom >= 360) return false;

    const card_region = forFrame(.{
        .monitor_width_dip = 1920,
        .dpi = 144,
        .state = .expanded,
        .anchor = anchor,
        .current = Motion.boxForState(.expanded, anchor),
        .card_up = true,
        .card_left_dip = 500,
        .task_row_bounds = .{ .left = 1078, .top = 9, .right = 1180, .bottom = 39 },
        .status_strip_width_dip = BarControlLayout.status_strip_width_dip,
        .tray_icon_count = 1,
    });
    const expected_bottom = Geometry.dipToPixels(resting.rect.bottom + Motion.card_top_gap_dip + Motion.expanded_height_dip + 2, 144);
    if (card_region.left > Geometry.dipToPixels(500, 144) or
        card_region.right < Geometry.dipToPixels(1020, 144) or
        card_region.bottom != expected_bottom) return false;

    const closing_region = forFrame(.{
        .monitor_width_dip = 1920,
        .dpi = 144,
        .state = .collapsed,
        .anchor = anchor,
        .current = Motion.lerpBox(Motion.boxForState(.expanded, anchor), resting, 0.5),
        .card_up = true,
        .card_left_dip = 1130,
        .task_row_bounds = .{ .left = 1150, .top = 9, .right = 1650, .bottom = 39 },
        .tray_icon_count = 1,
    });
    if (closing_region.right < Geometry.dipToPixels(1650, 144) or closing_region.bottom != expected_bottom) return false;

    const wide_rest = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 2560, 0));
    const tray_region = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_row_bounds = .{ .left = 1398, .top = 9, .right = 2180, .bottom = 39 },
        .tray_icon_count = BarControlLayout.max_tray_icons,
    });
    const tray_button = BarControlLayout.trayButtonFor(wide_rest);
    const cluster = BarControlLayout.barClusterFor(wide_rest, true);
    if (tray_region.left > @as(i32, @intFromFloat(cluster.rect.left)) or
        tray_region.right < @as(i32, @intFromFloat(@max(tray_button.right, 2180)))) return false;

    const with_status = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_row_bounds = .{ .left = 1398, .top = 9, .right = 1700, .bottom = 39 },
        .status_strip_width_dip = BarControlLayout.status_strip_width_dip,
    });
    const without_status = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_row_bounds = .{ .left = 1398, .top = 9, .right = 1700, .bottom = 39 },
    });
    if (with_status.left >= without_status.left or with_status.bottom != without_status.bottom) return false;

    const full_anchor = Motion.anchorForWindow(0, 0, 2560, 32);
    const full_bar = Motion.boxForState(.full_bar, full_anchor);
    const full_region = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .full_bar,
        .anchor = full_anchor,
        .current = full_bar,
    });
    return full_region.left == 0 and full_region.right >= 2560 and
        full_region.bottom <= Geometry.dipToPixels(full_bar.rect.bottom + 2, 96);
}
