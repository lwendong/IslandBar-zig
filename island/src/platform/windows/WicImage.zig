const std = @import("std");

pub const DecodeSlot = enum(i32) { artwork = 0, background = 1, icon = 2, other = 3 };
pub const decode_slot_count: usize = 4;

pub const DecodedImage = struct {
    width: i32 = 0,
    height: i32 = 0,
    pixels: ?[*]const u8 = null,
};

pub const AccentColour = struct {
    r: f32 = 0.40,
    g: f32 = 0.80,
    b: f32 = 0.95,
    from_artwork: bool = false,
};

const png_signature = [_]u8{ 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };

/// Picks saturated, sufficiently opaque pixels and raises their average into an accent color.
/// Input is tightly packed BGRA with premultiplied alpha, as returned by WIC's PBGRA converter.
pub fn accentColourFromArtwork(bgra: []const u8, width: i32, height: i32) AccentColour {
    var result = AccentColour{};
    if (width <= 0 or height <= 0) return result;
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const pixels_count = std.math.mul(usize, w, h) catch return result;
    const needed = std.math.mul(usize, pixels_count, 4) catch return result;
    if (bgra.len < needed) return result;

    const step_x: usize = if (width > 64) w / 64 else 1;
    const step_y: usize = if (height > 64) h / 64 else 1;
    var sum_r: f64 = 0;
    var sum_g: f64 = 0;
    var sum_b: f64 = 0;
    var counted: usize = 0;

    var y: usize = 0;
    while (y < h) : (y += step_y) {
        var x: usize = 0;
        while (x < w) : (x += step_x) {
            const offset = (y * w + x) * 4;
            const alpha = @as(f32, @floatFromInt(bgra[offset + 3])) / 255.0;
            if (alpha < 0.5) continue;

            const r = (@as(f32, @floatFromInt(bgra[offset + 2])) / 255.0) / alpha;
            const g = (@as(f32, @floatFromInt(bgra[offset + 1])) / 255.0) / alpha;
            const b = (@as(f32, @floatFromInt(bgra[offset + 0])) / 255.0) / alpha;
            const high = @max(r, @max(g, b));
            const low = @min(r, @min(g, b));
            if (high - low < 0.12 or high < 0.12) continue;

            sum_r += r;
            sum_g += g;
            sum_b += b;
            counted += 1;
        }
    }
    if (counted == 0) return result;

    const count_f: f64 = @floatFromInt(counted);
    var r: f32 = @floatCast(sum_r / count_f);
    var g: f32 = @floatCast(sum_g / count_f);
    var b: f32 = @floatCast(sum_b / count_f);
    const mean = (r + g + b) / 3.0;
    r = mean + (r - mean) * 1.45;
    g = mean + (g - mean) * 1.45;
    b = mean + (b - mean) * 1.45;

    const high = @max(r, @max(g, b));
    if (high > 0.001) {
        const target: f32 = if (high < 0.80) 0.80 else 0.95;
        const scale = target / high;
        r *= scale;
        g *= scale;
        b *= scale;
    }
    result.r = clamp01(r);
    result.g = clamp01(g);
    result.b = clamp01(b);
    result.from_artwork = true;
    return result;
}

/// Returns the exact end of a complete PNG, or zero for invalid or truncated data.
/// This follows chunk lengths and the IEND marker, rather than returning the caller's capacity.
pub fn pngLength(data: []const u8) usize {
    if (data.len < png_signature.len or !std.mem.eql(u8, data[0..8], &png_signature)) return 0;
    var offset: usize = 8;
    while (offset <= data.len and data.len - offset >= 8) {
        const length: usize = (@as(usize, data[offset]) << 24) |
            (@as(usize, data[offset + 1]) << 16) |
            (@as(usize, data[offset + 2]) << 8) |
            @as(usize, data[offset + 3]);
        if (length > data.len or data.len - offset < 12 or length > data.len - offset - 12) return 0;
        const kind = data[offset + 4 .. offset + 8];
        if (std.mem.eql(u8, kind, "IEND")) return offset + 12;
        offset += 12 + length;
    }
    return 0;
}

