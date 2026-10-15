const std = @import("std");
const SoundAudio = @import("SoundAudio");

pub const operation_timeout_ms: u64 = 5000;
pub const hresult_timeout: i32 = @bitCast(@as(u32, 0x800705B4));
pub const hresult_unavailable: i32 = @bitCast(@as(u32, 0x80070490));

pub const Action = union(enum) {
    refresh,
    set_master_volume: f32,
    set_master_muted: bool,
    set_session_volume: struct { pid: u32, level: f32, topology_generation: u64 },
    select_default_device: struct { id: [256]u16, topology_generation: u64 },
};

pub const PortResult = struct {
    accepted: bool = false,
    hresult: i32 = 0,
};

pub const Port = struct {
    context: ?*anyopaque = null,
    request_fn: *const fn (?*anyopaque, *const Action, u64, *PortResult) callconv(.c) void,
};

pub const Dispatch = enum { queued, duplicate, no_device, stale_target, unavailable, failed };
pub const ResultDisposition = enum { applied, stale };

pub const ServiceError = struct {
    operation: SoundAudio.Operation,
    token: u64,
    hresult: i32,
};

const Pending = struct {
    action: Action,
    token: u64,
    issued_ms: u64,
    topology_generation: u64,
    result_received: bool = false,
};

const SessionIntent = struct {
    active: bool = false,
    pid: u32 = 0,
    level: f32 = 0,
    token: u64 = 0,
};

pub const State = struct {
    output: SoundAudio.Snapshot = .{},
    output_revision: u64 = 0,
    topology_generation: u64 = 0,
    revision: u64 = 0,
    master_available: bool = false,
    master_level: f32 = 0,
    master_muted: bool = false,
    master_peak: f32 = 0,
    master_revision: u64 = 0,
    optimistic_master_level: ?f32 = null,
    optimistic_master_muted: ?bool = null,
    sessions: [SoundAudio.max_sessions]SessionIntent = @splat(.{}),
    pending: ?Pending = null,
    last_error: ?ServiceError = null,

    pub fn displayedMasterLevel(self: *const State) f32 {
        return self.optimistic_master_level orelse self.master_level;
    }

    pub fn displayedMuted(self: *const State) bool {
        return self.optimistic_master_muted orelse self.master_muted;
    }

    pub fn displayedSessionLevel(self: *const State, pid: u32, confirmed: f32) f32 {
        for (self.sessions) |intent| {
            if (intent.active and intent.pid == pid) return intent.level;
        }
        return confirmed;
    }
};

