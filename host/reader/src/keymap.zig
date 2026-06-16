//! Parse a ZMK .keymap into per-layer key legends. See docs/protocol.md sibling.

const std = @import("std");

pub const key_count = 42;

const code_labels = std.StaticStringMap([]const u8).initComptime(.{
    .{ "ESCAPE", "Esc" },          .{ "ESC", "Esc" },
    .{ "BSPC", "Bspc" },           .{ "BACKSPACE", "Bspc" },
    .{ "TAB", "Tab" },             .{ "RET", "Ent" },
    .{ "RETURN", "Ent" },          .{ "ENTER", "Ent" },
    .{ "SPACE", "Spc" },           .{ "DELETE", "Del" },
    .{ "HOME", "Home" },           .{ "END", "End" },
    .{ "PAGE_UP", "PgUp" },        .{ "PAGE_DOWN", "PgDn" },
    .{ "PRINTSCREEN", "PrSc" },    .{ "CAPSLOCK", "Caps" },
    .{ "LEFT", "Left" },           .{ "RIGHT", "Right" },
    .{ "UP", "Up" },               .{ "UP_ARROW", "Up" },
    .{ "DOWN", "Down" },           .{ "DOWN_ARROW", "Down" },
    .{ "LCTRL", "Ctrl" },          .{ "RCTRL", "Ctrl" },
    .{ "LEFT_CONTROL", "Ctrl" },   .{ "LSHIFT", "Shft" },
    .{ "LEFT_SHIFT", "Shft" },     .{ "RSHIFT", "Shft" },
    .{ "LALT", "Alt" },            .{ "RALT", "Alt" },
    .{ "LEFT_ALT", "Alt" },        .{ "LCMD", "Cmd" },
    .{ "LGUI", "Cmd" },            .{ "RGUI", "Cmd" },
    .{ "MINUS", "-" },             .{ "EQUAL", "=" },
    .{ "PLUS", "+" },              .{ "ASTERISK", "*" },
    .{ "SLASH", "/" },             .{ "BACKSLASH", "\\" },
    .{ "NON_US_BACKSLASH", "\\" }, .{ "SEMICOLON", ";" },
    .{ "COMMA", "," },             .{ "PERIOD", "." },
    .{ "GRAVE", "`" },             .{ "TILDE", "~" },
    .{ "EXCLAMATION", "!" },       .{ "AT_SIGN", "@" },
    .{ "POUND", "#" },             .{ "NUHS", "#" },
    .{ "DOLLAR", "$" },            .{ "PERCENT", "%" },
    .{ "CARET", "^" },             .{ "AMPERSAND", "&" },
    .{ "UNDERSCORE", "_" },        .{ "PIPE", "|" },
    .{ "COLON", ":" },             .{ "LESS_THAN", "<" },
    .{ "GREATER_THAN", ">" },      .{ "LEFT_BRACE", "{" },
    .{ "RIGHT_BRACE", "}" },       .{ "LEFT_BRACKET", "[" },
    .{ "RBKT", "]" },              .{ "RIGHT_BRACKET", "]" },
    .{ "LEFT_PARENTHESIS", "(" },  .{ "RIGHT_PARENTHESIS", ")" },
    .{ "DOUBLE_QUOTES", "\"" },    .{ "SINGLE_QUOTE", "'" },
});

/// Label for a `&kp <code>` keycode. Letters/digits map to themselves; named
/// keys to short forms; unknown codes fall back to the raw code.
pub fn keycodeLabel(code: []const u8) []const u8 {
    if (code.len == 1) return code; // A-Z, single chars
    if (code_labels.get(code)) |l| return l;
    // N0..N9 and NUMBER_1..9 -> the digit
    if (std.mem.startsWith(u8, code, "NUMBER_")) return code[code.len - 1 ..];
    if (code.len == 2 and code[0] == 'N' and code[1] >= '0' and code[1] <= '9') return code[1..];
    // F1..F12 pass through
    if (code[0] == 'F' and code.len >= 2 and code[1] >= '0' and code[1] <= '9') return code;
    return code;
}

/// Label for one binding given its whitespace-split tokens (e.g. {"&kp","Q"}).
pub fn bindingLabel(tokens: []const []const u8) []const u8 {
    if (tokens.len == 0) return "";
    const behavior = tokens[0];
    if (std.mem.eql(u8, behavior, "&kp")) {
        return if (tokens.len >= 2) keycodeLabel(tokens[1]) else "";
    }
    if (std.mem.eql(u8, behavior, "&mo")) {
        return if (tokens.len >= 2) layerShort(tokens[1]) else "mo";
    }
    if (std.mem.eql(u8, behavior, "&trans")) return "";
    if (std.mem.eql(u8, behavior, "&none")) return "";
    if (std.mem.eql(u8, behavior, "&caps")) return "Caps";
    // unknown behavior: strip the leading &
    return if (behavior.len > 0 and behavior[0] == '&') behavior[1..] else behavior;
}

fn layerShort(name: []const u8) []const u8 {
    if (std.mem.eql(u8, name, "NUMBERS")) return "Num";
    if (std.mem.eql(u8, name, "SYMBOLS")) return "Sym";
    if (std.mem.eql(u8, name, "QWERTY")) return "Base";
    return name;
}

const t = std.testing;

test "keycodeLabel maps named keys and passes letters through" {
    try t.expectEqualStrings("Esc", keycodeLabel("ESCAPE"));
    try t.expectEqualStrings("Q", keycodeLabel("Q"));
    try t.expectEqualStrings("@", keycodeLabel("AT_SIGN"));
    try t.expectEqualStrings("F12", keycodeLabel("F12"));
}

test "keycodeLabel maps both number spellings to the digit" {
    try t.expectEqualStrings("4", keycodeLabel("NUMBER_4"));
    try t.expectEqualStrings("7", keycodeLabel("N7"));
}

test "keycodeLabel falls back to the raw code for unknowns" {
    try t.expectEqualStrings("C_MUTE", keycodeLabel("C_MUTE"));
}

test "bindingLabel handles kp, mo, trans, none, and tap-dance" {
    try t.expectEqualStrings("A", bindingLabel(&.{ "&kp", "A" }));
    try t.expectEqualStrings("Num", bindingLabel(&.{ "&mo", "NUMBERS" }));
    try t.expectEqualStrings("", bindingLabel(&.{"&trans"}));
    try t.expectEqualStrings("", bindingLabel(&.{"&none"}));
    try t.expectEqualStrings("Caps", bindingLabel(&.{"&caps"}));
}
