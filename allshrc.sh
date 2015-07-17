# Function for running fbterm with a "wallpaper"
function fbterm-wallpaper() {
    local wallpaper=$1
    # Remove the image path from the arguments
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
    CURRENT_WALLPAPER="$wallpaper" FBTERM_BACKGROUND_IMAGE=1 TERM=fbterm fbterm "$@"
}

# When running directly on the linux ttys
if [[ "$TERM" == "linux" ]] ; then
    case $(tty) in
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
                fbterm-wallpaper "$wallpaper" "$@"
            else
                TERM=fbterm fbterm
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
                CURRENT_WALLPAPER="${CURRENT_WALLPAPER:-}" tmux
                # Exit bash after tmux closes
                exit
            fi
            ;;
        *)
    esac
fi

# When running on OSX...
if [ "$(uname)" '==' "Darwin" ]; then
    # Reset the path with the gnubin stuff up-front so that the GNU version of
    # coreutils (thank-you, homebrew) gets used instead of OSX's BSD versions
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    # MANPATH is also here for GNU coreutils
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
fi

# Add these so there's a place in the home directory to put binaries
export PATH="$PATH:~/.local/bin:~/.local/lib"

# Typo aliases for git
alias got=git
alias gti=git
alias gut=git

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
local sudopath="$(which sudo)"
sudo(){
    $sudopath true
    local sudoSuccess=$?
    if [ $sudoSuccess -eq 0 ] ; then
        $sudopath $@
    else
        echo "sudon't"
    fi
}

