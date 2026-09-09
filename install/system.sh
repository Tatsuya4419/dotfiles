#!/usr/bin/env bash
#
# システム全体に影響する（= root が要る）インストールだけを扱う。
# 共用サーバでは実行しないこと。1 台につき 1 回でよい。
# 権限が無い場合は `system.sh --print` で必要な apt-get 行だけ出力できる。

set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

apt_pkgs=(npm python3-pip pipx tree python3 vim)

# 未導入のものだけを拾う。dpkg が無い環境では実体の有無で代用する。
# dpkg -s は "deinstall ok config-files"（purge 前）でも 0 を返すため Status を見る。
apt_installed() {
  [[ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" == "install ok installed" ]]
}

apt_missing=()
if has dpkg-query; then
  for pkg in "${apt_pkgs[@]}"; do
    apt_installed "$pkg" || apt_missing+=("$pkg")
  done
else
  for pkg in npm pipx tree python3 vim; do
    has "$pkg" || apt_missing+=("$pkg")
  done
fi

# --print: 管理者に渡すためのコマンドだけ出して終わる。
if [[ "${1:-}" == "--print" ]]; then
  if [[ ${#apt_missing[@]} -gt 0 ]]; then
    printf 'sudo apt-get install -y %s\n' "${apt_missing[*]}"
  fi
  exit 0
fi

log "apt-get"
sudo_cmd="$(detect_sudo)"
if [[ ${#apt_missing[@]} -eq 0 ]]; then
  skip "all packages installed"
elif ! has apt-get; then
  warn "apt-get not available: install manually -> ${apt_missing[*]}"
elif [[ "$sudo_cmd" == "none" ]]; then
  warn "no sudo: run 'install/system.sh --print' and ask an admin -> ${apt_missing[*]}"
elif ! { $sudo_cmd apt-get update && $sudo_cmd apt-get install -y "${apt_missing[@]}"; }; then
  warn "apt-get failed (no privileges?) -> ${apt_missing[*]}"
fi

summary "system"
