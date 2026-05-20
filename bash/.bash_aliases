# common aliases for efficient workflow

alias ll="ls -lrtha --color=auto"

alias tmux-cs="sed -n '/TMUX CHEATSHEET/,/# split panes/p' \$DOTFILES_DIR/tmux/.tmux.conf | sed '\$d'"

alias git-cs="grep -E '^\s*[a-z]+\s*=' \$DOTFILES_DIR/git/git-aliases.gitconfig | sed 's/^\s*//' | sed 's/\s*#.*$//' | sed 's/\s*=\s*/ - /' | sort"

alias watchtty="watch -d -n 1 'ps -f --forest --tty $1'"

alias getdotfiles="git -C $DOTFILES_DIR pull --rebase"

alias prompt-tc='PROMPT_COMMAND="__tc_prompt_command"; echo "switched to TypeCraft prompt"'
alias prompt-default='PROMPT_COMMAND="__sd_prompt_command"; echo "switched to default prompt"'

prompt-check() {
  printf '\nNerd Font glyph test — what renders next to each label?\n\n'
  printf '  U+E0B0  sharp right arrow  (inner separator):  \xee\x82\xb0\n'
  printf '  U+E0B4  rounded right cap  (right end):        \xee\x82\xb4\n'
  printf '  U+E0B6  rounded left  cap  (left end):         \xee\x82\xb6\n'
  printf '  U+E0A0  git branch icon:                       \xee\x82\xa0\n'
  printf '\n'
  printf 'Expected: arrow/curve shapes.  Actual: □ or ? → font is not a Nerd Font.\n'
  printf '\n'
  printf 'Fix (VS Code terminal):\n'
  printf '  1. Install a Nerd Font on your LOCAL machine, e.g. MesloLGS NF:\n'
  printf '       https://github.com/romkatv/powerlevel10k#fonts\n'
  printf '  2. In VS Code → Settings → search "terminal font family"\n'
  printf '       terminal.integrated.fontFamily  →  MesloLGS NF\n'
  printf '  3. Restart the terminal and run  prompt-tc  again.\n\n'
  printf 'Current terminal: TERM_PROGRAM=%s  TERM=%s\n\n' "${TERM_PROGRAM:-?}" "${TERM:-?}"
}
