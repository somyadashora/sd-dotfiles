# common aliases for efficient workflow

# Set SD_NO_ABBREV_ALIAS=1 to disable abbreviation expansion and use plain alias
if [[ "${SD_NO_ABBREV_ALIAS:-0}" == "1" ]] || ! command -v abbrev-alias >/dev/null 2>&1; then
  abbrev-alias() { alias "$@"; }
fi

abbrev-alias ll="ls -lrtha --color=auto"

abbrev-alias tmux-cs="sed -n '/TMUX CHEATSHEET/,/# split panes/p' \$DOTFILES_DIR/tmux/.tmux.conf | sed '\$d'"

abbrev-alias git-cs="grep -E '^\s*[a-z]+\s*=' \$DOTFILES_DIR/git/git-aliases.gitconfig | sed 's/^\s*//' | sed 's/\s*#.*$//' | sed 's/\s*=\s*/ - /' | sort"

# End the range at the first blank line after the block (the cheatsheet is one
# contiguous comment block), not at a prose comment that may get reworded.
abbrev-alias fzf-cs="sed -n '/FZF CHEATSHEET/,/^\$/p' \$DOTFILES_DIR/fzf/fzf.bash | sed '\$d'"

# The range runs to EOF and quits at the first closing rule — a plain
# /start/,/end/ range would RESTART on the second "VIM CHEATSHEET" (the string
# appears again inside the vimrc's own :VimCS function) and print the rest of
# the file. Inside vim the same block renders in a scratch split via :VimCS.
abbrev-alias vim-cs="sed -n '/VIM CHEATSHEET/,\${p;/^\" -\{20,\}\$/q}' \$DOTFILES_DIR/vim/.vimrc | sed 's/^\" \?//' | sed '\$d'"

abbrev-alias rg-cs="sed -n '/RG CHEATSHEET/,/# Case-insensitive/p' \$DOTFILES_DIR/rg/ripgreprc | sed '\$d'"

abbrev-alias watchtty="watch -d -n 1 'ps -f --forest --tty $1'"

abbrev-alias getdotfiles="git -C $DOTFILES_DIR pull --rebase --autostash"

abbrev-alias slang-init="$DOTFILES_DIR/nvim/scripts/slang-init"
abbrev-alias verible-init="$DOTFILES_DIR/nvim/scripts/verible-init"
abbrev-alias init-ai="$DOTFILES_DIR/nvim/scripts/init-ai"

# prompt-tc and prompt-sd (formerly prompt-default) are FUNCTIONS in
# bash/.bash_prompt_tc and bash/.bash_prompt (each takes a color-scheme
# argument; -h lists the schemes: default/catppuccin/monokai-pro/tokyonight/
# material/kanagawa/cyberdream) — aliases here would shadow them, so neither
# lives in this file anymore.

