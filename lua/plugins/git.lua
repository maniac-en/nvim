-- lua/plugins/git.lua
return {
  -- Fugitive: Git commands in nvim
  {
    "tpope/vim-fugitive",
    event = { "VeryLazy", "BufReadPre" },                                       -- Load when needed or when buffer is read
    cmd = { "Git", "Gvdiffsplit", "GBrowse", "Gdiffsplit", "Gwrite", "Gread" }, -- Load on these commands
    dependencies = { "tpope/vim-rhubarb" },                                     -- GitHub integration
    config = function()
      local map = function(mode, lhs, rhs, desc, silent)
        silent = silent or false
        if desc then
          desc = "MANIAC_FUGITIVE: " .. desc
        end
        vim.keymap.set(mode, lhs, rhs, { remap = false, silent = silent, desc = desc })
      end

      map("n", "<leader>gs", vim.cmd.Git, "[<leader>gs] [G]it [S]tatus", true)
      map("n", "<leader>gb", ":GBrowse %<CR>", "[<leader>gb] [G]it [B]rowse", false)
    end,
  },

  -- Gitsigns: Git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500, -- Faster blame display
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
      },
      watch_gitdir = {
        follow_files = true,
        interval = 2000,          -- Reduced polling interval for better performance
      },
      attach_to_untracked = true, -- Show signs for untracked files
      update_debounce = 200,      -- Faster updates
      word_diff = false,          -- Can be toggled via command
    },
  },

  --  GV: A git commit browser in Vim
  {
    "junegunn/gv.vim",
    dependencies = {
      "tpope/vim-fugitive",
    }
  }
}
