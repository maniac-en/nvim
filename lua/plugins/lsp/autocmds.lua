-- lua/plugins/lsp/autocmds.lua
local group = vim.api.nvim_create_augroup("ManiacLSP", { clear = true })
local format_group = vim.api.nvim_create_augroup("ManiacLSPFormat", { clear = true })

-- Go: organize imports (gopls code action), then format
-- Ref: https://go.dev/gopls/editor/vim#neovim-imports
local function go_organize_imports(bufnr, client)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  ---@diagnostic disable-next-line: inject-field
  params.context = { only = { "source.organizeImports" } }
  -- 1000ms timeout; raise it if you have to write twice for imports to apply
  local res = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
  for _, r in pairs((res and res.result) or {}) do
    if r.edit then
      vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
    end
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    -- Disable semantic highlights: A language server can apply new highlights to your code, this is known as semantic tokens.
    client.server_capabilities.semanticTokensProvider = nil

    -- Enable workspace diagnostics
    require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)

    -- Format on save: one autocmd per buffer, however many clients attach.
    -- Capabilities are checked at save time because some servers (e.g. ruff)
    -- register formatting dynamically, after LspAttach has fired.
    vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_group,
      buffer = bufnr,
      callback = function()
        if vim.bo[bufnr].filetype == "go" then
          local gopls = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })[1]
          if gopls then go_organize_imports(bufnr, gopls) end
        end
        if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }) > 0 then
          vim.lsp.buf.format({ bufnr = bufnr, async = false })
        end
      end,
    })
  end,
})
