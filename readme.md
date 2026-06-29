# KLOR ZMK config

A [urob](https://github.com/urob/zmk-config)-style ZMK config for the **KLOR
polydactyl** (split, 2× rotary encoder, `nice_nano_v2`), with:

- **QWERTY** base layer + urob's timeless homerow mods (GUI / Alt / Shift / Ctrl)
- A **vim-style NAV layer** (hjkl arrows, page up/down, bspc/del, smart
  word/line selection)
- **Smart word/line selection** modelled on
  [getreuer's select_word](https://github.com/getreuer/qmk-modules/tree/main/select_word):
  tap to select, repeat to extend, any other key resets (built on `zmk-tri-state`)
- **No repeat key**: the right thumb is a plain magic-shift — tap = sticky shift,
  shift+tap = caps-word, hold = shift
- **NAV hold-taps** (urob's): arrows hold = line start/end + doc start/end;
  bspc/del hold = delete word
- urob's **combos**, **number/numword**, **mouse layer + smart-mouse**, **FN/SYS**
- **Two encoders**: left = volume, right = page scroll (edit in `config/klor.keymap`)
- **Portuguese accents + currency** (€ £ $ ¢ ¥) via the leader key + `zmk-unicode`
- **`make draw`** renders all layers to `draw/klor.svg` (keymap-drawer)

## Layout overview

| Layer | Notes |
|-------|-------|
| `DEF` | QWERTY; homerow mods on `ASDF`/`JKL;`; thumbs: space/NAV, FN/Ret, Num, Shift |
| `NAV` | left = sticky mods + alt-tab; right = `bspc pgdn pgup del` / `← ↓ ↑ →` (hold = home/end/doc/word) / word+line select |
| `FN`  | F-keys, media, desktop nav |
| `NUM` | numpad + numword |
| `SYS` | Bluetooth select, USB/BLE output, bootloader, reset (FN+NUM) |
| `MOUSE` | mouse move/scroll/clicks (smart-mouse toggle = `W`+`E` combo) |

Extra KLOR keys (not in urob's 34-key base) are layer-constant: outer column =
`Shift`/`Ctrl` (left), `'`/`Enter` (right); encoder pushes = `Mute`/`Play-Pause`;
extra thumbs = `Esc`, `Gui/Tab`, `SYS`, `Bspc`. Tweak these in
`config/klor.keymap`.

## Building (Docker only)

Needs a container engine — the `Makefile` auto-detects `docker`, and falls back
to `podman` if docker isn't installed (override with `make ENGINE=podman ...`).
No host toolchain otherwise.

```sh
make init     # once: create the west workspace and fetch ZMK + modules
make build    # build both halves -> firmware/klor_{left,right}.uf2
```

Then double-tap reset on a half to enter the bootloader and copy the matching
`.uf2` onto the USB drive that appears (or `make flash-left` / `flash-right`
after adjusting `MOUNT` in the `Makefile`). Flash the **left** half first (it's
the BLE central).

`make shell` drops you into the build container; `make clean` / `make pristine`
remove artifacts. A `docker-compose.yml` is provided as an alternative.

### Keymap diagram

`make draw` renders all layers to `draw/klor.svg` (via keymap-drawer in a
Python container). It needs `make init` to have run, since the renderer resolves
the zmk-helpers macros through `modules/` — `draw/config.yaml` points its
preprocessor there. keymap-drawer ships a built-in `klor` physical layout, so
the diagram matches the board.

## Unicode setup

Sequences assume Linux IBus input (`Ctrl+Shift+U`). Change `default-mode` in
`config/klor.keymap` for macOS/Windows. Trigger the leader with the `S`+`D`
combo (positions `LM2`+`LM1`), then:

- acute: `a e i o u` → á é í ó ú
- tilde: `n a` / `n o` → ã õ
- circumflex: `h a` / `h e` / `h o` → â ê ô
- grave: `g a` → à · cedilha: `c` → ç
- currency: `m e/l/d/c/y` → € £ $ ¢ ¥

Hold Shift during a letter sequence for the uppercase glyph.

## Customising

- **Encoders / extra keys**: `config/klor.keymap`
- **Layers, homerow mods, behaviors**: `config/base.keymap`
- **Combos**: `config/combos.dtsi` · **Leader**: `config/leader.dtsi` ·
  **Mouse**: `config/mouse.dtsi`
- **Per-key RGB** (off by default): see the note at the bottom of
  `config/klor.conf`.

The KLOR shield itself is vendored under `config/boards/shields/klor/`.

> Word/line selection uses Ctrl-based (Windows/Linux) cursor motions. For macOS,
> swap `Ctrl`→`Alt` in the `sw_*_init` macros and use `Gui` for line motions in
> `config/base.keymap`.
