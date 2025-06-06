-- lua/plugins/lsp/servers/lua.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.lua_ls.setup {}
end

M.setup()
return M
