-- lua/plugins/completion.lua
-- Docs: :h blink-cmp  (https://cmp.saghen.dev)

-- Menu marker for where an item came from (same markers the old nvim-cmp setup used)
local source_icons = {
  lsp = "λ",
  path = "🖫",
  buffer = "Ω",
  lazydev = "Π",
  dadbod = "🛢",
  cmdline = ":",
}

-- Is the character before the cursor inside a treesitter comment node?
-- (the node *at* an insert-mode cursor at end of line is the enclosing block)
local function in_comment()
  local ok, result = pcall(function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if not parser then return false end
    parser:parse({ row - 1, row }) -- make sure the tree reflects what was just typed
    local node = vim.treesitter.get_node({ pos = { row - 1, math.max(col - 1, 0) } })
    return node ~= nil and node:type():find("comment") ~= nil
  end)
  return ok and result
end

return {
  {
    "saghen/blink.cmp",
    -- release tags ship a prebuilt Rust fuzzy matcher
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      enabled = function()
        -- no completion while recording/replaying macros or inside comments
        -- (default conditions for prompt buffers and vim.b.completion = false still apply)
        if vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= "" then return false end
        return not in_comment()
      end,

      keymap = {
        preset = "none",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-y>"] = { "select_and_accept", "fallback" },

        ["<C-n>"] = { "select_next", "fallback_to_mappings" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },

        ["<M-p>"] = { "scroll_documentation_up", "fallback" },
        ["<M-n>"] = { "scroll_documentation_down", "fallback" },
        -- snippet placeholders: <Tab>/<S-Tab> are Neovim's built-in vim.snippet jumps
      },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        menu = {
          draw = {
            columns = { { "source_icon" }, { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
            components = {
              source_icon = {
                ellipsis = false,
                text = function(ctx) return source_icons[ctx.source_id] or ctx.source_id end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
      },

      -- signature help while typing function arguments
      signature = { enabled = true },

      sources = {
        default = { "lsp", "path", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
          sql = { "dadbod", "buffer" },
          mysql = { "dadbod", "buffer" },
          plsql = { "dadbod", "buffer" },
        },
        providers = {
          -- show buffer words alongside LSP items, not only when LSP has none
          lsp = { fallbacks = {} },
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
          buffer = {
            -- in / and ? searches, wait for 5 characters
            min_keyword_length = function(ctx) return ctx.mode == "cmdline" and 5 or 0 end,
          },
          cmdline = {
            -- in : commands, wait for 4 characters
            min_keyword_length = function(ctx) return ctx.mode == "cmdline" and 4 or 0 end,
            max_items = 7,
          },
        },
      },

      cmdline = {
        completion = { menu = { auto_show = true } },
      },

      fuzzy = {
        implementation = "prefer_rust_with_warning",
        -- 'label' also sorts entries starting with `_` last
        sorts = { "exact", "score", "sort_text", "label" },
      },
    },
    opts_extend = { "sources.default" },
  },
}
