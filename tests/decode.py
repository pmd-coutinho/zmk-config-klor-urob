#!/usr/bin/env python3
"""Turn ZMK's native_sim debug log into readable key events.

Reads zmk.exe output on stdin, keeps only HID keycode press/release lines and
prints e.g. "down LCTRL", "up A", "down N9 +LSHFT" (implicit/explicit mods).
"""
import re
import sys

KEYBOARD = {0x28: "RET", 0x29: "ESC", 0x2A: "BSPC", 0x2B: "TAB", 0x2C: "SPACE",
            0x2D: "MINUS", 0x2E: "EQUAL", 0x2F: "LBKT", 0x30: "RBKT", 0x31: "BSLH",
            0x33: "SEMI", 0x34: "SQT", 0x35: "GRAVE", 0x36: "COMMA", 0x37: "DOT",
            0x38: "FSLH", 0x39: "CAPS", 0x46: "PSCRN", 0x49: "INS", 0x4A: "HOME",
            0x4B: "PG_UP", 0x4C: "DEL", 0x4D: "END", 0x4E: "PG_DN", 0x4F: "RIGHT",
            0x50: "LEFT", 0x51: "DOWN", 0x52: "UP", 0x9B: "K_CANCEL"}
KEYBOARD.update({0x04 + i: chr(ord("A") + i) for i in range(26)})
KEYBOARD.update({0x1E + i: f"N{(i + 1) % 10}" for i in range(10)})
KEYBOARD.update({0x3A + i: f"F{i + 1}" for i in range(12)})
MODS = ["LCTRL", "LSHFT", "LALT", "LGUI", "RCTRL", "RSHFT", "RALT", "RGUI"]
KEYBOARD.update({0xE0 + i: m for i, m in enumerate(MODS)})
CONSUMER = {0xE2: "C_MUTE", 0xCD: "C_PP", 0xE9: "C_VOL_UP", 0xEA: "C_VOL_DN",
            0xB5: "C_NEXT", 0xB6: "C_PREV"}

LINE = re.compile(r"hid_listener_keycode_(pressed|released): usage_page 0x(\w+) "
                  r"keycode 0x(\w+) implicit_mods 0x(\w+) explicit_mods 0x(\w+)")

for line in sys.stdin:
    m = LINE.search(line)
    if not m:
        continue
    state, page, code, implicit, explicit = m.groups()
    page, code = int(page, 16), int(code, 16)
    table = CONSUMER if page == 0x0C else KEYBOARD
    name = table.get(code, f"0x{page:02x}:0x{code:02x}")
    mods = int(implicit, 16) | int(explicit, 16)
    suffix = "".join(f" +{n}" for i, n in enumerate(MODS) if mods & (1 << i))
    print(f"{'down' if state == 'pressed' else 'up'} {name}{suffix}")
