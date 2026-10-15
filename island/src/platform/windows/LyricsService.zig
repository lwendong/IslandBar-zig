const std = @import("std");

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

extern "kernel32" fn CreateEventW(attributes: ?*anyopaque, manual_reset: BOOL, initial_state: BOOL, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
extern "kernel32" fn SetEvent(event: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn WaitForSingleObject(handle: HANDLE, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn WaitForMultipleObjects(count: DWORD, handles: [*]const HANDLE, wait_all: BOOL, milliseconds: DWORD) callconv(.winapi) DWORD;
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) BOOL;
extern "kernel32" fn CreateThread(attributes: ?*anyopaque, stack_size: usize, entry: *const fn (?*anyopaque) callconv(.winapi) DWORD, parameter: ?*anyopaque, flags: DWORD, thread_id: ?*DWORD) callconv(.winapi) HANDLE;
extern "kernel32" fn InitializeCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn DeleteCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn EnterCriticalSection(section: *CriticalSection) callconv(.winapi) void;
extern "kernel32" fn LeaveCriticalSection(section: *CriticalSection) callconv(.winapi) void;

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

const wait_object_0: DWORD = 0;
const infinite: DWORD = 0xFFFFFFFF;
const winhttp_access_type_automatic_proxy: DWORD = 4;
const internet_default_https_port: u16 = 443;
const winhttp_flag_secure: DWORD = 0x00800000;
const winhttp_query_status_code: DWORD = 19;
const winhttp_query_flag_number: DWORD = 0x20000000;
const max_attempts_per_track = 3;
const fetch_timeout_ms = 10_000;
const http_agent: [*:0]const u16 = &.{ 'M', 'o', 'z', 'i', 'l', 'l', 'a', '/', '5', '.', '0', ' ', '(', 'W', 'i', 'n', 'd', 'o', 'w', 's', ' ', 'N', 'T', ' ', '1', '0', '.', '0', ';', ' ', 'W', 'i', 'n', '6', '4', ';', ' ', 'x', '6', '4', ')', ' ', 'A', 'p', 'p', 'l', 'e', 'W', 'e', 'b', 'K', 'i', 't', '/', '5', '3', '7', '.', '3', '6', ' ', '(', 'K', 'H', 'T', 'M', 'L', ',', ' ', 'l', 'i', 'k', 'e', ' ', 'G', 'e', 'c', 'k', 'o', ')', ' ', 'C', 'h', 'r', 'o', 'm', 'e', '/', '1', '2', '2', '.', '0', '.', '0', '.', '0', ' ', 'S', 'a', 'f', 'a', 'r', 'i', '/', '5', '3', '7', '.', '3', '6', 0 };
const http_get: [*:0]const u16 = &.{ 'G', 'E', 'T', 0 };

const LyricsProtocol = @import("LyricsProtocol");
pub const line_capacity = LyricsProtocol.line_capacity;
pub const max_lines = LyricsProtocol.max_lines;
pub const line_enter_seconds = LyricsProtocol.line_enter_seconds;
pub const LyricLine = LyricsProtocol.LyricLine;
pub const Lyrics = LyricsProtocol.Lyrics;
pub const LyricSource = LyricsProtocol.LyricSource;
const parseLrc = LyricsProtocol.parseLrc;
const extractLyricField = LyricsProtocol.extractLyricField;
const extractQqXmlLyric = LyricsProtocol.extractQqXmlLyric;
const urlEncode = LyricsProtocol.urlEncode;
const decodeXmlEntities = LyricsProtocol.decodeXmlEntities;
const findFlatStringInArray = LyricsProtocol.findFlatStringInArray;
const findFlatIntegerInArray = LyricsProtocol.findFlatIntegerInArray;
const reasonIsTransient = LyricsProtocol.reasonIsTransient;
const cSlice = LyricsProtocol.cSlice;

pub const FetchAttempt = struct {
    search_status: DWORD = 0,
    lyric_status: DWORD = 0,
    search_url: [1024]u8 = @splat(0),
    lyric_url: [1024]u8 = @splat(0),
    search_body: [2048]u8 = @splat(0),
    lyric_body: [2048]u8 = @splat(0),
    verdict: [160]u8 = @splat(0),
};

pub const LyricsFetchReport = struct { netease: FetchAttempt = .{}, qq: FetchAttempt = .{} };
pub const FetchOutcome = struct { parsed: bool = false, transient_failure: bool = false };

const HttpResponse = struct { ok: bool = false, status: DWORD = 0, length: usize = 0 };

fn putZ(output: []u8, input_arg: []const u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const input = cSlice(input_arg);
    var take = @min(input.len, output.len - 1);
    // Do not leave an invalid UTF-8 tail when a fixed diagnostic or title buffer is full.
    if (take < input.len) {
        while (take > 0 and (input[take] & 0xC0) == 0x80) take -= 1;
        if (take > 0) {
            const lead = input[take - 1];
            const sequence_len: usize = if (lead < 0x80) 1 else if ((lead & 0xE0) == 0xC0) 2 else if ((lead & 0xF0) == 0xE0) 3 else if ((lead & 0xF8) == 0xF0) 4 else 1;
            if (take - 1 + sequence_len > @min(input.len, output.len - 1)) take -= 1;
        }
    }
    @memcpy(output[0..take], input[0..take]);
}

fn asciiWideZ(input: []const u8, output: []u16) ?[*:0]const u16 {
    if (output.len == 0 or input.len >= output.len) return null;
    for (input, 0..) |byte, index| {
        if (byte > 0x7F) return null;
        output[index] = byte;
    }
    output[input.len] = 0;
    return @ptrCast(output.ptr);
}

fn appendWideAscii(output: []u16, cursor: *usize, input: []const u8) bool {
    if (output.len == 0 or cursor.* + input.len >= output.len) return false;
    for (input) |byte| {
        if (byte > 0x7F) return false;
        output[cursor.*] = byte;
        cursor.* += 1;
    }
    return true;
}

fn appendWide(output: []u16, cursor: *usize, input: []const u16) bool {
    if (output.len == 0 or cursor.* + input.len >= output.len) return false;
    @memcpy(output[cursor.* .. cursor.* + input.len], input);
    cursor.* += input.len;
    return true;
}

fn pathToUtf8(path: []const u16, output: []u8) void {
    if (output.len == 0) return;
    @memset(output, 0);
    const length = std.mem.indexOfScalar(u16, path, 0) orelse path.len;
    const take = @min(length, output.len - 1);
    for (path[0..take], 0..) |unit, index| output[index] = if (unit <= 0x7F) @intCast(unit) else '?';
}

fn httpGetWithReferer(host: []const u8, path: []const u16, referer: ?[]const u8, timeout_ms: i32, output: []u8) HttpResponse {
    if (output.len == 0) return .{};
    output[0] = 0;
    var host_wide: [128]u16 = @splat(0);
    const host_z = asciiWideZ(host, &host_wide) orelse return .{};
    var request_path: [6144]u16 = @splat(0);
    const path_length = std.mem.indexOfScalar(u16, path, 0) orelse path.len;
    if (path_length >= request_path.len) return .{};
    @memcpy(request_path[0..path_length], path[0..path_length]);
    var referrer_wide: [128]u16 = @splat(0);
    const referrer_z = if (referer) |value| asciiWideZ(value, &referrer_wide) else null;

    const session = WinHttpOpen(http_agent, winhttp_access_type_automatic_proxy, null, null, 0) orelse return .{};
    defer _ = WinHttpCloseHandle(session);
    _ = WinHttpSetTimeouts(session, timeout_ms, timeout_ms, timeout_ms, timeout_ms);
    const connection = WinHttpConnect(session, host_z, internet_default_https_port, 0) orelse return .{};
    defer _ = WinHttpCloseHandle(connection);
    const request = WinHttpOpenRequest(connection, http_get, @ptrCast(&request_path), null, referrer_z, null, winhttp_flag_secure, 0) orelse return .{};
    defer _ = WinHttpCloseHandle(request);
    if (WinHttpSendRequest(request, null, 0, null, 0, 0, 0) == 0 or WinHttpReceiveResponse(request, null) == 0) return .{};

    var result = HttpResponse{};
    var status_size: DWORD = @sizeOf(DWORD);
    if (WinHttpQueryHeaders(request, winhttp_query_status_code | winhttp_query_flag_number, null, &result.status, &status_size, null) == 0) return .{};
    if (result.status != 200) return result;

    var used: usize = 0;
    result.ok = true;
    while (used + 1 < output.len) {
        var available: DWORD = 0;
        if (WinHttpQueryDataAvailable(request, &available) == 0) {
            result.ok = false;
            break;
        }
        if (available == 0) break;
        const chunk: DWORD = @intCast(@min(@as(usize, available), output.len - used - 1));
        if (chunk == 0) break;
        var read: DWORD = 0;
        if (WinHttpReadData(request, output[used..].ptr, chunk, &read) == 0) {
            result.ok = false;
            break;
        }
        if (read == 0) break;
        used += read;
    }
    output[used] = 0;
    result.length = used;
    return result;
}

fn setReason(reason: []u8, text: []const u8) void {
    putZ(reason, text);
}

fn makeSearchQuery(title_arg: []const u8, artist_arg: []const u8, output: []u8) ?[]const u8 {
    const title = cSlice(title_arg);
    const artist = cSlice(artist_arg);
    if (artist.len == 0) {
        const take = @min(title.len, output.len -| 1);
        @memcpy(output[0..take], title[0..take]);
        output[take] = 0;
        return output[0..take];
    }
    const query = std.fmt.bufPrint(output[0 .. output.len - 1], "{s} {s}", .{ title, artist }) catch return null;
    output[query.len] = 0;
    return query;
}

fn fetchFromNetEase(title: []const u8, artist: []const u8, timeout_ms: i32, out: *Lyrics, reason: []u8, attempt: ?*FetchAttempt) bool {
    var query: [512]u8 = @splat(0);
    const query_text = makeSearchQuery(title, artist, &query) orelse {
        setReason(reason, "netease: TRANSIENT: query is too long");
        return false;
    };
    var encoded_query: [2048]u16 = undefined;
    const encoded_len = urlEncode(query_text, &encoded_query);
    var search_path: [3072]u16 = @splat(0);
    var path_len: usize = 0;
    // Append the URL component with an explicit capacity check; the prefix is kept out of the
    // encoded output buffer so Unicode track names cannot be split into malformed byte sequences.
    if (!appendWideAscii(&search_path, &path_len, "/api/search/get/?s=")) {
        setReason(reason, "netease: TRANSIENT: search URL is too long");
        return false;
    }
    if (path_len + encoded_len + 42 >= search_path.len) {
        setReason(reason, "netease: TRANSIENT: search URL is too long");
        return false;
    }
    @memcpy(search_path[path_len .. path_len + encoded_len], encoded_query[0..encoded_len]);
    path_len += encoded_len;
    const suffix = "&type=1&limit=1&offset=0";
    _ = appendWideAscii(&search_path, &path_len, suffix);

    var search_body = std.heap.page_allocator.alloc(u8, 256 * 1024) catch {
        setReason(reason, "netease: TRANSIENT: could not allocate the search response buffer");
        return false;
    };
    defer std.heap.page_allocator.free(search_body);
    const search = httpGetWithReferer("music.163.com", &search_path, "https://music.163.com/", timeout_ms, search_body);
    if (attempt) |report| {
        report.search_status = search.status;
        pathToUtf8(&search_path, &report.search_url);
        putZ(&report.search_body, search_body[0..search.length]);
    }
    if (!search.ok) {
        if (search.status == 0) setReason(reason, "netease: TRANSIENT: search could not connect (offline, blocked, or TLS refused)") else {
            var message: [128]u8 = undefined;
            const rendered = std.fmt.bufPrint(&message, "netease: TRANSIENT: search returned HTTP {d}", .{search.status}) catch "netease: TRANSIENT: search failed";
            setReason(reason, rendered);
        }
        return false;
    }
    if (search.length == 0) {
        setReason(reason, "netease: TRANSIENT: search returned an empty body");
        return false;
    }
    const songs = [_][]const u8{"songs"};
    const song_id = findFlatIntegerInArray(search_body[0..search.length], &songs, "id") orelse {
        setReason(reason, "netease: TRANSIENT: the search response had no usable song id");
        return false;
    };
    if (song_id <= 0) {
        setReason(reason, "netease: TRANSIENT: the search response had no usable song id");
        return false;
    }
    var song_duration: i64 = 0;
    if (findFlatIntegerInArray(search_body[0..search.length], &songs, "duration")) |duration| {
        if (duration > 0) song_duration = duration;
    }

    var lyric_path_ascii: [512]u8 = undefined;
    const lyric_ascii = std.fmt.bufPrint(&lyric_path_ascii, "/api/song/lyric/?id={d}&lv=1&kv=1&tv=-1", .{song_id}) catch {
        setReason(reason, "netease: TRANSIENT: lyric URL is too long");
        return false;
    };
    var lyric_path: [512]u16 = @splat(0);
    const lyric_path_z = asciiWideZ(lyric_ascii, &lyric_path) orelse {
        setReason(reason, "netease: TRANSIENT: invalid lyric URL");
        return false;
    };
    _ = lyric_path_z;
    var lyric_body = std.heap.page_allocator.alloc(u8, 512 * 1024) catch {
        setReason(reason, "netease: TRANSIENT: could not allocate the lyric response buffer");
        return false;
    };
    defer std.heap.page_allocator.free(lyric_body);
    const lyric = httpGetWithReferer("music.163.com", &lyric_path, "https://music.163.com/", timeout_ms, lyric_body);
    if (attempt) |report| {
        report.lyric_status = lyric.status;
        putZ(&report.lyric_url, lyric_ascii);
        putZ(&report.lyric_body, lyric_body[0..lyric.length]);
    }
    if (!lyric.ok) {
        if (lyric.status == 0) setReason(reason, "netease: TRANSIENT: lyric request could not connect") else {
            var message: [128]u8 = undefined;
            const rendered = std.fmt.bufPrint(&message, "netease: TRANSIENT: lyric returned HTTP {d}", .{lyric.status}) catch "netease: TRANSIENT: lyric request failed";
            setReason(reason, rendered);
        }
        return false;
    }

    const lrc = std.heap.page_allocator.alloc(u8, 512 * 1024) catch {
        setReason(reason, "netease: TRANSIENT: could not allocate the parsed lyric buffer");
        return false;
    };
    defer std.heap.page_allocator.free(lrc);
    if (extractLyricField(lyric_body[0..lyric.length], lrc) == null) {
        setReason(reason, "netease: TRANSIENT: the response had no lyric field");
        return false;
    }
    if (lrc[0] == 0) {
        setReason(reason, "netease: that track has no lyrics (an instrumental)");
        return false;
    }
    var parsed = Lyrics{};
    if (parseLrc(lrc, &parsed) == 0) {
        setReason(reason, "netease: TRANSIENT: the lyric text held no timed lines");
        return false;
    }
    parsed.track_duration_ms = song_duration;
    out.* = parsed;
    setReason(reason, "ok (netease)");
    return true;
}

fn fetchFromQqMusic(title: []const u8, artist: []const u8, timeout_ms: i32, out: *Lyrics, reason: []u8, attempt: ?*FetchAttempt) bool {
    const query = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}{s}", .{ cSlice(title), if (cSlice(artist).len == 0) "" else " ", cSlice(artist) }) catch {
        setReason(reason, "qq: TRANSIENT: could not build the search query");
        return false;
    };
    defer std.heap.page_allocator.free(query);
    const search_json = std.fmt.allocPrint(std.heap.page_allocator, "{{\"req_0\":{{\"module\":\"music.search.SearchCgiService\",\"method\":\"DoSearchForQQMusicDesktop\",\"param\":{{\"query\":\"{s}\",\"num_per_page\":1,\"page_num\":1}}}}}}", .{query}) catch {
        setReason(reason, "qq: TRANSIENT: could not build the search request");
        return false;
    };
    defer std.heap.page_allocator.free(search_json);
    var encoded_search: [4096]u16 = undefined;
    const encoded_len = urlEncode(search_json, &encoded_search);
    var search_path: [6144]u16 = @splat(0);
    var search_path_len: usize = 0;
    if (!appendWideAscii(&search_path, &search_path_len, "/cgi-bin/musicu.fcg?format=json&data=") or
        !appendWide(&search_path, &search_path_len, encoded_search[0..encoded_len]))
    {
        setReason(reason, "qq: TRANSIENT: search URL is too long");
        return false;
    }

    var search_body = std.heap.page_allocator.alloc(u8, 256 * 1024) catch {
        setReason(reason, "qq: TRANSIENT: could not allocate the search response buffer");
        return false;
    };
    defer std.heap.page_allocator.free(search_body);
    const search = httpGetWithReferer("u.y.qq.com", &search_path, "https://y.qq.com/", timeout_ms, search_body);
    if (attempt) |report| {
        report.search_status = search.status;
        pathToUtf8(&search_path, &report.search_url);
        putZ(&report.search_body, search_body[0..search.length]);
    }
    if (!search.ok) {
        if (search.status == 0) setReason(reason, "qq: TRANSIENT: search could not connect (offline, blocked, or TLS refused)") else {
            var message: [128]u8 = undefined;
            const rendered = std.fmt.bufPrint(&message, "qq: TRANSIENT: search returned HTTP {d}", .{search.status}) catch "qq: TRANSIENT: search failed";
            setReason(reason, rendered);
        }
        return false;
    }

    const song_list_path = [_][]const u8{ "song", "list" };
    var song_mid: [128]u8 = @splat(0);
    if (!findFlatStringInArray(search_body[0..search.length], &song_list_path, "mid", &song_mid)) {
        setReason(reason, "qq: TRANSIENT: the search response had no usable song mid");
        return false;
    }
    var duration_ms: i64 = 0;
    if (findFlatIntegerInArray(search_body[0..search.length], &song_list_path, "interval")) |seconds| {
        if (seconds > 0) duration_ms = std.math.mul(i64, seconds, 1000) catch 0;
    }
    const mid_len = std.mem.indexOfScalar(u8, &song_mid, 0) orelse song_mid.len;
    var lyric_ascii: [1024]u8 = undefined;
    const lyric_path_ascii = std.fmt.bufPrint(&lyric_ascii, "/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid={s}&format=json&nobase64=1", .{song_mid[0..mid_len]}) catch {
        setReason(reason, "qq: TRANSIENT: lyric URL is too long");
        return false;
    };
    var lyric_path: [1024]u16 = @splat(0);
    if (asciiWideZ(lyric_path_ascii, &lyric_path) == null) {
        setReason(reason, "qq: TRANSIENT: invalid lyric URL");
        return false;
    }
    var lyric_body = std.heap.page_allocator.alloc(u8, 512 * 1024) catch {
        setReason(reason, "qq: TRANSIENT: could not allocate the lyric response buffer");
        return false;
    };
    defer std.heap.page_allocator.free(lyric_body);
    const lyric = httpGetWithReferer("c.y.qq.com", &lyric_path, "https://y.qq.com/", timeout_ms, lyric_body);
    if (attempt) |report| {
        report.lyric_status = lyric.status;
        putZ(&report.lyric_url, lyric_path_ascii);
        putZ(&report.lyric_body, lyric_body[0..lyric.length]);
    }
    if (!lyric.ok) {
        if (lyric.status == 0) setReason(reason, "qq: TRANSIENT: lyric request could not connect") else {
            var message: [128]u8 = undefined;
            const rendered = std.fmt.bufPrint(&message, "qq: TRANSIENT: lyric returned HTTP {d}", .{lyric.status}) catch "qq: TRANSIENT: lyric request failed";
            setReason(reason, rendered);
        }
        return false;
    }
    const lrc = std.heap.page_allocator.alloc(u8, 512 * 1024) catch {
        setReason(reason, "qq: TRANSIENT: could not allocate the parsed lyric buffer");
        return false;
    };
    defer std.heap.page_allocator.free(lrc);
    if (extractLyricField(lyric_body[0..lyric.length], lrc) == null and !extractQqXmlLyric(lyric_body[0..lyric.length], lrc)) {
        setReason(reason, "qq: TRANSIENT: the response had no lyric field");
        return false;
    }
    if (lrc[0] == 0) {
        setReason(reason, "qq: that track has no lyrics (an instrumental)");
        return false;
    }
    var parsed = Lyrics{};
    if (parseLrc(lrc, &parsed) == 0) {
        setReason(reason, "qq: TRANSIENT: the lyric text held no timed lines");
        return false;
    }
    parsed.track_duration_ms = duration_ms;
    out.* = parsed;
    setReason(reason, "ok (qq)");
    return true;
}

