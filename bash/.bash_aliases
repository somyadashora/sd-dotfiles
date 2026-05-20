# common aliases for efficient workflow

alias ll="ls -lrtha --color=auto"

alias tmux-cs="sed -n '/TMUX CHEATSHEET/,/# split panes/p' \$DOTFILES_DIR/tmux/.tmux.conf | sed '\$d'"

alias git-cs="grep -E '^\s*[a-z]+\s*=' \$DOTFILES_DIR/git/git-aliases.gitconfig | sed 's/^\s*//' | sed 's/\s*#.*$//' | sed 's/\s*=\s*/ - /' | sort"

alias watchtty="watch -d -n 1 'ps -f --forest --tty $1'"

alias getdotfiles="git -C $DOTFILES_DIR pull --rebase"

alias prompt-tc='PROMPT_COMMAND="__tc_prompt_command"; echo "switched to TypeCraft prompt"'
alias prompt-default='PROMPT_COMMAND="__sd_prompt_command"; echo "switched to default prompt"'
