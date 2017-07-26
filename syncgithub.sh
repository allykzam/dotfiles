#!/bin/bash

homepath="$(git config --get github.sync-homepath)"

function syncRepo() {
    local repoName="$1"
    local gitDir="${2:-}"
    local remoteGitDir="${3:-}"
    if [ "$gitDir" == "" ] ; then
        gitDir="git"
    fi
    if [ ! -d "$repoName" ] ; then
        repoName="$HOME/$gitDir/$repoName"
    fi
    if [ ! -d "$repoName" ] ; then
        echo "Can't find repo '$1'"
        exit 1
    fi
    (
        echo "Moving to $repoName"
        cd "$repoName"
        for remote in $(git remote)
        do
            (
                if [[ "$remote" == "origin" ]] ; then
                    echo
                    echo "Fetching origin..."
                elif [[ "$remote" == "upstream" ]] ; then
                    echo
                    echo "Fetching upstream..."
                else
                    break
                fi
                local homerepo="$(git remote -v | grep $remote | grep fetch | grep github | cut -d ':' -f 2 | cut -d ' ' -f 1)"
                if [ "$homerepo" == "" ] ; then
                    echo "The $remote doesn't appear to be a valid GitHub SSH URL? Skipping..."
                    break
                fi

                git fetch "$remote"
                if [ $? -ne 0 ] ; then echo "Fetch failed"; break; fi
                git fetch "$remote" --tags
                git fetch "$remote" --prune

                echo "Pushing data from $remote to the backup system"
                git push --quiet "$homepath$remoteGitDir$homerepo" refs/remotes/$remote/*:refs/heads/*
                if [ $? -ne 0 ] ; then
                    echo "Can't push to backup system; either the connection failed, or this repository doesn't exist there."
                    echo "There should be a bare repositor located at $homepath$remoteGitDir$homerepo"
                    break
                fi

                git push --quiet "$homepath$remoteGitDir$homerepo" --tags
            )
        done
    )
}


targetRepo="${1:-}"
if [ ! "$targetRepo" == "" ] ; then
    syncRepo "$targetRepo"
    exit 0
fi

(
    cd "$HOME/git"
    IFS=$'\n\t'
    user_token="$(git config --get github.access-token)"
    if [ "$user_token" == "" ] ; then
        echo "No token present under the github.access-token git config value" >&2
    else
        pageNumber=1
        echo "Getting page $pageNumber of your GitHub repositories"
        jsonData="$(curl -s https://api.github.com/user/repos?access_token=$user_token | grep full_name | cut -d ':' -f 2 | cut -d '"' -f 2)"
        while [ ${#jsonData} -gt 1 ] ;
        do
            for ghRepo in $jsonData
            do
                repoName="$(echo $ghRepo | cut -d '/' -f 2)"
                if [ ! -d "$repoName" ] && [ ! -d "$(echo $ghRepo | sed 's:/:_:g')" ] ; then
                    echo "$repoName doesn't exist locally; cloning from $ghRepo"
                    git clone --quiet "github.com:$ghRepo.git"
                fi
            done
            pageNumber=$((pageNumber+1))
            echo "Getting page $pageNumber of your GitHub repositories"
            jsonData="$(curl -s https://api.github.com/user/repos?access_token=$user_token\&page=$pageNumber | grep full_name | cut -d ':' -f 2 | cut -d '"' -f 2)"
        done
    fi
)


(
    cd "$HOME/gists"
    IFS=$'\n\t'
    user_token="$(git config --get github.access-token)"
    user_name="$(git config --get github.user)"
    if [ "$user_token" == "" ] ; then
        echo "No token or present under the github.access-token git config value" >&2
    elif [ "$user_name" == "" ] ; then
        echo "No user name present under the github.user git config value" >&2
    else
        pageNumber=1
        echo "Getting page $pageNumber of your GitHub gists"
        jsonData="$(curl -s https://api.github.com/users/$user_name/gists?access_token=$user_token | grep git_pull_url | cut -d '"' -f 4)"
        while [ ${#jsonData} -gt 1 ] ;
        do
            for gist in $jsonData
            do
                gistId="$(echo $gist | rev | cut -d '.' -f 2 | cut -d '/' -f 1 | rev)"
                gistUrl="$(echo $gist | sed 's|https://gist.github.com/|github.com:|')"
                if [ ! -d "$gistId" ] ; then
                    echo "Gist ID $gistId doesn't exist locally; cloning from $gistUrl"
                    git clone --quiet "$gistUrl"
                fi
            done
            pageNumber=$((pageNumber+1))
            echo "Getting page $pageNumber of your GitHub gists"
            jsonData="$(curl -s https://api.github.com/users/$user_name/gists?access_token=$user_token\&page=$pageNumber | grep git_pull_url | cut -d '"' -f 4)"
        done
    fi
)


(
    cd "$HOME/git"
    for repo in *
    do
        (
            if [ -d "$repo" ] ; then
                echo
                echo
                syncRepo "$repo"
            fi
        )
    done
)

(
    cd "$HOME/gists"
    for repo in *
    do
        (
            if [ -d "$repo" ] ; then
                echo
                echo
                syncRepo "$repo" "gists" "gists/"
            fi
        )
    done
)
