#!/bin/bash

set -euo pipefail

# List of files/directories not to symlink
nolinkfiles=(".git" ".gitignore" ".gitmodules" "install.sh" "zshenv" "zsh")

# Things to install:
tools=("vim" "tmux" "git" "zsh" "curl" "wget" "grep" "sed" "unzip" "less" "mono")
linuxtools=("sudo" "terminus-font" "fbterm" "fbv" "openssh")

# OS information
unameDetails=$(uname -a)

# Figure out what package manager commands to use
pkgmanager=""
if echo "$unameDetails" | grep -q ARCH ; then
    # Install updates
    echo "Installing updates..."
    sudo pacman -Suy
    # Use `sudo pacman -S` on arch linux
    pkgmanager="sudo pacman -S --needed"
    # Add linux stuff to the list of things to install
    tools=("${tools[@]}" "${linuxtools[@]}")
elif echo "$unameDetails" | grep -q Darwin ; then
    echo "Installing updates..."
    brew update
    brew upgrade
    pkgmanager="brew install"
fi

# If a command was selected, run it; if not, complain to the user
if [ "$pkgmanager" == "" ] ; then
    read -r -p "Unknown system. Continue? [y/N] " response
    case $response in
        [yY][eE][sS]|[yY])
            echo "Continuing..."
            ;;
        *)
            return
            ;;
    esac
else
    echo "Installing packages..."
    installCmd="$pkgmanager ${tools[@]}"
    $installCmd && :
fi

# If systemd is installed on this system and there's a logind.conf file
if [ -e "/etc/systemd/logind.conf" ] ; then
    echo "Setting systemd to provide 10 ttys at startup..."
    # If the logind.conf file contains a line for how many virtual ttys to start
    if grep -vq ^NAutoVTs=10 /etc/systemd/logind.conf ; then
        :
    elif grep -vq ^NAutoVTs /etc/systemd/logind.conf ; then
        # Replace the number of ttys with 10
        sudo sed -i s/NAutoVTs=.*/NAutoVTs=10/g /etc/systemd/logind.conf
    else
        # Else, add the line to the end of the file.
        sudo echo "NAutoVTs=10" >> /etc/systemd/logind.conf
    fi
fi

# Helper for checking arrays for values
function containsElement () {
    local e
    for e in "${@:2}"; do
        [[ "$e" == "$1" ]] && return 0
    done
    return 1
}

pushd "$(dirname "$0")" > /dev/null
SCRIPTHOME="$(pwd)"
popd > /dev/null

shopt -s dotglob
for file in $SCRIPTHOME/* ; do
    filename="$(basename "$file")"
    if containsElement "$filename" "${nolinkfiles[@]}" ; then
        # Do nothing if the file/directory is blacklisted
        :
    else
        if [ -e "$HOME/$filename" ] ; then
            echo "Skipping $filename; already exists"
        else
            echo "Symlinking $filename"
            ln -s "$file" "$HOME/$filename"
        fi
    fi
done

echo "Linking zshenv..."
if echo "$unameDetails" | grep -q ARCH ; then
    sudo ln -s "$HOME/GitHub/dotfiles/zshenv" "/etc/zsh/zshenv"
elif echo "$unameDetails" | grep -q Darwin ; then
    sudo ln -s "$HOME/GitHub/dotfiles/zshenv" "/etc/zshenv"
fi

