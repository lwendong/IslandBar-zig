const Contract = @import("SystemStatusContract");

pub const SettingsPage = enum { accessibility, battery, hotspot, nearby, display, typing, general };

pub const Action = union(enum) {
    none,
    open_settings: SettingsPage,
    open_sound_page,
    open_tray_page,
    open_start_page,
    toggle_live_captions,
    cycle_theme,
    toggle_wifi,
    toggle_bluetooth,
    toggle_radio,
    toggle_night_light,
    projection_modes,
};

/// Sole Feature-owned authority for sampled system values and confirmed brightness.
pub const State = struct {
    status: Contract.Snapshot = .{},
    installed_layout_count: i32 = 0,
    brightness_available: bool = false,
    brightness_percent: i32 = 50,
    panel_page: i32 = 0,
    revision: u64 = 0,

    pub fn updateStatus(self: *State, incoming: Contract.Snapshot, layout_count: i32) void {
        if (@import("std").meta.eql(self.status, incoming) and self.installed_layout_count == layout_count) return;
        self.status = incoming;
        self.installed_layout_count = @max(0, layout_count);
        self.revision +%= 1;
    }

    pub fn updateBrightness(self: *State, available: bool, percent: i32) void {
        const bounded = @max(0, @min(100, percent));
        if (self.brightness_available == available and (!available or self.brightness_percent == bounded)) return;
        self.brightness_available = available;
        if (available) self.brightness_percent = bounded;
        self.revision +%= 1;
    }

    /// Brightness changes only after the platform adapter confirms a write and readback.
    pub fn confirmBrightness(self: *State, succeeded: bool, landed_percent: i32) void {
        if (!succeeded) return;
        self.updateBrightness(true, landed_percent);
    }

    pub fn advancePage(self: *State, delta: i32, page_count_arg: i32) void {
        const page_count = @max(1, page_count_arg);
        self.panel_page = @mod(self.panel_page + delta + page_count, page_count);
        self.revision +%= 1;
    }
};

test "brightness state changes only after confirmed platform result" {
    var state = State{ .brightness_available = true, .brightness_percent = 40 };
    state.confirmBrightness(false, 75);
    try @import("std").testing.expectEqual(@as(i32, 40), state.brightness_percent);
    state.confirmBrightness(true, 76);
    try @import("std").testing.expectEqual(@as(i32, 76), state.brightness_percent);
}

test "snapshot and capability degradation do not invent unsupported values" {
    var state = State{};
    state.updateStatus(.{}, 0);
    state.updateBrightness(false, 0);
    try @import("std").testing.expect(!state.brightness_available);
    try @import("std").testing.expectEqual(@as(i32, 50), state.brightness_percent);
}
