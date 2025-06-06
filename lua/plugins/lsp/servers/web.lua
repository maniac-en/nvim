-- lua/plugins/lsp/servers/web.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.html.setup {}
  lspconfig.cssls.setup {}
  lspconfig.tailwindcss.setup {}
  lspconfig.ts_ls.setup {}
end

M.setup()
return M
