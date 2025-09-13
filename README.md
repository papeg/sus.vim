sus.vim — [sus](https://github.com/pc2/sus-compiler) language support for vim and neovim

Features
- Filetype detection for .sus
- Syntax highlighting
- LSP setup

Currently tested only with neovim 0.11.4 and vim 8.2.2121. Please give feedback for other versions.

Use for favorite plugin tool for installing, like vim-plug. When using vim the plugin is dependent on vim-lsp, which needs to be loaded first. For neovim there are no dependecies, because the built-in lsp is used.

```
call plug#begin()
  if !has('nvim')
      Plug 'prabirshrestha/vim-lsp'
  endif
  Plug 'papeg/sus.vim'
call plug#end()
```

sus currently supports lsp only in TCP mode. The plugin starts the server by it self on localhost using default port 25000.
