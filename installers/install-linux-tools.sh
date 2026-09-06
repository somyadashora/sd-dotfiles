#!/usr/bin/env bash

# Linux-only, no-sudo installer for this dotfiles/Neovim setup.
# Installs portable tools into ~/.local/opt/sd-tools and symlinks into ~/.local/bin.

# Refuse to run sourced. This script exits on a fatal error, and an `exit` in a
# sourced script kills the shell that sourced it — which from the outside looks
# exactly like the terminal dying on its own. (The transcript redirection in
# start_transcript would outlive the run too.) Checked BEFORE `set -e`, so the
# shell that sourced it is not left with -e — and killed by this very return.
if (return 0 2>/dev/null); then
  printf 'Run this script, do not source it: ./install-linux-tools.sh\n' >&2
  return 2
fi

set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OPT_DIR="${OPT_DIR:-$HOME/.somyadashora/sd-tools}"
FONT_DIR="${FONT_DIR:-$HOME/.local/share/fonts/MesloNerdFonts}"
VERSION_DIR="${OPT_DIR}/.versions"
# Neovim's official Linux tarballs (neovim/neovim) are built against a recent
# glibc. Hosts with an older glibc get the same versions from
# neovim/neovim-releases, which builds against an older glibc.
NVIM_GLIBC_MIN="${NVIM_GLIBC_MIN:-2.34}"
FORCE=0
SKIP_FONTS=0
SKIP_RUSTUP=0
SKIP_HERDR=0
NO_LOG=0
LOG_FILE="${LOG_FILE:-$OPT_DIR/install-linux-tools.log}"
# The option loop below shifts the script's positional parameters, so `$@` is
# empty by the time main runs. Snapshot the invocation for the log header here.
SD_ARGV="$*"

usage() {
  cat <<'USAGE'
Usage: ./install-linux-tools.sh [options]

Options:
  --force       Reinstall tools even when the detected version is current.
  --skip-fonts  Do not install MesloLGS Nerd Font.
  --skip-rustup Do not bootstrap Rust/cargo via rustup when it is needed to
                build the tree-sitter CLI from source.
  --skip-herdr  Do not install herdr or its plugins.
  --no-log      Do not write a transcript of this run to LOG_FILE.
  -h, --help    Show this help.

Environment overrides:
  BIN_DIR       Directory for command symlinks/binaries. Default: ~/.local/bin
  OPT_DIR       Directory for downloaded tool payloads. Default: ~/.local/opt/sd-tools
  FONT_DIR      Directory for Linux user fonts. Default: ~/.local/share/fonts/MesloNerdFonts
  NVIM_GLIBC_MIN  Min host glibc for official neovim/neovim builds. Older hosts
                  fall back to neovim/neovim-releases. Default: 2.34
  LOG_FILE      Transcript of the run. Default: $OPT_DIR/install-linux-tools.log

Notes:
  - This script never uses sudo and never uses system package managers.
  - git and tmux are checked but not built from source; install them separately
    if your Linux host does not already provide them.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --skip-fonts) SKIP_FONTS=1 ;;
    --skip-rustup) SKIP_RUSTUP=1 ;;
    --skip-herdr) SKIP_HERDR=1 ;;
    --no-log) NO_LOG=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "This script is for Linux only."
  if have termux-info || [[ "${PREFIX:-}" == *"/com.termux/"* ]]; then
    die "Termux detected. Use ./install-termux-tools.sh instead."
  fi
}

require_basic_tools() {
  local missing=()
  for tool in curl tar gzip sed grep head chmod find sort; do
    have "$tool" || missing+=("$tool")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "Missing required host tools: ${missing[*]}"
}

# Everything below uses only plain curl/git — no GitHub API, no tokens.
# (api.github.com 403s when rate-limited, and CI/codespace GITHUB_TOKENs are
# repo-scoped and 403 on foreign repos.) If a project moves hosts, only the
# URLs in these helpers/functions need to change.

latest_tag() {
  # `releases/latest` on the plain website 302-redirects to
  # `releases/tag/<TAG>` — same "latest published release" semantics as the
  # API (prereleases/drafts excluded), resolved with a HEAD request. Prints
  # nothing on failure so callers can warn-and-skip under set -e.
  local repo=$1 final
  final=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/${repo}/releases/latest" 2>/dev/null) || true
  case "$final" in
    */releases/tag/*) printf '%s\n' "${final##*/}" ;;
  esac
}

latest_commit() {
  # Plain `git ls-remote` — no GitHub API, so no token/rate-limit trouble
  # (api.github.com 403s when rate-limited, and CI/codespace GITHUB_TOKENs
  # are repo-scoped and 403 on foreign repos). Prints nothing on failure so
  # callers can warn-and-skip instead of dying under set -e.
  local repo=$1 branch=${2:-master}
  git ls-remote "https://github.com/${repo}" "refs/heads/${branch}" 2>/dev/null | cut -f1 || true
}

strip_v() { printf '%s' "${1#v}"; }
extract_version() { grep -Eo '[0-9]+([.][0-9]+)+([+-][A-Za-z0-9._-]+)?' | head -n 1 | sed 's/[+]$//'; }

version_ge() {
  local have_version=$1 need_version=$2
  [[ "$have_version" == "$need_version" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$need_version" "$have_version" | sort -V | head -n 1)" == "$need_version" ]]
}

