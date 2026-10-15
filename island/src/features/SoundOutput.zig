const std = @import("std");
const Log = @import("Log");
const MusicSession = @import("MusicSession");

pub const max_devices: usize = 8;
pub const max_sessions: usize = 10;
pub const icon_bytes: usize = 4096;
pub const icon_cache_entries: usize = 12;

const IconEntry = struct {
    pid: u32 = 0,
    revision: u64 = 0,
    size: usize = 0,
    bytes: [icon_bytes]u8 = @splat(0),
};

pub const SoundDeviceInfo = struct {
    name: [128]u16 = @splat(0),
    id: [256]u16 = @splat(0),
    form_factor: i32 = 0,
    is_default: bool = false,
};
pub const SoundSessionInfo = struct {
    name: [128]u16 = @splat(0),
    source: [260]u16 = @splat(0),
    pid: u32 = 0,
    volume: f32 = 1,
    active: bool = false,
    system: bool = false,
    has_icon: bool = false,
    icon_revision: u64 = 0,
    icon: [icon_bytes]u8 = @splat(0),
    icon_size: usize = 0,
};
pub const Snapshot = struct {
    devices: [max_devices]SoundDeviceInfo = @splat(.{}),
    device_count: usize = 0,
    default_device: ?usize = null,
    default_device_name: [128]u16 = @splat(0),
    sessions: [max_sessions]SoundSessionInfo = @splat(.{}),
    session_count: usize = 0,
    revision: u64 = 0,

    pub fn normalize(self: *Snapshot) void {
        self.device_count = @min(self.device_count, max_devices);
        self.session_count = @min(self.session_count, max_sessions);
        if (self.default_device) |index| if (index >= self.device_count) {
            self.default_device = null;
        };
        for (self.sessions[0..self.session_count]) |*session| session.volume = clamp01(session.volume);
    }

    pub fn sessionIndexForPid(self: *const Snapshot, pid: u32) ?usize {
        for (self.sessions[0..@min(self.session_count, max_sessions)], 0..) |session, index| {
            if (session.pid == pid) return index;
        }
        return null;
    }
};

const BOOL = i32;
const DWORD = u32;
const HANDLE = ?*anyopaque;
const HRESULT = i32;
const CLSCTX_ALL: DWORD = 23;
const e_render: i32 = 0;
const e_console: i32 = 0;
const device_state_active: DWORD = 1;
const stgm_read: DWORD = 0;
const process_query_limited_information: DWORD = 0x1000;
const wait_object_0: DWORD = 0;
const wait_timeout: DWORD = 258;
const wait_failed: DWORD = 0xFFFFFFFF;
const infinite: DWORD = 0xFFFFFFFF;
const rpc_e_changed_mode: HRESULT = -2147417850;

const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};
const PropertyKey = extern struct { fmtid: Guid, pid: u32 };
const PropValueUnion = extern union { pointer: ?[*:0]u16, unsigned: u32, padding: u64 };
const PropVariant = extern struct { vt: u16, reserved1: u16, reserved2: u16, reserved3: u16, value: PropValueUnion };

