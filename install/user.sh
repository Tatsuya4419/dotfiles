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

# mq
# https://mqlang.org/
# インストール先は ~/.local/bin。installer は config.fish に PATH 行を追記するので、
# 導入済みならスキップして追記の重複を避ける。
log "mq"
if has mq; then
  skip "$(mq --version 2>&1 | head -1)"
elif ! curl -sSL https://mqlang.org/install.sh | bash; then
  warn "mq install failed"
fi

# uv
# https://docs.astral.sh/uv/getting-started/installation/
# インストール先は ~/.local/bin（uv / uvx）。
log "uv"
if has uv; then
  skip "$(uv --version 2>&1)"
elif ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
  warn "uv install failed"
fi

# Headroom
# https://github.com/headroomlabs-ai/headroom
# Debian/Ubuntu の python は externally-managed なので pipx で入れる。
# [ml] extra が torch を引くが、GPU 無し環境で素の pip install だと
# CUDA 版 torch (nvidia-* 込みで数GB) が入ってしまう。GPU が無ければ
# PyTorch の CPU-only wheel index を優先させて肥大化を避ける。
log "Headroom"
if ! has pipx; then
  warn "pipx not installed: run install/system.sh first"
elif pipx list --short 2>/dev/null | grep -q '^headroom-ai '; then
  skip "headroom-ai already installed"
else
  pip_args=()
  if ! detect_gpu; then
    pip_args=(--pip-args="--index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple")
  fi
  if ! pipx install "headroom-ai[all]" "${pip_args[@]}"; then
    warn "headroom-ai install failed"
  fi
fi

# Glances
# https://github.com/nicolargo/glances
# RHEL 系は EPEL にも無いため、apt/dnf 両対応の pipx に統一している
# （system.sh のパッケージリストには入れていない）。
log "Glances"
if ! has pipx; then
  warn "pipx not installed: run install/system.sh first"
elif pipx list --short 2>/dev/null | grep -q '^glances '; then
  skip "glances already installed"
elif ! pipx install glances; then
  warn "glances install failed"
fi

# コマンド名の互換シンボリックリンク。
# bat, fd: apt 系は実行ファイル名が batcat, fdfind（既存の別パッケージ名と衝突するため）
# python : 無いディストロ/環境向けに python3 へ張る
# sh は対象外。ほぼ全環境で最初から存在する（Debian/Ubuntu は dash、RHEL 系は bash への
# シンボリックリンク）上、もし無い場合に bash で代替しても sh 本来の挙動（dash の
# POSIX 準拠の厳しさ、bashism 非対応）とは一致しないため、代替として持たせる意味が薄い。
for pair in "bat:batcat" "fd:fdfind" "python:python3"; do
  want="${pair%%:*}"
  fallback="${pair#*:}"
  log "$want -> $fallback symlink"
  if has "$want"; then
    skip "$want already available"
  elif ! has "$fallback"; then
    skip "$fallback not installed"
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v "$fallback")" "$HOME/.local/bin/$want"
  fi
done

# Markdownlint
log "Markdownlint"
if ! has npm; then
  warn "npm not installed: skipping markdownlint-cli2"
elif npm ls -g --depth=0 markdownlint-cli2 >/dev/null 2>&1; then
  skip "markdownlint-cli2 already installed"
elif ! npm install markdownlint-cli2 --global; then
  warn "markdownlint-cli2 install failed"
fi

# Starship
# https://starship.rs/ja-JP/
# 既定の install 先は /usr/local/bin で sudo が要るため、--bin-dir で $HOME に寄せる。
log "Starship"
if has starship; then
  skip "$(starship --version 2>&1 | head -1)"
elif ! curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"; then
  warn "starship install failed"
fi
# preset は既存の設定を上書きするので、無いときだけ生成する。
if ! has starship; then
  skip "starship not installed: skipping preset"
elif [[ -f "$HOME/.config/starship.toml" ]]; then
  skip "starship.toml already exists"
else
  mkdir -p "$HOME/.config"
  starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml" ||
    warn "starship preset failed"
fi

# Fisher (fish plugin manager)
# https://github.com/jorgebucaran/fisher
# fish 上でしか動かないので fish -c 経由で叩く。導入後は fish_plugins の内容を同期する。
log "Fisher"
if ! has fish; then
  warn "fish not installed: skipping fisher"
elif fish -c 'functions -q fisher' >/dev/null 2>&1; then
  skip "fisher already installed"
elif fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'; then
  # fish_plugins に列挙されたプラグインを取り込む。
  fish -c 'fisher update' || warn "fisher update failed"
else
  warn "fisher install failed"
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
