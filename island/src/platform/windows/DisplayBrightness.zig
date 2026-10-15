const std = @import("std");

const HMONITOR = ?*anyopaque;
const HANDLE = ?*anyopaque;
const BOOL = i32;
const DWORD = u32;

const SRWLock = extern struct { pointer: ?*anyopaque };
extern "kernel32" fn AcquireSRWLockExclusive(lock: *SRWLock) callconv(.winapi) void;
extern "kernel32" fn ReleaseSRWLockExclusive(lock: *SRWLock) callconv(.winapi) void;

const PhysicalMonitor = extern struct {
    handle: HANDLE,
    description: [128]u16,
};

extern "dxva2" fn GetNumberOfPhysicalMonitorsFromHMONITOR(monitor: HMONITOR, count: *DWORD) callconv(.winapi) BOOL;
extern "dxva2" fn GetPhysicalMonitorsFromHMONITOR(monitor: HMONITOR, count: DWORD, monitors: *PhysicalMonitor) callconv(.winapi) BOOL;
extern "dxva2" fn DestroyPhysicalMonitors(count: DWORD, monitors: *const PhysicalMonitor) callconv(.winapi) BOOL;
extern "dxva2" fn GetMonitorCapabilities(monitor: HANDLE, caps: *DWORD, temperatures: *DWORD) callconv(.winapi) BOOL;
extern "dxva2" fn GetMonitorBrightness(monitor: HANDLE, minimum: *DWORD, current: *DWORD, maximum: *DWORD) callconv(.winapi) BOOL;
extern "dxva2" fn SetMonitorBrightness(monitor: HANDLE, brightness: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn OutputDebugStringW(text: [*:0]const u16) callconv(.winapi) void;

const brightness_capability: DWORD = 0x00000002;

const CachedMonitor = struct {
    monitor: HMONITOR = null,
    physical: PhysicalMonitor = .{ .handle = null, .description = @splat(0) },
    minimum: DWORD = 0,
    maximum: DWORD = 100,
    valid: bool = false,
};

var cached: CachedMonitor = .{};
var mutex: SRWLock = .{ .pointer = null };

fn debug(message: []const u8) void {
    var wide: [256:0]u16 = undefined;
    const count = @min(message.len, wide.len - 1);
    for (message[0..count], 0..) |byte, index| wide[index] = byte;
    wide[count] = 0;
    OutputDebugStringW(wide[0..count :0]);
}

fn dropLocked() void {
    if (cached.physical.handle != null) _ = DestroyPhysicalMonitors(1, &cached.physical);
    cached = .{};
}

fn acquireLocked(monitor: HMONITOR) bool {
    if (cached.valid and cached.monitor == monitor) return true;
    dropLocked();
    if (monitor == null) return false;

    var count: DWORD = 0;
    if (GetNumberOfPhysicalMonitorsFromHMONITOR(monitor, &count) == 0 or count == 0) {
        debug("IslandBar: display reports no physical monitors\n");
        return false;
    }

    var physical = PhysicalMonitor{ .handle = null, .description = @splat(0) };
    if (GetPhysicalMonitorsFromHMONITOR(monitor, 1, &physical) == 0 or physical.handle == null) {
        debug("IslandBar: physical monitor could not be opened\n");
        return false;
    }

    var caps: DWORD = 0;
    var temperatures: DWORD = 0;
    if (GetMonitorCapabilities(physical.handle, &caps, &temperatures) == 0) {
        debug("IslandBar: monitor did not answer DDC/CI capabilities\n");
        _ = DestroyPhysicalMonitors(1, &physical);
        return false;
    }
    if ((caps & brightness_capability) == 0) {
        debug("IslandBar: monitor does not expose brightness\n");
        _ = DestroyPhysicalMonitors(1, &physical);
        return false;
    }

    var minimum: DWORD = 0;
    var current: DWORD = 0;
    var maximum: DWORD = 0;
    if (GetMonitorBrightness(physical.handle, &minimum, &current, &maximum) == 0 or maximum <= minimum) {
        debug("IslandBar: monitor did not report a valid brightness range\n");
        _ = DestroyPhysicalMonitors(1, &physical);
        return false;
    }

    cached = .{
        .monitor = monitor,
        .physical = physical,
        .minimum = minimum,
        .maximum = maximum,
        .valid = true,
    };
    return true;
}

fn readLocked(percent: ?*i32) bool {
    var minimum: DWORD = 0;
    var current: DWORD = 0;
    var maximum: DWORD = 0;
    if (GetMonitorBrightness(cached.physical.handle, &minimum, &current, &maximum) == 0 or maximum <= minimum) {
        dropLocked();
        return false;
    }

    cached.minimum = minimum;
    cached.maximum = maximum;
    if (percent) |out| {
        const span: u64 = maximum - minimum;
        const relative: u64 = current - minimum;
        out.* = @intCast((relative * 100 + span / 2) / span);
    }
    return true;
}

fn toRaw(percent_arg: i32, minimum: DWORD, maximum: DWORD) DWORD {
    const percent = @min(@max(percent_arg, 0), 100);
    const span: u64 = maximum - minimum;
    return minimum + @as(DWORD, @intCast((span * @as(u64, @intCast(percent)) + 50) / 100));
}

/// Whether the display exposes readable DDC/CI brightness.
pub fn brightnessAvailable(monitor: HMONITOR) bool {
    AcquireSRWLockExclusive(&mutex);
    defer ReleaseSRWLockExclusive(&mutex);
    return acquireLocked(monitor);
}

/// Reads brightness as a percentage of the monitor's own range.
pub fn readBrightnessPercent(monitor: HMONITOR, percent: *i32) bool {
    AcquireSRWLockExclusive(&mutex);
    defer ReleaseSRWLockExclusive(&mutex);
    if (!acquireLocked(monitor)) return false;
    return readLocked(percent);
}

/// Sets brightness and verifies the value by reading it back.
pub fn setBrightnessPercent(monitor: HMONITOR, percent: i32, landed_percent: ?*i32) bool {
    AcquireSRWLockExclusive(&mutex);
    defer ReleaseSRWLockExclusive(&mutex);
    if (!acquireLocked(monitor)) return false;

    const minimum = cached.minimum;
    const maximum = cached.maximum;
    const wanted = toRaw(percent, minimum, maximum);
    if (SetMonitorBrightness(cached.physical.handle, wanted) == 0) {
        if (landed_percent) |out| out.* = percent;
        return false;
    }

    var landed = percent;
    if (!readLocked(&landed)) {
        if (landed_percent) |out| out.* = percent;
        return false;
    }
    if (landed_percent) |out| out.* = landed;
    return toRaw(landed, minimum, maximum) == wanted;
}

/// Releases the cached physical-monitor handle.
pub fn forgetBrightnessMonitor() void {
    AcquireSRWLockExclusive(&mutex);
    defer ReleaseSRWLockExclusive(&mutex);
    dropLocked();
}

pub fn smokeCheck() bool {
    return toRaw(-1, 10, 110) == 10 and
        toRaw(50, 10, 110) == 60 and
        toRaw(101, 10, 110) == 110;
}