/// Fetches from NetEase then QQ on a worker thread. On failure `out` is left untouched.
pub fn fetchLyricsVerbose(title_arg: []const u8, artist_arg: []const u8, timeout_ms: i32, out: *Lyrics, diagnostic: []u8, report: ?*LyricsFetchReport) bool {
    if (report) |value| value.* = .{};
    if (diagnostic.len != 0) diagnostic[0] = 0;
    const title = cSlice(title_arg);
    if (title.len == 0) {
        setReason(diagnostic, "no track title");
        return false;
    }
    var reason_netease: [192]u8 = @splat(0);
    const netease_attempt = if (report) |value| &value.netease else null;
    if (fetchFromNetEase(title, cSlice(artist_arg), timeout_ms, out, diagnostic, netease_attempt)) {
        if (report) |value| putZ(&value.netease.verdict, "ok");
        return true;
    }
    putZ(&reason_netease, diagnostic);
    if (report) |value| putZ(&value.netease.verdict, if (diagnostic.len != 0 and diagnostic[0] != 0) cSlice(diagnostic) else "netease: failed");
    const qq_attempt = if (report) |value| &value.qq else null;
    if (fetchFromQqMusic(title, cSlice(artist_arg), timeout_ms, out, diagnostic, qq_attempt)) {
        if (report) |value| putZ(&value.qq.verdict, "ok");
        return true;
    }
    if (report) |value| putZ(&value.qq.verdict, if (diagnostic.len != 0 and diagnostic[0] != 0) cSlice(diagnostic) else "qq: failed");
    var combined: [384]u8 = @splat(0);
    const second = if (diagnostic.len != 0 and diagnostic[0] != 0) cSlice(diagnostic) else "qq: failed";
    const message = std.fmt.bufPrint(&combined, "{s}; then {s}", .{ cSlice(&reason_netease), second }) catch return false;
    setReason(diagnostic, message);
    return false;
}

