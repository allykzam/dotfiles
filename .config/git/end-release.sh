#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [ ! -d ".git" ] ; then
    echo "Not currently in a git repository?"
    exit 1
fi


branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ ! "$branch" =~ release/.* ]] ; then
    echo "Current branch is not a release branch"
    exit 1
fi

echo "Fetching from 'origin'"
git fetch
git merge "origin/$branch" --ff-only

lastMerge="$(git merge-base origin/main HEAD)"
lastReleaseCommit="$(git rev-parse HEAD)"

RED='\033[0;31m'
CLEAR='\033[0m'
CYAN='\033[0;36m'

if [ ! "$lastMerge" == "$lastReleaseCommit" ] ; then
    echo -e "${RED}Current release branch has not been merged to main yet${CLEAR}"
    exit 1
fi

echo
echo -e "${CYAN}Release branch has been completed; cleaning up${CLEAR}"
echo
echo -e "${CYAN}Updating local 'main' branch${CLEAR}"
git checkout main
git merge origin/main --ff-only
echo
echo -e "${CYAN}Updating local 'dev' branch${CLEAR}"
git checkout dev
git merge origin/dev --ff-only
echo
echo -e "${CYAN}Deleting release branch${CLEAR}"
git branch -d "$branch"
git push origin --delete "$branch"
