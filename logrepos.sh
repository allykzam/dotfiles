#!/bin/bash

name=$(git config --get user.name)
commits=""
repos=0

for dir in ~/git/* ~/gists/*
do
    data=$(
        cd "$dir" || exit
        if [ ! -e ".git" ]; then
            exit
        fi
        log=$(git shortlog -s --author="$name" --since="$1")
        log=${log/$name/}
        if [ ! "$log" == "" ]; then
            echo "$log -- $(basename $dir)"
        fi
    )
    if [ ! "$data" == "" ]; then
        repos=$((repos+1))
        commits="$commits
$data"
    fi
done

echo "$repos repositories have changes since '$1':"
echo "$commits"

for dir in ~/git/* ~/gists/*
do
    (
        cd "$dir" 2>/dev/null
        log=$(git lg1 --since="$1" --author="$name"  2>/dev/null)
        if [ "$log" == "" ]; then
            true
        else
            echo
            echo "$dir"
            echo
            echo "$log"
        fi
    )
done
