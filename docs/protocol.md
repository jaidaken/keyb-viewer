# keyb-viewer Raw HID protocol

Send-only, keyboard to host. Vendor HID usage page `0xFF60`, usage `0x61`,
fixed 32-byte reports (`zzeneg/zmk-raw-hid` transport). Byte 0 is the report
type; unused trailing bytes are zero.

## `0x01` LAYER_STATE

Sent on every layer change (and the host treats the first one after connect as
the initial sync).

| byte | meaning |
|------|---------|
| 0    | `0x01` |
| 1..4 | active-layer bitmap, u32 little-endian (bit N = layer N active) |
| 5    | highest active layer index, u8 |

## `0x02` KEY_EVENT

Sent on every physical key press and release.

| byte | meaning |
|------|---------|
| 0    | `0x02` |
| 1    | key matrix position, u8 (0-based, keymap binding order) |
| 2    | `1` pressed, `0` released |

## Notes

- Split keyboards emit from the central half only.
- Position is the flat ZMK keymap index; the host maps it to physical layout
  using the parsed `corne.keymap`.
