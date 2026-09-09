#!/usr/bin/env bash
#
# システム全体に影響する（= root が要る）インストールだけを扱う。
# 共用サーバでは実行しないこと。1 台につき 1 回でよい。
# 権限が無い場合は `system.sh --print` で必要なインストールコマンドだけ出力できる。

set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# パッケージ名はディストリごとに違う。コンテナ (almalinux:9 / :10) で確認済み。
# pkgs_dnf は RHEL 10 に合わせてある。9 が来たら手で直す（9 は npm、10 は nodejs-npm）。
# fish / pipx / gh は EPEL 前提。EPEL が使えない環境なら管理者に相談するか諦める。
# 除外したもの:
#   eza    - 9 にも 10 にも無い（EPEL を足しても無い）。ll は fish 側で ls に落ちる
#   zoxide - EPEL 9 にはあるが 10 に無い。dnf は 1 つでも未知の名前があると
#            何も入れずに落ちるため、リストに残せない
# bubblewrap は codex のサンドボックス実行用（bwrap コマンド）。両系統とも同名で、
# RHEL 側は EPEL 不要（baseos）。
pkgs_apt=(fish npm python3-pip pipx tree python3 vim gh eza zoxide bubblewrap)
pkgs_dnf=(fish nodejs-npm python3-pip pipx tree python3 vim-enhanced gh bubblewrap)

pm="$(detect_pm)"
case "$pm" in
  apt)
    pkgs=("${pkgs_apt[@]}")
    refresh_cmd=(apt-get update)
    install_cmd=(apt-get install -y)
    ;;
  dnf | yum)
    pkgs=(${pkgs_dnf[@]+"${pkgs_dnf[@]}"})
    refresh_cmd=()
    install_cmd=("$pm" install -y)
    ;;
  *)
    pkgs=()
    refresh_cmd=()
    install_cmd=()
    ;;
esac

# 導入済みかの判定もパッケージマネージャごとに違う。
# dpkg -s は "deinstall ok config-files"（purge 前）でも 0 を返すため Status を見る。
pkg_installed() {
  case "$pm" in
    apt) [[ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" == "install ok installed" ]] ;;
    dnf | yum) rpm -q "$1" >/dev/null 2>&1 ;;
    *) has "$1" ;;
  esac
}

missing=()
for pkg in ${pkgs[@]+"${pkgs[@]}"}; do
  pkg_installed "$pkg" || missing+=("$pkg")
done

# --print: 管理者に渡すためのコマンドだけ出して終わる。
if [[ "${1:-}" == "--print" ]]; then
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    printf '# %s 向けのパッケージリストは未定義。Debian 系の名前を読み替えること:\n' "$pm"
    printf '#   %s\n' "${pkgs_apt[*]}"
  elif [[ ${#missing[@]} -gt 0 ]]; then
    printf 'sudo %s %s\n' "${install_cmd[*]}" "${missing[*]}"
  fi
  exit 0
fi

log "packages ($pm)"
sudo_cmd="$(detect_sudo)"
if [[ "$pm" == "none" ]]; then
  warn "no supported package manager (apt-get/dnf/yum) -> ${pkgs_apt[*]}"
elif [[ ${#pkgs[@]} -eq 0 ]]; then
  warn "no package list defined for $pm: run 'install/system.sh --print' and map the names by hand"
elif [[ ${#missing[@]} -eq 0 ]]; then
  skip "all packages installed"
elif [[ "$sudo_cmd" == "none" ]]; then
  warn "no sudo: run 'install/system.sh --print' and ask an admin -> ${missing[*]}"
elif [[ ${#refresh_cmd[@]} -gt 0 ]] && ! $sudo_cmd "${refresh_cmd[@]}"; then
  warn "$pm refresh failed -> ${missing[*]}"
elif ! $sudo_cmd "${install_cmd[@]}" "${missing[@]}"; then
  warn "$pm install failed (no privileges?) -> ${missing[*]}"
fi

summary "system"
