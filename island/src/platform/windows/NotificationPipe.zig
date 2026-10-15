const std = @import("std");
const MiniJson = @import("MiniJson");
const NotificationInput = @import("NotificationInput");
const Log = @import("Log");

pub const pipe_name: []const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', '.', 'N', 'o', 't', 'i', 'f', 'y' };
pub const max_message_bytes: usize = 64 * 1024;
const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const LPARAM = isize;

const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: HANDLE,
    lock_semaphore: HANDLE,
    spin_count: usize,
};

const SecurityAttributes = extern struct { length: DWORD, descriptor: ?*anyopaque, inherit: BOOL };
extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CancelSynchronousIo(thread: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn Sleep(milliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateFileW(name: [*:0]const u16, access: DWORD, share: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn ReadFile(file: HANDLE, buffer: [*]u8, count: DWORD, read: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn WriteFile(file: HANDLE, buffer: [*]const u8, count: DWORD, written: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
extern "kernel32" fn CreateNamedPipeW(name: [*:0]const u16, open_mode: DWORD, pipe_mode: DWORD, max_instances: DWORD, out_buffer: DWORD, in_buffer: DWORD, default_timeout: DWORD, attributes: ?*SecurityAttributes) callconv(.winapi) HANDLE;
extern "kernel32" fn ConnectNamedPipe(pipe: HANDLE, overlapped: ?*anyopaque) callconv(.winapi) BOOL;
extern "kernel32" fn DisconnectNamedPipe(pipe: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn FlushFileBuffers(file: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn GetNamedPipeClientProcessId(pipe: HANDLE, process_id: *DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn WaitNamedPipeW(name: [*:0]const u16, timeout: DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn SetNamedPipeHandleState(pipe: HANDLE, mode: *DWORD, max_collection_count: ?*DWORD, collect_data_timeout: ?*DWORD) callconv(.winapi) BOOL;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LocalFree(memory: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "advapi32" fn ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl: [*:0]const u16, revision: DWORD, descriptor: *?*anyopaque, descriptor_size: ?*DWORD) callconv(.winapi) BOOL;

const generic_read: DWORD = 0x80000000;
const generic_write: DWORD = 0x40000000;
const open_existing: DWORD = 3;
const pipe_access_duplex: DWORD = 0x3;
const pipe_type_message: DWORD = 0x4;
const pipe_readmode_message: DWORD = 0x2;
const pipe_wait: DWORD = 0;
const pipe_buffer_bytes: DWORD = 4096;
const wait_object_0: DWORD = 0;
const error_pipe_connected: DWORD = 535;
const error_file_not_found: DWORD = 2;
const error_sem_timeout: DWORD = 121;
const pipe_read_mode_message: DWORD = 2;
const invalid_handle_value: usize = std.math.maxInt(usize);
const pipe_prefix: [*:0]const u16 = &.{ '\\', '\\', '.', '\\', 'p', 'i', 'p', 'e', '\\', 0 };
const pipe_security_sddl: [*:0]const u16 = &.{ 'D', ':', '(', 'A', ';', ';', 'G', 'A', ';', ';', ';', 'W', 'D', ')', 0 };

const PipeSecurity = struct {
    descriptor: ?*anyopaque = null,
    attributes: SecurityAttributes = .{ .length = @sizeOf(SecurityAttributes), .descriptor = null, .inherit = 0 },
    error_code: DWORD = 0,

    fn init(self: *PipeSecurity) bool {
        if (ConvertStringSecurityDescriptorToSecurityDescriptorW(pipe_security_sddl, 1, &self.descriptor, null) == 0) {
            self.error_code = GetLastError();
            return false;
        }
        self.attributes.descriptor = self.descriptor;
        return true;
    }

    fn deinit(self: *PipeSecurity) void {
        if (self.descriptor) |descriptor| _ = LocalFree(descriptor);
        self.descriptor = null;
        self.attributes.descriptor = null;
    }
};

fn isInvalid(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle) == invalid_handle_value;
}

fn pipePath(name: []const u16, output: []u16) ?[*:0]const u16 {
    if (output.len == 0) return null;
    var used: usize = 0;
    for (pipe_prefix[0..9]) |unit| {
        if (used + 1 >= output.len) return null;
        output[used] = unit;
        used += 1;
    }
    for (name) |unit| {
        if (unit == 0) break;
        if (used + 1 >= output.len) return null;
        output[used] = unit;
        used += 1;
    }
    output[used] = 0;
    return @ptrCast(output.ptr);
}

fn readAll(pipe: HANDLE, buffer: []u8) bool {
    var offset: usize = 0;
    while (offset < buffer.len) {
        var read: DWORD = 0;
        if (ReadFile(pipe, buffer[offset..].ptr, @intCast(buffer.len - offset), &read, null) == 0 or read == 0) return false;
        offset += read;
    }
    return true;
}

fn writeAll(pipe: HANDLE, buffer: []const u8) bool {
    var offset: usize = 0;
    while (offset < buffer.len) {
        var written: DWORD = 0;
        if (WriteFile(pipe, buffer[offset..].ptr, @intCast(buffer.len - offset), &written, null) == 0 or written == 0) return false;
        offset += written;
    }
    return true;
}

pub fn writeFrame(pipe: HANDLE, payload: []const u8) bool {
    if (isInvalid(pipe) or payload.len > max_message_bytes) return false;
    const length: u32 = @intCast(payload.len);
    const header = [_]u8{
        @truncate(length),
        @truncate(length >> 8),
        @truncate(length >> 16),
        @truncate(length >> 24),
    };
    if (!writeAll(pipe, &header)) return false;
    return payload.len == 0 or writeAll(pipe, payload);
}

pub fn readFrame(pipe: HANDLE, output: []u8) bool {
    if (isInvalid(pipe) or output.len == 0) return false;
    output[0] = 0;
    var header: [4]u8 = undefined;
    if (!readAll(pipe, &header)) return false;
    const length: usize = @as(usize, header[0]) | (@as(usize, header[1]) << 8) |
        (@as(usize, header[2]) << 16) | (@as(usize, header[3]) << 24);
    if (length == 0 or length > max_message_bytes) return false;
    const wanted = @min(length, output.len - 1);
    if (!readAll(pipe, output[0..wanted])) return false;
    output[wanted] = 0;
    var remaining = length - wanted;
    var scratch: [512]u8 = undefined;
    while (remaining > 0) {
        const chunk = @min(remaining, scratch.len);
        if (!readAll(pipe, scratch[0..chunk])) return false;
        remaining -= chunk;
    }
    return true;
}

pub const NotificationServer = struct {
    stop_event: HANDLE = null,
    thread: HANDLE = null,
    name: [256]u16 = @splat(0),
    running: bool = false,
    lock: CriticalSection = .{ .debug_info = null, .lock_count = 0, .recursion_count = 0, .owning_thread = null, .lock_semaphore = null, .spin_count = 0 },
    lock_ready: bool = false,
    queue: [64]NotificationInput.Message = @splat(.{}),
    queue_count: usize = 0,
    received_count: i32 = 0,
    rejected_count: i32 = 0,

    pub fn start(self: *NotificationServer, name: []const u16) bool {
        if (self.isRunning()) return true;
        if (pipePath(name, &self.name) == null) return false;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        if (self.stop_event == null) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        var thread_id: DWORD = 0;
        self.thread = CreateThread(null, 0, threadEntry, self, 0, &thread_id);
        if (self.thread == null) {
            _ = CloseHandle(self.stop_event);
            self.stop_event = null;
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        for (0..100) |_| {
            if (self.isRunning()) return true;
            if (WaitForSingleObject(self.thread, 0) == wait_object_0) break;
            Sleep(5);
        }
        if (self.isRunning()) return true;
        self.stop();
        return false;
    }

    pub fn stop(self: *NotificationServer) void {
        if (self.stop_event != null) _ = SetEvent(self.stop_event);
        if (self.thread != null) {
            // The listener blocks in synchronous ConnectNamedPipe. Cancel the
            // worker's pending I/O so it can observe stop_event and release its
            // own pipe handle before the lock and context go away. Keep the
            // short connect poke as a fallback for drivers/runtimes that do not
            // cancel that particular wait.
            while (WaitForSingleObject(self.thread, 0) != wait_object_0) {
                _ = CancelSynchronousIo(self.thread);
                if (WaitNamedPipeW(@ptrCast(&self.name), 50) != 0) {
                    const wake = CreateFileW(@ptrCast(&self.name), generic_read | generic_write, 0, null, open_existing, 0, null);
                    if (!isInvalid(wake)) _ = CloseHandle(wake);
                }
                _ = WaitForSingleObject(self.thread, 20);
            }
            _ = CloseHandle(self.thread);
            self.thread = null;
        }
        if (self.stop_event != null) {
            _ = CloseHandle(self.stop_event);
            self.stop_event = null;
        }
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
        @atomicStore(bool, &self.running, false, .release);
    }

    pub fn isRunning(self: *const NotificationServer) bool {
        return @atomicLoad(bool, &self.running, .acquire);
    }

    pub fn take(self: *NotificationServer, output: *NotificationInput.Message) bool {
        if (!self.lock_ready) return false;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        if (self.queue_count == 0) return false;
        output.* = self.queue[0];
        for (1..self.queue_count) |index| self.queue[index - 1] = self.queue[index];
        self.queue_count -= 1;
        return true;
    }

    pub fn receivedCount(self: *const NotificationServer) i64 {
        return @atomicLoad(i32, &self.received_count, .acquire);
    }

    pub fn rejectedCount(self: *const NotificationServer) i64 {
        return @atomicLoad(i32, &self.rejected_count, .acquire);
    }

    fn enqueue(self: *NotificationServer, notification: NotificationInput.Message) void {
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        if (self.queue_count < self.queue.len) {
            self.queue[self.queue_count] = notification;
            self.queue_count += 1;
        } else {
            for (1..self.queue_count) |index| self.queue[index - 1] = self.queue[index];
            self.queue[self.queue_count - 1] = notification;
        }
    }

    fn run(self: *NotificationServer) void {
        var security = PipeSecurity{};
        const security_ready = security.init();
        defer security.deinit();
        if (!security_ready) {
            var message: [128]u8 = undefined;
            const line = std.fmt.bufPrint(&message, "notification pipe: security descriptor setup failed (win32 {d}); using the process default ACL", .{security.error_code}) catch "notification pipe: security descriptor setup failed";
            Log.logLine(line);
        }
        while (WaitForSingleObject(self.stop_event, 0) != wait_object_0) {
            const pipe = CreateNamedPipeW(@ptrCast(&self.name), pipe_access_duplex, pipe_type_message | pipe_readmode_message | pipe_wait, 1, pipe_buffer_bytes, pipe_buffer_bytes, 0, if (security_ready) &security.attributes else null);
            if (isInvalid(pipe)) {
                Sleep(200);
                continue;
            }
            @atomicStore(bool, &self.running, true, .release);
            const connected = ConnectNamedPipe(pipe, null) != 0;
            const connect_error = if (connected) 0 else GetLastError();
            const client_present = connected or connect_error == error_pipe_connected;
            if (WaitForSingleObject(self.stop_event, 0) == wait_object_0) {
                _ = DisconnectNamedPipe(pipe);
                _ = CloseHandle(pipe);
                break;
            }
            if (!client_present) {
                _ = CloseHandle(pipe);
                continue;
            }

            var request: [max_message_bytes]u8 = @splat(0);
            if (readFrame(pipe, &request)) {
                if (NotificationInput.Message.fromJson(&request)) |notification_value| {
                    var notification = notification_value;
                    var client_pid: DWORD = 0;
                    if (GetNamedPipeClientProcessId(pipe, &client_pid) != 0) notification.sender_pid = client_pid;
                    self.enqueue(notification);
                    const received = @atomicRmw(i32, &self.received_count, .Add, 1, .seq_cst) + 1;
                    var response: [96]u8 = undefined;
                    const response_text = std.fmt.bufPrint(&response, "{{\"ok\":1,\"received\":{d}}}", .{received}) catch "{}";
                    _ = writeFrame(pipe, response_text);
                } else {
                    _ = @atomicRmw(i32, &self.rejected_count, .Add, 1, .seq_cst);
                    _ = writeFrame(pipe, "{\"ok\":0,\"error\":\"no title or body\"}");
                }
            } else {
                _ = @atomicRmw(i32, &self.rejected_count, .Add, 1, .seq_cst);
            }
            _ = FlushFileBuffers(pipe);
            _ = DisconnectNamedPipe(pipe);
            _ = CloseHandle(pipe);
        }
        @atomicStore(bool, &self.running, false, .release);
    }
};

fn threadEntry(context: ?*anyopaque) callconv(.winapi) DWORD {
    const server: *NotificationServer = @ptrCast(@alignCast(context orelse return 0));
    server.run();
    return 0;
}

/// Sends one notification and waits for the bar's acknowledgement.
pub fn sendNotification(notification: *const NotificationInput.Message, name: []const u16, response_output: ?[]u8, connect_timeout_ms: DWORD) bool {
    var full_name: [256]u16 = @splat(0);
    const name_z = pipePath(name, &full_name) orelse return false;
    const waited = WaitNamedPipeW(name_z, connect_timeout_ms) != 0;
    const wait_error = if (waited) 0 else GetLastError();
    if (!waited and wait_error != error_file_not_found) {
        if (response_output) |output| {
            const reason = if (wait_error == error_sem_timeout) "listener busy or not accepting" else "WaitNamedPipe failed";
            setErrorResponse(output, reason, wait_error);
        }
        return false;
    }

    // WaitNamedPipe can report ERROR_FILE_NOT_FOUND when the listener creates
    // its first instance at the same time. Try opening the instance directly in
    // that case; CreateFile is the authoritative connection attempt.
    const pipe = CreateFileW(name_z, generic_read | generic_write, 0, null, open_existing, 0, null);
    if (isInvalid(pipe)) {
        if (response_output) |output| {
            const error_code = GetLastError();
            const reason = if (wait_error == error_file_not_found and error_code == error_file_not_found)
                "no listener (is the bar running?)"
            else
                "CreateFile failed";
            setErrorResponse(output, reason, error_code);
        }
        return false;
    }
    defer _ = CloseHandle(pipe);
    var mode: DWORD = pipe_read_mode_message;
    _ = SetNamedPipeHandleState(pipe, &mode, null, null);
    var payload: [max_message_bytes]u8 = @splat(0);
    const json = notification.toJson(&payload) orelse return false;
    if (!writeFrame(pipe, json)) return false;
    var response: [1024]u8 = @splat(0);
    if (!readFrame(pipe, &response)) return false;
    if (response_output) |output| copyString(output, &response);
    return (MiniJson.getInt(&response, "ok") orelse 0) != 0;
}

fn copyString(output: []u8, source: []const u8) void {
    if (output.len == 0) return;
    const input = source[0 .. std.mem.indexOfScalar(u8, source, 0) orelse source.len];
    const count = @min(input.len, output.len - 1);
    @memcpy(output[0..count], input[0..count]);
    output[count] = 0;
}

fn setErrorResponse(output: []u8, reason: []const u8, code: DWORD) void {
    if (output.len == 0) return;
    const formatted = std.fmt.bufPrint(output[0 .. output.len - 1], "{s} (win32 {d})", .{ reason, code }) catch return;
    output[formatted.len] = 0;
}

pub fn smokeCheck() bool {
    if (max_message_bytes != 65536 or pipe_name.len != 16) return pipeSmokeFailure("constant mismatch");

    const test_name: []const u16 = &.{ 'I', 's', 'l', 'a', 'n', 'd', 'B', 'a', 'r', '.', 'N', 'o', 't', 'i', 'f', 'y', '.', 'S', 'm', 'o', 'k', 'e' };
    var server = NotificationServer{};
    if (!server.start(test_name)) return pipeSmokeFailure("server start failed");
    defer server.stop();

    var server_label: [300]u8 = undefined;
    var client_label: [300]u8 = undefined;
    const server_name = asciiWideName(&server.name, &server_label);
    var client_name_buffer: [256]u16 = @splat(0);
    const client_name_z = pipePath(test_name, &client_name_buffer) orelse return pipeSmokeFailure("client pipe name overflowed");
    const client_name = asciiWideName(std.mem.span(client_name_z), &client_label);
    if (!std.mem.eql(u8, server_name, client_name)) return pipeSmokeFailure("client and server pipe paths differ");

    var sent = NotificationInput.Message{};
    @memcpy(sent.title[0..9], "self-test");
    @memcpy(sent.app[0..5], "smoke");
    var response: [128]u8 = @splat(0);
    if (!sendNotification(&sent, test_name, &response, 1000)) {
        var message: [256]u8 = undefined;
        const detail = std.fmt.bufPrint(&message, "send failed to {s}: {s}", .{
            client_name,
            std.mem.sliceTo(&response, 0),
        }) catch "send failed";
        return pipeSmokeFailure(detail);
    }

    var received = NotificationInput.Message{};
    if (!server.take(&received)) return pipeSmokeFailure("server queue was empty after acknowledgement");
    if (!std.mem.eql(u8, received.title[0..9], "self-test") or
        !std.mem.eql(u8, received.app[0..5], "smoke") or
        server.receivedCount() != 1 or response[0] != '{')
    {
        return pipeSmokeFailure("acknowledged message did not match the submitted notification");
    }
    return true;
}

fn asciiWideName(wide: []const u16, output: []u8) []const u8 {
    var count: usize = 0;
    while (count < wide.len and wide[count] != 0 and count < output.len) : (count += 1) {
        output[count] = if (wide[count] <= 0x7f) @intCast(wide[count]) else '?';
    }
    return output[0..count];
}

fn pipeSmokeFailure(reason: []const u8) bool {
    var message: [256]u8 = undefined;
    const line = std.fmt.bufPrint(&message, "notification pipe self-test: {s}", .{reason}) catch "notification pipe self-test failed";
    Log.logAndPrint(line);
    return false;
}
