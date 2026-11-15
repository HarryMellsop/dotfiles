" Minimal (neo)vim config. Also used as ~/.config/nvim/init.vim.
syntax on
set number
set nocompatible
set encoding=utf-8
set updatetime=100
filetype plugin indent on

" reload buffers when files change on disk (e.g. edits from an agent)
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
autocmd FileChangedShellPost * echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" vim-plug, bootstrapped on first launch
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
" ctrl-h/j/k/l across vim splits and tmux panes (pairs with .tmux.conf)
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

set background=dark
silent! colorscheme tokyonight
