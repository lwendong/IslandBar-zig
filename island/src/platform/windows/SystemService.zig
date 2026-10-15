const Status = @import("SystemStatus");
const Toggles = @import("SystemToggles");
const Brightness = @import("DisplayBrightness");

pub const StatusReader = Status.SystemStatusReader;
pub const StatusSnapshot = Status.SystemStatus;
pub const RadioOutcome = Toggles.RadioOutcome;
pub const NightLightOutcome = Toggles.NightLightOutcome;

pub fn takeRadioOutcome() ?RadioOutcome {
    return Toggles.takeRadioOutcome();
}

pub fn takeNightLightOutcome() ?NightLightOutcome {
    return Toggles.takeNightLightOutcome();
}

pub fn requestRadios(wifi: bool, bluetooth: bool, on: bool) bool {
    return Toggles.requestRadios(wifi, bluetooth, on);
}

pub fn requestNightLight(on: bool) bool {
    return Toggles.requestNightLight(on);
}

pub fn toggleLiveCaptions() bool {
    return Toggles.toggleLiveCaptions();
}

pub fn readBrightness(monitor: ?*anyopaque, percent: *i32) bool {
    return Brightness.readBrightnessPercent(monitor, percent);
}

pub fn setBrightness(monitor: ?*anyopaque, percent: i32, landed_percent: *i32) bool {
    return Brightness.setBrightnessPercent(monitor, percent, landed_percent);
}

pub fn forgetBrightnessMonitor() void {
    Brightness.forgetBrightnessMonitor();
}

pub fn statusSmokeCheck() bool {
    return Status.smokeCheck();
}

pub fn togglesSmokeCheck() bool {
    return Toggles.smokeCheck();
}

pub fn brightnessSmokeCheck() bool {
    return Brightness.smokeCheck();
}
