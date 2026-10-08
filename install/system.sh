#!/usr/bin/env bash
#
# システム全体に影響する（= root が要る）インストールだけを扱う。
# 共用サーバでは実行しないこと。1 台につき 1 回でよい。
# 権限が無い場合は `system.sh --print` で必要なインストールコマンドだけ出力できる。
# `system.sh --upgrade` で導入済みのパッケージも最新版へ更新する。

set -uo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# パッケージ名はディストリごとに違う。コンテナ (almalinux:9 / :10) で確認済み。
# pkgs_dnf は RHEL 10 に合わせてある。9 が来たら手で直す（9 は npm、10 は nodejs-npm）。
# fish / pipx / gh は EPEL 前提。EPEL が使えない環境なら管理者に相談するか諦める。
# 除外したもの:
#   eza    - 9 にも 10 にも無い（EPEL を足しても無い）。ll は fish 側で ls に落ちる
#   zoxide - EPEL 9 にはあるが 10 に無い。dnf は 1 つでも未知の名前があると
#            何も入れずに落ちるため、リストに残せない
#   atuin  - 9 にも 10 にも無い（EPEL を足しても無い。コンテナで確認済み）。
#            公式インストーラ（curl）は ~/.atuin/bin 配下に入れる上、
#            config.fish 等のシェル設定ファイルを自動で書き換える副作用があり
#            他ツールの導入方式と揃わないため、ここでは見送る。
#            atuin / zoxide / eza / direnv で apt/dnf に無い環境は、user.sh が
#            GitHub Releases のバイナリを ~/.local/bin に入れて埋める
#   bat    - パッケージ名は apt/dnf 共通で `bat` だが、実行ファイル名が
#            apt 系だけ `batcat`（既存の別パッケージと衝突するため）。
#            `bat` コマンドとして揃えるシンボリックリンクは user.sh 側で張る
#   direnv - apt にはあるが、RHEL 9 / 10 には EPEL を足しても無い（コンテナで確認済み）。
#            dnf 側のリストに残すと install 全体が落ちるため apt 専用にしてある
#   fd-find - bat と同じ事情。apt 系だけ実行ファイル名が `fdfind`
#             （既存の別パッケージと衝突するため）。fd への
#             シンボリックリンクは user.sh 側で張る
# 候補が無いパッケージ（例: Ubuntu 24.04 の atuin）があっても、下の install 処理が
# 候補無しを除いて warn にとどめる。リストの手動の絞り込みは必須ではなくなったが、
# 毎回 warn が出るのを避けたい既知のものは引き続き外してある。
# unzip は AWS CLI の installer が依存する。WSL (Ubuntu) は最小構成で入っておらず、
# user.sh の AWS CLI で落ちた。
# bubblewrap は codex のサンドボックス実行用（bwrap コマンド）。両系統とも同名で、
# RHEL 側は EPEL 不要（baseos）。
# glances はここに無い。RHEL 側は EPEL を足しても無い（コンテナで確認済み）ため、
# 両ディストロで揃えられる pipx 経由に統一して user.sh 側で入れる。
pkgs_apt=(fish npm python3-pip pipx tree python3 vim gh eza zoxide bubblewrap sqlite3 htop btop ripgrep fzf bat fd-find atuin podman direnv unzip)
pkgs_dnf=(fish nodejs-npm python3-pip pipx tree python3 vim-enhanced gh bubblewrap sqlite htop btop ripgrep fzf bat fd-find podman unzip)

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

# リポジトリにインストール候補があるか。無い名前を install に混ぜると全体が落ちる。
has_candidate() {
  case "$pm" in
    apt)
      local c
      c="$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')"
      [[ -n "$c" && "$c" != "(none)" ]]
      ;;
    dnf | yum) "$pm" -q list --available "$1" >/dev/null 2>&1 ;;
    *) return 0 ;;
  esac
}

print_mode=0
upgrade_mode=0
for arg in "$@"; do
  case "$arg" in
    --print) print_mode=1 ;;
    --upgrade) upgrade_mode=1 ;;
  esac
done

missing=()
installed=()
for pkg in ${pkgs[@]+"${pkgs[@]}"}; do
  if pkg_installed "$pkg"; then
    installed+=("$pkg")
  else
    missing+=("$pkg")
  fi
done

# --print: 管理者に渡すためのコマンドだけ出して終わる。
if [[ "$print_mode" -eq 1 ]]; then
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    printf '# %s 向けのパッケージリストは未定義。Debian 系の名前を読み替えること:\n' "$pm"
    printf '#   %s\n' "${pkgs_apt[*]}"
  elif [[ ${#missing[@]} -gt 0 ]]; then
    printf 'sudo %s %s\n' "${install_cmd[*]}" "${missing[*]}"
  fi
  exit 0
fi

# dnf/yum は install 済みのパッケージに対して install を叩いても上げてくれない
# （apt はそのまま最新化される）ため、upgrade サブコマンドを別に用意する。
case "$pm" in
  apt) upgrade_cmd=(apt-get install -y) ;;
  dnf | yum) upgrade_cmd=("$pm" upgrade -y) ;;
  *) upgrade_cmd=() ;;
esac

log "packages ($pm)"
sudo_cmd="$(detect_sudo)"
if [[ "$pm" == "none" ]]; then
  warn "no supported package manager (apt-get/dnf/yum) -> ${pkgs_apt[*]}"
elif [[ ${#pkgs[@]} -eq 0 ]]; then
  warn "no package list defined for $pm: run 'install/system.sh --print' and map the names by hand"
elif [[ "$sudo_cmd" == "none" ]]; then
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "no sudo: run 'install/system.sh --print' and ask an admin -> ${missing[*]}"
  else
    skip "all packages installed"
  fi
elif [[ ${#refresh_cmd[@]} -gt 0 ]] && ! $sudo_cmd "${refresh_cmd[@]}"; then
  warn "$pm refresh failed -> ${missing[*]}"
else
  # apt/dnf とも未知の名前が 1 つでもあると何も入れずに落ちる（atuin は Debian 13 にあるが
  # Ubuntu 24.04 には無い）。候補の無いものを先に外して warn し、残りだけ入れる。
  # 候補の有無は refresh（apt update）の後でないと正しく引けないので、ここで見る。
  # dnf は AlmaLinux 9 (4.14) / 10 (4.20) で確認済み: `list --available` は
  # 有れば 0、無ければ 1 を返す。
  available=()
  for pkg in ${missing[@]+"${missing[@]}"}; do
    if has_candidate "$pkg"; then
      available+=("$pkg")
    else
      warn "$pm has no candidate for $pkg: skipped"
    fi
  done
  missing=(${available[@]+"${available[@]}"})
  if [[ ${#missing[@]} -eq 0 ]]; then
    skip "nothing to install"
  elif ! $sudo_cmd "${install_cmd[@]}" "${missing[@]}"; then
    warn "$pm install failed (no privileges?) -> ${missing[*]}"
  fi
  if [[ "$upgrade_mode" -eq 1 ]]; then
    if [[ ${#installed[@]} -eq 0 ]]; then
      skip "upgrade: nothing already installed"
    elif ! $sudo_cmd "${upgrade_cmd[@]}" "${installed[@]}"; then
      warn "$pm upgrade failed -> ${installed[*]}"
    fi
  fi
fi

summary "system"
