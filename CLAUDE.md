# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for Neovim, tmux, bash, git, and Sublime Text — focused on
VLSI/SystemVerilog development. Also carries a ZMK keyboard config
(`keyboard/sofle/`), which is built by CI rather than symlinked.
`install.sh` creates the necessary symlinks:

```
nvim/               → ~/.config/nvim
vim/.vimrc          → ~/.vimrc
tmux/.tmux.conf     → ~/.tmux.conf
tmux/scripts/       → ~/.config/tmux/scripts
lazygit/config.yml  → ~/.config/lazygit/config.yml
sublime/            → ~/.config/sublime-text/Packages/User  (ST3 dir if that's what exists)
```

## Installation

```bash
./install.sh                             # symlink all configs
bash installers/install-linux-tools.sh   # tools for standard Linux
bash installers/install-termux-tools.sh  # tools for Termux (Android)
```

## Config principle: graceful degradation

These dotfiles land on many machines (Linux workstations, ETX/SLES, Termux,
codespaces) where fancy tools may be missing or uninstallable. **Whenever a
config replaces or upgrades a base tool's behavior — now or for any future
tool — the base behavior must still work when the upgrade is absent.** Guard
the upgrade with a runtime check (`command -v X … || <stock fallback>`) instead
of assuming X exists; a missing optional tool must never break the underlying
command. Existing examples: delta's `core.pager`/`diffFilter` fall back to
plain less/cat (`git/delta.gitconfig`), bat themes fall back to built-ins,
image.nvim picks a backend per machine and no-ops on dumb terminals,
`nvim-clip` only activates when xclip/xsel/wl-copy are absent.

## Neovim architecture

Entry point: `nvim/init.lua` → `somya.core` + `somya.lazy`

- `nvim/lua/somya/core/` — options, keymaps (leader = `<Space>`)
- `nvim/lua/somya/core/navmsg.lua` — the shared "you are here" counter echoed
  after a list jump, modelled on gitsigns' own `Hunk 1 of 5`. All three
  navigation pairs speak in one voice, each labelled by **what** it landed on
  and coloured to match: `]d`/`[d` → `Warn 2 of 7` (severity name, severity
  colour), `]h`/`[h` → `Change 1 of 5` (hunk type, GitSigns colour), `]t`/`[t`
  → `TODO 3 of 4` (keyword, its Todo colour). `M.echo(label, index, total, hl)`
  is the whole API; callers compute their own index (each list has its own
  order) and pass `nil` when the landing spot can't be located, so a miss stays
  silent instead of printing a wrong number. Suppressed by `shortmess+=S` —
  gitsigns' own opt-out, so one setting silences every counter. Each caller
  computes the index over exactly the set its jump walked: diagnostics sort
  `vim.diagnostic.get()` by position (it only sorts per namespace) and match on
  fields since `get()` returns deepcopies; hunks come from `gitsigns.get_hunks`
  via `nav_hunk`'s async callback with `navigation_message = false` suppressing
  gitsigns' own uncoloured message; todos re-scan the buffer with
  todo-comments' own matcher (its pickers shell out to ripgrep, which answers a
  workspace question, not "where am I in this file") — passing a real bufnr,
  never `0`, since its `is_comment` looks the buffer up in
  `treesitter.highlighter.active[buf]` and a `0` silently matches nothing.
  `]d`/`[d` also moved off the deprecated `vim.diagnostic.goto_next/prev`
  (removal in 0.13, and their `float=true` default tripped a second
  deprecation) onto `vim.diagnostic.jump`, which returns the diagnostic it
  landed on; the float those two used to open is now configured once as
  `jump.on_jump` in `lspconfig.lua`, where `scope = "cursor"` is load-bearing —
  `open_float` derives `focus_id` from the scope and the `SdDiag*` alert
  styling only fires for `line`/`cursor`/`buffer`. `]h`/`[h` likewise moved off
  gitsigns' deprecated `next_hunk`/`prev_hunk` onto `nav_hunk`. All three
  honour a count (`3]d`).
- `nvim/lua/somya/core/abbreviations.lua` — insert-mode `:iabbrev`s for notes +
  SV. Three groups, each shaped so they never expand against you: global **prose
  typo fixes** (`teh→the`, …; safe because triggers are misspellings), global
  **`x`-prefixed conveniences** (`xdate`/`xtime`/`xnow` via `<expr>`,
  `xtodo`/`xfix`/`xnote` markers, `xsig`/`xmail`; the `x` shape rarely collides),
  and **SV keyword typo fixes** (`lgoic→logic`, …) kept **buffer-local** to
  `.sv`/`.svh` via a `FileType systemverilog` autocmd so they can't fire in
  prose. Structural SV constructs stay in the LuaSnip sets — this file only
  covers inline keywords + typos.
- `nvim/lua/somya/plugins/dashboard.lua` — alpha-nvim start screen ("SD-NVIM",
  *nvim for Chip Design*) shown on `nvim` with no file args. Buttons run real
  actions (find/grep/explorer/`:Cheatsheet`/`:QfHelp`/Lazy) and display the
  matching `<leader>` keymap, so it doubles as onboarding. It also shows a
  date/time line and a machine-info line (`user@host | OS arch | cores RAM
  | nvim ver`), computed at startup and refreshed once on `User VeryLazy`.
  Both render in a colored "box" (dark text on an accent bg) — the box uses the
  table-form hl (`{{group,0,-1}}`) so alpha offsets it by the centering pad and
  the pill hugs the text instead of painting from the left edge. Every draw
  (`FileType alpha`) re-rolls three things from catppuccin palettes: the box
  accent (also tints subheader/footer), the whole-window background (applied via
  window-local `winhighlight`, cleared on `BufWinLeave`/`BufHidden` so it never
  leaks into files), and a 6-color slice of a color ring for the SD-NVIM
  gradient art — so each launch looks different. `cheatsheet.lua`
  exposes `:Cheatsheet` / `:QfHelp` commands for the buttons.
- `nvim/lua/somya/plugins/which-key.lua` — names every `<leader>` prefix that fans
  out into multiple keys via `opts.spec` (e.g. `c → +Cursor`, `t → +Terminal`), so
  the popup labels groups instead of showing a bare count. Add a row when a new
  prefix grows a second binding.
