export EDITOR=nvim
export PAGER=less
# less -R prints color escape codes directly to output
# less -S stops auto-wrapping of long lines
# less -M adds more verbose positioning info to less' output
export LESS=RSM
# tell zsh to load its dot-files from the dotfiles repo if it exists
if [[ -d "$HOME/dev/dotfiles/zsh" ]] ; then
    export ZDOTDIR="$HOME/dev/dotfiles/zsh"
fi
