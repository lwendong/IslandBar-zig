const std = @import("std");
const Log = @import("Log");
const WeatherData = @import("WeatherData");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};

extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn GetProcAddress(module: HANDLE, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: DWORD, share: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn ReadFile(file: HANDLE, buffer: [*]u8, count: DWORD, read: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*:0]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*:0]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*BOOL) callconv(.winapi) i32;

extern "winhttp" fn WinHttpOpen(agent: [*:0]const u16, access_type: DWORD, proxy: ?[*:0]const u16, bypass: ?[*:0]const u16, flags: DWORD) callconv(.winapi) HANDLE;
extern "winhttp" fn WinHttpSetTimeouts(session: HANDLE, resolve: i32, connect: i32, send: i32, receive: i32) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpConnect(session: HANDLE, host: [*:0]const u16, port: u16, reserved: DWORD) callconv(.winapi) HANDLE;
extern "winhttp" fn WinHttpOpenRequest(connection: HANDLE, verb: [*:0]const u16, path: [*:0]const u16, version: ?[*:0]const u16, referrer: ?[*:0]const u16, accept_types: ?*anyopaque, flags: DWORD, context: usize) callconv(.winapi) HANDLE;
extern "winhttp" fn WinHttpSendRequest(request: HANDLE, headers: ?[*:0]const u16, headers_length: DWORD, optional_data: ?*anyopaque, optional_length: DWORD, total_length: DWORD, context: usize) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpReceiveResponse(request: HANDLE, reserved: ?*anyopaque) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpQueryHeaders(request: HANDLE, level: DWORD, name: ?[*:0]const u16, buffer: *anyopaque, buffer_length: *DWORD, index: ?*DWORD) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpQueryDataAvailable(request: HANDLE, available: *DWORD) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpReadData(request: HANDLE, buffer: [*]u8, bytes: DWORD, read: *DWORD) callconv(.winapi) BOOL;
extern "winhttp" fn WinHttpCloseHandle(handle: HANDLE) callconv(.winapi) BOOL;

const max_path = 260;
const cp_utf8: DWORD = 65001;
const generic_read: DWORD = 0x80000000;
const file_share_read: DWORD = 1;
const open_existing: DWORD = 3;
const file_attribute_normal: DWORD = 0x80;
const error_invalid_handle: usize = std.math.maxInt(usize);
const wait_object_0: DWORD = 0;
const infinite: DWORD = 0xFFFFFFFF;
const winhttp_access_type_automatic_proxy: DWORD = 4;
const internet_default_https_port: u16 = 443;
const winhttp_flag_secure: DWORD = 0x00800000;
const winhttp_query_status_code: DWORD = 19;
const winhttp_query_flag_number: DWORD = 0x20000000;
const http_agent: [*:0]const u16 = &.{ 'M', 'o', 'z', 'i', 'l', 'l', 'a', '/', '5', '.', '0', ' ', '(', 'W', 'i', 'n', 'd', 'o', 'w', 's', ' ', 'N', 'T', ' ', '1', '0', '.', '0', ';', ' ', 'W', 'i', 'n', '6', '4', ';', ' ', 'x', '6', '4', ')', ' ', 'A', 'p', 'p', 'l', 'e', 'W', 'e', 'b', 'K', 'i', 't', '/', '5', '3', '7', '.', '3', '6', ' ', '(', 'K', 'H', 'T', 'M', 'L', ',', ' ', 'l', 'i', 'k', 'e', ' ', 'G', 'e', 'c', 'k', 'o', ')', ' ', 'C', 'h', 'r', 'o', 'm', 'e', '/', '1', '2', '2', '.', '0', '.', '0', '.', '0', ' ', 'S', 'a', 'f', 'a', 'r', 'i', '/', '5', '3', '7', '.', '3', '6', 0 };
const geocode_host: [*:0]const u16 = &.{ 'g', 'e', 'o', 'c', 'o', 'd', 'i', 'n', 'g', '-', 'a', 'p', 'i', '.', 'o', 'p', 'e', 'n', '-', 'm', 'e', 't', 'e', 'o', '.', 'c', 'o', 'm', 0 };
const forecast_host: [*:0]const u16 = &.{ 'a', 'p', 'i', '.', 'o', 'p', 'e', 'n', '-', 'm', 'e', 't', 'e', 'o', '.', 'c', 'o', 'm', 0 };
const http_get: [*:0]const u16 = &.{ 'G', 'E', 'T', 0 };
const wide_trim_chars = &[_]u16{ ' ', '\t', '\r' };

