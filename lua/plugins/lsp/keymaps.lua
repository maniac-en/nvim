-- lua/plugings/lsp/keymaps.lua
local M = {}

local map = function(mode, lhs, rhs, desc, bufnr)
  if desc then
    desc = "MANIAC_LSP: " .. desc
  end
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, remap = false, desc = desc, silent = true })
end

function M.setup()
  -- Stuff to do when LSP is attached
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ManiacLSPKeybinds", {}),
    callback = function(args)
      local bufnr = args.buf
      if not bufnr then return end

      -- LSP related mappings
      local tele_builtin = require("telescope.builtin")
      map("n", "<leader>ds", tele_builtin.lsp_document_symbols, "[<leader>ds] Get [D]ocument [S]ymbols via telescope",
        bufnr)

      map("n", "gd", tele_builtin.lsp_definitions, "[gd] [G]et [D]efinition via telescope", bufnr)
      map("n", "<leader>gd", function()
        tele_builtin.lsp_definitions({
          jump_type = "vsplit"
        })
      end, "[<leader>gd] Definition in vertical split", bufnr)
      map("n", "gD", vim.lsp.buf.declaration, "[gD] [G]et [D]eclaration", bufnr)
      map("n", "gi", tele_builtin.lsp_implementations, "[gi] [G]et [I]mplementation", bufnr)
      map("n", "<leader>sd", tele_builtin.diagnostics, "[<leader>sd] Show [D]iagnostics via telescope", bufnr)
      map(
        "n",
        "<leader>ws",
        tele_builtin.lsp_dynamic_workspace_symbols,
        "[<leader>ws] Get dynamic [W]orkspace [S]ymbols",
        bufnr
      )
      map("n", "<leader>td", tele_builtin.lsp_type_definitions, "[<leader>td] LSP [T]ype [D]efinitions", bufnr)
    end,
  })
end

M.setup()
return M