command_version() {
  local command_name=$1
  case "$command_name" in
    nvim) nvim --version 2>/dev/null | head -n 1 | extract_version ;;
    lazygit) lazygit --version 2>/dev/null | extract_version ;;
    fzf) fzf --version 2>/dev/null | extract_version ;;
    rg) rg --version 2>/dev/null | head -n 1 | extract_version ;;
    fd) fd --version 2>/dev/null | extract_version ;;
    tree-sitter) tree-sitter --version 2>/dev/null | extract_version ;;
    slang-server) slang-server --version 2>/dev/null | extract_version ;;
    tmux) tmux -V 2>/dev/null | extract_version ;;
    # Same reason as sandbox_run: this one runs the INSTALLED herdr, on every
    # subsequent run of this script, before anything else has touched it.
    herdr) sandbox_run 20 herdr --version 2>/dev/null | extract_version ;;
    git) git --version 2>/dev/null | extract_version ;;
    *) "$command_name" --version 2>/dev/null | extract_version ;;
  esac
}

needs_update() {
  local label=$1 command_name=$2 latest=$3 latest_version installed_version
  # Prefer the installer-managed binary in BIN_DIR over whatever else PATH
  # resolves first — a stale manually-installed copy earlier in PATH would
  # otherwise misreport the version and force a re-download every run.
  local PATH="$BIN_DIR:$PATH"
  latest_version=$(strip_v "$latest")
  [[ "$FORCE" == 1 ]] && return 0
  have "$command_name" || return 0
  installed_version=$(command_version "$command_name" || true)
  if [[ -z "$installed_version" ]]; then
    warn "Could not detect ${label} version; reinstalling."
    return 0
  fi
  if version_ge "$installed_version" "$latest_version"; then
    ok "${label} is current (${installed_version})."
    return 1
  fi
  log "Updating ${label}: ${installed_version} -> ${latest_version}"
  return 0
}

needs_exact_tag_update() {
  local label=$1 command_name=$2 latest_tag_value=$3
  # Same BIN_DIR-first lookup as needs_update (see comment there).
  local PATH="$BIN_DIR:$PATH"
  [[ "$FORCE" == 1 ]] && return 0
  have "$command_name" || return 0
  if "$command_name" --version 2>&1 | grep -Fq "$latest_tag_value"; then
    ok "${label} is current (${latest_tag_value})."
    return 1
  fi
  return 0
}

# Make cargo available, bootstrapping a no-sudo Rust toolchain via rustup when
# it is missing (into ~/.cargo and ~/.rustup). Returns non-zero if cargo still
# cannot be found afterwards.
ensure_cargo() {
  have cargo && return 0
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  have cargo && return 0
  [[ "$SKIP_RUSTUP" == 1 ]] && return 1
  log "Bootstrapping Rust/cargo via rustup (no sudo, into ~/.cargo and ~/.rustup)"
  if ! curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --profile minimal; then
    warn "rustup bootstrap failed."
    return 1
  fi
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  have cargo
}

glibc_version() {
  local version=""
  if have getconf; then
    version=$(getconf GNU_LIBC_VERSION 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+' | head -n 1)
  fi
  if [[ -z "$version" ]] && have ldd; then
    version=$(ldd --version 2>/dev/null | head -n 1 | grep -Eo '[0-9]+\.[0-9]+' | head -n 1)
  fi
  printf '%s' "$version"
}

host_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo x86_64 ;;
    aarch64|arm64) echo arm64 ;;
    armv7l|armv7*) echo armv7 ;;
    i386|i686) echo x86 ;;
    *) uname -m ;;
  esac
}

tmpdir() { mktemp -d "${TMPDIR:-/tmp}/sd-linux-tools.XXXXXX"; }
prepare_dirs() { mkdir -p "$BIN_DIR" "$OPT_DIR" "$VERSION_DIR"; }

download() {
  local url=$1 output=$2
  log "Downloading ${url}"
  curl -fsSL -o "$output" "$url"
}

link_binary() {
  local target=$1 name=$2
  mkdir -p "$BIN_DIR"
  ln -sfn "$target" "$BIN_DIR/$name"
}

# `</dev/null` matters as much as the exit status here: this runs a binary that
# was on the internet a second ago, and a probe that finds a terminal to read
# from can sit on it forever instead of answering.
test_binary() { "$1" --version </dev/null >/dev/null 2>&1; }

# herdr is the one tool in this script that IS a terminal multiplexer, so it is
# the one tool that can take the terminal down with it — a run that claims this
# terminal as its controlling tty, or signals the process group the shell lives
# in, closes the window and the scrollback along with it, and `run_step`'s
# subshell cannot help with that (it isolates a failing *function*, not a child
# that kills its terminal). So every herdr invocation goes through here: no
# stdin, so it can never sit on a prompt; a hard timeout, so it can never hang
# the installer; and, where `setsid -w` exists, its own session with no
# controlling terminal, which is what puts this terminal out of its reach.
# `-w` is not optional — a bare `setsid` forks and returns 0 immediately, so
# every success check downstream would believe a step that never ran.
SANDBOX_PROBED=0
SANDBOX_SETSID=0
sandbox_run() {
  local timeout_seconds=$1
  shift
  if (( ! SANDBOX_PROBED )); then
    SANDBOX_PROBED=1
    if have setsid && setsid -w true >/dev/null 2>&1; then
      SANDBOX_SETSID=1
    fi
  fi
  local -a cmd=()
  if (( SANDBOX_SETSID )); then cmd+=(setsid -w); fi
  if have timeout; then cmd+=(timeout -k 10 "$timeout_seconds"); fi
  cmd+=("$@")
  "${cmd[@]}" </dev/null
}

