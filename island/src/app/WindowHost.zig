const AppBar = @import("AppBar");
const Geometry = @import("Geometry");
const IslandWindow = @import("IslandWindow");
const Log = @import("Log");
const Monitor = @import("Monitor");

/// Owns the native bar window, its monitor-derived bounds, and optional AppBar
/// registration. App code supplies callbacks and retains feature/shell state.
pub const WindowHost = struct {
    window: IslandWindow.NativeWindow = .{},
    app_bar: AppBar.AppBar = .{},
    monitor: Monitor.MonitorGeometry = .{},
    dpi: u32 = 96,
    width_px: i32 = 0,
    height_px: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    bar_thickness_px: i32 = 0,
    app_bar_result: AppBar.AppBarResult = .no_window,
    window_created: bool = false,

    pub fn initialize(
        self: *WindowHost,
        reserve_app_bar: bool,
        keep_taskbar: bool,
        paint: IslandWindow.PaintCallback,
        timer: ?IslandWindow.TimerCallback,
    ) bool {
        self.monitor = Monitor.queryMonitor(null);
        self.dpi = self.monitor.dpi;
        self.width_px = Monitor.screenWidth(self.monitor);
        self.height_px = Geometry.dipToPixels(Geometry.window_height_dip, self.dpi);
        self.x = self.monitor.screen.left;
        self.y = self.monitor.screen.top;

        if (!self.window.create(self.x, self.y, self.width_px, self.height_px, 0, paint, timer, @ptrCast(&self.window))) return false;
        self.window_created = true;

        const actual_window_dpi = self.window.dpi();
        if (actual_window_dpi != 0 and actual_window_dpi != self.dpi) {
            self.dpi = actual_window_dpi;
            self.monitor.dpi = actual_window_dpi;
            self.monitor.dpi_y = actual_window_dpi;
            self.height_px = Geometry.dipToPixels(Geometry.window_height_dip, self.dpi);
            if (!self.window.setBounds(self.x, self.y, self.width_px, self.height_px)) return false;
        }

        self.window.setAppBar(&self.app_bar);
        self.bar_thickness_px = Geometry.dipToPixels(Geometry.reserved_bar_height_dip, self.dpi);
        if (reserve_app_bar and !keep_taskbar) {
            self.app_bar_result = self.app_bar.claim(self.window.handle(), .top, self.bar_thickness_px);
            Log.logLine(if (self.app_bar_result == .registered) "appbar: reserved the top work-area strip" else "appbar: reservation failed; using a floating bar");
        }
        return true;
    }

    pub fn destroy(self: *WindowHost) void {
        if (self.window_created) {
            self.window.destroy();
            self.window_created = false;
        }
        self.app_bar.release();
    }

    pub fn messageLoop(self: *WindowHost) i32 {
        return self.window.messageLoop();
    }
};
