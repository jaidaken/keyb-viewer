# studio-reader

status=active pane=na session=bg-job ts=1781687000
outcome: (not started) Rust sidecar to read keymap + physical layout from the device over the ZMK Studio RPC, so the overlay live-syncs with on-device Studio edits instead of reading the keymap file.

decisions:
- Rust + zmk-studio-api 0.3.1 (Zig has no usable protobuf path for the Studio schemas). a sidecar that emits JSON the overlay reads.
- Studio RPC: USB CDC serial, delimiter framing (SoF 0xAB, EoF 0xAD, esc 0xAC), protobuf. get_keymap (layers+names+raw BehaviorBinding behavior_id+param1/param2) + get_physical_layouts. READS are NOT unlock-gated. combos/macros ABSENT (devicetree only) so combos stay on keymap-drawer.
- bindings are RAW -> resolve via behaviors.get_behavior_details + a client HID->glyph table (the hard part).

files: host/studio-reader/ (Cargo.toml w/ zmk-studio-api 0.3.1 + lints, src/main.rs stub). flake.nix has rust/cargo/udev. crate fetches clean (protoc deps).

dropped: -

next: study the zmk-studio-api crate source (docs only 16% documented) to learn StudioClient connect/get_keymap/get_physical_layouts signatures; write the client; test against the device on /dev/ttyACM0 (Studio CDC). emit layout.json-compatible JSON. ONLY worth it if file/Studio desync annoys Jamie in daily use; keymap-drawer file pipeline already covers legends+combos+any-board.
