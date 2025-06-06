-- lua/plugins/lsp/servers/clangd.lua
local M = {}

function M.setup()
  -- For C/C++
  local lspconfig = require("lspconfig")
  lspconfig.clangd.setup {}
end

M.setup()
return M
