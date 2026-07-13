# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for Neovim, tmux, bash, git, and Sublime Text — focused on
VLSI/SystemVerilog development. `install.sh` creates the necessary symlinks:

```
nvim/               → ~/.config/nvim
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
| `tmux-watch`        | watch window for the command running in / last fired from the current pane (`prefix+W`; shell: `watchlast`, `watchthis CMD`): htop scoped to the job's process tree + `ps -f --forest` (watchtty format) + a vitals pane that announces when the job exits. Targets the pane tty's foreground process, falling back to the newest non-shell child of the pane's shell (prompt helpers are skipped), `-g` for newest user process machine-wide |
| `tmux-sysmon`       | system-wide monitor window (`prefix+M`; shell: `watchsys`): htop + a RAM pane (`free -h` + top 15 by RSS) + a bottleneck-vitals pane (load vs cores, `/proc/pressure` PSI stall %, swap in/out + iowait via vmstat, D-state processes, root-disk usage). The machine-scoped sibling of `tmux-watch`; re-invoking replaces the window |

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
- `git/delta.gitconfig` — delta pager config (side-by-side, line numbers,
  hyperlinks), included the same way. Deliberately sets **no** `syntax-theme`:
  delta falls back to `BAT_THEME`, which the prompt schemes export — so diff
  syntax colors follow the active prompt scheme
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
from it on a fresh machine), Terminus/Makefile settings + a Terminus python
build. Machine-local files plugins write into `Packages/User` are kept out of
git by `sublime/.gitignore`. Sublime Text itself is not installed by the
installers — only the config is managed here.

## Useful aliases (from `.bash_aliases`)

```bash
tmux-cs       # print tmux keybinding cheatsheet
git-cs        # print git aliases
fzf-cs        # print fzf keybindings/syntax cheatsheet
rg-cs         # print ripgrep usage cheatsheet
getdotfiles   # git pull --rebase on this repo
prompt-check  # verify Nerd Font glyphs render correctly
```