pub fn fetchLyricsDetailed(title: []const u8, artist: []const u8, timeout_ms: i32, out: *Lyrics, diagnostic: []u8) FetchOutcome {
    const parsed = fetchLyricsVerbose(title, artist, timeout_ms, out, diagnostic, null);
    return .{ .parsed = parsed, .transient_failure = !parsed and reasonIsTransient(diagnostic) };
}

pub fn fetchLyricsFromNetwork(title: []const u8, artist: []const u8, timeout_ms: i32, out: *Lyrics, diagnostic: []u8) bool {
    return fetchLyricsVerbose(title, artist, timeout_ms, out, diagnostic, null);
}

/// Background lyric lookup with the same request de-duplication and bounded retry policy as the
/// original worker. The frame loop only queues a track and reads the last snapshot.
pub const LyricsProvider = struct {
    stop_event: HANDLE = null,
    request_event: HANDLE = null,
    thread: HANDLE = null,
    running_flag: i32 = 0,
    lock: CriticalSection = .{ .debug_info = null, .lock_count = 0, .recursion_count = 0, .owning_thread = null, .lock_semaphore = null, .spin_count = 0 },
    lock_ready: bool = false,
    requested_title: [256]u8 = @splat(0),
    requested_artist: [256]u8 = @splat(0),
    request_pending: i32 = 0,
    have_asked: bool = false,
    last_answer_was_transient: bool = false,
    attempt_count: i32 = 0,
    request_generation: i32 = 0,
    requested_track_generation: u64 = 0,
    result_track_generation: u64 = 0,
    lyrics: Lyrics = .{},
    have_lyrics: bool = false,
    revision: i32 = 0,
    fetch_count: i32 = 0,
    last_reason: [192]u8 = @splat(0),

    pub fn start(self: *LyricsProvider) bool {
        if (self.thread != null and @atomicLoad(i32, &self.running_flag, .seq_cst) != 0) return true;
        if (self.lock_ready) return false;
        InitializeCriticalSection(&self.lock);
        self.lock_ready = true;
        self.stop_event = CreateEventW(null, 1, 0, null);
        self.request_event = CreateEventW(null, 0, 0, null);
        if (self.stop_event == null or self.request_event == null) {
            self.closeEvents();
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        @atomicStore(i32, &self.running_flag, 1, .seq_cst);
        self.thread = CreateThread(null, 0, threadEntry, self, 0, null);
        if (self.thread == null) {
            @atomicStore(i32, &self.running_flag, 0, .seq_cst);
            self.closeEvents();
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
            return false;
        }
        return true;
    }

    pub fn stop(self: *LyricsProvider) void {
        if (self.stop_event) |event| _ = SetEvent(event);
        if (self.thread) |thread| {
            // The worker may be inside a synchronous WinHTTP call. Join it before freeing
            // its events and lock; a timed-out join followed by teardown is a use-after-free.
            _ = WaitForSingleObject(thread, infinite);
            _ = CloseHandle(thread);
            self.thread = null;
        }
        self.closeEvents();
        if (self.lock_ready) {
            DeleteCriticalSection(&self.lock);
            self.lock_ready = false;
        }
        @atomicStore(i32, &self.running_flag, 0, .seq_cst);
    }

    fn closeEvents(self: *LyricsProvider) void {
        if (self.stop_event) |event| {
            _ = CloseHandle(event);
            self.stop_event = null;
        }
        if (self.request_event) |event| {
            _ = CloseHandle(event);
            self.request_event = null;
        }
    }

    pub fn request(self: *LyricsProvider, title_arg: []const u8, artist_arg: []const u8, track_generation: u64) void {
        if (@atomicLoad(i32, &self.running_flag, .seq_cst) == 0 or title_arg.len == 0) return;
        const title = cSlice(title_arg);
        const artist = cSlice(artist_arg);
        EnterCriticalSection(&self.lock);
        self.requested_track_generation = track_generation;
        const same_track = self.have_asked and std.mem.eql(u8, title, cSlice(&self.requested_title)) and
            std.mem.eql(u8, artist, cSlice(&self.requested_artist));
        const permanent_answer = same_track and !self.last_answer_was_transient;
        const retry_budget_left = !same_track or self.attempt_count < max_attempts_per_track;
        if (permanent_answer or !retry_budget_left) {
            LeaveCriticalSection(&self.lock);
            return;
        }
        if (!same_track) {
            self.attempt_count = 0;
            self.request_generation +%= 1;
            self.lyrics.count = 0;
            @atomicStore(bool, &self.have_lyrics, false, .seq_cst);
            _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
        }
        putZ(&self.requested_title, title);
        putZ(&self.requested_artist, artist);
        self.have_asked = true;
        self.attempt_count += 1;
        _ = @atomicRmw(i32, &self.request_pending, .Xchg, 1, .seq_cst);
        LeaveCriticalSection(&self.lock);
        if (self.request_event) |event| _ = SetEvent(event);
    }

    pub fn hasLyrics(self: *const LyricsProvider) bool {
        return @atomicLoad(bool, &self.have_lyrics, .seq_cst);
    }

    /// The pointer remains valid until the provider replaces its result or stops.
    pub fn current(self: *const LyricsProvider) ?*const Lyrics {
        if (!self.lock_ready or !self.hasLyrics()) return null;
        return &self.lyrics;
    }

    pub fn snapshot(self: *LyricsProvider, out: *Lyrics, track_generation: *u64) bool {
        if (!self.lock_ready) return false;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        if (!self.have_lyrics) return false;
        out.* = self.lyrics;
        track_generation.* = self.result_track_generation;
        return true;
    }

    /// Copies only the active lyric line while holding the provider lock. This
    /// avoids copying the full 512-line catalogue on each UI frame.
    pub fn copyLineAt(self: *LyricsProvider, position_ms: i64, output: *LyricLine) bool {
        if (!self.lock_ready) return false;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        if (!self.have_lyrics) return false;
        const index = self.lyrics.lineAt(position_ms) orelse return false;
        output.* = self.lyrics.lines[index];
        return output.text[0] != 0;
    }

    pub fn getRevision(self: *const LyricsProvider) u64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.revision, .seq_cst)));
    }

    pub fn getFetchCount(self: *const LyricsProvider) i64 {
        return @intCast(@max(0, @atomicLoad(i32, &self.fetch_count, .seq_cst)));
    }

    pub fn getLastReason(self: *LyricsProvider, output: []u8) void {
        if (output.len == 0) return;
        output[0] = 0;
        if (!self.lock_ready) return;
        EnterCriticalSection(&self.lock);
        defer LeaveCriticalSection(&self.lock);
        putZ(output, &self.last_reason);
    }

    fn threadEntry(parameter: ?*anyopaque) callconv(.winapi) DWORD {
        const self: *LyricsProvider = @ptrCast(@alignCast(parameter orelse return 0));
        self.run();
        return 0;
    }

    fn run(self: *LyricsProvider) void {
        const waits = [_]HANDLE{ self.stop_event, self.request_event };
        while (true) {
            const signalled = WaitForMultipleObjects(waits.len, &waits, 0, infinite);
            if (signalled == wait_object_0) break;
            if (signalled != wait_object_0 + 1) break;

            var title: [256]u8 = @splat(0);
            var artist: [256]u8 = @splat(0);
            var request_generation: i32 = 0;
            var track_generation: u64 = 0;
            EnterCriticalSection(&self.lock);
            putZ(&title, &self.requested_title);
            putZ(&artist, &self.requested_artist);
            request_generation = self.request_generation;
            track_generation = self.requested_track_generation;
            _ = @atomicRmw(i32, &self.request_pending, .Xchg, 0, .seq_cst);
            LeaveCriticalSection(&self.lock);
            if (title[0] == 0) continue;

            var fetched = Lyrics{};
            var reason: [384]u8 = @splat(0);
            const outcome = fetchLyricsDetailed(&title, &artist, fetch_timeout_ms, &fetched, &reason);
            _ = @atomicRmw(i32, &self.fetch_count, .Add, 1, .seq_cst);
            if (self.stop_event) |event| if (WaitForSingleObject(event, 0) == wait_object_0) break;

            EnterCriticalSection(&self.lock);
            if (request_generation != self.request_generation) {
                LeaveCriticalSection(&self.lock);
                continue;
            }
            self.last_answer_was_transient = outcome.transient_failure;
            putZ(&self.last_reason, &reason);
            if (outcome.parsed) {
                self.lyrics = fetched;
                self.result_track_generation = track_generation;
                @atomicStore(bool, &self.have_lyrics, true, .seq_cst);
            } else {
                self.lyrics = .{};
                @atomicStore(bool, &self.have_lyrics, false, .seq_cst);
            }
            _ = @atomicRmw(i32, &self.revision, .Add, 1, .seq_cst);
            LeaveCriticalSection(&self.lock);
        }
        @atomicStore(i32, &self.running_flag, 0, .seq_cst);
    }
};

pub fn workerSmokeCheck() bool {
    var provider = LyricsProvider{};
    if (!provider.start()) return false;
    provider.request("", "", 0); // Empty titles are deliberately ignored and must not touch the network.
    const untouched = !provider.hasLyrics() and provider.getRevision() == 0 and provider.getFetchCount() == 0;
    provider.stop();
    return untouched and @atomicLoad(i32, &provider.running_flag, .seq_cst) == 0 and provider.thread == null;
}

pub fn smokeCheck() bool {
    return LyricsProtocol.smokeCheck();
}

test "lyrics worker starts and joins without an empty-title request" {
    try std.testing.expect(workerSmokeCheck());
}
