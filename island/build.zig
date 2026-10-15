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
        .{ .name = "AppBar", .module = sourceModule(b, target, optimize, "src/platform/windows/AppBar.zig") },
        .{ .name = "AudioVolume", .module = sourceModule(b, target, optimize, "src/platform/windows/AudioVolume.zig") },
        .{ .name = "CardLayout", .module = sourceModule(b, target, optimize, "src/core/CardLayout.zig") },
        .{ .name = "CommandLine", .module = sourceModule(b, target, optimize, "src/app/CommandLine.zig") },
        .{ .name = "Diagnostics", .module = sourceModule(b, target, optimize, "src/app/Diagnostics.zig") },
        .{ .name = "DisplayBrightness", .module = sourceModule(b, target, optimize, "src/platform/windows/DisplayBrightness.zig") },
        .{ .name = "Geometry", .module = sourceModule(b, target, optimize, "src/core/Geometry.zig") },
        .{ .name = "InputRegion", .module = sourceModule(b, target, optimize, "src/core/InputRegion.zig") },
        .{ .name = "GlassMaterial", .module = sourceModule(b, target, optimize, "src/ui/GlassMaterial.zig") },
        .{ .name = "IslandWindow", .module = sourceModule(b, target, optimize, "src/ui/IslandWindow.zig") },
        .{ .name = "Log", .module = sourceModule(b, target, optimize, "src/platform/windows/Log.zig") },
        .{ .name = "Lyrics", .module = sourceModule(b, target, optimize, "src/features/Lyrics.zig") },
        .{ .name = "MiniJson", .module = sourceModule(b, target, optimize, "src/core/MiniJson.zig") },
        .{ .name = "Monitor", .module = sourceModule(b, target, optimize, "src/platform/windows/Monitor.zig") },
        .{ .name = "Motion", .module = sourceModule(b, target, optimize, "src/core/Motion.zig") },
        .{ .name = "MusicSession", .module = sourceModule(b, target, optimize, "src/features/MusicSession.zig") },
        .{ .name = "NativeTaskbar", .module = sourceModule(b, target, optimize, "src/platform/windows/NativeTaskbar.zig") },
        .{ .name = "Notification", .module = sourceModule(b, target, optimize, "src/features/Notification.zig") },
        .{ .name = "NotificationIcon", .module = sourceModule(b, target, optimize, "src/features/NotificationIcon.zig") },
        .{ .name = "NotificationPipe", .module = sourceModule(b, target, optimize, "src/platform/windows/NotificationPipe.zig") },
        .{ .name = "PlayerWindow", .module = sourceModule(b, target, optimize, "src/ui/PlayerWindow.zig") },
        .{ .name = "Renderer", .module = sourceModule(b, target, optimize, "src/ui/Renderer.zig") },
        .{ .name = "SoundOutput", .module = sourceModule(b, target, optimize, "src/features/SoundOutput.zig") },
        .{ .name = "StartApps", .module = sourceModule(b, target, optimize, "src/features/StartApps.zig") },
        .{ .name = "StartMenu", .module = sourceModule(b, target, optimize, "src/features/StartMenu.zig") },
        .{ .name = "StatePolicy", .module = sourceModule(b, target, optimize, "src/core/StatePolicy.zig") },
        .{ .name = "SysStatusProbe", .module = sourceModule(b, target, optimize, "src/platform/windows/SysStatusProbe.zig") },
        .{ .name = "SystemStatus", .module = sourceModule(b, target, optimize, "src/platform/windows/SystemStatus.zig") },
        .{ .name = "SystemToggles", .module = sourceModule(b, target, optimize, "src/platform/windows/SystemToggles.zig") },
        .{ .name = "TaskStripLayout", .module = sourceModule(b, target, optimize, "src/core/TaskStripLayout.zig") },
        .{ .name = "TextRenderer", .module = sourceModule(b, target, optimize, "src/ui/TextRenderer.zig") },
        .{ .name = "Theme", .module = sourceModule(b, target, optimize, "src/ui/Theme.zig") },
        .{ .name = "ThumbnailPreview", .module = sourceModule(b, target, optimize, "src/ui/ThumbnailPreview.zig") },
        .{ .name = "ToastStore", .module = sourceModule(b, target, optimize, "src/features/ToastStore.zig") },
        .{ .name = "TrayIcons", .module = sourceModule(b, target, optimize, "src/platform/windows/TrayIcons.zig") },
        .{ .name = "TrayPress", .module = sourceModule(b, target, optimize, "src/platform/windows/TrayPress.zig") },
        .{ .name = "Weather", .module = sourceModule(b, target, optimize, "src/features/Weather.zig") },
        .{ .name = "WeChatWatch", .module = sourceModule(b, target, optimize, "src/features/WeChatWatch.zig") },
        .{ .name = "WicImage", .module = sourceModule(b, target, optimize, "src/platform/windows/WicImage.zig") },
        .{ .name = "WindowList", .module = sourceModule(b, target, optimize, "src/platform/windows/WindowList.zig") },
    };

    // Each source module has its own root; dependencies are wired explicitly so
    // modules cannot silently reach across categories at compile time.
    bindModules(moduleByName(&modules, "AppBar"), &modules, &.{ "Monitor", "Log" });
    bindModules(moduleByName(&modules, "CardLayout"), &modules, &.{ "Geometry", "TaskStripLayout" });
    bindModules(moduleByName(&modules, "CommandLine"), &modules, &.{"Motion"});
    bindModules(moduleByName(&modules, "Diagnostics"), &modules, &.{ "Geometry", "Motion", "StatePolicy", "CardLayout", "IslandWindow", "Lyrics", "MiniJson", "Monitor", "MusicSession", "Notification", "Renderer", "TextRenderer", "Theme", "WicImage", "Log" });
    bindModules(moduleByName(&modules, "GlassMaterial"), &modules, &.{"Theme"});
    bindModules(moduleByName(&modules, "IslandWindow"), &modules, &.{"AppBar"});
    bindModules(moduleByName(&modules, "InputRegion"), &modules, &.{ "Geometry", "Motion", "TaskStripLayout" });
    bindModules(moduleByName(&modules, "Lyrics"), &modules, &.{"MiniJson"});
    bindModules(moduleByName(&modules, "Motion"), &modules, &.{"Geometry"});
    bindModules(moduleByName(&modules, "MusicSession"), &modules, &.{ "Log", "WicImage" });
    bindModules(moduleByName(&modules, "NativeTaskbar"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "Notification"), &modules, &.{"MiniJson"});
    bindModules(moduleByName(&modules, "NotificationIcon"), &modules, &.{ "MusicSession", "WicImage", "Log", "Notification" });
    bindModules(moduleByName(&modules, "NotificationPipe"), &modules, &.{ "Log", "MiniJson", "Notification" });
    bindModules(moduleByName(&modules, "Renderer"), &modules, &.{ "CardLayout", "Geometry", "Motion", "MusicSession", "Notification", "TaskStripLayout", "TextRenderer", "Theme", "Weather", "WicImage" });
    bindModules(moduleByName(&modules, "SoundOutput"), &modules, &.{ "Log", "MusicSession" });
    bindModules(moduleByName(&modules, "StartApps"), &modules, &.{"WicImage"});
    bindModules(moduleByName(&modules, "StatePolicy"), &modules, &.{"Motion"});
    bindModules(moduleByName(&modules, "SysStatusProbe"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "SystemStatus"), &modules, &.{ "AudioVolume", "Log", "SystemToggles" });
    bindModules(moduleByName(&modules, "SystemToggles"), &modules, &.{"StartMenu"});
    bindModules(moduleByName(&modules, "TaskStripLayout"), &modules, &.{ "Geometry", "Motion" });
    bindModules(moduleByName(&modules, "TextRenderer"), &modules, &.{ "CardLayout", "Geometry", "GlassMaterial", "StartApps", "TaskStripLayout", "Theme", "Weather", "WicImage" });
    bindModules(moduleByName(&modules, "Theme"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "ToastStore"), &modules, &.{"Notification"});
    bindModules(moduleByName(&modules, "Weather"), &modules, &.{"Log"});
    bindModules(moduleByName(&modules, "WeChatWatch"), &modules, &.{ "Notification", "Log" });
    bindModules(moduleByName(&modules, "WindowList"), &modules, &.{"Monitor"});

    const setup_module = sourceModule(b, target, optimize, "setup/Setup.zig");
    const main_module = sourceModule(b, target, optimize, "src/app/main.zig");
    bindModules(main_module, &modules, &.{ "Geometry", "GlassMaterial", "WicImage", "AppBar", "AudioVolume", "Weather", "MusicSession", "Lyrics", "SoundOutput", "StartApps", "TrayPress", "Renderer", "Diagnostics", "IslandWindow", "InputRegion", "TextRenderer", "Log", "Motion", "CommandLine", "PlayerWindow", "DisplayBrightness", "Monitor", "NativeTaskbar", "NotificationIcon", "NotificationPipe", "StartMenu", "StatePolicy", "SystemStatus", "SystemToggles", "SysStatusProbe", "ThumbnailPreview", "Theme", "ToastStore", "TrayIcons", "WindowList", "WeChatWatch", "TaskStripLayout", "CardLayout", "MiniJson", "Notification" });
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
    bindModules(json_probe_module, &modules, &.{ "MiniJson", "Notification" });
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
}