pub const Reading = WeatherData.Reading;

pub fn percentEncodeUtf8(input: []const u8, output: []u8) usize {
    if (output.len == 0) return 0;
    var written: usize = 0;
    for (input) |byte| {
        const unreserved = (byte >= 'A' and byte <= 'Z') or (byte >= 'a' and byte <= 'z') or
            (byte >= '0' and byte <= '9') or byte == '-' or byte == '.' or byte == '_' or byte == '~';
        const need: usize = if (unreserved) 1 else 3;
        if (need >= output.len - written) break;
        if (unreserved) {
            output[written] = byte;
            written += 1;
        } else {
            const hex = "0123456789ABCDEF";
            output[written] = '%';
            output[written + 1] = hex[byte >> 4];
            output[written + 2] = hex[byte & 0x0F];
            written += 3;
        }
    }
    output[written] = 0;
    return written;
}

pub fn parseCurrentCsv(csv: []const u8) ?Reading {
    var last: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, csv, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len != 0) last = trimmed;
    }
    const data_line = last orelse return null;
    var fields = std.mem.splitScalar(u8, data_line, ',');
    _ = fields.next() orelse return null;
    const temp_text = std.mem.trim(u8, fields.next() orelse return null, " \t\r");
    const code_text = std.mem.trim(u8, fields.next() orelse return null, " \t\r");
    const temperature = std.fmt.parseFloat(f64, temp_text) catch return null;
    const code = std.fmt.parseInt(i32, code_text, 10) catch return null;
    if (!std.math.isFinite(temperature)) return null;
    return .{ .temperature_c = temperature, .weather_code = code, .valid = true };
}

pub fn parseGeocodeJson(document: []const u8) ?struct { latitude: f64, longitude: f64 } {
    const results_at = std.mem.indexOf(u8, document, "\"results\"") orelse return null;
    const results = document[results_at..];
    const lat = findJsonNumber(results, "\"latitude\"") orelse return null;
    const lon = findJsonNumber(results, "\"longitude\"") orelse return null;
    return .{ .latitude = lat, .longitude = lon };
}

fn findJsonNumber(document: []const u8, key: []const u8) ?f64 {
    const at = std.mem.indexOf(u8, document, key) orelse return null;
    const colon = std.mem.indexOfScalarPos(u8, document, at + key.len, ':') orelse return null;
    var start = colon + 1;
    while (start < document.len and (document[start] == ' ' or document[start] == '\t')) : (start += 1) {}
    var end = start;
    while (end < document.len and (std.ascii.isDigit(document[end]) or document[end] == '-' or document[end] == '+' or document[end] == '.' or document[end] == 'e' or document[end] == 'E')) : (end += 1) {}
    if (end == start) return null;
    return std.fmt.parseFloat(f64, document[start..end]) catch null;
}

const Settings = struct {
    city: [128]u16 = @splat(0),
    has_value: bool = false,
    coordinates: bool = false,
};

fn isInvalidHandle(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle) == error_invalid_handle;
}

fn weatherSettingsPath(output: []u16) ?[*:0]const u16 {
    if (output.len == 0) return null;
    @memset(output, 0);
    var executable: [max_path]u16 = @splat(0);
    const length = GetModuleFileNameW(null, &executable, max_path);
    if (length == 0 or length >= max_path) return null;
    var folder_end: ?usize = null;
    for (executable[0..length], 0..) |unit, index| {
        if (unit == '\\' or unit == '/') folder_end = index + 1;
    }
    const prefix_len = folder_end orelse return null;
    const file_name = "weather.txt";
    if (prefix_len + file_name.len >= output.len) return null;
    @memcpy(output[0..prefix_len], executable[0..prefix_len]);
    for (file_name, 0..) |byte, index| output[prefix_len + index] = byte;
    output[prefix_len + file_name.len] = 0;
    return @ptrCast(output.ptr);
}

