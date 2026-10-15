const AppIcon = @import("AppIcon");
const AudioService = @import("AudioService");
const AudioVolume = @import("AudioVolume");
const LyricsService = @import("LyricsService");
const LauncherService = @import("LauncherService");
const Log = @import("Log");
const MediaService = @import("MediaService");
const NotificationPipe = @import("NotificationPipe");
const PlayerWindow = @import("PlayerWindow");
const SoundController = @import("SoundController");
const SystemService = @import("SystemService");
const TrayIcons = @import("TrayIcons");
const WeatherService = @import("WeatherService");
const std = @import("std");

pub const SoundPortContext = struct {
    audio_volume: ?*AudioVolume.AudioVolume = null,
    audio_service: ?*AudioService.AudioService = null,
};

/// App-owned Windows runtime services. Startup is best-effort per feature;
/// shutdown is explicit and reverse ordered so no worker outlives its ports.
pub const Runtime = struct {
    notification_server: NotificationPipe.NotificationServer = .{},
    notification_server_started: bool = false,
    shell_allocator: std.mem.Allocator = std.heap.page_allocator,
    tray_icons: TrayIcons.TrayIcons = .{},
    start_apps: LauncherService.StartApps = .{},
    music_session: MediaService.MusicSession = .{},
    music_started: bool = false,
    lyrics_provider: LyricsService.LyricsProvider = .{},
    player_window: PlayerWindow.PlayerWindowWatch = .{},
    player_window_started: bool = false,
    status_reader: SystemService.StatusReader = .{},
    sampled_system_status: SystemService.StatusSnapshot = .{},
    audio_volume: AudioVolume.AudioVolume = .{},
    audio_volume_started: bool = false,
    sound_output: AudioService.AudioService = .{},
    sound_started: bool = false,
    sound_ports: SoundPortContext = .{},
    weather_reader: WeatherService.WeatherReader = .{},
    weather_started: bool = false,
    stopped: bool = false,

    pub fn startBackground(
        self: *Runtime,
        session_available: bool,
        player_window_available: bool,
        no_media: bool,
        no_session: bool,
        app_icon_fetch: AppIcon.FetchPngFn,
    ) void {
        self.notification_server_started = self.notification_server.start(NotificationPipe.pipe_name);
        Log.logLine(if (self.notification_server_started) "notification pipe started" else "notification pipe could not be started");

        self.music_session.app_icon_fetch = app_icon_fetch;
        self.music_started = session_available and self.music_session.start();
        Log.logLine(if (self.music_started)
            "music session worker started"
        else if (no_media)
            "music disabled by ISLANDBAR_NO_MEDIA"
        else if (no_session)
            "music session disabled by ISLANDBAR_NO_SESSION; player-window fallback remains active"
        else if (!session_available and player_window_available)
            "music session disabled; player-window fallback remains active"
        else
            "music session API unavailable; continuing without music");

        const lyrics_started = self.lyrics_provider.start();
        Log.logLine(if (lyrics_started) "lyrics worker started" else "lyrics worker unavailable; continuing without lyrics");

        self.player_window_started = player_window_available and self.player_window.start();
        Log.logLine(if (self.player_window_started)
            "player window fallback started"
        else if (no_media)
            "player window fallback disabled by ISLANDBAR_NO_MEDIA"
        else if (!player_window_available)
            "player window fallback disabled"
        else
            "player window fallback unavailable");

        _ = self.status_reader.open();
        self.status_reader.sample(&self.sampled_system_status);

        self.audio_volume_started = self.audio_volume.start();
        Log.logLine(if (self.audio_volume_started) "audio volume worker started" else "audio volume worker unavailable");

        self.sound_output.app_icon_fetch = app_icon_fetch;
        self.sound_started = self.sound_output.start();
        Log.logLine(if (self.sound_started) "sound output worker started" else "sound output worker unavailable");
        self.sound_ports = .{
            .audio_volume = if (self.audio_volume_started) &self.audio_volume else null,
            .audio_service = if (self.sound_started) &self.sound_output else null,
        };
    }

    pub fn initializeSoundController(self: *Runtime, controller: *SoundController.Controller) void {
        var initial_level: f32 = 0;
        var initial_peak: f32 = 0;
        _ = self.audio_volume.get(&initial_level);
        _ = self.audio_volume.peak(&initial_peak);
        controller.updateMaster(
            self.audio_volume.available(),
            initial_level,
            self.audio_volume.isMuted(),
            initial_peak,
            self.audio_volume.getRevision(),
        );
        controller.updateOutput(if (self.sound_started) self.sound_output.snapshot() else .{});
    }

    pub fn initializeShellResources(self: *Runtime, allocator: std.mem.Allocator) usize {
        self.shell_allocator = allocator;
        const tray_count = self.tray_icons.refresh(allocator);
        Log.logLine(if (tray_count == 0) "tray icon snapshots unavailable or empty" else "tray icon snapshots loaded");
        self.start_apps.loadPins();
        return tray_count;
    }

    pub fn startWeather(self: *Runtime, enabled: bool) void {
        if (!enabled) return;
        self.weather_started = self.weather_reader.start();
        if (!self.weather_started) Log.logLine("weather worker could not be started");
    }

    pub fn stopWeather(self: *Runtime) void {
        if (!self.weather_started) return;
        Log.logLine("shutdown: stopping weather worker");
        self.weather_reader.stop();
        self.weather_started = false;
        Log.logLine("shutdown: weather worker stopped");
    }

    pub fn stop(self: *Runtime) void {
        if (self.stopped) return;
        self.stopped = true;
        self.start_apps.deinit();
        self.tray_icons.deinit(self.shell_allocator);
        self.stopWeather();
        Log.logLine("shutdown: stopping sound-output worker");
        self.sound_output.stop();
        self.sound_started = false;
        Log.logLine("shutdown: sound-output worker stopped");
        self.audio_volume.stop();
        self.status_reader.close();
        if (self.player_window_started) {
            Log.logLine("shutdown: stopping player-window worker");
            self.player_window.stop();
            self.player_window_started = false;
            Log.logLine("shutdown: player-window worker stopped");
        }
        Log.logLine("shutdown: stopping lyrics worker");
        self.lyrics_provider.stop();
        Log.logLine("shutdown: lyrics worker stopped");
        if (self.music_started) {
            Log.logLine("shutdown: stopping music session worker");
            self.music_session.stop();
            self.music_started = false;
            Log.logLine("shutdown: music session worker stopped");
        }
        if (self.notification_server_started) {
            self.notification_server.stop();
            self.notification_server_started = false;
        }
        self.sound_ports = .{};
    }
};

