#!/usr/bin/env bash

gitDir=".git"
if [ -d ".git" ]; then
    true
else
    gitDir=$(git rev-parse --git-dir)
    if [ $? == 0 ]; then
        true
    else
        echo "Current directory is not part of a git repository."
        exit 1
    fi
fi

user_token=$(git config --get github.access-token)
github_origin=$(git remote -v | grep origin | grep github.com | grep fetch | sed 's|ssh://git@ssh.github.com:443/|github.com:|')
repo_owner=$(echo "$github_origin" | rev | cut -d ':' -f 1 | rev | cut -d '/' -f 1)
repo_name=$(echo "$github_origin" | cut -d ':' -f 2 | cut -d ' ' -f 1)
repo_name=$(basename "$repo_name" | sed 's/.git//')

function getData() {
    jsonData=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_name/issues?access_token=$user_token")
    result=$(echo "$jsonData" | ~/dev/dotfiles/.config/git/issue-cmd.py)
    page=1
    while [ "$result" == "" ]; do
        page=$((page+1))
        jsonData=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_name/issues?access_token=$user_token&page=$page")
        result=$(echo "$jsonData" | ~/dev/dotfiles/.config/git/issue-cmd.py)
    done
}

if [[ -d "$gitDir/issues" ]]; then
    rm -rf "$gitDir/issues"
fi
mkdir "$gitDir/issues"

getData

options=()
index=0
for issue in "$gitDir"/issues/* ; do
    number=$(echo "$issue" | cut -d '/' -f 3) || true
    if [ "$number" != "" ]; then
        title=$(cat "$issue")
        options[$index]=$number
        index=$((index+1))
        options[$index]=$title
        index=$((index+1))
    fi
done

CHOICE=$(dialog --clear --menu "Select a GitHub issue to start an issue for:" 20 150 20 "${options[@]}" 2>&1 >/dev/tty)

clear

if [ "$CHOICE" != "" ]; then
    git checkout -b "issue/$CHOICE"
fi
