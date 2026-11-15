syntax on
set number
set nocompatible
set encoding=utf-8
filetype plugin indent on

" trigger `autoread` when files changes on disk
set autoread
au CursorHold * checktime
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" notification after file change
autocmd FileChangedShellPost * echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" ignore venv, git etc. from ctrlp
let g:ctrlp_custom_ignore = '\v[\/](venv|node_modules|\.git|\.hg|\.svn)$'

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
	silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
" --> plugins <--

"{{ Configuring NerdTree
Plug 'scrooloose/nerdtree'
" ---> to hide unwanted files <---
let NERDTreeIgnore = [ '__pycache__', '\.pyc$', '\.o$', '\.swp',  '*\.swp',  'node_modules/' ]
" ---> show hidden files <---
let NERDTreeShowHidden=1
" ---> autostart nerd-tree when you start vim <---
autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:stdn_in") | NERDTree | endif
"  " ---> toggling nerd-tree using Ctrl-N <---
map <C-n> :NERDTreeToggle<CR>
"}}

"{{ Configuring YouCompleteMe
Plug 'valloric/youcompleteme', { 'do': './install.py' }
" ---> youcompleteme configuration <---
let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
" ---> compatibility with another plugin (ultisnips) <---
let g:ycm_key_list_select_completion = [ '<C-n>', '<Down>' ] 
let g:ycm_key_list_previous_completion = [ '<C-p>', '<Up>' ]
let g:SuperTabDefaultCompletionType = '<C-n>'
" ---> disable preview window <---
set completeopt-=preview
" ---> navigating to the definition of a a symbol <---
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>
"}}

"{{ Configuring CtrlP
Plug 'ctrlpvim/ctrlp.vim'
"}}

"{{ Git integration
" ---> git commands within vim <---
Plug 'tpope/vim-fugitive'
" ---> git changes on the gutter <---
Plug 'airblade/vim-gitgutter'
" ---> nerdtree git changes <---
Plug 'Xuyuanp/nerdtree-git-plugin'
"}}

"{{ Color-scheme
Plug 'morhetz/gruvbox'
set background=dark
let g:gruvbox_contrast_dark='default'
"}}

Plug 'folke/tokyonight.nvim', { 'branch': 'main' }

"{{ Autopairs
" ---> closing XML tags <---
Plug 'alvan/vim-closetag'
" ---> files on which to activate tags auto-closing <---
let g:closetag_filenames ='*.html,*.xhtml,*.xml,*.vue,*.phtml,*.js,*.jsx,*.coffee,*.erb'
" ---> closing braces and brackets <---
Plug 'jiangmiao/auto-pairs'
"}}

Plug 'f-person/git-blame.nvim'

"{{ TMux - Vim integration
Plug 'christoomey/vim-tmux-navigator'
"}}"

call plug#end()

colorscheme tokyonight

set updatetime=100
