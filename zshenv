# This is added to the global zshenv file by homebrew; since I use my dotfiles
# on both Arch Linux and OSX, it makes sense to keep this around. :)
if [ -x /usr/libexec/path_helper ]; then
    eval `/usr/libexec/path_helper -s`
fi

export EDITOR=nvim
export PAGER=less
# less -R prints color escape codes directly to output
# less -S stops auto-wrapping of long lines
# less -M adds more verbose positioning info to less' output
export LESS=RSM
# tell zsh to load its dot-files from the dotfiles repo if it exists
if [[ -d "$HOME/GitHub/dotfiles/zsh" ]] ; then
    export ZDOTDIR="$HOME/GitHub/dotfiles/zsh"
fi