- `nvim/lua/somya/plugins/bufferline.lua` — the buffer tabline. Its `name_formatter`
  exists because bufferline's own truncation keeps the **head** of a name, which is
  the useless half in a big SV project where every file is `<ProjectTag><Module>.sv`
  (`MyProjectM..`). `shorten()` strips the longest basename prefix **shared by all
  listed buffers** (cached, invalidated on `BufAdd`/`BufDelete`/`BufFilePost`/
  `TabEnter`, since it runs per buffer per tabline redraw; scope.nvim unlists
  out-of-tab buffers so it follows the tab's own set), then left-cuts anything still
  over `MAX_NAME` — either way the distinguishing tail survives: `…ModuleLRU.sv`.
  `truncate_names = false` + `max_name_length = MAX_NAME` keep bufferline from
  re-cutting the head off the result.
- `nvim/lua/somya/lazy.lua` — bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim);
  imports `somya.plugins`, `somya.plugins.lsp`, and `somya.plugins.colorschemes`
  (subdirs need their own import entry — they aren't auto-recursed)
- `nvim/lua/somya/plugins/` — one file per plugin, each returns a lazy spec table
- `nvim/lua/somya/plugins/lsp/` — `mason.lua` (installer) + `lspconfig.lua`
  (server config via `vim.lsp.config()` API, nvim-lspconfig 0.11+)
- `nvim/lua/somya/plugins/colorschemes/` — one file per colorscheme plugin
  (`tokyonight.lua`, `catppuccin.lua`, `monokai-pro.lua`, `material.lua`,
  `kanagawa.lua`, `cyberdream.lua`, `vim-monokai.lua`); the
  switching/orchestration logic lives in `core/theme.lua` (see below)

**Theme / colorscheme management** (`nvim/lua/somya/core/theme.lua` is the single
source of truth): the colorscheme *plugins* live in `plugins/colorschemes/` —
tokyonight (`tokyonight.lua`, customized via `on_colors` + hl overrides) and
catppuccin (`catppuccin.lua`, also a palette source for hl overrides elsewhere)
load eagerly; monokai-pro, material (`material.lua`), kanagawa, cyberdream, and
vim-monokai are lazy, loaded as styler dependencies. The many scheme *names* you
see in `:Telescope colorscheme` (tokyonight-storm/moon, catppuccin-frappe/latte/…,
monokai-pro-spectrum, kanagawa-wave/dragon/lotus) are built-in **variants** of
those plugins, not separate files — except material and cyberdream, which each
have one name (`material` / `cyberdream`; variant set via `vim.g.material_style`
and cyberdream's `variant` opt), and vim-monokai, a classic Vimscript scheme with
the single name `monokai` (no setup()).
`theme.lua` holds `M.default` (the startup
colorscheme — `tokyonight.lua` loads it via `require`; edit this one line to
change the default) and `M.styler_themes` (the per-filetype table). styler.nvim
*overrides* the global scheme **per filetype, window-locally** (sv→monokai,
python→catppuccin, …) and starts **ON**: `plugins/styler.lua` calls
`theme.enable_styler()` when the plugin loads (VeryLazy), so per-filetype themes
apply by default — `:colorscheme X` changes the file explorer but not a pinned
`.sv`/`.py` buffer. Toggle with `<leader>uy` / `:StylerToggle` (off = reset every
window's hl namespace to 0 + drop styler's autocmds; on = `setup()`, which
re-pins all open windows). For a true full-window preview, styler must be off:
`<leader>uc` / `:ThemeBrowse` opens the picker with `enable_preview`, suspending
styler first if it's on (re-enable with `<leader>uy` after picking). The
`<leader>u` prefix is "+UI / Theme".

**Italics** (`core/theme.lua`, "Italics" section): italics in a terminal are a
rendering question, not a taste one — a font with no real italic face makes the
emulator fake the slant, which overhangs the character cell and gets clipped
when the neighbouring cell repaints (comment/keyword tails look cut off and
flicker as the cursor moves). **There is deliberately no auto-detection**:
terminfo's `sitm` — the only signal reachable from inside nvim — describes the
TERMINAL, not the FONT, and VTE/GNOME Terminal advertises it and then
synthesises the slant anyway, so a probe answers "supported" on exactly the
machines where italics are unreadable. It's a look-and-decide call:
`<leader>ui` / `:ItalicsToggle` strips the italic attribute from ns 0 and every
styler namespace (turning italics back ON reloads the scheme and re-pins styler,
since stripping destroyed the originals) and remembers the answer per machine in
`stdpath("state")/sd-italics` — never committed, same philosophy as
`~/.vimrc.local` — so it survives restarts. `M.italics` (default `false`) is
only the fallback for a machine that has never been told; `M.italic_keep`
exempts groups where italic is the content (empty by default). The shell-side
`italic-check` alias prints an upright/italic pair to judge by eye.

**Completion & snippets** (`nvim/lua/somya/plugins/nvim-cmp.lua`): nvim-cmp with
LuaSnip as the snippet engine. `<Tab>`/`<S-Tab>` expand a snippet or jump between
placeholders (falling back to cmp menu nav); `<C-j>`/`<C-k>` move the menu. Two
snippet sources load: `friendly-snippets` (VSCode JSON, via `from_vscode`) and our
own Lua snippets (via `from_lua`, pointed at two roots under
`stdpath("config")/snippets` — `nvim/` is symlinked to `~/.config/nvim`). The Lua
loader is a snipmate-style collection: every `.lua` file in a folder named after the
filetype is loaded, so it's **one snippet per file**. The SystemVerilog set is split
into two collections by synthesizability — `nvim/snippets/sv-design/systemverilog/`
(synthesizable: module, interface, package, function, case, if, for, foreach, begin,
always_ff `aff`/`affs`, `acomb`, `fsm`, `tenum`/`tstruct`, `genfor`) and
`nvim/snippets/sv-tb/systemverilog/` (verification/non-synth: class, uvmclass, task,
constraint, covergroup, comment_box `///`, initial, fork, `assertp`, clocking,
`uvmobj`, `uvmseq`). Both map to the `systemverilog` filetype, so the split is
organizational — **all** snippets are available in any `.sv`/`.svh` buffer.
Files use LuaSnip's `snip_env` globals (`s`, `i`,
`d`, `sn`, `fmt`, `rep`, …) directly — no requires. Snippets are written with `fmt`
(literal `{` `}` escaped as `{{` `}}`); module/class/uvm names default to the file
name via a dynamic node (`d(1, function() return sn(nil, i(1, fname())) end)`).

**Terminal** (`nvim/lua/somya/plugins/toggleterm.lua`): toggleterm.nvim under the
`<leader>t` prefix — `tt` toggle (last used, defaults to float), `tf` float, `th`
bottom/horizontal, `tv` vertical, `ta` toggle-all. Each variant uses a distinct count
so they're independent terminals. (Tab management lives at the `<leader>T` prefix in
`core/keymaps.lua`.) Terminal windows get a distinct catppuccin-based
background (default mint/teal) so they stand out against the navy editor — applied
window-locally (and re-applied on `ColorScheme`, so it survives styler.nvim's
colorscheme-reload cycle) without leaking into normal buffers. `<leader>tc` cycles
through the dark, catppuccin-accented schemes in the `schemes` table: `mint` (Teal,
default), `espresso` (Peach), `purple` (Mauve), `rose` (Pink), `lavender`, `maroon`,
`gold` (Yellow); cycling recolors open terminals live and updates the config so new
terminals follow suit. In terminal mode `jk`
exits to normal, `<C-h/j/k/l>` navigate windows; `<esc>` is left alone so TUI apps work.