const QueryInterfaceFn = *const fn (*anyopaque, *const Guid, *?*anyopaque) callconv(.winapi) HRESULT;
const ReleaseFn = *const fn (*anyopaque) callconv(.winapi) u32;
const UnknownVTable = extern struct {
    query_interface: QueryInterfaceFn,
    add_ref: *const fn (*anyopaque) callconv(.winapi) u32,
    release: ReleaseFn,
};
const Unknown = extern struct { vtable: *const UnknownVTable };
const EnumEndpointsFn = *const fn (*anyopaque, i32, DWORD, *?*anyopaque) callconv(.winapi) HRESULT;
const DefaultEndpointFn = *const fn (*anyopaque, i32, i32, *?*anyopaque) callconv(.winapi) HRESULT;
const DeviceEnumeratorVTable = extern struct {
    unknown: UnknownVTable,
    enum_audio_endpoints: EnumEndpointsFn,
    get_default_audio_endpoint: DefaultEndpointFn,
    get_device: usize,
    register_endpoint_notification_callback: usize,
    unregister_endpoint_notification_callback: usize,
};
const DeviceCollectionVTable = extern struct {
    unknown: UnknownVTable,
    get_count: *const fn (*anyopaque, *u32) callconv(.winapi) HRESULT,
    item: *const fn (*anyopaque, u32, *?*anyopaque) callconv(.winapi) HRESULT,
};
const DeviceVTable = extern struct {
    unknown: UnknownVTable,
    activate: *const fn (*anyopaque, *const Guid, DWORD, ?*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT,
    open_property_store: *const fn (*anyopaque, DWORD, *?*anyopaque) callconv(.winapi) HRESULT,
    get_id: *const fn (*anyopaque, *?[*:0]u16) callconv(.winapi) HRESULT,
    get_state: usize,
};
const PropertyStoreVTable = extern struct {
    unknown: UnknownVTable,
    get_count: usize,
    get_at: usize,
    get_value: *const fn (*anyopaque, *const PropertyKey, *PropVariant) callconv(.winapi) HRESULT,
    set_value: usize,
    commit: usize,
};
const SessionManagerVTable = extern struct {
    unknown: UnknownVTable,
    get_audio_session_control: usize,
    get_simple_audio_volume: usize,
    get_session_enumerator: *const fn (*anyopaque, *?*anyopaque) callconv(.winapi) HRESULT,
    register_session_notification: usize,
    unregister_session_notification: usize,
    register_duck_notification: usize,
    unregister_duck_notification: usize,
};
const SessionEnumeratorVTable = extern struct {
    unknown: UnknownVTable,
    get_count: *const fn (*anyopaque, *i32) callconv(.winapi) HRESULT,
    get_session: *const fn (*anyopaque, i32, *?*anyopaque) callconv(.winapi) HRESULT,
};
const SessionControlVTable = extern struct {
    unknown: UnknownVTable,
    get_state: *const fn (*anyopaque, *i32) callconv(.winapi) HRESULT,
    get_display_name: *const fn (*anyopaque, *?[*:0]u16) callconv(.winapi) HRESULT,
    set_display_name: usize,
    get_icon_path: usize,
    set_icon_path: usize,
    get_grouping_param: usize,
    set_grouping_param: usize,
    register_notification: usize,
    unregister_notification: usize,
};
const SessionControl2VTable = extern struct {
    base: SessionControlVTable,
    get_session_identifier: usize,
    get_session_instance_identifier: usize,
    get_process_id: *const fn (*anyopaque, *DWORD) callconv(.winapi) HRESULT,
    is_system_sounds_session: usize,
    set_ducking_preference: usize,
};
const PolicyConfigVTable = extern struct {
    unknown: UnknownVTable,
    get_mix_format: usize,
    get_device_format: usize,
    reset_device_format: usize,
    set_device_format: usize,
    get_processing_period: usize,
    set_processing_period: usize,
    get_share_mode: usize,
    set_share_mode: usize,
    get_property_value: usize,
    set_property_value: usize,
    set_default_endpoint: *const fn (*anyopaque, [*:0]const u16, i32) callconv(.winapi) HRESULT,
    set_endpoint_visibility: usize,
};
const SimpleVolumeVTable = extern struct {
    unknown: UnknownVTable,
    set_master_volume: *const fn (*anyopaque, f32, ?*const Guid) callconv(.winapi) HRESULT,
    get_master_volume: *const fn (*anyopaque, *f32) callconv(.winapi) HRESULT,
    set_mute: *const fn (*anyopaque, BOOL, ?*const Guid) callconv(.winapi) HRESULT,
    get_mute: usize,
};

const clsid_mm_device_enumerator = Guid{ .data1 = 0xBCDE0395, .data2 = 0xE52F, .data3 = 0x467C, .data4 = .{ 0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E } };
const clsid_policy_config = Guid{ .data1 = 0x870AF99C, .data2 = 0x171D, .data3 = 0x4F9E, .data4 = .{ 0xAF, 0x0D, 0xE6, 0x3D, 0xF4, 0x0C, 0x2B, 0xC9 } };
const iid_policy_config10 = Guid{ .data1 = 0x294935CE, .data2 = 0xF637, .data3 = 0x4E7C, .data4 = .{ 0xA4, 0x1B, 0xAB, 0x25, 0x54, 0x60, 0xB8, 0x62 } };
const iid_mm_device_enumerator = Guid{ .data1 = 0xA95664D2, .data2 = 0x9614, .data3 = 0x4F35, .data4 = .{ 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6 } };
const iid_session_manager2 = Guid{ .data1 = 0x77AA99A0, .data2 = 0x1BD6, .data3 = 0x484F, .data4 = .{ 0x8B, 0xC7, 0x2C, 0x65, 0x4C, 0x9A, 0x9B, 0x6F } };
const iid_session_enumerator = Guid{ .data1 = 0xE2F5BB11, .data2 = 0x0570, .data3 = 0x40CA, .data4 = .{ 0xAC, 0xDD, 0x3A, 0xA0, 0x12, 0x77, 0xDE, 0xE8 } };
const iid_session_control2 = Guid{ .data1 = 0xBFB7FF88, .data2 = 0x7239, .data3 = 0x4FC9, .data4 = .{ 0x8F, 0xA2, 0x07, 0xC9, 0x50, 0xBE, 0x9C, 0x6D } };
const iid_simple_audio_volume = Guid{ .data1 = 0x87CE5498, .data2 = 0x68D6, .data3 = 0x44E5, .data4 = .{ 0x92, 0x15, 0x6D, 0xA4, 0x7E, 0xF8, 0x83, 0xD8 } };
const pkey_device_friendly_name = PropertyKey{ .fmtid = .{ .data1 = 0xA45C254E, .data2 = 0xDF1C, .data3 = 0x4EFD, .data4 = .{ 0x80, 0x20, 0x67, 0xD1, 0x46, 0xA8, 0x50, 0xE0 } }, .pid = 14 };
const pkey_endpoint_form_factor = PropertyKey{ .fmtid = .{ .data1 = 0x1DA5D803, .data2 = 0xD492, .data3 = 0x4EDD, .data4 = .{ 0x8C, 0x23, 0xE0, 0xC0, 0xFF, 0xEE, 0x7F, 0x0E } }, .pid = 0 };

extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, apartment: DWORD) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoCreateInstance(clsid: *const Guid, outer: ?*anyopaque, context: DWORD, iid: *const Guid, object: *?*anyopaque) callconv(.winapi) HRESULT;
extern "ole32" fn CoTaskMemFree(memory: ?*anyopaque) callconv(.winapi) void;
extern "ole32" fn PropVariantClear(value: *PropVariant) callconv(.winapi) HRESULT;
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn WaitForMultipleObjects(count: DWORD, handles: [*]const HANDLE, wait_all: BOOL, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, pid: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, length: *DWORD) callconv(.winapi) BOOL;

