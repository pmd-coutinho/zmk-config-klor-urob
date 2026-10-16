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
| `MOUSE` | mouse move/scroll/clicks (smart-mouse toggle = `E`+`R` combo) |

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

The west workspace (ZMK, Zephyr, modules, build dirs) lives in the gitignored
`.zmk/` folder. Dependency pins are in `config/west.yml` and track
[urob's](https://github.com/urob/zmk-config/blob/main/config/west.yml).

### Tests

`make test` replays scripted key presses through the real keymap on ZMK's
`native_sim` board and diffs the keycodes it sends against
`tests/<case>/expected.log`. It covers the base layer, homerow mods, NAV, combos,
num-word, magic-shift, the leader key and the Gui/Tab thumb. Run one case with
`make test T=combos`. After an intentional keymap change, `make test ACCEPT=1`
rewrites the expected logs; review that diff before committing it.

### Recovery

Flashing can't brick the board: the nice!nano's UF2 bootloader is never
overwritten. Double-tap reset to get the `NICENANO` drive back, then copy any
`.uf2` onto it. Any older firmware can be rebuilt from git history; the
pre-migration build (commit `fda0936`) is kept in `firmware/backup/`
(gitignored).

## ZMK Studio

The left (central) half is built with [ZMK Studio](https://zmk.dev/docs/features/studio)
enabled, over USB and BLE (`make build STUDIO=n` turns it off). Open
<https://zmk.studio> (Chrome/Edge) or the native app, then unlock the keyboard
with `&studio_unlock` (SYS layer, top row, third key on the right). On Linux your
user needs access to the USB serial port (e.g. the `uucp`/`dialout` group).

> Once you **save** changes in Studio, they override `config/*.keymap`: later
> edits to the keymap files are ignored until you run "Restore Stock Settings"
> in Studio. Studio can't edit combos, macros, hold-tap timings or encoders.
> Pick one source of truth: Studio for quick tweaks, or the files.

### Keymap diagram

`make draw` renders all layers to `draw/klor.svg` (via keymap-drawer in a
Python container). It needs `make init` to have run, since the renderer resolves
the zmk-helpers macros through `.zmk/modules/` — `draw/config.yaml` points its
preprocessor there. keymap-drawer ships a built-in `klor` physical layout, so
the diagram matches the board.

## Unicode setup

Sequences assume Linux IBus input (`Ctrl+Shift+U`). Change `default-mode` in
`config/klor.keymap` for macOS/Windows. Trigger the leader with the `D`+`F`
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

### Shield / hardware

The repo doubles as a ZMK keyboard module (`zephyr/module.yml`, the layout
ZMK's [unified config template](https://github.com/zmkfirmware/unified-zmk-config-template)
uses). The KLOR shield lives in `boards/shields/klor/`:

- `klor.dtsi`: matrix transform, kscan, encoders, OLED
- `klor-layouts.dtsi`: physical layout (a grid of key positions, needed for
  ZMK Studio)
- `klor_left.overlay` / `klor_right.overlay`: per-half column pins and encoder

Local builds pass the module via `-DZMK_EXTRA_MODULES` (see `Makefile`). ZMK's
GitHub Actions build workflow detects it automatically.

> Word/line selection uses Ctrl-based (Windows/Linux) cursor motions. For macOS,
> swap `Ctrl`→`Alt` in the `sw_*_init` macros and use `Gui` for line motions in
> `config/base.keymap`.
