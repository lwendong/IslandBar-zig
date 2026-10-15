const std = @import("std");
const ShellCommand = @import("ShellCommand");

pub const NightLightState = enum { unknown, off, on };

const HANDLE = ?*anyopaque;
const DWORD = u32;
const process_snapshot: DWORD = 2;
const invalid_handle: usize = std.math.maxInt(usize);
const max_name = 260;

const ProcessEntry32W = extern struct {
    size: DWORD,
    usage: DWORD,
    process_id: DWORD,
    default_heap_id: usize,
    module_id: DWORD,
    threads: DWORD,
    parent_process_id: DWORD,
    base_priority: i32,
    flags: DWORD,
    exe_file: [max_name]u16,
};
const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const LPARAM = isize;
const BOOL = i32;
const HRESULT = i32;
const VariantData = extern union { bstr: ?[*:0]u16, raw: [2]u64 };
const Variant = extern struct { vt: u16, reserved: [3]u16, data: VariantData };
const FrameList = struct { items: [128]HANDLE = @splat(null), count: usize = 0 };

extern "kernel32" fn CreateToolhelp32Snapshot(flags: DWORD, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Process32FirstW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) i32;
extern "kernel32" fn Process32NextW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetModuleHandleW(name: [*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn GetProcAddress(module: HANDLE, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "advapi32" fn RegOpenKeyExW(key: HANDLE, subkey: [*:0]const u16, options: DWORD, access: DWORD, result: *HANDLE) callconv(.winapi) i32;
extern "advapi32" fn RegQueryValueExW(key: HANDLE, value: [*:0]const u16, reserved: ?*DWORD, value_type: *DWORD, data: [*]u8, data_size: *DWORD) callconv(.winapi) i32;
extern "advapi32" fn RegCloseKey(key: HANDLE) callconv(.winapi) i32;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, apartment: DWORD) callconv(.winapi) HRESULT;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CoCreateInstance(class_id: *const Guid, outer: HANDLE, context: DWORD, iid: *const Guid, object: *HANDLE) callconv(.winapi) HRESULT;
extern "oleaut32" fn SysAllocString(value: [*:0]const u16) callconv(.winapi) ?[*:0]u16;
extern "oleaut32" fn SysFreeString(value: ?[*:0]u16) callconv(.winapi) void;
extern "user32" fn EnumWindows(callback: *const fn (HANDLE, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn GetClassNameW(window: HANDLE, class_name: [*]u16, max_count: i32) callconv(.winapi) i32;
extern "user32" fn IsWindowVisible(window: HANDLE) callconv(.winapi) BOOL;
extern "user32" fn PostMessageW(window: HANDLE, message: u32, wparam: usize, lparam: isize) callconv(.winapi) BOOL;
extern "shell32" fn ShellExecuteW(window: HANDLE, operation: ?[*:0]const u16, file: [*:0]const u16, parameters: ?[*:0]const u16, directory: ?[*:0]const u16, show_command: i32) callconv(.winapi) HANDLE;

const hkey_current_user: HANDLE = @ptrFromInt(0x80000001);
const key_read: DWORD = 0x00020019;
const reg_binary: DWORD = 3;
const error_success: i32 = 0;
const night_light_key: [*:0]const u16 = &.{ 'S', 'o', 'f', 't', 'w', 'a', 'r', 'e', '\\', 'M', 'i', 'c', 'r', 'o', 's', 'o', 'f', 't', '\\', 'W', 'i', 'n', 'd', 'o', 'w', 's', '\\', 'C', 'u', 'r', 'r', 'e', 'n', 't', 'V', 'e', 'r', 's', 'i', 'o', 'n', '\\', 'C', 'l', 'o', 'u', 'd', 'S', 't', 'o', 'r', 'e', '\\', 'S', 't', 'o', 'r', 'e', '\\', 'D', 'e', 'f', 'a', 'u', 'l', 't', 'A', 'c', 'c', 'o', 'u', 'n', 't', '\\', 'C', 'u', 'r', 'r', 'e', 'n', 't', '\\', 'd', 'e', 'f', 'a', 'u', 'l', 't', '$', 'w', 'i', 'n', 'd', 'o', 'w', 's', '.', 'd', 'a', 't', 'a', '.', 'b', 'l', 'u', 'e', 'l', 'i', 'g', 'h', 't', 'r', 'e', 'd', 'u', 'c', 't', 'i', 'o', 'n', '.', 'b', 'l', 'u', 'e', 'l', 'i', 'g', 'h', 't', 'r', 'e', 'd', 'u', 'c', 't', 'i', 'o', 'n', 's', 't', 'a', 't', 'e', '\\', 'w', 'i', 'n', 'd', 'o', 'w', 's', '.', 'd', 'a', 't', 'a', '.', 'b', 'l', 'u', 'e', 'l', 'i', 'g', 'h', 't', 'r', 'e', 'd', 'u', 'c', 't', 'i', 'o', 'n', '.', 'b', 'l', 'u', 'e', 'l', 'i', 'g', 'h', 't', 'r', 'e', 'd', 'u', 'c', 't', 'i', 'o', 'n', 's', 't', 'a', 't', 'e', 0 };
const night_light_value: [*:0]const u16 = &.{ 'D', 'a', 't', 'a', 0 };

const clsid_ui_automation = Guid{ .data1 = 0xff48dba4, .data2 = 0x60ef, .data3 = 0x4201, .data4 = .{ 0xaa, 0x87, 0x54, 0x10, 0x3e, 0xef, 0x59, 0x4e } };
const iid_ui_automation = Guid{ .data1 = 0x30cbe57d, .data2 = 0xd9d0, .data3 = 0x452a, .data4 = .{ 0xab, 0x13, 0x7a, 0xc5, 0xac, 0x48, 0x25, 0xee } };
const iid_ui_automation_invoke = Guid{ .data1 = 0xfb377fbe, .data2 = 0x8ea6, .data3 = 0x46d5, .data4 = .{ 0x9c, 0x73, 0x64, 0x99, 0x64, 0x2d, 0x30, 0x59 } };
const iid_radio_statics = Guid{ .data1 = 0x5fb6a12e, .data2 = 0x67cb, .data3 = 0x46ae, .data4 = .{ 0xaa, 0xe9, 0x65, 0x91, 0x9f, 0x86, 0xef, 0xf4 } };
const iid_radio = Guid{ .data1 = 0x252118df, .data2 = 0xb33e, .data3 = 0x416a, .data4 = .{ 0x87, 0x5f, 0x1c, 0xf3, 0x8a, 0xe2, 0xd8, 0x3e } };
const clsctx_inproc_server: DWORD = 1;
const coinit_apartment_threaded: DWORD = 2;
const ro_init_multithreaded: u32 = 1;
const tree_scope_descendants: i32 = 4;
const uia_automation_id_property_id: i32 = 30011;
const uia_invoke_pattern_id: i32 = 10000;
const variant_bstr: u16 = 8;
const wm_close: u32 = 0x0010;
const sw_shownormal: i32 = 1;
const radio_kind_wifi: i32 = 1;
const radio_kind_bluetooth: i32 = 3;
const radio_state_on: i32 = 1;
const radio_state_off: i32 = 2;
const radio_access_allowed: i32 = 1;
const async_status_started: i32 = 0;
const async_status_completed: i32 = 1;
const async_status_canceled: i32 = 2;
const async_status_error: i32 = 3;

const JobKind = enum { none, radios, night_light };
const JobResult = struct {
    finished: bool = false,
    kind: JobKind = .none,
    wanted: bool = false,
    wifi_requested: bool = false,
    bluetooth_requested: bool = false,
    succeeded: bool = false,
    hresult: i32 = 0,
    wifi_now: bool = false,
    bluetooth_now: bool = false,
    state_after: bool = false,
};
pub const RadioOutcome = struct {
    wifi_now: bool,
    bluetooth_now: bool,
    wifi_asked: bool,
    bluetooth_asked: bool,
    succeeded: bool,
    hresult: i32,
};
pub const NightLightOutcome = struct { wanted: bool, state_after: bool, succeeded: bool };

var job_mutex: std.atomic.Mutex = .unlocked;
var job_busy = false;
var job_result: JobResult = .{};
var worker_thread: ?std.Thread = null;
var have_night_light_page_state = false;
var night_light_page_state = false;

fn lockJobs() void {
    while (!job_mutex.tryLock()) std.atomic.spinLoopHint();
}

fn comCall(comptime Function: type, object: HANDLE, slot: usize, args: anytype) @typeInfo(@typeInfo(Function).pointer.child).@"fn".return_type.? {
    const self = object orelse unreachable;
    const vtable_pointer = @as(*const ?*const anyopaque, @ptrCast(@alignCast(self))).* orelse unreachable;
    const vtable: [*]const *const anyopaque = @ptrCast(@alignCast(vtable_pointer));
    const function: Function = @ptrCast(@alignCast(vtable[slot]));
    return @call(.auto, function, .{self} ++ args);
}

fn comRelease(object: HANDLE) void {
    if (object) |value| _ = comCall(*const fn (*anyopaque) callconv(.winapi) u32, value, 2, .{});
}

fn claimJob(kind: JobKind) bool {
    var previous: ?std.Thread = null;
    lockJobs();
    if (job_busy) {
        job_mutex.unlock();
        return false;
    }
    previous = worker_thread;
    worker_thread = null;
    job_mutex.unlock();
    if (previous) |thread| thread.join();

    lockJobs();
    if (job_busy) {
        job_mutex.unlock();
        return false;
    }
    job_result = .{ .kind = kind };
    job_busy = true;
    job_mutex.unlock();
    return true;
}

fn publishJob(result: JobResult) void {
    lockJobs();
    job_result = result;
    job_result.finished = true;
    job_busy = false;
    job_mutex.unlock();
}

fn launchRadioJob(wifi: bool, bluetooth: bool, on: bool) bool {
    if ((!wifi and !bluetooth) or !claimJob(.radios)) return false;
    const thread = std.Thread.spawn(.{}, runRadioJob, .{ wifi, bluetooth, on }) catch {
        lockJobs();
        job_result = .{};
        job_busy = false;
        job_mutex.unlock();
        return false;
    };
    lockJobs();
    worker_thread = thread;
    job_mutex.unlock();
    return true;
}

fn launchNightLightJob(on: bool) bool {
    if (!claimJob(.night_light)) return false;
    const thread = std.Thread.spawn(.{}, runNightLightJob, .{on}) catch {
        lockJobs();
        job_result = .{};
        job_busy = false;
        job_mutex.unlock();
        return false;
    };
    lockJobs();
    worker_thread = thread;
    job_mutex.unlock();
    return true;
}

const WinRtApi = struct {
    module: HANDLE,
    initialize: *const fn (u32) callconv(.winapi) HRESULT,
    uninitialize: *const fn () callconv(.winapi) void,
    create_string: *const fn ([*]const u16, u32, *HANDLE) callconv(.winapi) HRESULT,
    delete_string: *const fn (HANDLE) callconv(.winapi) HRESULT,
    get_activation_factory: *const fn (HANDLE, *const Guid, *HANDLE) callconv(.winapi) HRESULT,

    fn load() ?WinRtApi {
        const library_name: [*:0]const u16 = &.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 };
        const module = GetModuleHandleW(library_name) orelse LoadLibraryW(library_name) orelse return null;
        const initialize = GetProcAddress(module, "RoInitialize") orelse return null;
        const uninitialize = GetProcAddress(module, "RoUninitialize") orelse return null;
        const create_string = GetProcAddress(module, "WindowsCreateString") orelse return null;
        const delete_string = GetProcAddress(module, "WindowsDeleteString") orelse return null;
        const get_activation_factory = GetProcAddress(module, "RoGetActivationFactory") orelse return null;
        return .{
            .module = module,
            .initialize = @ptrCast(initialize),
            .uninitialize = @ptrCast(uninitialize),
            .create_string = @ptrCast(create_string),
            .delete_string = @ptrCast(delete_string),
            .get_activation_factory = @ptrCast(get_activation_factory),
        };
    }

    fn createRadioFactory(self: *const WinRtApi, error_code: *i32) HANDLE {
        error_code.* = 0;
        const class_name = "Windows.Devices.Radios.Radio";
        var wide: [class_name.len]u16 = undefined;
        for (class_name, 0..) |byte, index| wide[index] = byte;
        var name: HANDLE = null;
        const string_result = self.create_string(&wide, wide.len, &name);
        if (string_result < 0) {
            error_code.* = string_result;
            return null;
        }
        defer _ = self.delete_string(name);
        var factory: HANDLE = null;
        const factory_result = self.get_activation_factory(name, &iid_radio_statics, &factory);
        if (factory_result < 0) {
            error_code.* = factory_result;
            return null;
        }
        return factory;
    }
};

fn asyncInfoStatus(operation: HANDLE, error_code: *i32) ?i32 {
    var status: i32 = async_status_started;
    const hr = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, operation, 7, .{&status});
    if (hr < 0) {
        error_code.* = hr;
        return null;
    }
    return status;
}

fn awaitAsyncInt(operation: HANDLE, error_code: *i32) ?i32 {
    error_code.* = 0;
    var attempt: usize = 0;
    while (attempt < 600) : (attempt += 1) {
        const status = asyncInfoStatus(operation, error_code) orelse return null;
        if (status == async_status_completed) {
            var value: i32 = 0;
            const hr = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, operation, 13, .{&value});
            if (hr < 0) {
                error_code.* = hr;
                return null;
            }
            return value;
        }
        if (status == async_status_error) {
            _ = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, operation, 8, .{error_code});
            return null;
        }
        if (status == async_status_canceled) {
            error_code.* = -2147023673; // HRESULT_FROM_WIN32(ERROR_CANCELLED)
            return null;
        }
        Sleep(50);
    }
    _ = comCall(*const fn (*anyopaque) callconv(.winapi) HRESULT, operation, 9, .{});
    error_code.* = -2147023436; // HRESULT_FROM_WIN32(ERROR_TIMEOUT)
    return null;
}

