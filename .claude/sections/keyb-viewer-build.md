# keyb-viewer build

status=done pane=na session=bg-job ts=1781687000
outcome: live on-screen ZMK key/layer visualizer for Jamie's Corne, working end-to-end (firmware raw-HID feed -> zig reader -> noctalia QML overlay). full detail in README.md + .claude/handoffs/2c9dd7b2-d4e4-46a6-bb92-0ed0f89b650f.md.

decisions:
- ride nice_oled's existing raw HID (no zzeneg, no 0xFF60 collision); emit module = repo-root ZMK module.
- keymap-drawer (build-time, host/layout/gen_layout.py) for layout coords + legends + combos, any board. raw_binding_map (NOT zmk_keycode_map) for UK label overrides.
- ZMK pinned v0.3.0 (nice_oled requires it); board nice_nano_v2.
- udev rule MODE 0660 GROUP dialout (uaccess failed: niri session not logind-seated).
- UK: POUND=£ NUHS=# @=LS(SQT) "=LS(N2) \=NUBS |=PIPE2 ~=TILDE2.
- Studio enabled in firmware (live editing); reader to consume it = deferred (see studio-reader section).

files:
- Corne-layout (jaidaken/Corne-layout, his zmk-config): config/corne.keymap, corne.conf, build.yaml, config/west.yml.
- keyb-viewer (jaidaken/keyb-viewer): zephyr/ src/ CMakeLists.txt Kconfig (firmware module); host/reader/ (zig); host/overlay/ (shell.qml, config.json, layout.json); host/layout/ (gen_layout.py, keymap-drawer.yaml); host/nixos/keyb-viewer-udev.nix; flake.nix; README.md.
- nixos-config: nix-modules/system/boot.nix (udev rule), nix-modules/home/niri.nix (xkb gb).

dropped: the long permission saga (chmod attempts, uaccess-vs-group debugging); the abandoned hardcoded grid + zig keycode parser; the Studio-vs-keymap-drawer back-and-forth; build-cycle failure noise (board rename, HWMv2 variant, artifact slash, nice_view-vs-OLED misdiagnosis).

next: Jamie to flash latest firmware (host/build-artifacts/) for UK Symbols + studio_unlock, verify symbols type right. Then optional studio-reader section below.
