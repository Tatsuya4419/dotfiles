#!/usr/bin/env bash
# 全レシピが今の環境で終了コード 0 で動くか確認する（結果は保存しない）
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
fail=0
for sh in */*/*.sh; do
  IFS=/ read -r fmt op file <<< "$sh"
  ./render.sh --run "$fmt" "$op" "${file%.sh}" > /dev/null 2>&1 || { echo "FAIL: $sh" >&2; fail=1; }
done
exit "$fail"
