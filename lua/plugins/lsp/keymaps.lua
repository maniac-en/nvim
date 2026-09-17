-- lua/plugins/lsp/keymaps.lua
local set = require("config.map").set

local float_opts = { max_width = 100, max_height = 14 }

-- Stuff to do when LSP is attached
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ManiacLSPKeybinds", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local function map(mode, lhs, rhs, area, text)
      set(mode, lhs, rhs, area, text, { buffer = bufnr, silent = true })
    end
    local tele = function(picker, opts)
      return function() require("telescope.builtin")[picker](opts) end
    end

    -- Hover / signature help with size limits (defaults are K and insert-mode <C-s>)
    map("n", "K", function() vim.lsp.buf.hover(float_opts) end, "LSP", "hover documentation")
    map("i", "<C-s>", function() vim.lsp.buf.signature_help(float_opts) end, "LSP", "[S]ignature help")

    -- Navigation: every LSP jump is gr + a letter, opening a telescope picker
    -- (<C-q> in the picker sends the results to the quickfix list). grd and grs
    -- are ours; grr/gri/grt are Neovim defaults pointed at telescope here.
    -- Built in and left alone: grn rename, gra code action, grx run codelens.
    map("n", "grd", tele("lsp_definitions"), "LSP", "[G]o to [D]efinition")
    map("n", "grr", tele("lsp_references"), "LSP", "[R]eferences")
    map("n", "gri", tele("lsp_implementations"), "LSP", "[I]mplementations")
    map("n", "grt", tele("lsp_type_definitions"), "LSP", "[T]ype definition")
    map("n", "grs", tele("lsp_document_symbols"), "LSP", "[S]ymbols in this file")
    map("n", "gO", tele("lsp_document_symbols"), "LSP", "symbols in this file (same as grs)")
    map("n", "<leader>sy", tele("lsp_dynamic_workspace_symbols"), "Search", "[S]earch s[Y]mbols in the project")
  end,
})
