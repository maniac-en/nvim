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

    -- Navigation (telescope pickers); built in as well: grr grn gra gri grt gO
    map("n", "gd", tele("lsp_definitions"), "LSP", "[G]o to [D]efinition")
    map("n", "<leader>gd", tele("lsp_definitions", { jump_type = "vsplit" }), "LSP",
      "[G]o to [D]efinition in vertical split")
    map("n", "gD", vim.lsp.buf.declaration, "LSP", "[G]o to [D]eclaration")
    map("n", "gi", tele("lsp_implementations"), "LSP", "[G]o to [I]mplementation")
    map("n", "<leader>td", tele("lsp_type_definitions"), "LSP", "[T]ype [D]efinition")
    map("n", "<leader>ds", tele("lsp_document_symbols"), "LSP", "[D]ocument [S]ymbols")
    map("n", "<leader>ws", tele("lsp_dynamic_workspace_symbols"), "LSP", "[W]orkspace [S]ymbols")
    map("n", "<leader>sd", tele("diagnostics"), "Search", "[S]earch [D]iagnostics")
  end,
})
