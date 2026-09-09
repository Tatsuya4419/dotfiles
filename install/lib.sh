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
