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
      -- Buffer-local, only in files gitsigns attaches to (inside a repo).
      -- Staging here is for quick fixes; <leader>gs (fugitive) is the full view.
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, text)
          require("config.map").set(mode, lhs, rhs, "Hunk", text, { buffer = bufnr, silent = true })
        end

        -- Navigation
        map("n", "]h", function() gs.nav_hunk("next") end, "next [h]unk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "previous [h]unk")
        map("n", "]H", function() gs.nav_hunk("last") end, "last [h]unk")
        map("n", "[H", function() gs.nav_hunk("first") end, "first [h]unk")

        -- Viewing
        map("n", "<leader>hp", gs.preview_hunk, "[P]review hunk in a float")
        map("n", "<leader>hi", gs.preview_hunk_inline, "preview hunk [i]nline")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "[B]lame this line")
        map("n", "<leader>hd", gs.diffthis, "[D]iff this file against the index")
        map("n", "<leader>hq", gs.setqflist, "hunks of this buffer to the [Q]uickfix list")
        map("n", "<leader>hQ", function() gs.setqflist("all") end, "hunks of all buffers to the [Q]uickfix list")

        -- Staging (visual: only the selected lines)
        map("n", "<leader>hs", gs.stage_hunk, "[S]tage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "[R]eset hunk")
        map("x", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          "[S]tage selected lines")
        map("x", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          "[R]eset selected lines")
        map("n", "<leader>hS", gs.stage_buffer, "[S]tage the whole buffer")
        map("n", "<leader>hR", gs.reset_buffer, "[R]eset the whole buffer")

        -- Toggles
        map("n", "<leader>hB", gs.toggle_current_line_blame, "toggle [B]lame text on the current line")
        map("n", "<leader>hw", gs.toggle_word_diff, "toggle [w]ord-level diff highlighting")

        -- Textobject: vih selects the hunk, dah deletes it
        map({ "o", "x" }, "ih", gs.select_hunk, "[i]nside [h]unk")
        map({ "o", "x" }, "ah", gs.select_hunk, "[a]round [h]unk")
      end,
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