# Terminal scrollback is not evidence you can rely on while a step is capable
# of closing the terminal: the window goes and the output goes with it. The log
# file is still there afterwards.
start_transcript() {
  [[ "$NO_LOG" == 1 ]] && return 0
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || return 0
  printf '\n===== %s | %s =====\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
    >> "$LOG_FILE" 2>/dev/null || return 0
  exec > >(tee -a "$LOG_FILE") 2>&1
  log "Transcript of this run: ${LOG_FILE}"
}

skip_incompatible_binary() {
  local label=$1
  local tmp=$2
  warn "Downloaded ${label} binary does not run on this host; keeping existing installation."
  rm -rf "$tmp"
}

install_nvim() {
  local arch=$1 repo glibc tag version asset url tmp archive root target
  repo="neovim/neovim"
  glibc=$(glibc_version)
  if [[ -n "$glibc" ]] && ! version_ge "$glibc" "$NVIM_GLIBC_MIN"; then
    repo="neovim/neovim-releases"
    log "Host glibc ${glibc} < ${NVIM_GLIBC_MIN}; using ${repo} for older-glibc builds."
  elif [[ -z "$glibc" ]]; then
    warn "Could not detect glibc version; using ${repo} (newer-glibc builds)."
  fi
  tag=$(latest_tag "$repo")
  [[ -n "$tag" ]] || die "Could not resolve latest Neovim release."
  needs_update neovim nvim "$tag" || return 0
  case "$arch" in
    x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
    arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *) warn "No Neovim Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  version=$(strip_v "$tag")
  url="https://github.com/${repo}/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  [[ -n "$root" && -x "$root/bin/nvim" ]] || die "Neovim archive layout was not recognized."
  if ! test_binary "$root/bin/nvim"; then
    skip_incompatible_binary neovim "$tmp"
    return 0
  fi
  target="$OPT_DIR/neovim-$version"
  rm -rf "$target"
  mv "$root" "$target"
  link_binary "$target/bin/nvim" nvim
  rm -rf "$tmp"
  ok "Installed neovim ${version}."
}

install_lazygit() {
  local arch=$1 tag version goarch asset url tmp archive target
  tag=$(latest_tag jesseduffield/lazygit)
  [[ -n "$tag" ]] || die "Could not resolve latest lazygit release."
  needs_update lazygit lazygit "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in x86_64) goarch=x86_64 ;; arm64) goarch=arm64 ;; *) warn "No lazygit Linux asset for ${arch}; skipping."; return 0 ;; esac
  asset="lazygit_${version}_linux_${goarch}.tar.gz"
  url="https://github.com/jesseduffield/lazygit/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  [[ -x "$tmp/lazygit" ]] || die "lazygit archive layout was not recognized."
  if ! test_binary "$tmp/lazygit"; then
    skip_incompatible_binary lazygit "$tmp"
    return 0
  fi
  target="$OPT_DIR/lazygit-$version"
  mkdir -p "$target"
  mv "$tmp/lazygit" "$target/lazygit"
  link_binary "$target/lazygit" lazygit
  rm -rf "$tmp"
  ok "Installed lazygit ${version}."
}

install_fzf() {
  local arch=$1 tag version fzf_arch asset url tmp archive target
  tag=$(latest_tag junegunn/fzf)
  [[ -n "$tag" ]] || die "Could not resolve latest fzf release."
  needs_update fzf fzf "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in x86_64) fzf_arch=amd64 ;; arm64) fzf_arch=arm64 ;; armv7) fzf_arch=armv7 ;; *) warn "No fzf Linux asset for ${arch}; skipping."; return 0 ;; esac
  asset="fzf-${version}-linux_${fzf_arch}.tar.gz"
  url="https://github.com/junegunn/fzf/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  [[ -x "$tmp/fzf" ]] || die "fzf archive layout was not recognized."
  if ! test_binary "$tmp/fzf"; then
    skip_incompatible_binary fzf "$tmp"
    return 0
  fi
  target="$OPT_DIR/fzf-$version"
  mkdir -p "$target"
  mv "$tmp/fzf" "$target/fzf"
  link_binary "$target/fzf" fzf
  rm -rf "$tmp"
  ok "Installed fzf ${version}."
}

install_ripgrep() {
  local arch=$1 tag version triple asset url tmp archive root target binary
  tag=$(latest_tag BurntSushi/ripgrep)
  [[ -n "$tag" ]] || die "Could not resolve latest ripgrep release."
  needs_update ripgrep rg "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in
    x86_64) triple=x86_64-unknown-linux-musl ;;
    arm64) triple=aarch64-unknown-linux-gnu ;;
    *) warn "No ripgrep Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  asset="ripgrep-${version}-${triple}.tar.gz"
  url="https://github.com/BurntSushi/ripgrep/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  binary=$(find "$root" -type f -name rg -perm /111 | head -n 1)
  [[ -n "$binary" ]] || die "ripgrep archive layout was not recognized."
  if ! test_binary "$binary"; then
    skip_incompatible_binary ripgrep "$tmp"
    return 0
  fi
  target="$OPT_DIR/ripgrep-$version"
  rm -rf "$target"
  mv "$root" "$target"
  link_binary "$target/rg" rg
  rm -rf "$tmp"
  ok "Installed ripgrep ${version}."
}

