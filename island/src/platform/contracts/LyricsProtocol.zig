const std = @import("std");
const MiniJson = @import("MiniJson");

pub const line_capacity = 256;
pub const max_lines = 512;
pub const line_enter_seconds: f32 = 0.26;

pub const LyricLine = struct {
    time_ms: i64 = 0,
    text: [line_capacity]u8 = @splat(0),
};
pub const Lyrics = struct {
    lines: [max_lines]LyricLine = @splat(.{}),
    count: usize = 0,
    title: [line_capacity]u8 = @splat(0),
    artist: [line_capacity]u8 = @splat(0),
    track_duration_ms: i64 = 0,

    pub fn lineAt(self: *const Lyrics, position_ms: i64) ?usize {
        if (self.count == 0 or position_ms < self.lines[0].time_ms) return null;
        var best: ?usize = null;
        for (self.lines[0..self.count], 0..) |line, index| {
            if (line.time_ms > position_ms) break;
            if (line.text[0] != 0) best = index;
        }
        return best;
    }

    pub fn at(self: *const Lyrics, index: usize) ?*const LyricLine {
        if (index >= self.count) return null;
        return &self.lines[index];
    }

    pub fn empty(self: *const Lyrics) bool {
        return self.count == 0;
    }
};

pub const LyricSource = enum { lrc, tlyric, lyric };

pub fn lyricLineRollFor(age_seconds: f32) f32 {
    if (age_seconds <= 0) return 0;
    if (age_seconds >= line_enter_seconds) return 1;
    const remaining = 1 - age_seconds / line_enter_seconds;
    return 1 - remaining * remaining * remaining;
}

pub fn lyricLineChanged(arriving: []const u8, shown: []const u8) bool {
    return !std.mem.eql(u8, cSlice(arriving), cSlice(shown));
}

pub fn parseLrc(document: []const u8, out: *Lyrics) usize {
    out.* = .{};
    var source = document;
    if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) source = source[3..];
    var offset_ms: i64 = 0;

    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |physical_arg| {
        const physical = std.mem.trimEnd(u8, physical_arg, "\r");
        var cursor: usize = 0;
        var times: [16]i64 = undefined;
        var time_count: usize = 0;
        while (time_count < times.len) {
            const parsed = readTimeTag(physical, cursor) orelse break;
            times[time_count] = parsed.time_ms;
            cursor = parsed.next;
            time_count += 1;
        }

        if (time_count != 0) {
            const text = physical[cursor..];
            for (times[0..time_count]) |time_ms| insertSorted(out, time_ms, text);
            continue;
        }

        if (physical.len < 4 or physical[0] != '[') continue;
        const close = std.mem.indexOfScalar(u8, physical, ']') orelse continue;
        const colon = std.mem.indexOfScalar(u8, physical[1..close], ':') orelse continue;
        const key = physical[1 .. colon + 1];
        const value = physical[colon + 2 .. close];
        if (std.ascii.eqlIgnoreCase(key, "ti")) copyText(&out.title, value);
        if (std.ascii.eqlIgnoreCase(key, "ar")) copyText(&out.artist, value);
        if (std.ascii.eqlIgnoreCase(key, "offset")) offset_ms = std.fmt.parseInt(i64, value, 10) catch offset_ms;
    }

    if (offset_ms != 0) for (out.lines[0..out.count]) |*line| {
        line.time_ms = @max(0, line.time_ms + offset_ms);
    };
    return out.count;
}

/// Percent encodes UTF-8 bytes for a URL query component, matching the service API's rules.
pub fn urlEncode(utf8: []const u8, output: []u16) usize {
    if (output.len == 0) return 0;
    var written: usize = 0;
    for (cSlice(utf8)) |byte| {
        const unreserved = (byte >= 'A' and byte <= 'Z') or (byte >= 'a' and byte <= 'z') or
            (byte >= '0' and byte <= '9') or byte == '-' or byte == '_' or byte == '.' or byte == '~';
        const needed: usize = if (unreserved) 1 else 3;
        if (needed >= output.len - written) break;
        if (unreserved) {
            output[written] = byte;
            written += 1;
        } else {
            const hex = "0123456789ABCDEF";
            output[written] = '%';
            output[written + 1] = hex[byte >> 4];
            output[written + 2] = hex[byte & 0x0f];
            written += 3;
        }
    }
    output[written] = 0;
    return written;
}

