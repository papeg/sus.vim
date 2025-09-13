" ftdetect/sus.vim
augroup sus_ftdetect
  autocmd!
  autocmd BufRead,BufNewFile *.sus set filetype=sus
augroup END

