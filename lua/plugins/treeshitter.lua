-- lua/plugins/treeshitter.lua
-- nvim-treesitter `main` branch (Neovim 0.12+): installs parsers/queries only.
-- Highlighting and indentation are switched on per buffer below; folds stay manual.
-- Docs: :h nvim-treesitter, :h treesitter

local parsers = {
  -- Go / Python / Lua (config)
  "go", "gomod", "gosum", "gowork",
  "python",
  "lua", "luadoc", "vim", "vimdoc", "query",
  -- C / web / data / shell
  "c", "cpp", "make",
  "html", "css", "javascript", "typescript", "tsx",
  "json", "yaml", "toml", "sql", "http",
  "bash",
  -- docs / git
  "markdown", "markdown_inline", "comment", "gitcommit", "diff",
}

-- Filetypes/languages where treesitter highlighting stays off
local no_highlight = { htmldjango = true, dockerfile = true }
local max_filesize = 100 * 1024 -- 100 KB

---@param buf integer
---@param lang string
local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.treesitter.language.add(lang) then return end
  if no_highlight[lang] then return end
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  if ok and stats and stats.size > max_filesize then return end

  vim.treesitter.start(buf, lang)
  if vim.treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.install(parsers) -- async; no-op for parsers already installed

      local available = ts.get_available()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("maniac_treesitter", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then return end
          if vim.tbl_contains(ts.get_installed("parsers"), lang) or not vim.tbl_contains(available, lang) then
            attach(buf, lang)
          else
            -- missing but installable: install, then attach
            ts.install(lang):await(function() attach(buf, lang) end)
          end
        end,
      })

      -- Grow/shrink the selection by syntax node, on top of the built-in
      -- visual-mode `an` (parent node) / `in` (child node)
      vim.keymap.set("n", "<C-space>", function()
        -- select the node under the cursor itself (`van` would skip one-character nodes)
        local node = vim.treesitter.get_node()
        if not node then return vim.cmd("normal van") end -- no parser: LSP selection range fallback
        local sr, sc, er, ec = node:range()
        if ec == 0 and er > sr then -- range ends at the start of a line: stop at the previous line's end
          er = er - 1
          ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
        end
        vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
      end, { desc = "MANIAC_TS: [<C-space>] Select node under cursor" })
      vim.keymap.set("x", "<C-space>", "an", { remap = true, desc = "MANIAC_TS: [<C-space>] Grow selection to parent node" })
      vim.keymap.set("x", "<C-backspace>", "in", { remap = true, desc = "MANIAC_TS: [<C-backspace>] Shrink selection to child node" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true }, -- jump forward to the next textobject
        move = { set_jumps = true },    -- record moves in the jumplist
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      local function map(modes, lhs, fn, desc)
        vim.keymap.set(modes, lhs, fn, { desc = "MANIAC_TS: " .. desc })
      end

      -- Select: { keys, capture, description }
      for _, obj in ipairs({
        { "a=", "@assignment.outer", "outer part of an assignment" },
        { "i=", "@assignment.inner", "inner part of an assignment" },
        { "l=", "@assignment.lhs", "left hand side of an assignment" },
        { "r=", "@assignment.rhs", "right hand side of an assignment" },
        { "aa", "@parameter.outer", "outer part of a parameter/argument" },
        { "ia", "@parameter.inner", "inner part of a parameter/argument" },
        { "ai", "@conditional.outer", "outer part of a conditional" },
        { "ii", "@conditional.inner", "inner part of a conditional" },
        { "al", "@loop.outer", "outer part of a loop" },
        { "il", "@loop.inner", "inner part of a loop" },
        { "af", "@call.outer", "outer part of a function call" },
        { "if", "@call.inner", "inner part of a function call" },
        { "am", "@function.outer", "outer part of a method/function definition" },
        { "im", "@function.inner", "inner part of a method/function definition" },
        { "ac", "@class.outer", "outer part of a class" },
        { "ic", "@class.inner", "inner part of a class" },
        { "ab", "@block.outer", "outer part of a block" },
        { "ib", "@block.inner", "inner part of a block" },
        { "ir", "@request.inner", "inner HTTP request" }, -- queries/http/textobjects.scm
        { "ar", "@request.outer", "HTTP request" },
        { "ad", "@comment.outer", "outer part of a comment" },
      }) do
        map({ "x", "o" }, obj[1], function() select.select_textobject(obj[2], "textobjects") end,
          ("[%s] Select %s"):format(obj[1], obj[3]))
      end

      -- Move: ]x next start, [x previous start
      for key, capture in pairs({ f = "@function.outer", c = "@class.outer", p = "@parameter.inner", b = "@block.outer", r = "@request.outer" }) do
        map({ "n", "x", "o" }, "]" .. key, function() move.goto_next_start(capture, "textobjects") end,
          ("[]%s] Next %s start"):format(key, capture))
        map({ "n", "x", "o" }, "[" .. key, function() move.goto_previous_start(capture, "textobjects") end,
          ("[[%s] Previous %s start"):format(key, capture))
      end

      -- Swap parameters
      map("n", "<leader>sa", function() swap.swap_next("@parameter.inner") end, "[<leader>sa] Swap with next parameter")
      map("n", "<leader>sA", function() swap.swap_previous("@parameter.inner") end, "[<leader>sA] Swap with previous parameter")

      -- vim way: ; repeats in the direction you were moving, , the opposite;
      -- builtin f/F/t/T are repeatable the same way
      local repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
      vim.keymap.set({ "n", "x", "o" }, ";", repeat_move.repeat_last_move)
      vim.keymap.set({ "n", "x", "o" }, ",", repeat_move.repeat_last_move_opposite)
      vim.keymap.set({ "n", "x", "o" }, "f", repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "F", repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "t", repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ "n", "x", "o" }, "T", repeat_move.builtin_T_expr, { expr = true })
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
