" ftplugin/sus.vim (Vim 8)
" Vim integration via prabirshrestha/vim-lsp. Requires Vim >= 8.2.2121.

if has('nvim')
  finish
endif

if !has('patch-8.2.2121')
  echohl WarningMsg
  echom 'sus.vim requires Vim 8.2.2121+ for LSP integration.'
  echohl None
  finish
endif

if exists('g:_sus_lsp_vim_registered') && g:_sus_lsp_vim_registered
  finish
endif

let s:allow = ['sus']
let s:tcp = get(g:, 'sus_lsp_tcp', {})
let s:host = get(s:tcp, 'host', 'localhost')
let s:port = get(s:tcp, 'port', 25000)
let s:autostart = get(g:, 'sus_lsp_autostart', 1)

function! s:sus_start_server_if_needed() abort
  if !s:autostart | return | endif
  if exists('g:_sus_lsp_vim_started') && g:_sus_lsp_vim_started | return | endif
  let l:start_cmd = get(g:, 'sus_lsp_start_cmd', '')
  if type(l:start_cmd) == type([])
    " If a list is provided, run with job_start for better handling
    try
      call job_start(l:start_cmd)
      let g:_sus_lsp_vim_started = 1
      return
    catch
    endtry
  endif
  if empty(l:start_cmd)
    let l:start_cmd = 'sus_compiler --lsp --socket ' . s:port . ' --lsp-listen'
  endif
  " Use system to background and silence output
  call system(l:start_cmd . ' >/dev/null 2>&1 &')
  let g:_sus_lsp_vim_started = 1
endfunction

function! s:sus_register_lsp() abort
  if exists('g:_sus_lsp_vim_registered') && g:_sus_lsp_vim_registered
    return
  endif
  if exists('*lsp#register_server')
    call s:sus_start_server_if_needed()
    try
      call lsp#register_server({
            \ 'name': 'sus_compiler',
            \ 'tcp': {server_info->(s:host . ':' . s:port)},
            \ 'allowlist': s:allow,
            \ 'whitelist': s:allow,
            \ })
      let g:_sus_lsp_vim_registered = 1
    catch
      echohl WarningMsg
      echom 'sus.vim: failed to register vim-lsp server.'
      echohl None
    endtry
  else
    " Defer message to not spam on every buffer; user can verify after vim-lsp loads.
    if !exists('g:_sus_lsp_vim_warned')
      let g:_sus_lsp_vim_warned = 1
      echohl WarningMsg
      echom 'sus.vim: vim-lsp not loaded yet; will register on User lsp_setup.'
      echohl None
    endif
  endif
endfunction

augroup sus_vim_lsp
  autocmd!
  autocmd User lsp_setup call s:sus_start_server_if_needed()
  autocmd User lsp_setup call s:sus_register_lsp()
augroup END

" Try immediate registration if vim-lsp is already available
call s:sus_start_server_if_needed()
call s:sus_register_lsp()