fn parseWideNumber(input: []const u16) ?f64 {
    if (input.len == 0 or input.len >= 64) return null;
    var ascii: [64]u8 = undefined;
    for (input, 0..) |unit, index| {
        if (unit > 0x7F) return null;
        ascii[index] = @intCast(unit);
    }
    return std.fmt.parseFloat(f64, ascii[0..input.len]) catch null;
}

fn parseCoordinates(line: []const u16) ?struct { latitude: f64, longitude: f64 } {
    const comma = std.mem.indexOfScalar(u16, line, ',') orelse return null;
    const latitude = parseWideNumber(std.mem.trim(u16, line[0..comma], wide_trim_chars)) orelse return null;
    const longitude = parseWideNumber(std.mem.trim(u16, line[comma + 1 ..], wide_trim_chars)) orelse return null;
    if (!std.math.isFinite(latitude) or !std.math.isFinite(longitude) or
        @abs(latitude) > 90 or @abs(longitude) > 180) return null;
    return .{ .latitude = latitude, .longitude = longitude };
}

fn readSettings() Settings {
    var result: Settings = .{};
    var path: [max_path]u16 = @splat(0);
    const zpath = weatherSettingsPath(&path) orelse return result;
    const file = CreateFileW(zpath, generic_read, file_share_read, null, open_existing, file_attribute_normal, null);
    if (isInvalidHandle(file)) return result;
    defer _ = CloseHandle(file);

    var bytes: [1024]u8 = @splat(0);
    var read: DWORD = 0;
    if (ReadFile(file, &bytes, bytes.len - 1, &read, null) == 0) return result;
    bytes[read] = 0;
    var wide: [1024]u16 = @splat(0);
    const wide_count = MultiByteToWideChar(cp_utf8, 0, @ptrCast(&bytes), -1, &wide, wide.len);
    if (wide_count <= 0) return result;

    var content: []const u16 = wide[0..@intCast(wide_count - 1)];
    if (content.len != 0 and content[0] == 0xFEFF) content = content[1..];
    var cursor: usize = 0;
    while (cursor < content.len) {
        var end = cursor;
        while (end < content.len and content[end] != '\n') : (end += 1) {}
        var line = std.mem.trim(u16, content[cursor..end], wide_trim_chars);
        if (line.len != 0 and line[0] != '#') {
            const count = @min(line.len, result.city.len - 1);
            @memcpy(result.city[0..count], line[0..count]);
            result.city[count] = 0;
            line = result.city[0..count];
            result.has_value = count != 0;
            result.coordinates = parseCoordinates(line) != null;
            return result;
        }
        if (end == content.len) break;
        cursor = end + 1;
    }
    return result;
}

fn wideToUtf8(input: [*:0]const u16, output: []u8) ?[]const u8 {
    if (output.len == 0) return null;
    const count = WideCharToMultiByte(cp_utf8, 0, input, -1, output.ptr, @intCast(output.len), null, null);
    if (count <= 0 or count > output.len) return null;
    return output[0..@intCast(count - 1)];
}

fn asciiToWideZ(input: []const u8, output: []u16) ?[*:0]const u16 {
    if (output.len == 0 or input.len >= output.len) return null;
    for (input, 0..) |byte, index| {
        if (byte > 0x7F) return null;
        output[index] = byte;
    }
    output[input.len] = 0;
    return @ptrCast(output.ptr);
}