/// Expands the XML entities used in QQ's lyric attribute.
pub fn decodeXmlEntities(source: []const u8, output: []u8) usize {
    if (output.len == 0) return 0;
    var written: usize = 0;
    const input = cSlice(source);
    const entities = [_]struct { text: []const u8, value: u8 }{
        .{ .text = "&#10;", .value = '\n' },
        .{ .text = "&#13;", .value = '\r' },
        .{ .text = "&lt;", .value = '<' },
        .{ .text = "&gt;", .value = '>' },
        .{ .text = "&quot;", .value = '"' },
        .{ .text = "&apos;", .value = '\'' },
        .{ .text = "&amp;", .value = '&' },
    };
    var i: usize = 0;
    while (i < input.len and written + 1 < output.len) {
        var matched = false;
        for (entities) |entity| {
            if (std.mem.startsWith(u8, input[i..], entity.text)) {
                output[written] = entity.value;
                written += 1;
                i += entity.text.len;
                matched = true;
                break;
            }
        }
        if (!matched) {
            output[written] = input[i];
            written += 1;
            i += 1;
        }
    }
    output[written] = 0;
    return written;
}

/// Reads `key` at the first level of the first object in the array addressed by `path`.
/// This avoids confusing song identifiers with identically named nested album or artist fields.
fn flatFieldInArrayObject(document: []const u8, path: []const []const u8, key: []const u8) ?[]const u8 {
    const doc = cSlice(document);
    if (path.len == 0 or key.len == 0) return null;
    var cursor: usize = 0;
    for (path) |part| {
        const quoted = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\"", .{part}) catch return null;
        defer std.heap.page_allocator.free(quoted);
        const found = std.mem.indexOfPos(u8, doc, cursor, quoted) orelse return null;
        var open = found + quoted.len;
        while (open < doc.len and doc[open] != '{' and doc[open] != '[') : (open += 1) {}
        if (open == doc.len) return null;
        cursor = open + 1;
    }

    while (cursor < doc.len and doc[cursor] != '{' and doc[cursor] != ']') : (cursor += 1) {}
    if (cursor == doc.len or doc[cursor] != '{') return null;

    var depth: usize = 0;
    var i = cursor;
    while (i < doc.len) {
        if (doc[i] == '"') {
            const end = quotedStringEnd(doc, i) orelse return null;
            if (depth == 1 and std.mem.eql(u8, doc[i + 1 .. end], key)) {
                var value = end + 1;
                skipJsonSpace(doc, &value);
                if (value >= doc.len or doc[value] != ':') return null;
                value += 1;
                skipJsonSpace(doc, &value);
                if (value >= doc.len) return null;
                return doc[value..];
            }
            i = end + 1;
            continue;
        }
        switch (doc[i]) {
            '{', '[' => depth += 1,
            '}', ']' => {
                if (depth == 0) return null;
                depth -= 1;
                if (depth == 0) return null;
            },
            else => {},
        }
        i += 1;
    }
    return null;
}

pub fn findFlatStringInArray(document: []const u8, path: []const []const u8, key: []const u8, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    const value = flatFieldInArrayObject(document, path, key) orelse return false;
    if (value.len == 0 or value[0] != '"') return false;
    const end = quotedStringEnd(value, 0) orelse return false;
    _ = MiniJson.unescape(value[1..end], output);
    return output[0] != 0;
}

pub fn findFlatIntegerInArray(document: []const u8, path: []const []const u8, key: []const u8) ?i64 {
    const value = flatFieldInArrayObject(document, path, key) orelse return null;
    var number = value;
    if (number.len > 0 and number[0] == '"') {
        number = number[1..];
        const close = std.mem.indexOfScalar(u8, number, '"') orelse return null;
        number = number[0..close];
    } else {
        var end: usize = 0;
        if (end < number.len and number[end] == '-') end += 1;
        while (end < number.len and std.ascii.isDigit(number[end])) : (end += 1) {}
        number = number[0..end];
    }
    return std.fmt.parseInt(i64, number, 10) catch null;
}

/// Extracts a non-empty JSON string field in one lyrics container.
pub fn extractJsonLyricField(document: []const u8, container: []const u8, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    const doc = cSlice(document);
    const quoted = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\"", .{container}) catch return false;
    defer std.heap.page_allocator.free(quoted);
    const at = std.mem.indexOf(u8, doc, quoted) orelse return false;
    const boundary = nextLyricContainer(doc, at + 1) orelse doc.len;
    return scanStringField(doc, at, boundary, "lyric", output);
}

/// Tries the original lyrics, their translation, then QQ's flat lyric field, in that order.
pub fn extractLyricField(document: []const u8, output: []u8) ?LyricSource {
    if (output.len == 0) return null;
    output[0] = 0;
    if (extractJsonLyricField(document, "lrc", output)) return .lrc;
    if (extractJsonLyricField(document, "tlyric", output)) return .tlyric;
    const doc = cSlice(document);
    const boundary = firstLyricContainer(doc) orelse doc.len;
    if (scanStringField(doc, 0, boundary, "lyric", output)) return .lyric;
    output[0] = 0;
    return null;
}

