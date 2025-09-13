-- ftplugin/sus.lua (plugin)
-- Prefer nvim-lspconfig auto-spawn via stdio, with a TCP fallback if lspconfig
-- is not available. This avoids manual server startup.

if not vim.g._sus_lsp_setup_done then
  local has_lspconfig, lspconfig = pcall(require, 'lspconfig')
  if has_lspconfig then
    local util = require('lspconfig.util')

    local cmd = vim.g.sus_lsp_cmd
    local tcp = vim.g.sus_lsp_tcp

    if type(cmd) ~= 'table' and type(tcp) ~= 'table' then
      cmd = { 'sus_compiler', '--lsp' }
    end

    if not lspconfig.configs.sus_compiler then
      lspconfig.configs.sus_compiler = {
        default_config = {
          name = 'sus_compiler',
          cmd = (type(tcp) == 'table' and vim.lsp.rpc.connect(tcp.host or '127.0.0.1', tcp.port or 25000))
            or cmd,
          filetypes = { 'sus' },
          root_dir = util.root_pattern('sus.toml', '.git') or vim.fn.getcwd(),
        },
        docs = {
          description = 'sus_compiler language server',
        },
      }
    end

    lspconfig.sus_compiler.setup({})
    vim.g._sus_lsp_setup_done = true
  else
    local ok_tcp, sus = pcall(require, 'sus_lsp')
    if ok_tcp then
      sus.setup({ host = '127.0.0.1', port = 25000, name = 'sus_compiler' })
      sus.connect(0, false)
    else
      vim.notify('Neither lspconfig nor sus_lsp available for sus LSP.', vim.log.levels.ERROR)
    end
  end
end

