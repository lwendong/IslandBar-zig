/// Pixel-space values shared by thumbnail layout and the Windows DWM adapter.
pub const Rect = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
pub const Size = extern struct { cx: i32, cy: i32 };

pub const Placement = struct {
    card: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    picture: Rect = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    valid: bool = false,
};