fn httpGet(host: [*:0]const u16, path: []const u16, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    if (path.len == 0) return false;
    var terminated_path: [1024]u16 = @splat(0);
    if (path.len >= terminated_path.len) return false;
    @memcpy(terminated_path[0..path.len], path);
    const session = WinHttpOpen(http_agent, winhttp_access_type_automatic_proxy, null, null, 0) orelse return false;
    defer _ = WinHttpCloseHandle(session);
    _ = WinHttpSetTimeouts(session, 10_000, 10_000, 10_000, 10_000);
    const connection = WinHttpConnect(session, host, internet_default_https_port, 0) orelse return false;
    defer _ = WinHttpCloseHandle(connection);
    const request = WinHttpOpenRequest(connection, http_get, @ptrCast(&terminated_path), null, null, null, winhttp_flag_secure, 0) orelse return false;
    defer _ = WinHttpCloseHandle(request);
    if (WinHttpSendRequest(request, null, 0, null, 0, 0, 0) == 0 or WinHttpReceiveResponse(request, null) == 0) return false;

    var status: DWORD = 0;
    var status_size: DWORD = @sizeOf(DWORD);
    if (WinHttpQueryHeaders(request, winhttp_query_status_code | winhttp_query_flag_number, null, &status, &status_size, null) == 0 or status != 200) return false;

    var used: usize = 0;
    while (used + 1 < output.len) {
        var available: DWORD = 0;
        if (WinHttpQueryDataAvailable(request, &available) == 0) return false;
        if (available == 0) break;
        const chunk: DWORD = @intCast(@min(@as(usize, available), output.len - used - 1));
        if (chunk == 0) break;
        var read: DWORD = 0;
        if (WinHttpReadData(request, output[used..].ptr, chunk, &read) == 0) return false;
        if (read == 0) break;
        used += read;
    }
    output[used] = 0;
    return true;
}

pub const poll_interval_ms: DWORD = 15 * 60 * 1000;
pub const retry_interval_ms: DWORD = 60 * 1000;