install_fd() {
  local arch=$1 tag version triple asset url tmp archive root target binary
  tag=$(latest_tag sharkdp/fd)
  [[ -n "$tag" ]] || die "Could not resolve latest fd release."
  needs_update fd fd "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in
    x86_64) triple=x86_64-unknown-linux-musl ;;
    arm64) triple=aarch64-unknown-linux-musl ;;
    *) warn "No fd Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  asset="fd-${tag}-${triple}.tar.gz"
  url="https://github.com/sharkdp/fd/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  binary=$(find "$root" -type f -name fd -perm /111 | head -n 1)
  [[ -n "$binary" ]] || die "fd archive layout was not recognized."
  if ! test_binary "$binary"; then
    skip_incompatible_binary fd "$tmp"
    return 0
  fi
  target="$OPT_DIR/fd-$version"
  rm -rf "$target"
  mv "$root" "$target"
  link_binary "$target/fd" fd
  rm -rf "$tmp"
  ok "Installed fd ${version}."
}

install_tree_sitter() {
  local arch=$1 tag version asset url tmp archive binary target
  tag=$(latest_tag tree-sitter/tree-sitter)
  [[ -n "$tag" ]] || die "Could not resolve latest tree-sitter release."
  needs_update tree-sitter tree-sitter "$tag" || return 0
  version=$(strip_v "$tag")

  # Prefer the prebuilt binary (no cargo/compiler needed); these ship as a
  # single gzipped executable.
  case "$arch" in
    x86_64) asset="tree-sitter-linux-x64.gz" ;;
    arm64) asset="tree-sitter-linux-arm64.gz" ;;
    armv7) asset="tree-sitter-linux-arm.gz" ;;
    x86) asset="tree-sitter-linux-x86.gz" ;;
    *) asset="" ;;
  esac
  if [[ -n "$asset" ]]; then
    url="https://github.com/tree-sitter/tree-sitter/releases/download/${tag}/${asset}"
    tmp=$(tmpdir); archive="$tmp/$asset"
    download "$url" "$archive"
    gzip -d "$archive"
    binary="${archive%.gz}"
    chmod +x "$binary"
    if test_binary "$binary"; then
      target="$OPT_DIR/tree-sitter-$version"
      mkdir -p "$target"
      mv "$binary" "$target/tree-sitter"
      link_binary "$target/tree-sitter" tree-sitter
      rm -rf "$tmp"
      ok "Installed tree-sitter ${version}."
      return 0
    fi
    skip_incompatible_binary tree-sitter "$tmp"
  fi

  # Fallback: build from source with cargo when no prebuilt binary fits
  # (e.g. host glibc is older than the prebuilt binary requires). Bootstraps
  # rustup if cargo is missing, since a cargo build links against the host's
  # own glibc and runs anywhere.
  if ensure_cargo; then
    log "Installing tree-sitter CLI ${version} with cargo --no-default-features"
    CARGO_INSTALL_ROOT="$HOME/.local" cargo install --locked --no-default-features "tree-sitter-cli@${version}"
    ok "Installed tree-sitter ${version}."
  else
    warn "No usable prebuilt tree-sitter binary for ${arch} and cargo is unavailable; skipping."
  fi
}

install_slang_server() {
  local arch=$1 tag version asset url tmp archive target binary
  local candidates=()
  tag=$(latest_tag hudson-trading/slang-server)
  [[ -n "$tag" ]] || { warn "Could not resolve latest slang-server release; skipping."; return 0; }
  needs_update slang-server slang-server "$tag" || return 0
  version=$(strip_v "$tag")
  # Asset names changed in v0.2.8: linux-x64-gcc.tar.gz -> linux-x64.tar.gz,
  # plus an old-linux build (older glibc) and an arm64 build. Try candidates
  # in order until one both downloads and runs on this host, so upstream
  # renames degrade to the next candidate instead of failing the tool.
  case "$arch" in
    x86_64) candidates=(slang-server-linux-x64.tar.gz slang-server-old-linux-x64-gcc.tar.gz slang-server-linux-x64-gcc.tar.gz) ;;
    arm64)  candidates=(slang-server-linux-arm64.tar.gz) ;;
    *) warn "No slang-server Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  binary=""
  for asset in "${candidates[@]}"; do
    url="https://github.com/hudson-trading/slang-server/releases/download/${tag}/${asset}"
    tmp=$(tmpdir); archive="$tmp/$asset"
    log "Downloading ${url}"
    curl -fsSL -o "$archive" "$url" || { rm -rf "$tmp"; continue; }
    tar -xzf "$archive" -C "$tmp"
    [[ -x "$tmp/slang-server" ]] || { warn "slang-server archive layout not recognized (${asset})."; rm -rf "$tmp"; continue; }
    if test_binary "$tmp/slang-server"; then
      binary="$tmp/slang-server"
      break
    fi
    warn "slang-server from ${asset} does not run on this host; trying next candidate."
    rm -rf "$tmp"
  done
  [[ -n "$binary" ]] || { warn "No usable slang-server asset for this host; skipping."; return 0; }
  target="$OPT_DIR/slang-server-$version"
  mkdir -p "$target"
  mv "$binary" "$target/slang-server"
  link_binary "$target/slang-server" slang-server
  rm -rf "$tmp"
  ok "Installed slang-server ${version}."
}

