-- lua/plugins/lsp/servers/python.lua

local M = {}

function M.setup()
  local lspconfig = require("lspconfig")
  lspconfig.pyright.setup({
    capabilities = {
      general = {
        -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
        positionEncodings = { "utf-16" }
      },
    },
    handlers = {
    },
    settings = {
      pyright = {
        disableOrganizeImports = false,
      },
      python = {
        analysis = {
          ignore = { "*" },
          logLevel = "Information",
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticMode = "off",
          typeCheckingMode = "on",
          useLibraryCodeForTypes = true,
        },
      },
    },
  })
  lspconfig.ruff.setup({
    on_attach = function(client, _)
      if client.name == "ruff" then
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end
    end,
    init_options = {
      settings = {
        args = {
          "--select=F6,F7,F8",
        },
      },
    },
    capabilities = {
      general = {
        -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
        positionEncodings = { "utf-16" }
      },
    }
  })
end

M.setup()
return M
