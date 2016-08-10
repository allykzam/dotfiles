#!/usr/bin/env bash

branch="$1"
issue="$(basename "$branch")"

if [ "$issue" == "" ]
then
    echo "$branch does not appear to be an issue branch?"
    exit 1
fi

if [ "$issue" == "$branch" ]
then
    git show-ref --verify --quiet "refs/heads/issue/$issue"
    if [ "$?" == "0" ]
    then
        branch="issue/$issue"
    else
        git show-ref --verify --quiet "refs/heads/hotfix/$issue"
        if [ "$?" == "0" ]
        then
            branch="hotfix/$issue"
        else
            echo "$branch does not appear to be an issue branch?"
            exit 1
        fi
    fi
fi

git merge "$branch" --gpg-sign --no-edit -m "Merge \"$branch\" into \"$(git rev-parse --abbrev-ref HEAD)\"

Closes #$issue"
