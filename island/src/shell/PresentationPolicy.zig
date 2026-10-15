const std = @import("std");

/// The Shell's authoritative selection for the surface currently presented.
pub const CardOwner = enum(i32) { none = 0, system_panel = 1, notification = 2, music = 3 };

/// The selected subpage within the system card.
pub const PanelLevel = enum(u8) { tiles = 0, sound = 1, tray = 2, start = 3 };

pub const State = struct {
    card_owner: CardOwner = .none,
    panel_level: PanelLevel = .tiles,
};

/// Value-only facts sampled by the composition root for one presentation update.
pub const Facts = struct {
    card_up: bool = false,
    card_wanted: bool = false,
    notification_active: bool = false,
    music_present: bool = false,
    panel_wanted: bool = false,
    tray_wanted: bool = false,
    sound_wanted: bool = false,
    start_wanted: bool = false,
};

pub const ControlLit = struct { system: bool = false, tray: bool = false, start: bool = false };

/// Resolves Shell presentation state while preserving the existing hold and priority rules.
pub fn next(previous: State, facts: Facts) State {
    return .{
        .card_owner = nextCardOwner(previous.card_owner, facts),
        .panel_level = nextPanelLevel(previous.panel_level, facts),
    };
}

fn nextCardOwner(current: CardOwner, facts: Facts) CardOwner {
    if (!facts.card_up) return .none;
    if (!facts.card_wanted) return current;
    if (facts.panel_wanted) return .system_panel;
    if (facts.notification_active) return .notification;
    if (facts.music_present) return .music;
    return current;
}

fn nextPanelLevel(held: PanelLevel, facts: Facts) PanelLevel {
    if (!facts.card_up) return .tiles;
    if (!facts.panel_wanted) return held;
    if (facts.tray_wanted) return .tray;
    if (facts.sound_wanted) return .sound;
    if (facts.start_wanted) return .start;
    return .tiles;
}

/// Button state is derived from the selected Shell surface and passed to UI as values.
pub fn controlLitFor(state: State, card_up: bool) ControlLit {
    if (!card_up or state.card_owner != .system_panel) return .{};
    return .{
        .system = state.panel_level == .tiles or state.panel_level == .sound,
        .tray = state.panel_level == .tray,
        .start = state.panel_level == .start,
    };
}

test "card owner preserves panel, notification, then music priority" {
    const selected = next(.{}, .{
        .card_up = true,
        .card_wanted = true,
        .notification_active = true,
        .music_present = true,
        .panel_wanted = true,
        .tray_wanted = true,
    });
    try std.testing.expectEqual(CardOwner.system_panel, selected.card_owner);
    try std.testing.expectEqual(PanelLevel.tray, selected.panel_level);

    const notification = next(.{}, .{ .card_up = true, .card_wanted = true, .notification_active = true, .music_present = true });
    try std.testing.expectEqual(CardOwner.notification, notification.card_owner);
    const music = next(.{}, .{ .card_up = true, .card_wanted = true, .music_present = true });
    try std.testing.expectEqual(CardOwner.music, music.card_owner);
}

test "closing holds the selected surface until the card is fully down" {
    const opening = next(.{}, .{
        .card_up = true,
        .card_wanted = true,
        .panel_wanted = true,
        .tray_wanted = true,
    });
    const closing = next(opening, .{ .card_up = true });
    try std.testing.expectEqual(opening, closing);

    const closed = next(closing, .{});
    try std.testing.expectEqual(State{}, closed);
}

test "panel priority and quick reversal use the latest facts" {
    const opening = next(.{}, .{
        .card_up = true,
        .card_wanted = true,
        .panel_wanted = true,
        .tray_wanted = true,
        .sound_wanted = true,
        .start_wanted = true,
    });
    try std.testing.expectEqual(PanelLevel.tray, opening.panel_level);

    const closing = next(opening, .{ .card_up = true });
    const reversed = next(closing, .{
        .card_up = true,
        .card_wanted = true,
        .panel_wanted = true,
        .sound_wanted = true,
    });
    try std.testing.expectEqual(PanelLevel.sound, reversed.panel_level);
    try std.testing.expectEqual(CardOwner.system_panel, reversed.card_owner);
}

test "control lights follow the selected system panel surface" {
    const sound = State{ .card_owner = .system_panel, .panel_level = .sound };
    const sound_lights = controlLitFor(sound, true);
    try std.testing.expect(sound_lights.system and !sound_lights.tray and !sound_lights.start);

    const tray = State{ .card_owner = .system_panel, .panel_level = .tray };
    const tray_lights = controlLitFor(tray, true);
    try std.testing.expect(!tray_lights.system and tray_lights.tray and !tray_lights.start);
    try std.testing.expectEqual(ControlLit{}, controlLitFor(tray, false));
    try std.testing.expectEqual(ControlLit{}, controlLitFor(.{ .card_owner = .music }, true));
}
