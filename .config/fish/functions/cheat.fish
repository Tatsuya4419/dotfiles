function cheat --description 'cheats/ のレシピを fzf で選び、サンプル入力つきワンライナーをコマンドラインに入れる（引数: 先に絞る語、例 csv）'
    # 関数ファイルは setup.sh で symlink されるので、実体を辿って dotfiles/cheats を見つける
    set -l dir (path resolve (path resolve (status filename) | path dirname)/../../../cheats)
    set -l render $dir/render.sh

    # 1行 = 「形式 操作 ツール」。例: csv distinct mlr
    set -l query ''
    test (count $argv) -gt 0; and set query "$argv "

    set -l sel (for f in $dir/*/*/*.sh
            string join ' ' (path basename (path dirname (path dirname $f))) (path basename (path dirname $f)) (path change-extension '' (path basename $f))
        end | fzf --query "$query" --preview "bash $render --show {1} {2} {3}" --preview-window 'down,70%')
    test -n "$sel"; or return 1

    set -l parts (string split ' ' -- $sel)
    commandline -r -- (bash $render $parts[1] $parts[2] $parts[3])
    commandline -f repaint
end