fn awaitAsyncInterface(operation: HANDLE, error_code: *i32) HANDLE {
    error_code.* = 0;
    var attempt: usize = 0;
    while (attempt < 600) : (attempt += 1) {
        const status = asyncInfoStatus(operation, error_code) orelse return null;
        if (status == async_status_completed) {
            var value: HANDLE = null;
            const hr = comCall(*const fn (*anyopaque, *HANDLE) callconv(.winapi) HRESULT, operation, 13, .{&value});
            if (hr < 0) {
                error_code.* = hr;
                return null;
            }
            return value;
        }
        if (status == async_status_error) {
            _ = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, operation, 8, .{error_code});
            return null;
        }
        if (status == async_status_canceled) {
            error_code.* = -2147023673;
            return null;
        }
        Sleep(50);
    }
    _ = comCall(*const fn (*anyopaque) callconv(.winapi) HRESULT, operation, 9, .{});
    error_code.* = -2147023436;
    return null;
}

fn runRadioJob(wifi: bool, bluetooth: bool, on: bool) void {
    var result = JobResult{
        .kind = .radios,
        .wanted = on,
        .wifi_requested = wifi,
        .bluetooth_requested = bluetooth,
    };
    const api = WinRtApi.load() orelse {
        result.hresult = -2147467259;
        publishJob(result);
        return;
    };
    const init_result = api.initialize(ro_init_multithreaded);
    if (init_result < 0) {
        result.hresult = init_result;
        publishJob(result);
        return;
    }
    defer api.uninitialize();

    var factory_error: i32 = 0;
    const factory = api.createRadioFactory(&factory_error);
    if (factory == null) {
        result.hresult = factory_error;
        publishJob(result);
        return;
    }
    defer comRelease(factory);

    var access_operation: HANDLE = null;
    const access_call = comCall(*const fn (*anyopaque, *HANDLE) callconv(.winapi) HRESULT, factory, 9, .{&access_operation});
    if (access_call < 0 or access_operation == null) {
        result.hresult = access_call;
        publishJob(result);
        return;
    }
    defer comRelease(access_operation);
    var async_error: i32 = 0;
    const access = awaitAsyncInt(access_operation, &async_error) orelse {
        result.hresult = async_error;
        publishJob(result);
        return;
    };
    if (access != radio_access_allowed) {
        result.hresult = access;
        publishJob(result);
        return;
    }

    var radios_operation: HANDLE = null;
    const radios_call = comCall(*const fn (*anyopaque, *HANDLE) callconv(.winapi) HRESULT, factory, 6, .{&radios_operation});
    if (radios_call < 0 or radios_operation == null) {
        result.hresult = radios_call;
        publishJob(result);
        return;
    }
    defer comRelease(radios_operation);
    const radios = awaitAsyncInterface(radios_operation, &async_error) orelse {
        result.hresult = async_error;
        publishJob(result);
        return;
    };
    defer comRelease(radios);

    var count: u32 = 0;
    if (comCall(*const fn (*anyopaque, *u32) callconv(.winapi) HRESULT, radios, 8, .{&count}) < 0) {
        publishJob(result);
        return;
    }
    var requested = false;
    var all_writes_allowed = true;
    var index: u32 = 0;
    while (index < count) : (index += 1) {
        var radio: HANDLE = null;
        if (comCall(*const fn (*anyopaque, u32, *HANDLE) callconv(.winapi) HRESULT, radios, 7, .{ index, &radio }) < 0 or radio == null) continue;
        defer comRelease(radio);
        var kind: i32 = 0;
        const kind_result = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, radio, 11, .{&kind});
        if (kind_result < 0) {
            if (result.hresult == 0) result.hresult = kind_result;
            continue;
        }
        const is_wifi = kind == radio_kind_wifi;
        const is_bluetooth = kind == radio_kind_bluetooth;
        if (!((is_wifi and wifi) or (is_bluetooth and bluetooth))) continue;
        requested = true;

        var operation: HANDLE = null;
        const set_call = comCall(*const fn (*anyopaque, i32, *HANDLE) callconv(.winapi) HRESULT, radio, 6, .{ if (on) radio_state_on else radio_state_off, &operation });
        var access_after: ?i32 = null;
        if (set_call >= 0 and operation != null) {
            defer comRelease(operation);
            access_after = awaitAsyncInt(operation, &async_error);
            if (access_after == null and result.hresult == 0) result.hresult = async_error;
        } else if (result.hresult == 0) {
            result.hresult = set_call;
        }

        var state: i32 = 0;
        const state_ok = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) HRESULT, radio, 9, .{&state}) >= 0;
        const now = state_ok and state == radio_state_on;
        if (is_wifi) result.wifi_now = now else result.bluetooth_now = now;
        if (access_after != radio_access_allowed) all_writes_allowed = false;
    }
    if (requested) {
        result.succeeded = all_writes_allowed;
        if (wifi and result.wifi_now != on) result.succeeded = false;
        if (bluetooth and result.bluetooth_now != on) result.succeeded = false;
    }
    publishJob(result);
}

