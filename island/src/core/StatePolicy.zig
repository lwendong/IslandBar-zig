const Motion = @import("Motion");

pub const IslandState = Motion.IslandState;

pub const PointerContext = struct {
    shape: IslandState = .collapsed,
    resting: IslandState = .collapsed,
    pointer_inside: bool = false,
    notification_active: bool = false,
    music_present: bool = false,
    icon_count: i32 = 0,
    hovered_icon: i32 = -1,
    fullscreen_app: bool = false,
    system_panel_open: bool = false,
    pointer_on_deck: bool = false,
    pointer_on_island: bool = false,
    pointer_in_card_column: bool = false,
};

pub const StatusPlacement = struct {
    in_island: bool = true,
    beside_deck: bool = false,
};

pub fn pointerIsOnIcon(c: PointerContext) bool {
    return c.icon_count > 0 and c.hovered_icon >= 0;
}

pub fn shouldGiveUpCard(c: PointerContext) bool {
    if (!c.pointer_inside or c.pointer_on_island or c.pointer_in_card_column) return false;
    return c.shape == .expanded;
}

pub fn shouldPromoteToCard(c: PointerContext) bool {
    if (!c.pointer_inside or !c.pointer_on_island) return false;
    if (c.shape != .hover and c.shape != .collapsed and c.shape != .music_strip) return false;
    return c.music_present;
}

pub fn shouldPromoteToTaskbar(c: PointerContext) bool {
    if (!c.pointer_inside or c.notification_active) return false;
    if (pointerIsOnIcon(c) or c.pointer_on_deck) return false;
    if (c.shape == .expanded and c.music_present) return false;
    return c.shape == .collapsed or c.shape == .music_strip or c.shape == .expanded;
}

pub fn shouldReturnToResting(c: PointerContext) bool {
    if (c.notification_active or c.pointer_inside) return false;
    return c.shape == .expanded or c.shape == .hover;
}

pub fn shouldAdoptNewResting(c: PointerContext) bool {
    if (c.notification_active or c.pointer_inside or c.shape == c.resting) return false;
    return c.shape == .collapsed or c.shape == .music_strip or c.shape == .notice_strip;
}

pub fn nextShape(c: PointerContext) IslandState {
    if (c.fullscreen_app) return if (c.notification_active) .notice_strip else .full_bar;
    if (c.shape == .full_bar) return c.resting;
    if (c.system_panel_open) return .expanded;
    if (c.notification_active) return .notice_strip;
    if (shouldGiveUpCard(c)) return c.resting;
    if (shouldPromoteToCard(c)) return .expanded;
    if (shouldPromoteToTaskbar(c)) return .hover;
    if (shouldReturnToResting(c) or shouldAdoptNewResting(c)) return c.resting;
    return c.shape;
}

pub fn nextShapeLegacy(shape: IslandState, resting: IslandState, pointer_inside: bool, notification_active: bool) IslandState {
    return nextShape(.{
        .shape = shape,
        .resting = resting,
        .pointer_inside = pointer_inside,
        .notification_active = notification_active,
        .music_present = resting == .music_strip,
        .pointer_on_island = pointer_inside,
    });
}

pub fn statusPlacementFor(island_line_taken: bool) StatusPlacement {
    return .{ .in_island = !island_line_taken, .beside_deck = island_line_taken };
}
