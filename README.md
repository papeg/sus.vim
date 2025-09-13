Sus.nvim — Sus language support for Neovim

Features
- Filetype detection for .sus
- Syntax highlighting (types, keywords, numbers, comments, braces folding)
- LSP setup: auto-spawn via nvim-lspconfig (stdio), TCP fallback helper

Install (vim-plug)

Option A: Local path

  Plug '~/.config/nvim/sus.nvim'

Option B: Git (recommended)

  Plug 'your-user/sus.nvim'

Usage
- Open a .sus file; LSP attaches automatically if lspconfig is present.
- Default LSP command (stdio): { 'sus_compiler', '--lsp' }
- To use TCP instead, before opening a .sus buffer:
  - let g:sus_lsp_tcp = {'host': '127.0.0.1', 'port': 25000}
  - Start the server separately: sus_compiler --lsp --lsp-listen

Overrides
- Set a custom command: let g:sus_lsp_cmd = ['sus_compiler', '--lsp', '--stdio']

Notes
- Requires Neovim 0.10+ for vim.lsp.start and vim.lsp.rpc.connect.
- Works without lspconfig by connecting to an already running TCP server.

