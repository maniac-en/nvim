-- lua/plugins/lsp/servers/bash.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.bashls.setup({
    filetypes = { "sh", "bash", "zsh" }
  })
end

M.setup()
return M