# nvim-bash: put THIS shell into vi editing mode with nvim as $EDITOR and show
# the current vi mode two ways — the readline cursor (\e[5 q blinking bar =
# insert, \e[2 q steady block = normal) and a colored pill at the start of the
# prompt's last line: green " I " while inserting, mauve/purple " N " in
# normal mode. The prompt itself is left alone — the pill works on whichever
# of prompt-sd / prompt-tc / prompt-minimal is active, colored in that
# prompt's current scheme accents (see __nvim_bash_rebind). Both indicators
# ride readline's show-mode-in-prompt strings — the ONLY mechanism that
# live-updates as you hit Esc/i (PS1 is rebuilt once per prompt, so
# PROMPT_COMMAND can't track mode changes). Undo with emacs-bash below. Run
# per-shell; shells that never call nvim-bash are untouched. (Was a plain
# alias; now a function — declared with the `function` keyword + alias/abbrev
# scrub because the old alias may still be live in long-running shells, same
# parse-time expansion trap as prompt-tc.)

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
# prompt's scheme accents — prompt-tc's green/mauve/pill-dark roles, or the
# staged/user roles (crust text) when prompt-sd or prompt-minimal (which
# shares the __sd_c_* palette) owns PROMPT_COMMAND — falling back to
# catppuccin mocha green/mauve/crust when no prompt file is loaded. \1..\2
# wrap the non-printing escapes so prompt width stays correct; both pills
# print the same width (4 cells) so the prompt never shifts on mode change.
# prompt-sd/prompt-tc/prompt-minimal call this after every scheme switch so
# the pill recolors live; the shopt guard makes that a no-op in shells that
# never ran nvim-bash.
__nvim_bash_rebind() {
  shopt -qo vi || return 0
  local ins cmd dark='38;2;17;17;27'
  if [[ ${PROMPT_COMMAND:-} == *__sd_prompt_command* || ${PROMPT_COMMAND:-} == *__mini_prompt_command* ]]; then
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

# __nvim_bash_edit_cmdline: what vi-mode `v` runs instead of readline's stock
# vi-edit-and-execute-command. Stock `v` launches ${VISUAL:-$EDITOR} — the
# full lazy.nvim config, seconds of plugin loading for a one-line edit — and
# executes the result the moment you :wq. This opens `nvim --clean` instead
# (no user config / plugins / shada — starts in milliseconds, still has
# syntax highlighting + sane defaults) and, unlike stock, puts the edited
# text BACK ON THE PROMPT for review instead of running it immediately —
# press Enter to execute. Override the editor with SD_NVIM_BASH_EDITOR
# (word-split, e.g. 'nvim -u ~/nvim-mini.lua'). EDITOR/VISUAL stay untouched,
# so git commit etc. still get the full nvim.
# __nvim_bash_edit_cmdline() {
#   local tmp
#   tmp=$(mktemp "${TMPDIR:-/tmp}/bash-edit.XXXXXX") || return
#   printf '%s\n' "$READLINE_LINE" > "$tmp"
#   ${SD_NVIM_BASH_EDITOR:-nvim --clean} -c 'setf bash' "$tmp" </dev/tty >/dev/tty
#   READLINE_LINE=$(<"$tmp")
#   READLINE_POINT=${#READLINE_LINE}
#   rm -f "$tmp"
# }

unalias nvim-bash 2>/dev/null
unset '_abbrev_aliases[nvim-bash]' 2>/dev/null
function nvim-bash {
  export EDITOR=nvim
  set -o vi
  __nvim_bash_rebind            # pill in the active prompt's scheme accents
  # bind -m vi-command -x '"v": __nvim_bash_edit_cmdline'
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
# output; the $(...)+printf gives exactly one trailing newline.
#   NOTE — this reads the shada FILE, not any live nvim. It does not query a
#   running instance's in-memory register. With two nvim instances open, each
#   holding its own value in reg a, nvim-reg shows neither current value — only
#   what was last written to shada (on a prior exit / :wshada). Once both close,
#   nvim merges shada by timestamp, so the reg a from whichever instance wrote
#   most recently (usually the last to quit) wins. To capture a live instance's
#   register first, run :wshada in it (or query it with a --remote-expr call).
# Examples:
#   nvim-reg        # the unnamed register "  (last yank/delete)
#   nvim-reg 0      # the yank register
#   nvim-reg a      # named register a
nvim-reg() {
    local reg="${1:-\"}" val
    val=$(nvim --headless -u NONE -c "echo getreg('$reg')" -c 'q' 2>&1)
    printf '%s\n' "$val"
}

# nvim-regs: dump ALL registers in one go — the `:registers` table (name +
# preview, control chars shown readably), same shada-file semantics as nvim-reg
# above (last saved session, not any live instance). Optional args restrict it to
# specific registers, exactly like :reg does. Examples:
#   nvim-regs        # every register
#   nvim-regs a0"    # only registers a, 0, and the unnamed "
nvim-regs() {
    local out
    out=$(nvim --headless -u NONE -c "echo execute('registers $*')" -c 'q' 2>&1)
    printf '%s\n' "$out"
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

# __proc_descendants PID -> "PID,child,grandchild,…" (BFS over the process tree);
# used for the tree view when pstree is missing.
__proc_descendants() {
    local queue="$1" all="$1" kids
    while [ -n "$queue" ]; do
        kids=$(ps -o pid= --ppid "${queue// /,}" 2>/dev/null | tr -s ' \n' ' ')
        kids="${kids# }"; kids="${kids% }"
        queue="$kids"
        [ -n "$kids" ] && all="$all $kids"
    done
    echo "${all// /,}"
}

# __watch_ps_frame PID -> one screenful for watch-ps: what the process is doing
# plus its CPU / RAM / disk-I/O and other vitals in plain words, then its ps tree.
# Kept as a function (exported) so watch and the fallback loop share one renderer.
__watch_ps_frame() {
    local pid="$1"
    if ! kill -0 "$pid" 2>/dev/null; then
        printf '  process %s is not running (it exited)\n' "$pid"
        return 0
    fi
    local cores user st pcpu pmem rss etime nlwp ni name
    cores=$(nproc 2>/dev/null || echo '?')
    # comm can (rarely) contain spaces, so read it LAST into $name.
    read -r user st pcpu pmem rss etime nlwp ni name < <(
        ps -o user=,stat=,pcpu=,pmem=,rss=,etime=,nlwp=,ni=,comm= -p "$pid" 2>/dev/null)

    # State letter -> plain words (see ps(1) PROCESS STATE CODES).
    local state
    case "${st:0:1}" in
        R) state="running (using the CPU now)" ;;
        S) state="sleeping (idle, waiting for work)" ;;
        D) state="stuck (uninterruptible — usually waiting on disk/IO)" ;;
        I) state="idle (kernel thread)" ;;
        T) state="stopped (suspended)" ;;
        t) state="stopped (paused by a debugger)" ;;
        Z) state="zombie (finished, waiting to be reaped)" ;;
        X) state="dead" ;;
        *) state="${st:-?}" ;;
    esac
    case "$st" in *+*) state="$state · in the foreground" ;; esac

    # Live CPU%: ps %cpu is a lifetime average (misleading for long-lived apps
    # like nvim), so sample utime+stime from /proc across a short window instead.
    # Falls back to ps %cpu where /proc is absent (non-Linux).
    local cpu_now="$pcpu"
    if [ -r "/proc/$pid/stat" ]; then
        local hz t1 t2
        hz=$(getconf CLK_TCK 2>/dev/null || echo 100)
        t1=$(awk '{print $14+$15}' "/proc/$pid/stat" 2>/dev/null)
        sleep 0.2
        t2=$(awk '{print $14+$15}' "/proc/$pid/stat" 2>/dev/null)
        if [ -n "$t1" ] && [ -n "$t2" ]; then
            cpu_now=$(awk -v d="$((t2 - t1))" -v hz="$hz" 'BEGIN{printf "%.0f", (d/hz)/0.2*100}')
        fi
    fi

    local rss_mb cmdline rbytes wbytes fds cwd
    rss_mb=$(awk -v k="${rss:-0}" 'BEGIN{printf "%.0f", k/1024}')
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null); cmdline="${cmdline% }"
    [ -n "$cmdline" ] || cmdline="$name"
    rbytes=$(awk '/^read_bytes/  {printf "%.1f", $2/1048576}' "/proc/$pid/io" 2>/dev/null)
    wbytes=$(awk '/^write_bytes/ {printf "%.1f", $2/1048576}' "/proc/$pid/io" 2>/dev/null)
    fds=$(ls "/proc/$pid/fd" 2>/dev/null | wc -l | tr -d ' ')
    cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)

    printf '  %s  (pid %s, owner %s)   updated %s\n' "${name:-?}" "$pid" "${user:-?}" "$(date +%H:%M:%S)"
    printf '  ────────────────────────────────────────────────────────────\n'
    printf '  doing:   %s\n' "$state"
    printf '  CPU:     %s%% of one core   (this machine has %s cores)\n' "${cpu_now:-?}" "$cores"
    printf '  RAM:     %s MB held         (%s%% of this machine'\''s memory)\n' "${rss_mb:-?}" "${pmem:-?}"
    printf '  running: %s (h:m:s / d-h:m:s)   niceness %s (lower = higher priority)\n' "${etime:-?}" "${ni:-?}"
    printf '  threads: %s worker thread(s)   ·   %s open file(s)/socket(s)\n' "${nlwp:-?}" "${fds:-?}"
    [ -n "$rbytes$wbytes" ] && \
    printf '  disk:    read %s MB · written %s MB  (since it started)\n' "${rbytes:-0}" "${wbytes:-0}"
    [ -n "$cwd" ] && printf '  in dir:  %s\n' "$cwd"
    printf '  command: %s\n' "$cmdline"
    printf '\n  process tree\n  ────────────────────────────────────────────────────────────\n'
    if command -v pstree >/dev/null 2>&1; then
        pstree -ap "$pid" 2>/dev/null | head -n 40
    else
        ps -f --forest -p "$(__proc_descendants "$pid")" 2>/dev/null | head -n 40
    fi
}

