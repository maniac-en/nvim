-- lua/plugins/editor.lua
return {
  -- Detect indentation automatically
  {
    "tpope/vim-sleuth",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Set default values (sleuth will override these when it detects different settings)
      vim.o.tabstop = 4
      vim.o.softtabstop = 4
      vim.o.shiftwidth = 4
      vim.o.expandtab = true

      -- Optional: Add configuration to ignore certain filetypes
      vim.g.sleuth_no_filetype_indentation = {
        "text",
        "help",
        "markdown",
      }

      -- Improve performance by disabling features not needed
      vim.g.sleuth_neighbor_limit = 5 -- Limit number of neighboring files checked
    end,
  },

  -- Undo history visualizer
  {
    "mbbill/undotree",
    keys = {
      {
        "<leader>u",
        function()
          vim.cmd.UndotreeToggle()
          vim.cmd.UndotreeFocus() -- Automatically focus the undotree panel
        end,
        desc = "MANIAC_UNDOTREE [<leader>u] Toggle [U]ndoTree",
      },
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

      -- Increase the saved undo history for better undotree usage
      vim.opt.undofile = true                             -- Save undo history to file
      vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir" -- Dir for undo files
      vim.opt.undolevels = 10000                          -- Maximum number of changes that can be undone
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
        cloak_highlight_group = "Comment",
        cloak_fts = { "env", "sh" },
        cloak_filetypes = { "env", "sh" },
      })
    end,
  },

}