install_delta() {
  local arch=$1 tag version triple asset url tmp archive root target binary
  tag=$(latest_tag dandavison/delta)
  [[ -n "$tag" ]] || die "Could not resolve latest delta release."
  needs_update delta delta "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in
    x86_64) triple=x86_64-unknown-linux-musl ;;
    arm64)  triple=aarch64-unknown-linux-gnu ;;
    *) warn "No delta Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  asset="delta-${version}-${triple}.tar.gz"
  url="https://github.com/dandavison/delta/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  binary=$(find "$root" -type f -name delta -perm /111 | head -n 1)
  [[ -n "$binary" ]] || die "delta archive layout was not recognized."
  if ! test_binary "$binary"; then
    skip_incompatible_binary delta "$tmp"
    return 0
  fi
  target="$OPT_DIR/delta-$version"
  rm -rf "$target"
  mv "$root" "$target"
  link_binary "$target/delta" delta
  rm -rf "$tmp"
  ok "Installed delta ${version}."
}

install_bat() {
  local arch=$1 tag version triple asset url tmp archive root target binary
  tag=$(latest_tag sharkdp/bat)
  [[ -n "$tag" ]] || die "Could not resolve latest bat release."
  needs_update bat bat "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in
    x86_64) triple=x86_64-unknown-linux-musl ;;
    arm64)  triple=aarch64-unknown-linux-gnu ;;
    *) warn "No bat Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  asset="bat-${tag}-${triple}.tar.gz"
  url="https://github.com/sharkdp/bat/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  binary=$(find "$root" -type f -name bat -perm /111 | head -n 1)
  [[ -n "$binary" ]] || die "bat archive layout was not recognized."
  if ! test_binary "$binary"; then
    skip_incompatible_binary bat "$tmp"
    return 0
  fi
  target="$OPT_DIR/bat-$version"
  rm -rf "$target"
  mv "$root" "$target"
  link_binary "$target/bat" bat
  rm -rf "$tmp"
  ok "Installed bat ${version}."
}

# One .tmTheme per bash prompt scheme (see __sd_apply_bat_theme in
# bash/.bash_prompt, which maps BAT_THEME to these): catppuccin (mocha),
# tokyonight (storm — the variant the prompt palette mirrors), kanagawa
# (wave), cyberdream, material (base16 palenight port — material styles share
# their accent colors, only backgrounds differ). monokai-pro needs no
# download: it maps to bat's built-in "Monokai Extended" (Monokai Pro itself
# is proprietary, no free tmTheme exists).
install_bat_themes() {
  local themes_dir spec repo branch path file name sha marker url changed=0
  command -v bat >/dev/null 2>&1 || { warn "bat not on PATH; skipping bat themes."; return 0; }
  themes_dir="$(bat --config-dir)/themes"
  mkdir -p "$themes_dir"
  for spec in \
    'catppuccin/bat|main|themes/Catppuccin Mocha.tmTheme|Catppuccin Mocha.tmTheme' \
    'folke/tokyonight.nvim|main|extras/sublime/tokyonight_storm.tmTheme|tokyonight_storm.tmTheme' \
    'obergodmar/kanagawa-tmTheme|master|Kanagawa.tmTheme|Kanagawa.tmTheme' \
    'scottmckendry/cyberdream.nvim|main|extras/textmate/cyberdream.tmTheme|cyberdream.tmTheme' \
    'chriskempson/base16-textmate|master|Themes/base16-material-palenight.tmTheme|base16-material-palenight.tmTheme'
  do
    IFS='|' read -r repo branch path file <<< "$spec"
    name=${file%.tmTheme}
    sha=$(latest_commit "$repo" "$branch")
    [[ -n "$sha" ]] || { warn "Could not resolve ${repo} commit; skipping bat theme ${name}."; continue; }
    marker="$VERSION_DIR/bat-theme-${name// /-}"
    if [[ "$FORCE" != 1 && -f "$marker" && "$(cat "$marker")" == "$sha" && -f "$themes_dir/$file" ]]; then
      ok "bat theme ${name} is current (${sha:0:7})."
      continue
    fi
    url="https://raw.githubusercontent.com/${repo}/${sha}/${path// /%20}"
    log "Installing bat theme ${name} (${sha:0:7})"
    # Plain curl: raw.githubusercontent.com needs no auth, and a scoped
    # GITHUB_TOKEN header can actively break it.
    curl -fsSL -o "$themes_dir/$file" "$url" || { warn "Download failed for bat theme ${name}; skipping."; continue; }
    printf '%s\n' "$sha" > "$marker"
    changed=1
  done
  # Upstream fix-up (idempotent; runs even when the theme was already
  # current): Kanagawa ships gutterForeground #2A2A37 (sumiInk4) — bat's
  # line numbers render invisible against a dark terminal. Lift just the
  # gutter to sumiInk6 #54546D (what nvim's kanagawa uses for LineNr); the
  # theme's other #2A2A37 use (invisibles) is meant to stay dim.
  if [[ -f "$themes_dir/Kanagawa.tmTheme" ]] \
      && grep -A1 '<key>gutterForeground</key>' "$themes_dir/Kanagawa.tmTheme" | grep -q '#2A2A37'; then
    sed -i '/<key>gutterForeground<\/key>/{n;s/#2A2A37/#54546D/;}' "$themes_dir/Kanagawa.tmTheme"
    changed=1
  fi
  if [[ "$changed" == 1 ]]; then
    bat cache --build >/dev/null
    ok "Rebuilt bat's theme cache."
  fi
}

