# common aliases for efficient workflow

# Set SD_NO_ABBREV_ALIAS=1 to disable abbreviation expansion and use plain alias
if [[ "${SD_NO_ABBREV_ALIAS:-0}" == "1" ]] || ! command -v abbrev-alias >/dev/null 2>&1; then
  abbrev-alias() { alias "$@"; }
fi

abbrev-alias ll="ls -lrtha --color=auto"

abbrev-alias tmux-cs="sed -n '/TMUX CHEATSHEET/,/# split panes/p' \$DOTFILES_DIR/tmux/.tmux.conf | sed '\$d'"

abbrev-alias git-cs="grep -E '^\s*[a-z]+\s*=' \$DOTFILES_DIR/git/git-aliases.gitconfig | sed 's/^\s*//' | sed 's/\s*#.*$//' | sed 's/\s*=\s*/ - /' | sort"

abbrev-alias watchtty="watch -d -n 1 'ps -f --forest --tty $1'"

abbrev-alias getdotfiles="git -C $DOTFILES_DIR pull --rebase"

abbrev-alias slang-init="$DOTFILES_DIR/nvim/scripts/slang-init"
abbrev-alias verible-init="$DOTFILES_DIR/nvim/scripts/verible-init"
abbrev-alias init-ai="$DOTFILES_DIR/nvim/scripts/init-ai"

abbrev-alias prompt-tc='PROMPT_COMMAND="__tc_prompt_command"; echo "switched to TypeCraft prompt"'
abbrev-alias prompt-default='PROMPT_COMMAND="__sd_prompt_command"; echo "switched to default prompt"'

# nvim-bash: put THIS shell into vi editing mode with nvim as $EDITOR, and make
# the readline cursor reflect the mode — a blinking line while inserting, a
# steady block in command/normal mode. The cursor switch rides on readline's
# show-mode-in-prompt strings (\1..\2 wrap the non-printing escape so prompt
# width stays correct; \e[5 q = blinking bar, \e[2 q = steady block). The final
# printf sets the line cursor right away since you land in insert mode. Plain
# `alias` (not abbrev-alias) so the escape-laden body isn't expanded inline as
# you type it. Run it per-shell; add it to .bash_rc if you want it everywhere.
alias nvim-bash='export EDITOR=nvim; set -o vi; bind "set show-mode-in-prompt on"; bind "set vi-ins-mode-string \1\e[5 q\2"; bind "set vi-cmd-mode-string \1\e[2 q\2"; printf "\e[5 q"'

alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

# nvim-reg: print the contents of an nvim register from the shell. Registers
# persist in the shada file when nvim exits, so this shows them from your last
# session. -u NONE skips your config so plugin/startup noise stays out of the
# output; the $(...)+printf gives exactly one trailing newline. Examples:
#   nvim-reg        # the unnamed register "  (last yank/delete)
#   nvim-reg 0      # the yank register
#   nvim-reg a      # named register a
nvim-reg() {
    local reg="${1:-\"}" val
    val=$(nvim --headless -u NONE -c "echo getreg('$reg')" -c 'q' 2>&1)
    printf '%s\n' "$val"
}

batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}

# watchlast: open the tmux watch window (htop + ps --forest + vitals) for the
# command running in / last fired from this pane — same as prefix+W. Also takes
# a pid or process name, or -g for the newest user process machine-wide.
# watchthis CMD...: launch CMD and watch it from the start (monitors are armed
# with the exact pid, so no discovery guesswork); Ctrl-C still kills CMD.
watchlast() { "$DOTFILES_DIR/tmux/scripts/tmux-watch" "$@"; }
# watchsys: open the system-wide tmux monitor window (htop + RAM hogs +
# bottleneck vitals: load vs cores, PSI stall %, swap/iowait, D-state procs)
# — same as prefix+M. Answers "how much RAM is used / what's slowing us down".
watchsys() { "$DOTFILES_DIR/tmux/scripts/tmux-sysmon" "$@"; }
watchthis() {
    [ $# -gt 0 ] || { echo "usage: watchthis <command...>" >&2; return 1; }
    "$@" &
    local pid=$!
    "$DOTFILES_DIR/tmux/scripts/tmux-watch" "$pid"
    wait "$pid"
}

prompt-check() {
  printf '\nNerd Font glyph test\n'
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '  1. Sharp right arrow  U+E0B0:  \xee\x82\xb0  (should look like ▶)\n'
  printf '  2. Rounded right cap  U+E0B4:  \xee\x82\xb4  (should look like )\n'
  printf '  3. Rounded left  cap  U+E0B6:  \xee\x82\xb6  (should look like )\n'
  printf '  4. Git branch icon    U+E0A0:  \xee\x82\xa0  (should look like a branch)\n'
  printf '\n'
  printf 'Mini prompt preview:\n'
  printf '  \e[38;2;198;160;246m\xee\x82\xb0\e[48;2;198;160;246m\e[38;2;36;39;58m\e[1m user \e[0m'
  printf '\e[48;2;245;169;127m\e[38;2;198;160;246m\xee\x82\xb0\e[38;2;36;39;58m\e[1m ~/path \e[0m'
  printf '\e[48;2;139;213;202m\e[38;2;245;169;127m\xee\x82\xb0\e[38;2;36;39;58m\e[1m  main \e[0m'
  printf '\e[38;2;139;213;202m\xee\x82\xb4\e[0m'
  printf '\n\n'
  printf 'If boxes/? appear: the glyph is missing from your font.\n'
  printf 'Items 2+3 (rounded) need a FULL Nerd Font, not just MesloLGS NF.\n'
  printf '\n'
  printf 'Recommended fonts with full coverage:\n'
  printf '  • JetBrainsMono Nerd Font  (nerdfonts.com)\n'
  printf '  • FiraCode Nerd Font\n'
  printf '  • Hack Nerd Font\n'
  printf '\n'
  printf 'VS Code setting:  terminal.integrated.fontFamily → "JetBrainsMono Nerd Font"\n'
  printf 'Terminal: TERM_PROGRAM=%s  TERM=%s\n\n' "${TERM_PROGRAM:-?}" "${TERM:-?}"
}
