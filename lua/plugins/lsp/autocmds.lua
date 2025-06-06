-- lua/plugings/lsp/autocmds.lua
local M = {}

function M.setup()
  -- Stuff to do when LSP is attached
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end

      -- Disable semantic highlights: A language server can apply new highlights
      -- to your code, this is known as semantic tokens.
      client.server_capabilities.semanticTokensProvider = nil

      ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
      if client:supports_method('textDocument/formatting') then
        -- Format the current buffer on save
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = args.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = args.buf, id = client.id, })
          end
        })
      end

      -- mappings
      vim.keymap.set(
        "n",
        "<leader>ds",
        require("telescope.builtin").lsp_document_symbols,
        {
          buffer = true,
          -- bufnr = args.buf,
          desc = "MANIAC_LSP: [<leader>ds] Get [D]ocument [S]ymbols",
          silent = true,
        }
      )
    end,
  })
end

M.setup()
return M
