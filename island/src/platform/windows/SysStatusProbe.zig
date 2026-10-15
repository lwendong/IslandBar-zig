const std = @import("std");
const Log = @import("Log");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const ERROR_SUCCESS: DWORD = 0;
const ERROR_NO_MORE_ITEMS: DWORD = 259;
const WLAN_STATE = enum(u32) {
    not_ready = 0,
    connected = 1,
    ad_hoc = 2,
    disconnecting = 3,
    disconnected = 4,
    associating = 5,
    discovering = 6,
    authenticating = 7,
    _,
};
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const InterfaceInfo = extern struct { guid: Guid, description: [256]u16, state: WLAN_STATE };
const InterfaceInfoList = extern struct { count: DWORD, index: DWORD, interfaces: [1]InterfaceInfo };
const Dot11Ssid = extern struct { length: DWORD, bytes: [32]u8 };
const AssociationAttributes = extern struct {
    ssid: Dot11Ssid,
    bss_type: DWORD,
    bssid: [6]u8,
    phy_type: DWORD,
    phy_index: DWORD,
    signal_quality: DWORD,
    receive_rate: DWORD,
    transmit_rate: DWORD,
};
const SecurityAttributes = extern struct { security_enabled: BOOL, one_x_enabled: BOOL, auth_algorithm: DWORD, cipher_algorithm: DWORD };
const ConnectionAttributes = extern struct {
    state: WLAN_STATE,
    mode: DWORD,
    profile_name: [256]u16,
    association: AssociationAttributes,
    security: SecurityAttributes,
};
const PhyRadioState = extern struct { index: DWORD, software: DWORD, hardware: DWORD };
const RadioState = extern struct { count: DWORD, phys: [64]PhyRadioState };
const RadioFindParams = extern struct { size: DWORD };
const BluetoothAddress = extern union { value: u64, bytes: [8]u8 };
const BluetoothRadioInfo = extern struct {
    size: DWORD,
    address: BluetoothAddress,
    name: [248]u16,
    class_of_device: DWORD,
    lmp_subversion: u16,
    manufacturer: u16,
};

extern "wlanapi" fn WlanOpenHandle(version: DWORD, reserved: ?*anyopaque, negotiated: *DWORD, client: *HANDLE) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanEnumInterfaces(client: HANDLE, reserved: ?*anyopaque, list: *?*InterfaceInfoList) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanQueryInterface(client: HANDLE, interface_guid: *const Guid, opcode: DWORD, reserved: ?*anyopaque, data_size: *DWORD, data: *?*anyopaque, value_type: ?*DWORD) callconv(.winapi) DWORD;
extern "wlanapi" fn WlanFreeMemory(memory: ?*anyopaque) callconv(.winapi) void;
extern "wlanapi" fn WlanCloseHandle(client: HANDLE, reserved: ?*anyopaque) callconv(.winapi) DWORD;
extern "bthprops" fn BluetoothFindFirstRadio(params: *const RadioFindParams, radio: *HANDLE) callconv(.winapi) HANDLE;
extern "bthprops" fn BluetoothFindNextRadio(find: HANDLE, radio: *HANDLE) callconv(.winapi) BOOL;
extern "bthprops" fn BluetoothFindRadioClose(find: HANDLE) callconv(.winapi) BOOL;
extern "bthprops" fn BluetoothGetRadioInfo(radio: HANDLE, info: *BluetoothRadioInfo) callconv(.winapi) DWORD;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;

fn logFormat(comptime format: []const u8, args: anytype) void {
    const line = std.fmt.allocPrint(std.heap.page_allocator, format, args) catch return;
    defer std.heap.page_allocator.free(line);
    Log.logLine(line);
}

pub fn wlanStateName(state: WLAN_STATE) []const u8 {
    return switch (state) {
        .not_ready => "not ready",
        .connected => "connected",
        .ad_hoc => "ad-hoc",
        .disconnecting => "disconnecting",
        .disconnected => "disconnected",
        .associating => "associating",
        .discovering => "discovering",
        .authenticating => "authenticating",
        _ => "?",
    };
}

fn interfaceAt(list: *InterfaceInfoList, index: usize) *InterfaceInfo {
    return @ptrFromInt(@intFromPtr(list) + @offsetOf(InterfaceInfoList, "interfaces") + index * @sizeOf(InterfaceInfo));
}

