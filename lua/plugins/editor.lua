-- lua/plugins/editor.lua
local key = require("config.map").lazy

return {
  -- Detect indentation automatically: from the file itself, or from sibling
  -- files of the same type for new/unindented files. Modelines and .editorconfig
  -- take precedence; defaults live in lua/config/options.lua
  {
    "tpope/vim-sleuth",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      vim.g.sleuth_neighbor_limit = 5 -- Limit number of neighboring files checked
    end,
  },

  -- Undo history visualizer
  {
    "mbbill/undotree",
    keys = {
      key("<leader>u", function()
        vim.cmd.UndotreeToggle()
        vim.cmd.UndotreeFocus() -- Automatically focus the undotree panel
      end, "Undo", "[U]ndotree toggle"),
    },
    init = function()
      -- Configure undotree appearance
      vim.g.undotree_WindowLayout = 2    -- Layout style (2 = right side)
      vim.g.undotree_SplitWidth = 30     -- Width of the undotree panel
      vim.g.undotree_DiffAutoOpen = 1    -- Auto open diff window
      vim.g.undotree_DiffpanelHeight = 10 -- Height of diff panel
      vim.g.undotree_SetFocusWhenToggle = 1 -- Focus undotree when opening
      vim.g.undotree_ShortIndicators = 1 -- Use short indicators
      vim.g.undotree_HelpLine = 0        -- Hide help line for more space
      -- undofile/undodir/undolevels are set in lua/config/options.lua
    end,
  },

  -- Hide/mask sensitive information
  {
    "laytan/cloak.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("cloak").setup({
        enabled = true,
        cloak_character = "*",
        highlight_group = "Comment",
        -- cloak_pattern: Lua pattern per line; `replace` keeps the captured part visible
        patterns = {
          -- .env, .env.local, .envrc, ...: every value
          { file_pattern = ".env*", cloak_pattern = "=.+" },
          -- shell scripts: only values of exported variables (export API_KEY=*****)
          { file_pattern = "*.sh", cloak_pattern = { { "^(%s*export%s+[%w_]+=).+", replace = "%1" } } },
        },
      })
    end,
  },

}