install_abbrev_alias() {
  local sha marker dest url
  sha=$(latest_commit momo-lab/bash-abbrev-alias master)
  [[ -n "$sha" ]] || { warn "Could not resolve bash-abbrev-alias commit; skipping."; return 0; }
  marker="$VERSION_DIR/abbrev-alias"
  dest="$OPT_DIR/abbrev-alias/abbrev-alias.plugin.bash"
  if [[ "$FORCE" != 1 && -f "$marker" && "$(cat "$marker")" == "$sha" ]]; then
    ok "bash-abbrev-alias is current (${sha:0:7})."
    return 0
  fi
  url="https://raw.githubusercontent.com/momo-lab/bash-abbrev-alias/${sha}/abbrev-alias.plugin.bash"
  log "Installing bash-abbrev-alias (${sha:0:7})"
  mkdir -p "$OPT_DIR/abbrev-alias"
  curl -fsSL -o "$dest" "$url" || { warn "Download failed for bash-abbrev-alias; skipping."; return 0; }
  printf '%s\n' "$sha" > "$marker"
  ok "Installed bash-abbrev-alias (${sha:0:7})."
}

install_fzf_git() {
  local sha marker dest url
  sha=$(latest_commit junegunn/fzf-git.sh main)
  [[ -n "$sha" ]] || { warn "Could not resolve fzf-git.sh commit; skipping."; return 0; }
  marker="$VERSION_DIR/fzf-git"
  dest="$OPT_DIR/fzf-git/fzf-git.sh"
  if [[ "$FORCE" != 1 && -f "$marker" && "$(cat "$marker")" == "$sha" ]]; then
    ok "fzf-git.sh is current (${sha:0:7})."
    return 0
  fi
  url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/${sha}/fzf-git.sh"
  log "Installing fzf-git.sh (${sha:0:7})"
  mkdir -p "$OPT_DIR/fzf-git"
  curl -fsSL -o "$dest" "$url" || { warn "Download failed for fzf-git.sh; skipping."; return 0; }
  printf '%s\n' "$sha" > "$marker"
  ok "Installed fzf-git.sh (${sha:0:7})."
}

