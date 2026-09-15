function _smart_atuin_down --description 'Down: down-or-search に委譲しつつ、_smart_atuin_up のカウンタを連動してデクリメントする'
    if commandline --paging-mode
        down-or-search
        return
    end
    if test (commandline --line) != 1
        down-or-search
        return
    end

    set -q _smart_up_count[1]; or set -g _smart_up_count 0
    if test $_smart_up_count -gt 0
        set -g _smart_up_count (math $_smart_up_count - 1)
    end

    down-or-search
end
