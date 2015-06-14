source "$HOME/GitHub/dotfiles/allshrc.sh"

# Any command that starts with whitespace is kept out of the history
declare -x HISTCONTROL=ignorespace

# If there's anything else machine-specific in .local, run it
if [ -e "$HOME/.local/.bashrc" ] ; then
    source "$HOME/.local/.bashrc"
fi

