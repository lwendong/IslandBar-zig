const std = @import("std");

const ValueType = enum { string, number, other };

const Value = struct {
    start: usize,
    kind: ValueType,
};

fn cString(text: []const u8) []const u8 {
    return text[0..(std.mem.indexOfScalar(u8, text, 0) orelse text.len)];
}

fn encodeUtf8(code_point: u32, output: *[4]u8) usize {
    if (code_point == 0 or code_point >= 0xd800 and code_point <= 0xdfff) return 0;
    if (code_point < 0x80) {
        output[0] = @intCast(code_point);
        return 1;
    }
    if (code_point < 0x800) {
        output[0] = @intCast(0xc0 | (code_point >> 6));
        output[1] = @intCast(0x80 | (code_point & 0x3f));
        return 2;
    }
    if (code_point < 0x10000) {
        output[0] = @intCast(0xe0 | (code_point >> 12));
        output[1] = @intCast(0x80 | ((code_point >> 6) & 0x3f));
        output[2] = @intCast(0x80 | (code_point & 0x3f));
        return 3;
    }
    if (code_point <= 0x10ffff) {
        output[0] = @intCast(0xf0 | (code_point >> 18));
        output[1] = @intCast(0x80 | ((code_point >> 12) & 0x3f));
        output[2] = @intCast(0x80 | ((code_point >> 6) & 0x3f));
        output[3] = @intCast(0x80 | (code_point & 0x3f));
        return 4;
    }
    return 0;
}

fn isHighSurrogate(value: u32) bool {
    return value >= 0xd800 and value <= 0xdbff;
}

fn isLowSurrogate(value: u32) bool {
    return value >= 0xdc00 and value <= 0xdfff;
}

fn hexDigit(value: u8) ?u4 {
    return switch (value) {
        '0'...'9' => @intCast(value - '0'),
        'a'...'f' => @intCast(value - 'a' + 10),
        'A'...'F' => @intCast(value - 'A' + 10),
        else => null,
    };
}

fn readHex4(text: []const u8, start: usize) ?u16 {
    if (start > text.len or text.len - start < 4) return null;
    var value: u16 = 0;
    for (text[start .. start + 4]) |digit| {
        value = (value << 4) | (hexDigit(digit) orelse return null);
    }
    return value;
}

/// Escapes a byte string into a JSON string body. The output includes a trailing NUL.
pub fn escape(text: []const u8, output: []u8) usize {
    if (output.len == 0) return 0;
    output[0] = 0;
    var written: usize = 0;

    for (cString(text)) |byte| {
        const replacement: ?[]const u8 = switch (byte) {
            '"' => "\\\"",
            '\\' => "\\\\",
            '\x08' => "\\b",
            '\x0c' => "\\f",
            '\n' => "\\n",
            '\r' => "\\r",
            '\t' => "\\t",
            else => null,
        };

        var unicode_escape: [6]u8 = undefined;
        const encoded = replacement orelse if (byte < 0x20) blk: {
            const hex = "0123456789ABCDEF";
            unicode_escape[0] = '\\';
            unicode_escape[1] = 'u';
            unicode_escape[2] = '0';
            unicode_escape[3] = '0';
            unicode_escape[4] = hex[byte >> 4];
            unicode_escape[5] = hex[byte & 0x0f];
            break :blk unicode_escape[0..];
        } else &.{byte};

        if (encoded.len + 1 > output.len - written) break;
        @memcpy(output[written .. written + encoded.len], encoded);
        written += encoded.len;
    }
    output[written] = 0;
    return written;
}

const ByteWriter = struct {
    output: []u8,
    written: usize = 0,
    overflowed: bool = false,

    fn put(self: *ByteWriter, byte: u8) void {
        if (self.overflowed) return;
        if (self.written + 1 >= self.output.len) {
            self.overflowed = true;
            return;
        }
        self.output[self.written] = byte;
        self.written += 1;
    }

    fn putCodePoint(self: *ByteWriter, code_point: u32) void {
        var bytes: [4]u8 = undefined;
        const length = encodeUtf8(code_point, &bytes);
        if (length == 0) {
            self.put('?');
            return;
        }
        for (bytes[0..length]) |byte| self.put(byte);
    }
};

/// Decodes a JSON string body. The output includes a trailing NUL.
pub fn unescape(text: []const u8, output: []u8) usize {
    if (output.len == 0) return 0;
    output[0] = 0;
    var writer = ByteWriter{ .output = output };
    var index: usize = 0;

    while (index < text.len and !writer.overflowed) {
        const byte = text[index];
        if (byte != '\\') {
            writer.put(byte);
            index += 1;
            continue;
        }

        if (index + 1 >= text.len) {
            writer.put(byte);
            index += 1;
            continue;
        }

        const escaped = text[index + 1];
        switch (escaped) {
            '"' => {
                writer.put('"');
                index += 2;
            },
            '\\' => {
                writer.put('\\');
                index += 2;
            },
            '/' => {
                writer.put('/');
                index += 2;
            },
            'b' => {
                writer.put('\x08');
                index += 2;
            },
            'f' => {
                writer.put('\x0c');
                index += 2;
            },
            'n' => {
                writer.put('\n');
                index += 2;
            },
            'r' => {
                writer.put('\r');
                index += 2;
            },
            't' => {
                writer.put('\t');
                index += 2;
            },
            'u' => {
                const high_or_code = readHex4(text, index + 2) orelse {
                    writer.put(byte);
                    index += 1;
                    continue;
                };
                index += 6;

                if (isHighSurrogate(high_or_code)) {
                    if (index + 6 <= text.len and text[index] == '\\' and text[index + 1] == 'u') {
                        if (readHex4(text, index + 2)) |low| {
                            if (isLowSurrogate(low)) {
                                const code_point: u32 = 0x10000 +
                                    ((@as(u32, high_or_code) - 0xd800) << 10) +
                                    (@as(u32, low) - 0xdc00);
                                writer.putCodePoint(code_point);
                                index += 6;
                                continue;
                            }
                        }
                    }
                    writer.putCodePoint(0xfffd);
                } else if (isLowSurrogate(high_or_code)) {
                    writer.putCodePoint(0xfffd);
                } else {
                    writer.putCodePoint(high_or_code);
                }
            },
            else => {
                writer.put(escaped);
                index += 2;
            },
        }
    }

    output[writer.written] = 0;
    return writer.written;
}