const night_light_on_id: [*:0]const u16 = &.{ 'S', 'y', 's', 't', 'e', 'm', 'S', 'e', 't', 't', 'i', 'n', 'g', 's', '_', 'D', 'i', 's', 'p', 'l', 'a', 'y', '_', 'B', 'l', 'u', 'e', 'L', 'i', 'g', 'h', 't', '_', 'M', 'a', 'n', 'u', 'a', 'l', 'T', 'o', 'g', 'g', 'l', 'e', 'O', 'n', '_', 'B', 'u', 't', 't', 'o', 'n', 0 };
const night_light_off_id: [*:0]const u16 = &.{ 'S', 'y', 's', 't', 'e', 'm', 'S', 'e', 't', 't', 'i', 'n', 'g', 's', '_', 'D', 'i', 's', 'p', 'l', 'a', 'y', '_', 'B', 'l', 'u', 'e', 'L', 'i', 'g', 'h', 't', '_', 'M', 'a', 'n', 'u', 'a', 'l', 'T', 'o', 'g', 'g', 'l', 'e', 'O', 'f', 'f', '_', 'B', 'u', 't', 't', 'o', 'n', 0 };
const settings_night_light_uri: [*:0]const u16 = &.{ 'm', 's', '-', 's', 'e', 't', 't', 'i', 'n', 'g', 's', ':', 'n', 'i', 'g', 'h', 't', 'l', 'i', 'g', 'h', 't', 0 };

