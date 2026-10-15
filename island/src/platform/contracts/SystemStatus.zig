/// Platform-independent snapshot of system facts displayed by SystemPanel.
/// Failed Windows queries leave the last confirmed value unchanged in the adapter.
pub const SignalStrength = enum(i32) { none = 0, weak = 1, fair = 2, good = 3, excellent = 4 };
pub const NetworkKind = enum(i32) { none = 0, disconnected = 1, connected = 2 };

pub const Snapshot = struct {
    network: NetworkKind = .none,
    signal: SignalStrength = .none,
    signal_percent: i32 = 0,
    ssid: [33]u16 = @splat(0),
    wireless_radio_on: bool = true,
    bluetooth_present: bool = false,
    bluetooth_on: bool = false,
    bluetooth_name: [248]u16 = @splat(0),
    night_light_on: bool = false,
    live_captions_on: bool = false,
    wifi_radio_on: bool = true,
    battery_present: bool = false,
    on_ac_power: bool = true,
    battery_percent: i32 = 0,
    battery_saver_on: bool = false,
    input_language_id: u16 = 0,
    age_ms: u64 = 0,
};

test "system status defaults safely when capabilities have not been sampled" {
    const status = Snapshot{};
    try @import("std").testing.expect(status.network == .none);
    try @import("std").testing.expect(status.wifi_radio_on);
    try @import("std").testing.expect(!status.bluetooth_present and !status.battery_present);
}
