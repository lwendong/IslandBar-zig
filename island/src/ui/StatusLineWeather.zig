/// Public, render-only contribution for the weather segment of the shared
/// status line. Weather Feature code maps source values into this DTO.
pub const Mark = enum { none, sun, sun_cloud, cloud, fog, rain, snow, thunder };

pub const View = struct {
    mark: Mark = .none,
    sky: [24]u16 = @splat(0),
    temperature: [16]u16 = @splat(0),
};