/// Extracts and decodes the lyric attribute from QQ's XML response.
pub fn extractQqXmlLyric(document: []const u8, output: []u8) bool {
    if (output.len == 0) return false;
    output[0] = 0;
    const doc = cSlice(document);
    const marker = std.mem.indexOf(u8, doc, "lyric=\"") orelse return false;
    const start = marker + "lyric=\"".len;
    const end = std.mem.indexOfScalarPos(u8, doc, start, '"') orelse return false;
    if (end == start) return false;
    _ = decodeXmlEntities(doc[start..end], output);
    return output[0] != 0;
}

pub fn reasonIsTransient(reason: []const u8) bool {
    return std.mem.indexOf(u8, cSlice(reason), "TRANSIENT") != null;
}

fn quotedStringEnd(document: []const u8, opening_quote: usize) ?usize {
    if (opening_quote >= document.len or document[opening_quote] != '"') return null;
    var i = opening_quote + 1;
    while (i < document.len) {
        if (document[i] == '\\') {
            if (i + 1 >= document.len) return null;
            i += 2;
        } else if (document[i] == '"') {
            return i;
        } else {
            i += 1;
        }
    }
    return null;
}

fn skipJsonSpace(document: []const u8, index: *usize) void {
    while (index.* < document.len) : (index.* += 1) {
        switch (document[index.*]) {
            ' ', '\t', '\r', '\n' => {},
            else => return,
        }
    }
}

fn containerKey(comptime name: []const u8) []const u8 {
    return std.fmt.comptimePrint("\"{s}\"", .{name});
}

fn findContainer(document: []const u8, start: usize) ?usize {
    const keys = [_][]const u8{ containerKey("lrc"), containerKey("klyric"), containerKey("tlyric") };
    var first: ?usize = null;
    for (keys) |key| {
        if (std.mem.indexOfPos(u8, document, start, key)) |at| {
            if (first == null or at < first.?) first = at;
        }
    }
    return first;
}

fn firstLyricContainer(document: []const u8) ?usize {
    return findContainer(document, 0);
}

fn nextLyricContainer(document: []const u8, start: usize) ?usize {
    return findContainer(document, start);
}

fn scanStringField(document: []const u8, start: usize, boundary: usize, name: []const u8, output: []u8) bool {
    if (output.len == 0 or start > document.len or boundary > document.len) return false;
    output[0] = 0;
    const needle = std.fmt.allocPrint(std.heap.page_allocator, "\"{s}\"", .{name}) catch return false;
    defer std.heap.page_allocator.free(needle);
    var search = start;
    while (search < boundary) {
        const at = std.mem.indexOfPos(u8, document, search, needle) orelse return false;
        if (at >= boundary) return false;
        var cursor = at + needle.len;
        skipJsonSpace(document, &cursor);
        if (cursor < boundary and document[cursor] == ':') {
            cursor += 1;
            skipJsonSpace(document, &cursor);
            if (cursor < boundary and document[cursor] == '"') {
                const end = quotedStringEnd(document, cursor) orelse return false;
                if (end >= boundary) return false;
                _ = MiniJson.unescape(document[cursor + 1 .. end], output);
                if (output[0] != 0) return true;
            }
        }
        search = at + 1;
    }
    return false;
}

const ParsedTime = struct { time_ms: i64, next: usize };
fn readTimeTag(text: []const u8, start: usize) ?ParsedTime {
    if (start >= text.len or text[start] != '[') return null;
    var cursor = start + 1;
    const minute_start = cursor;
    while (cursor < text.len and cursor - minute_start < 3 and std.ascii.isDigit(text[cursor])) : (cursor += 1) {}
    if (cursor == minute_start or cursor >= text.len or text[cursor] != ':') return null;
    const minutes = std.fmt.parseInt(i64, text[minute_start..cursor], 10) catch return null;
    cursor += 1;
    const second_start = cursor;
    while (cursor < text.len and cursor - second_start < 2 and std.ascii.isDigit(text[cursor])) : (cursor += 1) {}
    if (cursor == second_start) return null;
    const seconds = std.fmt.parseInt(i64, text[second_start..cursor], 10) catch return null;
    var millis: i64 = 0;
    if (cursor < text.len and (text[cursor] == '.' or text[cursor] == ':')) {
        cursor += 1;
        const fraction_start = cursor;
        while (cursor < text.len and cursor - fraction_start < 3 and std.ascii.isDigit(text[cursor])) : (cursor += 1) {}
        const digits = cursor - fraction_start;
        if (digits == 0) return null;
        const raw = std.fmt.parseInt(i64, text[fraction_start..cursor], 10) catch return null;
        millis = switch (digits) {
            1 => raw * 100,
            2 => raw * 10,
            else => raw,
        };
    }
    if (cursor >= text.len or text[cursor] != ']') return null;
    return .{ .time_ms = minutes * 60000 + seconds * 1000 + millis, .next = cursor + 1 };
}

