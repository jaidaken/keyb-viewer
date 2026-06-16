const std = @import("std");
const reader = @import("reader");

const c = @cImport({
    @cInclude("hidapi/hidapi.h");
});

const vendor_id: c_ushort = 0x1d50;
const usage_page: u16 = 0xff60;
const report_size: usize = 32;

pub fn main() !void {
    if (c.hid_init() != 0) {
        std.log.err("hid_init failed", .{});
        return error.HidInit;
    }
    defer _ = c.hid_exit();

    while (true) {
        const dev = openDevice() orelse {
            sleep1s();
            continue;
        };
        runReadLoop(dev) catch |err| std.log.warn("read loop ended: {t}", .{err});
        c.hid_close(dev);
        sleep1s();
    }
}

/// Enumerate the keyboard's HID interfaces and open the vendor Raw HID one
/// (usage page 0xFF60). Returns null if not present yet.
fn openDevice() ?*c.hid_device {
    const list = c.hid_enumerate(vendor_id, 0);
    if (list == null) return null;
    defer c.hid_free_enumeration(list);

    var cur: ?*c.struct_hid_device_info = list;
    while (cur) |info| : (cur = info.next) {
        if (info.usage_page != usage_page) continue;
        if (info.path == null) continue;
        const dev = c.hid_open_path(info.path);
        if (dev != null) return dev;
    }
    return null;
}

fn runReadLoop(dev: *c.hid_device) !void {
    var buf: [report_size]u8 = undefined;
    var line: [64]u8 = undefined;
    while (true) {
        const n = c.hid_read_timeout(dev, &buf, report_size, 1000);
        if (n < 0) return error.HidReadFailed;
        if (n == 0) continue;
        const ev = reader.decode(buf[0..@intCast(n)]) orelse continue;
        const out = format(&line, ev) orelse continue;
        _ = std.c.write(1, out.ptr, out.len);
    }
}

fn format(buf: []u8, ev: reader.Event) ?[]u8 {
    return switch (ev) {
        .layer => |l| std.fmt.bufPrint(buf, "{{\"t\":\"L\",\"hi\":{d},\"bm\":{d}}}\n", .{ l.highest, l.bitmap }) catch null,
        .key => |k| std.fmt.bufPrint(buf, "{{\"t\":\"K\",\"p\":{d},\"d\":{d}}}\n", .{ k.position, @intFromBool(k.pressed) }) catch null,
    };
}

fn sleep1s() void {
    const ts = std.c.timespec{ .sec = 1, .nsec = 0 };
    _ = std.c.nanosleep(&ts, null);
}