/// Writes premultiplied BGRA pixels to a valid RGBA PNG. The deflate stream uses
/// uncompressed blocks: icons are tiny, the output is bounded by the caller, and
/// this keeps PNG writing independent of a C runtime or a third-party zlib DLL.
pub fn encodeBgraToPng(bgra: []const u8, width: i32, height: i32, output: []u8) usize {
    return encodeBgraToPngMode(bgra, width, height, output, true);
}

fn encodeBgraToPngMode(bgra: []const u8, width: i32, height: i32, output: []u8, keep_alpha: bool) usize {
    if (width <= 0 or height <= 0) return 0;
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const stride = std.math.mul(usize, w, 4) catch return 0;
    const source_len = std.math.mul(usize, stride, h) catch return 0;
    if (bgra.len < source_len) return 0;
    const output_pixel_stride: usize = if (keep_alpha) 4 else 3;
    const png_stride = std.math.mul(usize, w, output_pixel_stride) catch return 0;
    const scanline = std.math.add(usize, png_stride, 1) catch return 0;
    const raw_len = std.math.mul(usize, scanline, h) catch return 0;
    const blocks = (raw_len + 65534) / 65535;
    const deflate_overhead = std.math.mul(usize, blocks, 5) catch return 0;
    const zlib_len = std.math.add(usize, 6, std.math.add(usize, raw_len, deflate_overhead) catch return 0) catch return 0;
    const total_len = std.math.add(usize, 57, zlib_len) catch return 0;
    if (output.len < total_len) return 0;

    @memcpy(output[0..8], &png_signature);
    var cursor: usize = 8;
    writeU32(output[cursor .. cursor + 4], 13);
    @memcpy(output[cursor + 4 .. cursor + 8], "IHDR");
    cursor += 8;
    writeU32(output[cursor .. cursor + 4], @intCast(w));
    writeU32(output[cursor + 4 .. cursor + 8], @intCast(h));
    output[cursor + 8] = 8;
    output[cursor + 9] = if (keep_alpha) 6 else 2; // RGBA or RGB
    @memset(output[cursor + 10 .. cursor + 13], 0);
    const ihdr_crc = crc32(output[12 .. cursor + 13]);
    cursor += 13;
    writeU32(output[cursor .. cursor + 4], ihdr_crc);
    cursor += 4;

    const idat_start = cursor;
    writeU32(output[cursor .. cursor + 4], @intCast(zlib_len));
    @memcpy(output[cursor + 4 .. cursor + 8], "IDAT");
    cursor += 8;
    output[cursor] = 0x78;
    output[cursor + 1] = 0x01;
    cursor += 2;

    var raw_offset: usize = 0;
    var adler_a: u32 = 1;
    var adler_b: u32 = 0;
    while (raw_offset < raw_len) {
        const chunk_len: u16 = @intCast(@min(raw_len - raw_offset, 65535));
        const final_block = raw_offset + chunk_len == raw_len;
        output[cursor] = if (final_block) 1 else 0;
        output[cursor + 1] = @truncate(chunk_len);
        output[cursor + 2] = @truncate(chunk_len >> 8);
        const inverted = ~chunk_len;
        output[cursor + 3] = @truncate(inverted);
        output[cursor + 4] = @truncate(inverted >> 8);
        cursor += 5;

        var in_block: usize = 0;
        while (in_block < chunk_len) : (in_block += 1) {
            const raw_index = raw_offset + in_block;
            const row = raw_index / scanline;
            const column = raw_index % scanline;
            var value: u8 = 0;
            if (column != 0) {
                const pixel_offset = row * stride + (column - 1) / output_pixel_stride * 4;
                const channel = (column - 1) % output_pixel_stride;
                const alpha = bgra[pixel_offset + 3];
                value = switch (channel) {
                    0 => unpremultiply(bgra[pixel_offset + 2], alpha),
                    1 => unpremultiply(bgra[pixel_offset + 1], alpha),
                    2 => unpremultiply(bgra[pixel_offset], alpha),
                    else => alpha,
                };
            }
            output[cursor] = value;
            cursor += 1;
            adler_a = (adler_a + value) % 65521;
            adler_b = (adler_b + adler_a) % 65521;
        }
        raw_offset += chunk_len;
    }

    const adler = (adler_b << 16) | adler_a;
    writeU32(output[cursor .. cursor + 4], adler);
    cursor += 4;
    const idat_crc = crc32(output[idat_start + 4 .. cursor]);
    writeU32(output[cursor .. cursor + 4], idat_crc);
    cursor += 4;

    writeU32(output[cursor .. cursor + 4], 0);
    @memcpy(output[cursor + 4 .. cursor + 8], "IEND");
    const iend_crc = crc32(output[cursor + 4 .. cursor + 8]);
    writeU32(output[cursor + 8 .. cursor + 12], iend_crc);
    cursor += 12;
    return if (cursor == total_len) cursor else 0;
}

