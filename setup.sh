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

setfile ".config/atuin/config.toml"

setfile ".claude/settings.json"
if [[ -d .claude/skills ]]; then
  find .claude/skills -type f -print0 | while IFS= read -r -d '' file; do
    setfile "$file"
    # .agents/skills is read by both Codex and Gemini CLI
    setfile "$file" ".agents/skills/${file#.claude/skills/}"
    # Antigravity CLI (agy) の global skills は別パス。.agents/skills は workspace 用
    setfile "$file" ".gemini/antigravity-cli/skills/${file#.claude/skills/}"
  done
fi

# one source, each agent's global rule path (Codex: AGENTS.md, Claude Code: CLAUDE.md)
setfile ".config/agents/AGENTS.md" ".codex/AGENTS.md"
setfile ".config/agents/AGENTS.md" ".claude/CLAUDE.md"
# Antigravity CLI: global context is ~/.gemini/GEMINI.md
setfile ".config/agents/AGENTS.md" ".gemini/GEMINI.md"

setfile ".markdownlint-cli2.jsonc"

setfile ".mermaid_config.jsonc"

setfile ".gitconfig_shared"
# setfile ".gitignore_global"
# git config --global include.path "~/.gitconfig_shared"

mkdir -p ~/.config/git
setfile ".gitignore_global" ".config/git/ignore"