pub const SoundOutput = struct {
    stop_event: HANDLE = null,
    work_event: HANDLE = null,
    thread: HANDLE = null,
    running: u8 = 0,
    lock: CriticalSection = std.mem.zeroes(CriticalSection),
    lock_ready: bool = false,
    snapshot_value: Snapshot = .{},
    revision_value: i32 = 0,
    have_reading: bool = false,
    pending_pid: u32 = 0,
    pending_level: f32 = 0,
    pending_volume: bool = false,
    pending_device: [256]u16 = @splat(0),
    pending_default_device: bool = false,
    refresh_requested: bool = false,
    icons: [icon_cache_entries]IconEntry = @splat(.{}),
    icon_count: usize = 0,
    next_icon_revision: u64 = 1,

    pub fn start(self: *SoundOutput) bool {
        if (@atomicLoad(u8, &self.running, .acquire) != 0) return true;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        self.work_event = CreateEventW(null, 0, 0, null);
        if (self.stop_event == null or self.work_event == null) {
            self.stop();
            return false;
        }
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            self.stop();
            return false;
        }
        var i: usize = 0;
        while (i < 800 and !self.hasReading()) : (i += 1) Sleep(5);
        if (!self.hasReading()) {
            self.stop();
            return false;
        }
        @atomicStore(u8, &self.running, 1, .release);
        return true;
    }

    pub fn stop(self: *SoundOutput) void {
        if (self.stop_event) |event| _ = SetEvent(event);
        if (self.thread) |thread| {
            _ = WaitForSingleObject(thread, 3000);
            _ = CloseHandle(thread);
            self.thread = null;
        }
        closeHandle(&self.stop_event);
        closeHandle(&self.work_event);
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
        @atomicStore(u8, &self.running, 0, .release);
    }

    pub fn snapshot(self: *SoundOutput) Snapshot {
        if (!self.lock_ready) return .{};
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        return self.snapshot_value;
    }

    pub fn revision(self: *SoundOutput) u64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.revision_value, .acquire)));
    }

    pub fn refresh(self: *SoundOutput) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        self.refresh_requested = true;
        LeaveCriticalSection(&self.lock);
        if (self.work_event) |event| _ = SetEvent(event);
    }

    pub fn setSessionVolume(self: *SoundOutput, pid: u32, level: f32) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        self.pending_pid = pid;
        self.pending_level = clamp01(level);
        self.pending_volume = true;
        LeaveCriticalSection(&self.lock);
        if (self.work_event) |event| _ = SetEvent(event);
    }

    pub fn setDefaultDevice(self: *SoundOutput, device_id: []const u16) void {
        if (!self.lock_ready or device_id.len == 0) return;
        self.enter();
        self.pending_device = @splat(0);
        const source = cWide(device_id);
        const length = @min(source.len, self.pending_device.len - 1);
        @memcpy(self.pending_device[0..length], source[0..length]);
        self.pending_default_device = true;
        self.leave();
        if (self.work_event) |event| _ = SetEvent(event);
    }

    fn hasReading(self: *SoundOutput) bool {
        if (!self.lock_ready) return false;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        return self.have_reading;
    }

    fn run(self: *SoundOutput) void {
        const hr = CoInitializeEx(null, 0);
        const apartment = hr >= 0 or hr == rpc_e_changed_mode;
        if (apartment) self.readAll();
        while (true) {
            const stop_handle = self.stop_event orelse break;
            const work = self.work_event orelse break;
            const handles = [_]HANDLE{ stop_handle, work };
            const wait = WaitForMultipleObjects(handles.len, &handles, 0, 250);
            if (wait == wait_object_0 or wait == wait_failed) break;
            if (!apartment) break;
            var want_refresh = wait == wait_timeout;
            if (wait == wait_object_0 + 1) {
                self.enter();
                want_refresh = want_refresh or self.refresh_requested;
                self.refresh_requested = false;
                self.leave();
            }
            if (want_refresh) self.readAll();
            self.applyVolume();
        }
        if (apartment) CoUninitialize();
        @atomicStore(u8, &self.running, 0, .release);
    }

    fn readAll(self: *SoundOutput) void {
        var fresh = Snapshot{};
        const devices_ok = readDevices(&fresh);
        const sessions_ok = readSessions(self, &fresh);
        self.enter();
        fresh.revision = self.snapshot_value.revision +% 1;
        fresh.normalize();
        self.snapshot_value = fresh;
        self.have_reading = true;
        self.leave();
        _ = @atomicRmw(i32, &self.revision_value, .Add, 1, .release);
        if (devices_ok or sessions_ok) {
            var message: [128]u8 = undefined;
            const line = std.fmt.bufPrint(&message, "sound snapshot: {d} device(s), {d} session(s)", .{ fresh.device_count, fresh.session_count }) catch return;
            Log.logLine(line);
        }
    }

    fn applyVolume(self: *SoundOutput) void {
        self.enter();
        const do_write = self.pending_volume;
        const pid = self.pending_pid;
        const level = self.pending_level;
        const do_default = self.pending_default_device;
        const device_id = self.pending_device;
        self.pending_volume = false;
        self.pending_default_device = false;
        self.refresh_requested = false;
        self.leave();
        if (do_default) {
            const result = applyDefaultDevice(&device_id);
            var message: [96]u8 = undefined;
            const line = std.fmt.bufPrint(&message, "default audio device switch {s} (HRESULT 0x{x:0>8})", .{
                if (succeeded(result)) "succeeded" else "failed",
                @as(u32, @bitCast(result)),
            }) catch "default audio device switch failed";
            Log.logLine(line);
        }
        if (!do_write) return;

        const enumerator = createEnumerator() orelse return;
        defer release(enumerator);
        var device: ?*anyopaque = null;
        if (!succeeded(vt(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint(enumerator, e_render, e_console, &device))) return;
        defer release(device);
        var manager: ?*anyopaque = null;
        if (!succeeded(vt(DeviceVTable, device).activate(device.?, &iid_session_manager2, CLSCTX_ALL, null, &manager))) return;
        defer release(manager);
        var sessions: ?*anyopaque = null;
        if (!succeeded(vt(SessionManagerVTable, manager).get_session_enumerator(manager.?, &sessions))) return;
        defer release(sessions);
        var count: i32 = 0;
        if (!succeeded(vt(SessionEnumeratorVTable, sessions).get_count(sessions.?, &count))) return;
        var i: i32 = 0;
        while (i < count) : (i += 1) {
            var control: ?*anyopaque = null;
            if (!succeeded(vt(SessionEnumeratorVTable, sessions).get_session(sessions.?, i, &control))) continue;
            defer release(control);
            var control2: ?*anyopaque = null;
            if (!succeeded(queryInterface(control, &iid_session_control2, &control2))) continue;
            var session_pid: DWORD = 0;
            _ = vt(SessionControl2VTable, control2).get_process_id(control2.?, &session_pid);
            release(control2);
            if (session_pid != pid) continue;
            var volume: ?*anyopaque = null;
            if (!succeeded(queryInterface(control, &iid_simple_audio_volume, &volume))) continue;
            _ = vt(SimpleVolumeVTable, volume).set_master_volume(volume.?, level, null);
            release(volume);
            break;
        }
    }

    fn enter(self: *SoundOutput) void {
        EnterCriticalSection(&self.lock);
    }
    fn leave(self: *SoundOutput) void {
        LeaveCriticalSection(&self.lock);
    }
};

