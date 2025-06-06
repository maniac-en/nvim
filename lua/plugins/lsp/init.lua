-- lua/plugings/lsp/init.lua
return {
  {
    "neovim/nvim-lspconfig",
    event = { 'BufReadPre', 'BufNewFile' },
    pin = true,
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
      -- nvim-cmp source for neovim's builtin LSP client
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig_defaults = require("lspconfig").util.default_config
      lspconfig_defaults.capabilities = vim.tbl_deep_extend(
        'force',
        lspconfig_defaults.capabilities,
        require("cmp_nvim_lsp").default_capabilities()
      )

      require("plugins.lsp.config")
      require("plugins.lsp.servers")
      require("plugins.lsp.autocmds")
    end
  }
}
