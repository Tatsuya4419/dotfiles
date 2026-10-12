" 表示関連
set number
syntax on
set ambiwidth=double
set laststatus=2
set autoindent
set showmatch
set title
set ruler

" 行番号を薄く表示(colorscheme を変えても効くよう autocmd で当てる)
augroup dim_linenr
    autocmd!
    autocmd ColorScheme * highlight LineNr ctermfg=240 guifg=#6c6c6c
augroup END
highlight LineNr ctermfg=240 guifg=#6c6c6c

" 入力関連
set backspace=indent,eol,start
set expandtab
set shiftwidth=4
set softtabstop=4
" 端末の Alt+j/k は ESC j/k として届く。Vim は <M-j> と認識しないので、ESC + 文字を
" <M-j> として登録する。しないと visual モードでは ESC で選択が外れて j が走る
" (Alt+矢印は端末のキーコードとして認識されるので効く)。Neovim は不要
if !has('nvim') && !has('gui_running')
    execute "set <M-j>=\ej"
    execute "set <M-k>=\ek"
    set ttimeout
    set ttimeoutlen=50
endif
nnoremap <M-j> <Cmd>move .+1<CR>==
xnoremap <M-j> :move '>+1<CR>gv=gv
inoremap <M-j> <Esc>:m+<CR>==gi

nnoremap <M-k> <Cmd>move .-2<CR>==
xnoremap <M-k> :move '<-2<CR>gv=gv
inoremap <M-k> <Esc>:m-2<CR>==gi

" 検索関連
set ignorecase
set smartcase
set wrapscan
set incsearch
set hlsearch
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>
