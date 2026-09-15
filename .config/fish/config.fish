if status is-interactive
    abbr -a g git
    abbr -a c clear
    abbr -a gc git checkout
    abbr -a gs git status
    abbr -a ga git add
    abbr -a gb git branch
    abbr -a gp git push
    abbr -a gl git log
    abbr -a gf git fetch
    abbr -a xr xargs -I {}
    abbr -a py python3
    # eza があれば使う（アイコンと git ステータス列つき）。
    if command -q eza
        abbr -a ll eza -la --group --icons --git
    else
        abbr -a ll ls -al
    end
    abbr -a t tree -L 2
    # fa の後に Space で展開だけ（続けて引数を打てる）。
    # Enter で展開すると、展開後の行がそのまま実行されてしまうので注意。
    abbr -a fa --function fzf_abbr
end

command -q starship; and starship init fish | source
command -q zoxide; and zoxide init fish | source

# fzf: Ctrl-T (ファイル挿入) と Alt-C (cd)。fzf 0.60 以降は --fish が使える
command -q fzf; and fzf --fish | source

# atuin: Ctrl-R を置き換える。fzf より後に読むこと
command -q atuin; and atuin init fish | source

# Up キーは 2 回までは fish 標準の linear history、3 回目から atuin の検索 UI に切り替える。
# atuin init が上で bind 済みの Up (_atuin_bind_up) を上書きするので、この行はそれより後に置くこと。
if command -q atuin
    set -g _smart_up_linear_presses 2
    bind \eOA _smart_atuin_up
    bind \e\[A _smart_atuin_up
    bind \eOB _smart_atuin_down
    bind \e\[B _smart_atuin_down
    if bind -M insert >/dev/null 2>&1
        bind -M insert -k up _smart_atuin_up
        bind -M insert \eOA _smart_atuin_up
        bind -M insert \e\[A _smart_atuin_up
        bind -M insert -k down _smart_atuin_down
        bind -M insert \eOB _smart_atuin_down
        bind -M insert \e\[B _smart_atuin_down
    end
end

export PATH="$HOME/.local/bin:$PATH"

# npm global (see install/install.sh: npm config set prefix ~/.npm-global)
fish_add_path -g "$HOME/.npm-global/bin"

