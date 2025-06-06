-- lua/plugins/treeshitter.lua
-- Ref: https://www.josean.com/posts/nvim-treesitter-and-textobjects
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          disable = function(lang, buf)
            if lang == "htmldjango" then
              return true
            end
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
        },
        indent = { enable = true },
        ensure_installed = {
          "bash",
          "c",
          "comment",
          "cpp",
          "css",
          "dockerfile",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "sql",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        },
        -- Auto-install missing parsers when entering buffer
        auto_install = true,

        -- Incremental selection based on syntax tree
        incremental_selection = {
          enable = true,
          disable = { "htmldjango" },
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<C-backspace>",
          },
        },
        -- Treesitter extensions
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to matching textobj
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
              ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
              ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
              ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

              ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
              ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

              ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
              ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

              ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
              ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

              ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
              ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

              ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
              ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

              ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },

              ["ad"] = { query = "@comment.outer", desc = "Select outer part of a comment" },
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- Track jumps in jumplist
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]p"] = "@parameter.inner",
              ["]b"] = "@block.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[p"] = "@parameter.inner",
              ["[b"] = "@block.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>sa"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>sA"] = "@parameter.inner",
            },
          },
        },
      })
      local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

      -- vim way: ; goes to the direction you were moving.
      vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
    end,
  },
  -- Improved commenting with treesitter awareness
  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
}
