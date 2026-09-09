#!/usr/bin/env bash
#
# $HOME 内で完結する（= root が要らない）インストール。
# 共用サーバではこれだけを実行すればよい。アカウントごとに毎回実行する。

set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# npm
# prefix を ~/.npm-global にすることで global install に sudo が要らなくなる。
log "npm prefix"
if ! has npm; then
  warn "npm not installed: run install/system.sh first"
else
  mkdir -p "$HOME/.npm-global/bin"
  if [[ "$(npm config get prefix)" == "$HOME/.npm-global" ]]; then
    skip "prefix already set"
  else
    npm config set prefix "$HOME/.npm-global"
  fi
fi

# AWS CLI
# https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html
# インストール先は ~/.local/bin/aws。
log "AWS CLI"
if has aws; then
  skip "$(aws --version 2>&1)"
elif ! curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash; then
  warn "AWS CLI install failed"
fi

# Claude Code
# https://code.claude.com/docs/ja/quickstart
log "Claude Code"
if has claude; then
  skip "$(claude --version)"
elif ! curl -fsSL https://claude.ai/install.sh | bash; then
  warn "Claude Code install failed"
fi

# Codex
# https://learn.chatgpt.com/docs/codex/cli#getting-started
log "Codex"
if has codex; then
  skip "$(codex --version)"
elif ! curl -fsSL https://chatgpt.com/codex/install.sh | sh; then
  warn "Codex install failed"
fi

# Headroom
# https://github.com/headroomlabs-ai/headroom
# Debian/Ubuntu の python は externally-managed なので pipx で入れる。
log "Headroom"
if ! has pipx; then
  warn "pipx not installed: run install/system.sh first"
elif pipx list --short 2>/dev/null | grep -q '^headroom-ai '; then
  skip "headroom-ai already installed"
elif ! pipx install "headroom-ai[all]"; then
  warn "headroom-ai install failed"
fi

# Markdownlint
log "Markdownlint"
if ! has npm; then
  warn "npm not installed: skipping markdownlint-cli2"
elif npm ls -g --depth=0 markdownlint-cli2 >/dev/null 2>&1; then
  skip "markdownlint-cli2 already installed"
elif ! npm install markdownlint-cli2 --global; then
  warn "markdownlint-cli2 install failed"
fi

# MCP
log "MCP: context7"
if ! has codex; then
  skip "codex not installed"
elif codex mcp list 2>/dev/null | grep -q '\bcontext7\b'; then
  skip "codex: context7 already added"
elif ! codex mcp add context7 -- npx -y @upstash/context7-mcp; then
  warn "codex mcp add context7 failed"
fi
if ! has claude; then
  skip "claude not installed"
elif claude mcp list 2>/dev/null | grep -q '^context7:'; then
  skip "claude: context7 already added"
elif ! claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp; then
  warn "claude mcp add context7 failed"
fi

summary "user"
