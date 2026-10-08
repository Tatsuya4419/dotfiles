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
# sudo を付けても付けなくてもよい。付けた場合、user.sh は SUDO_USER として実行する。

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

# `sudo install.sh` で呼ばれると user.sh まで root で走り、root の $HOME 以下に入れて
# しまう。sudo 経由（SUDO_USER が root 以外）なら user.sh だけ元のユーザーに戻す。
# 素の root ログイン（SUDO_USER 無し）は、そのまま root のアカウント向けに入れる。
if [[ "${EUID:-$(id -u)}" -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  sudo -u "$SUDO_USER" -H "$script_dir/user.sh" ${upgrade_args[@]+"${upgrade_args[@]}"} || status=1
else
  "$script_dir/user.sh" ${upgrade_args[@]+"${upgrade_args[@]}"} || status=1
fi

exit "$status"