**Note-taking** (`nvim/lua/somya/plugins/telekasten.lua`): telekasten.nvim over a
single local vault at `~/.somyadashora/sd-notes` (a **local** git repo — never
pushed, so notes stay per-machine; commits are manual). The vault is bootstrapped
on first use (`ensure_repo`: `mkdir -p` the vault + `daily`/`weekly`/`templates`
subdirs — pre-creating them stops telekasten's "create folder?" prompt — +
`git init` + write `notes.md` and `templates/weekly.md` if absent), so no manual
setup. **Templates** live in `vault/templates/`; `Zw` fills
`templates/weekly.md` (`template_new_weekly`) with telekasten's
`{{placeholders}}` ({{title}}, {{week}}, {{year}}, {{monday}}…{{sunday}}, …) for
a new week's note. Bootstrap writes a template only when the file is missing, so
per-machine edits are never overwritten; add more (e.g. `daily.md` +
`template_new_daily`) the same way. All maps live under the `<leader>Z` ("+Notes") prefix. The
headline pair is a jump-to-notes-tab / jump-back: `<leader>Zz` opens (or switches
to) a dedicated **notes tab** — a new tab tagged with a tab-local `vim.t.is_notes_tab`
flag plus a tab-local `name` var set to the vault's base dir name (**"sd-notes"**,
via `fnamemodify(home, ":t")` — same convention as `:TabProject` tabs) — bufferline's
right-side tabpage indicator renders that `name` var in place of the tab number, so
the notes tab shows "sd-notes" there (Neovim tabs have no native name)), `tcd`-scoped to the
vault, opening `notes.md`; `<leader>Zr` returns to the tab you
came from (remembered tabpage handle). The rest are telekasten actions — `Zf` find,
`Zs` search/grep, `Zn` new, `Zd` today's daily, `Zw` this week's weekly, `Zl`/`Zk`
insert/follow link, `Zb` backlinks, `Zc` toggle calendar (calendar-vim dep; in the
calendar `<CR>` opens that day's daily note, ←/→ month, ↑/↓ year, `t`/`r`/`q`
today/redisplay/close), `Zp` panel — plus `Z?`, a help popup that reuses the
cheatsheet float renderer (`somya.cheatsheet` now `return`s `{ open, open_grid }`
so other modules can render help with the same look).

**Markdown rendering** (`nvim/lua/somya/plugins/render-markdown.lua`):
render-markdown.nvim renders Markdown in-buffer as virtual text (heading pills,
bullet glyphs, code-block backgrounds, aligned tables, checkboxes, callouts) —
the file itself is never modified, and the cursor's line un-renders to raw
source for editing. Lazy-loaded on `ft = markdown`, depends on treesitter's
`markdown`/`markdown_inline` parsers + nvim-web-devicons. Starts **on**
(`enabled = true`) for every markdown buffer; `<leader>um` toggles rendering
(under the `<leader>u` "+UI / Theme" group). Pairs with the telekasten vault.

**Mermaid diagrams / inline images** (`nvim/lua/somya/plugins/image.lua` +
`diagram.lua`): image.nvim draws markdown image links as real pictures over the
buffer, and diagram.nvim feeds it rendered ```` ```mermaid ```` fences (plus
plantuml/d2/gnuplot when those CLIs exist). Chosen over snacks.image for the
**ueberzugpp backend**: an X11 overlay that works in ANY terminal with a
`$DISPLAY` (ETX/SLES) — no kitty required. `image.lua`'s `pick_backend()`
chooses per machine: kitty protocol on kitty/ghostty, else `ueberzug` when
`ueberzugpp` is on PATH, else kitty escapes (harmless no-op). The buffer is
never modified — render-markdown styles the text, these draw the pictures.
Mermaid theme follows `'background'`. Runtime deps (none installed by the
installers): ImageMagick CLI (`processor = "magick_cli"`, `build = false`
skips the luarocks magick rock), `ueberzugpp` for the X11 path, `mmdc`
(`npm i -g @mermaid-js/mermaid-cli`) for mermaid, curl for remote images.
The kitty path inside tmux needs `allow-passthrough on` + `focus-events on`
(set in `.tmux.conf`, `-q`-guarded for tmux <3.3); ueberzugpp needs neither.

**Bookmarks** (`nvim/lua/somya/plugins/bookmarks.lua`): bookmarks.nvim
(LintaoAmons) — **persistent**, SQLite-backed bookmarks that survive across
sessions, carry names/descriptions, group into named lists, and are browsable via
Telescope (`picker_backend = "telescope"`), a tree view, or grep. A richer
complement to the ephemeral `'a`-style marks from marks.nvim. **All maps live under
`<leader>m` ("+Bookmarks")** — that's Space-then-m, a different namespace from the
bare `m` prefix marks.nvim owns (whose recommended `mm/mo/ma/md` would collide with
bare marks), so the two never conflict: `mm` mark/rename, `mo` goto (picker), `md`
describe, `mc` command palette (exposes every action — the fallback if a command
name drifts between versions), `mt` tree, `ml`/`mn` select/new list, `ms` grep
bookmarked files, `mi` info, `m]`/`m[` next/prev, `mv` toggle the bookmark visuals
over code, `m?` help popup (reuses the cheatsheet float renderer). (The multi-cursor
plugin vim-visual-multi moved to `<leader>M` in the same swap.) The gutter mark, its full-line background,
and the tree's list icons are all catppuccin **Mauve** (`#cba6f7` — the repo's neon
purple) so a bookmark never blends with diagnostic/git/todo signs; these hls
re-apply on `ColorScheme` (styler reloads schemes per filetype). The **tree
side-panel** (`mt`) is styled window-locally on `BufWinEnter` (not `FileType` — the
plugin sets the ft before the buffer is windowed, so `FileType`'s current window is
still the code buffer): its gutter is dropped (`BookmarksTree` added to statuscol's
`ft_ignore`, plus signcolumn/fold/number off), it gets a mauve-tinted lifted
background via `winhighlight` (contained — `NormalNC` keeps it lit from the code
window, and it can't leak since the tree buffer is wipe-on-close), and content is
colored by row type via disjoint `\zs` `matchadd` patterns (mauve icons, lavender
list names, muted order numbers, bright bookmark text; a negative-lookahead skips
the active row so the plugin's own **active-list** hl — `treeview.highlights.active_list`,
set to mauve-bold on a bar — shows through). The tree also gets a custom **`K`** key
(via `treeview.keymap`, deep-merged so the defaults stay) that shows the bookmark's
**description** in a markdown hover float — the built-in `i` only lists metadata, and
descriptions (added with `md`) aren't otherwise visible in the tree. `mv` toggles the sign/line-bg/inline-desc visuals by swapping the
sign module's refresh fn (the plugin redraws signs on Win/Buf/InsertLeave, so a
one-shot clean won't stick) — the DB is untouched, so bookmarks/lists persist while
hidden. To keep
bookmarks.nvim the single "bookmark" concept, **marks.nvim's own overlapping
numbered-bookmark feature (`m0`-`m9`, `m}`/`m{`, `dm=`, annotate) is disabled** in
`marks.lua` via its `mappings` table (regular letter marks stay). The SQLite DB sits
per-machine at `stdpath("data")/bookmarks.sqlite.db` (never pushed — same philosophy
as the telekasten vault); back it up before a major-version upgrade (spec pins
`^4.0.0`). Requires `kkharji/sqlite.lua` + the system `libsqlite3` at runtime.

**Indent guides & chunk brackets** — three renderers draw in the indent
columns, each with one job. `indent-blankline.nvim` (`indent-blankline.lua`)
draws a dim `┊` at EVERY indent level. `hlchunk.nvim` (`hlchunk.lua`) brackets
the block the cursor is in — `╭─` on the opening line, `│` down the side, `╰─`
on the closing one — so `end` / `endmodule` is visibly paired with what opened
it. `mini.indentscope` (`mini-indentscope.lua`) draws a `┊` for the current
indent scope and owns the `[i`/`]i` motions + `ii`/`ai` text objects.

The last two answer the same question at different columns, so they **take
turns instead of stacking**: the chunk bracket is ON by default and sets
`vim.g.miniindentscope_disable`; `<leader>uk` / `:ChunkToggle` swaps them
(mini checks that flag only in its drawing path, so `[i`/`]i`/`ii`/`ai` keep
working either way). Both wear catppuccin **Lavender** `#b4befe` — one
indicator identity, two shapes. hlchunk's `ic` text object is "inner chunk"
(`vic`, `dic`), the treesitter-block counterpart to `ii`'s indent block.

Only hlchunk's `chunk` module is enabled — its `indent`/`line_num`/`blank`
modules would duplicate indent-blankline. Two things about it are load-bearing
for this repo: it finds the chunk via **treesitter** (its non-treesitter
fallback is `searchpair("{", "", "}")`, which cannot see `begin`/`end` or
`module`/`endmodule`, so on a host where parsers can't be built it silently
draws nothing and `notify = false` keeps that quiet — the degradation), and its
node-type table had to be **taught SystemVerilog**. hlchunk's built-in
fallback patterns (`^func`, `^if`, `class`, …) are written for brace languages
and miss `module_declaration`, `seq_block`, `always_construct`,
`conditional_statement` and `case_statement` outright. `hlchunk.lua` registers
a real node table (names taken from the pinned gmlarumbe grammar's
`src/node-types.json`) under **both** the `systemverilog` and `verilog`
filetypes, since one grammar serves both. Note the semantics flip once a
filetype has a table: matching becomes **exact, with no regex fallback**, so a
construct left out of the list simply gets no bracket. Adding a language is the
same move. `error_sign` is deliberately off — a tier-2 grammar's parse errors
(UVM macro soup parses badly and is legal) are not authoritative when
slang/verible already report real syntax errors as diagnostics.

**Motions** (`nvim/lua/somya/plugins/sneak.lua`): vim-sneak. `f/F/t/T` are
remapped to `<Plug>Sneak_f`/… (n/x/o) so they — and `;`/`,` repeats — work
across lines instead of stopping at the current one. The 2-char `s{ab}`/`S{ab}`
sneak comes along, with mode-specific keys matching sneak's defaults to dodge
nvim-surround: visual backward is `Z` (visual `S` stays surround), operator-
pending is `z`/`Z` (`ds`/`cs`/`ys` untouched). Native `s` ≡ `cl`. All maps are
lazy.nvim `keys` triggers, so behavior is identical before/after plugin load.
The highlight groups live in `core/theme.lua`'s `M.overrides_common` (sneak's
own colors are `highlight default`, so ours always win): Sneak/SneakCurrent
reuse the Search/CurSearch catppuccin family (muted yellow / peach), and
SneakLabel (+LabelMask) is catppuccin mauve `#cba6f7` — the repo accent —
applied to every scheme + styler namespace like the search overrides.

