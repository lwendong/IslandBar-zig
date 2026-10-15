const std = @import("std");

const HANDLE = ?*anyopaque;
const HWND = HANDLE;
const DWORD = u32;
const BOOL = i32;
const LPARAM = isize;
const INVALID_HANDLE_VALUE: usize = std.math.maxInt(usize);
const TH32CS_SNAPPROCESS: DWORD = 0x00000002;
const HWND_MESSAGE: HWND = @ptrFromInt(std.math.maxInt(usize) - 2);

pub const Rect = extern struct { left: i32 = 0, top: i32 = 0, right: i32 = 0, bottom: i32 = 0 };
pub const Guid = extern struct { data1: u32 = 0, data2: u16 = 0, data3: u16 = 0, data4: [8]u8 = @splat(0) };
pub const Request = struct {
    uid: u32 = 0,
    has_uid: bool = false,
    has_guid: bool = false,
    guid: Guid = .{},
    exe_path: [512]u16 = @splat(0),
    name: [96]u16 = @splat(0),
};
pub const Result = enum { pressed, found, not_in_shell, no_window, no_element, no_taskbar, refused };
pub const Outcome = struct {
    result: Result = .refused,
    rect: Rect = .{},
    shell_name: [128]u16 = @splat(0),
    lookup_ms: i64 = 0,
    press_ms: i64 = 0,
};

const ProcessEntry32W = extern struct {
    size: DWORD,
    usage_count: DWORD,
    process_id: DWORD,
    default_heap_id: usize,
    module_id: DWORD,
    thread_count: DWORD,
    parent_process_id: DWORD,
    base_priority: i32,
    flags: DWORD,
    exe_file: [260]u16,
};
const NotifyIconIdentifier = extern struct { cb_size: DWORD, window: HWND, uid: DWORD, guid: Guid };
const WindowSearch = struct { pids: []const DWORD, windows: *std.ArrayList(HWND) };
const UnknownVTable = extern struct {
    query_interface: *const fn (*anyopaque, *const Guid, *HANDLE) callconv(.winapi) i32,
    add_ref: *const fn (*anyopaque) callconv(.winapi) u32,
    release: *const fn (*anyopaque) callconv(.winapi) u32,
};
const Unknown = extern struct { vtable: *const UnknownVTable };
const VariantData = extern union { bstr: ?[*:0]u16, raw: [2]u64 };
const Variant = extern struct { vt: u16, reserved: [3]u16, data: VariantData };
const UiAElementRect = struct { element: HANDLE, rect: Rect };

const clsid_ui_automation = Guid{ .data1 = 0xFF48DBA4, .data2 = 0x60EF, .data3 = 0x4201, .data4 = .{ 0xAA, 0x87, 0x54, 0x10, 0x3E, 0xEF, 0x59, 0x4E } };
const iid_ui_automation = Guid{ .data1 = 0x30CBE57D, .data2 = 0xD9D0, .data3 = 0x452A, .data4 = .{ 0xAB, 0x13, 0x7A, 0xC5, 0xAC, 0x48, 0x25, 0xEE } };
const iid_ui_automation_invoke = Guid{ .data1 = 0xFB377FBE, .data2 = 0x8EA6, .data3 = 0x46D5, .data4 = .{ 0x9C, 0x73, 0x64, 0x99, 0x64, 0x2D, 0x30, 0x59 } };
const rpc_e_changed_mode: i32 = -2147417850;
const clsctx_inproc_server: DWORD = 1;
const coinit_apartment_threaded: DWORD = 2;
const tree_scope_children: i32 = 2;
const tree_scope_descendants: i32 = 4;
const variant_bstr: u16 = 8;
const uia_automation_id_property_id: i32 = 30011;
const uia_class_name_property_id: i32 = 30012;
const uia_invoke_pattern_id: i32 = 10000;

