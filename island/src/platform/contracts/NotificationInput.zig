const std = @import("std");
const MiniJson = @import("MiniJson");

pub const app_name_capacity = 64;
pub const title_capacity = 160;
pub const body_capacity = 512;
pub const icon_path_capacity = 260;

pub const Urgency = enum(i32) { normal = 0, low = 1, high = 2 };
pub const Source = enum { pipe, windows_toast, wechat_toast, wechat_sound, wechat_call };

/// Value-only event crossing from a platform notification source into the Feature.
pub const Message = struct {
    app: [app_name_capacity]u8 = @splat(0),
    title: [title_capacity]u8 = @splat(0),
    body: [body_capacity]u8 = @splat(0),
    icon_path: [icon_path_capacity]u8 = @splat(0),
    sender_pid: u32 = 0,
    urgency: Urgency = .normal,
    sticky: bool = false,
    source: Source = .pipe,
    source_key: u64 = 0,

    pub fn fromJson(document: []const u8) ?Message {
        var parsed = Message{};
        _ = MiniJson.getString(document, "title", &parsed.title);
        _ = MiniJson.getString(document, "body", &parsed.body);
        if (field(&parsed.title).len == 0 and field(&parsed.body).len == 0) return null;

        var urgency: [16]u8 = @splat(0);
        _ = MiniJson.getString(document, "app", &parsed.app);
        _ = MiniJson.getString(document, "icon", &parsed.icon_path);
        _ = MiniJson.getString(document, "urgency", &urgency);
        if (std.ascii.eqlIgnoreCase(field(&urgency), "high")) {
            parsed.urgency = .high;
        } else if (std.ascii.eqlIgnoreCase(field(&urgency), "low")) {
            parsed.urgency = .low;
        }
        if (MiniJson.getInt(document, "sticky")) |sticky| parsed.sticky = sticky != 0;
        return parsed;
    }

    /// Keeps the existing pipe JSON field names and values.
    pub fn toJson(self: *const Message, output: []u8) ?[]const u8 {
        if (output.len == 0) return null;
        output[0] = 0;
        var writer = JsonWriter{ .output = output };
        writer.append("{");
        var first = true;
        writer.stringField(&first, "app", field(&self.app));
        writer.stringField(&first, "title", field(&self.title));
        writer.stringField(&first, "body", field(&self.body));
        writer.stringField(&first, "icon", field(&self.icon_path));
        writer.stringField(&first, "urgency", switch (self.urgency) {
            .normal => "normal",
            .low => "low",
            .high => "high",
        });
        if (self.sticky) {
            writer.fieldPrefix(&first, "sticky");
            writer.append("1");
        }
        writer.append("}");
        if (writer.failed) {
            output[0] = 0;
            return null;
        }
        output[writer.used] = 0;
        return output[0..writer.used];
    }
};

pub const Event = union(enum) {
    message: Message,
    dismiss_source: SourceIdentity,
};

pub const SourceIdentity = struct { source: Source, key: u64 };

pub fn field(array: []const u8) []const u8 {
    return array[0 .. std.mem.indexOfScalar(u8, array, 0) orelse array.len];
}

const JsonWriter = struct {
    output: []u8,
    used: usize = 0,
    failed: bool = false,

    fn append(self: *JsonWriter, text: []const u8) void {
        if (self.failed) return;
        if (self.used >= self.output.len or text.len > self.output.len - self.used - 1) {
            self.failed = true;
            return;
        }
        @memcpy(self.output[self.used .. self.used + text.len], text);
        self.used += text.len;
    }

    fn fieldPrefix(self: *JsonWriter, first: *bool, name: []const u8) void {
        if (!first.*) self.append(",");
        self.append("\"");
        self.append(name);
        self.append("\":");
        first.* = false;
    }

    fn stringField(self: *JsonWriter, first: *bool, name: []const u8, value: []const u8) void {
        self.fieldPrefix(first, name);
        self.append("\"");
        var escaped: [body_capacity * 6]u8 = undefined;
        const length = MiniJson.escape(value, &escaped);
        self.append(escaped[0..length]);
        self.append("\"");
    }
};

pub fn smokeCheck() bool {
    const message = Message.fromJson("{\"title\":\"Build\",\"body\":\"done\",\"app\":\"CI\",\"urgency\":\"HIGH\",\"sticky\":1}") orelse return false;
    if (message.urgency != .high or !message.sticky or !std.mem.eql(u8, field(&message.title), "Build")) return false;
    var output: [2048]u8 = undefined;
    const json = message.toJson(&output) orelse return false;
    const restored = Message.fromJson(json) orelse return false;
    return restored.urgency == message.urgency and restored.sticky and
        std.mem.eql(u8, field(&restored.title), "Build") and
        Message.fromJson("{\"app\":\"empty\"}") == null;
}

test "notification input preserves the existing JSON protocol" {
    const message = Message.fromJson("{\"title\":\"Build\",\"body\":\"done\",\"app\":\"CI\",\"urgency\":\"HIGH\",\"sticky\":1}").?;
    var output: [1024]u8 = undefined;
    const json = message.toJson(&output).?;
    try std.testing.expect(MiniJson.hasKey(json, "title"));
    try std.testing.expect(MiniJson.hasKey(json, "sticky"));
    try std.testing.expectEqual(Source.pipe, message.source);
    try std.testing.expect(Message.fromJson("{\"app\":\"empty\"}") == null);
}
