#!/usr/bin/env bash

# Pandoc installer for Ubuntu/SUSE (no-sudo, GitHub release) and Termux (pkg).
# Installs the pandoc binary into ~/.local/opt/sd-tools and symlinks into ~/.local/bin.

set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OPT_DIR="${OPT_DIR:-$HOME/.somyadashora/sd-tools}"
GITHUB_API="${GITHUB_API:-https://api.github.com}"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: ./install-pandoc.sh [options]

Options:
  --force    Reinstall even when the detected version is current.
  -h, --help Show this help.

Environment overrides:
  BIN_DIR      Directory for command symlinks. Default: ~/.local/bin
  OPT_DIR      Directory for downloaded tool payloads. Default: ~/.somyadashora/sd-tools
  GITHUB_TOKEN Optional token to avoid GitHub API rate limits.

Platform support:
  - Termux  : uses pkg install pandoc
  - Ubuntu / SUSE / other Linux : downloads the official GitHub release binary (no sudo)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
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

is_termux() {
  have pkg && [[ "${PREFIX:-}" == *"/com.termux/"* ]]
}

host_arch() {
  case "$(uname -m)" in
    x86_64|amd64)   echo amd64 ;;
    aarch64|arm64)  echo arm64 ;;
    armv7l|armv7*)  echo armv7l ;;
    *)              uname -m ;;
  esac
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

strip_v()          { printf '%s' "${1#v}"; }
extract_version()  { grep -Eo '[0-9]+([.][0-9]+)+' | head -n 1; }

version_ge() {
  local have_ver=$1 need_ver=$2
  [[ "$have_ver" == "$need_ver" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$need_ver" "$have_ver" | sort -V | head -n 1)" == "$need_ver" ]]
}

pandoc_installed_version() {
  pandoc --version 2>/dev/null | head -n 1 | extract_version
}

needs_update() {
  local latest_version=$1 installed_version
  [[ "$FORCE" == 1 ]] && return 0
  have pandoc || return 0
  installed_version=$(pandoc_installed_version || true)
  if [[ -z "$installed_version" ]]; then
    warn "Could not detect installed pandoc version; reinstalling."
    return 0
  fi
  if version_ge "$installed_version" "$latest_version"; then
    ok "pandoc is current (${installed_version})."
    return 1
  fi
  log "Updating pandoc: ${installed_version} -> ${latest_version}"
  return 0
}

install_pandoc_termux() {
  log "Termux detected — installing pandoc via pkg"
  pkg install -y pandoc
  ok "pandoc installed via pkg ($(pandoc --version 2>/dev/null | head -n 1 || echo 'unknown version'))."
}

install_pandoc_linux() {
  local arch tag version asset url tmp archive root binary target
  arch=$(host_arch)

  tag=$(latest_tag jgm/pandoc)
  [[ -n "$tag" ]] || die "Could not resolve latest pandoc release."
  version=$(strip_v "$tag")

  needs_update "$version" || return 0

  case "$arch" in
    amd64)  asset="pandoc-${version}-linux-amd64.tar.gz" ;;
    arm64)  asset="pandoc-${version}-linux-arm64.tar.gz" ;;
    armv7l) asset="pandoc-${version}-linux-armv7l.tar.gz" ;;
    *)      die "No pandoc release binary for arch '${arch}'. Install pandoc manually." ;;
  esac

  url="https://github.com/jgm/pandoc/releases/download/${tag}/${asset}"
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/sd-pandoc.XXXXXX")
  archive="$tmp/$asset"

  log "Downloading pandoc ${version} for linux-${arch}"
  github_curl -o "$archive" "$url"

  tar -xzf "$archive" -C "$tmp"
  root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  binary=$(find "$root/bin" -type f -name pandoc -perm /111 2>/dev/null | head -n 1)
  [[ -n "$binary" ]] || die "pandoc archive layout was not recognised (expected bin/pandoc inside ${root})."

  if ! "$binary" --version >/dev/null 2>&1; then
    warn "Downloaded pandoc binary does not run on this host; keeping existing installation."
    rm -rf "$tmp"
    return 0
  fi

  target="$OPT_DIR/pandoc-${version}"
  rm -rf "$target"
  mv "$root" "$target"
  mkdir -p "$BIN_DIR"
  ln -sfn "$target/bin/pandoc" "$BIN_DIR/pandoc"
  # pandoc-lua is bundled since v3; link it if present
  if [[ -x "$target/bin/pandoc-lua" ]]; then
    ln -sfn "$target/bin/pandoc-lua" "$BIN_DIR/pandoc-lua"
  fi

  rm -rf "$tmp"
  ok "Installed pandoc ${version} -> ${BIN_DIR}/pandoc"
}

main() {
  if is_termux; then
    install_pandoc_termux
  else
    [[ "$(uname -s)" == "Linux" ]] || die "This script supports Linux (Ubuntu/SUSE) and Termux only."
    local missing=()
    for tool in curl tar gzip sed grep head; do
      have "$tool" || missing+=("$tool")
    done
    [[ ${#missing[@]} -eq 0 ]] || die "Missing required host tools: ${missing[*]}"
    mkdir -p "$BIN_DIR" "$OPT_DIR"
    install_pandoc_linux
    cat <<EOF

Make sure this is early in PATH:
  export PATH="$BIN_DIR:\$PATH"

Check:
  pandoc --version
EOF
  fi
}

main "$@"
