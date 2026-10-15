const std = @import("std");
const NotificationInput = @import("NotificationInput");

pub const max_notifications = 32;
pub const app_name_capacity = 64;
pub const title_capacity = 160;
pub const body_capacity = 512;
pub const display_ms = 6000;

pub const Urgency = NotificationInput.Urgency;

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
    source: NotificationInput.Source = .pipe,
    source_key: u64 = 0,

    pub fn fromInput(input: NotificationInput.Message) Notification {
        return .{
            .app = input.app,
            .title = input.title,
            .body = input.body,
            .icon_path = input.icon_path,
            .sender_pid = input.sender_pid,
            .urgency = input.urgency,
            .sticky = input.sticky,
            .source = input.source,
            .source_key = input.source_key,
        };
    }

    pub fn toInput(self: *const Notification) NotificationInput.Message {
        return .{
            .app = self.app,
            .title = self.title,
            .body = self.body,
            .icon_path = self.icon_path,
            .sender_pid = self.sender_pid,
            .urgency = self.urgency,
            .sticky = self.sticky,
            .source = self.source,
            .source_key = self.source_key,
        };
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

    pub fn ingest(self: *Store, input: NotificationInput.Message, now_ms: u64) IngestResult {
        if (input.source_key != 0) {
            for (0..self.count) |index| {
                const existing = self.atMutable(index).?;
                if (!existing.read and existing.source == input.source and existing.source_key == input.source_key) {
                    return .{ .notification = existing, .inserted = false };
                }
            }
        }
        return .{ .notification = self.pushAt(Notification.fromInput(input), now_ms), .inserted = true };
    }

    pub fn apply(self: *Store, event: NotificationInput.Event, now_ms: u64) bool {
        return switch (event) {
            .message => |message| self.ingest(message, now_ms).inserted,
            .dismiss_source => |identity| self.markSourceRead(identity.source, identity.key) != 0,
        };
    }

    pub fn markSourceRead(self: *Store, source: NotificationInput.Source, source_key: u64) usize {
        if (source_key == 0) return 0;
        var changed: usize = 0;
        for (0..self.count) |index| {
            const notification = self.atMutable(index).?;
            if (!notification.read and notification.source == source and notification.source_key == source_key) {
                notification.read = true;
                changed += 1;
            }
        }
        return changed;
    }

    pub fn sourceNotificationId(self: *const Store, source: NotificationInput.Source, source_key: u64) ?i64 {
        if (source_key == 0) return null;
        for (0..self.count) |index| {
            const notification = self.at(index).?;
            if (!notification.read and notification.source == source and notification.source_key == source_key) return notification.id;
        }
        return null;
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

pub const IngestResult = struct { notification: *Notification, inserted: bool };

pub fn smokeCheck() bool {
    var store = Store{};
    var first_message = Notification{};
    @memcpy(first_message.title[0..5], "Build");
    @memcpy(first_message.body[0..4], "done");
    const first = store.pushAt(first_message, 100);
    if (first.id != 1 or store.unreadCount() != 1) return false;
    if (store.activeDisplay(100 + display_ms + 1) == null) return false;
    if (store.markRead(first.id) != 1 or store.activeDisplay(101) != null) return false;
    var transient = Notification{};
    @memcpy(transient.title[0..9], "transient");
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

test "notification input dedupe and source dismissal belong to the Feature store" {
    var store = Store{};
    const input = NotificationInput.Message{
        .title = [_]u8{'x'} ++ @as([title_capacity - 1]u8, @splat(0)),
        .source = .wechat_call,
        .source_key = 77,
        .sticky = true,
    };
    const first = store.ingest(input, 10);
    const duplicate = store.ingest(input, 20);
    try std.testing.expect(first.inserted);
    try std.testing.expect(!duplicate.inserted);
    try std.testing.expectEqual(first.notification.id, duplicate.notification.id);
    try std.testing.expect(store.apply(.{ .dismiss_source = .{ .source = .wechat_call, .key = 77 } }, 30));
    try std.testing.expectEqual(@as(usize, 0), store.unreadCount());
}