**Yank history** (`nvim/lua/somya/plugins/yanky.lua`): yanky.nvim — a
persistent kill-ring so an overwritten unnamed register is never lost (chosen
over yankbank-nvim for ring-cycling + the Telescope picker). `y` routes through
`<Plug>(YankyYank)` (also keeps the cursor in place), `p/P/gp/gP` become
ring-aware puts, and **immediately after a put** `[y`/`]y` swap the pasted text
for the previous/next ring entry in place (yanky's default `<c-p>/<c-n>` cycle
keys are avoided — `<C-n>` belongs to vim-visual-multi). `<leader>y` opens the
ring in Telescope (`<CR>` put, `<c-x>` delete entry; custom mappings, since the
extension's defaults bind `<c-k>` and would clobber this config's `<C-j>/<C-k>`
menu nav). Ring persists via shada; system-clipboard copies sync into it.
Yanky's `on_yank` flash is off (the `TextYankPost` autocmd in `core/autocmds.lua`
already flashes) — only its `on_put` flash is kept. All maps are lazy `keys`
triggers.

**SystemVerilog LSP**: two servers are configured — `verible` (Mason-installed) and
`slang-server` (`~/.local/bin/slang-server`). Only one should be active at a time;
switch with `:UseVerible` / `:UseSlang`.

**LSP keymaps** (set on `LspAttach` in `lsp/lspconfig.lua`): generic actions — usable
with any server — live under the `<leader>v` ("LSP / Code") group: `va` code action,
`vr` smart rename, `vi` active-client info, `vR` restart. Navigation stays on `g*`
— but **only `gd` (definitions) and `gR` (references)**, the two methods both SV
servers actually implement. `gD`/`gi`/`gt` are deliberately NOT mapped: neither
slang-server nor verible advertises declaration/implementation/typeDefinition, so
mapping them would shadow the native `gD` (global-declaration search), `gi`
(insert at last insert) and `gt` (next tab) motions just to raise "no client
supports". Neovim 0.11+ already ships `gri`/`grt`/`grn`/`gra`/`grr`/`gO` as
built-in LSP defaults for servers that do support them (lua_ls), and glance's
`gli`/`glt` peek the same things. Plus `K` hover, `<leader>d`/`D` and `[d`/`]d`
diagnostics. Server-specific
maps are guarded by client name: the slang-only maps attach only when `slang-server`
is the client, so they appear/disappear as you `:UseSlang` / `:UseVerible` (which
re-attach the buffer). Those are the cone traces (`<leader>vd` drivers / `vl` loads,
via LSP call-hierarchy) plus four **design queries** built on slang's
`workspace/executeCommand` entry points: `vm` instances of the module under the
cursor (hier paths → Trouble), `vp` yank the hierarchical path of the instance under
the cursor (for waveform search / config_db / plusargs), `vs` browse an elaborated
scope (ports/params/nets with types and **resolved** param values), `vx` expand this
file's macros into a side-by-side scratch buffer. All five render through one
`qf_open` helper (setqflist → `Trouble qflist open`). **slang's command argument
shapes are undocumented and inconsistent** — `getInstancesOfModule`/`getScope` take a
bare string, `getInstances` takes TextDocumentPosition params, and `expandMacros`
takes plain filesystem paths (a `file://` URI fails); the shapes were verified by
probing the server over stdio and are recorded in a comment above `slang_cmd`.

