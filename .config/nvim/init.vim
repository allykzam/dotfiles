" UI
set showtabline=2                       " always show tab bar at top
set laststatus=2                        " always show status line at bottom
set scrolloff=2                         " keep 2 lines of context around cursor
set number                              " show line numbers
set ruler                               " always show cursor position
set spell                               " enable spell-check
                                        " use the `zg` command to add the word
                                        " under the cursor to the dictionary
set background=light                    " I don't like vim's dark colors :[
color desert                            " I've given up and moved to the desert color theme
" add highlighting for trailing whitespace
highlight ExtraWhitespace ctermbg=red
match ExtraWhitespace /\s\+$/
set lazyredraw                          " don't redraw the screen while running
                                        " macros, etc.
set showmatch                           " show matching brackets while typing
set matchtime=2                         " x0.1s to highlight matching parens
                                        " with showmatch enabled
set showcmd                             " display incomplete commands
set equalalways                         " make multiple windows the same size on
                                        " splitting or cloning windows
set listchars=tab:↹·,extends:⇉,precedes:⇇,trail:␠,nbsp:␣,trail:░
                                        " show invisible characters
set showbreak=↳\                        " show this at start of wrapped lines
set foldmethod=indent                   " auto-fold based on indentation
set foldlevel=99


" safety files (backup, undo, swap)
set backspace=indent,eol,start          " allow backspace/DEL over indentation,
                                        " line endings, and line beginnings
set backup                              " enable backups
set backupdir=~/.config/nvim/backup     " hide backup files here
set backupext=.bak                      " add this extension
set undofile                            " enable persistent-undo
set undodir=~/.config/nvim/undo         " dump undo files in a dir I don't see
set directory=~/.config/nvim/swap       " hide swap files here


" file encoding info
set encoding=utf-8                      " use UTF-8 by default
setglobal fileencoding=utf-8            " ditto above
set fileencodings=ucs-bom,utf-8,iso-8859-1,latin1
                                        " try the above encodings in-order when
                                        " trying to load a file
set nobomb                              " no byte-order-marker in my UTF-8 plz
set fileformats=unix,dos                " perfer \n in new files
set display=uhex                        " display unknown characters as hex


" whitespace
set expandtab                           " never use hard tabs
set autoindent                          " enable automatic indentation
set tabstop=4
set shiftwidth=4                        " one tab = four spaces (autoindent)
set softtabstop=4                       " one tab = four spaces (tab key)
set shiftround                          " only indent to multiples of 4
set smarttab
set colorcolumn=81                      " add a vertical bar at char 81; useful
                                        " for keeping myself from going past 80
highlight ColorColumn ctermbg=darkgray ctermfg=green

" mouse
set mousefocus                          " shift focus to window under the mouse
set mousehide                           " hide mouse cursor when typing
set mouse=a                             " allow mouse support when possible


" misc
set nrformats=alpha,octal,hex           " allow ^A/^X to {in,de}crement letters,
                                        " octal values, and hex
set allowrevins                         " allow ^_ in insert mode to toggle
                                        " reverse insert mode; fun to play
                                        " with :)
set autoread                            " re-load files that have been changed
                                        " externally w/o any changes in vim
set confirm                             " gives a dialog when something would
                                        " have complained about unsaved changes;
                                        " also allows cancelling :D
set errorbells                          " beep with error messages
set redrawtime=500                      " ms to wait for redraws; after this
                                        " long, stops trying to find matches
set scroll=10                           " scroll this many lines with ^U or ^D
set history=1000                        " remember command history


" regexes
set incsearch                           " do incremental searching
set ignorecase                          " search is case insensitive
set smartcase                           " case-sens when capital letters


" tab completion -- this section stolen from @eevee's vimrc as well
set wildmenu                            " show a menu of completion options
set wildmode=full                       " complete longest common prefix first
set complete-=i                         " don't try to tab-complete #included
                                        " files
set completeopt-=preview                " preview window is super annoying


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" file-type fixes

" Fix lasso files to use PHP syntax highlighting
autocmd BufNewFile,BufRead *.lasso setfiletype php
autocmd BufNewFile,BufRead *.las setfiletype php

" Fix crontab issue
autocmd BufEnter /private/tmp/crontab.* setl backupcopy=yes

" tell vim that .md files are markdown
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" tell vim that .muttrc files are...muttrc files?
autocmd BufNewFile,BufReadPost *.muttrc set filetype=muttrc

" Use the "desert" color scheme for assembly
autocmd BufNewFile,BufReadPost *.asm color desert

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" plugins

" enable pathogen and load all its stuff
execute pathogen#infect()

" syntastic settings suggested by their README for new users (me)
" these first three lines make vim complain?
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" gundo for graph undo graphs the tree of undo history
" turn on/off gundo with @eevee's shortcut for it
nnoremap ,u :GundoToggle<CR>
let g:gundo_preview_height = 40         " give gundo some room for previewing
let g:gundo_preview_bottom = 1

" let airline know to use the powerline glyphs
let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" color and syntax

" add syntax and search highlighting when color support is available
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

filetype plugin indent on           " enable file type detection

" when editing a file, always jump to last known cursor position; don't do
" this when the position is invalid, when inside an event handler, or when
" the mark is on the first line.
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" when editing a git commit, move to the top
" done here because the above command will override this
autocmd BufReadPost COMMIT_* call setpos('.', [0, 1, 1, 0])

" set all `text` files to have a width of 80 characters
autocmd FileType text setlocal textwidth=80
autocmd FileType markdown setlocal textwidth=80

autocmd BufRead,BufNewFile *.asm set filetype=nasm

" XAML files should be processed as XML
autocmd BufNewFile,BufRead *.xaml set filetype=xml
