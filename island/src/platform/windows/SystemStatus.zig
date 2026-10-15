const std = @import("std");
const AudioVolume = @import("AudioVolume");
const Log = @import("Log");
const SystemToggles = @import("SystemToggles");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };

const WlanInterfaceInfo = extern struct {
    interface_guid: Guid,
    description: [256]u16,
    state: DWORD,
};
const WlanInterfaceInfoList = extern struct {
    number_of_items: DWORD,
    index: DWORD,
    interface_info: [1]WlanInterfaceInfo,
};
const Dot11Ssid = extern struct { length: DWORD, bytes: [32]u8 };
const WlanAssociationAttributes = extern struct {
    ssid: Dot11Ssid,
    bss_type: DWORD,
    bssid: [6]u8,
    phy_type: DWORD,
    phy_index: DWORD,
    signal_quality: DWORD,
    receive_rate: DWORD,
    transmit_rate: DWORD,
};
const WlanSecurityAttributes = extern struct {
    security_enabled: BOOL,
    one_x_enabled: BOOL,
    authentication_algorithm: DWORD,
    cipher_algorithm: DWORD,
};
const WlanConnectionAttributes = extern struct {
    state: DWORD,
    connection_mode: DWORD,
    profile_name: [256]u16,
    association: WlanAssociationAttributes,
    security: WlanSecurityAttributes,
};
const WlanPhyRadioState = extern struct {
    phy_index: DWORD,
    software_state: DWORD,
    hardware_state: DWORD,
};
const WlanRadioState = extern struct { number_of_phys: DWORD, phy_states: [1]WlanPhyRadioState };
const BluetoothFindRadioParams = extern struct { size: DWORD };
const BluetoothRadioInfo = extern struct {
    size: DWORD,
    padding: DWORD,
    address: u64,
    name: [248]u16,
    class_of_device: DWORD,
    lmp_subversion: u16,
    manufacturer: u16,
};
const SystemPowerStatus = extern struct {
    ac_line_status: u8,
    battery_flag: u8,
    battery_life_percent: u8,
    system_status_flag: u8,
    battery_life_time: i32,
    battery_full_life_time: i32,
};

