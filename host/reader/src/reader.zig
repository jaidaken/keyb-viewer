//! Decoding of keyb-viewer Raw HID reports. See docs/protocol.md.

const std = @import("std");

pub const report_layer: u8 = 0x01;
pub const report_key: u8 = 0x02;

pub const LayerState = struct {
    bitmap: u32,
    highest: u8,
};

pub const KeyEvent = struct {
    position: u8,
    pressed: bool,
};

pub const Event = union(enum) {
    layer: LayerState,
    key: KeyEvent,
};

/// Decode one Raw HID report. Returns null for an unknown type or a report too
/// short for its type. Never reads out of bounds.
pub fn decode(report: []const u8) ?Event {
    if (report.len < 3) return null;
    switch (report[0]) {
        report_layer => {
            if (report.len < 6) return null;
            const bm = @as(u32, report[1]) |
                (@as(u32, report[2]) << 8) |
                (@as(u32, report[3]) << 16) |
                (@as(u32, report[4]) << 24);
            return .{ .layer = .{ .bitmap = bm, .highest = report[5] } };
        },
        report_key => {
            return .{ .key = .{ .position = report[1], .pressed = report[2] != 0 } };
        },
        else => return null,
    }
}

const t = std.testing;

test "decode reads a layer report's bitmap and highest layer" {
    const r = [_]u8{ 0x01, 0x06, 0x00, 0x00, 0x00, 0x02 } ++ [_]u8{0} ** 26;
    const ev = decode(&r) orelse return error.TestUnexpectedNull;
    try t.expectEqual(@as(u32, 0x06), ev.layer.bitmap);
    try t.expectEqual(@as(u8, 2), ev.layer.highest);
}

test "decode reads a key press report" {
    const r = [_]u8{ 0x02, 13, 1 } ++ [_]u8{0} ** 29;
    const ev = decode(&r) orelse return error.TestUnexpectedNull;
    try t.expectEqual(@as(u8, 13), ev.key.position);
    try t.expect(ev.key.pressed);
}

test "decode reads a key release report" {
    const r = [_]u8{ 0x02, 13, 0 } ++ [_]u8{0} ** 29;
    const ev = decode(&r) orelse return error.TestUnexpectedNull;
    try t.expect(!ev.key.pressed);
}

test "decode rejects an unknown report type" {
    const r = [_]u8{ 0x09, 1, 2 } ++ [_]u8{0} ** 29;
    try t.expect(decode(&r) == null);
}

test "decode rejects a report too short for any type" {
    const r = [_]u8{0x01};
    try t.expect(decode(&r) == null);
}

test "decode rejects a layer report shorter than its fields" {
    const r = [_]u8{ 0x01, 0x06, 0x00 };
    try t.expect(decode(&r) == null);
}

test "decode extracts the right source bytes for any random input" {
    var prng = std.Random.DefaultPrng.init(0xC0FFEE);
    const rnd = prng.random();
    var buf: [32]u8 = undefined;
    var i: usize = 0;
    while (i < 5000) : (i += 1) {
        rnd.bytes(&buf);
        if (decode(&buf)) |ev| switch (ev) {
            .key => |k| try t.expectEqual(buf[1], k.position),
            .layer => |l| try t.expectEqual(buf[5], l.highest),
        };
    }
}
