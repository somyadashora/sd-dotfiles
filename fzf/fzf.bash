# ──────────────────────────────────────────────────────────────────────────────
#  fzf configuration — colors + layout in sync with the nvim/tmux configs
#
#  Sourced from bash/.bash_rc (fzf has no config file of its own — everything
#  rides on FZF_* environment variables). Requires fzf; fd/bat/tree upgrade
#  the experience when present but everything degrades gracefully.
#
#  Print the cheatsheet below with:  fzf-cs
# ──────────────────────────────────────────────────────────────────────────────

# ============================================================================
# FZF CHEATSHEET  (fzf-cs prints this)
# ============================================================================
# SHELL KEYBINDINGS (installed by `fzf --bash` in .bash_rc):
#   Ctrl+T   - pick file(s) under the current dir, paste onto command line
#   Ctrl+R   - fuzzy-search shell history — ALL shells, live (searches the
#              history file, flushed per prompt; Ctrl+R again toggles sort)
#   Alt+C    - cd into a fuzzy-picked subdirectory
#
# INSIDE ANY PICKER:
#   Tab / Shift+Tab  - multi-select down / up (where --multi is on)
#   Ctrl+/           - toggle the preview pane
#   Ctrl+J/K, Ctrl+N/P, arrows - move    ·    Enter accept · Esc abort
#   PgUp/PgDn scroll the preview (Shift+↑/↓ too)
#
# SEARCH SYNTAX (space-separated terms AND together):
#   word   fuzzy      'word   exact       ^word   prefix
#   word$  suffix     !word   negate      a | b   OR (within one term)
#   e.g.:  .sv$ ^rtl/ !tb_    → *.sv under rtl/, skipping testbenches
#
# TRIGGER COMPLETION (type ** then Tab):
#   nvim **<Tab>      pick file(s)        cd **<Tab>     pick a directory
#   kill -9 **<Tab>   pick a process      ssh **<Tab>    pick a host
#   export **<Tab>    pick an env var     unalias **<Tab> pick an alias
#
# PIPE ANYTHING:
#   git branch | fzf                    fuzzy-pick a branch name
#   git log --oneline | fzf --multi     pick commit(s)
#   nvim "$(fzf)"                       open a picked file
#   rg -l TODO | fzf | xargs -r nvim    pick among files containing TODO
#
# IN TMUX:
#   the keybindings above open in a floating popup (FZF_TMUX_OPTS)
#   prefix+f = tmux-fzf action menu · prefix+b = paste-buffer picker
# ============================================================================

# Colors — catppuccin mocha, same palette as the nvim/tmux/lazygit configs:
# mauve #cba6f7 accent (prompt/pointer/border label — the repo accent), peach
# match highlight (echoes nvim's Search/CurSearch overrides), surface pills
# for selection, crust-adjacent base bg. Layout mirrors the repo's shapes:
# rounded borders like the tmux popups + prompt capsules, ❯ like prompt-tc.
export FZF_DEFAULT_OPTS="
  --height=80% --layout=reverse --border=rounded --info=inline-right
  --prompt='❯ ' --pointer='❯' --marker='✓'
  --bind=ctrl-/:toggle-preview
  --color=bg:#1e1e2e,bg+:#313244,gutter:#1e1e2e
  --color=fg:#cdd6f4,fg+:#cdd6f4,hl:#fab387,hl+:#fab387
  --color=prompt:#cba6f7,pointer:#cba6f7,marker:#a6e3a1
  --color=info:#7f849c,spinner:#f5c2e7,header:#94e2d5
  --color=border:#45475a,label:#cba6f7
"

# Inside tmux, open the Ctrl+T / Ctrl+R / Alt+C pickers in a centered floating
# popup — same look as the prefix+b buffer picker in .tmux.conf.
export FZF_TMUX_OPTS="-p 80%,70%"

# File listing: fd (fast, honors .gitignore, keeps hidden files but skips
# .git) → rg fallback → plain find. Ctrl+T shares the same command.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Previews: bat for files (Ctrl+T), tree/ls for directories (Alt+C).
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || ls -la {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C -L 2 {} 2>/dev/null || ls -la {}'"

# Ctrl+R — search the history FILE, not this shell's in-memory list.
# The prompt functions flush every command with `history -a` as it runs
# (see .bash_prompt/__sd_prompt_command), so this picker sees ALL shells'
# commands instantly — while each shell's in-memory history (up-arrow,
# !N) stays its own, never interleaved. Replaces the __fzf_history__
# binding installed by `eval "$(fzf --bash)"` — this file is sourced
# after that eval in .bash_rc, so our bind wins.
__sd_fzf_history_file() {
  local histfile=${HISTFILE:-$HOME/.bash_history} selected
  local picker=(fzf)
  # Same tmux popup as the other keybindings (FZF_TMUX_OPTS, word-split).
  if [[ -n $TMUX ]] && command -v fzf-tmux >/dev/null 2>&1; then
    picker=(fzf-tmux $FZF_TMUX_OPTS)
  fi
  selected=$(
    tac "$histfile" 2>/dev/null |
      grep -avE '^#[0-9]+$' |
      awk '!seen[$0]++' |
      "${picker[@]}" --scheme=history --no-multi --query "$READLINE_LINE" \
        --prompt='history ❯ ' --bind=ctrl-r:toggle-sort \
        --preview 'echo {}' --preview-window down:3:hidden:wrap
  ) || return
  READLINE_LINE=$selected
  READLINE_POINT=${#READLINE_LINE}
}
if [[ $- == *i* ]] && command -v fzf >/dev/null 2>&1; then
  bind -x '"\C-r": __sd_fzf_history_file'
fi
