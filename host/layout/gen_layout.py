#!/usr/bin/env python3
"""Generate host/overlay/layout.json for the keyb-viewer overlay.

Uses keymap-drawer to turn any ZMK config into per-key coordinates + per-layer
legends + combos. Key order matches the ZMK keymap binding order, which is the
position index our raw HID feed reports, so highlighting aligns on any board.

  gen_layout.py <config.keymap> [zmk_keyboard] > layout.json
"""
import json
import subprocess
import sys

import yaml
from keymap_drawer.config import Config
from keymap_drawer.physical_layout import PhysicalLayoutGenerator


def parse_legends_and_combos(keymap_path):
    out = subprocess.run(
        ["keymap", "parse", "-z", keymap_path],
        capture_output=True, text=True, check=True,
    ).stdout
    data = yaml.safe_load(out)
    return data.get("layers", {}), data.get("combos", [])


def gen_coords(zmk_keyboard):
    layout = PhysicalLayoutGenerator(config=Config(), zmk_keyboard=zmk_keyboard).generate()
    return [
        {"x": k.pos.x, "y": k.pos.y, "w": k.width, "h": k.height, "r": k.rotation}
        for k in layout.keys
    ]


SHORT = {
    "ESCAPE": "Esc", "BSPC": "Bspc", "DELETE": "Del", "RET": "Ent", "ENTER": "Ent",
    "SPACE": "Spc", "TAB": "Tab", "HOME": "Home", "END": "End",
    "PAGE DOWN": "PgDn", "PAGE UP": "PgUp", "PRINTSCREEN": "PrSc", "CAPSLOCK": "Caps",
    "LEFT": "←", "RIGHT": "→", "UP": "↑", "UP ARROW": "↑", "DOWN": "↓",
    "LCTRL": "Ctrl", "RCTRL": "Ctrl", "LSHIFT": "Shft", "RSHIFT": "Shft", "LEFT SHIFT": "Shft",
    "LEFT ALT": "Alt", "RIGHT ALT": "Alt", "LALT": "Alt", "RALT": "Alt",
    "LCMD": "Cmd", "LGUI": "Cmd", "RGUI": "Cmd",
    "&caps": "Caps", "&caps_word": "CapsWd", "&studio_unlock": "Unlock",
}


def short(s):
    return SHORT.get(s, s)


def legend_of(entry):
    if isinstance(entry, dict):
        return {"t": short(entry.get("t", "")), "h": entry.get("h", ""), "s": entry.get("s", "")}
    return {"t": "" if entry is None else short(str(entry)), "h": "", "s": ""}


def main():
    keymap_path = sys.argv[1]
    zmk_keyboard = sys.argv[2] if len(sys.argv) > 2 else "corne"

    layers, combos = parse_legends_and_combos(keymap_path)
    coords = gen_coords(zmk_keyboard)

    out_layers = [
        {"name": name, "keys": [legend_of(e) for e in keys]}
        for name, keys in layers.items()
    ]
    out_combos = [
        {"positions": c.get("p", c.get("key_positions", [])),
         "output": short(c.get("k", c.get("key", "")))}
        for c in combos
    ]

    json.dump({"keys": coords, "layers": out_layers, "combos": out_combos}, sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
