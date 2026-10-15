const std = @import("std");

const BOOL = i32;
const DWORD = u32;
const HANDLE = ?*anyopaque;
const HRESULT = i32;
const INVALID_HANDLE_VALUE: usize = std.math.maxInt(usize);
const WAIT_OBJECT_0: DWORD = 0;
const WAIT_TIMEOUT: DWORD = 258;
const WAIT_FAILED: DWORD = 0xFFFFFFFF;
const INFINITE: DWORD = 0xFFFFFFFF;
const CLSCTX_ALL: DWORD = 23;
const eRender: i32 = 0;
const eConsole: i32 = 0;
const POLL_INTERVAL_MS: u64 = 500;
const PEAK_INTERVAL_MS: DWORD = 33;

const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};

const QueryInterfaceFn = *const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) HRESULT;
const AddRefFn = *const fn (*anyopaque) callconv(.winapi) u32;
const ReleaseFn = *const fn (*anyopaque) callconv(.winapi) u32;
const UnknownVTable = extern struct { query_interface: QueryInterfaceFn, add_ref: AddRefFn, release: ReleaseFn };
const Unknown = extern struct { vtable: *const UnknownVTable };

const GetDefaultEndpointFn = *const fn (*anyopaque, i32, i32, *?*anyopaque) callconv(.winapi) HRESULT;
const DeviceEnumeratorVTable = extern struct {
    unknown: UnknownVTable,
    enum_audio_endpoints: usize,
    get_default_audio_endpoint: GetDefaultEndpointFn,
    get_device: usize,
    register_endpoint_notification_callback: usize,
    unregister_endpoint_notification_callback: usize,
};
const ActivateFn = *const fn (*anyopaque, *const Guid, DWORD, ?*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT;
const DeviceVTable = extern struct {
    unknown: UnknownVTable,
    activate: ActivateFn,
    open_property_store: usize,
    get_id: usize,
    get_state: usize,
};
const ScalarFn = *const fn (*anyopaque, f32, ?*const Guid) callconv(.winapi) HRESULT;
const GetScalarFn = *const fn (*anyopaque, *f32) callconv(.winapi) HRESULT;
const SetMuteFn = *const fn (*anyopaque, BOOL, ?*const Guid) callconv(.winapi) HRESULT;
const GetMuteFn = *const fn (*anyopaque, *BOOL) callconv(.winapi) HRESULT;
const EndpointVolumeVTable = extern struct {
    unknown: UnknownVTable,
    register_control_change_notify: usize,
    unregister_control_change_notify: usize,
    get_channel_count: usize,
    set_master_volume_level: usize,
    set_master_volume_level_scalar: ScalarFn,
    get_master_volume_level: usize,
    get_master_volume_level_scalar: GetScalarFn,
    set_channel_volume_level: usize,
    set_channel_volume_level_scalar: usize,
    get_channel_volume_level: usize,
    get_channel_volume_level_scalar: usize,
    set_mute: SetMuteFn,
    get_mute: GetMuteFn,
    get_volume_step_info: usize,
    volume_step_up: usize,
    volume_step_down: usize,
    query_hardware_support: usize,
    get_volume_range: usize,
};
const GetPeakFn = *const fn (*anyopaque, *f32) callconv(.winapi) HRESULT;
const MeterVTable = extern struct {
    unknown: UnknownVTable,
    get_peak_value: GetPeakFn,
    get_metering_channel_count: usize,
    get_channels_peak_values: usize,
    query_hardware_support: usize,
};

const CLSID_MMDeviceEnumerator = Guid{ .data1 = 0xBCDE0395, .data2 = 0xE52F, .data3 = 0x467C, .data4 = .{ 0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E } };
const IID_IMMDeviceEnumerator = Guid{ .data1 = 0xA95664D2, .data2 = 0x9614, .data3 = 0x4F35, .data4 = .{ 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6 } };
const IID_IAudioEndpointVolume = Guid{ .data1 = 0x5CDF2C82, .data2 = 0x841E, .data3 = 0x4546, .data4 = .{ 0x97, 0x22, 0x0C, 0xF7, 0x40, 0x78, 0x22, 0x9A } };
const IID_IAudioMeterInformation = Guid{ .data1 = 0xC02216F6, .data2 = 0x8C67, .data3 = 0x4B5B, .data4 = .{ 0x9D, 0x00, 0xD0, 0x08, 0xE7, 0x3E, 0x00, 0x64 } };

extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, apartment: DWORD) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoCreateInstance(clsid: *const Guid, outer: ?*anyopaque, context: DWORD, iid: *const Guid, object: *?*anyopaque) callconv(.winapi) HRESULT;
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, start: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn WaitForMultipleObjects(count: DWORD, handles: [*]const HANDLE, wait_all: BOOL, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;

pub const AudioVolume = struct {
    stop_event: HANDLE = null,
    write_event: HANDLE = null,
    thread: HANDLE = null,
    running: u8 = 0,
    lock: CriticalSection = std.mem.zeroes(CriticalSection),
    lock_ready: bool = false,
    level: f32 = 0,
    muted: bool = false,
    have_level: bool = false,
    revision: i32 = 0,
    peak_level: f32 = 0,
    have_peak: bool = false,
    pending_level: f32 = 0,
    pending_write: bool = false,
    pending_toggle_mute: bool = false,
    meter_device: ?*anyopaque = null,
    meter: ?*anyopaque = null,

    pub fn start(self: *AudioVolume) bool {
        if (@atomicLoad(u8, &self.running, .acquire) != 0) return true;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        self.write_event = CreateEventW(null, 0, 0, null);
        if (self.stop_event == null or self.write_event == null) {
            self.stop();
            return false;
        }
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            self.stop();
            return false;
        }

        var attempt: usize = 0;
        while (attempt < 400 and !self.available()) : (attempt += 1) Sleep(5);
        if (!self.available()) {
            self.stop();
            return false;
        }
        @atomicStore(u8, &self.running, 1, .release);
        return true;
    }

    pub fn stop(self: *AudioVolume) void {
        if (self.stop_event != null) _ = SetEvent(self.stop_event);
        if (self.thread) |thread| {
            _ = WaitForSingleObject(thread, 3000);
            _ = CloseHandle(thread);
            self.thread = null;
        }
        closeHandle(&self.stop_event);
        closeHandle(&self.write_event);
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
        @atomicStore(u8, &self.running, 0, .release);
    }

    pub fn available(self: *AudioVolume) bool {
        if (!self.lock_ready) return false;
        self.enter();
        defer self.leave();
        return self.have_level;
    }

    pub fn get(self: *AudioVolume, out_level: ?*f32) bool {
        const output = out_level orelse return false;
        if (!self.lock_ready) return false;
        self.enter();
        defer self.leave();
        if (!self.have_level) return false;
        output.* = self.level;
        return true;
    }

    pub fn isMuted(self: *AudioVolume) bool {
        if (!self.lock_ready) return false;
        self.enter();
        defer self.leave();
        return self.muted;
    }

    pub fn peak(self: *AudioVolume, out_level: ?*f32) bool {
        const output = out_level orelse return false;
        if (!self.lock_ready) return false;
        self.enter();
        defer self.leave();
        if (!self.have_peak) return false;
        output.* = self.peak_level;
        return true;
    }

    pub fn adjust(self: *AudioVolume, delta: f32) void {
        var current: f32 = 0;
        if (self.get(&current)) self.setLevel(current + delta);
    }

    pub fn setLevel(self: *AudioVolume, value: f32) void {
        if (!self.lock_ready) return;
        const wanted = clamp01(value);
        self.enter();
        self.level = wanted;
        self.have_level = true;
        self.pending_level = wanted;
        self.pending_write = true;
        self.leave();
        _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
        if (self.write_event != null) _ = SetEvent(self.write_event);
    }

    pub fn toggleMute(self: *AudioVolume) void {
        if (!self.lock_ready) return;
        self.enter();
        self.pending_toggle_mute = true;
        self.leave();
        if (self.write_event != null) _ = SetEvent(self.write_event);
    }

    pub fn getRevision(self: *AudioVolume) u64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.revision, .seq_cst)));
    }

    fn enter(self: *AudioVolume) void {
        EnterCriticalSection(&self.lock);
    }

    fn leave(self: *AudioVolume) void {
        LeaveCriticalSection(&self.lock);
    }

    fn readFromDevice(self: *AudioVolume) bool {
        const enumerator = createEnumerator() orelse return false;
        var device: ?*anyopaque = null;
        const enum_vtable = vtable(DeviceEnumeratorVTable, enumerator);
        const get_hr = enum_vtable.get_default_audio_endpoint(enumerator, eRender, eConsole, &device);
        release(enumerator);
        if (!succeeded(get_hr) or device == null) return false;
        defer release(device);

        const endpoint = activate(device, &IID_IAudioEndpointVolume) orelse return false;
        defer release(endpoint);
        const endpoint_vtable = vtable(EndpointVolumeVTable, endpoint);
        var new_level: f32 = 0;
        var new_muted: BOOL = 0;
        if (!succeeded(endpoint_vtable.get_master_volume_level_scalar(endpoint, &new_level)) or
            !succeeded(endpoint_vtable.get_mute(endpoint, &new_muted))) return false;

        self.enter();
        if (!self.pending_write) {
            self.level = clamp01(new_level);
            self.muted = new_muted != 0;
        }
        self.have_level = true;
        self.leave();
        return true;
    }

    fn readPeakFromDevice(self: *AudioVolume) bool {
        if (self.meter == null or self.meter_device == null) {
            self.releaseMeter();
            const enumerator = createEnumerator() orelse return false;
            var device: ?*anyopaque = null;
            const get_hr = vtable(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint(enumerator, eRender, eConsole, &device);
            release(enumerator);
            if (!succeeded(get_hr) or device == null) return false;
            const meter = activate(device, &IID_IAudioMeterInformation) orelse {
                release(device);
                return false;
            };
            self.meter_device = device;
            self.meter = meter;
        }

        var value: f32 = 0;
        if (!succeeded(vtable(MeterVTable, self.meter.?).get_peak_value(self.meter.?, &value))) return false;
        self.enter();
        self.peak_level = clamp01(value);
        self.have_peak = true;
        self.leave();
        return true;
    }

    fn run(self: *AudioVolume) void {
        const apartment_hr = CoInitializeEx(null, 0);
        const have_apartment = succeeded(apartment_hr) or apartment_hr == @as(HRESULT, @bitCast(@as(u32, 0x80010106)));
        var last_volume_read = GetTickCount64();
        if (have_apartment) _ = self.readFromDevice();

        while (true) {
            const waits = [_]HANDLE{ self.stop_event, self.write_event };
            const signalled = WaitForMultipleObjects(waits.len, &waits, 0, PEAK_INTERVAL_MS);
            if (signalled == WAIT_OBJECT_0 or signalled == WAIT_FAILED) break;
            if (!have_apartment) break;

            if (signalled == WAIT_OBJECT_0 + 1) self.applyPendingWrites();
            _ = self.readPeakFromDevice();
            const now = GetTickCount64();
            if (now - last_volume_read >= POLL_INTERVAL_MS) {
                last_volume_read = now;
                if (self.readFromDevice()) _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
            }
        }
        self.releaseMeter();
        if (have_apartment) CoUninitialize();
        @atomicStore(u8, &self.running, 0, .release);
    }

    fn applyPendingWrites(self: *AudioVolume) void {
        var wanted: f32 = 0;
        var do_write = false;
        var do_toggle_mute = false;
        self.enter();
        if (self.pending_write) {
            wanted = self.pending_level;
            self.pending_write = false;
            do_write = true;
        }
        if (self.pending_toggle_mute) {
            self.pending_toggle_mute = false;
            do_toggle_mute = true;
        }
        self.leave();
        if (!do_write and !do_toggle_mute) return;

        const enumerator = createEnumerator() orelse return;
        defer release(enumerator);
        var device: ?*anyopaque = null;
        if (!succeeded(vtable(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint(enumerator, eRender, eConsole, &device)) or device == null) return;
        defer release(device);
        const endpoint = activate(device, &IID_IAudioEndpointVolume) orelse return;
        defer release(endpoint);
        const endpoint_vtable = vtable(EndpointVolumeVTable, endpoint);
        if (do_write) _ = endpoint_vtable.set_master_volume_level_scalar(endpoint, wanted, null);
        if (do_toggle_mute) {
            var muted: BOOL = 0;
            if (succeeded(endpoint_vtable.get_mute(endpoint, &muted))) _ = endpoint_vtable.set_mute(endpoint, if (muted == 0) 1 else 0, null);
        }
    }

    fn releaseMeter(self: *AudioVolume) void {
        release(self.meter);
        release(self.meter_device);
        self.meter = null;
        self.meter_device = null;
    }
};

/// Samples the default render endpoint once without starting the volume worker.
/// This is used by the system-status snapshot, which must keep its own polling cadence.
pub fn readCurrentOutput(muted: *bool, percent: *i32) bool {
    const enumerator = createEnumerator() orelse return false;
    defer release(enumerator);

    var device: ?*anyopaque = null;
    const get_device = vtable(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint;
    if (!succeeded(get_device(enumerator, eRender, eConsole, &device)) or device == null) return false;
    defer release(device);

    const endpoint = activate(device, &IID_IAudioEndpointVolume) orelse return false;
    defer release(endpoint);
    const endpoint_vtable = vtable(EndpointVolumeVTable, endpoint);
    var raw_muted: BOOL = 0;
    var level: f32 = 0;
    if (!succeeded(endpoint_vtable.get_mute(endpoint, &raw_muted)) or
        !succeeded(endpoint_vtable.get_master_volume_level_scalar(endpoint, &level))) return false;
    muted.* = raw_muted != 0;
    percent.* = @intFromFloat(clamp01(level) * 100.0 + 0.5);
    return true;
}

fn threadEntry(parameter: ?*anyopaque) callconv(.winapi) DWORD {
    const self: *AudioVolume = @ptrCast(@alignCast(parameter orelse return 1));
    self.run();
    return 0;
}

fn createEnumerator() ?*anyopaque {
    var result: ?*anyopaque = null;
    if (!succeeded(CoCreateInstance(&CLSID_MMDeviceEnumerator, null, CLSCTX_ALL, &IID_IMMDeviceEnumerator, &result))) return null;
    return result;
}

fn activate(device: ?*anyopaque, iid: *const Guid) ?*anyopaque {
    const raw = device orelse return null;
    var result: ?*anyopaque = null;
    const hr = vtable(DeviceVTable, raw).activate(raw, iid, CLSCTX_ALL, null, &result);
    if (!succeeded(hr)) {
        release(result);
        return null;
    }
    return result;
}

fn vtable(comptime T: type, object: ?*anyopaque) *const T {
    const raw = object.?;
    const unknown: *const Unknown = @ptrCast(@alignCast(raw));
    return @ptrCast(@alignCast(unknown.vtable));
}

fn release(object: ?*anyopaque) void {
    if (object) |raw| {
        const unknown: *Unknown = @ptrCast(@alignCast(raw));
        _ = unknown.vtable.release(raw);
    }
}

fn closeHandle(handle: *HANDLE) void {
    if (handle.*) |raw| {
        if (@intFromPtr(raw) != INVALID_HANDLE_VALUE) _ = CloseHandle(raw);
        handle.* = null;
    }
}

fn succeeded(hr: HRESULT) bool {
    return hr >= 0;
}

fn clamp01(value: f32) f32 {
    return @max(0.0, @min(1.0, value));
}

pub fn smokeCheck() bool {
    if (clamp01(-1) != 0 or clamp01(0.35) != 0.35 or clamp01(2) != 1) return false;
    // Keep every public worker operation in the compilation path without opening an audio endpoint
    // as part of the application's ordinary deterministic smoke check.
    var volume = AudioVolume{};
    if (false) {
        _ = volume.start();
        volume.adjust(0.02);
        volume.setLevel(0.5);
        volume.toggleMute();
        _ = volume.available();
        _ = volume.get(null);
        _ = volume.isMuted();
        _ = volume.peak(null);
        _ = volume.getRevision();
        volume.stop();
    }
    return true;
}
