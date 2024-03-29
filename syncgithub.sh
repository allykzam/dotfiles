#!/bin/bash

homepath="$(git config --get github.sync-homepath)"
hubpath="$(git config --get github.sync-hubpath)"

function syncRepo() {
    local repoName="$1"
    local gitDir="${2:-}"
    local remoteGitDir="${3:-}"
    if [ "$gitDir" == "" ] ; then
        gitDir="dev"
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
        local homerepo="$(git remote -v | grep origin | grep fetch | grep github | cut -d ':' -f 2 | cut -d ' ' -f 1)"
        if [ "$homerepo" != "" ] ; then
            # Look to see if there is an "upstream" remote; if there is not, see
            # if we should create one.
            local upstream="$(git remote -v | grep '^upstream')"
            if [ "${upstream:-}" == "" ] ; then
                # Get the `user/repo` part of the origin URL
                upstream="$(echo "$homerepo" | sed 's/.git$//')"
                local access_token="$(git config --get github.access-token)"
                local user_name="$(git config --get github.user)"
                # Get GitHub's data for this repository
                local github_data="$(curl -s -u $user_name:$access_token https://api.github.com/repos/$upstream)"
                # Check to see if this repository is a fork
                local fork_status="$(echo "$github_data" | grep '"fork"' | cut -d ':' -f 2 | cut -d ',' -f 1 | head -n 1)"
                if [ "${fork_status:-}" == " true" ] ; then
                    # If this *is* a fork, get the upstream URL; should be the
                    # first "ssh_url" value after the "parent" data starts
                    upstream="$(echo "$github_data" | grep -A 100 '"parent"' | grep '"ssh_url"' | cut -d ':' -f 2- | cut -d '"' -f 2 | head -n 1 | sed 's/^git@//')"
                    echo "GitHub says this repository is a fork; adding a new 'upstream' remote at:"
                    echo "$upstream"
                    git remote add upstream "$upstream"
                fi
            fi
        fi
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
                    exit
                fi
                local homerepo="$(git remote -v | grep $remote | grep fetch | grep github | cut -d ':' -f 2- | cut -d ' ' -f 1)"
                if [ "$homerepo" == "" ] ; then
                    if [ "$remote" == "origin" ] ; then
                        echo "The remote $remote doesn't appear to be a valid GitHub SSH URL? Fetching changes, but will not be able to push to the backup system."
                        git fetch "$remote"
                        git fetch "$remote" --tags
                        git fetch "$remote" --prune
                    else
                        echo "The remote $remote doesn't appear to be a valid GitHub SSH URL? Skipping..."
                    fi
                    exit
                fi
                if [[ "$homerepo" == *"ssh.github.com"* ]] ; then
                    homerepo="$(echo "$homerepo" | sed -r 's|(//git@)?ssh.github.com(:443)?/?||')"
                fi

                git fetch "$remote"
                if [ $? -ne 0 ] ; then echo "Fetch failed"; break; fi
                git fetch "$remote" --tags
                git fetch "$remote" --prune

                echo "Pushing data from $remote to the backup system"
                git push --quiet "$homepath$remoteGitDir$homerepo" refs/remotes/$remote/*:refs/heads/*
                if [ $? -ne 0 ] ; then
                    echo "Can't push to backup system; either the connection failed, or this repository doesn't exist there."
                    echo "There should be a bare repository located at $homepath$remoteGitDir$homerepo"
                    exit
                fi

                git push --quiet "$homepath$remoteGitDir$homerepo" --tags
            )
        done
        local TFSRemote="$(git remote -v | grep -E "^tfs\\W")"
        local originRemote="$(git remote -v | grep -E "^origin\\W")"
        if [[ "${TFSRemote:-}" != "" && "${originRemote:-}" != "" ]] ; then
            echo "Pushing data from origin to TFS"
            git push --quiet tfs refs/remotes/origin/*:refs/heads/*
        fi
    )
}


targetRepo="${1:-}"
if [ ! "$targetRepo" == "" ] ; then
    syncRepo "$targetRepo"
    exit 0
fi

(
    cd "$HOME/dev"
    IFS=$'\n\t'
    user_token="$(git config --get github.access-token)"
    user_name="$(git config --get github.user)"
    if [ "$user_token" == "" ] ; then
        echo "No token present under the github.access-token git config value" >&2
    elif [ "$user_name" == "" ] ; then
        echo "No user name present under the github.user git config value" >&2
    else
        pageNumber=1
        echo "Getting page $pageNumber of your GitHub repositories"
        jsonData="$(curl -s -u $user_name:$user_token https://api.github.com/user/repos | grep full_name | cut -d ':' -f 2 | cut -d '"' -f 2)"
        while [ ${#jsonData} -gt 1 ] ;
        do
            for ghRepo in $jsonData
            do
                repoName="$(echo $ghRepo | cut -d '/' -f 2)"
                if [ ! -d "$repoName" ] && [ ! -d "$(echo $ghRepo | sed 's:/:_:g')" ] ; then
                    echo
                    echo "$repoName doesn't exist locally; cloning from $hubpath$ghRepo"
                    git clone "$hubpath$ghRepo.git"
                    echo
                fi
            done
            pageNumber=$((pageNumber+1))
            echo "Getting page $pageNumber of your GitHub repositories"
            jsonData="$(curl -s -u $user_name:$user_token https://api.github.com/user/repos?page=$pageNumber | grep full_name | cut -d ':' -f 2 | cut -d '"' -f 2)"
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
        jsonData="$(curl -s -u $user_name:$user_token https://api.github.com/users/$user_name/gists | grep git_pull_url | cut -d '"' -f 4)"
        while [ ${#jsonData} -gt 1 ] ;
        do
            for gist in $jsonData
            do
                gistId="$(echo $gist | rev | cut -d '.' -f 2 | cut -d '/' -f 1 | rev)"
                gistUrl="$(echo $gist | sed "s|https://gist.github.com/|$hubpath|" )"
                if [ ! -d "$gistId" ] ; then
                    echo "Gist ID $gistId doesn't exist locally; cloning from $gistUrl"
                    git clone --quiet "$gistUrl"
                fi
            done
            pageNumber=$((pageNumber+1))
            echo "Getting page $pageNumber of your GitHub gists"
            jsonData="$(curl -s -u $user_name:$user_token https://api.github.com/users/$user_name/gists?page=$pageNumber | grep git_pull_url | cut -d '"' -f 4)"
        done
    fi
)


(
    cd "$HOME/dev"
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