fn enumSettingsFrames(window: HANDLE, parameter: LPARAM) callconv(.winapi) BOOL {
    const frames: *FrameList = @ptrFromInt(@as(usize, @bitCast(parameter)));
    var class_name: [64]u16 = @splat(0);
    const length = GetClassNameW(window, &class_name, class_name.len);
    if (length > 0 and wideAsciiEqlIgnoreCase(class_name[0..@intCast(length)], "ApplicationFrameWindow") and frames.count < frames.items.len) {
        frames.items[frames.count] = window;
        frames.count += 1;
    }
    return 1;
}

fn collectSettingsFrames(frames: *FrameList) void {
    frames.count = 0;
    _ = EnumWindows(enumSettingsFrames, @bitCast(@intFromPtr(frames)));
}

fn wasThereBefore(frames: *const FrameList, window: HANDLE) bool {
    for (frames.items[0..frames.count]) |old| if (old == window) return true;
    return false;
}

fn createPropertyCondition(automation: HANDLE, property_id: i32, value: [*:0]const u16) HANDLE {
    const bstr = SysAllocString(value) orelse return null;
    defer SysFreeString(bstr);
    const variant = Variant{ .vt = variant_bstr, .reserved = .{ 0, 0, 0 }, .data = .{ .bstr = bstr } };
    var condition: HANDLE = null;
    if (comCall(*const fn (*anyopaque, i32, Variant, *HANDLE) callconv(.winapi) HRESULT, automation, 23, .{ property_id, variant, &condition }) < 0) return null;
    return condition;
}