# watch-ps: a live one-process dashboard in the CURRENT terminal — no tmux
# needed (unlike watchlast/watchsys). Shows the process's ps tree plus its CPU,
# RAM, disk I/O and other vitals in plain words, refreshed each second by
# `watch -d` so whatever changed is highlighted. Target by pid or name; with no
# argument it picks the newest interesting (non-shell) process you own. Examples:
#   watch-ps 12345    # that pid
#   watch-ps nvim     # newest process of yours named nvim
#   watch-ps          # newest interesting process you own
watch-ps() {
    local target="${1:-}"
    case "$target" in
        -h|--help) echo "usage: watch-ps [pid|name]   (no arg = newest process you own)"; return 0 ;;
        '')
            target=$(ps -u "$USER" --sort=-start_time -o pid=,comm= 2>/dev/null \
                | awk '$2 !~ /^(bash|zsh|sh|tmux|ps|awk|sshd|watch|sleep|watch-ps)$/ {print $1; exit}')
            [ -n "$target" ] || { echo "watch-ps: no candidate process found" >&2; return 1; } ;;
        *[!0-9]*)
            target=$(pgrep -n -u "$USER" -x "$target" 2>/dev/null || pgrep -n -u "$USER" "$target" 2>/dev/null)
            [ -n "$target" ] || { echo "watch-ps: no process of $USER matches '$1'" >&2; return 1; } ;;
        *)
            kill -0 "$target" 2>/dev/null || { echo "watch-ps: pid $target is not running" >&2; return 1; } ;;
    esac
    # Export the renderer so watch's `bash -c` subshell can call it. Wrapping in
    # `bash -c` (rather than watch -x) means it works whether watch uses sh or
    # bash internally, since the exported function rides in via the environment.
    export -f __watch_ps_frame __proc_descendants
    if command -v watch >/dev/null 2>&1; then
        watch -d -n 1 "bash -c '__watch_ps_frame $target'"
    else
        # No watch(1): plain clear+sleep loop (same info, no change-highlighting).
        while kill -0 "$target" 2>/dev/null; do clear; __watch_ps_frame "$target"; sleep 1; done
        __watch_ps_frame "$target"
    fi
}