/// Owns the weather polling thread and publishes the last successful reading under a lock.
/// The first fetch happens immediately; failed fetches keep the prior reading and retry in one minute.
pub const WeatherReader = struct {
    stop_event: HANDLE = null,
    thread: HANDLE = null,
    lock: CriticalSection = .{ .debug_info = null, .lock_count = 0, .recursion_count = 0, .owning_thread = null, .lock_semaphore = null, .spin_count = 0 },
    lock_ready: bool = false,
    have_reading: bool = false,
    temperature_c: f64 = 0,
    code: i32 = -1,
    revision: u64 = 0,
    last_attempt_succeeded: bool = false,
    last_success_ms: u64 = 0,
    attempt_succeeded_this_run: bool = false,
    reported_no_location: bool = false,

    pub fn start(self: *WeatherReader) bool {
        if (self.thread != null) return true;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        if (self.stop_event == null) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            _ = CloseHandle(self.stop_event);
            self.stop_event = null;
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        return true;
    }

    pub fn stop(self: *WeatherReader) void {
        if (self.stop_event) |event| _ = SetEvent(event);
        if (self.thread) |thread| {
            _ = WaitForSingleObject(thread, infinite);
            _ = CloseHandle(thread);
            self.thread = null;
        }
        if (self.stop_event) |event| {
            _ = CloseHandle(event);
            self.stop_event = null;
        }
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
    }

    pub fn getSnapshot(self: *WeatherReader) ?WeatherData.SourceSnapshot {
        if (!self.lock_ready) return null;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        return .{
            .reading = .{ .temperature_c = self.temperature_c, .weather_code = self.code, .valid = self.have_reading },
            .has_reading = self.have_reading,
            .revision = self.revision,
            .last_attempt_succeeded = self.last_attempt_succeeded,
            .last_success_ms = self.last_success_ms,
        };
    }

    fn threadEntry(parameter: ?*anyopaque) callconv(.winapi) DWORD {
        const self: *WeatherReader = @ptrCast(@alignCast(parameter orelse return 0));
        self.run();
        return 0;
    }

    fn run(self: *WeatherReader) void {
        var winrt_api = WinRtApi.load();
        var initialized_winrt = false;
        if (winrt_api) |loaded| {
            if (loaded.initialize(1) >= 0) {
                initialized_winrt = true;
            } else {
                winrt_api = null;
            }
        }
        defer if (initialized_winrt) {
            if (winrt_api) |loaded| loaded.uninitialize();
        };

        var resolved_city: [128]u8 = @splat(0);
        var unresolved_city: [256]u8 = @splat(0);
        var latitude: f64 = 0;
        var longitude: f64 = 0;
        var wait_ms: DWORD = 0;
        while (true) {
            if (wait_ms != 0 and WaitForSingleObject(self.stop_event, wait_ms) == wait_object_0) break;
            if (WaitForSingleObject(self.stop_event, 0) == wait_object_0) break;
            wait_ms = self.refresh(&resolved_city, &unresolved_city, &latitude, &longitude, winrt_api);
        }
    }

    fn refresh(self: *WeatherReader, resolved_city: *[128]u8, unresolved_city: *[256]u8, latitude: *f64, longitude: *f64, winrt_api: ?WinRtApi) DWORD {
        self.attempt_succeeded_this_run = false;
        const wait_ms = self.refreshAttempt(resolved_city, unresolved_city, latitude, longitude, winrt_api);
        if (!self.attempt_succeeded_this_run) self.publishAttemptFailure();
        return wait_ms;
    }

    fn refreshAttempt(self: *WeatherReader, resolved_city: *[128]u8, unresolved_city: *[256]u8, latitude: *f64, longitude: *f64, winrt_api: ?WinRtApi) DWORD {
        const settings = readSettings();
        if (!settings.has_value) {
            unresolved_city[0] = 0;
            const located = if (winrt_api) |api| locationFromWindows(&api, latitude, longitude, self.stop_event) else false;
            if (!located) {
                if (!self.reported_no_location) {
                    Log.logAndPrint("weather: Windows location did not provide a position\n");
                    self.reported_no_location = true;
                }
                return retry_interval_ms;
            }
            const marker = "<windows-location>";
            @memcpy(resolved_city[0..marker.len], marker);
            resolved_city[marker.len] = 0;
        }

        if (settings.coordinates) {
            unresolved_city[0] = 0;
            const point = parseCoordinates(std.mem.sliceTo(&settings.city, 0)) orelse return retry_interval_ms;
            latitude.* = point.latitude;
            longitude.* = point.longitude;
            @memcpy(resolved_city[0..9], "<lat,lon>");
            resolved_city[9] = 0;
        } else if (settings.has_value) {
            var city_utf8: [256]u8 = @splat(0);
            const city = wideToUtf8(@ptrCast(&settings.city), &city_utf8) orelse return retry_interval_ms;
            if (std.mem.eql(u8, city, std.mem.sliceTo(unresolved_city, 0))) return poll_interval_ms;
            if (!std.mem.eql(u8, city, std.mem.sliceTo(resolved_city, 0))) {
                var encoded: [768]u8 = @splat(0);
                const encoded_len = percentEncodeUtf8(city, &encoded);
                var geocode_url: [900]u8 = undefined;
                const url_bytes = std.fmt.bufPrint(&geocode_url, "/v1/search?name={s}&count=1&language=zh&format=json", .{encoded[0..encoded_len]}) catch return retry_interval_ms;
                var wide_url: [1024]u16 = @splat(0);
                const url = asciiToWideZ(url_bytes, &wide_url) orelse return retry_interval_ms;
                var body: [8192]u8 = @splat(0);
                if (!httpGet(geocode_host, url[0..url_bytes.len], &body)) {
                    Log.logAndPrint("weather: geocoding request failed; retrying\n");
                    return retry_interval_ms;
                }
                const point = parseGeocodeJson(std.mem.sliceTo(&body, 0)) orelse {
                    copyBytesZ(unresolved_city, city);
                    var message: [512]u8 = undefined;
                    const text = std.fmt.bufPrint(&message, "weather: configured city \"{s}\" was not found; check weather.txt beside IslandBar.exe\n", .{city}) catch "weather: configured city was not found\n";
                    Log.logAndPrint(text);
                    return poll_interval_ms;
                };
                latitude.* = point.latitude;
                longitude.* = point.longitude;
                copyBytesZ(resolved_city, city);
                unresolved_city[0] = 0;
            }
        }

        var forecast_url: [256]u8 = undefined;
        const url_bytes = std.fmt.bufPrint(&forecast_url, "/v1/forecast?latitude={d:.4}&longitude={d:.4}&current=temperature_2m,weather_code&format=csv&timezone=auto", .{ latitude.*, longitude.* }) catch return retry_interval_ms;
        var wide_url: [1024]u16 = @splat(0);
        const url = asciiToWideZ(url_bytes, &wide_url) orelse return retry_interval_ms;
        var body: [4096]u8 = @splat(0);
        if (!httpGet(forecast_host, url[0..url_bytes.len], &body)) {
            Log.logAndPrint("weather: forecast request failed; retrying\n");
            return retry_interval_ms;
        }
        const reading = parseCurrentCsv(std.mem.sliceTo(&body, 0)) orelse {
            Log.logAndPrint("weather: forecast response did not contain a reading\n");
            return retry_interval_ms;
        };

        if (settings.has_value) {
            const current_settings = readSettings();
            if (!current_settings.has_value or current_settings.coordinates != settings.coordinates or
                !std.mem.eql(u16, std.mem.sliceTo(&current_settings.city, 0), std.mem.sliceTo(&settings.city, 0)))
            {
                Log.logAndPrint("weather: discarded response for changed settings\n");
                return retry_interval_ms;
            }
        }
        self.publishSuccess(reading);
        Log.logAndPrint("weather: current conditions updated\n");
        return poll_interval_ms;
    }

    fn publishSuccess(self: *WeatherReader, reading: Reading) void {
        EnterCriticalSection(&self.lock);
        self.temperature_c = reading.temperature_c;
        self.code = reading.weather_code;
        self.have_reading = true;
        self.last_attempt_succeeded = true;
        self.last_success_ms = GetTickCount64();
        self.revision +%= 1;
        LeaveCriticalSection(&self.lock);
        self.attempt_succeeded_this_run = true;
    }

    fn publishAttemptFailure(self: *WeatherReader) void {
        EnterCriticalSection(&self.lock);
        self.last_attempt_succeeded = false;
        self.revision +%= 1;
        LeaveCriticalSection(&self.lock);
    }
};

