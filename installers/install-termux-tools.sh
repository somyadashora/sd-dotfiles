#!/data/data/com.termux/files/usr/bin/sh

# Termux-only installer for this dotfiles/Neovim setup.
# Uses Termux packages and never uses sudo.
# Compatible with sh and bash (run as: sh install-termux-tools.sh  OR  ./install-termux-tools.sh)

set -eu

FONT_DIR="${FONT_DIR:-$HOME/.termux}"
NERD_FONT_VERSION_FILE="${FONT_DIR}/.meslo-nerd-font-version"
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
  - Installs python + poppler, and pip-installs pyyaml/gdown, so sd-vlsi's
    scripts/fetch-refs.py can rehydrate and extract reference PDFs.
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

# Everything below uses only plain curl/git — no GitHub API, no tokens.
# If a project moves hosts, only the URLs here need to change.

latest_tag() {
  # `releases/latest` on the plain website 302-redirects to
  # `releases/tag/<TAG>` — same "latest published release" semantics as the
  # API, resolved with a HEAD request. Prints nothing on failure.
  local repo=$1 final
  final=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/${repo}/releases/latest" 2>/dev/null) || true
  case "$final" in
    */releases/tag/*) printf '%s\n' "${final##*/}" ;;
  esac
}

latest_commit() {
  # Plain `git ls-remote` — no GitHub API, so no token/rate-limit trouble.
  # Prints nothing on failure so callers can warn-and-skip under set -e.
  local repo=$1 branch=$2
  git ls-remote "https://github.com/${repo}" "refs/heads/${branch}" 2>/dev/null | cut -f1 || true
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
    git-delta \
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
    termux-api \
    python \
    python-pip \
    poppler
}

# sd-vlsi keeps reference PDFs out of git and rehydrates them from a manifest
# with scripts/fetch-refs.py, which is Python. poppler supplies the three
# binaries that script shells out to: pdftotext (--extract), pdfimages
# (--extract-images) and pdftoppm (--render-pages). pip is a separate Termux
# package from python, hence both above.
install_refs_python_deps() {
  log "Installing Python packages for the sd-vlsi refs pipeline"
  have python3 || die "python3 not found after installing the python package."
  # Neither has a Termux package -- there is no python-pyyaml in
  # termux-packages, and gdown is pip-only. PyYAML has no Android wheel on
  # PyPI and compiles from source, which is what clang above is for.
  python3 -m pip install --upgrade pyyaml gdown
  ok "pyyaml and gdown installed."
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
  curl -fsSL -o "$archive" "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/Meslo.tar.xz"
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
  pdftotext -v
  python3 -c 'import yaml, gdown; print("refs deps OK")'
EOF_STATUS

  cat <<'EOF_REFS'

sd-vlsi refs pipeline: fetch-refs.py is Python, and Termux has no /usr/bin
for its shebang to resolve against, so call the interpreter explicitly:

  python3 scripts/fetch-refs.py --check
  python3 scripts/fetch-refs.py --extract
EOF_REFS

  warn "herdr is skipped on Termux: it publishes no Android build, and its own installer refuses Android outright. tmux stays the multiplexer here; herdr/config.toml is still symlinked by install.sh so a synced checkout stays consistent."
  warn "slang-server is skipped on Termux: no official Android/Termux release asset is handled here."
  warn "verible is skipped on Termux: no native Termux package or official Android release asset is handled here."
  warn "termux-api installed — also install the Termux:API companion app (F-Droid/Play Store) for Android clipboard to work in nvim."
}

# Same layout as install-linux-tools.sh (OPT_DIR/fzf-git + a commit marker in
# OPT_DIR/.versions), so fzf/fzf.bash finds the script at one path everywhere.
install_fzf_git() {
  local opt_dir sha sha7 marker dest url
  opt_dir="${OPT_DIR:-$HOME/.somyadashora/sd-tools}"
  sha=$(latest_commit junegunn/fzf-git.sh main)
  [ -n "$sha" ] || { warn "Could not resolve fzf-git.sh commit; skipping."; return 0; }
  sha7=$(printf '%.7s' "$sha")
  marker="$opt_dir/.versions/fzf-git"
  dest="$opt_dir/fzf-git/fzf-git.sh"
  if [ "$FORCE" != 1 ] && [ -f "$marker" ] && [ "$(cat "$marker")" = "$sha" ]; then
    ok "fzf-git.sh is current (${sha7})."
    return 0
  fi
  url="https://raw.githubusercontent.com/junegunn/fzf-git.sh/${sha}/fzf-git.sh"
  log "Installing fzf-git.sh (${sha7})"
  mkdir -p "$opt_dir/fzf-git" "$opt_dir/.versions"
  curl -fsSL -o "$dest" "$url" || { warn "Download failed for fzf-git.sh; skipping."; return 0; }
  printf '%s\n' "$sha" > "$marker"
  ok "Installed fzf-git.sh (${sha7})."
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

  ok "TPM installed. Open tmux and press Ctrl+b then Shift+I to install all plugins (catppuccin etc)."
}

# Isolate each tool: run the step in a subshell so any failure (including a
# die inside the function) skips only that tool instead of aborting the rest.
FAILED_STEPS=""
run_step() {
  step=$1
  shift
  if ! ( "$step" "$@" ); then
    warn "${step} failed; continuing with the remaining steps."
    FAILED_STEPS="${FAILED_STEPS} ${step}"
  fi
}

main() {
  require_termux
  install_packages
  run_step install_refs_python_deps
  run_step install_fzf_git
  run_step install_tpm
  run_step install_meslo_font
  show_status
  [ -n "$FAILED_STEPS" ] && warn "Finished with failed steps:${FAILED_STEPS} (everything else installed)."
  ok "Termux tool installation complete."
}

main "$@"
