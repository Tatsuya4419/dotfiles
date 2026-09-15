function _smart_atuin_up --description 'Up を N 回連続で押すまでは fish 標準の linear history、それ以降で atuin の検索 UI に切り替える'
    # 補完メニューなどのページング中は常に fish 標準に委譲。
    # commandline --search-mode はここでは見ない: 1 回目の up-or-search 自体が
    # fish を「履歴検索中」状態にしてしまうため、これをガードに使うと 2 回目以降が
    # 毎回ここで早期 return してしまい、以下のカウンタ分岐に永遠に到達できなくなる
    # （＝Up を何回押しても linear のままになる不具合の原因だった）。
    if commandline --paging-mode
        up-or-search
        return
    end
    if test (commandline --line) != 1
        up-or-search
        return
    end

    set -q _smart_up_count[1]; or set -g _smart_up_count 0
    # linear 連打が始まる前（カウント 0）の入力内容を覚えておく。atuin に切り替える
    # 際、linear で history の文言に置き換わった状態のまま渡すと、それが
    # atuin の検索クエリの初期値（ATUIN_QUERY = commandline -b）になってしまうため。
    if test $_smart_up_count -eq 0
        set -g _smart_up_orig_line (commandline -b)
    end
    set -g _smart_up_count (math $_smart_up_count + 1)

    if test $_smart_up_count -le $_smart_up_linear_presses
        up-or-search
    else
        commandline -r -- $_smart_up_orig_line
        _atuin_search --shell-up-key-binding
    end
end

# 新しいプロンプトが出るたびにカウンタをリセットする
# （行編集中に文字を打ってから Up を押し直すケースまでは追わない）
function _smart_atuin_up_reset --on-event fish_prompt
    set -g _smart_up_count 0
    set -g _smart_up_orig_line ''
end
