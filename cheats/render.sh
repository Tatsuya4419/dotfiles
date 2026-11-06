#!/usr/bin/env bash
# 使い方: render.sh [--run|--show] <fmt> <op> <tool>
#   fmt は csv か json。入力は <fmt>/<op>/in.<fmt>、コマンドは <fmt>/<op>/<tool>.sh
#   既定  : コマンドラインに入れるワンライナー（<cmd> < サンプル入力ファイル）を出力する
#   --run : そのワンライナーを今の環境で実行する
#   --show: IN と OUT を左右に並べ、下にコマンドを出す（fzf のプレビュー用）
set -eu
cd "$(dirname "${BASH_SOURCE[0]}")"
mode=print
case "${1:-}" in --run) mode=run; shift ;; --show) mode=show; shift ;; esac
fmt="$1"; op="$2"; tool="$3"
dir="$fmt/$op"
in="$dir/in.$fmt"
line="$(<"$dir/$tool.sh") < $PWD/$in"

case "$mode" in
  print) printf '%s\n' "$line" ;;
  run)   AI_AGENT= bash -c "$line" ;;
  show)
    out="$(AI_AGENT= bash -c "$line" 2>&1 || true)"
    paste -d '\t' \
      <(printf 'IN\n--\n'; cat "$in") \
      <(printf 'OUT\n---\n'; printf '%s\n' "$out") |
      expand -t 28
    printf '\n$ %s\n' "$line"
    ;;
esac