extern "kernel32" fn CreateToolhelp32Snapshot(flags: DWORD, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Process32FirstW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn Process32NextW(snapshot: HANDLE, entry: *ProcessEntry32W) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn OpenProcess(access: DWORD, inherit: BOOL, process_id: DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn QueryFullProcessImageNameW(process: HANDLE, flags: DWORD, path: [*]u16, length: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn CompareStringOrdinal(a: [*]const u16, a_length: i32, b: [*]const u16, b_length: i32, ignore_case: BOOL) callconv(.winapi) i32;
extern "user32" fn EnumWindows(callback: *const fn (HWND, LPARAM) callconv(.winapi) BOOL, parameter: LPARAM) callconv(.winapi) BOOL;
extern "user32" fn FindWindowExW(parent: HWND, child_after: HWND, class_name: ?[*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn GetWindowThreadProcessId(window: HWND, process_id: *DWORD) callconv(.winapi) DWORD;
extern "user32" fn FindWindowW(class_name: [*:0]const u16, window_name: ?[*:0]const u16) callconv(.winapi) HWND;
extern "user32" fn GetWindowLongPtrW(window: HWND, index: i32) callconv(.winapi) isize;
extern "user32" fn SetWindowLongPtrW(window: HWND, index: i32, value: isize) callconv(.winapi) isize;
extern "user32" fn SetLayeredWindowAttributes(window: HWND, color_key: u32, alpha: u8, flags: DWORD) callconv(.winapi) BOOL;
extern "user32" fn ShowWindow(window: HWND, command: i32) callconv(.winapi) BOOL;
extern "user32" fn SetWindowPos(window: HWND, insert_after: HWND, x: i32, y: i32, width: i32, height: i32, flags: DWORD) callconv(.winapi) BOOL;
extern "user32" fn GetCursorPos(point: *Point) callconv(.winapi) BOOL;
extern "user32" fn SetCursorPos(x: i32, y: i32) callconv(.winapi) BOOL;
extern "user32" fn mouse_event(flags: DWORD, dx: DWORD, dy: DWORD, data: DWORD, extra_info: usize) callconv(.winapi) void;
extern "shell32" fn Shell_NotifyIconGetRect(identifier: *const NotifyIconIdentifier, rect: *Rect) callconv(.winapi) i32;
extern "ole32" fn CoCreateInstance(class_id: *const Guid, outer: HANDLE, context: DWORD, iid: *const Guid, object: *HANDLE) callconv(.winapi) i32;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, apartment: DWORD) callconv(.winapi) i32;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "oleaut32" fn SysAllocString(value: [*:0]const u16) callconv(.winapi) ?[*:0]u16;
extern "oleaut32" fn SysFreeString(value: ?[*:0]u16) callconv(.winapi) void;
extern "user32" fn IsWindowVisible(window: HWND) callconv(.winapi) BOOL;

const Point = extern struct { x: i32, y: i32 };
const g_interactive: DWORD = 0x00000200;
const gwl_exstyle: i32 = -20;
const ws_ex_layered: isize = 0x00080000;
const lwa_alpha: DWORD = 0x2;
const sw_hide: i32 = 0;
const sw_showna: i32 = 8;
const swp_nosize: DWORD = 0x1;
const swp_nozorder: DWORD = 0x4;
const swp_noactivate: DWORD = 0x10;
const mouseeventf_rightdown: DWORD = 0x0008;
const mouseeventf_rightup: DWORD = 0x0010;
const process_query_limited_information: DWORD = 0x1000;

var press_in_flight = std.atomic.Value(bool).init(false);
var cleanup_taskbar = std.atomic.Value(usize).init(0);
var cleanup_style = std.atomic.Value(isize).init(0);

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

fn comAddRef(object: HANDLE) void {
    if (object) |value| _ = comCall(*const fn (*anyopaque) callconv(.winapi) u32, value, 1, .{});
}

fn createTrueCondition(automation: HANDLE) HANDLE {
    var condition: HANDLE = null;
    const hr = comCall(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, automation, 21, .{&condition});
    return if (hr >= 0) condition else null;
}

fn createPropertyCondition(automation: HANDLE, property_id: i32, value: [*:0]const u16) HANDLE {
    const bstr = SysAllocString(value) orelse return null;
    defer SysFreeString(bstr);
    var condition: HANDLE = null;
    const variant = Variant{ .vt = variant_bstr, .reserved = .{ 0, 0, 0 }, .data = .{ .bstr = bstr } };
    const hr = comCall(*const fn (*anyopaque, i32, Variant, *HANDLE) callconv(.winapi) i32, automation, 23, .{ property_id, variant, &condition });
    return if (hr >= 0) condition else null;
}

fn findAll(root: HANDLE, scope: i32, condition: HANDLE) HANDLE {
    var elements: HANDLE = null;
    const hr = comCall(*const fn (*anyopaque, i32, HANDLE, *HANDLE) callconv(.winapi) i32, root, 6, .{ scope, condition, &elements });
    return if (hr >= 0) elements else null;
}

fn elementArrayLength(elements: HANDLE) i32 {
    var count: i32 = 0;
    const hr = comCall(*const fn (*anyopaque, *i32) callconv(.winapi) i32, elements, 3, .{&count});
    return if (hr >= 0 and count > 0) count else 0;
}

fn elementArrayGet(elements: HANDLE, index: i32) HANDLE {
    var element: HANDLE = null;
    const hr = comCall(*const fn (*anyopaque, i32, *HANDLE) callconv(.winapi) i32, elements, 4, .{ index, &element });
    return if (hr >= 0) element else null;
}

fn currentRect(element: HANDLE) ?Rect {
    var rect = Rect{};
    const hr = comCall(*const fn (*anyopaque, *Rect) callconv(.winapi) i32, element, 43, .{&rect});
    if (hr < 0 or rect.right <= rect.left or rect.bottom <= rect.top) return null;
    return rect;
}

fn elementOnRect(automation: HANDLE, root: HANDLE, wanted: Rect, tolerance_px: i32, require_invoke: bool, name_out: ?[]u16) HANDLE {
    const condition = createTrueCondition(automation) orelse return null;
    defer comRelease(condition);
    const found = findAll(root, tree_scope_descendants, condition) orelse return null;
    defer comRelease(found);

    const allocator = std.heap.page_allocator;
    var candidates = std.ArrayList(UiAElementRect).empty;
    defer {
        for (candidates.items) |candidate| comRelease(candidate.element);
        candidates.deinit(allocator);
    }
    const count = elementArrayLength(found);
    for (0..@intCast(count)) |index| {
        const element = elementArrayGet(found, @intCast(index)) orelse continue;
        const rect = currentRect(element) orelse {
            comRelease(element);
            continue;
        };
        candidates.append(allocator, .{ .element = element, .rect = rect }) catch {
            comRelease(element);
            continue;
        };
    }

    var rects = std.ArrayList(Rect).empty;
    defer rects.deinit(allocator);
    for (candidates.items) |candidate| rects.append(allocator, candidate.rect) catch return null;
    const hit = indexOfRectNear(rects.items, wanted, tolerance_px) orelse return null;
    const element = candidates.items[hit].element;
    if (require_invoke) {
        var invoke: HANDLE = null;
        const hr = comCall(*const fn (*anyopaque, i32, *const Guid, *HANDLE) callconv(.winapi) i32, element, 14, .{ uia_invoke_pattern_id, &iid_ui_automation_invoke, &invoke });
        if (hr < 0 or invoke == null) {
            comRelease(invoke);
            return null;
        }
        comRelease(invoke);
    }

    if (name_out) |output| {
        if (output.len > 0) {
            @memset(output, 0);
            var name: ?[*:0]u16 = null;
            const hr = comCall(*const fn (*anyopaque, *?[*:0]u16) callconv(.winapi) i32, element, 23, .{&name});
            if (hr >= 0) {
                if (name) |value| {
                    var length: usize = 0;
                    while (length + 1 < output.len and value[length] != 0) : (length += 1) output[length] = value[length];
                    SysFreeString(value);
                }
            }
        }
    }
    comAddRef(element);
    return element;
}

fn findOverflowChevron(automation: HANDLE, taskbar: HANDLE, output_rect: ?*Rect) HANDLE {
    const condition = createPropertyCondition(automation, uia_automation_id_property_id, &.{ 'S', 'y', 's', 't', 'e', 'm', 'T', 'r', 'a', 'y', 'I', 'c', 'o', 'n', 0 }) orelse return null;
    defer comRelease(condition);
    const buttons = findAll(taskbar, tree_scope_descendants, condition) orelse return null;
    defer comRelease(buttons);

    var best: HANDLE = null;
    var best_rect = Rect{};
    const count = elementArrayLength(buttons);
    for (0..@intCast(count)) |index| {
        const element = elementArrayGet(buttons, @intCast(index)) orelse continue;
        defer comRelease(element);
        const rect = currentRect(element) orelse continue;
        if (best == null or rect.left < best_rect.left) {
            if (best != null) comRelease(best);
            comAddRef(element);
            best = element;
            best_rect = rect;
        }
    }
    if (best != null and output_rect != null) output_rect.?.* = best_rect;
    return best;
}

fn invokeElement(element: HANDLE) bool {
    if (element == null) return false;
    var invoke: HANDLE = null;
    const hr = comCall(*const fn (*anyopaque, i32, *const Guid, *HANDLE) callconv(.winapi) i32, element, 14, .{ uia_invoke_pattern_id, &iid_ui_automation_invoke, &invoke });
    if (hr < 0 or invoke == null) return false;
    defer comRelease(invoke);
    return comCall(*const fn (*anyopaque) callconv(.winapi) i32, invoke, 3, .{}) >= 0;
}

fn overflowIconCount(automation: HANDLE, element: HANDLE) i32 {
    const condition = createPropertyCondition(automation, uia_automation_id_property_id, &.{ 'N', 'o', 't', 'i', 'f', 'y', 'I', 't', 'e', 'm', 'I', 'c', 'o', 'n', 0 }) orelse return 0;
    defer comRelease(condition);
    const elements = findAll(element, tree_scope_descendants, condition) orelse return 0;
    defer comRelease(elements);
    return elementArrayLength(elements);
}

fn findOverflowFlyout(automation: HANDLE) HANDLE {
    var desktop: HANDLE = null;
    const root_hr = comCall(*const fn (*anyopaque, *HANDLE) callconv(.winapi) i32, automation, 5, .{&desktop});
    if (root_hr < 0 or desktop == null) return null;
    defer comRelease(desktop);

    const condition = createPropertyCondition(automation, uia_class_name_property_id, &.{ 'T', 'o', 'p', 'L', 'e', 'v', 'e', 'l', 'W', 'i', 'n', 'd', 'o', 'w', 'F', 'o', 'r', 'O', 'v', 'e', 'r', 'f', 'l', 'o', 'w', 'X', 'a', 'm', 'l', 'I', 's', 'l', 'a', 'n', 'd', 0 }) orelse return null;
    defer comRelease(condition);
    const tops = findAll(desktop, tree_scope_children, condition) orelse return null;
    defer comRelease(tops);
    const count = elementArrayLength(tops);
    for (0..@intCast(count)) |index| {
        const candidate = elementArrayGet(tops, @intCast(index)) orelse continue;
        var native_window: isize = 0;
        const native_hr = comCall(*const fn (*anyopaque, *isize) callconv(.winapi) i32, candidate, 36, .{&native_window});
        const window: HWND = if (native_window == 0) null else @ptrFromInt(@as(usize, @bitCast(native_window)));
        if (native_hr >= 0 and window != null and IsWindowVisible(window) != 0 and overflowIconCount(automation, candidate) > 0) return candidate;
        comRelease(candidate);
    }
    return null;
}

pub fn indexOfRectNear(rects: []const Rect, wanted: Rect, tolerance_px: i32) ?usize {
    for (rects, 0..) |rect, index| {
        if (@abs(rect.left - wanted.left) <= tolerance_px and @abs(rect.top - wanted.top) <= tolerance_px and
            @abs(rect.right - wanted.right) <= tolerance_px and @abs(rect.bottom - wanted.bottom) <= tolerance_px) return index;
    }
    return null;
}

/// Asks the shell for the rectangle belonging to a registered tray icon.
/// GUID identities are direct; legacy UIDs are resolved against every window
/// owned by every process with the registered executable name.
pub fn iconRect(request: *const Request, output: *Rect) bool {
    if (request.has_guid) {
        var identifier = NotifyIconIdentifier{ .cb_size = @sizeOf(NotifyIconIdentifier), .window = null, .uid = 0, .guid = request.guid };
        return queryRect(&identifier, output);
    }
    if (!request.has_uid) return false;

    const allocator = std.heap.page_allocator;
    var pids = std.ArrayList(DWORD).empty;
    defer pids.deinit(allocator);
    collectPids(allocator, wideZSlice(&request.exe_path), &pids);
    if (pids.items.len == 0) return false;

    var windows = std.ArrayList(HWND).empty;
    defer windows.deinit(allocator);
    collectWindows(allocator, pids.items, &windows);
    if (windows.items.len == 0) return false;

    var rect_matches = std.ArrayList(Rect).empty;
    defer rect_matches.deinit(std.heap.page_allocator);
    for (windows.items) |window| {
        var identifier = NotifyIconIdentifier{ .cb_size = @sizeOf(NotifyIconIdentifier), .window = window, .uid = request.uid, .guid = .{} };
        var rect = Rect{};
        if (!queryRect(&identifier, &rect)) continue;
        rect_matches.append(std.heap.page_allocator, rect) catch return false;
    }
    if (uniqueRect(rect_matches.items)) |found| {
        output.* = found;
        return true;
    }
    if (rect_matches.items.len != 0) return false;

    // Some shell registrations report a sentinel UID. Accept the fallback only
    // when exactly one distinct rectangle among the small legacy range answers.
    var unique = Rect{};
    var matches: usize = 0;
    for (0..9) |uid_index| {
        for (windows.items) |window| {
            var identifier = NotifyIconIdentifier{ .cb_size = @sizeOf(NotifyIconIdentifier), .window = window, .uid = @intCast(uid_index), .guid = .{} };
            var rect = Rect{};
            if (!queryRect(&identifier, &rect)) continue;
            if (matches > 0 and sameRect(rect, unique)) continue;
            unique = rect;
            matches += 1;
            break;
        }
        if (matches >= 2) break;
    }
    if (matches != 1) return false;
    output.* = unique;
    return true;
}

fn collectPids(allocator: std.mem.Allocator, exe_path: []const u16, pids: *std.ArrayList(DWORD)) void {
    if (exe_path.len == 0) return;
    const snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == null or @intFromPtr(snapshot.?) == INVALID_HANDLE_VALUE) return;
    defer _ = CloseHandle(snapshot);

    var entry = std.mem.zeroes(ProcessEntry32W);
    entry.size = @sizeOf(ProcessEntry32W);
    if (Process32FirstW(snapshot, &entry) == 0) return;
    while (true) {
        if (processImagePath(entry.process_id)) |path| {
            if (wideEqualIgnoreCase(wideZSlice(&path), wideZSlice(exe_path))) pids.append(allocator, entry.process_id) catch return;
        }
        if (Process32NextW(snapshot, &entry) == 0) break;
    }
}

fn processImagePath(process_id: DWORD) ?[512]u16 {
    const process = OpenProcess(process_query_limited_information, 0, process_id) orelse return null;
    defer _ = CloseHandle(process);
    var path: [512]u16 = @splat(0);
    var length: DWORD = @intCast(path.len);
    if (QueryFullProcessImageNameW(process, 0, &path, &length) == 0 or length == 0) return null;
    path[@min(length, @as(DWORD, @intCast(path.len - 1)))] = 0;
    return path;
}

fn collectWindows(allocator: std.mem.Allocator, pids: []const DWORD, windows: *std.ArrayList(HWND)) void {
    var search = WindowSearch{ .pids = pids, .windows = windows };
    _ = EnumWindows(collectTopLevelWindow, @intCast(@intFromPtr(&search)));
    var child: HWND = null;
    while (true) {
        child = FindWindowExW(HWND_MESSAGE, child, null, null);
        const window = child orelse break;
        var process_id: DWORD = 0;
        _ = GetWindowThreadProcessId(window, &process_id);
        if (containsPid(pids, process_id)) windows.append(allocator, window) catch return;
    }
}

fn collectTopLevelWindow(window: HWND, parameter: LPARAM) callconv(.winapi) BOOL {
    const search: *WindowSearch = @ptrFromInt(@as(usize, @bitCast(parameter)));
    var process_id: DWORD = 0;
    _ = GetWindowThreadProcessId(window, &process_id);
    if (containsPid(search.pids, process_id)) search.windows.append(std.heap.page_allocator, window) catch return 0;
    return 1;
}

fn containsPid(pids: []const DWORD, process_id: DWORD) bool {
    for (pids) |pid| if (pid == process_id) return true;
    return false;
}

fn queryRect(identifier: *const NotifyIconIdentifier, output: *Rect) bool {
    var rect = Rect{};
    const hr = Shell_NotifyIconGetRect(identifier, &rect);
    if (hr < 0 or hr == 1) return false;
    output.* = rect;
    return true;
}

fn sameRect(a: Rect, b: Rect) bool {
    return a.left == b.left and a.top == b.top and a.right == b.right and a.bottom == b.bottom;
}

pub fn uniqueRect(rects: []const Rect) ?Rect {
    if (rects.len == 0) return null;
    const first = rects[0];
    for (rects[1..]) |rect| if (!sameRect(rect, first)) return null;
    return first;
}

fn wideZSlice(value: []const u16) []const u16 {
    const end = std.mem.indexOfScalar(u16, value, 0) orelse value.len;
    return value[0..end];
}

fn wideEqualIgnoreCase(a: []const u16, b: []const u16) bool {
    if (a.len != b.len or a.len > std.math.maxInt(i32)) return false;
    if (a.len == 0) return true;
    return CompareStringOrdinal(a.ptr, @intCast(a.len), b.ptr, @intCast(b.len), 1) == 2;
}

pub const Stage = struct {
    taskbar: HWND = null,
    flyout_window: HWND = null,
    flyout_home: Rect = .{},
    taskbar_style: isize = 0,
    flyout_style: isize = 0,
    taskbar_layered_added: bool = false,
    flyout_layered_added: bool = false,
    taskbar_was_visible: bool = false,
    com_initialized: bool = false,
    opened_flyout: bool = false,
    right_clicked: bool = false,
    automation: HANDLE = null,
    chevron: HANDLE = null,
    flyout: HANDLE = null,

    pub fn begin(self: *Stage, note: []u16) bool {
        setNote(note, &.{});
        self.taskbar = FindWindowW(&.{ 'S', 'h', 'e', 'l', 'l', '_', 'T', 'r', 'a', 'y', 'W', 'n', 'd', 0 }, null);
        if (self.taskbar == null) {
            setNote(note, &.{ 'n', 'o', ' ', 't', 'a', 's', 'k', 'b', 'a', 'r' });
            return false;
        }

        self.taskbar_style = GetWindowLongPtrW(self.taskbar, gwl_exstyle);
        self.taskbar_was_visible = IsWindowVisible(self.taskbar) != 0;
        if ((self.taskbar_style & ws_ex_layered) == 0) {
            _ = SetWindowLongPtrW(self.taskbar, gwl_exstyle, self.taskbar_style | ws_ex_layered);
            self.taskbar_layered_added = true;
        }
        _ = SetLayeredWindowAttributes(self.taskbar, 0, 0, lwa_alpha);
        _ = ShowWindow(self.taskbar, sw_showna);

        const com_hr = CoInitializeEx(null, coinit_apartment_threaded);
        self.com_initialized = com_hr >= 0;
        var automation: HANDLE = null;
        const create_hr = CoCreateInstance(&clsid_ui_automation, null, clsctx_inproc_server, &iid_ui_automation, &automation);
        if (create_hr < 0 or automation == null) {
            if (self.com_initialized) {
                CoUninitialize();
                self.com_initialized = false;
            }
            setNote(note, &.{ 'U', 'I', ' ', 'A', 'u', 't', 'o', 'm', 'a', 't', 'i', 'o', 'n', ' ', 'c', 'o', 'u', 'l', 'd', ' ', 'n', 'o', 't', ' ', 'b', 'e', ' ', 'c', 'r', 'e', 'a', 't', 'e', 'd' });
            return false;
        }
        self.automation = automation;

        var taskbar_element: HANDLE = null;
        var chevron_rect = Rect{};
        for (0..60) |_| {
            if (taskbar_element == null) {
                const hr = comCall(*const fn (*anyopaque, HWND, *HANDLE) callconv(.winapi) i32, automation, 6, .{ self.taskbar, &taskbar_element });
                if (hr < 0) taskbar_element = null;
            }
            if (taskbar_element != null) self.chevron = findOverflowChevron(automation, taskbar_element, &chevron_rect);
            if (self.chevron != null) break;
            Sleep(40);
        }
        comRelease(taskbar_element);
        if (self.chevron == null) {
            setNote(note, &.{ 't', 'h', 'e', ' ', 't', 'r', 'a', 'y', ' ', 'n', 'e', 'v', 'e', 'r', ' ', 'p', 'u', 'b', 'l', 'i', 's', 'h', 'e', 'd', ' ', 'i', 't', 's', ' ', 'b', 'u', 't', 't', 'o', 'n', 's' });
            return false;
        }

        self.flyout = findOverflowFlyout(automation);
        if (self.flyout == null) {
            _ = invokeElement(self.chevron);
            self.opened_flyout = true;
            for (0..400) |attempt| {
                Sleep(1);
                const panel = FindWindowExW(null, null, &.{ 'T', 'o', 'p', 'L', 'e', 'v', 'e', 'l', 'W', 'i', 'n', 'd', 'o', 'w', 'F', 'o', 'r', 'O', 'v', 'e', 'r', 'f', 'l', 'o', 'w', 'X', 'a', 'm', 'l', 'I', 's', 'l', 'a', 'n', 'd', 0 }, null);
                if (panel != null) self.hideFlyoutWindow(panel);
                if (attempt % 5 == 0) {
                    self.flyout = findOverflowFlyout(automation);
                    if (self.flyout != null) self.hidePanel(self.flyout);
                }
                if (self.flyout != null) break;
            }
        }
        if (self.flyout == null) {
            setNote(note, &.{ 't', 'h', 'e', ' ', 'o', 'v', 'e', 'r', 'f', 'l', 'o', 'w', ' ', 'f', 'l', 'y', 'o', 'u', 't', ' ', 'd', 'i', 'd', ' ', 'n', 'o', 't', ' ', 'o', 'p', 'e', 'n' });
            return false;
        }
        self.hidePanel(self.flyout);

        const flyout_seen = GetTickCount64();
        var previous = Rect{};
        var current = Rect{};
        var stable_reads: usize = 0;
        for (0..60) |_| {
            current = currentRect(self.flyout) orelse break;
            const same = sameRect(current, previous);
            stable_reads = if (same) stable_reads + 1 else 0;
            previous = current;
            if (stable_reads >= 3 and GetTickCount64() - flyout_seen >= 150) break;
            Sleep(25);
        }
        self.flyout_home = current;
        self.hidePanel(self.flyout);
        return true;
    }

    fn hideFlyoutWindow(self: *Stage, window: HWND) void {
        if (window == null) return;
        if (window != self.flyout_window) {
            self.flyout_window = window;
            self.flyout_style = GetWindowLongPtrW(window, gwl_exstyle);
            if ((self.flyout_style & ws_ex_layered) == 0) {
                _ = SetWindowLongPtrW(window, gwl_exstyle, self.flyout_style | ws_ex_layered);
                self.flyout_layered_added = true;
            }
        }
        _ = SetLayeredWindowAttributes(window, 0, 0, lwa_alpha);
    }

    fn hidePanel(self: *Stage, element: HANDLE) void {
        if (element == null) return;
        if (self.flyout_window != null) {
            self.hideFlyoutWindow(self.flyout_window);
            return;
        }
        var native_window: isize = 0;
        const hr = comCall(*const fn (*anyopaque, *isize) callconv(.winapi) i32, element, 36, .{&native_window});
        if (hr >= 0 and native_window != 0) self.hideFlyoutWindow(@ptrFromInt(@as(usize, @bitCast(native_window))));
    }

    pub fn resolveIconRect(self: *const Stage, request: *const Request, output: *Rect) bool {
        _ = self;
        return iconRect(request, output);
    }

    pub fn pressOnRect(self: *Stage, rect: Rect, press: bool, right_click: bool, shell_name: []u16) Result {
        if (self.automation == null or self.flyout == null) return .no_element;
        const button = elementOnRect(self.automation, self.flyout, rect, 4, !right_click, shell_name) orelse return .no_element;
        defer comRelease(button);
        self.right_clicked = press and right_click;
        if (!press) return .found;
        if (!right_click) return if (invokeElement(button)) .pressed else .refused;

        if (self.flyout_window != null) _ = SetLayeredWindowAttributes(self.flyout_window, 0, 255, lwa_alpha);
        var saved = Point{ .x = 0, .y = 0 };
        if (GetCursorPos(&saved) == 0) return .refused;
        const center_x = @divTrunc(rect.left + rect.right, 2);
        const center_y = @divTrunc(rect.top + rect.bottom, 2);
        _ = SetCursorPos(center_x, center_y);
        Sleep(30);
        mouse_event(mouseeventf_rightdown, 0, 0, 0, 0);
        Sleep(30);
        mouse_event(mouseeventf_rightup, 0, 0, 0, 0);
        if (self.flyout_window != null) _ = SetLayeredWindowAttributes(self.flyout_window, 0, 0, lwa_alpha);
        Sleep(60);
        _ = SetCursorPos(saved.x, saved.y);
        return .pressed;
    }

    pub fn reset(self: *Stage) void {
        if (self.opened_flyout and self.chevron != null and !self.right_clicked) {
            Sleep(50);
            _ = invokeElement(self.chevron);
            Sleep(120);
        }
        comRelease(self.chevron);
        comRelease(self.flyout);
        comRelease(self.automation);
        self.chevron = null;
        self.flyout = null;
        self.automation = null;
        if (self.com_initialized) {
            CoUninitialize();
            self.com_initialized = false;
        }
        if (self.flyout_window != null) {
            _ = SetWindowPos(self.flyout_window, null, self.flyout_home.left, self.flyout_home.top, 0, 0, swp_nosize | swp_nozorder | swp_noactivate);
            _ = SetLayeredWindowAttributes(self.flyout_window, 0, 255, lwa_alpha);
            if (self.flyout_layered_added) _ = SetWindowLongPtrW(self.flyout_window, gwl_exstyle, self.flyout_style);
            self.flyout_window = null;
            self.flyout_layered_added = false;
        }
        if (self.taskbar != null) {
            if (!self.taskbar_was_visible) _ = ShowWindow(self.taskbar, sw_hide);
            if (self.right_clicked and self.opened_flyout) {
                cleanup_style.store(self.taskbar_style, .seq_cst);
                cleanup_taskbar.store(@intFromPtr(self.taskbar), .seq_cst);
            } else {
                if (self.taskbar_layered_added) _ = SetWindowLongPtrW(self.taskbar, gwl_exstyle, self.taskbar_style);
                _ = SetLayeredWindowAttributes(self.taskbar, 0, 255, lwa_alpha);
            }
            self.taskbar = null;
            self.taskbar_layered_added = false;
        }
    }
};

fn setNote(note: []u16, value: []const u16) void {
    if (note.len == 0) return;
    @memset(note, 0);
    const copy_count = @min(value.len, note.len - 1);
    @memcpy(note[0..copy_count], value[0..copy_count]);
}

pub fn isInFlight() bool {
    return press_in_flight.load(.seq_cst);
}

pub fn cleanupPending() bool {
    return cleanup_taskbar.load(.seq_cst) != 0;
}

pub fn finishCleanup() bool {
    const taskbar = cleanup_taskbar.swap(0, .seq_cst);
    if (taskbar == 0) return false;
    const window: HWND = @ptrFromInt(taskbar);
    _ = ShowWindow(window, sw_hide);
    _ = SetWindowLongPtrW(window, gwl_exstyle, cleanup_style.load(.seq_cst));
    _ = SetLayeredWindowAttributes(window, 0, 255, lwa_alpha);
    return true;
}

pub fn pressTrayIcon(request: *const Request, press: bool, right_click: bool) Outcome {
    press_in_flight.store(true, .seq_cst);
    defer press_in_flight.store(false, .seq_cst);
    var outcome = Outcome{};
    var stage = Stage{};
    defer stage.reset();
    var note: [160]u16 = @splat(0);
    if (!stage.begin(&note)) {
        outcome.result = if (std.mem.eql(u16, wideZSlice(&note), &.{ 'n', 'o', ' ', 't', 'a', 's', 'k', 'b', 'a', 'r' })) .no_taskbar else .no_element;
        return outcome;
    }
    const lookup_start = GetTickCount64();
    const have_rect = stage.resolveIconRect(request, &outcome.rect);
    outcome.lookup_ms = @intCast(GetTickCount64() - lookup_start);
    if (!have_rect) {
        outcome.result = if (request.has_guid or request.has_uid) .not_in_shell else .no_window;
        return outcome;
    }
    const press_start = GetTickCount64();
    outcome.result = stage.pressOnRect(outcome.rect, press, right_click, &outcome.shell_name);
    outcome.press_ms = @intCast(GetTickCount64() - press_start);
    return outcome;
}

pub fn resultName(result: Result) []const u8 {
    return switch (result) {
        .pressed => "pressed",
        .found => "found it, and was asked not to press",
        .not_in_shell => "the shell has no rectangle for it",
        .no_window => "no window of that application answered",
        .no_element => "nothing sits on that rectangle",
        .no_taskbar => "no taskbar",
        .refused => "refused",
    };
}

pub fn smokeCheck() bool {
    // Keep the Windows/COM execution path type-checked by the normal build without running it here.
    const press_entrypoint: *const fn (*const Request, bool, bool) Outcome = pressTrayIcon;
    _ = press_entrypoint;
    const rects = [_]Rect{ .{ .left = 10, .top = 20, .right = 40, .bottom = 50 }, .{ .left = 90, .top = 20, .right = 120, .bottom = 50 } };
    return indexOfRectNear(&rects, .{ .left = 91, .top = 20, .right = 121, .bottom = 50 }, 1) == 1 and
        indexOfRectNear(&rects, .{ .left = 91, .top = 20, .right = 121, .bottom = 50 }, 0) == null and
        std.mem.eql(u8, resultName(.found), "found it, and was asked not to press") and
        std.mem.eql(u8, resultName(.no_taskbar), "no taskbar");
}

test "legacy tray UID resolution refuses ambiguous process windows" {
    const first = Rect{ .left = 10, .top = 20, .right = 30, .bottom = 40 };
    const same = [_]Rect{ first, first };
    const different = [_]Rect{ first, .{ .left = 50, .top = 20, .right = 70, .bottom = 40 } };
    try std.testing.expectEqual(first, uniqueRect(&same).?);
    try std.testing.expect(uniqueRect(&different) == null);
    try std.testing.expect(uniqueRect(&.{}) == null);
}