fn findNightLightSwitch(automation: HANDLE, window: HANDLE, currently_on: *bool) HANDLE {
    const ids = [_][*:0]const u16{ night_light_on_id, night_light_off_id };
    for (ids, 0..) |id, index| {
        const condition = createPropertyCondition(automation, uia_automation_id_property_id, id) orelse continue;
        defer comRelease(condition);
        var element: HANDLE = null;
        if (comCall(*const fn (*anyopaque, i32, HANDLE, *HANDLE) callconv(.winapi) HRESULT, window, 5, .{ tree_scope_descendants, condition, &element }) >= 0 and element != null) {
            // The button that turns the feature ON is published while night light is OFF.
            currently_on.* = index == 1;
            return element;
        }
    }
    return null;
}

fn invokeElement(element: HANDLE) bool {
    var invoke: HANDLE = null;
    if (comCall(*const fn (*anyopaque, i32, *const Guid, *HANDLE) callconv(.winapi) HRESULT, element, 14, .{ uia_invoke_pattern_id, &iid_ui_automation_invoke, &invoke }) < 0 or invoke == null) return false;
    defer comRelease(invoke);
    return comCall(*const fn (*anyopaque) callconv(.winapi) HRESULT, invoke, 3, .{}) >= 0;
}

fn findSwitchInVisibleSettings(automation: HANDLE, page_state: *bool) HANDLE {
    var frames: FrameList = .{};
    collectSettingsFrames(&frames);
    for (frames.items[0..frames.count]) |frame| {
        if (IsWindowVisible(frame) == 0) continue;
        var window: HANDLE = null;
        if (comCall(*const fn (*anyopaque, HANDLE, *HANDLE) callconv(.winapi) HRESULT, automation, 6, .{ frame, &window }) < 0 or window == null) continue;
        defer comRelease(window);
        if (findNightLightSwitch(automation, window, page_state)) |element| return element;
    }
    return null;
}

