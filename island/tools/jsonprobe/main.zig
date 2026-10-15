const std = @import("std");
const MiniJson = @import("MiniJson");
const Notification = @import("Notification");

extern "kernel32" fn ExitProcess(exit_code: u32) callconv(.winapi) noreturn;

var failures: usize = 0;

fn check(ok: bool, name: []const u8, detail: []const u8) void {
    std.debug.print("{s} {s:<46} {s}\n", .{ if (ok) "[ OK ]" else "[FAIL]", name, detail });
    if (!ok) failures += 1;
}

fn cString(text: []const u8) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse text.len];
}

fn equals(actual: []const u8, expected: []const u8) bool {
    return std.mem.eql(u8, cString(actual), expected);
}

pub fn main() void {
    failures = 0;
    std.debug.print("jsonprobe: MiniJson + Notification\n-------------------------------------------------\n", .{});
    var value: [256]u8 = @splat(0);
    const simple = "{\"app\":\"dsh\",\"title\":\"Build finished\",\"body\":\"3 warnings\"}";

    std.debug.print("-- step 1: GetString on a flat document --\n", .{});
    const got = MiniJson.getString(simple, "app", &value);
    check(got and equals(&value, "dsh"), "reads a flat string", cString(&value));

    std.debug.print("-- step 2: missing key --\n", .{});
    check(!MiniJson.getString(simple, "missing", &value), "missing key reports false", "");

    std.debug.print("-- step 3: small buffer --\n", .{});
    check(MiniJson.getString(simple, "app", value[0..3]) and equals(value[0..3], "ds"), "truncates into a small buffer", cString(value[0..3]));

    std.debug.print("-- step 4: whitespace --\n", .{});
    const spaced = "{ \"title\" : \"x\" , \"n\" : 42 }";
    check(MiniJson.getString(spaced, "title", &value) and equals(&value, "x"), "whitespace around key and colon", cString(&value));

    std.debug.print("-- step 5: integers --\n", .{});
    check(MiniJson.getInt(spaced, "n") == 42, "reads an integer", "");

    std.debug.print("-- step 6: nested key --\n", .{});
    const nested = "{\"outer\":{\"title\":\"WRONG\"},\"title\":\"RIGHT\"}";
    check(MiniJson.getString(nested, "title", &value) and equals(&value, "RIGHT"), "ignores a nested key", cString(&value));

    std.debug.print("-- step 7: key inside a value --\n", .{});
    const in_value = "{\"body\":\"the word \\\"title\\\":\\\"nope\\\" is inside me\"}";
    check(!MiniJson.getString(in_value, "title", &value), "no match inside another value", "");

    std.debug.print("-- step 8: array element key --\n", .{});
    const array = "{\"list\":[{\"title\":\"WRONG\"}],\"title\":\"RIGHT\"}";
    check(MiniJson.getString(array, "title", &value) and equals(&value, "RIGHT"), "ignores a key inside an array", cString(&value));

    std.debug.print("-- step 9: escapes --\n", .{});
    const escaped = "{\"title\":\"a\\\"b\\\\c\\nd\\te\"}";
    check(MiniJson.getString(escaped, "title", &value) and equals(&value, "a\"b\\c\nd\te"), "decodes escapes", cString(&value));

    std.debug.print("-- step 10: \\u escape --\n", .{});
    const unicode = "{\"title\":\"\\u4e2d\\u6587\"}";
    check(MiniJson.getString(unicode, "title", &value) and equals(&value, "中文"), "decodes \\uXXXX", cString(&value));

    std.debug.print("-- step 11: malformed documents --\n", .{});
    const malformed = [_][]const u8{
        "",   "{",    "}",                         "{\"title\"", "{\"title\":}", "{\"title\":\"unterminated",
        "[]", "null", "{\"title\":\"ok\"}garbage",
    };
    for (malformed, 0..) |document, index| {
        std.debug.print("   case {d}: '{s}'\n", .{ index, document });
        var scratch: [256]u8 = @splat(0);
        _ = MiniJson.getString(document, "title", &scratch);
        _ = MiniJson.hasKey(document, "title");
        _ = MiniJson.getInt(document, "title");
    }
    check(true, "malformed documents returned", "");

    std.debug.print("-- step 12: notification parsing --\n", .{});
    const parsed = Notification.Notification.fromJson("{\"app\":\"dsh\",\"title\":\"Build ok\",\"body\":\"clean\"}");
    check(parsed != null, "parses a message", if (parsed) |item| cString(&item.title) else "");
    check(Notification.Notification.fromJson("{\"app\":\"dsh\"}") == null, "rejects an empty message", "");

    std.debug.print("-- step 13: store push --\n", .{});
    var store = Notification.Store{};
    const pushed = store.pushAt(parsed orelse .{}, 100);
    check(pushed.id == 1, "push assigns id 1", "");
    check(store.count == 1 and store.unreadCount() == 1, "counts as unread", "");

    std.debug.print("-- step 14: store overflow --\n", .{});
    var item = Notification.Notification{};
    for (0..Notification.max_notifications + 10) |index| {
        @memset(&item.title, 0);
        const title = std.fmt.bufPrint(&item.title, "item {d}", .{index}) catch unreachable;
        item.title[title.len] = 0;
        _ = store.pushAt(item, 200 + index);
    }
    check(store.count == Notification.max_notifications, "capacity respected", "");

    std.debug.print("-- step 15: mark read and clear --\n", .{});
    _ = store.markAllRead();
    check(store.unreadCount() == 0, "nothing unread", "");
    store.clear();
    check(store.count == 0, "cleared", "");

    std.debug.print("-------------------------------------------------\nRESULT: {s} ({d} failures)\n", .{ if (failures == 0) "PASS" else "FAIL", failures });
    if (failures != 0) ExitProcess(1);
}