pub fn probeWlan() void {
    Log.logLine("--- WLAN probe ---");
    var negotiated: DWORD = 0;
    var client: HANDLE = null;
    const opened = WlanOpenHandle(2, null, &negotiated, &client);
    if (opened != ERROR_SUCCESS) {
        logFormat("WlanOpenHandle -> {d}", .{opened});
        return;
    }
    defer _ = WlanCloseHandle(client, null);
    logFormat("WLAN client open, negotiated version {d}", .{negotiated});

    var list: ?*InterfaceInfoList = null;
    const enumerated = WlanEnumInterfaces(client, null, &list);
    const interfaces = list orelse {
        logFormat("WlanEnumInterfaces -> {d}", .{enumerated});
        return;
    };
    defer WlanFreeMemory(interfaces);
    logFormat("WLAN interfaces: {d}", .{interfaces.count});
    var index: usize = 0;
    while (index < interfaces.count) : (index += 1) {
        const info = interfaceAt(interfaces, index);
        logFormat("WLAN interface {d}: {s}", .{ index, wlanStateName(info.state) });
        var size: DWORD = 0;
        var attributes_data: ?*anyopaque = null;
        var opcode: DWORD = 0;
        const queried = WlanQueryInterface(client, &info.guid, 7, null, &size, &attributes_data, &opcode);
        if (queried != ERROR_SUCCESS) {
            logFormat("WlanQueryInterface current connection -> {d} (not connected)", .{queried});
            continue;
        }
        const attributes: *ConnectionAttributes = @ptrCast(@alignCast(attributes_data orelse continue));
        logFormat("connected signal quality: {d}%", .{attributes.association.signal_quality});
        WlanFreeMemory(attributes);
    }

    if (interfaces.count > 0) {
        var size: DWORD = 0;
        var radio_data: ?*anyopaque = null;
        var opcode: DWORD = 0;
        const result = WlanQueryInterface(client, &interfaceAt(interfaces, 0).guid, 8, null, &size, &radio_data, &opcode);
        if (result == ERROR_SUCCESS and radio_data != null and size >= @offsetOf(RadioState, "phys") + @sizeOf(PhyRadioState)) {
            const state: *const RadioState = @ptrCast(@alignCast(radio_data.?));
            if (state.count > 0 and state.count <= state.phys.len) {
                logFormat("WLAN radio: {d} phys, software={d}, hardware={d}", .{ state.count, state.phys[0].software, state.phys[0].hardware });
            } else {
                logFormat("WLAN radio state query -> {d}", .{result});
            }
            WlanFreeMemory(radio_data);
        } else {
            logFormat("WLAN radio state query -> {d}", .{result});
            if (radio_data) |data| WlanFreeMemory(data);
        }
    }
}

pub fn probeBluetooth() void {
    Log.logLine("--- Bluetooth probe ---");
    const params = RadioFindParams{ .size = @sizeOf(RadioFindParams) };
    var radio: HANDLE = null;
    const find = BluetoothFindFirstRadio(&params, &radio);
    if (find == null) {
        const error_code = GetLastError();
        logFormat("BluetoothFindFirstRadio -> none (error {d})", .{error_code});
        Log.logLine(if (error_code == ERROR_NO_MORE_ITEMS) "no Bluetooth radio found" else "Bluetooth radio could not be opened");
        return;
    }
    defer _ = BluetoothFindRadioClose(find);
    var count: usize = 0;
    while (radio) |handle| {
        var info = std.mem.zeroes(BluetoothRadioInfo);
        info.size = @sizeOf(BluetoothRadioInfo);
        const result = BluetoothGetRadioInfo(handle, &info);
        if (result == ERROR_SUCCESS) {
            logFormat("Bluetooth radio {d}: address={X}, manufacturer={d}, lmp={d}", .{ count, info.address.value, info.manufacturer, info.lmp_subversion });
        } else {
            logFormat("BluetoothGetRadioInfo -> {d}", .{result});
        }
        _ = CloseHandle(handle);
        count += 1;
        if (BluetoothFindNextRadio(find, &radio) == 0) break;
    }
    logFormat("Bluetooth radios enumerated: {d}", .{count});
}

pub fn runProbe() void {
    probeWlan();
    probeBluetooth();
}

pub fn main() void {
    runProbe();
}

pub fn smokeCheck() bool {
    if (!std.mem.eql(u8, wlanStateName(.connected), "connected")) return false;
    if (!std.mem.eql(u8, wlanStateName(.disconnected), "disconnected")) return false;
    return std.mem.eql(u8, wlanStateName(@fromBackingInt(@intCast(999))), "?");
}

comptime {
    if (false) runProbe();
}