**Surface identities** (chrome groups in `theme.lua`'s `overrides_common`, so
they hold on every scheme + styler namespace): generic floats/panels =
**mint/teal** (NormalFloat, matching the terminal); `K` hover = **"ember"**
dark coffee bg, warm ivory text, glowing gold border + solid gold
" 󰋗 hover " title pill (`SdHover*` groups, stamped
onto hover floats by a one-time `vim.lsp.util.open_floating_preview` wrapper
in `lspconfig.lua` keyed on hover `focus_id`s — stock K and the slang macro K
both pass through it; signature/which-key floats keep teal); diagnostic floats
(`<leader>d`, the auto-float after `]d`/`[d`) = **"alert"** — near-black plum
bg + rounded border and solid title pill tinted by the float's worst severity
(`SdDiag*`, same wrapper, keyed on the scope `focus_id`s vim.diagnostic uses);
glance peek = **"dune"** amber (see Peek below); gitsigns popups (`preview_hunk`,
`blame_line`) = **"neon"** noice.nvim-inspired electric-cyan rounded border +
solid neon title pill (`SdGitPopup*`, applied by a `gitsigns.popup.create`
wrap in `gitsigns.lua`) with neon green/red diff rows. Surfaces also restyle
their **content**, not just the frame: `theme.pin_surface(win, surface)` loads
a real non-pastel colorscheme (`M.surface_schemes`: glance →
`monokai-pro-ristretto`, hover → `kanagawa-dragon` as a no-teal/no-pastel
base, re-accented VIVID WARM — red/orange/gold/green syntax — by
`M.surface_overrides.hover`; a `capture_backfill` step copies concrete attrs
into the ns for common `@`-captures the scheme leaves to nvim's global default
links, which would otherwise leak the pastel editor colors)
into a cached window-local namespace via styler's loader and marks the window
`w.sd_surface`
— styler's `set_theme`/`clear` are guarded (in `enable_styler`) to skip such
windows, since its per-filetype repinning would otherwise snap the peek/hover
back to the pastel schemes. Degrades gracefully without styler (chrome-only).
Diagnostic colors (base/sign/floating/virtual-text/undercurl) and gitsigns
hunk colors are likewise forced to one saturated Monokai accent set — red
`#ff6188` / amber `#ffd866` / cyan `#78dce8` / green `#a9dc76` — on every
scheme, replacing the washed-out per-scheme pastels.

**Peek** (`nvim/lua/somya/plugins/glance.lua`): glance.nvim — VSCode-style
embedded preview under the `gl` prefix ("gl-ance"; `gld`/`glr`/`gli`/`glt` =
peek definitions/references/implementations/type-defs; in the peek: `<Tab>` next
location, `<CR>` jump, `<C-g>` hop between list and preview text (the editable
real buffer; glance's `<leader>l` default is removed — it shadowed the
Lint/LazyGit prefix), `q` close). `gp`/`gP` were deliberately avoided — yanky
owns both as ring-aware puts. Division of labor: `K` hover = info ABOUT a
symbol, Telescope `gd/gR/...` = fuzzy-pick then jump away, Trouble `<leader>xr`
= persistent sidebar, glance = look at the source in place without leaving the
buffer. Fully lazy (cmd/keys). Glance's auto theme is OFF: the peek wears its
own warm **"dune"** identity — dark sand-brown panel bgs + saturated Monokai
amber (`#ffd866`) border rules + a solid-amber winbar pill — via the `Glance*`
groups in `theme.lua`'s `overrides_common`. That's a third hue family,
deliberately apart from the editor's pastels and the mint/teal panel/terminal
family, so peek boundaries are unmistakable. List-row matches are amber-bold
text (`GlanceListMatch`; glance's default links to Search, whose sand-block
override painted every reference row garishly); preview matches keep a
contained warm band. The preview winbar shows the filename only (glance
hardcodes an absolute path; its `Winbar.render` is wrapped to drop it).

**Per-project LSP setup** — two bootstrap scripts in `nvim/scripts/` (aliased in
`.bash_aliases`), run once at a project root:
- `slang-init` — creates `.slang/server.json` + a `.f` filelist (indexing →
  def/refs/diagnostics). `-t TOP` bakes `--top` into the filelist and adds a
  `build` entry so driver/load cone tracing (`<leader>vd`/`vl`) works;
  `--regen-only` refreshes just the filelist. `.svh` headers are pulled in via
  `-I`, not listed as sources.
- `verible-init` — creates `verible.filelist` at the repo root (lists `.sv`/
  `.svh`/`.v` — verible has no `+incdir+`, so headers ARE listed) and a
  `.verible_format` formatter `--flagfile` (auto-detected by conform's verible
  formatter, walking up from the file; falls back to baked-in defaults if absent).
  `--rules` also scaffolds `.rules.verible_lint`. No build/elaboration needed.

**Clipboard fallback** (`nvim/scripts/nvim-clip`): a Python 3.6 tkinter daemon that owns the
X CLIPBOARD selection, used on ETX/SLES environments without xclip/xsel/wl-copy. It is
auto-detected and only activated when those native tools are absent.

## Vim (`vim/.vimrc`)

The companion to the nvim config, **not a copy of it**: nvim is the editor,
plain vim is what you reach for to open a multi-GB simulation log on a machine
you don't control. Deliberately **zero plugins, one self-contained file** —
nothing to install, nothing to update, nothing to break on a locked-down box.
Floor is vim 8.0 (guarded), and it `finish`es immediately without `+eval` so
vim-tiny still starts. Machine-specific settings go in `~/.vimrc.local`, which
the vimrc sources and this repo never contains (same per-machine philosophy as
the telekasten vault and the bookmarks DB).

Shared muscle memory with nvim where it's free: `<Space>` leader, `jk` to
escape, `<leader>s*` splits, `<leader>T*` tabs, `]q`/`[q` quickfix,
`<C-hjkl>` window moves, `<leader>u*` UI toggles.

**Big-file mode** — a `BufReadPre` size check (`g:sd_bigfile_mb`, default 10)
strips everything that is O(file size) before the read: syntax, undo/swap,
relativenumber, cursorline, folding. `BufRead` and `BufReadPost` are the SAME
event, so the log-filetype autocmd would otherwise fire `FileType` *after*
big-file mode and let vim's own `syntaxset` group turn syntax back on — the
`SdBigFileSyntax` augroup is defined last precisely to have the final word.

**Log highlighting** uses `matchadd()`, not a syntax file: it survives
big-file mode's `syntax=off` and only costs anything for lines on screen.
Priorities are negative so `hlsearch` still paints over it — searching is the
point of opening the log. Colours are the repo's Monokai accents (amber
`#ffd866` / cyan `#78dce8` / green `#a9dc76`), except **error**, which is a
deeper crimson `#d20f39` (catppuccin Latte red) rather than nvim's pinkish
`#ff6188` — on a wall of log text the pink reads as decoration, the crimson
reads as a stop sign.

The **file-path** pattern has three constraints that are easy to get wrong and
were each hit in practice. Alternatives must be **longest-first**, because
vim's alternation is leftmost-first rather than longest-match — listing `c`
before `cpp` rendered every real `x.cpp` as `x.c`. The extension needs a `>`
word-end anchor, or an elaborated instance path like `model.lru.common.cell`
matches its own middle as `model.lru.c`. And a `(\.\w)@!` guard is needed on
top of that, so a hierarchy component that happens to *be* an extension
(`model.lru.v.cell`) isn't treated as a file either. Net effect: real files
highlight, hierarchy paths stay plain.

**Patterns are stored twice, on purpose.** The combined `\v`-alternation
regexes are for `matchadd()` only (screen-local, so precision is free). Search
and counting use *lists of alternation-free patterns* instead, because vim can
only take its fast literal-search path when a pattern has no top-level
alternation: measured on a 400k-line, 34 MB log, one combined alternation costs
**~74 µs/line vs ~1.7 µs/line** for the same set split up — 3.7 s vs 0.05 s for
a single `]e`. `s:ScanPats` bounds each successive search by the best hit so
far, tries the pattern that won last time in this buffer first (one log's
markers are overwhelmingly all of one kind), and `s:NearestMatch` checks a
nearby window (`g:sd_log_window`, 5000 lines) before falling back to the whole
buffer — a pattern that matches *nowhere* has to reach EOF before it can say so.

