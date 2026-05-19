" ── Neovim init.vim ──────────────────────────────────────────────────────
" Stylix injects the colorscheme before this file is loaded.
" Do not set colorscheme here.

" ── Python provider ────────────────────────────────────────────────────────
" NixOS puts Python at a stable location regardless of machine.
let g:python3_host_prog = '/run/current-system/sw/bin/python3'

" ── Basic settings ─────────────────────────────────────────────────────────
set number
set relativenumber
set cursorline
set scrolloff=8
set sidescrolloff=8

set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

set ignorecase
set smartcase
set incsearch
set hlsearch

set wrap
set linebreak

set splitright
set splitbelow

set mouse=a
set clipboard=unnamedplus   " use system clipboard

set undofile                " persistent undo across sessions
set updatetime=300

" ── File explorer (netrw) ──────────────────────────────────────────────────
" You are using Yazi for file management; netrw is just the fallback
let g:netrw_banner = 0
let g:netrw_liststyle = 3

" ── Run Python on current file ─────────────────────────────────────────────
" Maps <leader>r to run the current Python file and show output below
nnoremap <leader>r :w<CR>:split<CR>:terminal python3 %<CR>

" ── Keymaps ────────────────────────────────────────────────────────────────
let mapleader = " "

" Clear search highlight
nnoremap <leader>/ :nohlsearch<CR>

" Move between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Open Yazi from Neovim
nnoremap <leader>e :!kitty yazi<CR>