fn requestSoundAction(raw_context: ?*anyopaque, action: *const SoundController.Action, token: u64, result: *SoundController.PortResult) callconv(.c) void {
    const ports: *SoundPortContext = @ptrCast(@alignCast(raw_context orelse {
        result.* = .{ .accepted = false, .hresult = SoundController.hresult_unavailable };
        return;
    }));
    var accepted = false;
    switch (action.*) {
        .refresh => {
            if (ports.audio_service) |service| {
                service.refresh();
                accepted = true;
            }
        },
        .set_master_volume => |level| {
            if (ports.audio_volume) |volume| accepted = volume.setLevelWithToken(level, token);
        },
        .set_master_muted => |muted| {
            if (ports.audio_volume) |volume| accepted = volume.setMutedWithToken(muted, token);
        },
        .set_session_volume => |request| {
            if (ports.audio_service) |service| accepted = service.setSessionVolumeWithToken(request.pid, request.level, token);
        },
        .select_default_device => |request| {
            if (ports.audio_service) |service| accepted = service.setDefaultDeviceWithToken(@import("std").mem.sliceTo(&request.id, 0), token);
        },
    }
    result.* = .{ .accepted = accepted, .hresult = if (accepted) 0 else SoundController.hresult_unavailable };
}

pub fn soundControllerPort(ports: *SoundPortContext) SoundController.Port {
    return .{ .context = @ptrCast(ports), .request_fn = requestSoundAction };
}
