# Sofle MX 58 — ZMK config

Parix Sofle MX, 58 keys + 2 rotary encoders, nice!nano v2 per half, wireless.
Stock ZMK `sofle` shield — the board matches upstream, so nothing here
redefines the matrix, the physical layout, or the encoders.

This is **not** a dotfile. `install.sh` does not touch it; there is nothing to
symlink. It lives here because ZMK's reusable build workflow accepts
`config_path` / `build_matrix_path`, so a keyboard config no longer needs a
repository of its own.

```
build.yaml     left (+ ZMK Studio) / right / settings_reset
west.yml       ZMK source, pinned to a commit
sofle.conf     encoders, OLED, sleep
sofle.keymap   the actual layout
```

**This directory IS the ZMK config directory**, and it has to sit exactly one
level below the repo root. ZMK's reusable workflow runs `west update` from the
repo root, while `west init -l <dir>` puts the west workspace topdir at the
*parent* of `<dir>` — so nesting this any deeper (`keyboard/sofle/config`) puts
the workspace where west cannot find it, and every build job dies at West
Update. The flat, shield-named layout is also how a multi-board zmk-config is
normally arranged: a second keyboard is another `<shield>.conf` /
`<shield>.keymap` pair here, plus a `build.yaml` entry.

Built by `.github/workflows/zmk-sofle.yml`, which only fires on changes under
this directory.

---

## Read this before touching ZMK Studio

ZMK Studio cannot import or export keymap files. That feature is
[planned, not implemented](https://zmk.dev/docs/features/studio). Studio edits
the **live device** over USB and writes to the keyboard's settings partition.
There is no file you download from here and upload there.

That matters because of the trap: **the moment Studio saves anything, this
`.keymap` file stops being applied**, permanently, even across reflashes —
until you run *Restore Stock Settings* from the Studio UI. Two sources of
truth, and the device silently prefers the other one.

So pick a lane:

| | Source of truth | Good for |
|---|---|---|
| **This repo** (recommended) | `sofle.keymap` → build → flash | everything; the only way to get combos, home-row mods, macros, encoders |
| **Studio** | the device | trying a key swap in ten seconds, in a meeting, on a laptop with no toolchain |

The workflow that keeps both: experiment in Studio, and when a change earns its
place, write it into `sofle.keymap`, *Restore Stock Settings*, then flash. Never
leave a Studio change as the only copy of a decision.

Studio also cannot define combos, tune hold-tap timings, add macros, define new
behaviors, or create layers devicetree did not declare — which is most of what
this keymap is. Two `status = "reserved"` layers exist so Studio at least has
somewhere to put a new one without a reflash.

---

## The hardware, as reported by the board itself

From `INFO_UF2.TXT` on the mounted bootloader drive (2026-09-05):

```
UF2 Bootloader 0.6.0  lib/nrfx (v2.0.0)  lib/tinyusb (0.10.1-41-gdf0cda2d)
                      lib/uf2 (remotes/origin/configupdate-9-gadbb8c7)
Model:       nice!nano
Board-ID:    nRF52840-nicenano
SoftDevice:  S140 version 6.1.1
Date:        Jun 19 2021
```

`Board-ID: nRF52840-nicenano` is the genuine nice!nano target and matches the
`0xADA52840` UF2 family ID in the firmware this repo builds. Bootloader 0.6.0
is old but is what nice!nano v2 shipped with and is fine with current ZMK.
**Do not update it** unless something concretely requires it — it is the one
operation on this board that can actually brick it.

Per-key SK6812MINI-E LEDs, no underglow strip. 1000mAh per half.

## Build and flash

1. Push a change under `keyboard/`. The **Sofle firmware** workflow runs.
2. Open the run in GitHub → download the `sofle-firmware` artifact. It contains
   `sofle_left-nice_nano_v2.uf2`, `sofle_right-nice_nano_v2.uf2`, and
   `settings_reset-nice_nano_v2.uf2`.
3. Unzip **on the machine the keyboard is plugged into**. Flashing is a USB
   mass-storage copy, so it cannot happen from a Codespace — download the
   artifact locally.
4. Per half: plug in USB, **double-tap reset**, wait for the `NICENANO` drive
   to mount, copy the matching `.uf2` onto it — `sofle_left` when the cable is
   in the left half, `sofle_right` when it is in the right.

   The drive shows three files (`CURRENT.UF2`, `INFO_UF2.TXT`, `INDEX.HTM`).
   They are not real files — the bootloader fakes a FAT filesystem — so there
   is nothing to delete first and deletes are ignored. **`CURRENT.UF2` is a
   dump of whatever is on the board right now**, so copying it off before the
   first flash is a free rollback to the vendor's stock firmware.

   The drive vanishes mid-copy and the OS may report the device as
   disconnected or improperly ejected. That is success: the bootloader reboots
   into the new firmware as soon as the write lands.
5. Flash **both halves** whenever the keymap changes. They exchange nothing
   about the keymap at runtime, and mismatched halves fail in confusing ways.

### When things go wrong

- **Halves won't pair, or Studio state is stuck** — flash `settings_reset.uf2`
  to the affected half, let it boot once, then flash the real firmware back.
  This is also the nuclear option for the Studio-overrides-your-keymap trap.
- **Encoders do nothing** — `CONFIG_EC11` in `sofle.conf`. The stock shield
  ships it commented out.
- **Build fails right after a ZMK bump** — the pin in `west.yml` and the `uses:`
  ref in the workflow must name the same commit.
- **A bootloader key seems to do nothing** — it almost certainly worked, on the
  other half. `&bootloader` is declared `BEHAVIOR_LOCALITY_EVENT_SOURCE`, so
  the central forwards it back to the half the key is *physically on* rather
  than running it itself (`zmk/app/src/behavior.c`). Put the cable in that
  half, or use the bootloader key that lives on the half you want. That is why
  ADJ has two: **ADJ+B** for the left half, **ADJ+N** for the right.
- **"Invalid BOARD" at cmake** — the board is `nice_nano@2.0.0/nrf52840/zmk`,
  not `nice_nano_v2`. Since Zephyr 4.1 ZMK uses Zephyr board variants: board
  name `nice_nano`, revision `2.0.0` for the v2 hardware, `/zmk` for the ZMK
  variant. `west boards -f "{name}|{qualifiers}"` lists what actually exists.

---

## The layout

Four layers: `base`, `nav` (left thumb), `media` (right thumb), `adj` (both).

The base layer is meant to be **the TKL you already know** — unshifted QWERTY
where a TKL has it, and TKL's own bottom-row order (Ctrl Win Alt … Alt Win
Ctrl). Every key prints its shifted face in the diagrams, keycap style.

