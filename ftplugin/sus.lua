-- ftplugin/sus.lua (Neovim)
-- Neovim integration via nvim-lspconfig. Requires Neovim >= 0.11.4.

if not vim.g._sus_lsp_setup_done then
  local supported = false
  do
    local ver = vim.version and vim.version() or nil
    if ver then
      if ver.major > 0 then
        supported = true
      elseif ver.minor > 11 then
        supported = true
      elseif ver.minor == 11 then
        supported = (ver.patch or 0) >= 4
      end
    else
      supported = vim.fn.has('nvim-0.11') == 1
    end
  end
  if not supported then
    vim.schedule(function()
      vim.notify('sus.vim requires Neovim 0.11.4+ for LSP integration.', vim.log.levels.ERROR)
    end)
    return
  end

  local ok_lspconfig, lspconfig = pcall(require, 'lspconfig')
  if not ok_lspconfig then
    vim.schedule(function()
      vim.notify('sus.vim: nvim-lspconfig not found. Please install neovim/nvim-lspconfig.', vim.log.levels.ERROR)
    end)
    return
  end

  local util = require('lspconfig.util')
  local configs = require('lspconfig.configs')

  local tcp = vim.g.sus_lsp_tcp or {}
  local host = tcp.host or '127.0.0.1'
  local port = tonumber(tcp.port or 25000)
  local use_stdio = (vim.g.sus_lsp_use_stdio == 1)

  local function start_tcp_server()
    if use_stdio then return end
    if vim.g.sus_lsp_autostart == 0 then return end
    if vim.g._sus_lsp_server_started then return end

    local start_cmd = vim.g.sus_lsp_start_cmd
    local cmdlist
    if type(start_cmd) == 'table' then
      cmdlist = start_cmd
    elseif type(start_cmd) == 'string' then
      cmdlist = { 'sh', '-c', start_cmd }
    else
      cmdlist = { 'sus_compiler', '--lsp', '--socket', tostring(port), '--lsp-listen' }
    end

    local job_id = vim.fn.jobstart(cmdlist)
    if job_id <= 0 then
      vim.schedule(function()
        vim.notify('sus.vim: failed to start TCP server (sus_compiler). Check your PATH or g:sus_lsp_start_cmd.', vim.log.levels.ERROR)
      end)
    else
      vim.g._sus_lsp_server_started = true
    end
  end

  -- Public command to manually start the server if needed
  pcall(vim.api.nvim_create_user_command, 'SusLspStartServer', function()
    start_tcp_server()
  end, {})

  if not configs.sus_compiler then
    configs.sus_compiler = {
      default_config = {
        name = 'sus_compiler',
        cmd = (use_stdio and (vim.g.sus_lsp_cmd or { 'sus_compiler', '--lsp' }))
          or vim.lsp.rpc.connect(host, port),
        filetypes = { 'sus' },
        root_dir = util.root_pattern('sus.toml', '.git') or vim.fn.getcwd(),
      },
      docs = {
        description = 'sus_compiler language server',
      },
    }
  end

  -- Ensure TCP server is running when using TCP mode
  if not use_stdio then
    start_tcp_server()
  end

  lspconfig.sus_compiler.setup({})
  vim.g._sus_lsp_setup_done = true
end
