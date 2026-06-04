#!/usr/bin/env bash

# Linux-only, no-sudo installer for this dotfiles/Neovim setup.
# Installs portable tools into ~/.local/opt/sd-tools and symlinks into ~/.local/bin.

set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OPT_DIR="${OPT_DIR:-$HOME/.somyadashora/sd-tools}"
FONT_DIR="${FONT_DIR:-$HOME/.local/share/fonts/MesloNerdFonts}"
VERSION_DIR="${OPT_DIR}/.versions"
GITHUB_API="${GITHUB_API:-https://api.github.com}"
FORCE=0
SKIP_FONTS=0

usage() {
  cat <<'USAGE'
Usage: ./install-linux-tools.sh [options]

Options:
  --force       Reinstall tools even when the detected version is current.
  --skip-fonts  Do not install MesloLGS Nerd Font.
  -h, --help    Show this help.

Environment overrides:
  BIN_DIR       Directory for command symlinks/binaries. Default: ~/.local/bin
  OPT_DIR       Directory for downloaded tool payloads. Default: ~/.local/opt/sd-tools
  FONT_DIR      Directory for Linux user fonts. Default: ~/.local/share/fonts/MesloNerdFonts
  GITHUB_TOKEN  Optional token to avoid GitHub API rate limits.

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

github_curl() {
  local args=(-fsSL)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  curl "${args[@]}" "$@"
}

latest_tag() {
  local repo=$1
  github_curl "${GITHUB_API}/repos/${repo}/releases/latest" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

latest_commit() {
  local repo=$1 branch=${2:-master}
  github_curl "${GITHUB_API}/repos/${repo}/commits/${branch}" \
    | sed -n 's/.*"sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
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
    git) git --version 2>/dev/null | extract_version ;;
    *) "$command_name" --version 2>/dev/null | extract_version ;;
  esac
}

needs_update() {
  local label=$1 command_name=$2 latest=$3 latest_version installed_version
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
  [[ "$FORCE" == 1 ]] && return 0
  have "$command_name" || return 0
  if "$command_name" --version 2>&1 | grep -Fq "$latest_tag_value"; then
    ok "${label} is current (${latest_tag_value})."
    return 1
  fi
  return 0
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
  github_curl -o "$output" "$url"
}

link_binary() {
  local target=$1 name=$2
  mkdir -p "$BIN_DIR"
  ln -sfn "$target" "$BIN_DIR/$name"
}

test_binary() { "$1" --version >/dev/null 2>&1; }

skip_incompatible_binary() {
  local label=$1
  local tmp=$2
  warn "Downloaded ${label} binary does not run on this host; keeping existing installation."
  rm -rf "$tmp"
}

install_nvim() {
  local arch=$1 tag version asset url tmp archive root target
  tag=$(latest_tag neovim/neovim)
  [[ -n "$tag" ]] || die "Could not resolve latest Neovim release."
  needs_update neovim nvim "$tag" || return 0
  case "$arch" in
    x86_64) asset="nvim-linux-x86_64.tar.gz" ;;
    arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *) warn "No Neovim Linux asset for ${arch}; skipping."; return 0 ;;
  esac
  version=$(strip_v "$tag")
  url="https://github.com/neovim/neovim/releases/download/${tag}/${asset}"
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
  local tag version
  tag=$(latest_tag tree-sitter/tree-sitter)
  [[ -n "$tag" ]] || die "Could not resolve latest tree-sitter release."
  needs_update tree-sitter tree-sitter "$tag" || return 0
  version=$(strip_v "$tag")
  if have cargo; then
    log "Installing tree-sitter CLI ${version} with cargo --no-default-features"
    CARGO_INSTALL_ROOT="$HOME/.local" cargo install --locked --no-default-features "tree-sitter-cli@${version}"
    ok "Installed tree-sitter ${version}."
  else
    warn "cargo is missing; cannot install tree-sitter CLI without sudo on this host."
  fi
}

install_slang_server() {
  local arch=$1 tag version asset url tmp archive target binary
  tag=$(latest_tag hudson-trading/slang-server)
  [[ -n "$tag" ]] || die "Could not resolve latest slang-server release."
  needs_update slang-server slang-server "$tag" || return 0
  version=$(strip_v "$tag")
  case "$arch" in x86_64) asset="slang-server-linux-x64-gcc.tar.gz" ;; *) warn "No slang-server Linux asset for ${arch}; skipping."; return 0 ;; esac
  url="https://github.com/hudson-trading/slang-server/releases/download/${tag}/${asset}"
  tmp=$(tmpdir); archive="$tmp/$asset"
  download "$url" "$archive"
  tar -xzf "$archive" -C "$tmp"
  binary="$tmp/slang-server"
  [[ -x "$binary" ]] || die "slang-server archive layout was not recognized."
  if ! test_binary "$binary"; then
    skip_incompatible_binary slang-server "$tmp"
    return 0
  fi
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
  github_curl -o "$dest" "$url"
  printf '%s\n' "$sha" > "$marker"
  ok "Installed bash-abbrev-alias (${sha:0:7})."
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

main() {
  local arch
  require_linux
  require_basic_tools
  prepare_dirs
  arch=$(host_arch)
  log "Detected Linux/${arch}; installing into ${OPT_DIR} and ${BIN_DIR}"

  install_nvim "$arch"
  install_lazygit "$arch"
  install_fzf "$arch"
  install_ripgrep "$arch"
  install_fd "$arch"
  install_tree_sitter
  install_slang_server "$arch"
  install_delta "$arch"
  install_bat "$arch"
  install_abbrev_alias
  install_verible "$arch"
  install_meslo_font
  check_existing_only_tools

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
  # bash-abbrev-alias: source \$HOME/.somyadashora/sd-tools/abbrev-alias/abbrev-alias.plugin.bash
  tmux -V
  git --version
EOF_STATUS
}

main "$@"
