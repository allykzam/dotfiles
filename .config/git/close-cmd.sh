#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'


branch="$1"

currentBranch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$currentBranch" == "master" || "$currentBranch" == "main" || "$currentBranch" == "dev" || "$currentBranch" =~ maintenance/.* ]] ; then
    echo "Currently on a primary branch - change to the branch you want to merge and try again."
    exit 1
elif [[ "$currentBranch" =~ .*/.* ]] ; then
    if [ "$branch" == "master" ] ; then
        branch="$currentBranch"
        git checkout master
    elif [ "$branch" == "main" ] ; then
        branch="$currentBranch"
        git checkout main
    elif [ "$branch" == "dev" ] ; then
        branch="$currentBranch"
        git checkout dev
    elif [[ "$branch" =~ maintenance/.* ]] ; then
        git checkout "$branch"
        branch="$currentBranch"
    else
        echo "Currently on $currentBranch which appears to be an issue branch, but you specified $branch which does not appear to be master/main/dev?"
        exit 1
    fi
else
    echo "Currently on $currentBranch and not sure what to do with it; it should look like 'issue/123' or 'your-name/add-the-thing'"
    exit 1
fi

issue="$(basename "$branch")"

if [ "$issue" == "" ]
then
    echo "$branch does not appear to be an issue branch?"
    exit 1
fi

git fetch
status="$(git status --branch --porcelain | cut -d \[ -f 2 | cut -d ' ' -f 1)"
if [ "$status" == "ahead" ]
then
    echo "The current branch is ahead of its remote. You should push your local changes before closing an issue branch."
    exit 1
elif [ "$status" == "behind" ]
then
    echo "The current branch is behind its remote. You need to make sure your local changes are up-to-date before closing an issue branch."
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

remote="$(git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" | cut -d '/' -f1)"

if [[ "$issue" =~ '^[0-9]+$' ]] ; then
    RUNNING_GIT_CLOSE=true git merge "$branch" --gpg-sign --no-edit -m "Merge \"$branch\" into \"$(git rev-parse --abbrev-ref HEAD)\"

Closes #$issue"
else
    RUNNING_GIT_CLOSE=true git merge "$branch" --gpg-sign --no-edit -m "Merge \"$branch\" into \"$(git rev-parse --abbrev-ref HEAD)\""
fi

git push && git branch -df  "$branch"
git push "$remote" --delete "$branch"