fn unpremultiply(value: u8, alpha: u8) u8 {
    if (alpha == 0) return 0;
    return @intCast(@min(255, (@as(u32, value) * 255 + alpha / 2) / alpha));
}

fn writeU32(output: []u8, value: u32) void {
    output[0] = @truncate(value >> 24);
    output[1] = @truncate(value >> 16);
    output[2] = @truncate(value >> 8);
    output[3] = @truncate(value);
}

fn crc32(bytes: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (bytes) |byte| {
        crc ^= byte;
        for (0..8) |_| crc = if ((crc & 1) != 0) (crc >> 1) ^ 0xEDB88320 else crc >> 1;
    }
    return ~crc;
}

fn clamp01(value: f32) f32 {
    return @max(0.0, @min(1.0, value));
}

pub fn smokeCheck() bool {
    compileCheck(false);
    const minimal_png = [_]u8{
        0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A,
        0,    0,   0,   0,   'I',  'E',  'N',  'D',
        0,    0,   0,   0,
    };
    if (pngLength(&minimal_png) != minimal_png.len) return false;
    if (pngLength(minimal_png[0 .. minimal_png.len - 1]) != 0) return false;

    const red_pixel = [_]u8{ 0, 0, 255, 255 };
    const accent = accentColourFromArtwork(&red_pixel, 1, 1);
    if (!accent.from_artwork or accent.r < 0.94 or accent.g > 0.2 or accent.b > 0.2) return false;

    const transparent_pixel = [_]u8{ 0, 0, 0, 0 };
    const fallback = accentColourFromArtwork(&transparent_pixel, 1, 1);
    if (fallback.from_artwork or fallback.r != 0.40 or fallback.g != 0.80 or fallback.b != 0.95) return false;
    var encoded: [128]u8 = undefined;
    const encoded_len = encodeBgraToPng(&red_pixel, 1, 1, &encoded);
    if (encoded_len == 0 or pngLength(encoded[0..encoded_len]) != encoded_len) return false;
    return true;
}

