/// Returns PNG bytes for a file's associated icon in the caller-owned buffer.
/// A zero result means the icon could not be obtained or the buffer was too small.
pub const FetchPngFn = *const fn (executable_path: []const u16, output: []u8) usize;

pub fn unavailable(_: []const u16, _: []u8) usize {
    return 0;
}
