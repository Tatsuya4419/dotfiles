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

" 検索関連
set ignorecase
set smartcase
set wrapscan
set incsearch
set hlsearch
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>
