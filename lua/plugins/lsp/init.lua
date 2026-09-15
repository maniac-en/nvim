-- lua/plugins/lsp/init.lua
-- Servers use Neovim's built-in vim.lsp.config/vim.lsp.enable. nvim-lspconfig
-- only provides the base server configs (its lsp/*.lua files); per-server
-- overrides live in after/lsp/<server>.lua.

local servers = {
  -- Go
  "gopls",
  -- Python
  "basedpyright",
  "ruff",
  -- Lua
  "lua_ls",
  -- Shell
  "bashls",
  -- C/C++
  "clangd",
  -- JSON
  "jsonls",
  -- Web
  "html",
  "cssls",
  "tailwindcss",
  "ts_ls",
}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      --  Easier downloads of LSP servers via mason registry
      {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        opts = {
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗"
            }
          }
        }
      },
      -- LSP progress indicator
      { "j-hui/fidget.nvim", opts = {}, },
      -- get workspace diagnostics
      "artemave/workspace-diagnostics.nvim",
    },
    config = function()
      -- Applies to every server
      vim.lsp.config("*", {
        -- completion capabilities from blink.cmp (snippets, resolve, labelDetails, ...)
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      require("plugins.lsp.config")
      require("plugins.lsp.autocmds")
      require("plugins.lsp.keymaps")

      vim.lsp.enable(servers)
    end
  },

  --  Faster LuaLS setup for Neovim (a separate spec: as a dependency it would
  --  load with nvim-lspconfig on every file, not just Lua files)
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
}
