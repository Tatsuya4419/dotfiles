# .config/fish/config.fish の abbr に合わせたエイリアス。
# 非対話シェル（agent の実行環境を含む）では定義しない。
case $- in
  *i*)
    alias g='git'
    alias c='clear'
    alias gc='git checkout'
    alias gs='git status'
    alias ga='git add'
    alias gb='git branch'
    alias gp='git push'
    alias gl='git log'
    alias gf='git fetch'
    alias xr='xargs -I {}'
    alias ll='ls -al --color=auto'
    # 元は fish 側で `tr` だったが coreutils の tr と衝突するため t に変更した。
    alias t='tree -L 2'
    ;;
esac

# PATH (このリポジトリが管理している唯一の bash 設定ファイルなのでここに置く。
# ~/.bashrc が本ファイルを source する)
# npm global (see install/install.sh: npm config set prefix ~/.npm-global)
if [ -d "$HOME/.npm-global/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.npm-global/bin:"*) ;;
    *) export PATH="$HOME/.npm-global/bin:$PATH" ;;
  esac
fi
