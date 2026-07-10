# common aliases for efficient workflow

# Set SD_NO_ABBREV_ALIAS=1 to disable abbreviation expansion and use plain alias
if [[ "${SD_NO_ABBREV_ALIAS:-0}" == "1" ]] || ! command -v abbrev-alias >/dev/null 2>&1; then
  abbrev-alias() { alias "$@"; }
fi

abbrev-alias ll="ls -lrtha --color=auto"

abbrev-alias tmux-cs="sed -n '/TMUX CHEATSHEET/,/# split panes/p' \$DOTFILES_DIR/tmux/.tmux.conf | sed '\$d'"

abbrev-alias git-cs="grep -E '^\s*[a-z]+\s*=' \$DOTFILES_DIR/git/git-aliases.gitconfig | sed 's/^\s*//' | sed 's/\s*#.*$//' | sed 's/\s*=\s*/ - /' | sort"

abbrev-alias fzf-cs="sed -n '/FZF CHEATSHEET/,/# Colors/p' \$DOTFILES_DIR/fzf/fzf.bash | sed '\$d'"

abbrev-alias rg-cs="sed -n '/RG CHEATSHEET/,/# Case-insensitive/p' \$DOTFILES_DIR/rg/ripgreprc | sed '\$d'"

abbrev-alias watchtty="watch -d -n 1 'ps -f --forest --tty $1'"

abbrev-alias getdotfiles="git -C $DOTFILES_DIR pull --rebase"

abbrev-alias slang-init="$DOTFILES_DIR/nvim/scripts/slang-init"
abbrev-alias verible-init="$DOTFILES_DIR/nvim/scripts/verible-init"
abbrev-alias init-ai="$DOTFILES_DIR/nvim/scripts/init-ai"

# prompt-tc and prompt-sd (formerly prompt-default) are FUNCTIONS in
# bash/.bash_prompt_tc and bash/.bash_prompt (each takes a color-scheme
# argument; -h lists the schemes: default/catppuccin/monokai-pro/tokyonight/
# material/kanagawa/cyberdream) — aliases here would shadow them, so neither
# lives in this file anymore.

# nvim-bash: put THIS shell into vi editing mode with nvim as $EDITOR, jump to
# the TypeCraft prompt (scheme arg forwarded: `nvim-bash catppuccin`), and show
# the current vi mode two ways — the readline cursor (\e[5 q blinking bar =
# insert, \e[2 q steady block = normal) and a colored pill at the start of the
# prompt's last line: green " I " while inserting, mauve/purple " N " in
# normal mode, colored in the ACTIVE prompt scheme's accents (see
# __nvim_bash_rebind). Both ride readline's show-mode-in-prompt strings — the
# ONLY mechanism that live-updates as you hit Esc/i (PS1 is rebuilt once per
# prompt, so PROMPT_COMMAND can't track mode changes). Undo with emacs-bash
# below. Run per-shell; shells that never call nvim-bash are untouched. (Was a
# plain alias; now a function — declared with the `function` keyword +
# alias/abbrev scrub because the old alias may still be live in long-running
# shells, same parse-time expansion trap as prompt-tc.)

# __nvim_bash_accent: pull the SGR params ("38;2;R;G;B" or "38;5;N") out of a
# prompt color variable (PS1-format, '\[\e[38;...m\]'); $2 is the fallback
# used when the variable is unset or not in that shape.
__nvim_bash_accent() {
  local s=${1:-}
  if [[ $s == *'\e['*m* ]]; then
    s=${s#*\\e\[}
    printf '%s' "${s%%m*}"
  else
    printf '%s' "$2"
  fi
}

# __nvim_bash_rebind: (re)apply the vi mode-pill strings in the ACTIVE
# prompt's scheme accents — prompt-tc's green/mauve/pill-dark roles, or
# prompt-sd's staged/user roles (crust text) when that prompt owns
# PROMPT_COMMAND — falling back to catppuccin mocha green/mauve/crust when
# neither prompt file is loaded. \1..\2 wrap the non-printing escapes so
# prompt width stays correct; both pills print the same width (4 cells) so the
# prompt never shifts on mode change. prompt-sd/prompt-tc call this after
# every scheme switch so the pill recolors live; the shopt guard makes that a
# no-op in shells that never ran nvim-bash.
__nvim_bash_rebind() {
  shopt -qo vi || return 0
  local ins cmd dark='38;2;17;17;27'
  if [[ ${PROMPT_COMMAND:-} == *__sd_prompt_command* ]]; then
    ins=$(__nvim_bash_accent "${__sd_c_staged:-}" '38;2;166;227;161')
    cmd=$(__nvim_bash_accent "${__sd_c_user:-}" '38;2;203;166;247')
  else
    ins=$(__nvim_bash_accent "${__tc_fg_green:-}" '38;2;166;227;161')
    cmd=$(__nvim_bash_accent "${__tc_fg_mauve:-}" '38;2;203;166;247')
    dark=$(__nvim_bash_accent "${__tc_fg_s0:-}" "$dark")
  fi
  bind 'set show-mode-in-prompt on'
  bind "set vi-ins-mode-string \"\1\e[5 q\e[48${ins#38}m\e[${dark}m\e[1m\2 I \1\e[0m\2 \""
  bind "set vi-cmd-mode-string \"\1\e[2 q\e[48${cmd#38}m\e[${dark}m\e[1m\2 N \1\e[0m\2 \""
}

unalias nvim-bash 2>/dev/null
unset '_abbrev_aliases[nvim-bash]' 2>/dev/null
function nvim-bash {
  export EDITOR=nvim
  set -o vi
  if declare -F prompt-tc >/dev/null 2>&1; then
    prompt-tc "$@" || return    # sets the scheme + recolors the pill itself
  fi
  __nvim_bash_rebind            # covers shells without the prompt files
  printf '\e[5 q'               # land in insert: line cursor right away
  echo "vi editing mode on — I/N mode pill in prompt (emacs-bash to undo)"
}

# emacs-bash: undo nvim-bash — emacs editing mode back, mode pill off,
# terminal-default cursor. $EDITOR and the prompt are left alone (prompt-sd
# switches the prompt back if you want that too).
function emacs-bash {
  set -o emacs
  bind 'set show-mode-in-prompt off'
  printf '\e[0 q'
  echo "emacs editing mode restored (mode pill off, default cursor)"
}

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
