//! Reads a ZMK .keymap on stdin, writes per-layer legends as JSON to stdout.
//!   keymap-parse < config/corne.keymap > host/overlay/layout.json

const std = @import("std");
const keymap = @import("keymap.zig");

pub fn main() void {
    var buf: [65536]u8 = undefined;
    const src = buf[0..readAll(buf[0..])];

    out("{\"layers\":[");
    var first_layer = true;
    var idx: usize = 0;
    while (std.mem.indexOfPos(u8, src, idx, "display-name")) |dn| {
        const q1 = std.mem.indexOfScalarPos(u8, src, dn, '"') orelse break;
        const q2 = std.mem.indexOfScalarPos(u8, src, q1 + 1, '"') orelse break;
        const name = src[q1 + 1 .. q2];

        const bpos = std.mem.indexOfPos(u8, src, q2, "bindings") orelse break;
        const lt = std.mem.indexOfScalarPos(u8, src, bpos, '<') orelse break;
        const gt = std.mem.indexOfScalarPos(u8, src, lt + 1, '>') orelse break;
        const bindings = src[lt + 1 .. gt];
        idx = gt;

        if (!first_layer) out(",");
        first_layer = false;
        out("{\"name\":\"");
        outEscaped(name);
        out("\",\"keys\":[");
        emitKeys(bindings);
        out("]}");
    }
    out("]}\n");
}

fn emitKeys(bindings: []const u8) void {
    var it = std.mem.tokenizeAny(u8, bindings, " \t\r\n");
    var group: [8][]const u8 = undefined;
    var glen: usize = 0;
    var first = true;
    while (it.next()) |tok| {
        if (tok.len > 0 and tok[0] == '&') {
            if (glen > 0) emitKey(group[0..glen], &first);
            glen = 0;
            group[glen] = tok;
            glen += 1;
        } else if (glen > 0 and glen < group.len) {
            group[glen] = tok;
            glen += 1;
        }
    }
    if (glen > 0) emitKey(group[0..glen], &first);
}

fn emitKey(tokens: []const []const u8, first: *bool) void {
    if (!first.*) out(",");
    first.* = false;
    out("\"");
    outEscaped(keymap.bindingLabel(tokens));
    out("\"");
}

fn readAll(buf: []u8) usize {
    var total: usize = 0;
    while (total < buf.len) {
        const n = std.c.read(0, buf.ptr + total, buf.len - total);
        if (n <= 0) break;
        total += @intCast(n);
    }
    return total;
}

fn out(bytes: []const u8) void {
    _ = std.c.write(1, bytes.ptr, bytes.len);
}

fn outEscaped(s: []const u8) void {
    for (s) |ch| {
        switch (ch) {
            '"' => out("\\\""),
            '\\' => out("\\\\"),
            else => out(&[_]u8{ch}),
        }
    }
}
