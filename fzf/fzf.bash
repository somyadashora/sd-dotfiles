# ──────────────────────────────────────────────────────────────────────────────
#  fzf configuration — colors + layout in sync with the nvim/tmux configs
#
#  Sourced from bash/.bash_rc (fzf has no config file of its own — everything
#  rides on FZF_* environment variables). Requires fzf; fd/bat/tree upgrade
#  the experience when present but everything degrades gracefully.
#  The color half of FZF_DEFAULT_OPTS follows the active bash prompt scheme
#  (prompt-sd/tc/minimal <scheme> → __sd_apply_fzf_colors in .bash_prompt);
#  the catppuccin-mocha block below is the standalone/default fallback.
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
# GIT PICKERS (fzf-git.sh — Ctrl+G, then a plain key; holding Ctrl for the
# second key works too. The pick pastes onto the command line, so prefix a
# command first: `git rebase -i ` + Ctrl+G H):
#   Ctrl+G F   files (status + untracked)   Ctrl+G B   branches
#   Ctrl+G H   commit hashes                Ctrl+G T   tags
#   Ctrl+G S   stashes                      Ctrl+G R   remotes
#   Ctrl+G L   reflog                       Ctrl+G W   worktrees
#   Ctrl+G E   every ref                    Ctrl+G ?   this list
#   inside a picker: Ctrl+O open on GitHub · Alt+E edit · Tab multi-select
#   (each picker's header shows its own extras, e.g. Ctrl+X drop stash)
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

# FZF_DEFAULT_OPTS is built from two halves so the bash prompt schemes can
# recolor the chrome without touching layout (__sd_apply_fzf_colors in
# bash/.bash_prompt recomposes them on every prompt-sd/tc/minimal scheme
# switch). Sourcing this file alone — prompts never loaded — still exports
# the full catppuccin-mocha default below, so fzf always works.
#
# Layout half: rounded borders like the tmux popups + prompt capsules,
# ❯ like prompt-tc.
__sd_fzf_layout_opts="
  --height=80% --layout=reverse --border=rounded --info=inline-right
  --prompt='❯ ' --pointer='❯' --marker='✓'
  --bind=ctrl-/:toggle-preview"

# Color half — catppuccin mocha, same palette as the nvim/tmux/lazygit
# configs: mauve #cba6f7 accent (prompt/pointer/border label — the repo
# accent), peach match highlight (echoes nvim's Search/CurSearch overrides),
# surface pills for selection, crust-adjacent base bg. Doubles as the
# fallback block for the `default`/`catppuccin` (and unknown) schemes.
__sd_fzf_colors_default="
  --color=bg:#1e1e2e,bg+:#313244,gutter:#1e1e2e
  --color=fg:#cdd6f4,fg+:#cdd6f4,hl:#fab387,hl+:#fab387
  --color=prompt:#cba6f7,pointer:#cba6f7,marker:#a6e3a1
  --color=info:#7f849c,spinner:#f5c2e7,header:#94e2d5
  --color=border:#45475a,label:#cba6f7
"

export FZF_DEFAULT_OPTS="${__sd_fzf_layout_opts}
${__sd_fzf_colors_default}"

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

# fzf-git.sh — Ctrl+G chord pickers for git objects (files, branches, hashes,
# stashes, …; cheatsheet section above). Installed by the tool installers into
# sd-tools, like abbrev-alias; it binds nothing outside a git repo's Ctrl+G
# chords and handles bash vi mode itself (bridges through emacs mode), so it
# coexists with nvim-bash. Colors ride on FZF_DEFAULT_OPTS.
_sd_fzf_git="$HOME/.somyadashora/sd-tools/fzf-git/fzf-git.sh"
if [[ $- == *i* && -f $_sd_fzf_git ]] && command -v fzf >/dev/null 2>&1; then
  source "$_sd_fzf_git"
  # Upstream's sanctioned hook ("Redefine this function to change the
  # options"): a copy of its wrapper with three changes — tmux popup sized
  # like FZF_TMUX_OPTS (80%,70% vs upstream's 90%,70%), upstream's hardcoded
  # `--color label:blue` dropped so the mauve label from FZF_DEFAULT_OPTS
  # wins, and `--exit-0` added so a picker with nothing to show (no tags, no
  # stashes, …) closes immediately instead of presenting an empty list that
  # looks like a hang.
  _fzf_git_fzf() {
    fzf --height 50% --tmux 80%,70% \
      --layout reverse --multi --min-height 20+ --exit-0 \
      --no-separator --header-border horizontal \
      --border-label-pos 2 \
      --preview-window 'right,50%' --preview-border line \
      --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
  }
fi
unset _sd_fzf_git
