#!/usr/bin/env bash

changes="$(git status --porcelain)"
project=""
notes=""

IFS='\n'
while read -r file
do
    if [[ "$file" == *" RELEASE_NOTES.md"* ]]
    then
        notes="$file"
    fi
    if [[ "$file" == *" \"Release Notes.txt\""* ]]
    then
        notes="   Release Notes.txt"
    fi
    if [[ "$file" == *" Source/"* && "$file" == *"/RELEASE_NOTES.md"* ]]
    then
        project=$(dirname "$file")
        project=$(basename "$project")
        notes="$file"
    fi
done <<< "$changes"

if [ "$notes" != "" ]
then
    echo "$notes"
    notes=${notes:3}
    version=$(head "$notes" -n 1 | grep "####" | cut -d ' ' -f 2)
    if [ "$version" == "" ]
    then
        echo "Release notes file does not start with release info:"
        echo "$notes"
        exit 1
    fi
    if [ "$project" == "" ]
    then
        RUNNING_GIT_CLOSE=true git commit -S -m "Update release notes for $version"
    else
        RUNNING_GIT_CLOSE=true git commit -S -m "Update $project release notes for $version"
    fi
fi