pub const Controller = struct {
    state: State = .{},
    port: ?Port = null,
    next_token: u64 = 1,

    pub fn updateOutput(self: *Controller, incoming_arg: SoundAudio.Snapshot) void {
        var incoming = incoming_arg;
        incoming.normalize();
        if (incoming.revision == self.state.output_revision) return;

        const topology_changed = !sameTopology(&self.state.output, &incoming);
        self.state.output = incoming;
        self.state.output_revision = incoming.revision;
        if (topology_changed) {
            self.state.topology_generation +%= 1;
            for (&self.state.sessions) |*intent| intent.* = .{};
            if (self.state.pending) |pending| switch (pending.action) {
                .set_session_volume, .select_default_device => self.state.pending = null,
                else => {},
            };
        }
        self.confirmOutputAction();
        self.state.revision +%= 1;
    }

    pub fn updateMaster(self: *Controller, available: bool, level: f32, muted: bool, peak: f32, revision: u64) void {
        const normalized_peak = finiteClamp(peak);
        if (revision == self.state.master_revision and available == self.state.master_available) {
            self.state.master_peak = normalized_peak;
            return;
        }
        self.state.master_available = available;
        self.state.master_revision = revision;
        if (available) {
            self.state.master_level = finiteClamp(level);
            self.state.master_muted = muted;
            self.state.master_peak = normalized_peak;
        }
        if (self.state.optimistic_master_level) |wanted| {
            if (available and @abs(self.state.master_level - wanted) <= 0.015) self.state.optimistic_master_level = null;
        }
        if (self.state.optimistic_master_muted) |wanted| {
            if (available and self.state.master_muted == wanted) self.state.optimistic_master_muted = null;
        }
        self.confirmMasterAction();
        self.state.revision +%= 1;
    }

    pub fn dispatch(self: *Controller, action_arg: Action, now_ms: u64) Dispatch {
        var action = action_arg;
        switch (action) {
            .refresh => {},
            .set_master_volume => |value| {
                if (!self.state.master_available) return .no_device;
                const normalized = finiteClamp(value);
                action = .{ .set_master_volume = normalized };
                if (self.state.optimistic_master_level) |level| {
                    if (level == normalized) return .duplicate;
                } else if (self.state.master_level == normalized) return .duplicate;
            },
            .set_master_muted => |wanted| {
                if (!self.state.master_available) return .no_device;
                if (self.state.optimistic_master_muted) |muted| {
                    if (muted == wanted) return .duplicate;
                } else if (self.state.master_muted == wanted) return .duplicate;
            },
            .set_session_volume => |request| {
                if (request.topology_generation != self.state.topology_generation) return .stale_target;
                if (self.state.output.sessionIndexForPid(request.pid) == null) return .stale_target;
                const normalized = finiteClamp(request.level);
                action = .{ .set_session_volume = .{ .pid = request.pid, .level = normalized, .topology_generation = request.topology_generation } };
                for (self.state.sessions) |intent| if (intent.active and intent.pid == request.pid and intent.level == normalized) return .duplicate;
            },
            .select_default_device => |request| {
                if (request.topology_generation != self.state.topology_generation) return .stale_target;
                const index = deviceIndex(&self.state.output, &request.id) orelse return .stale_target;
                if (self.state.output.devices[index].is_default) return .duplicate;
            },
        }

        const port = self.port orelse return .unavailable;
        const token = self.next_token;
        self.next_token +%= 1;
        var result = PortResult{};
        port.request_fn(port.context, &action, token, &result);
        if (!result.accepted) {
            self.state.last_error = .{ .operation = operationFor(action), .token = token, .hresult = result.hresult };
            self.state.revision +%= 1;
            return .failed;
        }

        if (self.state.pending) |previous| self.clearOptimistic(previous.action, previous.token);
        self.state.pending = .{
            .action = action,
            .token = token,
            .issued_ms = now_ms,
            .topology_generation = self.state.topology_generation,
        };
        self.state.last_error = null;
        switch (action) {
            .set_master_volume => |value| self.state.optimistic_master_level = value,
            .set_master_muted => |value| self.state.optimistic_master_muted = value,
            .set_session_volume => |request| self.setSessionIntent(request.pid, request.level, token),
            .refresh, .select_default_device => {},
        }
        self.state.revision +%= 1;
        return .queued;
    }

    pub fn applyResult(self: *Controller, result: SoundAudio.OperationResult) ResultDisposition {
        const pending = self.state.pending orelse return .stale;
        if (pending.token != result.token or operationFor(pending.action) != result.operation or
            (isTopologyBound(pending.action) and pending.topology_generation != self.state.topology_generation)) return .stale;

        if (!SoundAudio.succeeded(result.hresult)) {
            self.state.last_error = .{ .operation = result.operation, .token = result.token, .hresult = result.hresult };
            self.clearOptimistic(pending.action, result.token);
            self.state.pending = null;
        } else {
            if (self.state.pending) |*current| current.result_received = true;
            self.confirmMasterAction();
            self.confirmOutputAction();
        }
        self.state.revision +%= 1;
        return .applied;
    }

    pub fn expire(self: *Controller, now_ms: u64) bool {
        const pending = self.state.pending orelse return false;
        if (now_ms -| pending.issued_ms < operation_timeout_ms) return false;
        self.state.last_error = .{ .operation = operationFor(pending.action), .token = pending.token, .hresult = hresult_timeout };
        self.clearOptimistic(pending.action, pending.token);
        self.state.pending = null;
        self.state.revision +%= 1;
        return true;
    }

    fn setSessionIntent(self: *Controller, pid: u32, level: f32, token: u64) void {
        for (&self.state.sessions) |*intent| {
            if (intent.active and intent.pid == pid) {
                intent.* = .{ .active = true, .pid = pid, .level = level, .token = token };
                return;
            }
        }
        for (&self.state.sessions) |*intent| {
            if (!intent.active) {
                intent.* = .{ .active = true, .pid = pid, .level = level, .token = token };
                return;
            }
        }
    }

    fn clearOptimistic(self: *Controller, action: Action, token: u64) void {
        switch (action) {
            .set_master_volume => self.state.optimistic_master_level = null,
            .set_master_muted => self.state.optimistic_master_muted = null,
            .set_session_volume => |request| for (&self.state.sessions) |*intent| {
                if (intent.active and intent.pid == request.pid and intent.token == token) intent.* = .{};
            },
            .refresh, .select_default_device => {},
        }
    }

    fn confirmMasterAction(self: *Controller) void {
        const pending = self.state.pending orelse return;
        if (!pending.result_received) return;
        switch (pending.action) {
            .set_master_volume => |wanted| {
                if (@abs(self.state.master_level - wanted) <= 0.015) self.state.pending = null;
            },
            .set_master_muted => |wanted| {
                if (self.state.master_muted == wanted) self.state.pending = null;
            },
            else => {},
        }
    }

    fn confirmOutputAction(self: *Controller) void {
        const pending = self.state.pending orelse return;
        if (!pending.result_received) return;
        switch (pending.action) {
            .set_session_volume => |request| {
                const index = self.state.output.sessionIndexForPid(request.pid) orelse return;
                if (@abs(self.state.output.sessions[index].volume - request.level) <= 0.015) {
                    self.clearOptimistic(pending.action, pending.token);
                    self.state.pending = null;
                }
            },
            .select_default_device => |request| {
                const index = deviceIndex(&self.state.output, &request.id) orelse return;
                if (self.state.output.devices[index].is_default) self.state.pending = null;
            },
            else => {},
        }
    }
};

