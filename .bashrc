source "$HOME/git/dotfiles/allshrc.sh"

# Any command that starts with whitespace is kept out of the history
declare -x HISTCONTROL=ignorespace

# If there's anything else machine-specific in .local, run it
if [ -e "$HOME/.local/.bashrc" ] ; then
    source "$HOME/.local/.bashrc"
fi
if [ -e "$HOME/.local/.allshrc" ] ; then
    source "$HOME/.local/.allshrc"
fi


# Set-up the prompt to do the posh-git stuff
posh_git_path="$HOME/git/posh-git-bash/git-prompt.sh"
posh_git_command='__git_ps1 "\u@\h:\w" "\\\$ "'
posh_gitmode_command='__git_ps1 "\u@\h:\w" "-> "'
normal_ps1='\u@\h:\w\$ '
gitmode_ps1='\u@\h:\w-> '
if [ -e "$posh_git_path" ]; then
    source "$posh_git_path"
    PROMPT_COMMAND="$posh_git_command"
else
    PS1="$normal_ps1"
fi