**`]e`/`[e`, `]w`/`[w`** echo a navmsg-style counter (`Error 3 of 12`), and
follow the same rule as the nvim side: counting is O(lines), so above
`g:sd_log_count_max` (20000) the label prints **without** an index rather than
a guessed one. The jump moves to the far edge of the current line first, so a
marker sitting right of the cursor can't make the next `]e` re-find the same
line. `<leader>le` builds a quickfix list from the *same* pattern lists, so it
can never disagree with the jumps.

**Fuzzy finding** (`<leader>ff` files, `fb` lines in this buffer, `fB` buffers,
`fg` live ripgrep) drives the **fzf binary** the installers already ship — and
deliberately **not** fzf's vim plugin. fzf is the fastest option precisely
because the matching runs in an external Go process, which also means a
terminal plus a temp file is the entire interface: `s:FzfRun` pipes a source
into `fzf` under `term_start()`, and `exit_cb` reads the pick back. So the file
stays zero-plugin (nothing sourced, nothing on the runtimepath) and startup
cost stays at ~0.5 ms for the whole section. `--height=100%` is passed **last**
so it overrides the `--height` in the shell's `FZF_DEFAULT_OPTS`, which vim
inherits — that inheritance is what makes these pickers match the catppuccin
theming in `fzf/fzf.bash`, and `$FZF_DEFAULT_COMMAND` is reused for the file
list so it agrees with bash's `Ctrl+T`. `fg` is a **live** picker (`--disabled`
+ `change:reload:rg {q}`: rg searches, fzf only draws) seeded from an empty
list rather than fzf's `start:` binding, which older fzf lacks; `<C-q>` there
sends the whole result set to quickfix, which is the persistent list a live
picker otherwise costs you. `<leader>fw` stays non-interactive (word under
cursor → quickfix) on purpose. Every picker degrades to the stock command it
replaced (`:find`, `/`, `:ls`+`:buffer`, `:grep`) when fzf or `+terminal` is
missing.

Also: `<leader>lf` follow/tail (timer + `checktime`, per-buffer), `<leader>lt`
timestamp deltas, `<leader>gf` smart open of `file:12` / `file(12)` /
`"file", line 12` refs, rg-backed `:grep`, and `<leader>y` OSC-52 yank (the vim
answer to nvim-clip: hands the text to the terminal emulator, the only
clipboard a `-clipboard` vim over ssh can reach).

**Vimscript trap to remember:** `:execute` treats a following `|` as part of
its expression, so `if x | execute x | normal! zz | endif` silently does the
wrong thing (it cost a real bug here — the cursor jump and a following `echohl`
both got swallowed). `:echo` does *not* have this problem. Split any line with
`execute` onto its own statement.

`:VimCS` renders the cheatsheet block in a scratch split (30 lines of `:echo`
runs straight into the more-prompt); `vim-cs` prints the same block in the
shell.

## AI coding skills

`ai/skills/` holds portable skills shared with AI coding agents (Claude Code,
Codex, Gemini, …):
- `sd-code-review` — apply review comments from `.code-review.md` (consumer
  side of the `code-review.nvim` plugin). Language-agnostic.
- `sd-rtl-coding` — synthesizable SV **coding** contract (allowed/banned
  constructs, reset/clock discipline, FSM/latch rules). Project-agnostic.
- `sd-rtl-style` — **naming/style** conventions. A template each project
  customizes (snake_case vs camelCase, suffixes, prefixes).

**Per-project install** — `nvim/scripts/init-ai` (aliased `init-ai`), run once at
a project root. Copies the skills into `<project>/.claude/skills/` (Claude Code
auto-discovers them). For other tools it creates `AGENTS.md` pointing at the
skills **only if one doesn't already exist** — it never edits an existing
`AGENTS.md`/`CLAUDE.md`, printing a paste-ready reference instead. `--force`
overwrites; `--regen-only` refreshes the project-agnostic skills, preserving the
customized `sd-rtl-style` template. Nothing is installed globally — per-project only.

## tmux architecture

Config: `tmux/.tmux.conf`. Prefix: `Ctrl+Space`.

**Status bar**:
- Primary (always on): session name left, Bangalore time + weather right
- Secondary (toggle `prefix+S`): CPU load, RAM, disk, SJC time + weather —
  rendered as `status-format[1]`

**Custom status scripts** in `tmux/scripts/`:
| Script              | What it does                                          |
|---------------------|-------------------------------------------------------|
| `tmux-cpu`          | 1-min load average from `/proc/loadavg`               |
| `tmux-ram`          | used/total RAM from `free -h`                         |
| `tmux-disk`         | disk usage                                            |
| `tmux-weather city` | wttr.in weather, 30-min cache in `~/.cache/tmux/` (`.v2` files). Fetches plain `condition\|temp\|wind` and renders with nf-md weather glyphs — wttr's emoji format misaligns in tmux. Unparseable cache prints as-is |
| `tmux-tz-time tz`   | current time in given timezone                        |
| `tmux-open-file`    | open file under cursor in nvim (bound to `prefix+gf`) |
| `tmux-pane-pid tty` | PID of the FOREGROUND process on a pane's tty (the running program, e.g. nvim — not `pane_pid`, the root shell). Used by `pane-border-format` to show `1/2 nvim 87629`. Prints ` <pid>`, or nothing on error so the pill degrades to the command name |
| `tmux-paste`        | paste tmux buffer without trailing newline            |
| `tmux-getdotfiles`  | pull latest dotfiles in a popup                       |
| `tmux-watch`        | watch window for the command running in / last fired from the current pane (`prefix+W`; shell: `watchlast`, `watchthis CMD`): htop scoped to the job's process tree + `ps -f --forest` (watchtty format) + a vitals pane that announces when the job exits. Targets the pane tty's foreground process, falling back to the newest non-shell child of the pane's shell (prompt helpers are skipped), `-g` for newest user process machine-wide |
| `tmux-pad`          | toggle a blank left margin in the current window (`prefix+P`) so the shell isn't glued to the far-left edge of a wide monitor. tmux has no margin setting, so it splits off a narrow empty pane on the left tagged with a pane-local `@sd_pad_pane`; that tag is what keeps it out of the status-bar pane counter, blanks its `pane-border-format`, and drives an `after-select-pane` hook that bounces focus back out. Per-window, and `on` refuses when the window is already split. Width from `@sd_pad_width` (default `15%`) or an arg (`tmux-pad on 30`); percentages are resolved to columns in-script so it works on tmux without `-l N%` |
| `tmux-sysmon`       | lightweight system-health window (`prefix+M`; shell: `watchsys`), no htop: two panes refreshed via `watch -d` so per-refresh changes are highlighted (falls back to a clear+sleep loop where `watch` is missing). Top: top-10 CPU / RAM consumers (`ps`). Bottom: plain-English vitals — CPU queue vs cores, RAM used/still-free, swap spill, `/proc/pressure` PSI stall %, disk space + iowait, frozen D-state programs. The machine-scoped sibling of `tmux-watch`; re-invoking replaces the window |

