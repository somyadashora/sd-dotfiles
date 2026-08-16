# sd-nvim · Somya Dashora's dotfiles

> Personal **Neovim, tmux, bash and git** configuration — tuned for **VLSI /
> SystemVerilog** development, but comfortable for general coding too.

A single `install.sh` symlinks everything into place. Neovim greets you with a
custom start screen (colours re-rolled on every launch) that doubles as an
onboarding cheat-card, and there's a full keymap cheatsheet a `<leader>fH` away.

```text
               ███████╗██████╗       ███╗   ██╗██╗   ██╗██╗███╗   ███╗
               ██╔════╝██╔══██╗      ████╗  ██║██║   ██║██║████╗ ████║
               ███████╗██║  ██║ ████ ██╔██╗ ██║██║   ██║██║██╔████╔██║
               ╚════██║██║  ██║ ████ ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
               ███████║██████╔╝      ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
               ╚══════╝╚═════╝       ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝

                     « nVim for Chip Design - by Somya Dashora »

                          Saturday, 20 Jun 2026   |   12:43
  codespace@codespaces-687c24   |   Linux x86_64   |   2 cores  8 GB   |  nvim 0.12

                 󰈞  Find file              <leader>ff               f
                 󰋚  Recent files           <leader>fr               r
                 󰊄  Live grep              <leader>fs               g
                    File explorer          <leader>ee               e
                 󰋗  Cheatsheet (all keys)  <leader>fH               H
                 󰘬  Quickfix :cdo help     <leader>qh               Q
                 󰒲  Plugins (Lazy)                                   l
```

---

## What's inside

