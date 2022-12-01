# This is my zshrc file. I started it by opening zsh's documents and reading
# about every option in the Options section. If the options seem to be in the
# exact same order as they're defined there, and/or you don't like that I used
# UPPER_SNAKE_CASE like they did, now you know why. :)

#### Changing Directories
setopt NO_AUTO_CD               # keep auto-cd disabled
setopt AUTO_PUSHD               # works like Windows Explorer's back button; use
                                # popd to go back one directory, use pushd to
                                # add a directory to the stack. with this
                                # enabled, cd automatically acts like pushd ran
                                # too.
setopt CDABLE_VARS              # running "cd dev" from /etc/ will cd to ~/dev
                                # (assuming there's no /etc/git)
setopt CHASE_DOTS               # if ~/.vim/ is a symlink to
                                # ~/dev/dotfiles/vim then running `cd ~/.vim/..`
                                # takes you to ~/dev/dotfiles/
setopt CHASE_LINKS              # this is similar to CHASE_DOTS, but now doing
                                # `cd ~/.vim` will take you directly to
                                # ~/dev/dotfiles/vim/ as well
setopt NO_PUSHD_IGNORE_DUPS     # not sure why you'd want this on
#setopt PUSHD_MINUS              # haven't used the stack enough to know if I
                                # want this or not
setopt NO_PUSHD_SILENT          # popd/pushd should echo the dir name
setopt NO_PUSHD_TO_HOME         # would make `pushd` = `pushd $HOME`
DIRSTACKSIZE=20                 # keep the last 20 directories in the stack


#### Completion
# I haven't used completion at all thus-far, so no options for it here yet.

#### Expansion and Globbing
setopt BAD_PATTERN              # complain if a pattern is malformed
setopt NO_CASE_GLOB             # don't do case-sensitive globbing
setopt GLOB                     # enable globbing
setopt NO_GLOB_ASSIGN           # don't glob `x=y*`, use `x=(y*)` instead
setopt MARK_DIRS                # add '/' to the end of dirs matched w/globbing
setopt MULTIBYTE                # honor multi-byte characters
setopt NOMATCH                  # complain if a pattern doesn't match anything
setopt NO_NULL_GLOB             # would erase a pattern that matches nothing
                                # chances are if a pattern matches nothing, I
                                # want to fix it, not remove it.
setopt NUMERIC_GLOB_SORT        # take the time to sort numeric glob results
                                # numerically vs alphabetically
setopt RC_EXPAND_PARAM          # glob 'foo${xx}bar' when xx = (a b c) =
                                # (fooabar foobbar foocbar) vs fooa b cbar
setopt REMATCH_PCRE             # use perl-compatible regexes w/regex matching
setopt NO_UNSET                 # complain on glob `*$var` when $var empty/unset
setopt WARN_CREATE_GLOBAL       # complain if a function creates a global var


#### History
export HISTFILE=~/.zsh_history  # leave the history stored in $HOME
export HISTSIZE=1000000         # nice big in-memory history
export SAVEHIST=1000000         # nice big on-disk history
setopt APPEND_HISTORY           # append history to the history file on exit
setopt EXTENDED_HISTORY         # track history with timestamps and durations
setopt HIST_BEEP                # beep on access history that doesn't exist
setopt HIST_EXPIRE_DUPS_FIRST   # removes duplicate history entries from the
                                # history first if saving and HISTSIZE>SAVEHIST.
                                # this doesn't matter when HISTSIZE=SAVEHIST,
                                # but for some machines HISTSIZE>SAVEHIST due to
                                # memory:disk ratio, etc.
setopt HIST_IGNORE_ALL_DUPS     # always write commands to the history, even if
setopt HIST_IGNORE_DUPS         # it's a duplicate of an earlier command
setopt HIST_IGNORE_SPACE        # adding a space before a command keeps it out
                                # of the history