fn insertSorted(out: *Lyrics, time_ms: i64, text: []const u8) void {
    if (out.count == max_lines) return;
    var at = out.count;
    while (at > 0 and out.lines[at - 1].time_ms > time_ms) : (at -= 1) out.lines[at] = out.lines[at - 1];
    out.lines[at] = .{ .time_ms = time_ms };
    copyText(&out.lines[at].text, text);
    out.count += 1;
}

fn copyText(destination: *[line_capacity]u8, source: []const u8) void {
    const trim = std.mem.trimEnd(u8, source, " \t\r");
    const take = @min(trim.len, line_capacity - 1);
    @memcpy(destination[0..take], trim[0..take]);
    destination[take] = 0;
}

pub fn cSlice(text: []const u8) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse text.len];
}

pub fn smokeCheck() bool {
    var lyrics = Lyrics{};
    if (parseLrc("\xEF\xBB\xBF[ti:Song]\n[ar:Artist]\n[offset:100]\n[00:02.5]Second\n[00:01.00]First\n[00:03.00]\n", &lyrics) != 3) return false;
    if (lyrics.lines[0].time_ms != 1100 or lyrics.lines[1].time_ms != 2600) return false;
    if (lyrics.lineAt(1050) != null or lyrics.lineAt(2700) != 1) return false;

    if (lyricLineRollFor(0) != 0 or lyricLineRollFor(line_enter_seconds) != 1) return false;
    if (!lyricLineChanged("new", "old") or lyricLineChanged("same", "same")) return false;

    var encoded: [96]u16 = undefined;
    const encoded_len = urlEncode("周杰伦", &encoded);
    const encoded_expected = "%E5%91%A8%E6%9D%B0%E4%BC%A6";
    if (encoded_len != encoded_expected.len) return false;
    for (encoded_expected, 0..) |byte, index| if (encoded[index] != byte) return false;

    var decoded_xml: [128]u8 = undefined;
    const decoded_xml_len = decodeXmlEntities("A&amp;B&#10;&lt;tag&gt;", &decoded_xml);
    if (!std.mem.eql(u8, decoded_xml[0..decoded_xml_len], "A&B\n<tag>")) return false;
    if (!reasonIsTransient("TRANSIENT: network timeout") or reasonIsTransient("NOT_FOUND")) return false;

    const search_json = "{\"result\":{\"songs\":[{\"album\":{\"id\":77},\"id\":123,\"name\":\"周杰伦\"}]}}";
    const search_path = [_][]const u8{ "result", "songs" };
    var song_name: [64]u8 = undefined;
    if (!findFlatStringInArray(search_json, &search_path, "name", &song_name)) return false;
    if (!std.mem.eql(u8, cSlice(&song_name), "周杰伦")) return false;
    if (findFlatIntegerInArray(search_json, &search_path, "id") != 123) return false;
    const negative_json = "{\"items\":[{\"id\":\"-9\"}]}";
    if (findFlatIntegerInArray(negative_json, &.{"items"}, "id") != -9) return false;

    const netease_json = "{\"lrc\":{\"version\":1,\"lyric\":\"[00:01.00]原文\\n\"},\"tlyric\":{\"lyric\":\"[00:01.00]翻译\\n\"}}";
    var response_lyric: [128]u8 = undefined;
    if (extractLyricField(netease_json, &response_lyric) != .lrc) return false;
    if (!std.mem.eql(u8, cSlice(&response_lyric), "[00:01.00]原文\n")) return false;

    const translated_only = "{\"lrc\":{\"lyric\":\"\"},\"tlyric\":{\"lyric\":\"[00:01.00]译文\\n\"}}";
    if (extractLyricField(translated_only, &response_lyric) != .tlyric) return false;
    if (!std.mem.eql(u8, cSlice(&response_lyric), "[00:01.00]译文\n")) return false;

    const qq_json = "{\"lyric\":\"[00:02.00]QQ\\n\"}";
    if (extractLyricField(qq_json, &response_lyric) != .lyric) return false;
    if (!std.mem.eql(u8, cSlice(&response_lyric), "[00:02.00]QQ\n")) return false;

    var qq_xml_lyric: [128]u8 = undefined;
    if (!extractQqXmlLyric("<lyric lyric=\"[00:03.00]A&amp;B&#10;\"/>", &qq_xml_lyric)) return false;
    return std.mem.eql(u8, cSlice(&qq_xml_lyric), "[00:03.00]A&B\n");
}

test "music lyric parsing and encoding rules" {
    try std.testing.expect(smokeCheck());
}