/// Exercises the real WIC decode, two-stage blur and PNG encode path used by
/// the media card. The caller initializes COM once for the whole runtime test.
pub fn backgroundBlurCheck() bool {
    var source_pixels: [32 * 24 * 4]u8 = undefined;
    for (0..24) |y| {
        for (0..32) |x| {
            const offset = (y * 32 + x) * 4;
            const warm = ((x / 4 + y / 4) % 2) == 0;
            source_pixels[offset + 0] = if (warm) 24 else 210;
            source_pixels[offset + 1] = if (warm) 96 else 48;
            source_pixels[offset + 2] = if (warm) 228 else 32;
            source_pixels[offset + 3] = 255;
        }
    }
    var source_png: [32 * 24 * 4 + 2048]u8 = undefined;
    const source_len = encodeBgraToPng(&source_pixels, 32, 24, &source_png);
    if (source_len == 0) return false;

    var blurred_png: [32 * 1024]u8 = undefined;
    const blurred_len = makeBlurredBackgroundPng(source_png[0..source_len], 105, 59, &blurred_png);
    if (blurred_len == 0 or pngLength(blurred_png[0..blurred_len]) != blurred_len) return false;

    var decoded = DecodedImage{};
    if (!decodeImage(blurred_png[0..blurred_len], &decoded, .background)) return false;
    return decoded.width == 105 and decoded.height == 59 and decoded.pixels != null;
}

pub fn codecRoundTripStatus(expected_bgra: []const u8, encoded: []u8, encoded_len: usize) u8 {
    const com_result = CoInitializeEx(null, COINIT_APARTMENTTHREADED);
    defer if (com_result >= 0) CoUninitialize();
    if (com_result < 0) return 1;
    var decoded = DecodedImage{};
    if (!decodeImage(encoded[0..encoded_len], &decoded, .other)) return 2;
    const pixels = decoded.pixels orelse return 3;
    if (decoded.width != 1 or decoded.height != 1 or expected_bgra.len < 4) return 4;
    return if (std.mem.eql(u8, pixels[0..4], expected_bgra[0..4])) 0 else 5;
}

/// Type-checks the Windows codec paths without initializing COM during offline smoke tests.
pub fn compileCheck(execute: bool) void {
    if (!execute) return;
    var image = DecodedImage{};
    var png: [64 * 1024]u8 = @splat(0);
    _ = decodeImage(&.{ 0, 1, 2 }, &image, .other);
    _ = reencodeToPng(&.{ 0, 1, 2 }, 96, &png);
    _ = makeBlurredBackgroundPng(&.{ 0, 1, 2 }, 64, 64, &png);
}

