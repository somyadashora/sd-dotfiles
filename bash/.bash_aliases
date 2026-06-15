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

abbrev-alias prompt-tc='PROMPT_COMMAND="__tc_prompt_command"; echo "switched to TypeCraft prompt"'
abbrev-alias prompt-default='PROMPT_COMMAND="__sd_prompt_command"; echo "switched to default prompt"'

alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
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
