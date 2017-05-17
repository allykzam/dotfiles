# Function for running fbterm with a "wallpaper"
function fbterm-wallpaper() {
    local wallpaper="$1"
    # Remove the image path from the arguments
    shift
    # Remove the TTY path from the arguments
    local old_tty="$1"
    shift
    # Hide the cursor
    tput civis
    # Run fbv with the following options:
    # -c => don't clear the screen before/after display (leave it for fbterm)
    # -i => don't show image information
    # -k => stretch the image "using a 'color average' resizing routine"
    # -e => "enlarge" the image to fill the screen
    # -r => ignore aspect ratio while stretching/enlarging
    # Related: need to find a better way to do this; passing an eof in with the
    # letter Q to quit fbv works okay, but leaves a blank spot where the "q" was
    # entered.
    TERM=fbterm fbv -ciker "$wallpaper" << EOF
q
EOF
    # Show the cursor again
    tput cnorm
    # Run fbterm with a background image, and set TERM; pass any remaining args
    OLD_TTY="$old_tty" CURRENT_WALLPAPER="$wallpaper" FBTERM_BACKGROUND_IMAGE=1 TERM=fbterm fbterm "$@"
}

# When running directly on the linux ttys
if [[ "$TERM" == "linux" ]] ; then
    case $(tty) in
        /dev/tty10)
            ;;
        /dev/tty[0-9]*)
            # Try to turn on numlock, but make sure return code is 0 even if it
            # doesn't work.
            setleds -D +num && true
            # Decide what wallpaper to use. If a tty-specific wallpaper exists,
            # use it; if not, check for a generic wallpaper.
            ttynum=$(tty)
            ttynum=${ttynum/\/dev\/tty/}
            if [ -d "$HOME/.config/fbterm/wallpaper/random" ] ; then
                wallpaper="$(shuf -n1 -e $HOME/.config/fbterm/wallpaper/random/*.jpg)"
            elif [ -f "$HOME/.config/fbterm/wallpaper$ttynum.jpg" ]; then
                wallpaper="$HOME/.config/fbterm/wallpaper$ttynum.jpg"
            elif [ -f "$HOME/.config/fbterm/wallpaper.jpg" ]; then
                wallpaper="$HOME/.config/fbterm/wallpaper.jpg"
            else
                wallpaper=""
            fi
            if [[ "$wallpaper" != "" ]]; then
                fbterm-wallpaper "$wallpaper" "$(tty)" "$@"
            else
                OLD_TTY="$(tty)" TERM=fbterm fbterm
            fi
            # After fbterm exits, exit bash too
            exit
            ;;
        /dev/pts/[0-9]*)
            # If on a pseudo-terminal, check to see if the TMUX var is set
            if [[ "${TMUX:-}" != "" ]] ; then
                # If in tmux, just set TERM
                export TERM=fbterm
            else
                # If not in tmux yet, set TERM, fix white, and start tmux
                export TERM=fbterm
                echo -en "\e[3;7;255;255;255}"
#                CURRENT_WALLPAPER="${CURRENT_WALLPAPER:-}" tmux
#                # Exit bash after tmux closes
#                exit
            fi
            ;;
        *)
    esac
fi

