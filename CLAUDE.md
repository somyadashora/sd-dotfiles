# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for Neovim, tmux, bash, and git — focused on VLSI/SystemVerilog development.
`install.sh` creates the necessary symlinks:

```
nvim/           → ~/.config/nvim
tmux/.tmux.conf → ~/.tmux.conf
tmux/scripts/   → ~/.config/tmux/scripts
```

## Installation

```bash
./install.sh                             # symlink all configs
bash installers/install-linux-tools.sh   # tools for standard Linux
bash installers/install-termux-tools.sh  # tools for Termux (Android)
```

## Neovim architecture

Entry point: `nvim/init.lua` → `somya.core` + `somya.lazy`

- `nvim/lua/somya/core/` — options, keymaps (leader = `<Space>`)
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
python→catppuccin, …) — but it now starts **OFF** (`M.styler_enabled = false`),
so on launch every window just shows `M.default`. Turn per-filetype themes on with
`<leader>uy` / `:StylerToggle`; only then does `:colorscheme X` change the file
explorer but not a pinned `.sv`/`.py` buffer. The toggle flips styler on/off
(off = reset every window's hl namespace to 0 + drop styler's autocmds; on =
`setup()`, which re-pins all open windows). Starting `false` means the *first*
`<leader>uy` enables it. For a true full-window preview, styler must be off (its
default state): `<leader>uc` / `:ThemeBrowse` opens the picker with
`enable_preview`, suspending styler first only if it happens to be on. The
`<leader>u` prefix is "+UI / Theme".

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
on first use (`ensure_repo`: `mkdir -p` + `git init` + write `notes.md` if absent),
so no manual setup. All maps live under the `<leader>Z` ("+Notes") prefix. The
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

**SystemVerilog LSP**: two servers are configured — `verible` (Mason-installed) and
`slang-server` (`~/.local/bin/slang-server`). Only one should be active at a time;
switch with `:UseVerible` / `:UseSlang`.

**LSP keymaps** (set on `LspAttach` in `lsp/lspconfig.lua`): generic actions — usable
with any server — live under the `<leader>v` ("LSP / Code") group: `va` code action,
`vr` smart rename, `vi` active-client info, `vR` restart. Navigation stays on `g*`
(`gd/gD/gR/gi/gt`), `K` hover, `<leader>d`/`D` and `[d`/`]d` diagnostics. Server-specific
maps are guarded by client name: the slang cone-tracing maps (`<leader>vd` drivers /
`vl` loads, via LSP call-hierarchy) attach only when `slang-server` is the client, so
they appear/disappear as you `:UseSlang` / `:UseVerible` (which re-attach the buffer).

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
| `tmux-weather city` | wttr.in weather, 30-min cache in `~/.cache/tmux/`     |
| `tmux-tz-time tz`   | current time in given timezone                        |
| `tmux-open-file`    | open file under cursor in nvim (bound to `prefix+gf`) |
| `tmux-paste`        | paste tmux buffer without trailing newline            |
| `tmux-getdotfiles`  | pull latest dotfiles in a popup                       |

**Plugins**: catppuccin/tmux (theme), sainnhe/tmux-fzf, tmux-plugins/tmux-yank, tmux-plugins/tpm.

## Critical tmux format rule

**Never use `#[fg=color,bg=color]` multi-attribute style tags inside `#{?cond,true,false}`
ternary expressions.** The comma inside the brackets terminates the ternary arm — the parser
sees it as the next argument. Use separate sequential `#[fg=...]#[bg=...]` tags instead.

## Bash / git

- `bash/.bash_aliases` — aliases including `tmux-cs` (print tmux cheatsheet),
  `git-cs` (print git aliases), `getdotfiles` (pull this repo)
- `bash/.bash_prompt` / `.bash_prompt_tc` — two prompt styles
  (switch with `prompt-default` / `prompt-tc`)
- `git/git-aliases.gitconfig` — git aliases; include with `[include] path = ...`
  in `~/.gitconfig`

## Useful aliases (from `.bash_aliases`)

```bash
tmux-cs       # print tmux keybinding cheatsheet
git-cs        # print git aliases
getdotfiles   # git pull --rebase on this repo
prompt-check  # verify Nerd Font glyphs render correctly
```