**Plugins**: catppuccin/tmux (theme), JosephLai241/tmux-line-numbers
(vim-style relative line numbers in a narrow left pane during copy mode —
mauve current line; needs tmux 3.2+), sainnhe/tmux-fzf, tmux-plugins/tmux-yank,
tmux-plugins/tmux-resurrect + tmux-continuum (session save/restore),
tmux-plugins/tpm.

## Critical tmux format rule

**Never use `#[fg=color,bg=color]` multi-attribute style tags inside `#{?cond,true,false}`
ternary expressions.** The comma inside the brackets terminates the ternary arm — the parser
sees it as the next argument. Use separate sequential `#[fg=...]#[bg=...]` tags instead.

## Bash / git

- `bash/.bash_aliases` — aliases including `tmux-cs` (print tmux cheatsheet),
  `git-cs` (print git aliases), `getdotfiles` (pull this repo). Also
  `nvim-bash` / `emacs-bash`: per-shell vi editing mode (nvim as `$EDITOR`,
  live I/N mode pill at the start of the prompt's last line via readline's
  show-mode-in-prompt — the only mechanism that updates on Esc/i mid-edit)
  and its undo. The active prompt is left as-is: the pill works on all three
  prompts, recolored to the active scheme's green/mauve roles —
  `__nvim_bash_rebind` reads the `__tc_fg_*` / `__sd_c_*` vars and
  prompt-sd/prompt-tc/prompt-minimal call it after scheme switches (a no-op
  unless the shell is in vi mode)
- `bash/.bash_prompt` / `.bash_prompt_tc` / `.bash_prompt_minimal` — three
  prompt styles, switched with the `prompt-sd` / `prompt-tc` /
  `prompt-minimal` shell functions. All take an optional color-scheme
  argument (`-h` lists them: default, catppuccin, monokai-pro, tokyonight,
  material, kanagawa, cyberdream — palettes mirroring the nvim colorschemes).
  Switching a scheme also re-themes the rest of the shell: a matching
  **BAT_THEME** is exported (`__sd_apply_bat_theme` in `.bash_prompt`, called
  from both scheme setters), so bat, the fzf Ctrl+T / fzf-git previews, and
  delta follow the prompt scheme; and the **fzf chrome** is recolored
  (`__sd_apply_fzf_colors` — recomposes FZF_DEFAULT_OPTS from fzf.bash's
  layout half + a per-scheme color block; no-op if fzf.bash wasn't sourced,
  and default/catppuccin/unknown schemes fall back to the mocha block).
  Both helpers run only at scheme-switch time — zero per-prompt cost. The .tmTheme files are installed by `install-linux-tools.sh`
  (`install_bat_themes`, commit-pinned into `$(bat --config-dir)/themes` +
  `bat cache --build`); a missing file — and the `default` scheme — falls back
  to bat's built-in `ansi` (follows the terminal palette), and monokai-pro
  maps to the built-in "Monokai Extended" (no free Monokai Pro tmTheme
  exists).
  The minimal prompt (`user ~/path [branch|flags] ❯`, green/red ❯ by exit
  status) borrows everything from `.bash_prompt` — the `__sd_c_*` palette
  (schemes shared with prompt-sd), compact-path builder, and cached async git
  segment — and supports the nvim-bash vi mode pill. They are functions, not aliases — bash-abbrev-alias's
  space-key expansion would swallow arguments, and a function name that
  collides with a live alias alias-expands at parse time (hence `function`
  keyword + scrubbing of stale alias/abbrev/function names on source)
