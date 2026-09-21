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
- **OLEDs are dark** — the external power rail, not the display config. Since
  `display/ext_power_boot.c` this should self-heal: leave the board powered
  for a minute (the settings debounce) and power-cycle once. See
  [Displays](#displays).
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
overflow: a TKL row has `[ ] \` after `P` and `=` after `-`. Rather than exile
them to a held layer, they are **chords on base**, which frees the two real
keys whose TKL position is worth most: **BSPC top-right**, and `-`/`_` right
after `P`.

| chord | plain | +Shift |
|---|---|---|
| `;` + `'` | `[` | `{` |
| `/` + bottom-right corner | `]` | `}` |
| `L` + `;` | `=` | `+` |
| `,` + `.` | `\` | `\|` |

Shift needs no separate binding: `[` and `{` are the same HID key.

**Three of those deliberately have no `require-prior-idle-ms`.** Every other
combo here does, because `,.`, `jk` and `qw` are sequences you genuinely type
and the guard is what stops a fast roll firing them. `;'`, `/]` and `l;` are
the opposite — pairs that essentially never occur — so the guard buys nothing
and costs a lot: it makes a combo *refuse to fire mid-burst*, which would break
`]d]d]d` through this config's ~20 `[x`/`]x` nvim mappings, and `==`/`<=`/`!=`,
which is most lines of RTL. The one real exposure is a single-letter variable
`l` before a semicolon in `L`+`;`; that is the pair to change first if `=`
starts appearing where it should not.

`[ ] \ =` also stay on NAV+9 / NAV+0 / NAV+8 / NAV+- as a fallback.

**The two keys between the halves are the encoder push-buttons**, not normal
keys — awkward to hit deliberately, easy to hit while turning the knob. They
carry mute (next to the volume knob) and play/pause on base:
things that are harmless to fire by accident. Never put a typing key there.

**Home-row mods, GACS** — `A`=GUI `S`=Alt `D`=Ctrl `F`=Shift, mirrored right.
This is what makes the daily chords layer-free: `Alt+hjkl` (nvim splits *and*
tmux panes, as one seamless space) is a left-hand hold plus a right-hand tap.

The `Ctrl+b` prefix — shared by tmux and herdr — is the exception, and it is
worth knowing why. `b` is a **left-half** key, so a left home-row Ctrl and `b`
are the same hand: the cross-hand guard refuses the hold and you get `db`.
Press it with either bottom-row corner Ctrl (`RCTRL` bottom-left, `LCTRL`
bottom-right — swapped on purpose), neither of which is a hold-tap. (The old `Ctrl+Space` prefix was reachable
from the home row precisely because Space is a right thumb; that property did
not survive the move to `Ctrl+b`.)

Two settings carry that: a **cross-hand guard** (`hold-trigger-key-positions`),
so a same-hand roll like `sd` types letters instead of firing Alt; and
`require-prior-idle-ms = 150`, so no mod can trigger mid-burst. Between them,
mods only happen when you meant them. If a mod still fires while typing fast,
raise `require-prior-idle-ms` before touching `tapping-term-ms`.

**`j`+`k` → Esc** as a hardware combo, not an nvim mapping — so it escapes in
nvim insert, in nvim-bash vi mode, in a bare `vi` on a locked-down box, and in
any TUI. Esc is also on its own key at the TKL position; the combo is the fast
one. Base layer only, 45ms window. **`h`+`j` → Enter** is the same shape one
key to the left, with the same guard and window.

**Thumbs, outside in:** left `GUI Shift Alt Space NAV`, right
`MEDIA Shift BSPC Space Enter`. Space is on **both** thumbs (nvim leader, most
pressed key). NAV is the left innermost key and MEDIA the right outermost, still
on opposite halves, so NAV + MEDIA still reaches ADJ. The both-Shift caps-word
combo follows the Shifts to second-from-outside. Both Spaces together send
`Ctrl+Space`.

**NAV keeps the TKL nav island as an island** — Ins/Home/PgUp over
Del/End/PgDn (PrtSc/ScrLk/Pause left out), three columns wide, in the three rightmost
columns. Same shape, same relative positions, so PgUp sits directly above PgDn
in the outermost column. Arrows are the TKL **inverted-T**, not hjkl: `hjkl` on
the base layer are already hjkl for vim, and this layer's arrows are for
everything that *isn't* vim — browsers, dialogs, spreadsheets — which is
exactly where the TKL shape is the one already in your fingers. NAV's **left
half is empty** (all transparent, encoder button included): the base home-row
mods show through, so `Ctrl+Shift+Left` is hold `D`+`F`, tap Left.

**NAV+Y** is tmux copy mode and **NAV+P** tmux paste — macros
that send the `Ctrl+Space` prefix then `[` / `]`; the rest of that row is
prefix + `k` / `j` / `z` — **U** previous window, **I** next window, **O**
zoom. **NAV+RET** reaches ADJ: it holds MEDIA rather than ADJ, because ZMK's
conditional layer switches ADJ off whenever NAV+MEDIA are not both active,
even if a key turned it on.

**MEDIA** is F1-F12 straight across the number row, in the same order and the
same place a TKL's function row sits above its number row. MEDIA is held on the
right outermost thumb, so the media keys are the two columns under F11/F12:
brightness up/down, volume up/down, prev/next, top to bottom. Mute is on `L`,
play/pause on `.`.

**Encoders** are per-layer: base = volume / page scroll, nav = word-wise cursor
/ tab cycling, media = volume / brightness.

`&studio_unlock` is on ADJ + `U`. Studio refuses every edit until it is pressed.

**Bootloader has a single-half escape hatch.** On NAV, pressing the two ends
of the left half's number row together (`` ` `` + `5`) puts the **left** half
into the bootloader; the same gesture on the right half's number row (`6` +
BSPC, its two ends) does the right. Both use a 50ms window, so they are not hittable by
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

`CONFIG_ZMK_RGB_UNDERGLOW_EXT_POWER` is **`n`**, which is not the default and
is what keeps the OLEDs alive -- see [Displays](#displays) below. The cost is
that the LED rail is never cut, so the strip's quiescent draw is always
flowing. That is the single biggest battery item on this board now, and it is
the price of having a display at all.

## Displays

Both halves have a 128x32 SSD1306. `CONFIG_ZMK_DISPLAY=y` in `sofle.conf`
turns them on and the layer names come from `display-name` on each layer in
`sofle.keymap`.

**What each half is allowed to show is decided by ZMK, not by taste.** Every
interesting widget is gated on being the *central* side of the split
(`app/src/display/widgets/Kconfig`: `depends on ZMK_SPLIT_ROLE_CENTRAL`),
because a peripheral never runs the keymap and therefore does not know the
layer, the active output, or the WPM:

| | LEFT (central) | RIGHT (peripheral) |
|---|---|---|
| layer name | yes | **no** |
| battery | yes | yes |
| output USB/BLE | yes | **no** |
| WPM | yes | **no** |
| split connection icon | no | yes |

So the right half has essentially nothing to say, which is why it gets the SD
wordmark instead:

```
LEFT  (central)      RIGHT (peripheral)
+--------------+     +--------------+
|OUT      BATT |     | SD      BATT |
|layer     wpm |     | __      conn |
+--------------+     +--------------+
```

### The module, and why it is in here rather than at the repo root

A logo needs a *custom status screen*, which means C compiled into the
firmware, which means this directory has to be a **Zephyr module**
(`zephyr/module.yml`, `CMakeLists.txt`, `Kconfig`).

ZMK's reusable workflow auto-detects a module only at the **repository root**
-- it literally tests `[ -e zephyr/module.yml ]` against `GITHUB_WORKSPACE`.
Taking that route would put a `zephyr/` directory and a `CMakeLists.txt` at
the top of a *dotfiles* repo for the keyboard's benefit, which is not a trade
worth making. It works from in here instead because `self.path: keyboard` in
`west.yml` already makes this the manifest repository, and the manifest repo
is a west project like any other, so Zephyr's module scan finds it with no
help from the workflow.

If that ever stops being true the failure is loud, not subtle: the link dies
on an undefined `zmk_display_status_screen`, because ZMK compiles no status
screen of its own once `STATUS_SCREEN_CUSTOM` is set. The fallback is a
`cmake-args: -DZMK_EXTRA_MODULES=...` entry per `build.yaml` target -- the
matrix's `cmake-args` are appended last to the `west build` line, so they win.

**`./Kconfig` is load-bearing and is the trap here.** The four status widgets,
the mono theme, the Montserrat fonts and the LVGL heap size are all properties
of `ZMK_DISPLAY_STATUS_SCREEN_BUILT_IN` in `zmk/app/src/display/Kconfig`. The
moment you pick `CUSTOM` you lose every one of them, and the build still
succeeds -- it just renders an empty screen. `Kconfig` puts them back.

The logo itself is `display/sd_logo.c`, an LVGL I1 bitmap generated by
`scripts/gen-logo` (Pillow + DejaVu Sans Bold) and committed, so a build needs
neither. Its format -- 8-byte palette, `ceil(w/8)` bytes a row, `data_size`
counting the palette -- is copied from ZMK's own `nice_view` art rather than
guessed, since every LVGL major version spells this differently.

Layer names are capped at **9 characters**. `layer_status.c` formats into a
`char text[14]` after a 3-byte LVGL keyboard glyph and a space, so longer
names are silently truncated by `snprintf`.

### The rail, and why the OLEDs were dark

The nice!nano's external power rail (P0.13) feeds the per-key LEDs **and** the
OLED. There is one rail; you cannot power one without the other.

With the stock `CONFIG_ZMK_RGB_UNDERGLOW_EXT_POWER=y`, the underglow driver
toggles that rail along with the LEDs, and combined with
`CONFIG_ZMK_RGB_UNDERGLOW_AUTO_OFF_IDLE=y` that is not a trade-off, it is a
deterministic failure:

1. Boot -- `ext_power_generic_init` enables the rail. OLEDs light.
2. 30 s idle (`CONFIG_ZMK_IDLE_TIMEOUT` default) -- the activity event calls
   `zmk_rgb_underglow_off()`, which calls `ext_power_disable()`. OLEDs dark.
3. Next keypress -- the wake path restores the LED state from *before* idling.
   That state is off, because `ON_START=n`, so it calls `off()` **again**. The
   rail is never re-enabled.

Net effect: the OLEDs die 30 seconds after every boot and never return. ZMK
separately has a standing bug where a display does not recover from an
ext-power cutoff at all ([zmk#674]), which is why its docs still call displays
a proof of concept.

Hence `CONFIG_ZMK_RGB_UNDERGLOW_EXT_POWER=n`. `AUTO_OFF_IDLE` still works --
it just blanks the pixels instead of cutting the rail.

**The rail's state is saved to flash and survives a reflash.** ZMK's docs are
explicit about it, which makes it the nastiest part of this: a board that ever
cut the rail comes up dark *no matter what firmware you give it*, because the
setting outlives the firmware that wrote it.

`display/ext_power_boot.c` removes that trap. It forces the rail on from the
top of `zmk_display_status_screen()`, which `main()` reaches immediately after
`settings_load()` has applied the stale value:

```
settings_subsys_init();
settings_load();      <- ext_power's commit handler may cut the rail here
zmk_display_init();   <- calls zmk_display_status_screen(), i.e. us
```

That is the first opportunity after the damage. A `SYS_INIT` would be too
early (every init level runs before `main()`), and a settings commit handler
of our own would race ZMK's on link order. It runs unconditionally rather than
checking the stored state, so the dark-OLED state cannot be re-entered.

**One caveat on the first boot after flashing.** The SSD1306's own init
sequence runs in the Zephyr driver at `POST_KERNEL`, before `main()`. If the
rail is cut during `settings_load` the panel loses that init and ZMK has no
re-init path ([zmk#674]) -- re-powering it microseconds later may or may not
beat the brown-out. It stops mattering after that: `ext_power_enable()` queues
the state back to flash, so once the board has been up for
`CONFIG_ZMK_SETTINGS_SAVE_DEBOUNCE` (60 s) the saved state is ON,
`settings_load` stops cutting the rail, and every later boot has continuous
power from `POST_KERNEL` onward. **So if the OLEDs are dark on the first boot
after flashing, leave it powered a minute and power-cycle once.**

**ADJ + EPTOG** (`&ext_power EP_TOG`, on `P`, next to `OUT`) is still bound as
a manual switch for killing the LED rail within a session. It no longer
survives a reboot -- the boot hook wins, by design.

[zmk#674]: https://github.com/zmkfirmware/zmk/issues/674

## Printable diagrams

```
keymap.svg   vector — print this (a real A4 page: Print at 100%, no scaling)
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

Every key on every layer but base carries, in its **bottom-left corner and
muted, the legend base has in that slot**. A layer sheet is a picture of the
same keys, and a held-layer legend tells you what a key *does* there, not which
key it is — on NAV most of the board is `▽` transparent, which tells you
neither. So: read the middle for the layer, read the corner to find the key
under your finger. Bottom-left is the one free corner (shifted goes
top-centre, hold bottom-centre, and no layer but base has holds anyway); the
generator stamps it, the config styles it.

**Combo boxes are sized per combo**, and their legends stack the way a key's
do — shifted above, tap below. keymap-drawer gives every box one size, which
has to be wide enough for the longest legend (`CAPSWRD`) and is then far too
wide for `[`, and both of the things that looked wrong came out of that single
size: an oversized box covered a neighbouring key's legend (`/` + the
bottom-right corner sat on that corner's `RCTRL`), while a box short enough
not to collide vertically had its own two legends collide instead (`=` over
`+` rendered as a `±` blob). So each box gets its own width, and loses the top
row when it has no shifted face. The widest box that sits between two keys now
reaches 18px into them, and the closest a key legend gets to that boundary is
14px — the worst key on the board, a 5-character 14px legend centred one
key-pitch away — so nothing overlaps anything.

The trap underneath it: keymap-drawer draws the box **rect** from the
per-combo size but places the legends inside it from the **config** `combo_h`.
Leave `combo_h` at the stock 26 and hand out a taller box and the shifted face
keeps 26's offset, landing on the tap. The two have to agree, so `combo_h` is
the two-legend height and the generator only ever shrinks below it.

Two things `keymap-drawer.yaml` has to handle in the **renderers**, both the
same shape — a CSS property Chrome implements and librsvg (which makes the
PNG) does not:

- `paint-order`, used to put a fat white halo *behind* layer headers and the
  footer. librsvg paints that 4px white stroke straight *over* the glyphs, so
  the text comes out invisible or as a blob. The config drops the stroke,
  which costs nothing because both sit in clear space. The footer was
  invisible in every PNG this script ever produced, because the original
  workaround named only `text.label`.
- `dominant-baseline`, which is how keymap-drawer centres a tap legend
  (`middle`) and hangs a shifted one off the key's top edge (`hanging`).
  librsvg ignores the property **outright** — measured: `middle`, `hanging`,
  `central` and `auto` all land on the plain alphabetic baseline — so tap
  legends drew a few px high and the top legends drew **entirely above the
  key**. That is the text-outside-the-box the PNG used to show. There is no
  renderer-neutral CSS for it, so the config pins every legend to the
  alphabetic baseline and `gen-keymap-art` redoes the vertical placement with
  `dy` (universally supported), hung on the first `<tspan>` when there is one:
  librsvg applies a `dy` on the parent `<text>` once *per* tspan where
  browsers apply it once, so a parent `dy` would reintroduce the same split on
  a two-line legend. It bails if keymap-drawer stops emitting those baselines
  — that would mean it fixed this itself and the offsets now double up.

`key_h` is also load-bearing: for a `zmk_keyboard:` layout it is the whole
scale (keys come out square, `key_w` is ignored), and the stock value left a
52px key — narrower than a 7-character legend at the 14px tap font, which is
why `CAPSWRD`/`PSCRN` used to spill over the edges. The footer is one
right-aligned line that keymap-drawer neither wraps nor measures, so the
generator checks it fits the sheet.

Two more maps, on the parse side. `raw_binding_map` handles bare ZMK behaviors
that would otherwise print as devicetree node names (`&studio_unlock` ->
`UNLOCK`). And `zmk_keycode_map` spells out the **shifted faces** —
keymap-drawer knows the shifted keycodes (`&kp LBRC` is `{`) but not that an
unshifted one also has a second legend, so `&kp COMMA` is just `,` to it until
told otherwise. **Add to both maps when you add a macro or a punctuation key.**

**Knobs.** keymap-drawer does not draw encoders, so `gen-keymap-art` does:
each layer's `sensor-bindings` becomes a small ↻ clockwise / ↺ counter-clockwise
pair above that knob's push-button, in words from `KNOB_WORDS` in the script
(a keycode missing from that table prints raw — add it). The text sits in the
empty column between the halves, and `check_knob_width` refuses a line too
wide for it — there is nothing to clip against, so an overlong one silently
prints across the neighbouring key's legend. `keymap.txt` lists them per layer
too.

**Folded layers.** A layer whose keys are all transparent and whose only real
content is its knobs gets no sheet of its own: `FOLDED` in the script names
it, and its knob pair is drawn under the base layer's in a muted style,
prefixed with the key you hold for it (`ALT ↻ NEXT WIN`). The `alt-tab` layer
is the case this exists for. A page of transparent glyphs carrying two lines
of knob text is both clutter and — see below — a fifth of the page budget.

**A4.** The sheet is a page, not an image. `fit_a4` sets the SVG's size in
**millimetres**, which is what makes the user unit a physical length: the
result is an A4 portrait page with a 10mm margin and the content centred in
it, so printing is Print-at-100% rather than a scaling dialog. (Bare user
units are why it used to come out as a narrow strip down the middle of the
paper.) Four layers at 1180×1828 is slightly taller than A4's proportions, so
the print is height-limited and the 14px legends land at **6.0pt** — small,
but a reference you read at arm's length rather than body text.
`outer_pad_h` in `keymap-drawer.yaml` is the lever that bought the last 10% of
that, and `fit_a4` asserts the result stays above `MIN_LEGEND_PT` (5.8), so a
new full-size layer fails the build instead of quietly making the sheet
unreadable. If that ever fires, the honest fix is a second sheet: two layers
on an A4 landscape page get to ~7.4pt.

## Bumping ZMK

Pick a `zmkfirmware/zmk` commit, put it in **both** `west.yml`
(`revision`) and `.github/workflows/zmk-sofle.yml` (the `uses:` ref), build,
flash both halves. Pinned rather than floating `main` for the same reason the
bat themes and fzf-git installs are pinned: the firmware you flash should be
the firmware you tested.
