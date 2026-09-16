-- lua/plugins/git.lua
return {
  -- Fugitive: Git commands in nvim
  {
    "tpope/vim-fugitive",
    cmd = {
      "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Ghdiffsplit", "GBrowse", "Gread", "Gwrite", "Gwq",
      "Gedit", "Gsplit", "Gvsplit", "Gtabedit", "Gpedit", "Gdrop", "Gclog", "Gllog", "Ggrep", "Glgrep",
      "GMove", "GRename", "GDelete", "GRemove", "GUnlink", "Gcd", "Glcd",
    },
    keys = { "<leader>gs", "<leader>gb" },
    dependencies = { "tpope/vim-rhubarb" },
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

      -- :AiCommit lives in ftplugin/gitcommit.lua
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