fn copyBytesZ(destination: []u8, source: []const u8) void {
    if (destination.len == 0) return;
    const count = @min(source.len, destination.len - 1);
    @memcpy(destination[0..count], source[0..count]);
    destination[count] = 0;
}

const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
const ComHeader = extern struct { vtable: [*]const ?*anyopaque };
const geolocator_class: [*:0]const u16 = &.{ 'W', 'i', 'n', 'd', 'o', 'w', 's', '.', 'D', 'e', 'v', 'i', 'c', 'e', 's', '.', 'G', 'e', 'o', 'l', 'o', 'c', 'a', 't', 'i', 'o', 'n', '.', 'G', 'e', 'o', 'l', 'o', 'c', 'a', 't', 'o', 'r', 0 };
const iid_activation_factory = Guid{ .data1 = 0x00000035, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const iid_async_info = Guid{ .data1 = 0x00000036, .data2 = 0, .data3 = 0, .data4 = .{ 0xC0, 0, 0, 0, 0, 0, 0, 0x46 } };
const iid_geolocator_statics = Guid{ .data1 = 0x9A8E7571, .data2 = 0x2DF5, .data3 = 0x4591, .data4 = .{ 0x9F, 0x87, 0xEB, 0x5F, 0xD8, 0x94, 0xE9, 0xB7 } };
const iid_geocoordinate_with_point = Guid{ .data1 = 0xFEEA0525, .data2 = 0xD22C, .data3 = 0x4D46, .data4 = .{ 0xB5, 0x27, 0x0B, 0x96, 0x06, 0x6F, 0xC7, 0xDB } };
const BasicGeoposition = extern struct { latitude: f64, longitude: f64, altitude: f64 };

const WinRtApi = struct {
    module: HANDLE,
    create_string: *const fn ([*]const u16, u32, *HANDLE) callconv(.winapi) i32,
    delete_string: *const fn (HANDLE) callconv(.winapi) i32,
    get_factory: *const fn (HANDLE, *const Guid, *HANDLE) callconv(.winapi) i32,
    initialize: *const fn (u32) callconv(.winapi) i32,
    uninitialize: *const fn () callconv(.winapi) void,

    fn load() ?WinRtApi {
        const module = GetModuleHandleW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse
            LoadLibraryW(&.{ 'c', 'o', 'm', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l', 0 }) orelse return null;
        const create = GetProcAddress(module, "WindowsCreateString") orelse return null;
        const delete = GetProcAddress(module, "WindowsDeleteString") orelse return null;
        const factory = GetProcAddress(module, "RoGetActivationFactory") orelse return null;
        const initialize = GetProcAddress(module, "RoInitialize") orelse return null;
        const uninitialize = GetProcAddress(module, "RoUninitialize") orelse return null;
        return .{
            .module = module,
            .create_string = @ptrCast(create),
            .delete_string = @ptrCast(delete),
            .get_factory = @ptrCast(factory),
            .initialize = @ptrCast(initialize),
            .uninitialize = @ptrCast(uninitialize),
        };
    }
};

fn comVtable(object: HANDLE) [*]const ?*anyopaque {
    return (@as(*const ComHeader, @ptrCast(@alignCast(object.?)))).vtable;
}

fn comRelease(object: HANDLE) void {
    const vtable = comVtable(object);
    const release: *const fn (*anyopaque) callconv(.winapi) u32 = @ptrCast(vtable[2] orelse return);
    _ = release(object.?);
}

fn queryInterface(object: HANDLE, iid: *const Guid, result: *HANDLE) bool {
    const vtable = comVtable(object);
    const query: *const fn (*anyopaque, *const Guid, *HANDLE) callconv(.winapi) i32 = @ptrCast(vtable[0] orelse return false);
    return query(object.?, iid, result) >= 0 and result.* != null;
}

fn awaitWinRtOperation(operation: HANDLE, timeout_ms: DWORD, stop_event: HANDLE) bool {
    var async_info: HANDLE = null;
    if (!queryInterface(operation, &iid_async_info, &async_info)) return false;
    defer comRelease(async_info);
    const info_vtable = comVtable(async_info);
    const get_status: *const fn (*anyopaque, *i32) callconv(.winapi) i32 = @ptrCast(info_vtable[7] orelse return false);
    var elapsed: DWORD = 0;
    while (elapsed <= timeout_ms) : (elapsed += 20) {
        if (stop_event != null and WaitForSingleObject(stop_event, 0) == wait_object_0) return false;
        var status: i32 = 0;
        if (get_status(async_info.?, &status) < 0) return false;
        if (status == 1) return true;
        if (status > 1) return false;
        Sleep(20);
    }
    return false;
}

fn winRtGetResults(operation: HANDLE, result: *anyopaque) bool {
    const vtable = comVtable(operation);
    const get_results: *const fn (*anyopaque, *anyopaque) callconv(.winapi) i32 = @ptrCast(vtable[8] orelse return false);
    return get_results(operation.?, result) >= 0;
}

fn locationFromWindows(api: *const WinRtApi, latitude: *f64, longitude: *f64, stop_event: HANDLE) bool {
    var class_name: HANDLE = null;
    if (api.create_string(@ptrCast(geolocator_class), @intCast(std.mem.span(geolocator_class).len), &class_name) < 0 or class_name == null) return false;
    defer _ = api.delete_string(class_name);

    var statics: HANDLE = null;
    if (api.get_factory(class_name, &iid_geolocator_statics, &statics) < 0 or statics == null) return false;
    defer comRelease(statics);
    const statics_vtable = comVtable(statics);
    const request_access: *const fn (*anyopaque, *HANDLE) callconv(.winapi) i32 = @ptrCast(statics_vtable[6] orelse return false);
    var access_operation: HANDLE = null;
    if (request_access(statics.?, &access_operation) < 0 or access_operation == null) return false;
    defer comRelease(access_operation);
    if (!awaitWinRtOperation(access_operation, 60_000, stop_event)) return false;
    var access_status: i32 = 0;
    if (!winRtGetResults(access_operation, @ptrCast(&access_status)) or access_status != 1) return false;

    var activation: HANDLE = null;
    if (api.get_factory(class_name, &iid_activation_factory, &activation) < 0 or activation == null) return false;
    defer comRelease(activation);
    const activation_vtable = comVtable(activation);
    const activate: *const fn (*anyopaque, *HANDLE) callconv(.winapi) i32 = @ptrCast(activation_vtable[6] orelse return false);
    var locator: HANDLE = null;
    if (activate(activation.?, &locator) < 0 or locator == null) return false;
    defer comRelease(locator);
    const locator_vtable = comVtable(locator);
    const set_accuracy: *const fn (*anyopaque, i32) callconv(.winapi) i32 = @ptrCast(locator_vtable[7] orelse return false);
    if (set_accuracy(locator.?, 0) < 0) return false;
    const get_position: *const fn (*anyopaque, i64, i64, *HANDLE) callconv(.winapi) i32 = @ptrCast(locator_vtable[14] orelse return false);
    var position_operation: HANDLE = null;
    if (get_position(locator.?, 36_000_000_000, 100_000_000, &position_operation) < 0 or position_operation == null) return false;
    defer comRelease(position_operation);
    if (!awaitWinRtOperation(position_operation, 12_000, stop_event)) return false;

    var position: HANDLE = null;
    if (!winRtGetResults(position_operation, @ptrCast(&position)) or position == null) return false;
    defer comRelease(position);
    const position_vtable = comVtable(position);
    const get_coordinate: *const fn (*anyopaque, *HANDLE) callconv(.winapi) i32 = @ptrCast(position_vtable[6] orelse return false);
    var coordinate: HANDLE = null;
    if (get_coordinate(position.?, &coordinate) < 0 or coordinate == null) return false;
    defer comRelease(coordinate);

    var point_coordinate: HANDLE = null;
    if (queryInterface(coordinate, &iid_geocoordinate_with_point, &point_coordinate)) {
        defer comRelease(point_coordinate);
        const point_vtable = comVtable(point_coordinate);
        const get_point: *const fn (*anyopaque, *HANDLE) callconv(.winapi) i32 = @ptrCast(point_vtable[6] orelse return false);
        var point: HANDLE = null;
        if (get_point(point_coordinate.?, &point) < 0 or point == null) return false;
        defer comRelease(point);
        const geo_point_vtable = comVtable(point);
        const get_position_value: *const fn (*anyopaque, *BasicGeoposition) callconv(.winapi) i32 = @ptrCast(geo_point_vtable[6] orelse return false);
        var value: BasicGeoposition = undefined;
        if (get_position_value(point.?, &value) < 0) return false;
        latitude.* = value.latitude;
        longitude.* = value.longitude;
        return true;
    }

    // Older Windows builds expose latitude and longitude directly on IGeocoordinate.
    const coordinate_vtable = comVtable(coordinate);
    const get_latitude: *const fn (*anyopaque, *f64) callconv(.winapi) i32 = @ptrCast(coordinate_vtable[6] orelse return false);
    const get_longitude: *const fn (*anyopaque, *f64) callconv(.winapi) i32 = @ptrCast(coordinate_vtable[7] orelse return false);
    return get_latitude(coordinate.?, latitude) >= 0 and get_longitude(coordinate.?, longitude) >= 0;
}

pub fn smokeCheck() bool {
    var encoded: [32]u8 = undefined;
    const encoded_len = percentEncodeUtf8("Beijing \xE5\x8C\x97", &encoded);
    if (!std.mem.eql(u8, encoded[0..encoded_len], "Beijing%20%E5%8C%97")) return false;
    const reading = parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,21.4,2\n") orelse return false;
    const point = parseGeocodeJson("{\"results\":[{\"latitude\":39.9,\"longitude\":116.4}]}") orelse return false;
    const configured_point = parseCoordinates(&.{ '3', '9', '.', '9', '0', '4', '2', ',', ' ', '1', '1', '6', '.', '4', '0', '7', '4' }) orelse return false;
    if (configured_point.latitude != 39.9042 or configured_point.longitude != 116.4074) return false;
    if (parseCoordinates(&.{ '9', '1', ',', '0' }) != null or parseCoordinates(&.{ '0', ',', '1', '8', '1' }) != null) return false;
    return reading.temperature_c == 21.4 and reading.weather_code == 2 and point.latitude == 39.9 and point.longitude == 116.4 and
        parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,broken,2\n") == null and
        parseCurrentCsv("time,temperature_2m\n2026-10-14T00:00,12.0\n") == null and
        parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,nan,2\n") == null;
}

test "weather source parsing rejects missing and non-finite response fields" {
    try std.testing.expect(parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,broken,2\n") == null);
    try std.testing.expect(parseCurrentCsv("time,temperature_2m\n2026-10-14T00:00,12.0\n") == null);
    try std.testing.expect(parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,nan,2\n") == null);
    const reading = parseCurrentCsv("time,temperature_2m,weather_code\n2026-10-14T00:00,-1.2,61\n").?;
    try std.testing.expect(reading.valid);
    try std.testing.expectEqual(@as(f64, -1.2), reading.temperature_c);
    try std.testing.expectEqual(@as(i32, 61), reading.weather_code);
}