fn runNightLightJob(on: bool) void {
    var result = JobResult{ .kind = .night_light, .wanted = on };
    const com_result = CoInitializeEx(null, coinit_apartment_threaded);
    const com_initialized = com_result >= 0;
    var frames_before: FrameList = .{};
    collectSettingsFrames(&frames_before);
    _ = ShellExecuteW(null, null, settings_night_light_uri, null, null, sw_shownormal);

    var have_page_state = false;
    var page_state_after = false;
    var automation: HANDLE = null;
    if (CoCreateInstance(&clsid_ui_automation, null, clsctx_inproc_server, &iid_ui_automation, &automation) >= 0 and automation != null) {
        var page_state = false;
        var element: HANDLE = null;
        var attempt: usize = 0;
        while (attempt < 150 and element == null) : (attempt += 1) {
            element = findSwitchInVisibleSettings(automation, &page_state);
            if (element == null) Sleep(100);
        }

        if (element) |found| {
            if (page_state == on) {
                result.succeeded = true;
                have_page_state = true;
                page_state_after = on;
                comRelease(found);
            } else {
                // The Settings tree appears before the page's switch is ready to act.
                Sleep(1500);
                const pressed = invokeElement(found);
                comRelease(found);
                var flipped = false;
                var now_on = page_state;
                var check_attempt: usize = 0;
                while (check_attempt < 20 and !flipped) : (check_attempt += 1) {
                    Sleep(400);
                    if (findSwitchInVisibleSettings(automation, &now_on)) |check| comRelease(check);
                    flipped = now_on == on;
                }
                result.succeeded = pressed and flipped;
                have_page_state = true;
                page_state_after = now_on;
            }
        }
        comRelease(automation);
    }

    result.state_after = if (have_page_state) page_state_after else nightLightOn();
    if (have_page_state) {
        lockJobs();
        have_night_light_page_state = true;
        night_light_page_state = page_state_after;
        job_mutex.unlock();
    }

    var frames_after: FrameList = .{};
    collectSettingsFrames(&frames_after);
    for (frames_after.items[0..frames_after.count]) |frame| {
        if (!wasThereBefore(&frames_before, frame)) _ = PostMessageW(frame, wm_close, 0, 0);
    }
    if (com_initialized) CoUninitialize();
    publishJob(result);
}

