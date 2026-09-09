#!/usr/bin/env bash
#
# Entrypoint. 何度実行しても安全（冪等）。
#
#   install/install.sh              system.sh → user.sh
#   install/install.sh --user-only  user.sh だけ（共用サーバ向け）
#
# system.sh は root が要りシステム全体に影響する。共用サーバでは --user-only か、
# install/user.sh を直接実行すること。

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

if [[ "${1:-}" == "--user-only" ]]; then
  printf '==> skipping system.sh (--user-only)\n'
else
  "$script_dir/system.sh" || status=1
fi

"$script_dir/user.sh" || status=1

exit "$status"
