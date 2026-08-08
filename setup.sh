#!/usr/bin/env bash

set -ue

setfile() {
  local src="$1"
  if [[ $# -gt 1 ]]; then
    local dst="$2"
  else
    local dst="$src"
  fi

  local script_path=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
  if [[ $HOME != $script_path ]]; then
    mkdir -p "$(dirname "$HOME/$dst")"
    if [[ -f "$HOME/$dst" && ! -L "$HOME/$dst" ]]; then
      command mv "$HOME/$dst" "$HOME/$dst.bak"
    fi
    ln -sf "$script_path/$src" "$HOME/$dst"
  fi

}

setfile ".bash_aliases"
if [[ -d .config/fish ]]; then
  find .config/fish -type f -print0 | while IFS= read -r -d '' file; do
    setfile "$file"
  done
fi
setfile ".config/fish/config.fish"

setfile ".claude/settings.json"

setfile ".gitconfig_shared"
# setfile ".gitignore_global"
# git config --global include.path "~/.gitconfig_shared"

mkdir -p ~/.config/git
setfile ".gitignore_global" ".config/git/ignore"