/// Parses the CloudStore night-light value. The outer CB header alone denotes the initial OFF state;
/// an inner 2A 2B 0E record carries the actual switch bytes.
pub fn nightLightStateFromBlob(bytes: ?[]const u8) NightLightState {
    const data = bytes orelse return .unknown;
    if (data.len < 6 or data[0] != 0x43 or data[1] != 0x42 or data[2] != 0x01 or data[3] != 0x00) return .unknown;

    if (data.len >= 10) {
        var i: usize = 0;
        while (i <= data.len - 10) : (i += 1) {
            if (data[i] != 0x2A or data[i + 1] != 0x2B or data[i + 2] != 0x0E) continue;
            if (data[i + 4] != 0x43 or data[i + 5] != 0x42 or data[i + 6] != 0x01 or data[i + 7] != 0x00) continue;
            return if (data[i + 8] == 0x10 and data[i + 9] == 0x00) .on else .off;
        }
    }
    return .off;
}

/// Reads the registry state blob used by the Windows Night light page.
pub fn nightLightOn() bool {
    var key: HANDLE = null;
    if (RegOpenKeyExW(hkey_current_user, night_light_key, 0, key_read, &key) != error_success) return false;
    defer _ = RegCloseKey(key);
    var bytes: [128]u8 = @splat(0);
    var size: DWORD = bytes.len;
    var kind: DWORD = 0;
    if (RegQueryValueExW(key, night_light_value, null, &kind, &bytes, &size) != error_success or kind != reg_binary or size > bytes.len) return false;
    return nightLightStateFromBlob(bytes[0..size]) == .on;
}

/// Uses the Settings page's last observed answer after this process has pressed its switch.
pub fn nightLightOnForDisplay() bool {
    lockJobs();
    const have_page_state = have_night_light_page_state;
    const page_state = night_light_page_state;
    job_mutex.unlock();
    return if (have_page_state) page_state else nightLightOn();
}

/// Starts a Wi-Fi and/or Bluetooth switch on a worker. Only one system switch may run at a time.
pub fn requestRadios(wifi: bool, bluetooth: bool, on: bool) bool {
    return launchRadioJob(wifi, bluetooth, on);
}

pub fn radioRequestInFlight() bool {
    lockJobs();
    const in_flight = job_busy and job_result.kind == .radios;
    job_mutex.unlock();
    return in_flight;
}

pub fn takeRadioOutcome() ?RadioOutcome {
    lockJobs();
    if (!job_result.finished or job_result.kind != .radios) {
        job_mutex.unlock();
        return null;
    }
    const outcome = RadioOutcome{
        .wifi_now = job_result.wifi_now,
        .bluetooth_now = job_result.bluetooth_now,
        .wifi_asked = job_result.wifi_requested,
        .bluetooth_asked = job_result.bluetooth_requested,
        .succeeded = job_result.succeeded,
        .hresult = job_result.hresult,
    };
    job_result = .{};
    const thread = worker_thread;
    worker_thread = null;
    job_mutex.unlock();
    if (thread) |finished_thread| finished_thread.join();
    return outcome;
}

/// Starts the Windows Settings UI Automation sequence that switches Night light.
pub fn requestNightLight(on: bool) bool {
    return launchNightLightJob(on);
}

