function fzf_abbr --description 'abbr --show を fzf で選び、展開後のコマンドを返す（abbr --function 用）'
    set -l sel (abbr --show \
        | string match -rv -- '--function' \
        | string replace -r '^abbr -a -- (\S+) (.*)$' '$1  $2' \
        | fzf)
    test -n "$sel"; or return 1

    set -l cmd (string replace -r '^\S+\s+' '' -- $sel)
    # string trim は「実際に何か剥がした場合のみ 0」を返す仕様のため、
    # クォート無し（単語だけ）の展開だと非 0 になり abbr --function に失敗と見なされていた。
    string trim -c "'" -- $cmd
    return 0
end
