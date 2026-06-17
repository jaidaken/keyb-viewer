# keyb-viewer

A live, on-screen visualizer for a ZMK split keyboard: shows the keyboard on
screen, lights keys as you press them, and swaps the legends as you change
layers. Built for a Corne on NixOS + niri + noctalia, but the layout/legends
come from the keymap so it works for any ZMK board.

## How it works

```
keyboard events -> firmware emit module -> raw HID (0xFF60) -> zig reader -> JSON stdout -> noctalia QML overlay
                                                                             (layout.json from keymap-drawer)
```

- **Firmware feed**: a ZMK module (lives in the keyboard's `zmk-config`, repo
  `jaidaken/Corne-layout`) rides `nice_oled`'s existing raw-HID channel and
  emits active-layer + per-key press/release. No second HID stack, no collision.
- **`host/reader/`**: Zig 0.16 + `hidapi`. Opens the `0xFF60` device, decodes
  the reports, prints JSON lines (`{"t":"K","p":..,"d":..}` / `{"t":"L",..}`).
- **`host/overlay/shell.qml`**: standalone Quickshell layer-shell panel. Draws
  the board from `layout.json` coordinates (real geometry, rotated thumbs),
  highlights pressed keys, shows the active layer's legends and a combos panel.
  Auto-themes from noctalia's active palette, click-through, configurable via
  `host/overlay/config.json` (anchor / size / opacity / font).
- **`host/layout/gen_layout.py`**: build-time. Uses `keymap-drawer` to turn the
  keymap into `layout.json` (per-key coordinates + legends + combos) for any ZMK
  board. `keymap-drawer.yaml` carries UK keycode-label overrides. Re-run after
  changing the keymap.
- **`host/studio-reader/`**: WIP Rust sidecar (see below).

## Run

```sh
# overlay (reads the live feed + layout.json)
nix develop -c quickshell -p host/overlay

# regenerate layout after a keymap change
nix develop -c python3 host/layout/gen_layout.py <path-to>.keymap corne > host/overlay/layout.json
```

HID access is granted by a udev rule (group `dialout`) in the NixOS config, so
the reader runs without `sudo` and survives reflashes.

## Status

Working end-to-end: keys light, layer-aware legends, noctalia theming,
click-through. The keyboard's firmware also has **ZMK Studio** enabled for live
keymap editing (`zmk.studio`, unlock combo = bottom-row outer corners).

**Not done:** `host/studio-reader/`, a Rust sidecar (using `zmk-studio-api`)
that would read the keymap + layout *from the device* over the Studio RPC, so
the overlay live-syncs with Studio edits instead of reading the keymap file.
Scaffolded only; the client isn't written. Until it exists, edits made in Studio
(on-device) do not appear in the overlay, so keep the keymap file as the source
of truth and re-run `gen_layout.py`.

## Layout

```
host/reader/        zig HID reader -> JSON stdout
host/overlay/       quickshell overlay (shell.qml, config.json, layout.json)
host/layout/        keymap-drawer pipeline (gen_layout.py, keymap-drawer.yaml)
host/studio-reader/ WIP rust Studio RPC client
host/nixos/         udev rule reference
flake.nix           devshell (hidapi, quickshell, python+keymap-drawer, rust)
zephyr/ src/ CMakeLists.txt Kconfig   the ZMK firmware module
```