# herdr publishes its own release manifest at herdr.dev/latest.json — the same
# one `herdr update` reads — carrying the version, a download URL per target and
# a SHA-256 per target. Using it keeps this file's rule intact (plain curl, no
# GitHub API, no tokens) AND gets a checksum, which the GitHub-release steps
# above have no equivalent for.
#
# Scoped awk rather than a JSON parser (none is guaranteed on these hosts) and
# rather than a bare grep: the manifest's `notes` field is a long release-notes
# blob on one line that mentions target names in prose, so the search has to be
# confined to the assets/sha256 objects. Same approach as herdr's own installer.
herdr_manifest_field() {
  local manifest=$1 section=$2 target=$3
  printf '%s\n' "$manifest" | awk -v section="\"${section}\"" -v target="\"${target}\"" '
    $0 ~ "^[[:space:]]*" section "[[:space:]]*:" { inside = 1; next }
    inside && /^[[:space:]]*}/ { exit }
    inside && index($0, target) {
      sub(/^.*:[[:space:]]*"/, "")
      sub(/".*$/, "")
      print
      exit
    }'
}

install_herdr() {
  local arch=$1 target manifest version url sha tmp binary dest
  case "$arch" in
    x86_64) target=linux-x86_64 ;;
    arm64)  target=linux-aarch64 ;;
    *) warn "No herdr Linux build for ${arch}; skipping."; return 0 ;;
  esac
  # curl's own message is the whole diagnosis here and used to be thrown away
  # with 2>/dev/null. "Could not reach herdr.dev" is true of an offline laptop,
  # a corporate proxy, and an intercepting TLS middlebox alike, and the fix is
  # different for each -- so keep what curl said, and its exit code, which
  # names the layer that failed.
  local curl_err rc=0
  curl_err=$(mktemp "${TMPDIR:-/tmp}/sd-herdr-curl.XXXXXX")
  manifest=$(curl -fsSL --retry 3 --connect-timeout 10 --max-time 20 \
    "https://herdr.dev/latest.json" 2>"$curl_err") || rc=$?
  if [[ -z "$manifest" ]]; then
    warn "Could not reach https://herdr.dev/latest.json (curl exit ${rc}); skipping herdr."
    if [[ -s "$curl_err" ]]; then
      warn "curl said: $(tr -d '\r' < "$curl_err" | head -n 2 | tr '\n' ' ')"
    fi
    case "$rc" in
      6)  warn "Exit 6 is DNS: herdr.dev did not resolve. Offline, split-horizon DNS, or a network that only reaches the internet through a proxy." ;;
      7)  warn "Exit 7 is connect: DNS resolved but the connection was refused or dropped — a firewall or a proxy sits in between." ;;
      28) warn "Exit 28 is timeout: the link is slow, or a proxy is accepting the connection and never answering." ;;
      35|60|77) warn "Exit ${rc} is TLS: an intercepting proxy's CA is most likely missing from this host's trust store." ;;
      22) warn "Exit 22 is HTTP: herdr.dev answered with an error status. The manifest URL may have moved — check https://herdr.dev/latest.json in a browser." ;;
    esac
    warn "Behind a proxy: export https_proxy=... http_proxy=... (curl honours both) and re-run."
    warn "This costs herdr only — every other tool installs regardless, and --skip-herdr silences the step."
    rm -f "$curl_err"
    return 0
  fi
  rm -f "$curl_err"
  version=$(printf '%s\n' "$manifest" | awk -F '"' '/^[[:space:]]*"version"[[:space:]]*:/ { print $4; exit }')
  url=$(herdr_manifest_field "$manifest" assets "$target")
  sha=$(herdr_manifest_field "$manifest" sha256 "$target")
  if [[ -z "$version" || -z "$url" || ${#sha} -ne 64 ]]; then
    warn "herdr manifest did not describe ${target}; skipping."
    return 0
  fi
  needs_update herdr herdr "$version" || return 0
  tmp=$(tmpdir); binary="$tmp/herdr"
  download "$url" "$binary"
  if have sha256sum; then
    if ! printf '%s  %s\n' "$sha" "$binary" | sha256sum -c --status; then
      warn "herdr checksum did not match the manifest; not installing."
      rm -rf "$tmp"
      return 0
    fi
  else
    warn "sha256sum unavailable; installing herdr without verifying the checksum."
  fi
  chmod +x "$binary"
  # herdr is a recent-glibc Rust build; older hosts (ETX/SLES) fall out here and
  # keep whatever they had, with tmux still doing the multiplexing. This is the
  # first time the downloaded binary is ever run, so it goes through the
  # sandbox rather than test_binary (see sandbox_run).
  if ! sandbox_run 20 "$binary" --version >/dev/null 2>&1; then
    skip_incompatible_binary herdr "$tmp"
    return 0
  fi
  dest="$OPT_DIR/herdr-$version"
  rm -rf "$dest"
  mkdir -p "$dest"
  mv "$binary" "$dest/herdr"
  link_binary "$dest/herdr" herdr
  rm -rf "$tmp"
  ok "Installed herdr ${version}."
}

# The four plugins herdr/config.toml binds keys for. Installed the TPM way —
# herdr manages the checkouts under ~/.config/herdr/plugins, nothing is vendored
# here. herdr-nvim and reviewr download a prebuilt binary; navigator and
# spreader build from source with cargo, so those two need rustup to have run.
# Each is guarded, so a missing cargo or a moved repo costs one plugin, not the
# step — a plugin_action keybinding for a plugin that isn't installed is inert,
# not a config error (verified with `herdr config check`).
#
# Every entry is REF-PINNED, the same rule as the bat themes / fzf-git.sh /
# pinned ZMK source: `herdr plugin install` otherwise takes whatever the default
# branch holds today, and the marketplace is explicitly unreviewed. Bump the tag
# and the plugin's keybindings in herdr/config.toml together.
#
# `--yes` is load-bearing: without it a non-interactive install prints
# "remote plugin install requires --yes when stdin is not interactive" and
# EXITS 0, so the step would report success having installed nothing. That is
# also why success is confirmed against `herdr plugin list` rather than $?.
install_herdr_plugins() {
  local entry repo ref id plugin_log missing=()
  local log_dir="$OPT_DIR/herdr-logs"
  have herdr || { warn "herdr not on PATH; skipping herdr plugins."; return 0; }
  mkdir -p "$log_dir"
  for entry in \
    'thanhdat77/herdr-navigator|v0.3.6|herdr-navigator' \
    'ChmaraX/herdr-nvim|v1.0.0|chmarax.herdr-nvim' \
    'persiyanov/herdr-reviewr|v0.36.2|persiyanov.reviewr' \
    'yuk1ty/herdr-spreader|v0.2.1|herdr-spreader'
  do
    IFS='|' read -r repo ref id <<<"$entry"
    if [[ "$FORCE" != 1 ]] && sandbox_run 60 herdr plugin list 2>/dev/null | grep -Fq "$id"; then
      ok "herdr plugin ${id} already installed."
      continue
    fi
    log "Installing herdr plugin ${id} (${ref})"
    # navigator and spreader build with cargo, so the timeout has to allow for
    # a cold compile. Output is kept rather than discarded: a plugin that fails
    # says why here, and this is the only place it says it.
    plugin_log="$log_dir/${id}.log"
    sandbox_run 1800 herdr plugin install "$repo" --ref "$ref" --yes \
      >"$plugin_log" 2>&1 || true
    if sandbox_run 60 herdr plugin list 2>/dev/null | grep -Fq "$id"; then
      ok "Installed herdr plugin ${id}."
    else
      missing+=("$id")
      warn "herdr plugin ${id} did not install; last lines of ${plugin_log}:"
      tail -n 15 "$plugin_log" 2>/dev/null | sed 's/^/    /' >&2 || true
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    warn "herdr plugins not installed: ${missing[*]} (their keybindings stay inert)."
    warn "herdr-navigator and herdr-spreader build with cargo — re-run this script once rustup has provided it."
  fi
}

install_verible() {
  local arch=$1 tag asset url tmp archive root target tool
  tag=$(latest_tag chipsalliance/verible)
  [[ -n "$tag" ]] || die "Could not resolve latest Verible release."
  needs_exact_tag_update verible verible-verilog-ls "$tag" || return 0
  case "$arch" in
    x86_64) asset="verible-${tag}-linux-static-x86_64.tar.gz" ;;
    arm64) asset="verible-${tag}-linux-static-arm64.tar.gz" ;;
    *) warn "No Verible Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  url="https://github.com/chipsalliance/verible/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  [[ -x "$root/bin/verible-verilog-ls" ]] || die "Verible archive layout was not recognized."
  if ! test_binary "$root/bin/verible-verilog-ls"; then
    skip_incompatible_binary verible "$tmp"
    return 0
  fi
  target="$OPT_DIR/verible-$tag"
  rm -rf "$target"
  mv "$root" "$target"
  for tool in "$target/bin"/*; do
    [[ -x "$tool" && -f "$tool" ]] || continue
    link_binary "$tool" "$(basename "$tool")"
  done
  rm -rf "$tmp"
  ok "Installed Verible ${tag}."
}

install_meslo_font() {
  [[ "$SKIP_FONTS" == 1 ]] && return 0

  local tag version marker url tmp archive
  tag=$(latest_tag ryanoasis/nerd-fonts)
  [[ -n "$tag" ]] || die "Could not resolve latest Nerd Fonts release."
  version=$(strip_v "$tag")
  marker="$VERSION_DIR/meslo-nerd-font"
  if [[ "$FORCE" != 1 && -f "$marker" && "$(cat "$marker")" == "$tag" ]]; then
    ok "MesloLGS Nerd Font is current (${version})."
    return 0
  fi

  log "Installing MesloLGS Nerd Font ${version}"
  tmp=$(tmpdir); archive="$tmp/Meslo.tar.xz"
  download "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/Meslo.tar.xz" "$archive"
  mkdir -p "$tmp/Meslo" "$FONT_DIR"
  tar -xJf "$archive" -C "$tmp/Meslo"
  find "$tmp/Meslo" -type f -name '*.ttf' -exec cp {} "$FONT_DIR" \;
  if have fc-cache; then
    fc-cache -f "$FONT_DIR"
  else
    warn "fc-cache not found; copied fonts but did not refresh font cache."
  fi
  printf '%s\n' "$tag" > "$marker"
  rm -rf "$tmp"
  ok "Installed MesloLGS Nerd Font ${version}."
}

check_existing_only_tools() {
  for tool in git tmux; do
    if have "$tool"; then
      ok "$tool available ($(command_version "$tool" || echo unknown))."
    else
      warn "$tool is missing. This no-sudo script does not build/install $tool from source."
    fi
  done
}

# Isolate each tool: run the step in a subshell so any failure — including
# an explicit `die` inside the function — skips only that tool instead of
# aborting the whole installer (one 404 must never block the tools after it).
FAILED_STEPS=()
run_step() {
  local step=$1
  shift
  if ! ( "$step" "$@" ); then
    warn "${step#install_} failed; continuing with the remaining tools."
    FAILED_STEPS+=("${step#install_}")
  fi
}

main() {
  local arch
  require_linux
  require_basic_tools
  prepare_dirs
  start_transcript "$0 $SD_ARGV"
  arch=$(host_arch)
  log "Detected Linux/${arch}; installing into ${OPT_DIR} and ${BIN_DIR}"

  run_step install_nvim "$arch"
  run_step install_lazygit "$arch"
  run_step install_fzf "$arch"
  run_step install_ripgrep "$arch"
  run_step install_fd "$arch"
  run_step install_tree_sitter "$arch"
  run_step install_slang_server "$arch"
  run_step install_delta "$arch"
  run_step install_bat "$arch"
  run_step install_bat_themes
  run_step install_abbrev_alias
  run_step install_fzf_git
  run_step install_verible "$arch"
  if [[ "$SKIP_HERDR" == 1 ]]; then
    warn "Skipping herdr and its plugins (--skip-herdr)."
  else
    run_step install_herdr "$arch"
    run_step install_herdr_plugins
  fi
  run_step install_meslo_font
  run_step check_existing_only_tools

  if (( ${#FAILED_STEPS[@]} > 0 )); then
    warn "Finished with failed steps: ${FAILED_STEPS[*]} (everything else installed)."
  fi
  [[ "$NO_LOG" == 1 ]] || log "Full transcript: ${LOG_FILE}"

  cat <<EOF_STATUS

Done.

Make sure this is early in PATH:
  export PATH="$BIN_DIR:\$PATH"

Useful checks:
  nvim --version | head -n 1
  lazygit --version
  fzf --version
  rg --version | head -n 1
  fd --version
  tree-sitter --version
  slang-server --version
  delta --version
  bat --version
  verible-verilog-ls --version
  herdr --version
  herdr plugin list          # navigator / herdr-nvim / reviewr / spreader
  # bash-abbrev-alias: source \$HOME/.somyadashora/sd-tools/abbrev-alias/abbrev-alias.plugin.bash
  # fzf-git.sh: sourced by fzf/fzf.bash from \$HOME/.somyadashora/sd-tools/fzf-git/fzf-git.sh (Ctrl-G pickers)
  bat --list-themes | grep -E 'Catppuccin|tokyonight|Kanagawa|cyberdream|palenight'  # prompt-scheme bat themes
  tmux -V
  git --version
EOF_STATUS
}

main "$@"