const Guid = extern struct { data1: u32, data2: u16, data3: u16, data4: [8]u8 };
extern "ole32" fn CoCreateInstance(class_id: *const Guid, outer: ?*anyopaque, context: u32, iid: *const Guid, result: *?*anyopaque) callconv(.winapi) i32;
extern "ole32" fn CoTaskMemFree(memory: ?*anyopaque) callconv(.winapi) void;
extern "ole32" fn CoInitializeEx(reserved: ?*anyopaque, co_init: u32) callconv(.winapi) i32;
extern "ole32" fn CoUninitialize() callconv(.winapi) void;
extern "ole32" fn CreateStreamOnHGlobal(global: ?*anyopaque, delete_on_release: i32, stream: *?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn GlobalAlloc(flags: u32, bytes: usize) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GlobalLock(global: ?*anyopaque) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn GlobalUnlock(global: ?*anyopaque) callconv(.winapi) i32;
extern "kernel32" fn GlobalFree(global: ?*anyopaque) callconv(.winapi) ?*anyopaque;

const CLSID_WIC_IMAGING_FACTORY = Guid{ .data1 = 0xcacaf262, .data2 = 0x9370, .data3 = 0x4615, .data4 = .{ 0xa1, 0x3b, 0x9f, 0x55, 0x39, 0xda, 0x4c, 0x0a } };
const IID_WIC_IMAGING_FACTORY = Guid{ .data1 = 0xec5ec8a9, .data2 = 0xc395, .data3 = 0x4314, .data4 = .{ 0x9c, 0x77, 0x54, 0xd7, 0xa9, 0x35, 0xff, 0x70 } };
const GUID_WIC_PIXEL_FORMAT_32BPP_PBGRA = Guid{ .data1 = 0x6fddc324, .data2 = 0x4e03, .data3 = 0x4bfe, .data4 = .{ 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x10 } };
const CLSCTX_INPROC_SERVER: u32 = 1;
const COINIT_APARTMENTTHREADED: u32 = 2;
const WIC_DECODE_METADATA_CACHE_ON_DEMAND: u32 = 0;
const WIC_DITHER_NONE: u32 = 0;
const WIC_PALETTE_CUSTOM: u32 = 0;
const HRESULT_OK: i32 = 0;

const ComHeader = extern struct { vtable: [*]const ?*anyopaque };
var factory_mutex: std.atomic.Mutex = .unlocked;
var factory: ?*anyopaque = null;
var decode_mutex: std.atomic.Mutex = .unlocked;
var decode_buffers: [decode_slot_count]?[]u8 = @splat(null);

fn spinLock(mutex: *std.atomic.Mutex) void {
    while (!mutex.tryLock()) std.atomic.spinLoopHint();
}

fn comMethod(comptime T: type, object: *anyopaque, index: usize) T {
    const header: *const ComHeader = @ptrCast(@alignCast(object));
    return @ptrCast(header.vtable[index] orelse unreachable);
}

fn release(object: ?*anyopaque) void {
    if (object) |value| {
        const release_fn = comMethod(*const fn (*anyopaque) callconv(.winapi) u32, value, 2);
        _ = release_fn(value);
    }
}

fn wicFactory() ?*anyopaque {
    spinLock(&factory_mutex);
    defer factory_mutex.unlock();
    if (factory) |value| return value;
    var created: ?*anyopaque = null;
    if (CoCreateInstance(&CLSID_WIC_IMAGING_FACTORY, null, CLSCTX_INPROC_SERVER, &IID_WIC_IMAGING_FACTORY, &created) < 0) return null;
    factory = created;
    return created;
}

fn decodeToBuffer(bytes: []const u8, slot: DecodeSlot, output: *DecodedImage) bool {
    if (bytes.len == 0 or bytes.len > std.math.maxInt(u32)) return false;
    const imaging_factory = wicFactory() orelse return false;
    const slot_index: usize = @intCast(@backingInt(slot));

    const global = GlobalAlloc(2, bytes.len) orelse return false;
    var keep_global = true;
    defer {
        if (keep_global) _ = GlobalFree(global);
    }
    const target = GlobalLock(global) orelse return false;
    @memcpy(@as([*]u8, @ptrCast(target))[0..bytes.len], bytes);
    _ = GlobalUnlock(global);
    var stream: ?*anyopaque = null;
    if (CreateStreamOnHGlobal(global, 1, &stream) < 0 or stream == null) return false;
    keep_global = false;
    defer release(stream);
    const create_decoder = comMethod(*const fn (*anyopaque, *anyopaque, ?*const Guid, u32, *?*anyopaque) callconv(.winapi) i32, imaging_factory, 4);
    var decoder: ?*anyopaque = null;
    const decoder_hr = create_decoder(imaging_factory, stream.?, null, WIC_DECODE_METADATA_CACHE_ON_DEMAND, &decoder);
    if (decoder_hr < 0 or decoder == null) return false;
    defer release(decoder);

    const get_frame = comMethod(*const fn (*anyopaque, u32, *?*anyopaque) callconv(.winapi) i32, decoder.?, 13);
    var frame: ?*anyopaque = null;
    const frame_hr = get_frame(decoder.?, 0, &frame);
    if (frame_hr < 0 or frame == null) return false;
    defer release(frame);
    const get_size = comMethod(*const fn (*anyopaque, *u32, *u32) callconv(.winapi) i32, frame.?, 3);
    var width: u32 = 0;
    var height: u32 = 0;
    const size_hr = get_size(frame.?, &width, &height);
    if (size_hr < 0 or width == 0 or height == 0) return false;
    if (width > std.math.maxInt(u32) / 4) return false;
    const stride = width * 4;
    if (height > std.math.maxInt(u32) / stride) return false;
    const bytes_needed = stride * height;

    const create_converter = comMethod(*const fn (*anyopaque, *?*anyopaque) callconv(.winapi) i32, imaging_factory, 10);
    var converter: ?*anyopaque = null;
    const converter_hr = create_converter(imaging_factory, &converter);
    if (converter_hr < 0 or converter == null) return false;
    defer release(converter);
    // IWICFormatConverter inherits IWICBitmapSource (five methods after IUnknown),
    // so Initialize is slot 8 and CanConvert is slot 9.
    const initialize_converter = comMethod(*const fn (*anyopaque, *anyopaque, *const Guid, u32, ?*anyopaque, f64, u32) callconv(.winapi) i32, converter.?, 8);
    const initialize_hr = initialize_converter(converter.?, frame.?, &GUID_WIC_PIXEL_FORMAT_32BPP_PBGRA, WIC_DITHER_NONE, null, 0.0, WIC_PALETTE_CUSTOM);
    if (initialize_hr < 0) return false;

    spinLock(&decode_mutex);
    defer decode_mutex.unlock();
    if (decode_buffers[slot_index] == null or decode_buffers[slot_index].?.len < bytes_needed) {
        if (decode_buffers[slot_index]) |old| std.heap.page_allocator.free(old);
        decode_buffers[slot_index] = std.heap.page_allocator.alloc(u8, bytes_needed) catch return false;
    }
    const buffer = decode_buffers[slot_index].?;
    const copy_pixels = comMethod(*const fn (*anyopaque, ?*const anyopaque, u32, u32, [*]u8) callconv(.winapi) i32, converter.?, 7);
    if (copy_pixels(converter.?, null, stride, bytes_needed, buffer.ptr) < 0) return false;
    output.width = @intCast(width);
    output.height = @intCast(height);
    output.pixels = buffer.ptr;
    return true;
}

pub fn decodeImage(bytes: []const u8, output: *DecodedImage, slot: DecodeSlot) bool {
    output.* = .{};
    const raw_slot = @backingInt(slot);
    if (raw_slot < 0 or raw_slot >= decode_slot_count) return false;
    return decodeToBuffer(bytes, slot, output);
}

fn scalePixels(source: []const u8, source_width: u32, source_height: u32, target_width: u32, target_height: u32, output: []u8) bool {
    if (source_width == 0 or source_height == 0 or target_width == 0 or target_height == 0) return false;
    if (source_width > std.math.maxInt(u32) / 4 or target_width > std.math.maxInt(u32) / 4) return false;
    const source_stride = source_width * 4;
    const source_len = std.math.mul(u32, source_stride, source_height) catch return false;
    const target_stride = target_width * 4;
    const target_len = std.math.mul(u32, target_stride, target_height) catch return false;
    if (source.len < source_len or output.len < target_len) return false;
    const imaging_factory = wicFactory() orelse return false;
    const create_bitmap = comMethod(*const fn (*anyopaque, u32, u32, *const Guid, u32, u32, [*]u8, *?*anyopaque) callconv(.winapi) i32, imaging_factory, 20);
    var bitmap: ?*anyopaque = null;
    if (create_bitmap(imaging_factory, source_width, source_height, &GUID_WIC_PIXEL_FORMAT_32BPP_PBGRA, source_stride, source_len, @constCast(source.ptr), &bitmap) < 0 or bitmap == null) return false;
    defer release(bitmap);

    const create_scaler = comMethod(*const fn (*anyopaque, *?*anyopaque) callconv(.winapi) i32, imaging_factory, 11);
    var scaler: ?*anyopaque = null;
    if (create_scaler(imaging_factory, &scaler) < 0 or scaler == null) return false;
    defer release(scaler);
    // IWICBitmapScaler also inherits IWICBitmapSource; Initialize is its first
    // interface method at slot 8, not GetSize at slot 3.
    const initialize = comMethod(*const fn (*anyopaque, *anyopaque, u32, u32, u32) callconv(.winapi) i32, scaler.?, 8);
    if (initialize(scaler.?, bitmap.?, target_width, target_height, 3) < 0) return false; // Fant interpolation
    const copy_pixels = comMethod(*const fn (*anyopaque, ?*const anyopaque, u32, u32, [*]u8) callconv(.winapi) i32, scaler.?, 7);
    return copy_pixels(scaler.?, null, target_stride, target_len, output.ptr) >= 0;
}

pub fn reencodeToPng(bytes: []const u8, max_dimension: i32, output: []u8) usize {
    var decoded = DecodedImage{};
    if (!decodeImage(bytes, &decoded, .other)) return 0;
    const width: u32 = @intCast(decoded.width);
    const height: u32 = @intCast(decoded.height);
    if (width == 0 or height == 0 or decoded.pixels == null) return 0;
    const source_stride = std.math.mul(u32, width, 4) catch return 0;
    const source_size = std.math.mul(u32, source_stride, height) catch return 0;
    const source = decoded.pixels.?[0..source_size];
    var target_width = width;
    var target_height = height;
    const long_side = @max(width, height);
    const requested_dimension: u32 = if (max_dimension > 0) @intCast(max_dimension) else 0;
    if (requested_dimension != 0 and long_side > requested_dimension) {
        const scale = @as(f64, @floatFromInt(requested_dimension)) / @as(f64, @floatFromInt(long_side));
        target_width = @max(1, @as(u32, @intFromFloat(@as(f64, @floatFromInt(width)) * scale + 0.5)));
        target_height = @max(1, @as(u32, @intFromFloat(@as(f64, @floatFromInt(height)) * scale + 0.5)));
    }
    if (target_width == width and target_height == height) return encodeBgraToPngMode(source, @intCast(width), @intCast(height), output, false);
    const target_len = std.math.mul(usize, std.math.mul(usize, target_width, target_height) catch return 0, 4) catch return 0;
    const resized = std.heap.page_allocator.alloc(u8, target_len) catch return 0;
    defer std.heap.page_allocator.free(resized);
    if (!scalePixels(source, width, height, target_width, target_height, resized)) return 0;
    return encodeBgraToPngMode(resized, @intCast(target_width), @intCast(target_height), output, false);
}

pub fn makeBlurredBackgroundPng(bytes: []const u8, width: i32, height: i32, output: []u8) usize {
    if (bytes.len == 0 or width <= 0 or height <= 0 or output.len == 0) return 0;
    var decoded = DecodedImage{};
    if (!decodeImage(bytes, &decoded, .background)) return 0;
    const source_width: u32 = @intCast(decoded.width);
    const source_height: u32 = @intCast(decoded.height);
    const target_width: u32 = @intCast(width);
    const target_height: u32 = @intCast(height);
    if (source_width == 0 or source_height == 0 or decoded.pixels == null) return 0;
    const source_size = std.math.mul(usize, std.math.mul(usize, source_width, source_height) catch return 0, 4) catch return 0;
    const tiny_width = target_width / 12 + 1;
    const tiny_height = target_height / 12 + 1;
    const tiny_size = std.math.mul(usize, std.math.mul(usize, tiny_width, tiny_height) catch return 0, 4) catch return 0;
    const tiny = std.heap.page_allocator.alloc(u8, tiny_size) catch return 0;
    defer std.heap.page_allocator.free(tiny);
    if (!scalePixels(decoded.pixels.?[0..source_size], source_width, source_height, tiny_width, tiny_height, tiny)) return 0;

    const full_size = std.math.mul(usize, std.math.mul(usize, target_width, target_height) catch return 0, 4) catch return 0;
    const full = std.heap.page_allocator.alloc(u8, full_size) catch return 0;
    defer std.heap.page_allocator.free(full);
    if (!scalePixels(tiny, tiny_width, tiny_height, target_width, target_height, full)) return 0;
    return encodeBgraToPngMode(full, width, height, output, false);
}