fn skipString(text: []const u8, start: usize) ?usize {
    if (start >= text.len or text[start] != '"') return null;
    var index = start + 1;
    while (index < text.len) {
        if (text[index] == '\\') {
            if (index + 1 >= text.len) return null;
            index += 2;
            continue;
        }
        if (text[index] == '"') return index + 1;
        index += 1;
    }
    return null;
}

fn skipWhitespace(text: []const u8, index: *usize) void {
    while (index.* < text.len) : (index.* += 1) {
        switch (text[index.*]) {
            ' ', '\t', '\n', '\r' => {},
            else => return,
        }
    }
}

fn findTopLevelValue(document_arg: []const u8, key: []const u8) ?Value {
    const document = cString(document_arg);
    var depth: i32 = 0;
    var index: usize = 0;

    while (index < document.len) {
        const byte = document[index];
        if (byte == '"') {
            const token_end = skipString(document, index) orelse return null;
            if (depth == 1 and token_end - index >= 2) {
                const body = document[index + 1 .. token_end - 1];
                if (std.mem.eql(u8, body, key)) {
                    var value_start = token_end;
                    skipWhitespace(document, &value_start);
                    if (value_start < document.len and document[value_start] == ':') {
                        value_start += 1;
                        skipWhitespace(document, &value_start);
                        const kind: ValueType = if (value_start < document.len and document[value_start] == '"')
                            .string
                        else if (value_start < document.len and (document[value_start] == '-' or std.ascii.isDigit(document[value_start])))
                            .number
                        else
                            .other;
                        return .{ .start = value_start, .kind = kind };
                    }
                }
            }
            index = token_end;
            continue;
        }

        switch (byte) {
            '{', '[' => depth += 1,
            '}', ']' => {
                depth -= 1;
                if (depth < 0) return null;
            },
            else => {},
        }
        index += 1;
    }
    return null;
}

/// Reads a top-level string. `output` reserves one byte for its NUL terminator.
pub fn getString(document: []const u8, key: []const u8, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    const value = findTopLevelValue(document, key) orelse return false;
    if (value.kind != .string) return false;
    const text = cString(document);
    const end = skipString(text, value.start) orelse return false;
    _ = unescape(text[value.start + 1 .. end - 1], output);
    return true;
}

/// Reads a signed top-level integer. Fractions are truncated, matching strtoll.
pub fn getInt(document: []const u8, key: []const u8) ?i64 {
    const value = findTopLevelValue(document, key) orelse return null;
    if (value.kind != .number) return null;
    const text = cString(document);
    var index = value.start;
    var negative = false;
    if (index < text.len and text[index] == '-') {
        negative = true;
        index += 1;
    }
    const digits_start = index;
    const limit: u64 = if (negative) @as(u64, std.math.maxInt(i64)) + 1 else std.math.maxInt(i64);
    var magnitude: u64 = 0;
    while (index < text.len and std.ascii.isDigit(text[index])) : (index += 1) {
        const digit: u64 = text[index] - '0';
        if (magnitude > (limit - digit) / 10) {
            magnitude = limit;
            while (index + 1 < text.len and std.ascii.isDigit(text[index + 1])) : (index += 1) {}
            break;
        }
        magnitude = magnitude * 10 + digit;
    }
    if (digits_start == index and magnitude == 0) return null;
    if (!negative) return @intCast(magnitude);
    if (magnitude == @as(u64, std.math.maxInt(i64)) + 1) return std.math.minInt(i64);
    return -@as(i64, @intCast(magnitude));
}

/// Reports whether a top-level key exists, regardless of its JSON value type.
pub fn hasKey(document: []const u8, key: []const u8) bool {
    return findTopLevelValue(document, key) != null;
}

/// Focused migration smoke check used by the Windows executable's --smoke mode.
pub fn smokeCheck() bool {
    var output: [64]u8 = undefined;
    const simple = "{\"app\":\"Discord\",\"nested\":{\"title\":\"wrong\"},\"title\":\"A\\uD83D\\uDE00\\nB\",\"n\":-17}";
    if (!getString(simple, "title", &output)) return false;
    const decoded = "A😀\nB";
    const end = std.mem.indexOfScalar(u8, &output, 0) orelse return false;
    if (!std.mem.eql(u8, output[0..end], decoded)) return false;
    if (getString(simple, "missing", &output)) return false;
    if (getInt(simple, "n") != -17) return false;
    if (getInt(simple, "title") != null) return false;
    if (hasKey("{\"v\":null}", "v") == false) return false;
    if (getString("{\"title\":\"ok\"}", "title", output[0..3]) == false) return false;
    return std.mem.eql(u8, output[0..2], "ok");
}