function show_git_status() {
    local header RED GREEN BLUE NC dir repo
    header="WTree,  Issue #, Stash -- Repository"
    RED='\033[0;31m'
    GREEN='\033[1;32m'
    BLUE='\033[1;34m'
    NC='\033[0m'
    function getStats() {
        local dir gitDir print issues branchName stashes MATCH MBEGIN MEND

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
        issues=""
        if (git update-index --ignore-submodules --really-refresh > /dev/null && git diff-files --quiet --ignore-submodules && git diff-index --cached --quiet HEAD --ignore-submodules) ; then
            issues="Clean,"
        else
            issues="${RED}Dirty${NC},"
            print=1
        fi

        branchName="$(git rev-parse --abbrev-ref HEAD)"
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
            issues="$issues [${BLUE}$stashes${NC}]"
        else
            declare -R3 stashes
            issues="$issues [  0]"
        fi

        if [[ "$issues" != "" && "$print" == "1" ]] ; then
            echo "$issues -- $(basename "$dir")"
        fi
    }
    for dir in ~/GitHub/* ; do
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

# When running on OSX...
if [ "$(uname)" '==' "Darwin" ]; then
    # Reset the path with the gnubin stuff up-front so that the GNU version of
    # coreutils (thank-you, homebrew) gets used instead of OSX's BSD versions
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    # MANPATH is also here for GNU coreutils
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
fi

# The "g" stands for "good" because the macOS version of /usr/bin/strings should
# be called "sstrings" (the "s" is for "sucks"). If "gstrings" exists on the
# local system, alias "strings" to it so that e.g. the `-e` flag will be
# available.
gstrings="$(which gstrings || true)"
if [[ "${gstrings:-}" != "" ]]; then
    alias "strings=$gstrings"
fi

# Add these so there's a place in the home directory to put binaries
export PATH="$HOME/.local/bin:$HOME/.local/lib:$PATH"

# Typo aliases for git
alias got=git
alias gti=git
alias gut=git

# Alias for neovim so it doesn't think it can't use colors
#alias nvim="TERM=xterm-256color nvim"

# Alias "todo" as the to-do script
alias todo="$HOME/GitHub/dotfiles/todo.sh"

# If running in GNU screen and screen_term_name is set, check to see if it's a
# GitHub project; if so, cd there and let screen move on. I use this at work to
# auto-open screen with three panes for `git log`, `git diff`, and `git commit`.
if [[ "${screen_term_name:-}" != "" ]] ; then
    if [ -d "$HOME/GitHub/$screen_term_name" ] ; then
        cd "$HOME/GitHub/$screen_term_name"
    fi
    unset screen_term_name
fi

# Custom function for "sudo" so that we get a fun error message as a result
sudopath="$(which sudo)"
sudo(){
    $sudopath true
    local sudoSuccess=$?
    if [ $sudoSuccess -eq 0 ] ; then
        $sudopath $@
    else
        echo "sudon't"
    fi
}

# Calls grep and passes the -i flag, to make it case insensitive
grepi(){
    grep -i $@
}

# Use gpg-agent for ssh keys
if [[ "$(uname)" == "Darwin" ]]; then
    SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"
    gpg-connect-agent /bye
else
    SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    gpg-agent --daemon --pinentry-program /usr/bin/pinentry > /dev/null 2>&1
fi
export SSH_AUTH_SOCK

# Alias for the logrepos script
alias logrepos=$HOME/GitHub/dotfiles/logrepos.sh

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
        # directory under ~/GitHub, then use that as the target path instead of
        # the current directory
        if [[ "${1:-}" != "" ]]; then
            if [ -d "$HOME/GitHub/${1:-}" ]; then
                export TMUXGITPATH="$HOME/GitHub/${1:-}"
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
        if [[ "${TMUXGITSIZE:-}" == "131 150" ]]; then
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
        if [[ "${TMUXDASHBOARDSIZE:-}" == "131 150" ]]; then
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
                    mutt
                else
                    echo "Re-running the dashboard in this tmux pane would cause additional panes to be created. Just call 'mutt' again."
                fi
            elif [[ "${TMUX_PANE:-}" == "%1" ]] ; then
                sleep 1 ; clear
            elif [[ "${TMUX_PANE:-}" == "%2" ]] ; then
                sleep 1 ; $HOME/GitHub/dotfiles/todo.sh
            elif [[ "${TMUX_PANE:-}" == "%3" ]] ; then
                while [ 1 ]
                do
                    output=$(show_git_status)
                    clear
                    echo "$output"
                    sleep 300
                done
            elif [[ "${TMUX_PANE:-}" == "%4" ]] ; then
                while [ 1 ]
                do
                    cal
                    echo
                    # 'q' disables the caption
                    # 'Q' disables the city name -- I know where I am
                    # '0' indicates that I want zero days' forecast
                    (wget -qO - "wttr.in/${WEATHER_LOCATION:-}\?q\&Q\&0" 2>/dev/null || true)
                    sleep 300
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
