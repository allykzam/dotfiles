# When running directly on the linux ttys
if [[ "$TERM" == "linux" ]] ; then
    case $(tty) in
        /dev/tty10)
            ;;
        /dev/tty[0-9]*)
            # Try to turn on numlock, but make sure return code is 0 even if it
            # doesn't work.
            setleds -D +num && true
            ;;
        *)
    esac
fi

function show_git_status() {
    local header RED GREEN BLUE YELLOW NC dir repo
    header="WTree,   Issue  #, Stash, UnRel -- Repository"
    RED='\033[0;31m'
    GREEN='\033[1;32m'
    BLUE='\033[1;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    function getStats() {
        local dir gitDir print printReason issues branchName upstream localChanges remoteChanges unreleasedChanges stashes MATCH MBEGIN MEND

        dir="$1"
        if [ -f "$dir" ] ; then
            exit
        fi
        cd "$dir" || exit
        gitDir=$(git rev-parse --git-dir 2>&1 || true)
        if [[ "$gitDir" != ".git" ]] ; then
            exit
        fi

        print=0
        printReason=""
        issues=""
        if (git update-index --ignore-submodules --really-refresh > /dev/null && git diff-files --quiet --ignore-submodules && git diff-index --cached --quiet HEAD --ignore-submodules) ; then
            issues="Clean,"
        else
            issues="${RED}Dirty${NC},"
            print=1
        fi

        branchName="$(git rev-parse --abbrev-ref HEAD)"
        upstream="$(git config --get "branch.$branchName.remote" || true)"
        if [[ "$upstream" != "" ]]; then
            upstream="$(git rev-list --left-right --count "$branchName...$upstream/$branchName" 2>/dev/null || true)"
        fi

        if [[ "$branchName" =~ issue/.* ]] ; then
            branchName="#$(basename "$branchName")"
            print=1
            declare -R8 branchName
            issues="$issues [${GREEN}$branchName${NC}],"
        elif [[ "$branchName" =~ release/.* ]] ; then
            if [[ "$branchName" =~ release/v.* ]] ; then
                branchName="$(basename "$branchName")"
            else
                branchName="v$(basename "$branchName")"
            fi
            print=1
            declare -R8 branchName
            issues="$issues [${GREEN}$branchName${NC}],"
        else
            declare -L8 branchName
            issues="$issues [$branchName],"
        fi

        stashes="$(wc -l "${dir}.git/logs/refs/stash" 2>/dev/null | xargs | cut -d ' ' -f 1)"
        if [[ "$stashes" != "0" && "$stashes" != "" ]] ; then
            print=1
            declare -R3 stashes
            issues="$issues [${BLUE}$stashes${NC}],"
        else
            declare -R3 stashes
            issues="$issues [  0],"
        fi

        if [[ "$branchName" != "main" ]] ; then
            unreleasedChanges="$(git log HEAD ^origin/main --no-merges --oneline --no-show-signature 2>/dev/null | wc -l | sed 's/ //g')"
            if [[ "$unreleasedChanges" != "0" && "$unreleasedChanges" != "" ]] ; then
                print=1
                declare -R3 unreleasedChanges
                issues="$issues [${GREEN}$unreleasedChanges${NC}]"
            else
                issues="$issues [  0]"
            fi
        else
            issues="$issues [  0]"
        fi

        if [[ "$upstream" != "" && "$upstream" != "$(echo -e '0\t0')" ]]; then
            localChanges="$(echo "$upstream" | cut -f 1)"
            remoteChanges="$(echo "$upstream" | cut -f 2)"
            if [[ "$localChanges" == "0" && "$remoteChanges" != "0" ]] ; then
                upstream="${RED}↓${NC} "
            elif [[ "$localChanges" != "0" && "$remoteChanges" == "0" ]] ; then
                upstream="${GREEN}↑${NC} "
            else
                upstream="${YELLOW}X${NC} "
            fi
            print=1
        else
            upstream=""
        fi

        if [[ "$issues" != "" && "$print" == "1" ]] ; then
            echo "$issues -- $upstream$(basename "$dir")"
        fi
    }
    for dir in ~/dev/* ~/gists/* ; do
        repo=$(getStats "$dir")
        if [[ "$repo" != "" ]] ; then
            if [[ "$header" != "" ]] ; then
                echo "$header"
                header=""
            fi
            echo -e "$repo"
        fi
    done
}

# Add these so there's a place in the home directory to put binaries
export PATH="$HOME/.local/bin:$HOME/.local/lib:$PATH"

if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Turn off telemetry for "dotnet" commands
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Typo aliases for git
alias got=git
alias gti=git
alias gut=git

# Alias "todo" as the to-do script
alias todo="$HOME/dev/dotfiles/todo.sh"

cdgit(){
    cd ~/dev/$1
    echo -n -e "\033]0;$(basename "$(pwd)")\007"
}

localUname="$(uname -a)"
if [[ "$(uname)" == "Darwin" ]]; then
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_BAT=1
    export HOMEBREW_DISPLAY_INSTALL_TIMES=1
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_GITHUB_API=1
    export HOMEBREW_NO_INSTALL_FROM_API=1
    export HOMEBREW_NO_INSTALL_UPGRADE=1
    export HOMEBREW_CASK_OPTS="--require-sha"

    heic() {
        (
            cd ~/Downloads
            for i in *.heic(:r) ;
            do
                sips -s format jpeg "$i.heic" --out "$i.jpg"
            done
        )
    }
fi

# Alias for the logrepos script
alias logrepos=$HOME/dev/dotfiles/logrepos.sh


# This is a helper for use on NixOS, which grabs the git commit for the current
# environment, checks for updates, and then grabs the git commit for the updated
# environment. If the commits differ, it produces a GitHub URL where the changes
# can be reviewed. This is not quite as helpful as pacman's `VerbosePkgLists`
# option on Arch linux, but is good enough that I can see which things I might
# break by updating.
nix-check-update(){
    local oldCommit, newCommit

    oldCommit=$(sudo nix-instantiate --find-file nixpkgs)
    oldCommit=$(dirname "$oldCommit")
    oldCommit=$(readlink "$oldCommit" | rev | cut -d '.' -f 1 | rev | cut -d '/' -f 1)

    sudo nix-channel --update nixos

    newCommit=$(sudo nix-instantiate --find-file nixpkgs)
    newCommit=$(dirname "$newCommit")
    newCommit=$(readlink "$newCommit" | rev | cut -d '.' -f 1 | rev | cut -d '/' -f 1)

    if [[ "${newCommit:-}" == "${oldCommit:-}" ]] ; then
        echo "Nothing has changed"
    else
        echo "Changes can be reviewed here:"
        echo "https://github.com/NixOS/nixpkgs-channels/compare/$oldCommit...$newCommit"
        echo "If they look good, run:"
        echo "sudo nixos-rebuild switch"
    fi
}



# Function for starting tmux and configuring it for git on different machines
#
# This currently chooses its setup based on the console size, so that, e.g., all
# of my *nix boxes running fbterm with the same screen resolution will get the
# same configuration, while allowing my work machine can get a different one (I
# keep Terminal.app open on a 1920x1080 monitor rotated portrait at work).
tmuxgit(){
    # This function has X stages:
    #
    # Stage 1 starts tmux
    #
    # Stage 2 configures panes based on the console size
    #
    # Stage 3 changes directory to the target location

    # If TMUXGIT isn't set yet, move to stage 1
    if [[ "${TMUXGIT:-}" == "" ]]; then
        export TMUXGITPATH="$(pwd)"

        # If the user gave an argument, and it's contents matches the name of a
        # directory under ~/dev, then use that as the target path instead of the
        # current directory
        if [[ "${1:-}" != "" ]]; then
            if [ -d "$HOME/dev/${1:-}" ]; then
                export TMUXGITPATH="$HOME/dev/${1:-}"
                printf '\e]1;%s\a' "dev/${1:-}"
            fi
        fi

        export TMUXGITSIZE="$(stty size)"
        # If already running under tmux, just set TMUXGIT=1 and start over
        if [[ "${TMUX:-}" != "" ]]; then
            export TMUXGIT=1
            tmuxgit

        # Otherwise, start tmux
        else
            if [[ "${1:-}" == "" ]]; then
                TMUXGIT=1 tmux
            else
                TMUXGIT=1 tmux -L "${1:-}"
            fi
        fi

    elif [[ "${TMUXGIT:-}" == "2" ]]; then
        cd "$TMUXGITPATH"
        export TMUXGIT=3

    # If stage 1 just finished, start stage 2 by creating new panes and then
    # setting TMUXGIT=2 (set it after creating a new pane so that each pane
    # has to run through this too
    elif [[ "${TMUXGIT:-}" == "1" ]]; then
        # System-specifics here:

        # This is my 1920x1080 monitor in portrait orientation at work. It gets
        # three panes; a large top pane for `git diff` and `git lg1`, a smaller
        # pane that I usually use for `git commit`, and then an even smaller one
        # that I use for `git commit` when I find myself needing `git lg1` up
        # top /and/ `git diff` in the middle pane. Weird, but it works for me.
        if [[ "${TMUXGITSIZE:-}" == "123 152" ]]; then
            if [[ "${TMUX_PANE:-}" == "%0" ]]; then
                tmux split-window -v
                tmux resize-pane -D 19

            elif [[ "${TMUX_PANE:-}" == "%1" ]]; then
                tmux split-window -v
                tmux resize-pane -D 7

            elif [[ "${TMUX_PANE:-}" == "%2" ]]; then
                tmux select-pane -t 0
            fi

        # This is an old Dell laptop I found at a thrift store for about $20?
        # Circa 2003, it's running a Pentium 4M and has a screen-size of
        # 1280x800. Works well enough for little things. It gets two panes
        # side-by-side, where the left one is for `git lg1` and `git diff`, and
        # the right one is for `git commit`. Not sure what to do with the extra
        # vertical space just yet? At any rate, I also only want this setup on
        # a particular tty (I use 10 of them on that system). The rest of my
        # ttys are likely to have neovim/vim open, which has its own
        # split-screen abilities.
        elif [[ "${TMUXGITSIZE:-}" == "66 213" && "${OLD_TTY:-}" == "/dev/tty1" ]]; then
            if [[ "${TMUX_PANE:-}" == "%0" ]]; then
                tmux split-window -h
                tmux resize-pane -R 20
            elif [[ "${TMUX_PANE:-}" == "%1" ]]; then
                tmux select-pane -t 0
            fi
        else
            echo "Uhh, your screen size isn't set-up yet?"
        fi

        export TMUXGIT=2
        tmuxgit
    fi
}

# If the shell just started and is partway through configuring the tmuxgit
# stuff, start it back up
if [[ "${TMUXGIT:-}" != "" ]]; then
    tmuxgit
fi


# Function for starting tmux and configuring it for a "dashboard" on different
# machines
dashboard(){
    # This function has X stages:
    #
    # Stage 1 starts tmux
    #
    # Stage 2 configures panes based on the console size

    # IF TMUXDASHBOARD isn't set yet, move to stage 1
    if [[ "${TMUXDASHBOARD:-}" == "" ]]; then
        export TMUXDASHBOARDSIZE="$(stty size)"
        printf '\e]1;%s\a' "dashboard"
        # If already running under tmux, just set TMUXDASHBOARD=1 and start over
        if [[ "${TMUX:-}" != "" ]]; then
            export TMUXDASHBOARD=1
            dashboard

        # Otherwise, start tmux
        else
            TMUXDASHBOARD=1 tmux -L tmux_dashboard
        fi

    elif [[ "${TMUXDASHBOARD:-}" == "1" ]]; then
        # System-specifics here:

        # This is my 1920x1080 monitor in portrait orientation at work. It gets
        # five panes; a large top pane for neomutt, a middle section divided
        # into an unclaimed pane I use for terminal commands and a section that
        # shows the output from `show_git_status`, and a bottom section divided
        # into my current "to-do list" and the current weather/calendar.
        if [[ "${TMUXDASHBOARDSIZE:-}" == "123 152" ]]; then
            if [[ "${TMUX_PANE:-}" == "%0" ]]; then
                if [[ "$(tmux list-panes | wc -l)" == "1" ]] ; then
                    tmux split-window -v
                    tmux split-window -v -t "%1"
                    tmux split-window -h -t "%1"
                    tmux split-window -h -t "%2"
                    tmux resize-pane -t "%0" -D 29
                    tmux resize-pane -t "%1" -D 16
                    tmux resize-pane -t "%1" -R 14
                    tmux resize-pane -t "%2" -R 44
                    tmux select-pane -t "%2"
                    tmux select-pane -t "%1"
                    tmux select-pane -t "%0"
                    neomutt
                else
                    echo "Re-running the dashboard in this tmux pane would cause additional panes to be created. Just call 'neomutt' again."
                fi
            elif [[ "${TMUX_PANE:-}" == "%1" ]] ; then
                sleep 1 ; clear
            elif [[ "${TMUX_PANE:-}" == "%2" ]] ; then
                sleep 1 ; $HOME/dev/dotfiles/todo.sh
            elif [[ "${TMUX_PANE:-}" == "%3" ]] ; then
                while [ 1 ]
                do
                    output=$(show_git_status)
                    clear
                    echo "$output"
                    sleep 900
                done
            elif [[ "${TMUX_PANE:-}" == "%4" ]] ; then
                while [ 1 ]
                do
                    cal
                    echo
                    # 'q' disables the caption
                    # 'Q' disables the city name -- I know where I am
                    # '0' indicates that I want zero days' forecast
                    (wget -qO - "wttr.in/${WEATHER_LOCATION:-}\?q\&Q\&0" 2>/dev/null | sed 's/Thunderstorm/TStorm/' | sed 's/In Vicinity/Nearby/' || true)
                    sleep 900
                done
            fi

        else
            echo "Uhh, your screen size isn't set-up yet?"
        fi
    fi
}

# If the shell just started and is partway through configuring the dashboard
# stuff, just start it back up
if [[ "${TMUXDASHBOARD:-}" != "" ]]; then
    dashboard
fi
