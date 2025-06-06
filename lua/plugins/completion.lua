-- lua/plugins/completion.lua
return {
  -- Core completion plugins
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-buffer",
      -- "hrsh7th/cmp-path", -- using async-path instead
      "https://codeberg.org/FelipeLema/cmp-async-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "onsails/lspkind.nvim",
      "tjdevries/plenary.nvim",
      "tjdevries/complextras.nvim",
      {
        "roobert/tailwindcss-colorizer-cmp.nvim",
        config = true,
      },
    },
    enabled = function()
      local disabled = false
      disabled = disabled or (vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'prompt')
      disabled = disabled or (vim.fn.reg_recording() ~= '')
      disabled = disabled or (vim.fn.reg_executing() ~= '')
      disabled = disabled or require('cmp.config.context').in_treesitter_capture('comment')
      return not disabled
    end,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")

      -- Setup Tailwind colorizer
      require("tailwindcss-colorizer-cmp").setup({
        color_square_width = 2,
      })

      -- Helper function for Tab completion
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- Set completeopt
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      vim.opt.shortmess:append("c")

      cmp.setup({

        sources = {
          { name = "nvim_lsp" },
          { name = "nvim_lua",   priority = 900, keyword_length = 2 },
          { name = "async_path", priority = 500 },
          {
            name = "buffer",
            priority = 300,
            option = {
              get_bufnrs = function()
                -- Complete from visible buffers
                local bufs = {}
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  bufs[vim.api.nvim_win_get_buf(win)] = true
                end
                return vim.tbl_keys(bufs)
              end,
              keyword_length = 3,
            },
          },
          { name = "nvim_lsp_signature_help" },
        },

        window = {
          completion = cmp.config.window.bordered({
            winhighlight = "Normal:CmpNormal",
          }),
          documentation = cmp.config.window.bordered({
            winhighlight = "Normal:CmpDocNormal",
          }),
        },

        formatting = {
          fields = { "abbr", "kind", "menu" },
          expandable_indicator = true,
          format = function(entry, vim_item)
            -- Format with lspkind
            vim_item = lspkind.cmp_format({
              mode = "symbol_text",
              menu = {
                buffer = "[Buffer]",
                nvim_lsp = "[LSP]",
                nvim_lua = "[Lua]",
                async_path = "[Path]",
                vim_dadbod_completion = "[DB]",
                nvim_lsp_signature_help = "[Sig]",
              },
              maxwidth = 50,
            })(entry, vim_item)

            -- Apply tailwind colorizer
            vim_item = require("tailwindcss-colorizer-cmp").formatter(entry, vim_item)

            return vim_item
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ["<M-p>"] = cmp.mapping.scroll_docs(-4),
          ["<M-n>"] = cmp.mapping.scroll_docs(4),
          ["<C-e>"] = cmp.mapping.close(),

          ["<C-y>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }),
          ["<M-y>"] = cmp.mapping(
            cmp.mapping.confirm({
              behavior = cmp.ConfirmBehavior.Replace,
              select = false,
            }),
            { "i", "c" }
          ),

          -- Ctrl-Space to manually trigger completion
          ["<c-space>"] = cmp.mapping({
            i = cmp.mapping.complete(),
            c = function(_)
              if cmp.visible() then
                if not cmp.confirm({ select = true }) then
                  return
                end
              else
                cmp.complete()
              end
            end,
          }),

          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        sorting = {
          priority_weight = 2,
          comparators = {
            -- Default sorting
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,

            -- Underscore handling
            function(entry1, entry2)
              local _, entry1_under = entry1.completion_item.label:find("^_+")
              local _, entry2_under = entry2.completion_item.label:find("^_+")
              entry1_under = entry1_under or 0
              entry2_under = entry2_under or 0
              if entry1_under > entry2_under then
                return false
              elseif entry1_under < entry2_under then
                return true
              end
            end,

            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },

      })

      -- Command line completion
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer", keyword_length = 5 },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "async_path", keyword_length = 4, max_item_count = 7 },
          { name = "cmdline",    keyword_length = 5, max_item_count = 7 },
        }),
        matching = { disallow_symbol_nonprefix_matching = false },
        formatting = {
          fields = { "abbr" },
          expandable_indicator = true,
        },
      })

      -- SQL/Database completion
      cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
        sources = cmp.config.sources({
          { name = "vim-dadbod-completion", priority = 1000 },
          { name = "buffer",                priority = 500 },
        }),
      })

      -- Complextras line completion
      vim.api.nvim_set_keymap(
        "i",
        "<C-x><C-m>",
        [[<c-r>=luaeval("require('complextras').complete_matching_line()")<CR>]],
        { noremap = true, desc = "[<C-x><C-m>] Complete line completion" }
      )
    end,
  },
}
