-- lua/plugins/lsp/init.lua
-- Servers use Neovim's built-in vim.lsp.config/vim.lsp.enable. nvim-lspconfig
-- only provides the base server configs (its lsp/*.lua files); per-server
-- overrides live in after/lsp/<server>.lua.

local servers = require("plugins.lsp.tools").servers
local tools = require("plugins.lsp.tools").mason

-- Install whatever on `tools` is missing (never updates installed ones)
local function install_missing_tools()
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(tools) do
      local ok, pkg = pcall(registry.get_package, name)
      if not ok then
        vim.notify("Mason: no package named " .. name, vim.log.levels.WARN)
      elseif not pkg:is_installed() and not pkg:is_installing() then
        vim.notify("Mason: installing " .. name)
        pkg:install({}, function(success)
          vim.schedule(function()
            vim.notify(("Mason: %s %s"):format(name, success and "installed" or "failed to install"),
              success and vim.log.levels.INFO or vim.log.levels.ERROR)
          end)
        end)
      end
    end
  end)
end

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
        },
        config = function(_, opts)
          require("mason").setup(opts)
          install_missing_tools()
        end,
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
