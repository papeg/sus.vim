-- lua/sus_lsp.lua (plugin copy)
local M = {}

local defaults = {
  host = "127.0.0.1",
  port = 25000,
  name = "sus_compiler",
  debounce_text_changes = 150,
  use_stdio = false,
  cmd = nil, -- e.g., { 'sus_compiler', '--lsp' }
}

local state = {
  configured = false,
  opts = nil,
}

local function opts_or_defaults(opts)
  local o = {}
  for k, v in pairs(defaults) do o[k] = v end
  if type(opts) == "table" then
    for k, v in pairs(opts) do o[k] = v end
  end
  return o
end

local function client_running_for_buf(bufnr, name)
  for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.name == name then
      return true
    end
  end
  return false
end

local function try_rpc_connect(host, port)
  if not (vim.lsp and vim.lsp.rpc and type(vim.lsp.rpc.connect) == "function") then
    return nil, "vim.lsp.rpc.connect not available"
  end
  local ok, cmd_factory = pcall(vim.lsp.rpc.connect, host, port)
  if not ok or not cmd_factory then
    return nil, "rpc.connect failed"
  end
  return cmd_factory, nil
end

local function try_start_with_transport(name, cmd_factory, debounce, bufnr)
  if type(vim.lsp.start) ~= "function" then
    return nil, "vim.lsp.start not available (requires Neovim 0.10+)"
  end
  local root_dir = (function()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local start = (bufname ~= "" and (vim.fs and vim.fs.dirname and vim.fs.dirname(bufname))) or (vim.loop and vim.loop.cwd()) or vim.fn.getcwd()
    local found
    if vim.fs and vim.fs.find then
      found = vim.fs.find({ 'sus.toml', '.git' }, { path = start, upward = true })
    end
    if found and #found > 0 then
      if vim.fs and vim.fs.dirname then
        return vim.fs.dirname(found[1])
      else
        return start
      end
    end
    return (vim.loop and vim.loop.cwd()) or vim.fn.getcwd()
  end)()

  local ok, id = pcall(vim.lsp.start, {
    name = name,
    cmd = cmd_factory,
    root_dir = root_dir,
    flags = { debounce_text_changes = debounce },
  }, { bufnr = bufnr })
  if ok and id then return id, nil end
  return nil, "vim.lsp.start with cmd=rpc.connect failed"
end

function M.setup(opts)
  if state.configured then return end
  state.opts = opts_or_defaults(opts)
  state.configured = true

  vim.api.nvim_create_user_command("SusLspConnect", function()
    local bufnr = vim.api.nvim_get_current_buf()
    M.connect(bufnr, true)
  end, {})

  vim.api.nvim_create_user_command("SusLspCheckPort", function()
    local tcp = vim.loop.new_tcp()
    tcp:connect(state.opts.host, state.opts.port, function(err)
      if err then
        vim.notify("TCP connect failed: "..tostring(err), vim.log.levels.ERROR)
      else
        vim.notify("TCP port is open on "..state.opts.host..":"..state.opts.port, vim.log.levels.INFO)
        tcp:shutdown(); tcp:close()
      end
    end)
  end, {})
end

function M.connect(bufnr, verbose)
  if not state.configured then M.setup() end
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local o = state.opts

  if client_running_for_buf(bufnr, o.name) then
    if verbose then vim.notify(o.name.." already attached.", vim.log.levels.INFO) end
    return true
  end

  local reasons = {}
  do
    if o.use_stdio and type(o.cmd) == "table" then
      if type(vim.lsp.start) ~= "function" then
        table.insert(reasons, "vim.lsp.start not available for stdio")
      else
        local ok, id = pcall(vim.lsp.start, {
          name = o.name,
          cmd = o.cmd,
          flags = { debounce_text_changes = o.debounce_text_changes },
        }, { bufnr = bufnr })
        if ok and id then
          if verbose then vim.notify(o.name.." started via stdio.", vim.log.levels.INFO) end
          return true
        else
          table.insert(reasons, "vim.lsp.start with stdio cmd failed")
        end
      end
    else
      local cmd_factory, err = try_rpc_connect(o.host, o.port)
      if cmd_factory then
        local id, err2 = try_start_with_transport(o.name, cmd_factory, o.debounce_text_changes, bufnr)
        if id then
          if verbose then vim.notify(o.name.." connected via tcp.", vim.log.levels.INFO) end
          return true
        else
          table.insert(reasons, tostring(err2))
        end
      else
        table.insert(reasons, err)
      end
    end
  end

  vim.notify("Failed to start "..o.name.." LSP client. Reasons: "..table.concat(reasons, " | ")..". Is the server listening on "..o.host..":"..o.port.."?", vim.log.levels.ERROR)
  return false
end

return M