pub fn nightLightRequestInFlight() bool {
    lockJobs();
    const in_flight = job_busy and job_result.kind == .night_light;
    job_mutex.unlock();
    return in_flight;
}

pub fn takeNightLightOutcome() ?NightLightOutcome {
    lockJobs();
    if (!job_result.finished or job_result.kind != .night_light) {
        job_mutex.unlock();
        return null;
    }
    const outcome = NightLightOutcome{
        .wanted = job_result.wanted,
        .state_after = job_result.state_after,
        .succeeded = job_result.succeeded,
    };
    job_result = .{};
    const thread = worker_thread;
    worker_thread = null;
    job_mutex.unlock();
    if (thread) |finished_thread| finished_thread.join();
    return outcome;
}

/// Whether LiveCaptions.exe is present in the current process snapshot.
pub fn liveCaptionsRunning() bool {
    const snapshot = CreateToolhelp32Snapshot(process_snapshot, 0);
    if (snapshot == null or @intFromPtr(snapshot.?) == invalid_handle) return false;
    defer _ = CloseHandle(snapshot);

    var entry = std.mem.zeroes(ProcessEntry32W);
    entry.size = @sizeOf(ProcessEntry32W);
    if (Process32FirstW(snapshot, &entry) == 0) return false;
    while (true) {
        if (wideAsciiEqlIgnoreCase(&entry.exe_file, "LiveCaptions.exe")) return true;
        if (Process32NextW(snapshot, &entry) == 0) break;
    }
    return false;
}

/// Toggles Windows Live Captions through its Win+Ctrl+L shortcut.
pub fn toggleLiveCaptions() bool {
    return ShellCommand.sendWindowsCtrlKeyChord('L');
}

fn wideAsciiEqlIgnoreCase(wide: []const u16, ascii: []const u8) bool {
    const end = std.mem.indexOfScalar(u16, wide, 0) orelse wide.len;
    if (end != ascii.len) return false;
    for (wide[0..end], ascii) |unit, byte| {
        var lowered = unit;
        if (lowered >= 'A' and lowered <= 'Z') lowered += 'a' - 'A';
        const expected: u16 = if (byte >= 'A' and byte <= 'Z') byte + ('a' - 'A') else byte;
        if (lowered != expected) return false;
    }
    return true;
}

pub fn smokeCheck() bool {
    const off_fresh = [_]u8{ 0x43, 0x42, 0x01, 0x00, 0x0A, 0x02, 0x01, 0x00, 0x2A, 0x2A, 0, 0, 0 };
    const off_again = [_]u8{ 0x43, 0x42, 0x01, 0x00, 0x0A, 0x02, 0x01, 0x00, 0x2A, 0x06, 0xBD, 0xE3, 0xB9, 0xD6, 0x06, 0x2A, 0x2B, 0x0E, 0x13, 0x43, 0x42, 0x01, 0x00, 0xD0, 0x0A, 0x02, 0xC6, 0x14, 0xBA, 0xBB, 0xFC, 0xDC, 0xCB, 0xE7, 0xD6, 0xEE, 0x01, 0x00, 0, 0, 0 };
    const on = [_]u8{ 0x43, 0x42, 0x01, 0x00, 0x0A, 0x02, 0x01, 0x00, 0x2A, 0x06, 0xBA, 0xE3, 0xB9, 0xD6, 0x06, 0x2A, 0x2B, 0x0E, 0x15, 0x43, 0x42, 0x01, 0x00, 0x10, 0x00, 0xD0, 0x0A, 0x02, 0xC6, 0x14, 0xB3, 0xD4, 0xFA, 0xCD, 0xCB, 0xE7, 0xD6, 0xEE, 0x01, 0x00, 0, 0, 0 };
    const malformed = [_]u8{ 0, 0, 0, 0, 0, 0 };
    return nightLightStateFromBlob(&off_fresh) == .off and
        nightLightStateFromBlob(&off_again) == .off and
        nightLightStateFromBlob(&on) == .on and
        nightLightStateFromBlob(&malformed) == .unknown and
        nightLightStateFromBlob(null) == .unknown and
        wideAsciiEqlIgnoreCase(&.{ 'l', 'I', 'v', 'e', 'C', 'a', 'p', 't', 'i', 'o', 'n', 's', '.', 'e', 'x', 'e', 0 }, "LiveCaptions.exe");
}
