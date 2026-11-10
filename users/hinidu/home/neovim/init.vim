" Plugins come from users/hinidu/home/neovim.nix

" Use space as leader key.
" NOTE: This should be set before any mapping with <leader>.
" In other case those mappings will use default <leader>.
let mapleader = ' '


" Plugins {{{

" Solarized {{{
set background=light
colorscheme NeoSolarized
" }}}

" fugitive {{{
nnoremap <leader>gs :<C-u>Git<CR>
nnoremap <leader>gd :<C-u>Gdiff<CR>
nnoremap <leader>gcm :<C-u>Git commit --verbose<CR>
nnoremap <leader>gca :<C-u>Git commit --verbose --amend<CR>
nnoremap <leader>gpl :<C-u>Git pull --ff-only --recurse-submodules<CR>
nnoremap <leader>gps :<C-u>Git push --set-upstream<CR>
nnoremap <leader>gpf :<C-u>Git push --set-upstream --force<CR>
" }}}

" move {{{
let g:move_key_modifier = 'C'
" }}}

" airline {{{
let g:airline_theme = 'solarized'
let g:airline_solarized_bg = 'light'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>- <Plug>AirlineSelectPrevTab
nmap <leader>+ <Plug>AirlineSelectNextTab

let g:airline#extensions#keymap#enabled = 0
" }}}

" Plugins }}}


" Settings {{{

" Tab width is 2 columns
set tabstop=2
" Backspace remove up to 2 spaces in beginning of line in insert mode
set softtabstop=2
" < and > commands remove/add 2 spaces to the end of line
set shiftwidth=2
" Replace tab with tabstop spaces when press <tab> in insert mode
set expandtab

" Default formatoptions
" set formatoptions=tcroq
" Automatic formatting of paragraphs
set formatoptions+=a
" When formatting test, recognize numbered lists
set formatoptions+=n
" Remove a comment leader when joining lines
set formatoptions+=j
" Don't break a line after a one-letter word
set formatoptions+=1
" A line that ends in a non-white character ends a paragraph
set formatoptions+=w

" Round indent to multiple of 'shiftwidth'
set shiftround

" Ignore case in search when pattern has no uppercase letters
set ignorecase
set smartcase

" Show line numbers relative to current line
set relativenumber
" Show number of current line instead of 0
set number
" Highlight line under the cursor
set cursorline

" Allow to switch to russian keymap with Ctrl-^ in insert mode
" This change would affect insert mode and search
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0

" Do not make all windows equal sizes after splitting or closing window
set noequalalways

" Use system clipboard for all yank, delete, change and put operations
set clipboard=unnamedplus

" Use special characters to mark tabs and trailing spaces
set list

" Allow to use mouse in all modes
set mouse=a

" Highlight 81's column
set colorcolumn=81

" Search by :find, gf, etc. in current directory recursively
set path+=**

set diffopt+=vertical

let g:sql_type_default = 'pgsql'

" Settings }}}


" Mappings {{{

" Always use very magic patterns
nnoremap / /\v

" Stop highlighting items from the last search with <leader>hl
nnoremap <leader>hl :nohlsearch<cr>

" Open this config (the live init.lua is generated and read-only) in a split
" window
nnoremap <leader>ev :vsplit /etc/nixos/users/hinidu/home/neovim/init.vim<cr>
" Source the live config
nnoremap <leader>sv :source $MYVIMRC<cr>

" Fast movements between quickfix list entries
nnoremap <leader>n :cnext<cr>
nnoremap <leader>p :cprevious<cr>

" Uppercase current word with Ctrl-U in insert mode
inoremap <c-u> <esc>:call PreserveState("normal viwUi")<cr>

" Remove trailing spaces in file
nnoremap <leader>$ :call PreserveState("%s/\\s\\+$//e")<cr>
" Reindent all lines in file
nnoremap <leader>= :call PreserveState("normal gg=G")<cr>

" Toggle spell checking
nnoremap <leader>sp :set spell!<cr>

" Mappings }}}


" Functions {{{

" Function that preserve current state and run some command
function! PreserveState(command)
  " Preparation: save last search and cursor position.
  let saved_search = @/
  let saved_line = line(".")
  let saved_column = col(".")
  " Do the business:
  execute a:command
  " Clean up: restore previous search history and cursor position
  let @/ = saved_search
  call cursor(saved_line, saved_column)
endfunction

" Functions }}}


" FileType-specific settings {{{

augroup filetype_cs
  autocmd!
  autocmd Filetype cs setlocal tabstop=4 softtabstop=4 shiftwidth=4
augroup end

augroup filetype_terraform
  autocmd!
  autocmd Filetype terraform setlocal fo=
augroup end

augroup filetype_haskell
  autocmd!
  " Backspace remove only one space in beginning of line in haskell sources
  autocmd Filetype haskell setlocal softtabstop=0
augroup end

augroup filetype_go
  autocmd!
  autocmd Filetype go setlocal noexpandtab nolist
augroup end

augroup filetype_vim
  autocmd!
  " Fold all markers the first time open the file
  autocmd Filetype vim setlocal foldmethod=marker foldlevelstart=0
augroup end

augroup filetype_tex
  autocmd!
  autocmd BufRead,BufNewFile *.tex set filetype=tex
  autocmd FileType tex setlocal spell spelllang=ru,en textwidth=80
augroup end

" FileType-specific settings }}}
