const std = @import("std");
const MiniJson = @import("MiniJson");

pub const max_notifications = 32;
pub const app_name_capacity = 64;
pub const title_capacity = 160;
pub const body_capacity = 512;
pub const display_ms = 6000;

pub const Urgency = enum(i32) { normal = 0, low = 1, high = 2 };

pub const Notification = struct {
    id: i64 = 0,
    timestamp_ms: u64 = 0,
    app: [app_name_capacity]u8 = @splat(0),
    title: [title_capacity]u8 = @splat(0),
    body: [body_capacity]u8 = @splat(0),
    icon_path: [260]u8 = @splat(0),
    sender_pid: u32 = 0,
    urgency: Urgency = .normal,
    read: bool = false,
    sticky: bool = false,

    pub fn fromJson(document: []const u8) ?Notification {
        var parsed = Notification{};
        _ = MiniJson.getString(document, "title", &parsed.title);
        _ = MiniJson.getString(document, "body", &parsed.body);
        if (field(&parsed.title).len == 0 and field(&parsed.body).len == 0) return null;

        var app: [app_name_capacity]u8 = @splat(0);
        var icon: [260]u8 = @splat(0);
        var urgency: [16]u8 = @splat(0);
        _ = MiniJson.getString(document, "app", &app);
        _ = MiniJson.getString(document, "icon", &icon);
        _ = MiniJson.getString(document, "urgency", &urgency);
        copyField(&parsed.app, field(&app));
        copyField(&parsed.icon_path, field(&icon));

        if (std.ascii.eqlIgnoreCase(field(&urgency), "high")) {
            parsed.urgency = .high;
        } else if (std.ascii.eqlIgnoreCase(field(&urgency), "low")) {
            parsed.urgency = .low;
        }
        if (MiniJson.getInt(document, "sticky")) |sticky| parsed.sticky = sticky != 0;
        return parsed;
    }

    /// Serializes a notification as a complete JSON object, or null if output is too small.
    pub fn toJson(self: *const Notification, output: []u8, append_id: bool) ?[]const u8 {
        if (output.len == 0) return null;
        output[0] = 0;
        var writer = JsonWriter{ .output = output };
        writer.append("{");
        var first = true;
        if (append_id) {
            var number: [32]u8 = undefined;
            const text = std.fmt.bufPrint(&number, "{d}", .{self.id}) catch return null;
            writer.fieldPrefix(&first, "id");
            writer.append(text);
        }
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

fn field(array: []const u8) []const u8 {
    return array[0 .. std.mem.indexOfScalar(u8, array, 0) orelse array.len];
}

fn copyField(destination: []u8, source: []const u8) void {
    if (destination.len == 0) return;
    const count = @min(source.len, destination.len - 1);
    @memcpy(destination[0..count], source[0..count]);
    destination[count] = 0;
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

pub const Store = struct {
    items: [max_notifications]Notification = std.mem.zeroes([max_notifications]Notification),
    count: usize = 0,
    head: usize = 0,
    next_id: i64 = 1,

    pub fn pushAt(self: *Store, source: Notification, now_ms: u64) *Notification {
        var stored = source;
        stored.id = self.next_id;
        self.next_id +%= 1;
        stored.timestamp_ms = now_ms;
        stored.read = false;
        self.head = (self.head + 1) % max_notifications;
        if (self.count < max_notifications) self.count += 1;
        self.items[self.head] = stored;
        return &self.items[self.head];
    }

    pub fn markAllRead(self: *Store) usize {
        return self.markAllReadExcept(null);
    }

    pub fn markAllReadExcept(self: *Store, keep_id: ?i64) usize {
        var changed: usize = 0;
        for (0..self.count) |index| {
            const item = self.atMutable(index).?;
            if (!item.read and (keep_id == null or item.id != keep_id.?)) {
                item.read = true;
                changed += 1;
            }
        }
        return changed;
    }

    pub fn markRead(self: *Store, id: i64) usize {
        for (0..self.count) |index| {
            const item = self.atMutable(index).?;
            if (item.id == id and !item.read) {
                item.read = true;
                return 1;
            }
        }
        return 0;
    }

    pub fn unreadCount(self: *const Store) usize {
        var unread: usize = 0;
        for (0..self.count) |index| {
            if (!self.at(index).?.read) unread += 1;
        }
        return unread;
    }

    /// Entries are indexed from newest to oldest.
    pub fn at(self: *const Store, index_from_newest: usize) ?*const Notification {
        if (index_from_newest >= self.count) return null;
        return &self.items[self.indexFromNewest(index_from_newest)];
    }

    pub fn activeDisplay(self: *const Store, now_ms: u64) ?*const Notification {
        if (self.count == 0) return null;
        const newest = &self.items[self.head];
        if (newest.read) return null;
        if (!newest.sticky) {
            const age = if (now_ms >= newest.timestamp_ms) now_ms - newest.timestamp_ms else 0;
            if (age > display_ms) return null;
        }
        return newest;
    }

    /// Fresh announcements win; an unread sticky state returns after they expire.
    pub fn activeDisplayWithFallback(self: *const Store, now_ms: u64, fallback_id: i64) ?*const Notification {
        if (self.activeDisplay(now_ms)) |newest| return newest;
        const fallback = self.find(fallback_id) orelse return null;
        return if (!fallback.read and fallback.sticky) fallback else null;
    }

    pub fn find(self: *const Store, id: i64) ?*const Notification {
        if (id == 0) return null;
        for (0..self.count) |index| {
            const item = self.at(index).?;
            if (item.id == id) return item;
        }
        return null;
    }

    pub fn clear(self: *Store) void {
        self.count = 0;
        self.head = 0;
        self.next_id = 1;
    }

    fn atMutable(self: *Store, index_from_newest: usize) ?*Notification {
        if (index_from_newest >= self.count) return null;
        return &self.items[self.indexFromNewest(index_from_newest)];
    }

    fn indexFromNewest(self: *const Store, index_from_newest: usize) usize {
        return (self.head + max_notifications - index_from_newest) % max_notifications;
    }
};

pub fn smokeCheck() bool {
    const parsed = Notification.fromJson("{\"title\":\"Build\",\"body\":\"done\",\"app\":\"CI\",\"urgency\":\"HIGH\",\"sticky\":1}") orelse return false;
    if (parsed.urgency != .high or !parsed.sticky) return false;
    if (!std.mem.eql(u8, field(&parsed.title), "Build")) return false;
    var output: [2048]u8 = undefined;
    const json = parsed.toJson(&output, true) orelse return false;
    if (!MiniJson.hasKey(json, "id") or !MiniJson.hasKey(json, "sticky")) return false;

    var store = Store{};
    const first = store.pushAt(parsed, 100);
    if (first.id != 1 or store.unreadCount() != 1) return false;
    if (store.activeDisplay(100 + display_ms + 1) == null) return false;
    if (store.markRead(first.id) != 1 or store.activeDisplay(101) != null) return false;
    const transient = Notification.fromJson("{\"title\":\"transient\"}") orelse return false;
    const second = store.pushAt(transient, 200);
    if (second.id != 2 or store.find(1) == null) return false;
    if (store.markAllReadExcept(2) != 0 or store.unreadCount() != 1) return false;

    var call = Notification{};
    call.sticky = true;
    const active_call = store.pushAt(call, 300);
    const active_call_id = active_call.id;
    const message = store.pushAt(transient, 301);
    if (store.activeDisplayWithFallback(301, active_call_id).?.id != message.id) return false;
    if (store.activeDisplayWithFallback(301 + display_ms + 1, active_call_id).?.id != active_call_id) return false;
    if (store.markRead(active_call_id) != 1 or store.activeDisplayWithFallback(301 + display_ms + 1, active_call_id) != null) return false;
    return true;
}
