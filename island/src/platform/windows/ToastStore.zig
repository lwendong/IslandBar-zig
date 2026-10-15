const std = @import("std");
const NotificationInput = @import("NotificationInput");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const BOOL = i32;
const sqlite_ok: i32 = 0;
const sqlite_row: i32 = 100;
const sqlite_done: i32 = 101;
const sqlite_open_read_only: i32 = 1;
const max_payload_bytes: usize = 64 * 1024;

const SqliteDb = opaque {};
const SqliteStmt = opaque {};

extern "kernel32" fn LoadLibraryW(name: [*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn FreeLibrary(module: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn GetProcAddress(module: HANDLE, name: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GetEnvironmentVariableW(name: [*:0]const u16, output: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*:0]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*:0]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;

const SqliteApi = struct {
    module: HANDLE = null,
    open_v2: ?*const fn ([*:0]const u8, *?*SqliteDb, i32, ?[*:0]const u8) callconv(.c) i32 = null,
    close: ?*const fn (*SqliteDb) callconv(.c) i32 = null,
    prepare_v2: ?*const fn (*SqliteDb, [*:0]const u8, i32, *?*SqliteStmt, ?*?[*:0]const u8) callconv(.c) i32 = null,
    step: ?*const fn (*SqliteStmt) callconv(.c) i32 = null,
    finalize: ?*const fn (*SqliteStmt) callconv(.c) i32 = null,
    bind_int64: ?*const fn (*SqliteStmt, i32, i64) callconv(.c) i32 = null,
    column_int64: ?*const fn (*SqliteStmt, i32) callconv(.c) i64 = null,
    column_text: ?*const fn (*SqliteStmt, i32) callconv(.c) ?[*:0]const u8 = null,
    column_blob: ?*const fn (*SqliteStmt, i32) callconv(.c) ?*const anyopaque = null,
    column_bytes: ?*const fn (*SqliteStmt, i32) callconv(.c) i32 = null,
};

fn resolve(module: HANDLE, comptime Function: type, name: [*:0]const u8) ?Function {
    const address = GetProcAddress(module, name) orelse return null;
    return @ptrCast(@alignCast(address));
}

fn asciiEqlIgnoreCase(left: []const u8, right: []const u8) bool {
    if (left.len != right.len) return false;
    for (left, right) |a, b| if (std.ascii.toLower(a) != std.ascii.toLower(b)) return false;
    return true;
}

fn startsWithIgnoreCase(text: []const u8, prefix: []const u8) bool {
    return text.len >= prefix.len and asciiEqlIgnoreCase(text[0..prefix.len], prefix);
}

fn appendBytes(output: []u8, used_arg: usize, text: []const u8) usize {
    if (output.len == 0) return used_arg;
    var used = @min(used_arg, output.len - 1);
    const count = @min(text.len, output.len - used - 1);
    @memcpy(output[used .. used + count], text[0..count]);
    used += count;
    output[used] = 0;
    return used;
}

fn appendUtf8Codepoint(output: []u8, used_arg: usize, codepoint: u32) usize {
    if (codepoint == 0 or codepoint > 0x10ffff or (codepoint >= 0xd800 and codepoint <= 0xdfff)) return used_arg;
    var encoded: [4]u8 = undefined;
    var length: usize = undefined;
    if (codepoint < 0x80) {
        encoded[0] = @intCast(codepoint);
        length = 1;
    } else if (codepoint < 0x800) {
        encoded[0] = @intCast(0xc0 | (codepoint >> 6));
        encoded[1] = @intCast(0x80 | (codepoint & 0x3f));
        length = 2;
    } else if (codepoint < 0x10000) {
        encoded[0] = @intCast(0xe0 | (codepoint >> 12));
        encoded[1] = @intCast(0x80 | ((codepoint >> 6) & 0x3f));
        encoded[2] = @intCast(0x80 | (codepoint & 0x3f));
        length = 3;
    } else {
        encoded[0] = @intCast(0xf0 | (codepoint >> 18));
        encoded[1] = @intCast(0x80 | ((codepoint >> 12) & 0x3f));
        encoded[2] = @intCast(0x80 | ((codepoint >> 6) & 0x3f));
        encoded[3] = @intCast(0x80 | (codepoint & 0x3f));
        length = 4;
    }
    return appendBytes(output, used_arg, encoded[0..length]);
}

fn decodeEntities(text: []const u8, output: []u8) usize {
    if (output.len == 0) return 0;
    output[0] = 0;
    var used: usize = 0;
    var index: usize = 0;
    while (index < text.len and used + 1 < output.len) {
        if (text[index] != '&') {
            used = appendBytes(output, used, text[index .. index + 1]);
            index += 1;
            continue;
        }
        const rest = text[index..];
        if (startsWithIgnoreCase(rest, "&amp;")) {
            used = appendBytes(output, used, "&");
            index += 5;
        } else if (startsWithIgnoreCase(rest, "&lt;")) {
            used = appendBytes(output, used, "<");
            index += 4;
        } else if (startsWithIgnoreCase(rest, "&gt;")) {
            used = appendBytes(output, used, ">");
            index += 4;
        } else if (startsWithIgnoreCase(rest, "&quot;")) {
            used = appendBytes(output, used, "\"");
            index += 6;
        } else if (startsWithIgnoreCase(rest, "&apos;")) {
            used = appendBytes(output, used, "'");
            index += 6;
        } else if (rest.len >= 4 and rest[1] == '#') {
            var cursor = index + 2;
            var base: u32 = 10;
            if (cursor < text.len and (text[cursor] == 'x' or text[cursor] == 'X')) {
                cursor += 1;
                base = 16;
            }
            const digits_start = cursor;
            var codepoint: u32 = 0;
            var valid = true;
            while (cursor < text.len and text[cursor] != ';') : (cursor += 1) {
                const digit = switch (text[cursor]) {
                    '0'...'9' => @as(u32, text[cursor] - '0'),
                    'a'...'f' => @as(u32, text[cursor] - 'a' + 10),
                    'A'...'F' => @as(u32, text[cursor] - 'A' + 10),
                    else => {
                        valid = false;
                        break;
                    },
                };
                if (digit >= base or codepoint > (0x10ffff - digit) / base) {
                    valid = false;
                    break;
                }
                codepoint = codepoint * base + digit;
            }
            if (valid and cursor > digits_start and cursor < text.len and text[cursor] == ';') {
                used = appendUtf8Codepoint(output, used, codepoint);
                index = cursor + 1;
            } else {
                used = appendBytes(output, used, "&");
                index += 1;
            }
        } else {
            used = appendBytes(output, used, "&");
            index += 1;
        }
    }
    output[used] = 0;
    return used;
}

fn findByteIgnoreCase(text: []const u8, start: usize, needle: []const u8) ?usize {
    if (start > text.len or needle.len > text.len - start) return null;
    var index = start;
    while (index + needle.len <= text.len) : (index += 1) {
        if (asciiEqlIgnoreCase(text[index .. index + needle.len], needle)) return index;
    }
    return null;
}

const TextRange = struct { start: usize, end: usize };

fn nextTextElement(xml: []const u8, cursor: *usize) ?TextRange {
    var open: ?usize = null;
    var search = cursor.*;
    while (findByteIgnoreCase(xml, search, "<text")) |candidate| {
        const after = candidate + 5;
        if (after >= xml.len or xml[after] == '>' or xml[after] == ' ' or xml[after] == '\t' or xml[after] == '\r' or xml[after] == '\n') {
            open = candidate;
            break;
        }
        search = candidate + 5;
    }
    const open_start = open orelse return null;
    const gt_rel = std.mem.indexOfScalar(u8, xml[open_start..], '>') orelse return null;
    const content_start = open_start + gt_rel + 1;
    const close_start = findByteIgnoreCase(xml, content_start, "</text") orelse return null;
    const close_gt = std.mem.indexOfScalar(u8, xml[close_start..], '>') orelse return null;
    if (close_gt > 6 and xml[close_start + 6] != ' ' and xml[close_start + 6] != '\t' and xml[close_start + 6] != '\r' and xml[close_start + 6] != '\n') return null;
    cursor.* = close_start + close_gt + 1;
    return .{ .start = content_start, .end = close_start };
}

/// Extracts the first toast text node as the title and joins later nodes as the body.
pub fn toastTextFromXml(xml: []const u8, title: []u8, body: []u8) bool {
    if (title.len != 0) title[0] = 0;
    if (body.len != 0) body[0] = 0;
    if (xml.len == 0 or title.len == 0) return false;
    var cursor: usize = 0;
    var found: usize = 0;
    var body_used: usize = 0;
    while (nextTextElement(xml, &cursor)) |range| {
        if (found == 0) {
            _ = decodeEntities(xml[range.start..range.end], title);
        } else if (body.len != 0) {
            if (body_used != 0) body_used = appendBytes(body, body_used, " ");
            body_used = appendBytes(body, body_used, xml[range.start..range.end]);
            // Decode the joined raw text after it has been safely bounded.
            var decoded: [1024]u8 = undefined;
            const raw_len = std.mem.indexOfScalar(u8, body[0..body_used], 0) orelse body_used;
            const decoded_len = decodeEntities(body[0..raw_len], &decoded);
            @memcpy(body[0..decoded_len], decoded[0..decoded_len]);
            body[decoded_len] = 0;
            body_used = decoded_len;
        }
        found += 1;
    }
    return found > 0;
}

/// Reduces an AppUserModelID to a display name.
pub fn friendlyNameFromHandlerId(primary_id_arg: []const u16, output: []u16) void {
    if (output.len == 0) return;
    output[0] = 0;
    const nul = std.mem.indexOfScalar(u16, primary_id_arg, 0) orelse primary_id_arg.len;
    const primary_id = primary_id_arg[0..nul];
    if (primary_id.len == 0) return;
    var end = primary_id.len;
    for (primary_id, 0..) |unit, index| if (unit == '!' or unit == '_') {
        end = index;
        break;
    };
    const trimmed = primary_id[0..end];
    var name_start: usize = 0;
    for (trimmed, 0..) |unit, index| if (unit == '\\') {
        name_start = index + 1;
    };
    if (name_start == 0) for (trimmed, 0..) |unit, index| if (unit == '.') {
        name_start = index + 1;
    };
    if (name_start >= trimmed.len) name_start = 0;
    const count = @min(trimmed.len - name_start, output.len - 1);
    @memcpy(output[0..count], trimmed[name_start .. name_start + count]);
    output[count] = 0;
}

fn widePathToUtf8(path: []const u16, output: []u8) ?[]const u8 {
    if (output.len == 0) return null;
    const input_len = std.mem.indexOfScalar(u16, path, 0) orelse path.len;
    if (input_len >= path.len) return null;
    const wide: [*:0]const u16 = @ptrCast(path.ptr);
    const count = WideCharToMultiByte(65001, 0, wide, -1, output.ptr, @intCast(@min(output.len, @as(usize, std.math.maxInt(i32)))), null, null);
    if (count <= 0) return null;
    return output[0..@intCast(count - 1)];
}

fn utf8ToWide(input: []const u8, output: []u16) bool {
    if (output.len == 0) return false;
    var terminated: [256]u8 = @splat(0);
    const count = @min(input.len, terminated.len - 1);
    @memcpy(terminated[0..count], input[0..count]);
    return MultiByteToWideChar(65001, 0, @ptrCast(&terminated), -1, output.ptr, @intCast(@min(output.len, @as(usize, std.math.maxInt(i32))))) > 0;
}

fn appendWide(output: []u16, used_arg: usize, text: []const u16) usize {
    if (output.len == 0) return used_arg;
    var used = @min(used_arg, output.len - 1);
    const amount = @min(text.len, output.len - used - 1);
    @memcpy(output[used .. used + amount], text[0..amount]);
    used += amount;
    output[used] = 0;
    return used;
}

pub const ToastReader = struct {
    api: SqliteApi = .{},
    database: ?*SqliteDb = null,
    last_id: i64 = 0,
    taken: usize = 0,
    primed: bool = false,
    opened_path: [260]u16 = @splat(0),

    pub fn start(self: *ToastReader, database_path: ?[]const u16) bool {
        if (self.database != null) return true;
        self.api.module = LoadLibraryW(&.{ 'w', 'i', 'n', 's', 'q', 'l', 'i', 't', 'e', '3', '.', 'd', 'l', 'l', 0 });
        const module = self.api.module orelse return false;
        self.api.open_v2 = resolve(module, *const fn ([*:0]const u8, *?*SqliteDb, i32, ?[*:0]const u8) callconv(.c) i32, "sqlite3_open_v2");
        self.api.close = resolve(module, *const fn (*SqliteDb) callconv(.c) i32, "sqlite3_close");
        self.api.prepare_v2 = resolve(module, *const fn (*SqliteDb, [*:0]const u8, i32, *?*SqliteStmt, ?*?[*:0]const u8) callconv(.c) i32, "sqlite3_prepare_v2");
        self.api.step = resolve(module, *const fn (*SqliteStmt) callconv(.c) i32, "sqlite3_step");
        self.api.finalize = resolve(module, *const fn (*SqliteStmt) callconv(.c) i32, "sqlite3_finalize");
        self.api.bind_int64 = resolve(module, *const fn (*SqliteStmt, i32, i64) callconv(.c) i32, "sqlite3_bind_int64");
        self.api.column_int64 = resolve(module, *const fn (*SqliteStmt, i32) callconv(.c) i64, "sqlite3_column_int64");
        self.api.column_text = resolve(module, *const fn (*SqliteStmt, i32) callconv(.c) ?[*:0]const u8, "sqlite3_column_text");
        self.api.column_blob = resolve(module, *const fn (*SqliteStmt, i32) callconv(.c) ?*const anyopaque, "sqlite3_column_blob");
        self.api.column_bytes = resolve(module, *const fn (*SqliteStmt, i32) callconv(.c) i32, "sqlite3_column_bytes");
        if (self.api.open_v2 == null or self.api.prepare_v2 == null or self.api.step == null or self.api.column_text == null or self.api.column_blob == null) return false;

        var wide_path: [520]u16 = @splat(0);
        if (database_path) |specified| {
            const count = @min(specified.len, wide_path.len - 1);
            @memcpy(wide_path[0..count], specified[0..count]);
        } else {
            const env_name: [*:0]const u16 = &.{ 'L', 'O', 'C', 'A', 'L', 'A', 'P', 'P', 'D', 'A', 'T', 'A', 0 };
            const env_len = GetEnvironmentVariableW(env_name, &wide_path, wide_path.len);
            if (env_len == 0 or env_len >= wide_path.len) return false;
            const suffix: []const u16 = &.{ '\\', 'M', 'i', 'c', 'r', 'o', 's', 'o', 'f', 't', '\\', 'W', 'i', 'n', 'd', 'o', 'w', 's', '\\', 'N', 'o', 't', 'i', 'f', 'i', 'c', 'a', 't', 'i', 'o', 'n', 's', '\\', 'w', 'p', 'n', 'd', 'a', 't', 'a', 'b', 'a', 's', 'e', '.', 'd', 'b' };
            if (env_len + suffix.len >= wide_path.len) return false;
            @memcpy(wide_path[env_len .. env_len + suffix.len], suffix);
        }
        var utf8_path: [2080]u8 = undefined;
        const utf8 = widePathToUtf8(&wide_path, &utf8_path) orelse return false;
        const path_z = utf8_path[0 .. utf8.len + 1];
        path_z[utf8.len] = 0;
        const open = self.api.open_v2.?;
        var db: ?*SqliteDb = null;
        if (open(@ptrCast(path_z.ptr), &db, sqlite_open_read_only, null) != sqlite_ok or db == null) return false;
        self.database = db;
        const path_count = @min(std.mem.indexOfScalar(u16, &wide_path, 0) orelse wide_path.len, self.opened_path.len - 1);
        @memcpy(self.opened_path[0..path_count], wide_path[0..path_count]);
        self.opened_path[path_count] = 0;
        self.primed = false;
        return true;
    }

    pub fn stop(self: *ToastReader) void {
        if (self.database) |database| {
            if (self.api.close) |close| _ = close(database);
        }
        self.database = null;
        if (self.api.module) |module| _ = FreeLibrary(module);
        self.api = .{};
    }

    pub fn available(self: *const ToastReader) bool {
        return self.database != null;
    }

    pub fn takenCount(self: *const ToastReader) usize {
        return self.taken;
    }

    fn prepare(self: *ToastReader, sql: [*:0]const u8) ?*SqliteStmt {
        const database = self.database orelse return null;
        const prepare_v2 = self.api.prepare_v2 orelse return null;
        var statement: ?*SqliteStmt = null;
        if (prepare_v2(database, sql, -1, &statement, null) != sqlite_ok) return null;
        return statement;
    }

    pub fn poll(self: *ToastReader, output: []NotificationInput.Message) usize {
        if (self.database == null or output.len == 0) return 0;
        if (!self.primed) {
            const stmt = self.prepare("SELECT IFNULL(MAX(Id), 0) FROM Notification") orelse return 0;
            defer {
                if (self.api.finalize) |finalize| _ = finalize(stmt);
            }
            if (self.api.step.?(stmt) == sqlite_row) self.last_id = self.api.column_int64.?(stmt, 0);
            self.primed = true;
            return 0;
        }
        const sql: [*:0]const u8 = "SELECT n.Id, IFNULL(h.PrimaryId, ''), n.Payload FROM Notification n LEFT JOIN NotificationHandler h ON h.RecordId = n.HandlerId WHERE n.Id > ?1 AND n.Type = 'toast' ORDER BY n.Id ASC LIMIT 16";
        const stmt = self.prepare(sql) orelse return 0;
        defer {
            if (self.api.finalize) |finalize| _ = finalize(stmt);
        }
        _ = self.api.bind_int64.?(stmt, 1, self.last_id);
        var added: usize = 0;
        while (self.api.step.?(stmt) == sqlite_row) {
            if (added >= output.len) break;
            const id = self.api.column_int64.?(stmt, 0);
            if (id > self.last_id) self.last_id = id;
            const blob = self.api.column_blob.?(stmt, 2) orelse continue;
            const byte_count_i32 = self.api.column_bytes.?(stmt, 2);
            if (byte_count_i32 <= 0 or byte_count_i32 > max_payload_bytes) continue;
            const byte_count: usize = @intCast(byte_count_i32);
            const xml: [*]const u8 = @ptrCast(blob);
            var notification = NotificationInput.Message{ .source = .windows_toast, .source_key = @intCast(@max(0, id)) };
            if (!toastTextFromXml(xml[0..byte_count], &notification.title, &notification.body)) continue;
            if (self.api.column_text.?(stmt, 1)) |handler| {
                var handler_wide: [256]u16 = @splat(0);
                _ = MultiByteToWideChar(65001, 0, handler, -1, &handler_wide, handler_wide.len);
                var app_wide: [128]u16 = @splat(0);
                friendlyNameFromHandlerId(&handler_wide, &app_wide);
                _ = WideCharToMultiByte(65001, 0, @ptrCast(&app_wide), -1, &notification.app, notification.app.len, null, null);
            }
            if (notification.title[0] == 0 and notification.body[0] == 0) continue;
            output[added] = notification;
            added += 1;
            self.taken += 1;
        }
        return added;
    }

    pub fn dump(self: *ToastReader, limit: i64, output: []u16) usize {
        if (self.database == null or output.len == 0) return 0;
        output[0] = 0;
        const sql: [*:0]const u8 = "SELECT n.Id, IFNULL(h.PrimaryId, ''), n.Payload FROM Notification n LEFT JOIN NotificationHandler h ON h.RecordId = n.HandlerId WHERE n.Type = 'toast' ORDER BY n.Id DESC LIMIT ?1";
        const stmt = self.prepare(sql) orelse return 0;
        defer {
            if (self.api.finalize) |finalize| _ = finalize(stmt);
        }
        _ = self.api.bind_int64.?(stmt, 1, limit);
        var used: usize = 0;
        var rows: usize = 0;
        while (self.api.step.?(stmt) == sqlite_row) {
            const id = self.api.column_int64.?(stmt, 0);
            var handler_wide: [256]u16 = @splat(0);
            if (self.api.column_text.?(stmt, 1)) |handler| _ = MultiByteToWideChar(65001, 0, handler, -1, &handler_wide, handler_wide.len);
            var app: [128]u16 = @splat(0);
            friendlyNameFromHandlerId(&handler_wide, &app);
            var title: [NotificationInput.title_capacity]u8 = @splat(0);
            var body: [NotificationInput.body_capacity]u8 = @splat(0);
            if (self.api.column_blob.?(stmt, 2)) |blob| {
                const count = self.api.column_bytes.?(stmt, 2);
                if (count > 0 and count <= max_payload_bytes) {
                    const xml: [*]const u8 = @ptrCast(blob);
                    _ = toastTextFromXml(xml[0..@intCast(count)], &title, &body);
                }
            }
            var app_utf8: [512]u8 = @splat(0);
            _ = WideCharToMultiByte(65001, 0, @ptrCast(&app), -1, &app_utf8, app_utf8.len, null, null);
            var line: [1024]u8 = undefined;
            const line_utf8 = std.fmt.bufPrint(&line, "#{d} [{s}] {s} -- {s}\n", .{ id, cString(&app_utf8), cString(&title), if (body[0] == 0) "(no body)" else cString(&body) }) catch continue;
            var line_wide: [2048]u16 = @splat(0);
            if (utf8ToWide(line_utf8, &line_wide)) used = appendWide(output, used, line_wide[0 .. std.mem.indexOfScalar(u16, &line_wide, 0) orelse line_wide.len]);
            rows += 1;
        }
        return rows;
    }
};

fn cString(text: []const u8) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse text.len];
}

pub fn smokeCheck() bool {
    var title: [80]u8 = @splat(0);
    var body: [160]u8 = @splat(0);
    if (!toastTextFromXml("<toast><visual><binding><text>Hello &amp; world</text><text>line 2</text></binding></visual></toast>", &title, &body)) return false;
    if (!std.mem.eql(u8, cString(&title), "Hello & world")) return false;
    if (!std.mem.eql(u8, cString(&body), "line 2")) return false;
    var app: [64]u16 = @splat(0);
    friendlyNameFromHandlerId(&.{ 'O', 'p', 'e', 'n', 'A', 'I', '.', 'C', 'o', 'd', 'e', 'x', '_', 'x', '!', 'A', 'p', 'p', 0 }, &app);
    return std.mem.eql(u16, app[0..5], &.{ 'C', 'o', 'd', 'e', 'x' });
}

test "toast XML adapter extracts readable text and handler names" {
    var title: [80]u8 = @splat(0);
    var body: [160]u8 = @splat(0);
    try std.testing.expect(toastTextFromXml("<toast><text>One &amp; two</text><text>second</text></toast>", &title, &body));
    try std.testing.expectEqualStrings("One & two", cString(&title));
    try std.testing.expectEqualStrings("second", cString(&body));
    var app: [64]u16 = @splat(0);
    friendlyNameFromHandlerId(&.{ 'O', 'p', 'e', 'n', 'A', 'I', '.', 'C', 'o', 'd', 'e', 'x', '_', 'x', '!', 'A', 'p', 'p', 0 }, &app);
    try std.testing.expectEqualSlices(u16, &.{ 'C', 'o', 'd', 'e', 'x' }, app[0..5]);
}
