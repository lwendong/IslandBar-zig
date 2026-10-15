/// A copied Start Menu entry. It contains no Shell/COM interface pointers.
pub const App = struct {
    name: [112]u16 = @splat(0),
    target: [512]u16 = @splat(0),
};

pub const LaunchResult = struct {
    succeeded: bool = false,
    shell_code: i32 = 0,
};
