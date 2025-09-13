Sus.vim — Sus language support for Vim8 and Neovim

Features
- Filetype detection for .sus
- Syntax highlighting (types, keywords, numbers, comments, braces folding)
- LSP setup (TCP by default):
  - Neovim: integrates via built-in LSP, connects over TCP
  - Vim 8: integrates via `vim-lsp`, connects over TCP
  - The plugin auto-starts the TCP server on demand

Requirements
- Neovim 0.11.4+, or
- Vim 8.2.2121+ and `prabirshrestha/vim-lsp`

Install (vim-plug)

Option A: Local path

  Plug '~/.config/nvim/sus.vim'

Option B: Git (recommended)

  Plug 'your-user/sus.vim'

Neovim

  Plug 'your-user/sus.vim'

Vim 8 (with vim-lsp)

  Plug 'prabirshrestha/vim-lsp'
  Plug 'your-user/sus.vim'

Usage
- Open a `.sus` file; LSP attaches automatically via the respective integration.
- TCP mode is default. The plugin will start the server automatically:
  - Command: `sus_compiler --lsp --socket <port> --lsp-listen`
  - Default host/port: `127.0.0.1:25000`

Overrides
- TCP host/port:
  - `let g:sus_lsp_tcp = {'host': '127.0.0.1', 'port': 25000}`
- Disable autostart (you run the server yourself):
  - `let g:sus_lsp_autostart = 0`
- Custom autostart command (string or list):
  - `let g:sus_lsp_start_cmd = 'sus_compiler --lsp --socket 25000 --lsp-listen'`
  - or `let g:sus_lsp_start_cmd = ['sus_compiler', '--lsp', '--socket', '25000', '--lsp-listen']`
- Wait time for TCP readiness (Neovim):
  - `let g:sus_lsp_wait_ms = 2000`  " time in ms to wait before first connect
- Neovim connect retry tuning:
  - `let g:sus_lsp_connect_tries = 15`
  - `let g:sus_lsp_connect_delay_ms = 200`
- Experimental stdio mode (kept for future server support):
  - `let g:sus_lsp_use_stdio = 1`
  - `let g:sus_lsp_cmd = ['sus_compiler', '--lsp']`

Notes
- Neovim path uses the built-in LSP and requires Neovim 0.11.4+.
- Vim path uses `vim-lsp` and requires Vim 8.2.2121+.
- Current server implementation is TCP-only; stdio remains available here for future use.
