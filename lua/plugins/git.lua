-- lua/plugins/git.lua
local key = require("config.map").lazy

return {
  -- Fugitive: Git commands in nvim
  {
    "tpope/vim-fugitive",
    cmd = {
      "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Ghdiffsplit", "GBrowse", "Gread", "Gwrite", "Gwq",
      "Gedit", "Gsplit", "Gvsplit", "Gtabedit", "Gpedit", "Gdrop", "Gclog", "Gllog", "Ggrep", "Glgrep",
      "GMove", "GRename", "GDelete", "GRemove", "GUnlink", "Gcd", "Glcd",
    },
    -- declared here (not in config) so they're described before fugitive loads;
    -- :AiCommit lives in ftplugin/gitcommit.lua
    keys = {
      key("<leader>gs", "<cmd>Git<CR>", "Git", "[G]it [S]tatus", { silent = true }),
      key("<leader>gb", ":GBrowse %<CR>", "Git", "[G]it [B]rowse (open file in browser)"),
    },
    dependencies = { "tpope/vim-rhubarb" },
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
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
      },
      -- libuv watcher on .git: signs update as soon as git state changes
      watch_gitdir = {
        enable = true,
        follow_files = true,
      },
      attach_to_untracked = true,
      update_debounce = 200,
      word_diff = false,
    },
  },

  -- GV: A git commit browser in Vim
  {
    "junegunn/gv.vim",
    cmd = "GV",
    dependencies = {
      "tpope/vim-fugitive",
    },
  },
}
