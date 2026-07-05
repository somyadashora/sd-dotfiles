#!/bin/bash

# Dotfiles install script
# This script creates symlinks from your home directory to the dotfiles in this repository.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to create symlink
create_symlink() {
    local source=$1
    local target=$2

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "Symlink already exists and points to correct location: $target"
        return
    fi

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up existing file: $target -> $target.backup"
        mv "$target" "$target.backup"
    elif [ -L "$target" ]; then
        echo "Removing existing symlink: $target"
        rm "$target"
    fi

    ln -s "$source" "$target"
    echo "Created symlink: $target -> $source"
}

echo "Installing dotfiles..."

# Bash configuration files
# create_symlink "$DOTFILES_DIR/bash/.bash_rc" "$HOME/.bashrc"

# Neovim configuration
mkdir -p "$HOME/.config"
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Tmux configuration
create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config/tmux"
create_symlink "$DOTFILES_DIR/tmux/scripts" "$HOME/.config/tmux/scripts"

# Lazygit configuration (only the config file — lazygit writes state.yml
# next to it, which must stay local and out of the repo)
mkdir -p "$HOME/.config/lazygit"
create_symlink "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

echo "Dotfiles installation complete!"
echo "You may need to restart your shell or reload your configuration."