# Does this terminal render italics, or fake them? terminfo (what nvim's
# theme.italic_supported reads) only says whether the TERMINAL claims support —
# it cannot see whether the FONT has a real italic face. VTE/GNOME Terminal
# advertises support and then synthesises the slant from the upright glyphs; the
# slant overhangs the character cell and gets clipped, which is what eats the
# tail of a comment in nvim. So: print both and look.
# If the two lines are indistinguishable, or the italic one looks smeared/clipped
# at the right, turn italics off in nvim with <leader>ui (pinned per machine).
italic-check() {
  printf '\nItalic rendering test\n'
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  if command -v tput >/dev/null 2>&1 && tput sitm >/dev/null 2>&1; then
    printf '  terminfo (TERM=%s): sitm present — terminal CLAIMS italic support\n' "$TERM"
  else
    printf '  terminfo (TERM=%s): no sitm — terminal claims NO italic support\n' "$TERM"
  fi
  [ -n "$VTE_VERSION" ] && printf '  VTE_VERSION=%s — VTE fakes italics when the font lacks a face\n' "$VTE_VERSION"
  printf '\n'
  printf '  upright:  // logic [31:0] data_q; typedef enum { A, B } state_e;\n'
  printf '  \e[3mitalic :  // logic [31:0] data_q; typedef enum { A, B } state_e;\e[0m\n'
  printf '\n'
  printf 'Look at the ITALIC line: is it actually slanted, and is the final\n'
  printf 'semicolon fully drawn? Clipped/smeared tail => turn italics off in\n'
  printf 'nvim with <leader>ui (or export SD_ITALICS=0 here).\n\n'
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
