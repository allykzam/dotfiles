#!/bin/bash

set -euo pipefail

# List of files/directories not to symlink
nolinkfiles=(".git" ".gitignore" ".gitmodules" "install.sh" "zshenv" "zsh" "allshrc.sh" ".DS_Store" "logrepos.sh" "gpg.conf" "gpg-agent.conf" "personal_gpg.pub" "work_auth_gpg.pub" "todo.sh" "start-voltron" "windows-terminal-settings.json" "wsl-gpg.sh")

# Things to install:
tools=("vim" "tmux" "git" "zsh" "curl" "wget" "grep" "unzip" "less" "neovim" "dialog" "duf" "httpie" "bat" "exa")
linuxtools=("sudo" "terminus-font" "fbterm" "fbv" "openssh" "sed" "mono" "fontconfig")
osxtools=("gnu-sed" "binutils" "pinentry-mac" "htop" "ykman" "bmon")

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
elif lsb_release -i | grep -q "Ubuntu" ; then
    echo "Installing updates..."
    sudo apt update
    sudo apt upgrade
    pkgmanager="sudo apt install"
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
elif echo "$unameDetails" | grep -q icrosoft ; then
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

if echo "$unameDetails" | grep -q Darwin ; then
    echo "Disabling bash sessions, because OSX 10.11 enabled them"
    touch ~/.bash_sessions_disable
    echo "Setting Finder to show hidden files"
    defaults write com.apple.finder AppleShowAllFiles YES
    echo "Setting Finder to show file extensions"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    echo "Setting Finder to show the path bar"
    defaults write com.apple.finder ShowPathbar -bool true
    echo "Setting Finder to show the full unix path in the title bar"
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    echo "Setting Finder's default view to List"
    defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
    echo "Setting Finder to keep folders at the top of the list (like Windows Explorer)"
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    echo "Setting Finder's search to target the current folder by default"
    defaults write com.apple.finder FXDefaultSearchScope -string SCcf
    echo "Disabling Finder's auto-delete of things in the trash"
    defaults write com.apple.finder FXRemoveOldTrashItems -bool false
    echo "Set default file save location to on-disk (vs iCloud)"
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    echo "Set save dialogs to be expanded by default"
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    echo "Disabling .DS_Store files on network shares"
    defaults write com.apple.desktopservice DSDontWriteNetworkStores true
    echo "Setting title bars to show icons (this may require granting full disk access to the terminal)"
    defaults write com.apple.universalaccess showWindowTitlebarIcons -bool true
    echo "Setting folders on the desktop to stay on top (like the Finder change)"
    defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
    echo "Setting dock to auto-hide"
    defaults write com.apple.dock autohide -bool true
    echo "Disabling recently used apps in the dock"
    defaults write com.apple.dock show-recents -bool false
    echo "Setting Safari to always show the full URL"
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
    echo "Setting Safari to not use universal search"
    defaults write com.apple.Safari UniversalSearchEnabled -bool false
    echo "Setting Safari to not show search suggestions"
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true
    echo "Setting Safari's new tab page to about:blank"
    defaults write com.apple.Safari HomePage -string "about:blank"
    echo "Setting TextEdit to not default to rich text"
    defaults write com.apple.TextEdit RichText -int 0
    echo "Setting TextEdit to prefer plain text"
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
    echo "Setting TextEdit's tab width to 4 spaces"
    defaults write com.apple.TextEdit TabWidth 4
    echo "Disabling smart quotes and emdashes"
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    echo "Setting function keys on Apple keyboards to send their F-code (F1, F2, etc.)"
    defaults write NSGlobalDomain com.apple.keyboard fnState -bool false
    echo "For the function keys change to take effect, you'll need to reboot."
    echo "Disabling gamed so that Game Center isn't hitting the network constantly"
    launchctl disable gui/501/com.apple.gamed
    echo "Setting Parallels (assuming it's installed) to perform better when coherence mode is used"
    defaults write "com.parallels.Parallels Desktop" "Application preferences.CoherenceOsScaling" 1

    killall Finder
    killall Dock
    killall Safari
fi

if [ ! -d "$HOME/dev/posh-git-sh" ] ; then
    echo "Cloning posh-git-sh"
    cd "$HOME/dev"
    git clone github.com:amazingant/posh-git-sh.git || echo "Could not clone posh-git-sh"
fi