fn sameTopology(a: *const SoundAudio.Snapshot, b: *const SoundAudio.Snapshot) bool {
    if (a.device_count != b.device_count or a.session_count != b.session_count or a.default_device != b.default_device) return false;
    for (a.devices[0..a.device_count], b.devices[0..b.device_count]) |left, right| {
        if (!wideEqual(&left.id, &right.id)) return false;
    }
    for (a.sessions[0..a.session_count], b.sessions[0..b.session_count]) |left, right| {
        if (left.pid != right.pid or !wideEqual(&left.source, &right.source)) return false;
    }
    return true;
}

fn wideEqual(a: anytype, b: anytype) bool {
    const left = a[0 .. std.mem.indexOfScalar(u16, a, 0) orelse a.len];
    const right = b[0 .. std.mem.indexOfScalar(u16, b, 0) orelse b.len];
    return std.mem.eql(u16, left, right);
}

fn deviceIndex(snapshot: *const SoundAudio.Snapshot, wanted: *const [256]u16) ?usize {
    const wanted_slice = std.mem.sliceTo(wanted, 0);
    for (snapshot.devices[0..snapshot.device_count], 0..) |device, index| {
        if (std.mem.eql(u16, std.mem.sliceTo(&device.id, 0), wanted_slice)) return index;
    }
    return null;
}

fn finiteClamp(value: f32) f32 {
    return if (std.math.isFinite(value)) std.math.clamp(value, 0, 1) else 0;
}

fn operationFor(action: Action) SoundAudio.Operation {
    return switch (action) {
        .set_master_volume => .master_volume,
        .set_master_muted => .master_mute,
        .set_session_volume => .session_volume,
        .select_default_device => .default_device,
        .refresh => .default_device,
    };
}

fn isTopologyBound(action: Action) bool {
    return switch (action) {
        .set_session_volume, .select_default_device => true,
        else => false,
    };
}

const FakePort = struct {
    accepted: bool = true,
    hresult: i32 = 0,
    calls: usize = 0,
    last_token: u64 = 0,

    fn request(raw: ?*anyopaque, _: *const Action, token: u64, out: *PortResult) callconv(.c) void {
        const self: *FakePort = @ptrCast(@alignCast(raw.?));
        self.calls += 1;
        self.last_token = token;
        out.* = .{ .accepted = self.accepted, .hresult = self.hresult };
    }

    fn port(self: *FakePort) Port {
        return .{ .context = self, .request_fn = request };
    }
};

fn basicOutput() SoundAudio.Snapshot {
    var output = SoundAudio.Snapshot{ .device_count = 2, .session_count = 1, .revision = 1 };
    output.devices[0] = .{ .id = wideId("device-a"), .is_default = true };
    output.devices[1] = .{ .id = wideId("device-b") };
    output.sessions[0] = .{ .pid = 42, .source = wideSource("app.exe"), .volume = 0.4 };
    return output;
}

fn wideId(comptime text: []const u8) [256]u16 {
    var result: [256]u16 = @splat(0);
    for (text, 0..) |byte, index| result[index] = byte;
    return result;
}

fn wideSource(comptime text: []const u8) [260]u16 {
    var result: [260]u16 = @splat(0);
    for (text, 0..) |byte, index| result[index] = byte;
    return result;
}

test "no audio endpoint rejects master actions without dispatch" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    try std.testing.expectEqual(Dispatch.no_device, controller.dispatch(.{ .set_master_volume = 0.5 }, 10));
    try std.testing.expectEqual(@as(usize, 0), fake.calls);
}