fn threadEntry(parameter: ?*anyopaque) callconv(.winapi) DWORD {
    const self: *SoundOutput = @ptrCast(@alignCast(parameter orelse return 1));
    self.run();
    return 0;
}

fn readDevices(out: *Snapshot) bool {
    const enumerator = createEnumerator() orelse return false;
    defer release(enumerator);
    var default_device: ?*anyopaque = null;
    var default_id: [256]u16 = @splat(0);
    if (succeeded(vt(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint(enumerator, e_render, e_console, &default_device))) {
        defer release(default_device);
        copyDeviceId(default_device, &default_id);
    }
    var collection: ?*anyopaque = null;
    if (!succeeded(vt(DeviceEnumeratorVTable, enumerator).enum_audio_endpoints(enumerator, e_render, device_state_active, &collection))) return false;
    defer release(collection);
    var count: u32 = 0;
    if (!succeeded(vt(DeviceCollectionVTable, collection).get_count(collection.?, &count))) return false;
    var i: u32 = 0;
    while (i < count and out.device_count < max_devices) : (i += 1) {
        var device: ?*anyopaque = null;
        if (!succeeded(vt(DeviceCollectionVTable, collection).item(collection.?, i, &device))) continue;
        defer release(device);
        var info = SoundDeviceInfo{};
        copyDeviceId(device, &info.id);
        info.is_default = default_id[0] != 0 and wideEql(&info.id, &default_id);
        var store: ?*anyopaque = null;
        if (succeeded(vt(DeviceVTable, device).open_property_store(device.?, stgm_read, &store))) {
            defer release(store);
            var value = std.mem.zeroes(PropVariant);
            if (succeeded(vt(PropertyStoreVTable, store).get_value(store.?, &pkey_device_friendly_name, &value))) {
                if (value.vt == 31) if (value.value.pointer) |name| copyWide(&info.name, name);
                _ = PropVariantClear(&value);
            }
            value = std.mem.zeroes(PropVariant);
            if (succeeded(vt(PropertyStoreVTable, store).get_value(store.?, &pkey_endpoint_form_factor, &value))) {
                if (value.vt == 19) info.form_factor = @intCast(value.value.unsigned);
                _ = PropVariantClear(&value);
            }
        }
        if (info.name[0] == 0) copyWideSlice(&info.name, "Output device");
        out.devices[out.device_count] = info;
        if (info.is_default) {
            out.default_device = out.device_count;
            shortName(&info.name, &out.default_device_name);
        }
        out.device_count += 1;
    }
    if (out.default_device == null and out.device_count > 0) {
        out.default_device = 0;
        out.devices[0].is_default = true;
        shortName(&out.devices[0].name, &out.default_device_name);
    }
    return out.device_count > 0;
}

fn readSessions(self: *SoundOutput, out: *Snapshot) bool {
    const enumerator = createEnumerator() orelse return false;
    defer release(enumerator);
    var device: ?*anyopaque = null;
    if (!succeeded(vt(DeviceEnumeratorVTable, enumerator).get_default_audio_endpoint(enumerator, e_render, e_console, &device))) return false;
    defer release(device);
    var manager: ?*anyopaque = null;
    if (!succeeded(vt(DeviceVTable, device).activate(device.?, &iid_session_manager2, CLSCTX_ALL, null, &manager))) return false;
    defer release(manager);
    var sessions: ?*anyopaque = null;
    if (!succeeded(vt(SessionManagerVTable, manager).get_session_enumerator(manager.?, &sessions))) return false;
    defer release(sessions);
    var count: i32 = 0;
    if (!succeeded(vt(SessionEnumeratorVTable, sessions).get_count(sessions.?, &count))) return false;
    var i: i32 = 0;
    while (i < count and out.session_count < max_sessions) : (i += 1) {
        var control: ?*anyopaque = null;
        if (!succeeded(vt(SessionEnumeratorVTable, sessions).get_session(sessions.?, i, &control))) continue;
        defer release(control);
        var state: i32 = 2;
        if (!succeeded(vt(SessionControlVTable, control).get_state(control.?, &state)) or state == 2) continue;
        var info = SoundSessionInfo{ .active = state == 0 };
        var control2: ?*anyopaque = null;
        if (succeeded(queryInterface(control, &iid_session_control2, &control2))) {
            _ = vt(SessionControl2VTable, control2).get_process_id(control2.?, &info.pid);
            release(control2);
        }
        info.system = info.pid == 0;
        var volume: ?*anyopaque = null;
        if (succeeded(queryInterface(control, &iid_simple_audio_volume, &volume))) {
            _ = vt(SimpleVolumeVTable, volume).get_master_volume(volume.?, &info.volume);
            release(volume);
        }
        if (info.system) {
            copyWideSlice(&info.name, "System sounds");
        } else {
            var executable: [260]u16 = @splat(0);
            processName(info.pid, &info.name, &executable);
            var written: usize = 0;
            var icon_revision: u64 = 0;
            if (iconForPid(self, info.pid, cWide(&executable), &info.icon, &written, &icon_revision)) {
                info.has_icon = true;
                info.icon_size = written;
                info.icon_revision = icon_revision;
                info.source = executable;
            }
        }
        out.sessions[out.session_count] = info;
        out.session_count += 1;
    }
    var index: usize = 0;
    while (index < out.session_count) : (index += 1) {
        if (!out.sessions[index].system) continue;
        const last = out.session_count - 1;
        const system_session = out.sessions[index];
        var j = index;
        while (j < last) : (j += 1) out.sessions[j] = out.sessions[j + 1];
        out.sessions[last] = system_session;
        break;
    }
    return true;
}

/// Icons are decoded on the audio worker, then copied into the immutable
/// snapshot. The renderer can keep its uploaded bitmap by comparing revisions.
fn iconForPid(self: *SoundOutput, pid: u32, executable: []const u16, output: []u8, written: *usize, revision: *u64) bool {
    if (pid == 0 or output.len < icon_bytes) return false;
    for (self.icons[0..self.icon_count]) |*entry| {
        if (entry.pid != pid) continue;
        @memcpy(output[0..entry.size], entry.bytes[0..entry.size]);
        written.* = entry.size;
        revision.* = entry.revision;
        return entry.size > 0;
    }
    if (executable.len == 0 or executable[0] == 0 or self.icon_count >= self.icons.len) return false;

    var entry = &self.icons[self.icon_count];
    entry.pid = pid;
    entry.revision = self.next_icon_revision;
    self.next_icon_revision +%= 1;
    entry.size = MusicSession.fetchAppIconForTest(executable, &entry.bytes);
    // Preserve the original cache growth rule: its last slot is a replacement
    // slot once the cache reaches its configured limit.
    if (self.icon_count + 1 < icon_cache_entries) self.icon_count += 1;
    if (entry.size == 0) return false;
    @memcpy(output[0..entry.size], entry.bytes[0..entry.size]);
    written.* = entry.size;
    revision.* = entry.revision;
    return true;
}

fn applyDefaultDevice(device: *const [256]u16) HRESULT {
    if (device[0] == 0) return -2147467259;
    var policy: ?*anyopaque = null;
    const created = CoCreateInstance(&clsid_policy_config, null, CLSCTX_ALL, &iid_policy_config10, &policy);
    if (!succeeded(created) or policy == null) return created;
    defer release(policy);
    const device_id: [*:0]const u16 = @ptrCast(device);
    const roles = [_]i32{ 0, 1, 2 }; // eConsole, eMultimedia, eCommunications
    var result: HRESULT = 0;
    for (roles) |role| {
        result = vt(PolicyConfigVTable, policy).set_default_endpoint(policy.?, device_id, role);
        if (!succeeded(result)) break;
    }
    return result;
}

fn createEnumerator() ?*anyopaque {
    var result: ?*anyopaque = null;
    if (!succeeded(CoCreateInstance(&clsid_mm_device_enumerator, null, CLSCTX_ALL, &iid_mm_device_enumerator, &result))) return null;
    return result;
}

fn vt(comptime T: type, object: ?*anyopaque) *const T {
    const raw = object.?;
    const unknown: *const Unknown = @ptrCast(@alignCast(raw));
    return @ptrCast(@alignCast(unknown.vtable));
}

fn queryInterface(object: ?*anyopaque, iid: *const Guid, output: *?*anyopaque) HRESULT {
    const raw = object orelse return -2147467259;
    return vt(UnknownVTable, raw).query_interface(raw, iid, output);
}

fn release(object: ?*anyopaque) void {
    if (object) |raw| _ = vt(UnknownVTable, raw).release(raw);
}

fn closeHandle(handle: *HANDLE) void {
    if (handle.*) |raw| {
        _ = CloseHandle(raw);
        handle.* = null;
    }
}

fn succeeded(hr: HRESULT) bool {
    return hr >= 0;
}

fn copyWide(destination: anytype, source: [*:0]const u16) void {
    const dest = destination[0..];
    var i: usize = 0;
    while (i + 1 < dest.len and source[i] != 0) : (i += 1) dest[i] = source[i];
    dest[i] = 0;
}

fn copyWideSlice(destination: anytype, source: []const u8) void {
    const dest = destination[0..];
    const n = @min(source.len, dest.len - 1);
    for (source[0..n], 0..) |ch, i| dest[i] = ch;
    dest[n] = 0;
}

fn cWide(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn copyDeviceId(device: ?*anyopaque, output: *[256]u16) void {
    var id: ?[*:0]u16 = null;
    if (!succeeded(vt(DeviceVTable, device).get_id(device.?, &id))) return;
    if (id) |value| {
        copyWide(output, value);
        CoTaskMemFree(value);
    }
}

fn wideEql(a: anytype, b: anytype) bool {
    for (a, b) |x, y| if (x != y) return false;
    return true;
}

fn shortName(friendly: *const [128]u16, output: *[128]u16) void {
    var length: usize = 0;
    while (length < friendly.len and friendly[length] != 0 and friendly[length] != '(') : (length += 1) {}
    while (length > 0 and friendly[length - 1] == ' ') : (length -= 1) {}
    if (length == 0) {
        copyWide(output, @ptrCast(friendly));
        return;
    }
    @memcpy(output[0..length], friendly[0..length]);
    output[length] = 0;
}

fn processName(pid: u32, name: *[128]u16, source: *[260]u16) void {
    const process = OpenProcess(process_query_limited_information, 0, pid) orelse {
        copyWideSlice(name, "Application");
        return;
    };
    defer _ = CloseHandle(process);
    var length: DWORD = 260;
    if (QueryFullProcessImageNameW(process, 0, source, &length) == 0) {
        copyWideSlice(name, "Application");
        return;
    }
    var start: usize = 0;
    for (source[0..length], 0..) |c, i| if (c == '\\' or c == '/') {
        start = i + 1;
    };
    const take = @min(length - start, name.len - 1);
    @memcpy(name[0..take], source[start .. start + take]);
    name[take] = 0;
}

pub fn clamp01(value: f32) f32 {
    return @max(0, @min(1, value));
}

pub fn smokeCheck() bool {
    var snapshot = Snapshot{};
    snapshot.device_count = max_devices + 1;
    snapshot.session_count = 1;
    snapshot.sessions[0].pid = 42;
    snapshot.sessions[0].volume = 2;
    snapshot.normalize();
    var service = SoundOutput{};
    if (false) {
        _ = service.start();
        service.stop();
        _ = service.snapshot();
        _ = service.revision();
        service.refresh();
        service.setSessionVolume(42, 0.5);
        service.setDefaultDevice(&.{ 'd', 'e', 'v', 'i', 'c', 'e', 0 });
    }
    return snapshot.device_count == max_devices and snapshot.session_count == 1 and
        snapshot.sessionIndexForPid(42) == 0 and snapshot.sessions[0].volume == 1 and
        snapshot.sessionIndexForPid(99) == null;
}
