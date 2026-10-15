const Geometry = @import("Geometry");
const Motion = @import("Motion");
const TaskStripLayout = @import("TaskStripLayout");

pub const Region = struct { left: i32, top: i32, right: i32, bottom: i32 };

pub const Frame = struct {
    monitor_width_dip: f32,
    dpi: u32,
    state: Motion.IslandState,
    anchor: Motion.IslandAnchor,
    current: Geometry.RoundedBox,
    card_up: bool = false,
    card_left_dip: f32 = 0,
    task_icon_count: i32 = 0,
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
    const cluster = TaskStripLayout.barClusterFor(target_island, tray_visible);
    left = @min(left, cluster.rect.left);

    if (frame.status_strip_width_dip > 0) {
        left = @min(left, TaskStripLayout.statusStripFor(target_island).rect.left);
    }
    left = @max(0, left);

    const resting_row = Motion.rowAnchorBox(frame.current, resting);
    const row_with_tray = TaskStripLayout.rowAnchorWithTray(resting_row, tray_visible);
    const wanted = if (frame.task_icon_count < 0)
        TaskStripLayout.max_task_icons
    else
        @min(@as(usize, @intCast(frame.task_icon_count)), TaskStripLayout.max_task_icons);
    const fitting = TaskStripLayout.taskIconsThatFitForMonitor(frame.monitor_width_dip, wanted);
    const row_left = TaskStripLayout.taskRowFor(
        row_with_tray,
        @max(fitting, 1),
        frame.card_left_dip,
        if (frame.card_up) Motion.expanded_width_dip else 0,
    ).left;
    if (fitting > 0) {
        const row_right = TaskStripLayout.taskIconButtonAt(
            TaskStripLayout.rowAnchorWithTray(resting, tray_visible),
            fitting - 1,
            fitting,
            @intCast(fitting - 1),
            1,
            frame.card_left_dip,
            if (frame.card_up) Motion.expanded_width_dip else 0,
        ).right;
        right = @max(right, row_right);
    } else {
        right = @max(right, row_left);
    }

    const target_row = TaskStripLayout.taskRowFor(target_island, 1, 0, 0);
    var bottom = if (frame.card_up) card_bottom else shape.rect.bottom;
    if (target_row.valid) bottom = @max(bottom, target_row.bottom);
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
        .task_icon_count = 3,
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
        .task_icon_count = 3,
        .status_strip_width_dip = TaskStripLayout.status_strip_width_dip,
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
        .task_icon_count = 1,
        .tray_icon_count = 1,
    });
    if (closing_region.right < Geometry.dipToPixels(1650, 144) or closing_region.bottom != expected_bottom) return false;

    const wide_fit = TaskStripLayout.taskIconsThatFitForMonitor(2560, TaskStripLayout.max_task_icons);
    const wide_rest = Motion.boxForState(.collapsed, Motion.anchorForWindow(0, 0, 2560, 0));
    const tray_region = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_icon_count = -1,
        .tray_icon_count = TaskStripLayout.max_tray_icons,
    });
    const tray_button = TaskStripLayout.trayButtonFor(wide_rest);
    const last_open_icon = TaskStripLayout.taskIconButtonAt(
        TaskStripLayout.rowAnchorWithTray(wide_rest, true),
        wide_fit - 1,
        wide_fit,
        @intCast(wide_fit - 1),
        1,
        0,
        0,
    );
    const cluster = TaskStripLayout.barClusterFor(wide_rest, true);
    if (wide_fit == 0 or tray_region.left > @as(i32, @intFromFloat(cluster.rect.left)) or
        tray_region.right < @as(i32, @intFromFloat(@max(tray_button.right, last_open_icon.right)))) return false;

    const with_status = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_icon_count = 8,
        .status_strip_width_dip = TaskStripLayout.status_strip_width_dip,
    });
    const without_status = forFrame(.{
        .monitor_width_dip = 2560,
        .dpi = 96,
        .state = .collapsed,
        .anchor = Motion.anchorForWindow(0, 0, 2560, 0),
        .current = wide_rest,
        .task_icon_count = 8,
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
