# Set up fancy posh-git prompt in a zsh-friendly way
git_prompt_status() {
    local ref=""
    ref="$(command git symbolic-ref HEAD 2> /dev/null)" || \
    ref="$(command git describe --tags --exact-match HEAD 2> /dev/null)" || \
    ref="$(command git rev-parse --short HEAD 2> /dev/null)" || return

    local INDEX="$(command git status --porcelain -b 2> /dev/null)"

    # index counters
    local count_added=$(echo "$INDEX" | grep -c '^A')
    local count_modified=$(echo "$INDEX" | grep -c -E '^[MR]')
    local count_deleted=$(echo "$INDEX" | grep -c '^D')
    # working directory counters
    local count_untracked=$(echo "$INDEX" | grep -c -E '^[\?A][\?A] ')
    local count_modified_wd=$(echo "$INDEX" | grep -c -E '^[A-Z ][MR] ')
    local count_deleted_wd=$(echo "$INDEX" | grep -c -E '^[A-Z ]D ')
    local count_conflict=$(echo "$INDEX" | grep -c '^[A-Z ]U ')

    # current branch
    local branch=${ref#refs\/heads\/}
    local BRANCH_TEXT=""
    local upstream="$(echo "$INDEX" | head -1)"
    if $(echo "$upstream" | grep -E "\[ahead [0-9]+\]$" &> /dev/null) ; then
        BRANCH_TEXT="%{$fg_bold[green]%}"
    elif $(echo "$upstream" | grep -E "\[behind [0-9]+\]$" &> /dev/null) ; then
        BRANCH_TEXT="%{$fg_bold[red]%}"
    elif $(echo "$upstream" | grep -E "\[ahead [0-9]+, behind [0-9]+\]$" &> /dev/null) ; then
        BRANCH_TEXT="%{$fg_bold[yellow]%}"
    else
        BRANCH_TEXT="%{$fg_bold[cyan]%}"
    fi
    BRANCH_TEXT="$BRANCH_TEXT$branch%{%f%b%}"

    # index status
    local SHOW_INDEX=false
    local INDEX_TEXT="%{$fg[green]%} +$count_added ~$count_modified -$count_deleted"
    [[ "$count_added" != "0" ]] && SHOW_INDEX=true
    [[ "$count_modified" != "0" ]] && SHOW_INDEX=true
    [[ "$count_deleted" != "0" ]] && SHOW_INDEX=true
    if [[ "$SHOW_INDEX" = false ]] ; then
        INDEX_TEXT=""
    fi

    # working-directory status
    local SHOW_WD=false
    local WORKING_TEXT="%{$fg[red]%} +$count_untracked ~$count_modified_wd -$count_deleted_wd"
    [[ "$count_untracked" != "0" ]] && SHOW_WD=true
    [[ "$count_modified_wd" != "0" ]] && SHOW_WD=true
    [[ "$count_deleted_wd" != "0" ]] && SHOW_WD=true
    if [[ "$SHOW_WD" = false ]] ; then
        WORKING_TEXT=""
    fi

    # index/working-director separator
    local SEPARATOR=" %{$fg_bold[yellow]%}|%{%f%b%}"
    if [[ "$SHOW_INDEX" = false || "$SHOW_WD" = false ]] ; then
        SEPARATOR=""
    fi

    # stash info
    local STASH_TEXT=""
    git rev-parse --verify refs/stash &> /dev/null && STASH_TEXT="%{$fg[blue]%}$%{%f%}"

    # provide output for prompt
    if [[ "$ref" != "" ]] ; then
        echo " %{$fg_bold[yellow]%}[%{%f%b%}$BRANCH_TEXT$INDEX_TEXT$SEPARATOR$WORKING_TEXT%{%f%}%{$fg_bold[yellow]%}]%{%f%b%}$STASH_TEXT"
    fi
}

PROMPT='%{$reset_color%}%n@%m:%~$(git_prompt_status)$ '