test "device changes invalidate targets from the old topology" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    var output = basicOutput();
    controller.updateOutput(output);
    const generation = controller.state.topology_generation;
    output.revision += 1;
    output.sessions[0].pid = 99;
    controller.updateOutput(output);
    try std.testing.expect(controller.state.topology_generation > generation);
    try std.testing.expectEqual(Dispatch.stale_target, controller.dispatch(.{ .set_session_volume = .{ .pid = 42, .level = 0.6, .topology_generation = generation } }, 20));
}

test "duplicate volume actions are suppressed" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateMaster(true, 0.2, false, 0, 1);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.6 }, 10));
    try std.testing.expectEqual(Dispatch.duplicate, controller.dispatch(.{ .set_master_volume = 0.6 }, 11));
    try std.testing.expectEqual(@as(usize, 1), fake.calls);
}

test "service failure preserves HRESULT and pending requests time out" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateMaster(true, 0.2, false, 0, 1);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.7 }, 100));
    try std.testing.expectEqual(ResultDisposition.applied, controller.applyResult(.{ .token = fake.last_token, .operation = .master_volume, .hresult = -2147024891 }));
    try std.testing.expectEqual(@as(i32, -2147024891), controller.state.last_error.?.hresult);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.8 }, 200));
    try std.testing.expect(controller.expire(200 + operation_timeout_ms));
    try std.testing.expectEqual(hresult_timeout, controller.state.last_error.?.hresult);
}

test "late service results are ignored after a newer request" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateMaster(true, 0.1, false, 0, 1);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.4 }, 10));
    const old_token = fake.last_token;
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.8 }, 11));
    try std.testing.expectEqual(ResultDisposition.stale, controller.applyResult(.{ .token = old_token, .operation = .master_volume, .hresult = 0 }));
}

test "permission failures retain the original system error code" {
    var fake = FakePort{ .accepted = false, .hresult = @bitCast(@as(u32, 0x80070005)) };
    var controller = Controller{ .port = fake.port() };
    controller.updateMaster(true, 0.1, false, 0, 1);
    try std.testing.expectEqual(Dispatch.failed, controller.dispatch(.{ .set_master_muted = true }, 10));
    try std.testing.expectEqual(@as(i32, @bitCast(@as(u32, 0x80070005))), controller.state.last_error.?.hresult);
}

test "rapid session drags keep the latest desired value and token" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateOutput(basicOutput());
    const generation = controller.state.topology_generation;
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_session_volume = .{ .pid = 42, .level = 0.2, .topology_generation = generation } }, 10));
    const first_token = fake.last_token;
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_session_volume = .{ .pid = 42, .level = 0.3, .topology_generation = generation } }, 20));
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_session_volume = .{ .pid = 42, .level = 0.4, .topology_generation = generation } }, 30));
    try std.testing.expectEqual(ResultDisposition.stale, controller.applyResult(.{ .token = first_token, .operation = .session_volume, .hresult = 0 }));
    try std.testing.expectApproxEqAbs(@as(f32, 0.4), controller.state.displayedSessionLevel(42, 0.1), 0.0001);
}

test "superseding an action clears its optimistic state" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateOutput(basicOutput());
    const generation = controller.state.topology_generation;
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_session_volume = .{ .pid = 42, .level = 0.8, .topology_generation = generation } }, 10));
    try std.testing.expectApproxEqAbs(@as(f32, 0.8), controller.state.displayedSessionLevel(42, 0.4), 0.0001);
    controller.updateMaster(true, 0.4, false, 0, 1);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_muted = true }, 20));
    try std.testing.expectApproxEqAbs(@as(f32, 0.4), controller.state.displayedSessionLevel(42, 0.4), 0.0001);
}

test "rejected replacement keeps the prior accepted operation tracked" {
    var fake = FakePort{};
    var controller = Controller{ .port = fake.port() };
    controller.updateMaster(true, 0.2, false, 0, 1);
    try std.testing.expectEqual(Dispatch.queued, controller.dispatch(.{ .set_master_volume = 0.6 }, 10));
    const original_token = fake.last_token;
    fake.accepted = false;
    fake.hresult = hresult_unavailable;
    try std.testing.expectEqual(Dispatch.failed, controller.dispatch(.{ .set_master_muted = true }, 11));
    try std.testing.expectEqual(original_token, controller.state.pending.?.token);
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), controller.state.displayedMasterLevel(), 0.0001);
}