setopt NO_HIST_NO_FUNCTIONS     # would keep function definitions out of history
setopt NO_HIST_NO_STORE         # would keep `history` command out of history
setopt HIST_REDUCE_BLANKS       # replaces `echo     "test"` w/ `echo "test"`
setopt HIST_VERIFY              # replace
setopt NO_INC_APPEND_HISTORY    # these options would append to the history
setopt NO_INC_APPEND_HISTORY_TIME   # before/after every command, vs on exit
                                # this could be helpful for some systems, but
                                # will mean writing to disk frequently. :(
setopt NO_SHARE_HISTORY


#### Input/Output
setopt INTERACTIVE_COMMENTS     # allow comments in the interactive shell
setopt PRINT_EXIT_VALUE         # show exit val if a command exits w/non-zero
setopt NO_RM_STAR_SILENT        # please do warn before I `rm *`
setopt RM_STAR_WAIT             # make me wait 10s before I confirm a `rm *`


#### Prompting
setopt PROMPT_PERCENT           # Enable special % expansions
setopt PROMPT_SUBST             # Enable parameter/command/arithmetic expansion


#### Scripts and Functions
setopt C_BASES                  # output hex as 0xFF vs 16#FF

#### Shell Emulation
setopt BSD_ECHO                 # disables backslash escape chars in echo w/o -e
                                # this may annoy me at some point, but it's the
                                # default behavior in a lot of places, so...
setopt POSIX_ALIASES            # disallows reserved words like "do" and "done"
                                # for use as aliases


#### Zle
setopt BEEP                     # beep!
setopt COMBINING_CHARS          # assume the terminal can handle combining chars


#### Other
# Stuff that wasn't mentioned in the options documentation when I read it, but I
# found elsewhere anyway
REPORTTIME=5                    # show the time a command took if >5s
# don't do globbing when calling find or wget
for command in find wget; alias $command="noglob $command"

if [ -e "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

localUname="$(uname -a)"
if [[ "$localUname" = *Linux* && "$localUname" = *"Microsoft"* ]]; then
    # This should convince tmux to stop using bash as its shell.
    export SHELL=/usr/bin/zsh
fi

# ls -l -> long listing format
# ls -a -> list everything
# ls -h -> human-friendly sizes, via powers of 1024
# ls -v -> sort version numbers better?
# ls -F -> add '/' on end of dirs, '*' on executables, etc.
LSOPTS='-lahvF --time-style=long-iso --color=auto'
EXAOPTS='-lahF --time-style=long-iso --color=auto'
if [[ "$localUname" = Darwin* ]]; then
    LSOPTS='-lahvF --color=auto'
fi
exaPath="$(which exa || true)"
if [[ "$exaPath" = */exa ]]; then
    alias ls="exa $EXAOPTS"
    alias ll="exa $EXAOPTS | less -FX"
else
    alias ls="ls $LSOPTS"
    alias ll="ls $LSOPTS | less -FX"
fi

# zsh's `dirs` command outputs like `ls` does; adding `-v` puts each directory
# on its own line and gives them numbers
alias dirs="dirs -v"

# "load" colors?
autoload -U colors
colors

# if there's anything machine-specific in .local, run it
if [ -e "$HOME/.local/.zshrc" ] ; then
    source "$HOME/.local/.zshrc"
fi
if [ -e "$HOME/.local/.allshrc" ] ; then
    source "$HOME/.local/.allshrc"
fi

source "$HOME/dev/dotfiles/allshrc.sh"

source "$HOME/dev/dotfiles/zsh/posh-git-zsh.sh"

# use vi-mode
bindkey -v
# provide a visual-indicator on the right side of the screen so I know what the
# friggin text mode is
function zle-line-init zle-keymap-select {
    local RPS1="${${KEYMAP/vicmd/-- NORMAL --}/(main|viins)/-- INSERT --}"
    local RPS2=$RPS1
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

# fix the delete key on my mac
if [ "$(uname)" = "Darwin" ] ; then
    bindkey "^[[3~" delete-char
    bindkey "^[3;5~" delete-char
fi

# Enaable autocomplete for things like git commands
autoload -Uz compinit && compinit

# Make some keystrokes behave as expected
# HOME and END keys
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
# OSX's Terminal.app sends these for HOME and END
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# Ctrl+Left/Right arrows
bindkey "\e[1;5D" backward-word
bindkey "\e[1;5C" forward-word