| Path              | What it is                                                            |
|-------------------|----------------------------------------------------------------------|
| `nvim/`           | Neovim config (lazy.nvim, one file per plugin) → `~/.config/nvim`     |
| `vim/`            | plugin-free `~/.vimrc` for large logs & run dirs (companion to nvim)  |
| `tmux/`           | tmux config + status-bar scripts → `~/.tmux.conf`, `~/.config/tmux`   |
| `bash/`           | aliases & two switchable prompt styles                                |
| `git/`            | git aliases + [delta](https://github.com/dandavison/delta) pager      |
| `ai/skills/`      | portable AI-agent skills (RTL coding/style contracts, code review)    |
| `installers/`     | tool installers for Linux, Termux & Windows                           |
| `install.sh`      | symlinks everything into your home directory                          |
| `install.ps1`     | Windows: junctions/copies `nvim/` into `%LOCALAPPDATA%\nvim`          |

## Requirements

- **Neovim ≥ 0.11** (uses the `vim.lsp.config()` API)
- **tmux ≥ 3.2**, **git**, **bash**
- A **[Nerd Font](https://www.nerdfonts.com/)** for the icons/glyphs
- Optional: `ripgrep` + `fd` (Telescope), `lazygit`, and for SystemVerilog
  [`verible`](https://github.com/chipsalliance/verible) /
  [`slang`](https://github.com/MikePopoloski/slang)

## Quick start

```bash
git clone <this-repo> ~/nvim-configs && cd ~/nvim-configs

./install.sh                             # symlink nvim / tmux configs
bash installers/install-linux-tools.sh   # CLI tools on a standard Linux box
bash installers/install-termux-tools.sh  # …or on Termux (Android)
```

`install.sh` backs up any real file it would overwrite to `*.backup`, and is
idempotent (re-running just re-checks the symlinks). It creates:

```
nvim/           → ~/.config/nvim
tmux/.tmux.conf → ~/.tmux.conf
tmux/scripts/   → ~/.config/tmux/scripts
```

### Windows (Neovim only)

```powershell
git clone <this-repo> $env:USERPROFILE\sd-dotfiles
cd $env:USERPROFILE\sd-dotfiles
.\install.ps1                              # junction nvim\ -> %LOCALAPPDATA%\nvim
.\install.ps1 -Copy                        # …or copy the files instead of linking
.\installers\install-windows-tools.ps1     # CLI tools (nvim, rg, fd, lazygit, …) via Scoop
```

`install.ps1` is the Windows counterpart to `install.sh` for the Neovim config.
It creates a directory junction (no admin rights / Developer Mode needed), backs
up any existing real config to `*.backup`, and is idempotent. tmux/bash aren't
applicable on Windows.

`install-windows-tools.ps1` mirrors `install-linux-tools.sh`: a no-admin,
user-local install via [Scoop](https://scoop.sh) (bootstrapped if missing). It
pulls neovim, git, lazygit, fzf, ripgrep, fd, bat, delta, tree-sitter, a C
compiler (gcc), and the Meslo Nerd Font, plus a best-effort GitHub-release fetch
of Verible (and slang-server, if a Windows build exists). `-Force` updates
everything; `-SkipFonts` / `-SkipCompiler` skip those. Open a new terminal
afterward so `~\scoop\shims` is on PATH.

---

## Neovim

Leader is `<Space>`. Press it and [which-key](https://github.com/folke/which-key.nvim)
shows every group with a readable label (`c → +Cursor`, `t → +Terminal`, …).

**Highlights**

- 🖥️ **Floating/split terminals** (toggleterm) under `<leader>t`, with a
  distinct dark-but-funky background so the terminal never blends into the
  editor — cycle 7 catppuccin themes live with `<leader>tc`.
- 🎛️ **SystemVerilog LSP** with two interchangeable servers — `verible` and
  `slang` — switchable on the fly via `:UseVerible` / `:UseSlang`. Slang adds
  driver/load **cone tracing** (`<leader>vd` / `<leader>vl`).
- 🔭 **Telescope** everywhere, with extras like `<C-q>` → quickfix and
  `<C-y>` → yank marked entries to a register.
- 🧰 **Quickfix workflow** — nvim-bqf marking, list-stack navigation, batch
  `:cdo`/`:cfdo` helpers, and [Trouble](https://github.com/folke/trouble.nvim)
  for fancy viewing.
- 🗂️ **Sessions, folds (ufo), git (gitsigns + lazygit), marks, surround,
  align, multi-cursor** and a styler-driven per-filetype colour theme.
- 📇 **`<leader>fH` cheatsheet** — an NvChad-style colourful card grid of every
  keymap; **`<leader>qh`** opens a focused `:cdo`/`:cfdo` reference.

**Snippet — the live-cyclable terminal themes** (`nvim/lua/somya/plugins/toggleterm.lua`)

```lua
-- Dark, catppuccin-accented terminal backgrounds. <leader>tc cycles them and
-- recolours every open terminal live, so the shell always stands out.
local schemes = {
  { name = "mint",     bg = "#15241f", accent = "#94e2d5" }, -- Teal (default)
  { name = "espresso", bg = "#2c211a", accent = "#fab387" }, -- Peach
  { name = "purple",   bg = "#2a1d3d", accent = "#cba6f7" }, -- Mauve
  { name = "rose",     bg = "#2b1a26", accent = "#f5c2e7" }, -- Pink
  { name = "lavender", bg = "#1f1d3a", accent = "#b4befe" }, -- Lavender
  { name = "maroon",   bg = "#2c1a1d", accent = "#eba0ac" }, -- Maroon
  { name = "gold",     bg = "#262214", accent = "#f9e2af" }, -- Yellow
}
```

### Per-project tooling

Run these once at a project root (aliased in `.bash_aliases`):

| Command        | What it sets up                                                       |
|----------------|----------------------------------------------------------------------|
| `slang-init`   | `.slang/server.json` + `.f` filelist; `-t TOP` enables cone tracing  |
| `verible-init` | `verible.filelist` + a `.verible_format` flagfile (and `--rules`)     |
| `init-ai`      | copies the `ai/skills/` into `<project>/.claude/skills/`              |

---

## tmux

Prefix is `Ctrl+Space`. The status bar shows the session and Bangalore
time + weather; `prefix + S` toggles a second row with CPU/RAM/disk and a San
Jose clock. Custom scripts in `tmux/scripts/` feed those widgets.

**Snippet — cached weather widget** (`tmux/scripts/tmux-weather`)

```sh
#!/bin/sh
# Fetch weather from wttr.in with a 30-minute cache. Usage: tmux-weather <city>
CITY="${1:-Bangalore}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux/weather-$(echo "$CITY" | tr ' /+' '___')"
mkdir -p "$(dirname "$CACHE")"

# Refresh only if the cache is missing or older than 30 minutes
if [ -z "$(find "$CACHE" -mmin -30 2>/dev/null)" ]; then
    RESULT=$(curl -sf --max-time 5 "wttr.in/${CITY}?format=2" | tr -d '\r\n')
    [ -n "$RESULT" ] && printf '%s' "$RESULT" > "$CACHE"
fi
cat "$CACHE" 2>/dev/null | tr -d '\r\n' || echo "?"
```

> **tmux format gotcha:** never put a `#[fg=a,bg=b]` multi-attribute style tag
> *inside* a `#{?cond,true,false}` ternary — the comma terminates the arm. Use
> separate sequential `#[fg=...]#[bg=...]` tags instead.

Print the full keybinding cheatsheet any time with `tmux-cs`.

---

## Bash & git

```bash
tmux-cs        # print the tmux keybinding cheatsheet
git-cs         # print the git aliases
getdotfiles    # git pull --rebase on this repo
prompt-default # / prompt-tc   — switch between the two prompt styles
prompt-check   # verify Nerd Font glyphs render correctly
```

Git aliases live in `git/git-aliases.gitconfig`; include them from `~/.gitconfig`:

```ini
[include]
    path = /path/to/nvim-configs/git/git-aliases.gitconfig
    path = /path/to/nvim-configs/git/delta.gitconfig
```

---

## Repo layout

```
nvim/
  init.lua                      # → somya.core + somya.lazy
  lua/somya/core/               # options, keymaps (leader = <Space>)
  lua/somya/plugins/            # one file per plugin (lazy specs)
  lua/somya/plugins/lsp/        # mason + lspconfig
  lua/somya/cheatsheet.lua      # :Cheatsheet / :QfHelp windows
  scripts/                      # slang-init, verible-init, init-ai, nvim-clip
vim/
  .vimrc                        # zero-plugin vim: big-file mode, log nav, tail
tmux/
  .tmux.conf
  scripts/                      # status-bar widgets
bash/  git/  ai/skills/  installers/
```

See [`CLAUDE.md`](CLAUDE.md) for a deeper architectural tour.

## Credits

Built on the excellent [lazy.nvim](https://github.com/folke/lazy.nvim),
[catppuccin](https://github.com/catppuccin), and the many plugin authors linked
above. Personal config — use freely, no warranty.
