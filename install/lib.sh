#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers. source して使う（直接実行しない）。

has() { command -v "$1" >/dev/null 2>&1; }
log() { printf '\n==> %s\n' "$*"; }
skip() { printf '    skip: %s\n' "$*"; }

warnings=()
warn() {
  printf '    WARN: %s\n' "$*" >&2
  warnings+=("$*")
}

# 警告が 1 件でもあれば一覧を出して 1 を返す。
summary() {
  if [[ ${#warnings[@]} -gt 0 ]]; then
    log "$1: done with ${#warnings[@]} warning(s)"
    printf '  - %s\n' "${warnings[@]}" >&2
    return 1
  fi
  log "$1: done"
  return 0
}

# 使えるパッケージマネージャ。対応外は "none"。
detect_pm() {
  if has apt-get; then
    printf 'apt'
  elif has dnf; then
    printf 'dnf'
  elif has yum; then
    printf 'yum'
  else
    printf 'none'
  fi
}

# NVIDIA GPU の有無。torch 系パッケージを CUDA 版にするか CPU-only 版にするかの分岐に使う。
detect_gpu() {
  has nvidia-smi || [[ -e /proc/driver/nvidia/version ]]
}

# root なら sudo 不要、非 root で sudo が無ければ "none"。
detect_sudo() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    printf ''
  elif has sudo; then
    printf 'sudo'
  else
    printf 'none'
  fi
}

# GitHub Releases のバイナリを ~/.local/bin に入れる。パッケージマネージャに無い
# ツールのフォールバック用で、root 不要・シェル設定には触らない。
#   gh_release_install <bin> <owner/repo> <asset 名のテンプレート>
# テンプレートは @TAG@ (v1.2.3) @VER@ (1.2.3) @ARCH@ (x86_64|aarch64)
# @GOARCH@ (amd64|arm64) を置換する。asset が .tar.gz なら展開して <bin> を探し、
# それ以外は実行ファイルそのものとして置く。<asset>.sha256 がリリースにあれば検証する
# （無いプロジェクトもあり、その場合は TLS だけが頼り）。
# 最新版の tag は API ではなく /releases/latest のリダイレクトから取る
# （レート制限も gh も要らない）。
gh_release_install() {
  local bin="$1" repo="$2" tmpl="$3" tmp rc
  tmp="$(mktemp -d)" || return 1
  _gh_release_install "$tmp" "$bin" "$repo" "$tmpl"
  rc=$?
  rm -rf "$tmp"
  return "$rc"
}

_gh_release_install() {
  local tmp="$1" bin="$2" repo="$3" tmpl="$4"
  local arch goarch url tag ver asset base code want got found

  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 goarch=amd64 ;;
    aarch64 | arm64) arch=aarch64 goarch=arm64 ;;
    *) warn "$bin: unsupported architecture $(uname -m)"; return 1 ;;
  esac

  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")" || {
    warn "$bin: could not resolve latest release of $repo"
    return 1
  }
  [[ "$url" == */releases/tag/* ]] || { warn "$bin: no release found for $repo"; return 1; }
  tag="${url##*/}"
  ver="${tag#v}"

  asset="$tmpl"
  asset="${asset//@TAG@/$tag}"
  asset="${asset//@VER@/$ver}"
  asset="${asset//@ARCH@/$arch}"
  asset="${asset//@GOARCH@/$goarch}"
  base="https://github.com/$repo/releases/download/$tag"

  curl -fsSL -o "$tmp/$asset" "$base/$asset" || { warn "$bin: download failed: $asset"; return 1; }

  code="$(curl -sSL -o "$tmp/sum" -w '%{http_code}' "$base/$asset.sha256")" || code=000
  case "$code" in
    200)
      want="$(awk '{print $1; exit}' "$tmp/sum")"
      got="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
      [[ "$want" == "$got" ]] || { warn "$bin: sha256 mismatch for $asset"; return 1; }
      printf '    sha256 verified: %s\n' "$asset"
      ;;
    404) printf '    no checksum published for %s (TLS only)\n' "$asset" ;;
    *) warn "$bin: could not fetch checksum (HTTP $code)"; return 1 ;;
  esac

  case "$asset" in
    *.tar.gz)
      mkdir "$tmp/x" && tar -xzf "$tmp/$asset" -C "$tmp/x" || { warn "$bin: extract failed"; return 1; }
      found="$(find "$tmp/x" -type f -name "$bin" | head -1)"
      ;;
    *) found="$tmp/$asset" ;;
  esac
  [[ -n "$found" ]] || { warn "$bin: binary not found in $asset"; return 1; }

  mkdir -p "$HOME/.local/bin"
  install -m 755 "$found" "$HOME/.local/bin/$bin" || { warn "$bin: install failed"; return 1; }
  printf '    installed: %s %s -> %s\n' "$bin" "$tag" "$HOME/.local/bin/$bin"
}