extern "wlanapi" fn WlanOpenHandle(version: DWORD, reserved: ?*anyopaque, negotiated: *DWORD, client: *HANDLE) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanCloseHandle(client: HANDLE, reserved: ?*anyopaque) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanEnumInterfaces(client: HANDLE, reserved: ?*anyopaque, list: *?*anyopaque) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanQueryInterface(client: HANDLE, interface_guid: *const Guid, opcode: DWORD, reserved: ?*anyopaque, data_size: *DWORD, data: *?*anyopaque, opcode_type: ?*DWORD) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanFreeMemory(memory: ?*anyopaque) callconv(.winapi) void;
extern "bthprops" fn BluetoothFindFirstRadio(params: *const BluetoothFindRadioParams, radio: *HANDLE) callconv(.winapi) HANDLE;
extern "bthprops" fn BluetoothFindNextRadio(find: HANDLE, radio: *HANDLE) callconv(.winapi) BOOL;
extern "bthprops" fn BluetoothGetRadioInfo(radio: HANDLE, info: *BluetoothRadioInfo) callconv(.winapi) DWORD;
extern "bthprops" fn BluetoothFindRadioClose(find: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn GetSystemPowerStatus(status: *SystemPowerStatus) callconv(.winapi) BOOL;
extern "user32" fn GetKeyboardLayoutList(count: i32, layouts: ?[*]HANDLE) callconv(.winapi) i32;
extern "user32" fn GetForegroundWindow() callconv(.winapi) HANDLE;
extern "user32" fn GetWindowThreadProcessId(window: HANDLE, process_id: ?*DWORD) callconv(.winapi) DWORD;
extern "user32" fn GetKeyboardLayout(thread_id: DWORD) callconv(.winapi) HANDLE;

const wlan_success: DWORD = 0;
const wlan_state_connected: DWORD = 1;
const wlan_opcode_radio_state: DWORD = 4;
const wlan_opcode_current_connection: DWORD = 7;
const wlan_radio_state_off: DWORD = 2;
const battery_flag_no_battery: u8 = 128;
const unknown_power_value: u8 = 255;

comptime {
    if (@sizeOf(Guid) != 16 or @sizeOf(WlanInterfaceInfo) != 532 or
        @sizeOf(WlanAssociationAttributes) != 68 or @sizeOf(WlanConnectionAttributes) != 604 or
        @sizeOf(WlanRadioState) != 16 or @sizeOf(BluetoothRadioInfo) != 520 or
        @sizeOf(SystemPowerStatus) != 12)
    {
        @compileError("Windows system-status ABI structure size mismatch");
    }
}

pub const SignalStrength = enum(i32) { none = 0, weak = 1, fair = 2, good = 3, excellent = 4 };
pub const NetworkKind = enum(i32) { none = 0, disconnected = 1, connected = 2 };

pub const SystemStatus = struct {
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
    muted: bool = false,
    volume_percent: i32 = 0,
    wifi_radio_on: bool = true,
    battery_present: bool = false,
    on_ac_power: bool = true,
    battery_percent: i32 = 0,
    battery_saver_on: bool = false,
    input_language_id: u16 = 0,
    age_ms: u64 = 0,
};

/// Holds the WLAN client and cached machine facts used by the system panel.
/// Sampling leaves each field unchanged when its Windows query fails.
pub const SystemStatusReader = struct {
    wlan_client: HANDLE = null,
    wlan_open: bool = false,
    installed_layout_count: i32 = 0,
    bluetooth_probed: bool = false,

    pub fn open(self: *SystemStatusReader) bool {
        self.installed_layout_count = GetKeyboardLayoutList(0, null);
        if (self.installed_layout_count < 0) self.installed_layout_count = 0;
        if (!self.wlan_open) {
            var negotiated: DWORD = 0;
            var client: HANDLE = null;
            if (WlanOpenHandle(2, null, &negotiated, &client) == wlan_success) {
                self.wlan_client = client;
                self.wlan_open = true;
                Log.logLine("system status: WLAN client opened");
            } else {
                Log.logLine("system status: WLAN client unavailable");
            }
        }
        return true;
    }

    pub fn close(self: *SystemStatusReader) void {
        if (self.wlan_open and self.wlan_client != null) {
            _ = WlanCloseHandle(self.wlan_client, null);
            self.wlan_client = null;
            self.wlan_open = false;
        }
    }

    pub fn sample(self: *SystemStatusReader, output_arg: ?*SystemStatus) void {
        const output = output_arg orelse return;
        if (self.wlan_open and self.wlan_client != null) self.sampleWireless(output);

        if (!self.bluetooth_probed) {
            self.bluetooth_probed = probeBluetooth(output);
            if (self.bluetooth_probed) Log.logLine("system status: Bluetooth radio found");
        } else {
            _ = probeBluetooth(output);
        }

        var muted = output.muted;
        var volume_percent = output.volume_percent;
        if (AudioVolume.readCurrentOutput(&muted, &volume_percent)) {
            output.muted = muted;
            output.volume_percent = volume_percent;
        }

        output.night_light_on = SystemToggles.nightLightOnForDisplay();
        output.live_captions_on = SystemToggles.liveCaptionsRunning();
        self.samplePower(output);
        self.sampleInputLanguage(output);
        output.age_ms = 0;
    }

    pub fn layoutCount(self: *const SystemStatusReader) i32 {
        return self.installed_layout_count;
    }

    fn sampleWireless(self: *SystemStatusReader, output: *SystemStatus) void {
        var raw_list: ?*anyopaque = null;
        if (WlanEnumInterfaces(self.wlan_client, null, &raw_list) != wlan_success or raw_list == null) return;
        const list: *WlanInterfaceInfoList = @ptrCast(@alignCast(raw_list.?));
        const has_interface = list.number_of_items > 0;
        var connected = false;
        output.signal = .none;
        output.signal_percent = 0;
        output.ssid[0] = 0;

        var index: usize = 0;
        while (index < list.number_of_items) : (index += 1) {
            const interfaces: [*]WlanInterfaceInfo = @ptrCast(&list.interface_info);
            const info = &interfaces[index];
            if (info.state != wlan_state_connected) continue;
            connected = true;
            var size: DWORD = 0;
            var raw_attributes: ?*anyopaque = null;
            var opcode_type: DWORD = 0;
            if (WlanQueryInterface(self.wlan_client, &info.interface_guid, wlan_opcode_current_connection, null, &size, &raw_attributes, &opcode_type) == wlan_success and raw_attributes != null) {
                const attributes: *WlanConnectionAttributes = @ptrCast(@alignCast(raw_attributes.?));
                const association = attributes.association;
                output.signal_percent = @intCast(association.signal_quality);
                output.signal = signalFromPercent(output.signal_percent);
                const ssid_len = @min(association.ssid.length, output.ssid.len - 1);
                for (0..ssid_len) |character| output.ssid[character] = association.ssid.bytes[character];
                output.ssid[ssid_len] = 0;
                WlanFreeMemory(raw_attributes);
            }
            break;
        }
        output.network = networkKindFor(has_interface, connected);

        if (has_interface) {
            var size: DWORD = 0;
            var raw_radio: ?*anyopaque = null;
            var opcode_type: DWORD = 0;
            const first_entry_size = @offsetOf(WlanRadioState, "phy_states") + @sizeOf(WlanPhyRadioState);
            const first_guid = &list.interface_info[0].interface_guid;
            if (WlanQueryInterface(self.wlan_client, first_guid, wlan_opcode_radio_state, null, &size, &raw_radio, &opcode_type) == wlan_success and raw_radio != null) {
                const radio: *WlanRadioState = @ptrCast(@alignCast(raw_radio.?));
                if (size >= first_entry_size and radio.number_of_phys > 0) {
                    output.wifi_radio_on = radio.phy_states[0].software_state != wlan_radio_state_off;
                    output.wireless_radio_on = output.wifi_radio_on;
                }
                WlanFreeMemory(raw_radio);
            }
        }
        WlanFreeMemory(raw_list);
    }

    fn samplePower(_: *SystemStatusReader, output: *SystemStatus) void {
        var power: SystemPowerStatus = undefined;
        if (GetSystemPowerStatus(&power) == 0) return;
        const no_battery = (power.battery_flag & battery_flag_no_battery) != 0;
        const percent_known = power.battery_life_percent != unknown_power_value;
        const ac_known = power.ac_line_status != unknown_power_value;
        output.battery_present = !no_battery and percent_known;
        if (percent_known) output.battery_percent = power.battery_life_percent;
        if (ac_known) output.on_ac_power = power.ac_line_status == 1;
        output.battery_saver_on = power.system_status_flag == 1;
    }

    fn sampleInputLanguage(_: *SystemStatusReader, output: *SystemStatus) void {
        const foreground = GetForegroundWindow() orelse return;
        const thread_id = GetWindowThreadProcessId(foreground, null);
        if (thread_id == 0) return;
        const layout = GetKeyboardLayout(thread_id) orelse return;
        output.input_language_id = @truncate(@intFromPtr(layout));
    }
};

fn probeBluetooth(output: *SystemStatus) bool {
    var params = BluetoothFindRadioParams{ .size = @sizeOf(BluetoothFindRadioParams) };
    var radio: HANDLE = null;
    const find = BluetoothFindFirstRadio(&params, &radio);
    if (find == null) {
        output.bluetooth_present = false;
        output.bluetooth_on = false;
        return false;
    }

    var found = false;
    while (radio != null) {
        var info = std.mem.zeroes(BluetoothRadioInfo);
        info.size = @sizeOf(BluetoothRadioInfo);
        if (BluetoothGetRadioInfo(radio, &info) == 0) {
            found = true;
            output.bluetooth_present = true;
            output.bluetooth_on = true;
            copyWideZ(&output.bluetooth_name, &info.name);
        }
        _ = CloseHandle(radio);
        radio = null;
        if (BluetoothFindNextRadio(find, &radio) == 0) break;
    }
    _ = BluetoothFindRadioClose(find);
    if (!found) {
        output.bluetooth_present = false;
        output.bluetooth_on = false;
    }
    return found;
}

fn copyWideZ(destination: []u16, source: []const u16) void {
    if (destination.len == 0) return;
    const source_len = std.mem.indexOfScalar(u16, source, 0) orelse source.len;
    const count = @min(source_len, destination.len - 1);
    @memcpy(destination[0..count], source[0..count]);
    destination[count] = 0;
}

fn wideSlice(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn appendWide(output: []u16, used_arg: usize, text: []const u16) usize {
    if (output.len == 0 or used_arg >= output.len - 1) return used_arg;
    const used = used_arg;
    const count = @min(text.len, output.len - used - 1);
    @memcpy(output[used .. used + count], text[0..count]);
    output[used + count] = 0;
    return used + count;
}

fn appendAscii(output: []u16, used_arg: usize, text: []const u8) usize {
    var used = used_arg;
    for (text) |ch| {
        if (output.len == 0 or used + 1 >= output.len) break;
        output[used] = ch;
        used += 1;
    }
    if (output.len > 0) output[used] = 0;
    return used;
}

fn writeWide(output: []u16, text: []const u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    _ = appendAscii(output, 0, text);
}

fn appendPercent(output: []u16, used: usize, percent: i32) usize {
    var number: [24]u8 = undefined;
    const formatted = std.fmt.bufPrint(&number, " ({d}%)", .{percent}) catch return used;
    return appendAscii(output, used, formatted);
}

pub fn signalFromPercent(percent: i32) SignalStrength {
    if (percent <= 0) return .none;
    if (percent < 25) return .weak;
    if (percent < 50) return .fair;
    if (percent < 75) return .good;
    return .excellent;
}

pub fn networkKindFor(has_interface: bool, connected: bool) NetworkKind {
    if (!has_interface) return .none;
    return if (connected) .connected else .disconnected;
}

pub fn inputMethodLabel(language_id: u16, output: []u16) void {
    if (output.len < 2) return;
    @memset(output, 0);
    const primary = language_id & 0x03ff;
    const label: ?[]const u16 = switch (primary) {
        0x04 => &.{0x4E2D},
        0x11 => &.{0x3042},
        0x12 => &.{0xD55C},
        0x09 => &.{ 'E', 'N' },
        0x07 => &.{ 'D', 'E' },
        0x0c => &.{ 'F', 'R' },
        0x0a => &.{ 'E', 'S' },
        0x10 => &.{ 'I', 'T' },
        0x16 => &.{ 'P', 'T' },
        0x19 => &.{ 'R', 'U' },
        else => null,
    };
    if (label) |value| {
        _ = appendWide(output, 0, value);
        return;
    }
    const digits = "0123456789ABCDEF";
    const byte: u8 = @truncate(language_id);
    output[0] = digits[byte >> 4];
    output[1] = digits[byte & 0x0f];
}

pub fn shouldDrawInputMethod(status: *const SystemStatus, installed_layout_count: i32) bool {
    return status.input_language_id != 0 and installed_layout_count > 1;
}

pub fn shouldDrawBattery(status: *const SystemStatus) bool {
    return status.battery_present and status.battery_percent >= 0 and status.battery_percent <= 100;
}

pub fn networkTooltip(status: *const SystemStatus, output: []u16) void {
    if (output.len == 0) return;
    @memset(output, 0);
    switch (status.network) {
        .none => writeWide(output, "No wireless adapter"),
        .disconnected => writeWide(output, "Not connected"),
        .connected => {
            var used: usize = 0;
            const ssid = wideSlice(&status.ssid);
            if (ssid.len > 0) {
                used = appendWide(output, used, ssid);
            } else {
                used = appendAscii(output, used, "Connected");
            }
            _ = appendPercent(output, used, status.signal_percent);
        },
    }
}

pub fn bluetoothTooltip(status: *const SystemStatus, output: []u16) void {
    if (output.len == 0) return;
    @memset(output, 0);
    if (!status.bluetooth_present) {
        writeWide(output, "No Bluetooth");
    } else if (!status.bluetooth_on) {
        writeWide(output, "Bluetooth off");
    } else if (wideSlice(&status.bluetooth_name).len > 0) {
        const used = appendAscii(output, 0, "Bluetooth: ");
        _ = appendWide(output, used, wideSlice(&status.bluetooth_name));
    } else {
        writeWide(output, "Bluetooth on");
    }
}

pub fn smokeCheck() bool {
    if (false) {
        var reader = SystemStatusReader{};
        _ = reader.open();
        var sample = SystemStatus{};
        reader.sample(&sample);
        reader.close();
        _ = reader.layoutCount();
    }
    if (signalFromPercent(0) != .none or signalFromPercent(1) != .weak or signalFromPercent(24) != .weak) return false;
    if (signalFromPercent(25) != .fair or signalFromPercent(50) != .good or signalFromPercent(75) != .excellent) return false;
    if (networkKindFor(false, true) != .none or networkKindFor(true, false) != .disconnected or networkKindFor(true, true) != .connected) return false;
    var label: [8]u16 = @splat(0);
    inputMethodLabel(0x0804, &label);
    if (!std.mem.eql(u16, wideSlice(&label), &.{0x4E2D})) return false;
    inputMethodLabel(0x0409, &label);
    if (!std.mem.eql(u16, wideSlice(&label), &.{ 'E', 'N' })) return false;
    var status = SystemStatus{ .network = .connected, .signal_percent = 74 };
    var tooltip: [64]u16 = @splat(0);
    networkTooltip(&status, &tooltip);
    if (!std.mem.eql(u16, wideSlice(&tooltip), &.{ 'C', 'o', 'n', 'n', 'e', 'c', 't', 'e', 'd', ' ', '(', '7', '4', '%', ')' })) return false;
    status.battery_present = true;
    status.battery_percent = 100;
    if (!shouldDrawBattery(&status)) return false;
    status.battery_percent = 255;
    if (shouldDrawBattery(&status)) return false;
    status.bluetooth_present = true;
    status.bluetooth_on = false;
    bluetoothTooltip(&status, &tooltip);
    return std.mem.eql(u16, wideSlice(&tooltip), &.{ 'B', 'l', 'u', 'e', 't', 'o', 'o', 't', 'h', ' ', 'o', 'f', 'f' });
}
