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
- `nvim/lua/somya/plugins/dashboard.lua` — alpha-nvim start screen ("SD-NVIM",
  *nvim for Chip Design*) shown on `nvim` with no file args. Buttons run real
  actions (find/grep/explorer/`:Cheatsheet`/`:QfHelp`/Lazy) and display the
  matching `<leader>` keymap, so it doubles as onboarding. It also shows a
  date/time line and a machine-info line (`user@host | OS arch | cores RAM
  | nvim ver`), computed at startup and refreshed once on `User VeryLazy`.
  `cheatsheet.lua`
  exposes `:Cheatsheet` / `:QfHelp` commands for the buttons.
- `nvim/lua/somya/plugins/which-key.lua` — names every `<leader>` prefix that fans
  out into multiple keys via `opts.spec` (e.g. `c → +Cursor`, `t → +Terminal`), so
  the popup labels groups instead of showing a bare count. Add a row when a new
  prefix grows a second binding.
- `nvim/lua/somya/lazy.lua` — bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim);
  imports all of `somya.plugins` and `somya.plugins.lsp`
- `nvim/lua/somya/plugins/` — one file per plugin, each returns a lazy spec table
- `nvim/lua/somya/plugins/lsp/` — `mason.lua` (installer) + `lspconfig.lua`
  (server config via `vim.lsp.config()` API, nvim-lspconfig 0.11+)

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
