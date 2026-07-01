#!/data/data/com.termux/files/usr/bin/sh

# Termux-only installer for this dotfiles/Neovim setup.
# Uses Termux packages and never uses sudo.
# Compatible with sh and bash (run as: sh install-termux-tools.sh  OR  ./install-termux-tools.sh)

set -eu

FONT_DIR="${FONT_DIR:-$HOME/.termux}"
NERD_FONT_VERSION_FILE="${FONT_DIR}/.meslo-nerd-font-version"
GITHUB_API="${GITHUB_API:-https://api.github.com}"
FORCE=0
SKIP_FONTS=0

usage() {
  cat <<'USAGE'
Usage: sh install-termux-tools.sh [options]

Options:
  --force       Reinstall/update even if a marker says the font is current.
  --skip-fonts  Do not install MesloLGS Nerd Font into ~/.termux/font.ttf.
  -h, --help    Show this help.

Notes:
  - Installs native Termux packages for nvim, lazygit, fzf, rg, tmux, git,
    fd, tree-sitter, lua-language-server, clang/make, and fontconfig.
  - slang-server and Verible do not currently have official Android/Termux
    release binaries handled by this script.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --skip-fonts) SKIP_FONTS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

require_termux() {
  have pkg || die "This script is for Termux only. Use ./install-linux-tools.sh on normal Linux."
  case "${PREFIX:-}" in
    *"/com.termux/"*) ;;
    *) die "This script is for Termux only. Use ./install-linux-tools.sh on normal Linux." ;;
  esac
}

github_curl() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "$@"
  else
    curl -fsSL "$@"
  fi
}

latest_tag() {
  local repo=$1
  github_curl "${GITHUB_API}/repos/${repo}/releases/latest" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

install_packages() {
  log "Updating Termux repositories and packages"
  pkg update -y
  pkg upgrade -y

  log "Installing Termux-native tools"
  pkg install -y \
    neovim \
    lazygit \
    fzf \
    ripgrep \
    tmux \
    git \
    fd \
    tree-sitter \
    sqlite \
    lua-language-server \
    clang \
    make \
    curl \
    tar \
    gzip \
    xz-utils \
    unzip \
    fontconfig \
    termux-api
}

install_meslo_font() {
  [ "$SKIP_FONTS" = 1 ] && return 0

  local tag version tmp archive font_file
  tag=$(latest_tag ryanoasis/nerd-fonts)
  [ -n "$tag" ] || die "Could not resolve latest Nerd Fonts release."
  version=${tag#v}

  mkdir -p "$FONT_DIR"
  if [ "$FORCE" != 1 ] && [ -f "$NERD_FONT_VERSION_FILE" ] && [ "$(cat "$NERD_FONT_VERSION_FILE")" = "$tag" ]; then
    ok "MesloLGS Nerd Font is current (${version})."
    return 0
  fi

  log "Installing MesloLGS Nerd Font ${version} for Termux"
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/termux-font.XXXXXX")
  archive="$tmp/Meslo.tar.xz"
  github_curl -o "$archive" "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/Meslo.tar.xz"
  mkdir -p "$tmp/Meslo"
  tar -xJf "$archive" -C "$tmp/Meslo"
  font_file=$(find "$tmp/Meslo" -type f -name 'MesloLGSNerdFontMono-Regular.ttf' | head -n 1)
  [ -n "$font_file" ] || die "Could not find MesloLGSNerdFontMono-Regular.ttf in Nerd Font archive."
  cp "$font_file" "$FONT_DIR/font.ttf"
  printf '%s\n' "$tag" > "$NERD_FONT_VERSION_FILE"
  rm -rf "$tmp"

  if have termux-reload-settings; then
    termux-reload-settings
  else
    warn "termux-reload-settings not found; restart Termux to load the font."
  fi
  ok "Installed MesloLGS Nerd Font ${version}."
}

show_status() {
  cat <<'EOF_STATUS'

Useful checks:
  nvim --version | head -n 1
  lazygit --version
  fzf --version
  rg --version | head -n 1
  fd --version
  tmux -V
  git --version
  tree-sitter --version
  lua-language-server --version
EOF_STATUS

  warn "slang-server is skipped on Termux: no official Android/Termux release asset is handled here."
  warn "verible is skipped on Termux: no native Termux package or official Android release asset is handled here."
  warn "termux-api installed — also install the Termux:API companion app (F-Droid/Play Store) for Android clipboard to work in nvim."
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ -d "$tpm_dir/.git" ]; then
    log "Updating TPM"
    git -C "$tpm_dir" pull --ff-only
  else
    log "Installing TPM (Tmux Plugin Manager)"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  ok "TPM installed. Open tmux and press Ctrl+Space+I to install all plugins (catppuccin etc)."
}

main() {
  require_termux
  install_packages
  install_tpm
  install_meslo_font
  show_status
  ok "Termux tool installation complete."
}

main "$@"
