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
    abbr -a ll ls -alg
    abbr -a t tree -L 2
end

command -v starship && starship init fish | source

export PATH="$HOME/.local/bin:$PATH"

# npm global (see install/install.sh: npm config set prefix ~/.npm-global)
fish_add_path -g "$HOME/.npm-global/bin"

