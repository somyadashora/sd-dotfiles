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
- `nvim/lua/somya/lazy.lua` — bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim);
  imports all of `somya.plugins` and `somya.plugins.lsp`
- `nvim/lua/somya/plugins/` — one file per plugin, each returns a lazy spec table
- `nvim/lua/somya/plugins/lsp/` — `mason.lua` (installer) + `lspconfig.lua`
  (server config via `vim.lsp.config()` API, nvim-lspconfig 0.11+)

**SystemVerilog LSP**: two servers are configured — `verible` (Mason-installed) and
`slang-server` (`~/.local/bin/slang-server`). Only one should be active at a time;
switch with `:UseVerible` / `:UseSlang`.

**Clipboard fallback** (`nvim/scripts/nvim-clip`): a Python 3.6 tkinter daemon that owns the
X CLIPBOARD selection, used on ETX/SLES environments without xclip/xsel/wl-copy. It is
auto-detected and only activated when those native tools are absent.

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
