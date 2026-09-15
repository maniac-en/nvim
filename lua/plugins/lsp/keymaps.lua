-- lua/plugins/lsp/keymaps.lua
local map = function(mode, lhs, rhs, desc, bufnr)
  if desc then
    desc = "MANIAC_LSP: " .. desc
  end
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, remap = false, desc = desc, silent = true })
end

local float_opts = { max_width = 100, max_height = 14 }

-- Stuff to do when LSP is attached
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ManiacLSPKeybinds", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local tele = function(picker, opts)
      return function() require("telescope.builtin")[picker](opts) end
    end

    -- Hover / signature help with size limits (defaults are K and insert-mode <C-s>)
    map("n", "K", function() vim.lsp.buf.hover(float_opts) end, "[K] Hover documentation", bufnr)
    map("i", "<C-s>", function() vim.lsp.buf.signature_help(float_opts) end, "[<C-s>] Signature help", bufnr)

    -- LSP related mappings
    map("n", "<leader>ds", tele("lsp_document_symbols"), "[<leader>ds] Get [D]ocument [S]ymbols via telescope", bufnr)
    map("n", "gd", tele("lsp_definitions"), "[gd] [G]et [D]efinition via telescope", bufnr)
    map("n", "<leader>gd", tele("lsp_definitions", { jump_type = "vsplit" }),
      "[<leader>gd] Definition in vertical split", bufnr)
    map("n", "gD", vim.lsp.buf.declaration, "[gD] [G]et [D]eclaration", bufnr)
    map("n", "gi", tele("lsp_implementations"), "[gi] [G]et [I]mplementation", bufnr)
    map("n", "<leader>sd", tele("diagnostics"), "[<leader>sd] Show [D]iagnostics via telescope", bufnr)
    map("n", "<leader>ws", tele("lsp_dynamic_workspace_symbols"), "[<leader>ws] Get dynamic [W]orkspace [S]ymbols", bufnr)
    map("n", "<leader>td", tele("lsp_type_definitions"), "[<leader>td] LSP [T]ype [D]efinitions", bufnr)
  end,
})
