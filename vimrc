set shell=/usr/bin/bash

set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'chriskempson/tomorrow-theme', {'rtp': 'vim/'}
Plugin 'Yggdroot/indentLine'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'will133/vim-dirdiff'
call vundle#end()
filetype plugin indent on

set expandtab shiftwidth=2 softtabstop=2 tabstop=2
set laststatus=2 noshowmode
set foldmethod=syntax foldlevelstart=99
set number relativenumber
set cursorline cursorlineopt=number
set nohlsearch incsearch
set timeoutlen=100 ttimeoutlen=100
set completeopt=""
set wildmenu
set background=dark
set updatetime=100
set vb t_vb=
set list listchars=tab:¦\ 
autocmd FileType qf setlocal nowrap
syntax on

function! SetTab(et, len)
  let &l:expandtab   = a:et
  let &l:shiftwidth  = a:len
  let &l:softtabstop = a:len
  let &l:tabstop     = a:len
endfunction
autocmd FileType python call SetTab(1, 2)
autocmd FileType kotlin call SetTab(1, 4)
autocmd FileType go     call SetTab(0, 2)

colorscheme Tomorrow-Night-Bright
hi ExtraWhitespace ctermbg=darkgray
hi Normal ctermbg=NONE
hi LineNr ctermfg=gray
hi CursorLine ctermbg=NONE
hi CursorLineNr cterm=NONE ctermfg=black ctermbg=darkgray
hi OverLength ctermbg=darkgray

autocmd FileType python    match OverLength /\%81v.\+/
autocmd FileType cpp       match OverLength /\%101v.\+/
autocmd FileType rust      match OverLength /\%101v.\+/

function! Sudowrite()
  exe 'w ! sudo tee' shellescape('%') '> /dev/null'
  edit!
endfunction
command W call Sudowrite()

function! MakeLocList(comm, ...)
  let errorformat = &g:errorformat
  let &g:errorformat = get(a:, 1, &g:errorformat)
  exe 'lexpr system(a:comm) " a:comm =' a:comm
  let &g:errorformat = errorformat
endfunction

" Grep/Ag searches pat in all files recursively under CWD.
" grep/ag style parameters are passed to exe_name.
" Optional parameters can be passed as the third argument:
"   i => ignore case; by default case sensitive
"   w => do not search for a whole word; by default search for a whole word
"   h => search only files with suffix '.h'; by default all files
function! Grep(exe_name, pat, ...)
  let args = get(a:, 1, '')
  let comm = a:exe_name.' -nr'
  let pat = a:pat

  if stridx(args, 'w') == -1
    let pat = '\b'.pat.'\b'
  endif
  if stridx(args, 'i') != -1
    let comm = comm.' -i'
  endif
  if stridx(args, 'h') != -1
    let comm = comm.' --include='.shellescape('*.h')
  endif
  call MakeLocList(comm.' -- '.shellescape(pat), '%f:%l:%m')
endfunction
function! Ag(exe_name, pat, ...)
  let args = get(a:, 1, '')
  let comm = a:exe_name.' --vimgrep'
  let pat = a:pat

  if stridx(args, 'w') == -1
    let comm = comm.' -w'
  endif
  if stridx(args, 'i') != -1
    let comm = comm.' -i'
  else
    let comm = comm.' -s'
  endif
  if stridx(args, 'h') != -1
    let comm = comm.' -G '.shellescape('\.h$')
  endif
  call MakeLocList(comm.' -- '.shellescape(pat), '%f:%l:%c:%m')
endfunction

" Find/Fd searches files path matching pat recursively under CWD.
" find/fd style parameters are passed to exe_name.
" Optional parameters can be passed as the third argument:
"   d => search directory only; by default file only
function! Find(exe_name, pat, ...)
  let args = get(a:, 1, '')
  let comm = a:exe_name
  let pat = a:pat

  if stridx(args, 'd') == -1
    let comm = comm.' -type f'
  else
    let comm = comm.' -type d'
  endif
  call MakeLocList(comm.' -ipath '.shellescape('*'.pat.'*'), '%f')
endfunction
function! Fd(exe_name, pat, ...)
  let args = get(a:, 1, '')
  let comm = a:exe_name.' -p'
  let pat = a:pat

  if stridx(args, 'd') == -1
    let comm = comm.' -tf'
  else
    let comm = comm.' -td'
  endif
  call MakeLocList(comm.' -- '.shellescape(pat), '%f')
endfunction

" Prefer using ag than grep.
if exepath('ag') != ""
  command -nargs=+ Grep call Ag('ag', <f-args>) | lopen
elseif exepath('grep') != ""
  command -nargs=+ Grep call Grep('grep', <f-args>) | lopen
else
  command -nargs=* Grep echo 'No valid executable for Grep'
endif

" Prefer using fd/fdfind than find.
if exepath('fd') != ""
  command -nargs=+ Find call Fd('fd', <f-args>)
elseif exepath('fdfind') != ""
  command -nargs=+ Find call Fd('fdfind', <f-args>)
elseif exepath('find') != ""
  command -nargs=+ Find call Find('find', <f-args>)
else
  command -nargs=* Find echo 'No valid executable for Find'
endif

nnoremap Y y$
