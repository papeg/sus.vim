-- ftplugin/sus.lua (Neovim)
-- Neovim integration using built-in LSP (no lspconfig dependency). Requires Neovim >= 0.11.4.

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

  local ok_mod, sus = pcall(require, 'sus_lsp')
  if not ok_mod then
    vim.schedule(function()
      vim.notify('sus.vim: failed to load sus_lsp module.', vim.log.levels.ERROR)
    end)
    return
  end

  local tcp = vim.g.sus_lsp_tcp or {}
  local host = tcp.host or '127.0.0.1'
  local port = tonumber(tcp.port or 25000)
  local use_stdio = (vim.g.sus_lsp_use_stdio == 1)
  local wait_ms = tonumber(vim.g.sus_lsp_wait_ms or 0)
  local connect_tries = tonumber(vim.g.sus_lsp_connect_tries or 15)
  local connect_delay = tonumber(vim.g.sus_lsp_connect_delay_ms or 200)

  -- root dir handled by sus_lsp via vim.fs; nothing to do here

  -- Avoid probing the TCP port directly to not steal single-client servers.

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

  -- Ensure TCP server is running when using TCP mode
  if not use_stdio then
    start_tcp_server()
  end
  -- Configure and connect the LSP client (TCP by default)
  sus.setup({
    host = host,
    port = port,
    name = 'sus_compiler',
    use_stdio = use_stdio,
    cmd = vim.g.sus_lsp_cmd,
  })
  local bufnr = vim.api.nvim_get_current_buf()
  local function attempt_connect(i)
    if sus.connect(bufnr, false) then return end
    if i < connect_tries then
      vim.defer_fn(function() attempt_connect(i + 1) end, connect_delay)
    else
      if wait_ms > 0 then vim.defer_fn(function() sus.connect(bufnr, true) end, wait_ms) else sus.connect(bufnr, true) end
    end
  end
  attempt_connect(1)
  vim.g._sus_lsp_setup_done = true
end
