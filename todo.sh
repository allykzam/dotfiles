#!/usr/bin/env bash

IFS=$'\n\t'
set -euo pipefail

# Enable extglob so that we can more-easily match against numbers
shopt -s extglob

# Make sure that the needed files and directory all exist
mkdir -p "$HOME/.local/share/todo_list"
todoFile="$HOME/.local/share/todo_list/current_list"
touch "$todoFile"
doneFile="$HOME/.local/share/todo_list/done_list"
touch "$doneFile"

# If the "todo_list" directory is a git repository, commits changes to any files
# in the directory.
function commitChanges() {
    if [ -e "$HOME/.local/shares/todo_list/.git" ] ; then
        (
            cd "$HOME/.local/shares/todo_list/.git"
            git add .
            git commit -m "$1" 2>/dev/null || true
        )
    fi
}

# Displays the current to-do list with line numbers
function displayTodo() {
    # Clear the display before updating the display
    clear
    # Iterate over every line of the text file, and spit out the contents
    lineNum=0
    while IFS='' read -r line ; do
        lineNum=$((lineNum+1))
        # Do not show the leading timestamp
        echo "$lineNum $(echo "$line" | cut -d ' ' -f 2-)"
    done < "$todoFile"
}


# Moves the most-recent task into the "done" list
function finishTask() {
    # Get the last line of the todo file
    lastLine="$(tail -n 1 "$todoFile")"
    # If the line had contents...
    if [[ "${lastLine:-}" != "" ]] ; then
        # Split off the start date for the task, add the current system time,
        # and add the info into the "done" list.
        date="$(echo "$lastLine" | cut -d ' ' -f 1)"
        task="$(echo "$lastLine" | cut -d ' ' -f 2-)"
        echo "$date $(date -Is) $task" >> "$doneFile"
        # Then use sed to remove the task from the current list
        sed -i ".old" '$d' "$todoFile"
        commitChanges "Finish current task"
    fi
}


# "Resumes" the given task number by moving it to the bottom of the to-do list
function resumeTask() {
    # Grab the specified line number
    line="$1"
    task="$(awk "NR == $1" "$todoFile")"
    # If the line had contents...
    if [[ "${task:-}" != "" ]] ; then
        # Remove the line from the to-do list...
        awk "NR != $1" "$todoFile" > "$todoFile.tmp"
        mv "$todoFile.tmp" "$todoFile"
        # And append it back onto the file
        echo "$task" >> "$todoFile"
        commitChanges "Resume task $1"
    fi
}


# "Pops" the given task number and puts it into the "done" list
function popTask() {
    # Grab the specified line number
    line="$1"
    task="$(awk "NR == $1" "$todoFile")"
    # If the line had contents...
    if [[ "${task:-}" != "" ]] ; then
        # Remove the line from the to-do list...
        awk "NR != $1" "$todoFile" > "$todoFile.tmp"
        mv "$todoFile.tmp" "$todoFile"
        # Split off the start date for the task, add the current system time,
        # and add the info into the "done" list.
        date="$(echo "$line" | cut -d ' ' -f 1)"
        task="$(echo "$line" | cut -d ' ' -f 2-)"
        echo "$date $(date -Is) $task" >> "$doneFile"
        commitChanges "Finished task $1"
    fi
}


# Allows the user to edit the current task
function editTask() {
    # Grab the current task
    task="$(tail -n 1 "$todoFile")"
    # If the line had contents...
    if [[ "${task:-}" != "" ]] ; then
        # Split off the start date for the task
        date="$(echo "$task" | cut -d ' ' -f 1)"
        task="$(echo "$task" | cut -d ' ' -f 2-)"
        # Ask the user to make their modification to the task
        read -e -i "$task" task
        # Remove the current task from the list, and then add it back on with
        # the modification(s)
        sed -i ".old" '$d' "$todoFile"
        echo "$date $task" >> "$todoFile"
        commitChanges "Modified current task"
    fi
}


# Clears the "finished" task list
function clearFinished() {
    > "$doneList"
    commitChanges "Clear finished task list"
}


displayTodo

userInput=
while read -r userInput
do
    doDisplay=true
    case "$userInput" in
        quit | q)
            exit
            ;;
        "pop" | p | "done" | d)
            finishTask
            ;;
        "finished" | f)
            clear
            cat "$doneFile"
            read -r userInput
            ;;
        "clear-finished" | cf)
            clearFinished
            ;;
        "edit" | e)
            editTask
            ;;
        +([0-9]))
            resumeTask "$userInput"
            ;;
        +([0-9])p | p+([0-9]))
            popTask "${userInput//p/}"
            ;;
        "")
            true
            ;;
        **)
            echo "$(date -Is) $userInput" >> "$todoFile"
            ;;
    esac
    if $doDisplay ; then
        displayTodo
    fi
done
