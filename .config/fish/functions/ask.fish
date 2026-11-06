function ask --description '辞書に無い軽い質問を Haiku に聞く。ツール無し・設定非読込・セッション非保存で縛ってある'
    if test (count $argv) -eq 0
        echo 'usage: ask <質問>' >&2
        return 1
    end

    # --tools ""                : 全ツール無効（ローカルの read/grep もパーミッション要求も発生しない）
    # --no-session-persistence  : 使い捨てなのでセッションを残さない
    # --disable-slash-commands  : スキルとコマンドを読まない
    # --strict-mcp-config       : MCP を読まない（--mcp-config を渡していないので何も入らない）
    # --setting-sources ""      : user/project/local の設定を読まない
    # 短い語や断片が来ても「それは何か」を答えさせる。聞き返さない・前置きしない。
    set -l sys '入力は、用語・略語・コマンド名・症状・うろ覚えの説明などの短い断片であることが多い。
文面どおりの質問でなくても、それが何を指すかを推定して答える。聞き返さず、前置きもしない。
形式: 1行目に正式名称または一般的な呼び名。続けて1〜3行で要点。別名や近い概念があれば最後に1行。
曖昧で複数の解釈があるときは、可能性の高い順に最大3つ挙げる。
知らない・自信がないものは、そう明記する。推測で断定しない。
回答は日本語。技術用語と固有名詞は原語のまま。'

    # env -C: 実行場所を固定する。プロジェクトごとの自動メモリは cwd で決まるため、
    #   dotfiles 内で実行するとメモリの索引が文脈に入る（--setting-sources では防げない）。
    #   --bare は認証（keychain）も飛ばしてログイン切れになるので使えない。
    command env -C /tmp claude --model haiku -p \
        --system-prompt "$sys" \
        --tools "" \
        --no-session-persistence \
        --disable-slash-commands \
        --strict-mcp-config \
        --setting-sources "" \
        -- "$argv"
end
