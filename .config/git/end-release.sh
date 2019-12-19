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

lastMerge="$(git merge-base origin/master HEAD)"
lastReleaseCommit="$(git rev-parse HEAD)"

if [ ! "$lastMerge" == "$lastReleaseCommit" ] ; then
    echo "Current release branch has not been merged to master yet"
    exit 1
fi

echo
echo "Release branch has been completed; cleaning up"
echo
echo "Updating local 'master' branch"
git checkout master
git merge origin/master --ff-only
echo
echo "Updating local 'dev' branch"
git checkout dev
git merge origin/dev --ff-only
echo
echo "Deleting release branch"
git branch -d "$branch"
git push origin --delete "$branch"
