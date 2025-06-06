-- lua/plugings/lsp/servers/init.lua

local M = {}

function M.setup()
  require("plugins.lsp.servers.lua")
  require("plugins.lsp.servers.bash")
  require("plugins.lsp.servers.python")
  require("plugins.lsp.servers.golang")
  require("plugins.lsp.servers.clangd")
  require("plugins.lsp.servers.web")
  require("plugins.lsp.servers.json")
end

M.setup()
return M
