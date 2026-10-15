const std = @import("std");
const ThemeTokens = @import("ThemeTokens");

const HANDLE = ?*anyopaque;
const DWORD = u32;
const MAX_PATH: usize = 260;
const CP_UTF8: DWORD = 65001;
const GENERIC_READ: DWORD = 0x80000000;
const GENERIC_WRITE: DWORD = 0x40000000;
const FILE_SHARE_READ: DWORD = 1;
const FILE_SHARE_WRITE: DWORD = 2;
const OPEN_EXISTING: DWORD = 3;
const CREATE_ALWAYS: DWORD = 2;
const FILE_ATTRIBUTE_NORMAL: DWORD = 0x80;
const FILE_ATTRIBUTE_DIRECTORY: DWORD = 0x10;
const INVALID_HANDLE_VALUE: usize = std.math.maxInt(usize);

const FileTime = extern struct { low: DWORD, high: DWORD };
const FindDataW = extern struct {
    attributes: DWORD,
    creation_time: FileTime,
    last_access_time: FileTime,
    last_write_time: FileTime,
    file_size_high: DWORD,
    file_size_low: DWORD,
    reserved0: DWORD,
    reserved1: DWORD,
    file_name: [MAX_PATH]u16,
    alternate_name: [14]u16,
};

extern "kernel32" fn GetModuleFileNameW(module: HANDLE, path: [*]u16, size: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn MultiByteToWideChar(code_page: DWORD, flags: DWORD, input: [*]const u8, input_length: i32, output: [*]u16, output_length: i32) callconv(.winapi) i32;
extern "kernel32" fn WideCharToMultiByte(code_page: DWORD, flags: DWORD, input: [*]const u16, input_length: i32, output: [*]u8, output_length: i32, default_char: ?[*:0]const u8, used_default: ?*i32) callconv(.winapi) i32;
extern "kernel32" fn CreateFileW(path: [*:0]const u16, access: DWORD, share: DWORD, security: ?*anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
extern "kernel32" fn GetFileSizeEx(file: HANDLE, size: *i64) callconv(.winapi) i32;
extern "kernel32" fn ReadFile(file: HANDLE, buffer: [*]u8, count: DWORD, read: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn WriteFile(file: HANDLE, buffer: [*]const u8, count: DWORD, written: *DWORD, overlapped: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) i32;
extern "kernel32" fn FindFirstFileW(pattern: [*:0]const u16, data: *FindDataW) callconv(.winapi) HANDLE;
extern "kernel32" fn FindNextFileW(search: HANDLE, data: *FindDataW) callconv(.winapi) i32;
extern "kernel32" fn FindClose(search: HANDLE) callconv(.winapi) i32;

pub const Color = ThemeTokens.Color;
pub const LogFn = *const fn ([]const u8) void;
pub const Theme = struct {
    name: [32]u16 = @splat(0),
    pill_top: Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    pill_bottom: Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    gloss: f32 = 0,
    card_fill: Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    card_edge: f32 = 0,
    tokens: ThemeTokens.Tokens = .{
        .accent = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
        .ink = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    },
    shadow: f32 = 0,
    grain: f32 = 0,
};

const built_in_themes = [_]Theme{
    .{
        .name = wideName(&.{ 0x9ED8, 0x8BA4 }),
        .pill_top = color(0.05, 0.05, 0.07, 0.92),
        .pill_bottom = color(0.04, 0.05, 0.08, 0.98),
        .gloss = 0.06,
        .card_fill = color(0.05, 0.05, 0.07, 0.97),
        .card_edge = 0.13,
        .tokens = .{ .accent = color(0.0, 0.47, 0.83, 0.95), .ink = color(0.93, 0.93, 0.93, 1.0) },
    },
    .{
        .name = wideName(&.{ 0x51B0, 0x84DD }),
        .pill_top = color(0.06, 0.09, 0.16, 0.93),
        .pill_bottom = color(0.02, 0.03, 0.07, 0.97),
        .gloss = 0.10,
        .card_fill = color(0.04, 0.06, 0.12, 0.97),
        .card_edge = 0.16,
        .tokens = .{ .accent = color(0.20, 0.62, 0.98, 0.95), .ink = color(0.90, 0.94, 1.0, 1.0) },
        .shadow = 0.05,
        .grain = 0.02,
    },
    .{
        .name = wideName(&.{ 0x77F3, 0x58A8 }),
        .pill_top = color(0.13, 0.13, 0.14, 0.94),
        .pill_bottom = color(0.08, 0.08, 0.09, 0.98),
        .gloss = 0.05,
        .card_fill = color(0.11, 0.11, 0.12, 0.97),
        .card_edge = 0.18,
        .tokens = .{ .accent = color(0.24, 0.56, 0.90, 0.95), .ink = color(0.99, 0.99, 0.99, 1.0) },
        .shadow = 0.05,
    },
    .{
        .name = wideName(&.{ 0x73BB, 0x7483 }),
        .pill_top = color(0.20, 0.24, 0.32, 0.66),
        .pill_bottom = color(0.06, 0.08, 0.14, 0.82),
        .gloss = 0.16,
        .card_fill = color(0.12, 0.14, 0.20, 0.78),
        .card_edge = 0.34,
        .tokens = .{ .accent = color(0.42, 0.78, 1.0, 0.95), .ink = color(0.98, 0.99, 1.0, 1.0) },
        .shadow = 0.20,
        .grain = 0.05,
    },
};

var themes: [64]Theme = undefined;
var theme_count: usize = 0;
var current_index: usize = 0;
var initialized = false;

fn color(r: f32, g: f32, b: f32, a: f32) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

fn wideName(comptime units: []const u16) [32]u16 {
    var result: [32]u16 = @splat(0);
    @memcpy(result[0..units.len], units);
    return result;
}

fn ensureInitialized() void {
    if (initialized) return;
    @memcpy(themes[0..built_in_themes.len], &built_in_themes);
    theme_count = built_in_themes.len;
    current_index = 0;
    initialized = true;
}

fn cWide(text: []const u16) []const u16 {
    return text[0 .. std.mem.indexOfScalar(u16, text, 0) orelse text.len];
}

fn cBytes(text: []const u8) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse text.len];
}

fn appendWide(out: []u16, used_arg: usize, text: []const u16) ?usize {
    if (out.len == 0) return null;
    const used = @min(used_arg, out.len - 1);
    if (text.len > out.len - 1 - used) return null;
    @memcpy(out[used .. used + text.len], text);
    out[used + text.len] = 0;
    return used + text.len;
}

fn dataFilePath(file_name: []const u16, out: []u16) bool {
    if (out.len < 2) return false;
    @memset(out, 0);
    var module_path: [MAX_PATH]u16 = @splat(0);
    const length = GetModuleFileNameW(null, &module_path, MAX_PATH);
    if (length == 0 or length >= MAX_PATH) return false;
    var folder_end: ?usize = null;
    for (module_path[0..length], 0..) |unit, i| if (unit == '\\' or unit == '/') {
        folder_end = i + 1;
    };
    const end = folder_end orelse return false;
    if (end >= out.len) return false;
    @memcpy(out[0..end], module_path[0..end]);
    return appendWide(out, end, file_name) != null;
}

fn utf8ToWide(text: []const u8, out: []u16) bool {
    if (out.len == 0) return false;
    @memset(out, 0);
    const input = cBytes(text);
    if (input.len == 0) return true;
    const converted = MultiByteToWideChar(CP_UTF8, 0, input.ptr, @intCast(input.len), out.ptr, @intCast(@min(out.len - 1, std.math.maxInt(i32))));
    if (converted <= 0 or converted >= out.len) return false;
    out[@intCast(converted)] = 0;
    return true;
}

fn wideToUtf8(text: []const u16, out: []u8) usize {
    const input = cWide(text);
    if (input.len == 0 or out.len == 0) return 0;
    const converted = WideCharToMultiByte(CP_UTF8, 0, input.ptr, @intCast(input.len), out.ptr, @intCast(@min(out.len, std.math.maxInt(i32))), null, null);
    return if (converted > 0) @intCast(converted) else 0;
}

fn trim(text: []const u8) []const u8 {
    var start: usize = 0;
    var end = text.len;
    while (start < end and (text[start] == ' ' or text[start] == '\t' or text[start] == '\r')) : (start += 1) {}
    while (end > start and (text[end - 1] == ' ' or text[end - 1] == '\t' or text[end - 1] == '\r')) : (end -= 1) {}
    return text[start..end];
}

fn parseScalar(text: []const u8) ?f32 {
    const value = std.fmt.parseFloat(f32, trim(text)) catch return null;
    if (!std.math.isFinite(value) or value < 0 or value > 1) return null;
    return value;
}

fn parseColor(text_arg: []const u8) ?Color {
    const text = trim(text_arg);
    var values: [4]f32 = .{ 0, 0, 0, 1 };
    var count: usize = 0;
    var iterator = std.mem.splitScalar(u8, text, ',');
    while (iterator.next()) |part| {
        if (count == 4) return null;
        values[count] = parseScalar(part) orelse return null;
        count += 1;
    }
    if (count == 1) {
        values[1] = values[0];
        values[2] = values[0];
    } else if (count < 3) return null;
    return color(values[0], values[1], values[2], values[3]);
}

fn setWhy(why: []u8, message: []const u8) void {
    if (why.len == 0) return;
    const count = @min(message.len, why.len - 1);
    @memcpy(why[0..count], message[0..count]);
    why[count] = 0;
}

fn appendWhy(why: []u8, prefix: []const u8, key: []const u8, value: []const u8) void {
    if (why.len == 0) return;
    var used: usize = 0;
    for (prefix) |ch| {
        if (used + 1 >= why.len) break;
        why[used] = ch;
        used += 1;
    }
    for (key) |ch| {
        if (used + 1 >= why.len) break;
        why[used] = ch;
        used += 1;
    }
    if (used + 1 < why.len) {
        why[used] = '=';
        used += 1;
    }
    for (value) |ch| {
        if (used + 1 >= why.len) break;
        why[used] = ch;
        used += 1;
    }
    why[used] = 0;
}

fn equalWideIgnoreCase(a: []const u16, b: []const u16) bool {
    const left = cWide(a);
    const right = cWide(b);
    if (left.len != right.len) return false;
    for (left, right) |x, y| {
        const lower_x = if (x >= 'A' and x <= 'Z') x + ('a' - 'A') else x;
        const lower_y = if (y >= 'A' and y <= 'Z') y + ('a' - 'A') else y;
        if (lower_x != lower_y) return false;
    }
    return true;
}

fn logTheme(theme: *const Theme, reason: []const u8, log_fn: LogFn) void {
    var name: [128]u8 = undefined;
    const name_len = wideToUtf8(&theme.name, &name);
    var line: [256]u8 = undefined;
    const formatted = std.fmt.bufPrint(&line, "theme: {s} ({s}), ink contrast {d:.1}:1", .{ name[0..name_len], reason, inkContrast(theme) }) catch return;
    log_fn(formatted);
}

/// Returns the active theme. The pointer remains valid for the process lifetime.
pub fn currentTheme() *const Theme {
    ensureInitialized();
    if (current_index >= theme_count) current_index = 0;
    return &themes[current_index];
}

pub fn themeCount() usize {
    ensureInitialized();
    return theme_count;
}

pub fn themeAt(index: usize) ?*const Theme {
    ensureInitialized();
    if (index >= theme_count) return null;
    return &themes[index];
}

pub fn currentThemeIndex() usize {
    ensureInitialized();
    return current_index;
}

pub fn builtInThemeCount() usize {
    return built_in_themes.len;
}

pub fn builtInTheme(index: usize) ?*const Theme {
    if (index >= built_in_themes.len) return null;
    return &built_in_themes[index];
}

pub fn cycleTheme(log_fn: LogFn) *const Theme {
    ensureInitialized();
    current_index = (current_index + 1) % theme_count;
    logTheme(&themes[current_index], "switched", log_fn);
    _ = saveThemeChoice(&themes[current_index].name);
    return &themes[current_index];
}

pub fn themeInk(alpha: f32) Color {
    return ThemeTokens.withOpacity(currentTheme().tokens.ink, alpha);
}

fn clamp01(value: f32) f32 {
    return @max(0, @min(1, value));
}

fn channelLuminance(value_arg: f32) f32 {
    const value = clamp01(value_arg);
    return if (value <= 0.03928) value / 12.92 else std.math.pow(f32, (value + 0.055) / 1.055, 2.4);
}

fn luminance(value: Color) f32 {
    return 0.2126 * channelLuminance(value.r) + 0.7152 * channelLuminance(value.g) + 0.0722 * channelLuminance(value.b);
}

pub fn inkContrast(theme: *const Theme) f32 {
    const alpha = clamp01(theme.card_fill.a);
    const backdrop: f32 = 0.9;
    const effective = color(
        theme.card_fill.r * alpha + backdrop * (1 - alpha),
        theme.card_fill.g * alpha + backdrop * (1 - alpha),
        theme.card_fill.b * alpha + backdrop * (1 - alpha),
        1,
    );
    const first = luminance(theme.tokens.ink);
    const second = luminance(effective);
    return (@max(first, second) + 0.05) / (@min(first, second) + 0.05);
}

/// Parses a UTF-8 theme file. Each line is key=value; optional fields inherit the built-in default.
pub fn themeFromText(text_arg: []const u8, out: *Theme, why: []u8) bool {
    const text = cBytes(text_arg);
    if (text.len == 0) {
        setWhy(why, "no text");
        return false;
    }
    var theme = built_in_themes[0];
    theme.name = @splat(0);
    var have_name = false;
    var applied: usize = 0;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line_arg| {
        const line = trim(line_arg);
        if (line.len == 0 or line[0] == '#') continue;
        const equals = std.mem.indexOfScalar(u8, line, '=') orelse {
            setWhy(why, "a line without '='");
            return false;
        };
        const key = trim(line[0..equals]);
        const value = trim(line[equals + 1 ..]);
        if (key.len == 0 or value.len == 0) {
            setWhy(why, "an empty key or value");
            return false;
        }
        if (std.mem.eql(u8, key, "name")) {
            if (!utf8ToWide(value, &theme.name)) {
                setWhy(why, "theme name is invalid UTF-8 or too long");
                return false;
            }
            have_name = theme.name[0] != 0;
            applied += 1;
        } else if (std.mem.eql(u8, key, "pill-top") or std.mem.eql(u8, key, "pill-bottom") or std.mem.eql(u8, key, "card") or std.mem.eql(u8, key, "accent") or std.mem.eql(u8, key, "ink")) {
            const parsed = parseColor(value) orelse {
                appendWhy(why, "not a colour (0..1 per channel): ", key, value);
                return false;
            };
            if (std.mem.eql(u8, key, "pill-top")) theme.pill_top = parsed else if (std.mem.eql(u8, key, "pill-bottom")) theme.pill_bottom = parsed else if (std.mem.eql(u8, key, "card")) theme.card_fill = parsed else if (std.mem.eql(u8, key, "accent")) theme.tokens.accent = parsed else theme.tokens.ink = parsed;
            applied += 1;
        } else if (std.mem.eql(u8, key, "gloss") or std.mem.eql(u8, key, "card-edge") or std.mem.eql(u8, key, "shadow") or std.mem.eql(u8, key, "grain")) {
            const parsed = parseScalar(value) orelse {
                appendWhy(why, "not a 0..1 number: ", key, value);
                return false;
            };
            if (std.mem.eql(u8, key, "gloss")) theme.gloss = parsed else if (std.mem.eql(u8, key, "card-edge")) theme.card_edge = parsed else if (std.mem.eql(u8, key, "shadow")) theme.shadow = parsed else theme.grain = parsed;
            applied += 1;
        } else {
            setWhy(why, "unknown key: ");
            if (why.len > 0) {
                const prefix_len = std.mem.indexOfScalar(u8, why, 0) orelse why.len;
                const count = @min(key.len, why.len - prefix_len - 1);
                @memcpy(why[prefix_len .. prefix_len + count], key[0..count]);
                why[prefix_len + count] = 0;
            }
            return false;
        }
    }
    if (!have_name) {
        setWhy(why, "no name= line");
        return false;
    }
    if (applied <= 1) {
        setWhy(why, "nothing but a name");
        return false;
    }
    out.* = theme;
    if (why.len > 0) why[0] = 0;
    return true;
}

fn isInvalid(handle: HANDLE) bool {
    return handle == null or @intFromPtr(handle) == INVALID_HANDLE_VALUE;
}

fn writeAll(file: HANDLE, bytes: []const u8) bool {
    var offset: usize = 0;
    while (offset < bytes.len) {
        var written: DWORD = 0;
        const count = @min(bytes.len - offset, std.math.maxInt(DWORD));
        if (WriteFile(file, bytes[offset..].ptr, @intCast(count), &written, null) == 0 or written == 0) return false;
        offset += written;
    }
    return true;
}

pub fn saveThemeChoice(name: []const u16) bool {
    var path: [MAX_PATH]u16 = @splat(0);
    if (!dataFilePath(&.{ 't', 'h', 'e', 'm', 'e', '.', 't', 'x', 't' }, &path)) return false;
    const file = CreateFileW(@ptrCast(&path), GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
    if (isInvalid(file)) return false;
    defer _ = CloseHandle(file);
    if (!writeAll(file, "# The bar's material. One line, the name of a theme: the built-in ones are\r\n# Default, Ice Blue, Graphite, and Glass; themes\\ adds more.\r\n")) return false;
    var encoded: [128]u8 = undefined;
    const length = wideToUtf8(name, &encoded);
    if (length == 0 or !writeAll(file, encoded[0..length])) return false;
    return writeAll(file, "\r\n");
}

fn loadUserThemes(log_fn: LogFn) void {
    ensureInitialized();
    if (theme_count >= themes.len) return;
    var directory: [MAX_PATH]u16 = @splat(0);
    if (!dataFilePath(&.{ 't', 'h', 'e', 'm', 'e', 's', '\\' }, &directory)) return;
    var pattern: [MAX_PATH]u16 = @splat(0);
    const pattern_len = cWide(&directory).len;
    if (appendWide(&pattern, 0, &directory[0..pattern_len]) == null) return;
    if (appendWide(&pattern, pattern_len, &.{ '*', '.', 't', 'x', 't' }) == null) return;
    var found: FindDataW = undefined;
    const search = FindFirstFileW(@ptrCast(&pattern), &found);
    if (isInvalid(search)) {
        log_fn("theme: no themes directory");
        return;
    }
    defer _ = FindClose(search);
    while (true) {
        if ((found.attributes & FILE_ATTRIBUTE_DIRECTORY) == 0 and theme_count < themes.len) {
            var path: [MAX_PATH]u16 = @splat(0);
            const dir_len = cWide(&directory).len;
            if (appendWide(&path, 0, &directory[0..dir_len])) |after_dir| {
                if (appendWide(&path, after_dir, cWide(&found.file_name))) |_| {
                    const file = CreateFileW(@ptrCast(&path), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
                    if (!isInvalid(file)) {
                        defer _ = CloseHandle(file);
                        var file_size: i64 = 0;
                        if (GetFileSizeEx(file, &file_size) != 0 and file_size >= 0 and file_size < 2048) {
                            var buffer: [2048]u8 = @splat(0);
                            var bytes_read: DWORD = 0;
                            if (ReadFile(file, &buffer, @intCast(file_size), &bytes_read, null) != 0) {
                                var content = buffer[0..bytes_read];
                                if (content.len >= 3 and content[0] == 0xEF and content[1] == 0xBB and content[2] == 0xBF) content = content[3..];
                                var parsed: Theme = undefined;
                                var why: [256]u8 = @splat(0);
                                if (themeFromText(content, &parsed, &why)) {
                                    themes[theme_count] = parsed;
                                    theme_count += 1;
                                    logTheme(&parsed, "loaded from themes", log_fn);
                                } else {
                                    var line: [320]u8 = undefined;
                                    const message = std.fmt.bufPrint(&line, "theme file skipped: {s}", .{cBytes(&why)}) catch "theme file skipped";
                                    log_fn(message);
                                }
                            }
                        }
                    }
                }
            }
        }
        if (FindNextFileW(search, &found) == 0) break;
    }
}

pub fn applyRememberedTheme(log_fn: LogFn) void {
    ensureInitialized();
    loadUserThemes(log_fn);
    var path: [MAX_PATH]u16 = @splat(0);
    if (!dataFilePath(&.{ 't', 'h', 'e', 'm', 'e', '.', 't', 'x', 't' }, &path)) return;
    const file = CreateFileW(@ptrCast(&path), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);
    if (isInvalid(file)) {
        logTheme(&themes[current_index], "built-in default", log_fn);
        return;
    }
    defer _ = CloseHandle(file);
    var buffer: [256]u8 = @splat(0);
    var read: DWORD = 0;
    if (ReadFile(file, &buffer, buffer.len - 1, &read, null) == 0) return;
    const text = buffer[0..read];
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line_arg| {
        const line = trim(line_arg);
        if (line.len == 0 or line[0] == '#') continue;
        var wanted: [32]u16 = @splat(0);
        if (!utf8ToWide(line, &wanted)) return;
        for (themes[0..theme_count], 0..) |*theme, i| {
            if (equalWideIgnoreCase(&theme.name, &wanted)) {
                current_index = i;
                logTheme(theme, "remembered by theme.txt", log_fn);
                return;
            }
        }
        log_fn("theme.txt names an unknown theme; keeping current theme");
        return;
    }
    logTheme(&themes[current_index], "theme.txt is empty; using default", log_fn);
}

pub fn smokeCheck() bool {
    ensureInitialized();
    if (themeCount() != built_in_themes.len or builtInThemeCount() != 4) return false;
    if (builtInTheme(0) == null or builtInTheme(4) != null or themeAt(theme_count) != null) return false;
    for (&built_in_themes) |*theme| if (inkContrast(theme) < 4.5) return false;
    const source = "# sample\nname=Test Theme\naccent=0.2,0.4,0.8\ngloss=0.3\n";
    var parsed: Theme = undefined;
    var why: [128]u8 = @splat(0);
    if (!themeFromText(source, &parsed, &why)) return false;
    if (!equalWideIgnoreCase(&parsed.name, &.{ 'T', 'e', 's', 't', ' ', 'T', 'h', 'e', 'm', 'e', 0 })) return false;
    if (parsed.tokens.accent.r != 0.2 or parsed.tokens.accent.g != 0.4 or parsed.tokens.accent.b != 0.8 or parsed.tokens.accent.a != 1) return false;
    if (themeFromText("name=Only Name\n", &parsed, &why)) return false;
    if (themeFromText("name=Broken\naccent=0,2,0\n", &parsed, &why)) return false;
    if (themeFromText("name=Broken\nunknown=x\n", &parsed, &why)) return false;
    return currentThemeIndex() == 0;
}

test "theme parsing preserves shared token values and contrast checks" {
    try std.testing.expect(smokeCheck());
}

fn ignoreLog(_: []const u8) void {}

comptime {
    if (false) {
        var theme: Theme = undefined;
        var reason: [128]u8 = undefined;
        _ = themeFromText("name=x\naccent=0.1,0.2,0.3\n", &theme, &reason);
        _ = saveThemeChoice(&theme.name);
        applyRememberedTheme(ignoreLog);
    }
}
