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
    # eza があれば使う（アイコンと git ステータス列つき）。
    if command -q eza
        abbr -a ll eza -la --group --icons --git
    else
        abbr -a ll ls -al
    end
    abbr -a t tree -L 2
end

command -q starship; and starship init fish | source
command -q zoxide; and zoxide init fish | source

export PATH="$HOME/.local/bin:$PATH"

# npm global (see install/install.sh: npm config set prefix ~/.npm-global)
fish_add_path -g "$HOME/.npm-global/bin"

