-- lua/plugins/lsp/autocmds.lua
local group = vim.api.nvim_create_augroup("ManiacLSP", { clear = true })
local format_group = vim.api.nvim_create_augroup("ManiacLSPFormat", { clear = true })

-- Organize imports on save, per filetype: which client provides the code action
-- Ref: https://go.dev/gopls/editor/vim#neovim-imports
local organize_imports = {
  go = "gopls",
  python = "ruff",
}

-- Filetypes that are not formatted on save
-- html: parked; embedded JS/CSS/templates make formatting unpredictable
local no_format_on_save = {
  html = true,
}

local function run_organize_imports(bufnr, client)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  ---@diagnostic disable-next-line: inject-field
  params.context = { only = { "source.organizeImports" }, diagnostics = {} }
  -- 1000ms timeout; raise it if you have to write twice for imports to apply
  local res = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
  for _, action in pairs((res and res.result) or {}) do
    -- Some servers (e.g. ruff) return the action without its edit; resolve it
    if not action.edit and client:supports_method("codeAction/resolve", bufnr) then
      local resolved = client:request_sync("codeAction/resolve", action, 1000, bufnr)
      action = (resolved and resolved.result) or action
    end
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
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
        local ft = vim.bo[bufnr].filetype
        if no_format_on_save[ft] then return end
        local importer = organize_imports[ft]
        if importer then
          local c = vim.lsp.get_clients({ bufnr = bufnr, name = importer })[1]
          if c then run_organize_imports(bufnr, c) end
        end
        if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }) > 0 then
          vim.lsp.buf.format({ bufnr = bufnr, async = false })
        end
      end,
    })
  end,
})
