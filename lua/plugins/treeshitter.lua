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
      local map = require("config.map").set
      map("n", "<C-space>", function()
        -- select the node under the cursor itself (`van` would skip one-character nodes)
        local node = vim.treesitter.get_node()
        if not node then return vim.cmd("normal van") end -- no parser: LSP selection range fallback
        local sr, sc, er, ec = node:range()
        if ec == 0 and er > sr then                       -- range ends at the start of a line: stop at the previous line's end
          er = er - 1
          ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
        end
        vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
      end, "Select", "syntax node under cursor")
      map("x", "<C-space>", "an", "Select", "grow to parent node", { remap = true })
      map("x", "<C-backspace>", "in", "Select", "shrink to child node", { remap = true })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true }, -- jump forward to the next textobject
        move = { set_jumps = true },   -- record moves in the jumplist
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      local map = require("config.map").set

      -- Select (x, o): { keys, capture, description }
      for _, obj in ipairs({
        { "am", "@function.outer",    "[a]round [m]ethod or function" },
        { "im", "@function.inner",    "[i]nside [m]ethod or function" },
        { "af", "@call.outer",        "[a]round [f]unction call" },
        { "if", "@call.inner",        "[i]nside [f]unction call" },
        { "ac", "@class.outer",       "[a]round [c]lass" },
        { "ic", "@class.inner",       "[i]nside [c]lass" },
        { "aa", "@parameter.outer",   "[a]round [a]rgument" },
        { "ia", "@parameter.inner",   "[i]nside [a]rgument" },
        { "ai", "@conditional.outer", "[a]round [i]f (conditional)" },
        { "ii", "@conditional.inner", "[i]nside [i]f (conditional)" },
        { "al", "@loop.outer",        "[a]round [l]oop" },
        { "il", "@loop.inner",        "[i]nside [l]oop" },
        { "ab", "@block.outer",       "[a]round [b]lock" },
        { "ib", "@block.inner",       "[i]nside [b]lock" },
        { "a=", "@assignment.outer",  "[a]round assignment [=]" },
        { "i=", "@assignment.inner",  "[i]nside assignment [=]" },
        { "l=", "@assignment.lhs",    "[l]eft side of assignment [=]" },
        { "r=", "@assignment.rhs",    "[r]ight side of assignment [=]" },
        { "ad", "@comment.outer",     "around comment ([d]oc)" },
        { "ar", "@request.outer",     "[a]round HTTP [r]equest (with ### title)" }, -- queries/http/textobjects.scm
        { "ir", "@request.inner",     "[i]nside HTTP [r]equest (method to body)" },
      }) do
        map({ "x", "o" }, obj[1], function() select.select_textobject(obj[2], "textobjects") end, "Textobject", obj[3])
      end

      -- Move (n, x, o): ]x next start, [x previous start
      for key, target in pairs({
        f = { "@function.outer", "[f]unction" },
        c = { "@class.outer", "[c]lass" },
        p = { "@parameter.inner", "[p]arameter" },
        b = { "@block.outer", "[b]lock" },
        r = { "@request.outer", "HTTP [r]equest (### title line)" },
      }) do
        map({ "n", "x", "o" }, "]" .. key, function() move.goto_next_start(target[1], "textobjects") end,
          "Move", "next " .. target[2])
        map({ "n", "x", "o" }, "[" .. key, function() move.goto_previous_start(target[1], "textobjects") end,
          "Move", "previous " .. target[2])
      end

      -- Swap parameters
      map("n", "<leader>sa", function() swap.swap_next("@parameter.inner") end, "Swap", "[S]wap [A]rgument with next")
      map("n", "<leader>sA", function() swap.swap_previous("@parameter.inner") end, "Swap",
        "[S]wap [A]rgument with previous")

      -- vim way: ; repeats in the direction you were moving, , the opposite;
      -- builtin f/F/t/T are repeatable the same way
      local repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
      local nxo = { "n", "x", "o" }
      map(nxo, ";", repeat_move.repeat_last_move, "Move", "repeat last move (same direction)")
      map(nxo, ",", repeat_move.repeat_last_move_opposite, "Move", "repeat last move (opposite direction)")
      map(nxo, "f", repeat_move.builtin_f_expr, "Move", "[f]ind character forward (repeat with ; ,)", { expr = true })
      map(nxo, "F", repeat_move.builtin_F_expr, "Move", "[F]ind character backward (repeat with ; ,)", { expr = true })
      map(nxo, "t", repeat_move.builtin_t_expr, "Move", "[t]ill character forward (repeat with ; ,)", { expr = true })
      map(nxo, "T", repeat_move.builtin_T_expr, "Move", "[T]ill character backward (repeat with ; ,)", { expr = true })
    end,
  },

  -- Improved commenting with treesitter awareness
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
}
