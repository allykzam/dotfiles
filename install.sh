#!/bin/bash

set -euo pipefail

# List of files/directories not to symlink
nolinkfiles=(".git" ".gitignore" ".gitmodules" "install.sh" "zshenv" "zsh" "allshrc.sh" ".DS_Store" "logrepos.sh" "gpg.conf" "gpg-agent.conf" "personal_gpg.pub" "work_auth_gpg.pub" "todo.sh" "start-voltron")

# Things to install:
tools=("vim" "tmux" "git" "zsh" "curl" "wget" "grep" "unzip" "less" "neovim" "dialog")
linuxtools=("sudo" "terminus-font" "fbterm" "fbv" "openssh" "sed" "mono" "fontconfig")
osxtools=("gnu-sed" "binutils" "mono")

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
    tools=("${tools[@]}" "${osxtools[@]}")
fi

# If running on WSL on a Win10 box, assume the user is going to deal with
# installing things themselves.
if echo "$unameDetails" | grep -q Microsoft ; then
    echo "You appear to be running bash on ubuntu on Windows on..."
    echo "You will need to manually delete the file /etc/zsh/zshenv, and"
    read -r p "install any missing packages. Have you done all of this? [y/N] " response
    case $response in
        [yY][eE][sS]|[yY])
            echo "Continuing..."
            ;;
        *)
            return
            ;;
    esac

# If a command was selected, run it; if not, complain to the user
elif [ "$pkgmanager" == "" ] ; then
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
    if grep -q ^NAutoVTs=10 /etc/systemd/logind.conf ; then
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
            linkpath="$(readlink "$HOME/$filename" || : )"
            if [ "$linkpath" '==' "$file" ] ; then
                echo "Skipping $filename; already up-to-date."
            elif [ "$linkpath" '==' "" ] ; then
                echo "File or folder exists for $filename; skipping"
            else
                echo "Fixing symlink for $filename"
                rm "$HOME/$filename"
                ln -s "$file" "$HOME/$filename"
            fi
        else
            echo "Symlinking $filename"
            ln -s "$file" "$HOME/$filename"
        fi
    fi
done

zshenvpath=""
if echo "$unameDetails" | grep -q ARCH ; then
    zshenvpath="/etc/zsh/zshenv"
elif echo "$unameDetails" | grep -q Microsoft ; then
    zshenvpath="/etc/zsh/zshenv"
elif echo "$unameDetails" | grep -q Darwin ; then
    zshenvpath="/etc/zshenv"
fi
if [ "$zshenvpath" == "" ] ; then
    echo "Unable to determine target zshenv path, skipping..."
elif [ ! -e "$zshenvpath" ] ; then
    echo "Symlinking zshenv"
    sudo ln -s "$HOME/dev/dotfiles/zshenv" "$zshenvpath"
else
    echo "Skipping zshenv"
fi

if [ ! -d "$HOME/.gnupg" ]; then
    mkdir "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
fi
if [ ! -e "$HOME/.gnupg/gpg.conf" ]; then
    ln -s "$HOME/dev/dotfiles/gpg.conf" "$HOME/.gnupg/gpg.conf"
fi
if [ ! -e "$HOME/.gnupg/gpg-agent.conf" ]; then
    ln -s "$HOME/dev/dotfiles/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
fi

if echo "$unameDetails" | grep -q ARCH ; then
    # Set-up the current user as a member of the "video" group so that
    # they can access the framebuffer devices (otherwise fbterm will
    # break on startup)
    echo "Setting user $USER as a member of the video group for fbterm"
    sudo gpasswd -a "$USER" video
    # According to the arch wiki page on fbterm, this enables keyboard
    # shortcuts for non-root users
    echo "Adding capability to use keyboard shortcuts"
    sudo setcap 'cap_sys_tty_config+ep' /usr/bin/fbterm
fi

echo "Setting-up submodules (so that vim plugins show up)"
(
    cd $(dirname $0)
    git submodule update --init --recursive
    echo "Setting up the vim-fsharp package so it works :)"
    cd .vim/bundle/vim-fsharp
    make
)

if echo "$unameDetails" | grep -q Darwin ; then
    echo "Disabling bash sessions, because OSX 10.11 enabled them"
    touch ~/.bash_sessions_disable
fi

if [ ! -d "$HOME/dev/posh-git-sh" ] ; then
    echo "Cloning posh-git-sh"
    cd "$HOME/dev"
    git clone github.com:amazingant/posh-git-sh.git || echo "Could not clone posh-git-sh"
fi
