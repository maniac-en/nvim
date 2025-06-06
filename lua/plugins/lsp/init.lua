-- lua/plugings/lsp/init.lua
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      --  Easier downloads of LSP servers via mason registry
      {
        "mason-org/mason.nvim",
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
      --  Faster LuaLS setup for Neovim
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
      -- LSP progress indicator
      { "j-hui/fidget.nvim", opts = {}, },
    },
    config = function()
      require("plugins.lsp.config")
      require("plugins.lsp.servers")
      require("plugins.lsp.autocmds")
    end
  }
}
