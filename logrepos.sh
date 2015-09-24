#!/bin/bash

name=$(git config --get user.name)

for dir in GitHub/*
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
