-- lua/plugins/lsp/servers/json.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.jsonls.setup {}
end

M.setup()
return M