- `fzf/fzf.bash` — fzf config (sourced from `.bash_rc`; fzf has no config file,
  it's all `FZF_*` env vars): catppuccin mocha colors with the mauve accent +
  peach match-highlight, rounded borders/reverse layout matching the tmux
  popups, fd/rg-backed default command, bat/tree previews for `Ctrl+T`/`Alt+C`,
  tmux-popup pickers via `FZF_TMUX_OPTS`. Its `FZF CHEATSHEET` comment block is
  printed by the `fzf-cs` alias (same sed-extraction pattern as `tmux-cs`).
  **Ctrl+R is a custom widget** (`__sd_fzf_history_file`, bound after fzf's
  eval so it wins): it searches the history FILE (newest-first, deduped),
  not the in-memory list — paired with a per-prompt `history -a` inside
  `__sd_prompt_command`/`__tc_prompt_command` (it must live *inside* them:
  prompt-sd/prompt-tc overwrite PROMPT_COMMAND wholesale, so anything chained
  in .bash_rc would be clobbered). Net effect: Ctrl+R finds every shell's
  commands instantly, while up-arrow/`!N` stay per-shell, never interleaved.
  **fzf-git.sh** (junegunn) is sourced at the end when present — `Ctrl+G
  <key>` pickers (plain key or Ctrl+key both bound) for git objects
  (Files/Branches/Tags/Hashes/Stashes/
  Remotes/refLogs/Worktrees/Each-ref, `Ctrl+G ?` lists them) that paste the
  pick onto the command line. Installed by both tool installers into
  `~/.somyadashora/sd-tools/fzf-git/` (commit-pinned, same pattern as
  abbrev-alias — not vendored). Its `_fzf_git_fzf` wrapper is redefined
  (upstream's documented hook) to size the tmux popup like FZF_TMUX_OPTS and
  drop the hardcoded blue label so the mauve accent wins; it handles bash vi
  mode itself, so it coexists with nvim-bash
- `rg/ripgreprc` — ripgrep defaults (rg has no default config location — only
  read because `.bash_rc` exports `RIPGREP_CONFIG_PATH` pointing here):
  `--smart-case`, an `sv` type (`rg -tsv` = SV/Verilog + `.f` filelists),
  long-line truncation, catppuccin colors (peach match / mauve path). Applies
  to every rg run incl. inside tools; opt out per-run with `--no-config`.
  Its `RG CHEATSHEET` comment block is printed by the `rg-cs` alias
- `git/git-aliases.gitconfig` — git aliases; include with `[include] path = ...`
  in `~/.gitconfig`
- `git/delta.gitconfig` — delta pager config (side-by-side, line numbers),
  included the same way. Hyperlinks live in a named `[delta "hyper"]` feature
  that the pager enables only when `less` >= 566 — older less can't pass
  OSC 8 through `-R`, so links would leak as literal `8;;file://…` text
  (stray semicolons) across the diff. Deliberately sets **no** `syntax-theme`:
  delta falls back to `BAT_THEME`, which the prompt schemes export — so diff
  syntax colors follow the active prompt scheme. `core.pager` and
  `interactive.diffFilter` are **fallback-guarded** (`command -v delta … ||
  exec less`/`cat`): on machines without delta (e.g. Termux before
  `pkg install git-delta`, which install-termux-tools.sh now includes)
  `git diff` / `git add -p` still work with plain less/cat instead of dying
  with "cannot run delta"
- `lazygit/config.yml` — lazygit theme (catppuccin mocha, mauve accent — matches
  the nvim accent) + density settings (command log hidden, narrower side panel,
  Nerd Font icons). Font size itself is terminal-owned; lazygit can't set it.
  The nvim `<leader>lg` float opens at full editor size (plugins/lazygit.lua).

## Sublime Text

`sublime/` IS Sublime's `Packages/User` (whole-dir symlink — same pattern as
`nvim/`), so edits made in Sublime's settings UI land directly in the repo.
Contents: `Preferences.sublime-settings` (gruvbox theme, Monocyanide scheme,
100-col rulers), `Default (Linux).sublime-keymap` (AlignTab, Terminus, SV
goto-driver/declaration on `alt+a`/`alt+d`), `SystemVerilog.sublime-settings`
(SystemVerilog plugin: completions, `clk`/`rst_n` names, instance prefix),
`Package Control.sublime-settings` (package list — Package Control installs
from it on a fresh machine; no LSP/GitSavvy — language-server and git
workflows live in nvim, not Sublime), Terminus/Makefile settings + a Terminus
python build. Machine-local
files plugins write into `Packages/User` are kept out of git by
`sublime/.gitignore`. Sublime Text itself is not installed by the installers —
only the config is managed here.

## Keyboard (`keyboard/sofle/`)

ZMK config for a Parix Sofle MX 58 (2 encoders, nice!nano v2 per half,
wireless). **Not a dotfile** — `install.sh` ignores it, there is nothing to
symlink. It lives in this repo rather than its own because ZMK's reusable build
workflow takes `config_path` / `build_matrix_path` inputs, so the mandated
`config/` + `build.yaml` structure works fine in a subdirectory.
`.github/workflows/zmk-sofle.yml` calls that workflow and is `paths:`-filtered
to `keyboard/sofle/**` — this repo is pushed constantly for nvim work and a
Zephyr build is minutes. ZMK source is **commit-pinned** in `config/west.yml`
AND in the workflow's `uses:` ref (bump both together) — same rule as the
pinned bat themes / fzf-git installs.

**ZMK Studio cannot import or export keymap files** (planned upstream, not
implemented). It edits the live device over USB. The trap: once Studio saves
anything, `sofle.keymap` is ignored forever until *Restore Stock Settings* is
run from the Studio UI — two sources of truth and the device silently prefers
the other one. This repo is the source of truth; Studio is a scratchpad, and a
change that earns its place gets written back into `sofle.keymap`. Studio also
cannot define combos, tune hold-tap timings, add macros, or create layers
devicetree did not declare, which is most of what this keymap is — two
`status = "reserved"` layers exist so it can at least add one without a
reflash.

Layout: `base` / `nav` (left thumb) / `media` (right thumb) / `adj` (both, via
conditional-layers). The design target is **"the TKL you already know"** — the
user came from a TKL — so base is unshifted QWERTY in TKL positions with TKL's
bottom-row order, NAV keeps the TKL nav island as a 3-wide island (PrtSc/ScrLk/
Pause over Ins/Home/PgUp over Del/End/PgDn, in the three rightmost columns, so
PgUp sits directly above PgDn), NAV's arrows are the TKL **inverted-T** rather
than hjkl (base-layer hjkl are already hjkl for vim; these arrows are for
browsers and dialogs, where the TKL shape is the muscle memory), and MEDIA is
F1-F12 straight across the number row. **Six columns per half cannot hold a
TKL's right-side overflow** (`[ ] \` after P, `=` after `-`), so all four live
on NAV under the digits they neighbour on a TKL — NAV+8/9/0/- = `\ [ ] =` —
with Shift composing for free (`[` and `{` are one HID key, so NAV+Shift+9 is
`{`). Don't "fix" this by shuffling QWERTY. The two keys between the halves are
the **encoder push-buttons**, not normal keys: easy to hit while turning the
knob, so they only ever get things harmless to fire by accident (mute,
play/pause, Win+L) — never a typing key.

**GACS home-row mods** (`A`=GUI `S`=Alt `D`=Ctrl `F`=Shift, mirrored) keep the
daily chords layer-free — `Ctrl+hjkl` (nvim windows), `Alt+hjkl` (tmux panes)
and `Ctrl+Space` (tmux prefix) are each a left-hand hold plus a right-hand tap.
Two settings carry that and are the first thing to touch if mods misfire: a
**cross-hand guard** (`hold-trigger-key-positions`, so a same-hand roll like
`sd` types letters) and `require-prior-idle-ms = 150` (no mod mid-burst) —
raise the latter before touching `tapping-term-ms`. **`j`+`k` → Esc is a
hardware combo**, not an nvim mapping, so it also escapes in nvim-bash vi mode
and in a bare `vi` on a box you don't control. Encoders are per-layer.
`&studio_unlock` is on ADJ+`U`.

Encoders need `CONFIG_EC11=y` in `config/sofle.conf` (the stock shield ships it
commented out). RGB underglow is deliberately **off**: binding `&rgb_ug` without
`CONFIG_ZMK_RGB_UNDERGLOW=y` is a hard build failure, so the config and the
bindings must be turned on together or not at all. `build.yaml` also builds
`settings_reset` — flash it to a half to wipe BT pairings and Studio-saved
state, then flash the real firmware back.

**Printable diagrams** — `keymap.svg` (print this), `keymap.png`, and
`keymap.txt` (`sofle-cs` prints it) are all **generated** from `sofle.keymap` by
`scripts/gen-keymap-art`, so they cannot drift from the firmware. `keymap.txt`
is **pure 7-bit ASCII on purpose** — box-drawing glyphs and `▽` are East Asian
*Ambiguous* width, so a Nerd Font or CJK locale renders them double-wide and
the grid shears; the generator asserts ASCII-ness and per-group column width
before writing. Regenerate
after every keymap change; the outputs are committed so reading them needs
nothing installed (generating needs `keymap-drawer`, plus `librsvg2-bin` for the
PNG only). `keymap-drawer.yaml` carries two necessary workarounds: it drops the
layer-header text stroke (keymap-drawer relies on `paint-order`, which Chrome
honours but librsvg/cairosvg do not — they paint the white stroke over the
glyphs, rendering every header invisible or as a black blob), and its
`raw_binding_map` renames bare ZMK behaviors that would otherwise print as
devicetree node names (`&studio_unlock` → `UNLOCK`), while `zmk_keycode_map`
spells out the **shifted faces** so every key prints its second legend keycap
style (keymap-drawer knows `&kp LBRC` is `{`, but not that `&kp COMMA` also
shows `<`) — **keep both in sync when adding a macro or punctuation key**. Encoders are
listed in `keymap.txt` only; keymap-drawer does not draw them.

Flashing is a USB mass-storage copy, so it **cannot happen from a Codespace**:
download the `sofle-firmware` artifact locally, double-tap reset, drag the
matching `.uf2` onto the `NICENANO` drive. Both halves, every keymap change.
Details in `keyboard/sofle/README.md`.

## Useful aliases (from `.bash_aliases`)

```bash
tmux-cs       # print tmux keybinding cheatsheet
git-cs        # print git aliases
fzf-cs        # print fzf keybindings/syntax cheatsheet
rg-cs         # print ripgrep usage cheatsheet
vim-cs        # print the plain-vim (~/.vimrc) cheatsheet
sofle-cs      # print the Sofle keymap (generated ASCII diagram, all layers)
getdotfiles   # git pull --rebase on this repo
prompt-check  # verify Nerd Font glyphs render correctly
italic-check  # print an upright/italic pair — does this terminal really
              # slant italics, or fake and clip them? (no probe exists)
watch-ps PROC # live one-process dashboard in the CURRENT terminal (no tmux):
              # ps tree + CPU/RAM/disk-I/O vitals in plain words under watch -d
              # -n 1. Target by pid/name, or no arg = newest process you own
```
