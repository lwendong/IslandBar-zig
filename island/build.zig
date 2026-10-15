const std = @import("std");

const NamedModule = struct {
    name: []const u8,
    module: *std.Build.Module,
};

fn sourceModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, path: []const u8) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path(path),
        .target = target,
        .optimize = optimize,
    });
}

fn moduleByName(modules: []const NamedModule, name: []const u8) *std.Build.Module {
    for (modules) |entry| {
        if (std.mem.eql(u8, entry.name, name)) return entry.module;
    }
    unreachable;
}

fn bindModules(module: *std.Build.Module, modules: []const NamedModule, dependencies: []const []const u8) void {
    for (dependencies) |name| module.addImport(name, moduleByName(modules, name));
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const modules = [_]NamedModule{
        .{ .name = "AppIcon", .module = sourceModule(b, target, optimize, "src/platform/contracts/AppIcon.zig") },
        .{ .name = "AppIconService", .module = sourceModule(b, target, optimize, "src/platform/windows/AppIconService.zig") },
        .{ .name = "AppRuntime", .module = sourceModule(b, target, optimize, "src/app/Runtime.zig") },
        .{ .name = "AppWindowHost", .module = sourceModule(b, target, optimize, "src/app/WindowHost.zig") },
        .{ .name = "AppBar", .module = sourceModule(b, target, optimize, "src/platform/windows/AppBar.zig") },
        .{ .name = "AudioService", .module = sourceModule(b, target, optimize, "src/platform/windows/AudioService.zig") },
        .{ .name = "AudioVolume", .module = sourceModule(b, target, optimize, "src/platform/windows/AudioVolume.zig") },
        .{ .name = "CardLayout", .module = sourceModule(b, target, optimize, "src/core/CardLayout.zig") },
        .{ .name = "Canvas", .module = sourceModule(b, target, optimize, "src/ui/Canvas.zig") },
        .{ .name = "CommandLine", .module = sourceModule(b, target, optimize, "src/app/CommandLine.zig") },
        .{ .name = "Diagnostics", .module = sourceModule(b, target, optimize, "src/app/Diagnostics.zig") },
        .{ .name = "DisplayBrightness", .module = sourceModule(b, target, optimize, "src/platform/windows/DisplayBrightness.zig") },
        .{ .name = "DrawLifecycle", .module = sourceModule(b, target, optimize, "src/ui/DrawLifecycle.zig") },
        .{ .name = "Geometry", .module = sourceModule(b, target, optimize, "src/core/Geometry.zig") },
        .{ .name = "InputRegion", .module = sourceModule(b, target, optimize, "src/core/InputRegion.zig") },
        .{ .name = "LayoutSnapshot", .module = sourceModule(b, target, optimize, "src/ui/LayoutSnapshot.zig") },
        .{ .name = "InputRouter", .module = sourceModule(b, target, optimize, "src/ui/InputRouter.zig") },
        .{ .name = "GlassMaterial", .module = sourceModule(b, target, optimize, "src/ui/GlassMaterial.zig") },
        .{ .name = "IslandWindow", .module = sourceModule(b, target, optimize, "src/platform/windows/IslandWindow.zig") },
        .{ .name = "Log", .module = sourceModule(b, target, optimize, "src/platform/windows/Log.zig") },
        .{ .name = "LyricsService", .module = sourceModule(b, target, optimize, "src/platform/windows/LyricsService.zig") },
        .{ .name = "LyricsProtocol", .module = sourceModule(b, target, optimize, "src/platform/contracts/LyricsProtocol.zig") },
        .{ .name = "LauncherCatalog", .module = sourceModule(b, target, optimize, "src/platform/contracts/LauncherCatalog.zig") },
        .{ .name = "LauncherController", .module = sourceModule(b, target, optimize, "src/features/launcher/Controller.zig") },
        .{ .name = "LauncherPage", .module = sourceModule(b, target, optimize, "src/features/launcher/ui/Page.zig") },
        .{ .name = "LauncherService", .module = sourceModule(b, target, optimize, "src/platform/windows/LauncherService.zig") },
        .{ .name = "ShellCommand", .module = sourceModule(b, target, optimize, "src/platform/windows/ShellCommand.zig") },
        .{ .name = "TrayCatalog", .module = sourceModule(b, target, optimize, "src/platform/contracts/TrayCatalog.zig") },
        .{ .name = "TrayController", .module = sourceModule(b, target, optimize, "src/features/tray/Controller.zig") },
        .{ .name = "TrayPage", .module = sourceModule(b, target, optimize, "src/features/tray/ui/Page.zig") },
        .{ .name = "MixerSlider", .module = sourceModule(b, target, optimize, "src/features/sound/ui/MixerSlider.zig") },
        .{ .name = "MiniJson", .module = sourceModule(b, target, optimize, "src/core/MiniJson.zig") },
        .{ .name = "Monitor", .module = sourceModule(b, target, optimize, "src/platform/windows/Monitor.zig") },
        .{ .name = "Motion", .module = sourceModule(b, target, optimize, "src/core/Motion.zig") },
        .{ .name = "MusicController", .module = sourceModule(b, target, optimize, "src/features/music/Controller.zig") },
        .{ .name = "MusicMedia", .module = sourceModule(b, target, optimize, "src/platform/contracts/MusicMedia.zig") },
        .{ .name = "MusicPage", .module = sourceModule(b, target, optimize, "src/features/music/ui/Page.zig") },
        .{ .name = "MusicLyrics", .module = sourceModule(b, target, optimize, "src/features/music/Lyrics.zig") },
        .{ .name = "MediaService", .module = sourceModule(b, target, optimize, "src/platform/windows/MediaService.zig") },
        .{ .name = "NativeTaskbar", .module = sourceModule(b, target, optimize, "src/platform/windows/NativeTaskbar.zig") },
        .{ .name = "Notification", .module = sourceModule(b, target, optimize, "src/features/notification/Controller.zig") },
        .{ .name = "NotificationIcon", .module = sourceModule(b, target, optimize, "src/platform/windows/NotificationIcon.zig") },
        .{ .name = "NotificationInput", .module = sourceModule(b, target, optimize, "src/platform/contracts/NotificationInput.zig") },
        .{ .name = "NotificationPage", .module = sourceModule(b, target, optimize, "src/features/notification/ui/Page.zig") },
        .{ .name = "NotificationPipe", .module = sourceModule(b, target, optimize, "src/platform/windows/NotificationPipe.zig") },
        .{ .name = "PlayerWindow", .module = sourceModule(b, target, optimize, "src/ui/PlayerWindow.zig") },
        .{ .name = "Renderer", .module = sourceModule(b, target, optimize, "src/ui/Renderer.zig") },
        .{ .name = "PresentationPolicy", .module = sourceModule(b, target, optimize, "src/shell/PresentationPolicy.zig") },
        .{ .name = "PagePainter", .module = sourceModule(b, target, optimize, "src/ui/PagePainter.zig") },
        .{ .name = "SoundAudio", .module = sourceModule(b, target, optimize, "src/platform/contracts/SoundAudio.zig") },
        .{ .name = "SoundController", .module = sourceModule(b, target, optimize, "src/features/sound/Controller.zig") },
        .{ .name = "SoundPage", .module = sourceModule(b, target, optimize, "src/features/sound/ui/Page.zig") },
        .{ .name = "StatePolicy", .module = sourceModule(b, target, optimize, "src/core/StatePolicy.zig") },
        .{ .name = "SystemController", .module = sourceModule(b, target, optimize, "src/features/system/Controller.zig") },
        .{ .name = "SystemLayout", .module = sourceModule(b, target, optimize, "src/features/system/ui/Layout.zig") },
        .{ .name = "SystemPage", .module = sourceModule(b, target, optimize, "src/features/system/ui/Page.zig") },
        .{ .name = "SystemPanelPresentation", .module = sourceModule(b, target, optimize, "src/ui/SystemPanelPresentation.zig") },
        .{ .name = "Slider", .module = sourceModule(b, target, optimize, "src/ui/Slider.zig") },
        .{ .name = "SysStatusProbe", .module = sourceModule(b, target, optimize, "src/platform/windows/SysStatusProbe.zig") },
        .{ .name = "SystemStatus", .module = sourceModule(b, target, optimize, "src/platform/windows/SystemStatus.zig") },
        .{ .name = "SystemStatusContract", .module = sourceModule(b, target, optimize, "src/platform/contracts/SystemStatus.zig") },
        .{ .name = "SystemService", .module = sourceModule(b, target, optimize, "src/platform/windows/SystemService.zig") },
        .{ .name = "SystemToggles", .module = sourceModule(b, target, optimize, "src/platform/windows/SystemToggles.zig") },
        .{ .name = "TaskbarCatalog", .module = sourceModule(b, target, optimize, "src/platform/contracts/TaskbarCatalog.zig") },
        .{ .name = "TaskbarController", .module = sourceModule(b, target, optimize, "src/features/taskbar/Controller.zig") },
        .{ .name = "TaskbarLayout", .module = sourceModule(b, target, optimize, "src/features/taskbar/ui/Layout.zig") },
        .{ .name = "TaskbarPage", .module = sourceModule(b, target, optimize, "src/features/taskbar/ui/Page.zig") },
        .{ .name = "BarControlLayout", .module = sourceModule(b, target, optimize, "src/core/BarControlLayout.zig") },
        .{ .name = "TextRenderer", .module = sourceModule(b, target, optimize, "src/ui/TextRenderer.zig") },
        .{ .name = "Theme", .module = sourceModule(b, target, optimize, "src/ui/Theme.zig") },
        .{ .name = "ThemeTokens", .module = sourceModule(b, target, optimize, "src/ui/ThemeTokens.zig") },
        .{ .name = "TaskbarPresentation", .module = sourceModule(b, target, optimize, "src/ui/TaskbarPresentation.zig") },
        .{ .name = "ThumbnailAdapter", .module = sourceModule(b, target, optimize, "src/platform/windows/ThumbnailAdapter.zig") },
        .{ .name = "ThumbnailContract", .module = sourceModule(b, target, optimize, "src/platform/contracts/Thumbnail.zig") },
        .{ .name = "ThumbnailLayout", .module = sourceModule(b, target, optimize, "src/features/taskbar/ui/ThumbnailLayout.zig") },
        .{ .name = "ToastStore", .module = sourceModule(b, target, optimize, "src/platform/windows/ToastStore.zig") },
        .{ .name = "TrayIcons", .module = sourceModule(b, target, optimize, "src/platform/windows/TrayIcons.zig") },
        .{ .name = "TrayPress", .module = sourceModule(b, target, optimize, "src/platform/windows/TrayPress.zig") },
        .{ .name = "StatusLineWeather", .module = sourceModule(b, target, optimize, "src/ui/StatusLineWeather.zig") },
        .{ .name = "WeatherController", .module = sourceModule(b, target, optimize, "src/features/weather/Controller.zig") },
        .{ .name = "WeatherData", .module = sourceModule(b, target, optimize, "src/platform/contracts/WeatherData.zig") },
        .{ .name = "WeatherPage", .module = sourceModule(b, target, optimize, "src/features/weather/ui/Page.zig") },
        .{ .name = "WeatherService", .module = sourceModule(b, target, optimize, "src/platform/windows/WeatherService.zig") },
        .{ .name = "WeChatWatch", .module = sourceModule(b, target, optimize, "src/platform/windows/WeChatAdapter.zig") },
        .{ .name = "WicImage", .module = sourceModule(b, target, optimize, "src/platform/windows/WicImage.zig") },
        .{ .name = "WindowList", .module = sourceModule(b, target, optimize, "src/platform/windows/WindowList.zig") },
    };

    // Each source module has its own root; dependencies are wired explicitly so
    // modules cannot silently reach across categories at compile time.
    bindModules(moduleByName(&modules, "AppBar"), &modules, &.{ "Monitor", "Log" });
    bindModules(moduleByName(&modules, "AppRuntime"), &modules, &.{ "AppIcon", "AudioService", "AudioVolume", "LauncherService", "LyricsService", "Log", "MediaService", "NotificationPipe", "PlayerWindow", "SoundController", "SystemService", "TrayIcons", "WeatherService" });
    bindModules(moduleByName(&modules, "AppWindowHost"), &modules, &.{ "AppBar", "Geometry", "IslandWindow", "Log", "Monitor" });
    bindModules(moduleByName(&modules, "AppIconService"), &modules, &.{"WicImage"});
    bindModules(moduleByName(&modules, "CardLayout"), &modules, &.{"Geometry"});
    bindModules(moduleByName(&modules, "Canvas"), &modules, &.{ "Geometry", "ThemeTokens" });
    bindModules(moduleByName(&modules, "CommandLine"), &modules, &.{"Motion"});
    bindModules(moduleByName(&modules, "DrawLifecycle"), &modules, &.{});
    bindModules(moduleByName(&modules, "Diagnostics"), &modules, &.{ "Geometry", "Motion", "StatePolicy", "CardLayout", "IslandWindow", "LyricsService", "MusicLyrics", "MiniJson", "Monitor", "MediaService", "Notification", "Renderer", "TextRenderer", "Theme", "WicImage", "Log" });
    bindModules(moduleByName(&modules, "GlassMaterial"), &modules, &.{"Theme"});
    bindModules(moduleByName(&modules, "IslandWindow"), &modules, &.{"AppBar"});
    bindModules(moduleByName(&modules, "InputRegion"), &modules, &.{ "Geometry", "Motion", "BarControlLayout" });
    bindModules(moduleByName(&modules, "LayoutSnapshot"), &modules, &.{"Geometry"});
    bindModules(moduleByName(&modules, "PagePainter"), &modules, &.{ "Geometry", "LayoutSnapshot", "TextRenderer" });
    bindModules(moduleByName(&modules, "InputRouter"), &modules, &.{"LayoutSnapshot"});
    bindModules(moduleByName(&modules, "LyricsService"), &modules, &.{"LyricsProtocol"});
    bindModules(moduleByName(&modules, "LyricsProtocol"), &modules, &.{"MiniJson"});
    bindModules(moduleByName(&modules, "LauncherController"), &modules, &.{"LauncherCatalog"});
    bindModules(moduleByName(&modules, "LauncherPage"), &modules, &.{ "Geometry", "LayoutSnapshot", "LauncherCatalog", "LauncherController", "TextRenderer", "Theme" });
    bindModules(moduleByName(&modules, "LauncherService"), &modules, &.{ "LauncherCatalog", "WicImage" });
    bindModules(moduleByName(&modules, "TrayIcons"), &modules, &.{"TrayCatalog"});
    bindModules(moduleByName(&modules, "TrayController"), &modules, &.{"TrayCatalog"});
    bindModules(moduleByName(&modules, "TrayPage"), &modules, &.{ "Geometry", "LayoutSnapshot", "TextRenderer", "Theme", "TrayCatalog", "TrayController" });
    bindModules(moduleByName(&modules, "MusicLyrics"), &modules, &.{"LyricsProtocol"});
    bindModules(moduleByName(&modules, "Motion"), &modules, &.{"Geometry"});
    bindModules(moduleByName(&modules, "MusicController"), &modules, &.{ "MusicMedia", "MusicLyrics" });
    bindModules(moduleByName(&modules, "MusicPage"), &modules, &.{ "Geometry", "LayoutSnapshot", "TextRenderer", "ThemeTokens" });
    bindModules(moduleByName(&modules, "MixerSlider"), &modules, &.{ "Slider", "ThemeTokens" });
    bindModules(moduleByName(&modules, "MediaService"), &modules, &.{ "AppIcon", "Log", "MusicMedia", "WicImage" });
    bindModules(moduleByName(&modules, "NativeTaskbar"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "Notification"), &modules, &.{"NotificationInput"});
    bindModules(moduleByName(&modules, "NotificationIcon"), &modules, &.{ "AppIcon", "WicImage", "Log", "NotificationInput" });
    bindModules(moduleByName(&modules, "NotificationInput"), &modules, &.{"MiniJson"});
    bindModules(moduleByName(&modules, "NotificationPage"), &modules, &.{ "Geometry", "LayoutSnapshot", "PagePainter", "TextRenderer", "Theme" });
    bindModules(moduleByName(&modules, "NotificationPipe"), &modules, &.{ "Log", "MiniJson", "NotificationInput" });
    bindModules(moduleByName(&modules, "Renderer"), &modules, &.{ "AppIcon", "DrawLifecycle", "Geometry", "LayoutSnapshot", "Motion", "PagePainter", "TaskbarPresentation", "BarControlLayout", "TextRenderer", "Theme", "StatusLineWeather", "WicImage" });
    bindModules(moduleByName(&modules, "AudioService"), &modules, &.{ "AppIcon", "Log", "SoundAudio" });
    bindModules(moduleByName(&modules, "AudioVolume"), &modules, &.{"SoundAudio"});
    bindModules(moduleByName(&modules, "SoundController"), &modules, &.{"SoundAudio"});
    bindModules(moduleByName(&modules, "SoundPage"), &modules, &.{ "Geometry", "LayoutSnapshot", "SoundAudio", "SoundController", "MixerSlider", "Slider", "ThemeTokens", "TextRenderer" });
    bindModules(moduleByName(&modules, "StatePolicy"), &modules, &.{"Motion"});
    bindModules(moduleByName(&modules, "SystemController"), &modules, &.{"SystemStatusContract"});
    bindModules(moduleByName(&modules, "SystemLayout"), &modules, &.{ "Geometry", "SystemPanelPresentation" });
    bindModules(moduleByName(&modules, "SystemPage"), &modules, &.{ "Geometry", "SystemController", "SystemStatusContract", "SystemLayout", "SystemPanelPresentation", "TextRenderer", "Theme" });
    bindModules(moduleByName(&modules, "SystemPanelPresentation"), &modules, &.{"Geometry"});
    bindModules(moduleByName(&modules, "SysStatusProbe"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "SystemStatus"), &modules, &.{ "Log", "SystemToggles", "SystemStatusContract" });
    bindModules(moduleByName(&modules, "SystemService"), &modules, &.{ "DisplayBrightness", "SystemStatus", "SystemToggles" });
    bindModules(moduleByName(&modules, "SystemToggles"), &modules, &.{"ShellCommand"});
    bindModules(moduleByName(&modules, "TaskbarController"), &modules, &.{"TaskbarCatalog"});
    bindModules(moduleByName(&modules, "TaskbarLayout"), &modules, &.{ "Geometry", "Motion", "BarControlLayout" });
    bindModules(moduleByName(&modules, "TaskbarPage"), &modules, &.{ "Geometry", "TaskbarCatalog", "TaskbarLayout", "TaskbarPresentation", "TextRenderer" });
    bindModules(moduleByName(&modules, "ThumbnailAdapter"), &modules, &.{"ThumbnailContract"});
    bindModules(moduleByName(&modules, "ThumbnailLayout"), &modules, &.{"ThumbnailContract"});
    bindModules(moduleByName(&modules, "BarControlLayout"), &modules, &.{ "Geometry", "Motion" });
    bindModules(moduleByName(&modules, "TaskbarPresentation"), &modules, &.{ "Geometry", "TextRenderer" });
    bindModules(moduleByName(&modules, "Slider"), &modules, &.{ "Canvas", "Geometry", "ThemeTokens" });
    bindModules(moduleByName(&modules, "TextRenderer"), &modules, &.{ "Canvas", "Geometry", "GlassMaterial", "Slider", "BarControlLayout", "SystemPanelPresentation", "Theme", "StatusLineWeather", "WicImage" });
    bindModules(moduleByName(&modules, "Theme"), &modules, &.{"ThemeTokens"});
    bindModules(moduleByName(&modules, "ToastStore"), &modules, &.{"NotificationInput"});
    bindModules(moduleByName(&modules, "WeatherController"), &modules, &.{"WeatherData"});
    bindModules(moduleByName(&modules, "WeatherPage"), &modules, &.{ "WeatherController", "WeatherData", "StatusLineWeather" });
    bindModules(moduleByName(&modules, "WeatherService"), &modules, &.{ "Log", "WeatherData" });
    bindModules(moduleByName(&modules, "WeChatWatch"), &modules, &.{ "NotificationInput", "Log" });
    bindModules(moduleByName(&modules, "WindowList"), &modules, &.{ "Monitor", "TaskbarCatalog" });

    const setup_module = sourceModule(b, target, optimize, "setup/Setup.zig");
    const main_module = sourceModule(b, target, optimize, "src/app/main.zig");
    bindModules(main_module, &modules, &.{ "AppIcon", "AppIconService", "AppRuntime", "AppWindowHost", "DrawLifecycle", "Geometry", "GlassMaterial", "WicImage", "AppBar", "AudioService", "AudioVolume", "WeatherService", "WeatherController", "WeatherPage", "StatusLineWeather", "MediaService", "MusicMedia", "MusicController", "MusicPage", "LyricsService", "MusicLyrics", "SoundController", "SoundPage", "LauncherCatalog", "LauncherController", "LauncherPage", "LauncherService", "ShellCommand", "TrayCatalog", "TrayController", "TrayPage", "TrayPress", "TaskbarCatalog", "TaskbarController", "TaskbarLayout", "TaskbarPage", "Renderer", "PresentationPolicy", "Diagnostics", "IslandWindow", "InputRegion", "LayoutSnapshot", "InputRouter", "TextRenderer", "Log", "Motion", "CommandLine", "PlayerWindow", "SystemService", "SystemController", "SystemPage", "SystemLayout", "Monitor", "NativeTaskbar", "NotificationIcon", "NotificationInput", "NotificationPage", "NotificationPipe", "StatePolicy", "SysStatusProbe", "ThumbnailAdapter", "ThumbnailContract", "ThumbnailLayout", "Theme", "ToastStore", "TrayIcons", "WindowList", "WeChatWatch", "BarControlLayout", "CardLayout", "MiniJson", "Notification" });
    main_module.addImport("Setup", setup_module);

    const exe = b.addExecutable(.{
        .name = "IslandBar",
        .root_module = main_module,
        .win32_manifest = b.path("res/windows/island_bar.manifest"),
    });
    main_module.addWin32ResourceFile(.{ .file = b.path("res/windows/island_bar.rc") });
    inline for (.{
        "dwmapi",  "advapi32",         "version", "powrprof", "d3d11",   "d2d1",     "dcomp", "dxgi",
        "dwrite",  "dxva2",            "gdi32",   "shcore",   "user32",  "kernel32", "ole32", "oleaut32",
        "shell32", "uiautomationcore", "wlanapi", "bthprops", "winhttp",
    }) |library| main_module.linkSystemLibrary(library, .{});
    exe.subsystem = .windows;
    b.installArtifact(exe);

    // Embed the built app in the single-file installer.
    const payload_files = b.addWriteFiles();
    _ = payload_files.addCopyFile(exe.getEmittedBin(), "payload.bin");
    const payload_source = payload_files.add("Payload.zig", "pub const bytes = @embedFile(\"payload.bin\");\n");
    const payload_module = b.createModule(.{
        .root_source_file = payload_source,
        .target = target,
        .optimize = optimize,
    });
    const setup_exe_module = sourceModule(b, target, optimize, "setup/main.zig");
    setup_exe_module.addImport("Setup", setup_module);
    setup_exe_module.addImport("Payload", payload_module);
    const setup_exe = b.addExecutable(.{ .name = "IslandBarSetup", .root_module = setup_exe_module });
    inline for (.{ "advapi32", "ole32", "shell32", "user32", "kernel32" }) |library| setup_exe_module.linkSystemLibrary(library, .{});
    setup_exe.subsystem = .windows;
    b.installArtifact(setup_exe);
    const setup_build_step = b.step("setup-build", "Build the single-file IslandBar installer");
    setup_build_step.dependOn(&setup_exe.step);

    const run_step = b.step("run", "Run IslandBar");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();
    run_step.dependOn(&run_cmd.step);

    const json_probe_module = sourceModule(b, target, optimize, "tools/jsonprobe/main.zig");
    bindModules(json_probe_module, &modules, &.{ "MiniJson", "Notification", "NotificationInput" });
    const json_probe = b.addExecutable(.{ .name = "jsonprobe", .root_module = json_probe_module });
    const json_probe_step = b.step("jsonprobe", "Run the translated JSON and notification probe");
    json_probe_step.dependOn(&b.addRunArtifact(json_probe).step);

    const thumb_probe_module = sourceModule(b, target, optimize, "tools/thumbprobe/main.zig");
    thumb_probe_module.linkSystemLibrary("dwmapi", .{});
    const thumb_probe = b.addExecutable(.{ .name = "thumbprobe", .root_module = thumb_probe_module });
    b.installArtifact(thumb_probe);
    const thumb_probe_build_step = b.step("thumbprobe-build", "Compile the translated DWM thumbnail probe");
    thumb_probe_build_step.dependOn(&thumb_probe.step);
    const thumb_probe_run_step = b.step("thumbprobe", "Run the DWM thumbnail probe");
    const run_thumb_probe = b.addRunArtifact(thumb_probe);
    run_thumb_probe.addPassthruArgs();
    thumb_probe_run_step.dependOn(&run_thumb_probe.step);

    const status_probe_module = moduleByName(&modules, "SysStatusProbe");
    status_probe_module.linkSystemLibrary("wlanapi", .{});
    status_probe_module.linkSystemLibrary("bthprops", .{});
    const status_probe = b.addExecutable(.{ .name = "sysstatusprobe", .root_module = status_probe_module });
    b.installArtifact(status_probe);
    const status_probe_build_step = b.step("sysstatusprobe-build", "Compile the translated WLAN and Bluetooth probe");
    status_probe_build_step.dependOn(&status_probe.step);
    const status_probe_run_step = b.step("sysstatusprobe", "Run the WLAN and Bluetooth probe");
    status_probe_run_step.dependOn(&b.addRunArtifact(status_probe).step);

    const native_smoke_module = sourceModule(b, target, optimize, "tools/smoke/main.zig");
    inline for (.{ "d3d11", "d2d1", "dcomp", "dwrite", "shcore", "dwmapi", "shell32", "ole32" }) |library| native_smoke_module.linkSystemLibrary(library, .{});
    const native_smoke = b.addExecutable(.{ .name = "native-smoke", .root_module = native_smoke_module });
    b.installArtifact(native_smoke);
    const native_smoke_build_step = b.step("native-smoke-build", "Compile the translated native API smoke probe");
    native_smoke_build_step.dependOn(&native_smoke.step);
    const native_smoke_run_step = b.step("native-smoke", "Run the translated native API smoke probe");
    native_smoke_run_step.dependOn(&b.addRunArtifact(native_smoke).step);

    const geoprobe_module = sourceModule(b, target, optimize, "tools/geoprobe/main.zig");
    geoprobe_module.linkSystemLibrary("advapi32", .{});
    const geoprobe = b.addExecutable(.{ .name = "geoprobe", .root_module = geoprobe_module });
    b.installArtifact(geoprobe);
    const geoprobe_build = b.step("geoprobe-build", "Compile the translated Windows location probe");
    geoprobe_build.dependOn(&geoprobe.step);

    const gsmtcprobe_module = sourceModule(b, target, optimize, "tools/gsmtcprobe/main.zig");
    const gsmtcprobe = b.addExecutable(.{ .name = "gsmtcprobe", .root_module = gsmtcprobe_module });
    b.installArtifact(gsmtcprobe);
    const gsmtcprobe_build = b.step("gsmtcprobe-build", "Compile the translated GSMTC probe");
    gsmtcprobe_build.dependOn(&gsmtcprobe.step);

    const state_policy_tests = b.addTest(.{ .root_module = moduleByName(&modules, "StatePolicy") });
    const run_state_policy_tests = b.addRunArtifact(state_policy_tests);
    const presentation_policy_tests = b.addTest(.{ .root_module = moduleByName(&modules, "PresentationPolicy") });
    const run_presentation_policy_tests = b.addRunArtifact(presentation_policy_tests);
    const icon_service_tests = b.addTest(.{ .root_module = moduleByName(&modules, "AppIconService") });
    inline for (.{ "kernel32", "user32", "gdi32", "shell32" }) |library| icon_service_tests.root_module.linkSystemLibrary(library, .{});
    const run_icon_service_tests = b.addRunArtifact(icon_service_tests);
    const audio_service_tests = b.addTest(.{ .root_module = moduleByName(&modules, "AudioService") });
    inline for (.{ "kernel32", "user32", "ole32", "uuid", "mmdevapi" }) |library| audio_service_tests.root_module.linkSystemLibrary(library, .{});
    const run_audio_service_tests = b.addRunArtifact(audio_service_tests);
    const draw_lifecycle_tests = b.addTest(.{ .root_module = moduleByName(&modules, "DrawLifecycle") });
    const run_draw_lifecycle_tests = b.addRunArtifact(draw_lifecycle_tests);
    const layout_snapshot_tests = b.addTest(.{ .root_module = moduleByName(&modules, "LayoutSnapshot") });
    const run_layout_snapshot_tests = b.addRunArtifact(layout_snapshot_tests);
    const input_router_tests = b.addTest(.{ .root_module = moduleByName(&modules, "InputRouter") });
    const run_input_router_tests = b.addRunArtifact(input_router_tests);
    const slider_tests = b.addTest(.{ .root_module = moduleByName(&modules, "Slider") });
    const run_slider_tests = b.addRunArtifact(slider_tests);
    const mixer_slider_tests = b.addTest(.{ .root_module = moduleByName(&modules, "MixerSlider") });
    const run_mixer_slider_tests = b.addRunArtifact(mixer_slider_tests);
    const theme_token_tests = b.addTest(.{ .root_module = moduleByName(&modules, "ThemeTokens") });
    const run_theme_token_tests = b.addRunArtifact(theme_token_tests);
    const theme_tests = b.addTest(.{ .root_module = moduleByName(&modules, "Theme") });
    const run_theme_tests = b.addRunArtifact(theme_tests);
    const sound_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SoundController") });
    const run_sound_controller_tests = b.addRunArtifact(sound_controller_tests);
    const sound_contract_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SoundAudio") });
    const run_sound_contract_tests = b.addRunArtifact(sound_contract_tests);
    const sound_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SoundPage") });
    const run_sound_page_tests = b.addRunArtifact(sound_page_tests);
    const launcher_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "LauncherController") });
    const run_launcher_controller_tests = b.addRunArtifact(launcher_controller_tests);
    const launcher_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "LauncherPage") });
    const run_launcher_page_tests = b.addRunArtifact(launcher_page_tests);
    const tray_catalog_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TrayCatalog") });
    const run_tray_catalog_tests = b.addRunArtifact(tray_catalog_tests);
    const tray_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TrayController") });
    const run_tray_controller_tests = b.addRunArtifact(tray_controller_tests);
    const tray_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TrayPage") });
    const run_tray_page_tests = b.addRunArtifact(tray_page_tests);
    const taskbar_catalog_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TaskbarCatalog") });
    const run_taskbar_catalog_tests = b.addRunArtifact(taskbar_catalog_tests);
    const taskbar_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TaskbarController") });
    const run_taskbar_controller_tests = b.addRunArtifact(taskbar_controller_tests);
    const taskbar_layout_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TaskbarLayout") });
    const run_taskbar_layout_tests = b.addRunArtifact(taskbar_layout_tests);
    const taskbar_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TaskbarPage") });
    const run_taskbar_page_tests = b.addRunArtifact(taskbar_page_tests);
    const system_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SystemController") });
    const run_system_controller_tests = b.addRunArtifact(system_controller_tests);
    const system_layout_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SystemLayout") });
    const run_system_layout_tests = b.addRunArtifact(system_layout_tests);
    const system_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SystemPage") });
    const run_system_page_tests = b.addRunArtifact(system_page_tests);
    const system_status_contract_tests = b.addTest(.{ .root_module = moduleByName(&modules, "SystemStatusContract") });
    const run_system_status_contract_tests = b.addRunArtifact(system_status_contract_tests);
    const thumbnail_layout_tests = b.addTest(.{ .root_module = moduleByName(&modules, "ThumbnailLayout") });
    const run_thumbnail_layout_tests = b.addRunArtifact(thumbnail_layout_tests);
    const bar_control_layout_tests = b.addTest(.{ .root_module = moduleByName(&modules, "BarControlLayout") });
    const run_bar_control_layout_tests = b.addRunArtifact(bar_control_layout_tests);
    const window_list_tests = b.addTest(.{ .root_module = moduleByName(&modules, "WindowList") });
    inline for (.{ "kernel32", "user32", "dwmapi" }) |library| window_list_tests.root_module.linkSystemLibrary(library, .{});
    const run_window_list_tests = b.addRunArtifact(window_list_tests);
    const notification_tests = b.addTest(.{ .root_module = moduleByName(&modules, "Notification") });
    const run_notification_tests = b.addRunArtifact(notification_tests);
    const notification_input_tests = b.addTest(.{ .root_module = moduleByName(&modules, "NotificationInput") });
    const run_notification_input_tests = b.addRunArtifact(notification_input_tests);
    const notification_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "NotificationPage") });
    const run_notification_page_tests = b.addRunArtifact(notification_page_tests);
    const toast_store_tests = b.addTest(.{ .root_module = moduleByName(&modules, "ToastStore") });
    toast_store_tests.root_module.linkSystemLibrary("kernel32", .{});
    const run_toast_store_tests = b.addRunArtifact(toast_store_tests);
    const wechat_adapter_tests = b.addTest(.{ .root_module = moduleByName(&modules, "WeChatWatch") });
    inline for (.{ "kernel32", "user32" }) |library| wechat_adapter_tests.root_module.linkSystemLibrary(library, .{});
    const run_wechat_adapter_tests = b.addRunArtifact(wechat_adapter_tests);
    const tray_press_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TrayPress") });
    inline for (.{ "kernel32", "user32", "shell32", "ole32" }) |library| tray_press_tests.root_module.linkSystemLibrary(library, .{});
    const run_tray_press_tests = b.addRunArtifact(tray_press_tests);
    const music_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "MusicController") });
    const run_music_controller_tests = b.addRunArtifact(music_controller_tests);
    const music_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "MusicPage") });
    const run_music_page_tests = b.addRunArtifact(music_page_tests);
    const music_lyrics_tests = b.addTest(.{ .root_module = moduleByName(&modules, "MusicLyrics") });
    const run_music_lyrics_tests = b.addRunArtifact(music_lyrics_tests);
    const lyrics_service_tests = b.addTest(.{ .root_module = moduleByName(&modules, "LyricsService") });
    lyrics_service_tests.root_module.linkSystemLibrary("winhttp", .{});
    lyrics_service_tests.root_module.linkSystemLibrary("kernel32", .{});
    const run_lyrics_service_tests = b.addRunArtifact(lyrics_service_tests);
    const media_service_tests = b.addTest(.{ .root_module = moduleByName(&modules, "MediaService") });
    inline for (.{ "advapi32", "kernel32", "ole32", "version" }) |library| media_service_tests.root_module.linkSystemLibrary(library, .{});
    const run_media_service_tests = b.addRunArtifact(media_service_tests);
    const text_renderer_tests = b.addTest(.{ .root_module = moduleByName(&modules, "TextRenderer") });
    const run_text_renderer_tests = b.addRunArtifact(text_renderer_tests);
    const weather_service_tests = b.addTest(.{ .root_module = moduleByName(&modules, "WeatherService") });
    inline for (.{ "kernel32", "winhttp" }) |library| weather_service_tests.root_module.linkSystemLibrary(library, .{});
    const run_weather_service_tests = b.addRunArtifact(weather_service_tests);
    const weather_controller_tests = b.addTest(.{ .root_module = moduleByName(&modules, "WeatherController") });
    const run_weather_controller_tests = b.addRunArtifact(weather_controller_tests);
    const weather_page_tests = b.addTest(.{ .root_module = moduleByName(&modules, "WeatherPage") });
    const run_weather_page_tests = b.addRunArtifact(weather_page_tests);
    const test_step = b.step("test", "Run policy, graphics lifecycle, layout, input routing, and shared UI primitive tests");
    test_step.dependOn(&run_state_policy_tests.step);
    test_step.dependOn(&run_presentation_policy_tests.step);
    test_step.dependOn(&run_icon_service_tests.step);
    test_step.dependOn(&run_audio_service_tests.step);
    test_step.dependOn(&run_draw_lifecycle_tests.step);
    test_step.dependOn(&run_layout_snapshot_tests.step);
    test_step.dependOn(&run_input_router_tests.step);
    test_step.dependOn(&run_slider_tests.step);
    test_step.dependOn(&run_mixer_slider_tests.step);
    test_step.dependOn(&run_theme_token_tests.step);
    test_step.dependOn(&run_theme_tests.step);
    test_step.dependOn(&run_sound_controller_tests.step);
    test_step.dependOn(&run_sound_contract_tests.step);
    test_step.dependOn(&run_sound_page_tests.step);
    test_step.dependOn(&run_launcher_controller_tests.step);
    test_step.dependOn(&run_launcher_page_tests.step);
    test_step.dependOn(&run_tray_catalog_tests.step);
    test_step.dependOn(&run_tray_controller_tests.step);
    test_step.dependOn(&run_tray_page_tests.step);
    test_step.dependOn(&run_taskbar_catalog_tests.step);
    test_step.dependOn(&run_taskbar_controller_tests.step);
    test_step.dependOn(&run_taskbar_layout_tests.step);
    test_step.dependOn(&run_taskbar_page_tests.step);
    test_step.dependOn(&run_system_controller_tests.step);
    test_step.dependOn(&run_system_layout_tests.step);
    test_step.dependOn(&run_system_page_tests.step);
    test_step.dependOn(&run_system_status_contract_tests.step);
    test_step.dependOn(&run_thumbnail_layout_tests.step);
    test_step.dependOn(&run_bar_control_layout_tests.step);
    test_step.dependOn(&run_window_list_tests.step);
    test_step.dependOn(&run_tray_press_tests.step);
    test_step.dependOn(&run_notification_tests.step);
    test_step.dependOn(&run_notification_input_tests.step);
    test_step.dependOn(&run_notification_page_tests.step);
    test_step.dependOn(&run_toast_store_tests.step);
    test_step.dependOn(&run_wechat_adapter_tests.step);
    test_step.dependOn(&run_music_controller_tests.step);
    test_step.dependOn(&run_music_page_tests.step);
    test_step.dependOn(&run_music_lyrics_tests.step);
    test_step.dependOn(&run_lyrics_service_tests.step);
    test_step.dependOn(&run_media_service_tests.step);
    test_step.dependOn(&run_text_renderer_tests.step);
    test_step.dependOn(&run_weather_service_tests.step);
    test_step.dependOn(&run_weather_controller_tests.step);
    test_step.dependOn(&run_weather_page_tests.step);
}