**What could not fit.** Six columns per half cannot hold a TKL's right-side
overflow: a TKL row has `[ ] \` after `P` and `=` after `-`, and there is
nowhere to put them. All four move to **NAV**, contiguous, under the digits
they already neighbour on a TKL:

| | NAV+8 | NAV+9 | NAV+0 | NAV+- |
|---|---|---|---|---|
| plain | `\` | `[` | `]` | `=` |
| +Shift | `\|` | `{` | `}` | `+` |

Shift needs no separate binding: `[` and `{` are the same HID key, so
`NAV+Shift+9` is `{` for free.

**The two keys between the halves are the encoder push-buttons**, not normal
keys — awkward to hit deliberately, easy to hit while turning the knob. They
carry mute (next to the volume knob) and play/pause on base, and Win+L on NAV:
things that are harmless to fire by accident. Never put a typing key there.

**Home-row mods, GACS** — `A`=GUI `S`=Alt `D`=Ctrl `F`=Shift, mirrored right.
This is what makes the daily chords layer-free: `Ctrl+hjkl` (nvim windows),
`Alt+hjkl` (tmux panes) and `Ctrl+Space` (tmux prefix) are all a left-hand hold
plus a right-hand tap.

Two settings carry that: a **cross-hand guard** (`hold-trigger-key-positions`),
so a same-hand roll like `sd` types letters instead of firing Alt; and
`require-prior-idle-ms = 150`, so no mod can trigger mid-burst. Between them,
mods only happen when you meant them. If a mod still fires while typing fast,
raise `require-prior-idle-ms` before touching `tapping-term-ms`.

**`j`+`k` → Esc** as a hardware combo, not an nvim mapping — so it escapes in
nvim insert, in nvim-bash vi mode, in a bare `vi` on a locked-down box, and in
any TUI. Esc is also on its own key at the TKL position; the combo is the fast
one. Base layer only, 45ms window.

**NAV keeps the TKL nav island as an island** — PrtSc/ScrLk/Pause over
Ins/Home/PgUp over Del/End/PgDn, three columns wide, in the three rightmost
columns. Same shape, same relative positions, so PgUp sits directly above PgDn
in the outermost column. Arrows are the TKL **inverted-T**, not hjkl: `hjkl` on
the base layer are already hjkl for vim, and this layer's arrows are for
everything that *isn't* vim — browsers, dialogs, spreadsheets — which is
exactly where the TKL shape is the one already in your fingers. The left hand
mirrors the home-row mods as plain mods, so `Ctrl+Shift+Left` works without
leaving the layer.

**MEDIA** is F1-F12 straight across the number row, in the same order and the
same place a TKL's function row sits above its number row. Transport and volume
are on the right home row, one-handed; brightness is the row above.

**Encoders** are per-layer: base = volume / page scroll, nav = word-wise cursor
/ tab cycling, media = volume / brightness.

`&studio_unlock` is on ADJ + `U`. Studio refuses every edit until it is pressed.

**Bootloader has a single-half escape hatch.** On NAV, pressing the two ends
of the left half's number row together (`` ` `` + `5`) puts the **left** half
into the bootloader; the same gesture on the right half's number row (`6` +
`-`) does the right. Both use a 50ms window, so they are not hittable by
accident.

The left one is the one that matters: NAV is a left thumb and both keys are
left-half, so it is entirely local to the central and works with the right
half flat, unpaired, or running different firmware. Every ADJ binding needs
the halves paired, because ADJ is NAV + MEDIA — thumbs on opposite halves —
and that is exactly the state you cannot rely on when you need a bootloader.
On a board whose reset button is sealed inside the case, that difference is
whether you can reflash at all.

The right-half combo still needs pairing. A ZMK peripheral never runs the
keymap — it only forwards key positions to the central — so a peripheral
cannot rescue itself with a keypress, and no keymap change can alter that.

**Bootloader is deliberately two keys, one per half** — `ADJ+B` on the left,
`ADJ+N` on the right. `&bootloader` runs on the half the key is physically on,
not on the central, so a single key could only ever reflash one side. Pressing
the wrong one looks like nothing happened: that half quietly reboots into a
bootloader with no USB attached and drops off Bluetooth.

## Per-key RGB

The per-key LEDs are **SK6812MINI-E** — addressable, WS2812-protocol parts. ZMK
drives them with its **underglow** subsystem, not its *backlight* one, which
trips people up: "backlight" in ZMK means a single-colour array that explicitly
cannot dim individual LEDs. So `CONFIG_ZMK_RGB_UNDERGLOW=y` is correct here even
though nothing glows from underneath.

`chain-length` is **29 per half**, overridden from `sofle.keymap`. The stock
shield overlay says 36 and calls it "arbitrary" — it isn't: a fully populated
Sofle RGB is 29 per-key + 6 rear underglow + 1 front indicator = 36. This build
has the per-key LEDs only. To check the number is right, pick the spectrum
effect and see whether the sweep reaches the last key; if the far end stays
dark, raise it.

### What ZMK cannot do

Worth knowing before designing around it — all three verified by reading
`zmk/app/src/rgb_underglow.c`, not the docs:

- **No per-key addressing.** "Light only the keys that exist on this layer" is
  not possible. ZMK has no RGB matrix.
- **No typing heatmap.** That is QMK's `RGB_MATRIX_TYPING_HEATMAP`.
- **No reactive lighting** — nothing lights up in response to a keypress.

There are exactly four effects, all whole-chain: **solid, breathe, spectrum,
swirl**.

### Layer colour

The closest thing to a layer indicator is the **whole board** changing colour,
so that is what this does. ZMK has no "layer entered" hook in the keymap, so
the layer keys are macros that activate the layer *and* set the colour —
`nav_rgb` / `media_rgb` in `sofle.keymap`. Hues are the repo's catppuccin
accents, so the board matches the editor: base blue, nav green, media mauve.

Two limits fall out of that. It is **only visible on the solid effect** —
spectrum and swirl paint over it. And **ADJ gets no colour**: it is a
conditional layer with no key to hang a macro on, so holding NAV+MEDIA shows
whichever you pressed second.

### Controls — MEDIA layer, left hand

| | | | | | |
|---|---|---|---|---|---|
| row 1 | `RGB_TOG` | dim | bright | prev effect | next effect |
| row 3 | speed − | hue − | hue + | sat − | sat + |

### Battery

This is the whole story on a wireless board. 29 RGB LEDs per half at full white
is roughly `29 x 60mA = 1.7A`, which a 1000mAh cell turns into well under an
hour. A single mid-brightness hue is nearer 200–350mA — hours, against the
**weeks** this board gets with the LEDs off.

So the defaults are deliberately timid: LEDs **start off** (opt in per session
with `RGB_TOG`), brightness is capped at 50% so a held brightness key cannot
reach the ugly end of that range, and they drop when the board goes idle. If
you decide the lights are a desk luxury rather than a portable one, uncomment
`CONFIG_ZMK_RGB_UNDERGLOW_AUTO_OFF_USB=y` — LEDs only while plugged in, and by
far the biggest single win.

Note that toggling the LEDs off also cuts external power, which **takes the
OLED with it**. That is the right trade for battery; set
`CONFIG_ZMK_RGB_UNDERGLOW_EXT_POWER=n` if you would rather keep the display.

## Printable diagrams

```
keymap.svg   vector — print this (browser -> Print, fits A4/Letter portrait)
keymap.png   raster — for a phone, or a quick look
keymap.txt   ASCII  — `sofle-cs` in a terminal, works over ssh
scripts/gen-keymap-art   regenerates all three
```

All three are **generated from `sofle.keymap`**, never hand-drawn, so a
diagram that disagrees with the firmware is impossible rather than merely
unlikely. Regenerate after any keymap change:

```bash
pip install keymap-drawer          # parser + SVG
sudo apt install librsvg2-bin      # optional, for the PNG only
./scripts/gen-keymap-art
```

The outputs are committed, so reading them needs none of that installed.

`keymap.txt` is **pure 7-bit ASCII on purpose**. Box-drawing characters and the
better-looking transparent glyph `▽` are East Asian *Ambiguous* width: a
terminal running a Nerd Font or a CJK locale renders them two columns wide and
the grid shears apart. `+---+` and `|` are one column everywhere. The generator
asserts both ASCII-ness and column width before writing, so this cannot
silently regress.

Three things `keymap-drawer.yaml` has to handle. It draws layer headers with a
fat white stroke behind the fill via `paint-order`, which Chrome honours and
librsvg/cairosvg do not — they paint the stroke straight over the glyphs, so
every header renders invisible or as a black blob; the config drops the stroke,
which costs nothing because headers sit in clear space. `raw_binding_map` maps
bare ZMK behaviors that would otherwise print as devicetree node names
(`&studio_unlock` -> `UNLOCK`). And `zmk_keycode_map` spells out the
**shifted faces** — keymap-drawer knows the shifted keycodes (`&kp LBRC` is
`{`) but not that an unshifted one also has a second legend, so `&kp COMMA` is
just `,` to it until told otherwise. **Add to both maps when you add a macro or
a punctuation key.**

Encoders are not in the SVG (keymap-drawer does not draw them); `keymap.txt`
lists them per layer.

## Bumping ZMK

Pick a `zmkfirmware/zmk` commit, put it in **both** `west.yml`
(`revision`) and `.github/workflows/zmk-sofle.yml` (the `uses:` ref), build,
flash both halves. Pinned rather than floating `main` for the same reason the
bat themes and fzf-git installs are pinned: the firmware you flash should be
the firmware you tested.
