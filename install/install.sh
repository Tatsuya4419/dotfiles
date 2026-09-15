#!/usr/bin/env bash
#
# Entrypoint. 何度実行しても安全（冪等）。
#
#   install/install.sh              system.sh → user.sh
#   install/install.sh --user-only  user.sh だけ（共用サーバ向け）
#   install/install.sh --upgrade    導入済みのものも最新化する（対応ツールのみ）
#
# system.sh は root が要りシステム全体に影響する。共用サーバでは --user-only か、
# install/user.sh を直接実行すること。

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

user_only=0
upgrade_args=()
for arg in "$@"; do
  case "$arg" in
    --user-only) user_only=1 ;;
    --upgrade) upgrade_args+=("--upgrade") ;;
  esac
done

if [[ "$user_only" -eq 1 ]]; then
  printf '==> skipping system.sh (--user-only)\n'
else
  "$script_dir/system.sh" ${upgrade_args[@]+"${upgrade_args[@]}"} || status=1
fi

"$script_dir/user.sh" ${upgrade_args[@]+"${upgrade_args[@]}"} || status=1

exit "$status"
