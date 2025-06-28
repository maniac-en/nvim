-- lua/config/autocmds.lua
local augroup = vim.api.nvim_create_augroup
local maniac_aug = augroup("maniac_aug", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- highlight the yanked text post yanking
autocmd("TextYankPost", {
  group = maniac_aug,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

-- clear out trailing spaces on buffer write
autocmd("BufWrite", {
  group = maniac_aug,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- disable line numbers in terminal
autocmd("TermOpen", {
  group = maniac_aug,
  pattern = "*",
  callback = function()
    vim.o.number = false
    vim.o.relativenumber = false
    vim.o.spell = false
  end,
})

-- file-type buffer-specific format options

-- Auto-format paragraphs
autocmd("FileType", {
  group = maniac_aug,
  pattern = { "text" },
  callback = function()
    vim.opt_local.formatoptions = vim.opt_local.formatoptions + "a"
  end,
})

-- Preferred format options for coding
autocmd("FileType", {
  group = maniac_aug,
  pattern = { "sh", "go", "lua", "python", "javascript" },
  callback = function()
    vim.opt_local.formatoptions = "jcroql"
  end,
})

-- Organize go imports automatically on save
-- Ref: https://cs.opensource.google/go/x/tools/+/refs/tags/v0.18.0:gopls/doc/vim.md#neovim-imports
autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params(0, "utf-16")
    ---@diagnostic disable-next-line: inject-field
    params.context = { only = { "source.organizeImports" } }
    -- buf_request_sync defaults to a 1000ms timeout. Depending on your
    -- machine and codebase, you may want longer. Add an additional
    -- argument after params if you find that you have to write the file
    -- twice for changes to be saved.
    -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    vim.lsp.buf.format({ async = false })
  end
})

-- https://github.com/akinsho/toggleterm.nvim/issues/155
vim.api.nvim_create_autocmd({ "TermEnter" }, {
  callback = function()
    for _, buffers in ipairs(vim.fn.getbufinfo()) do
      local filetype = vim.api.nvim_buf_get_option(buffers.bufnr, "filetype")
      if filetype == "toggleterm" then
        vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
          buffer = buffers.bufnr,
          command = "q!",
        })
      end
    end
  end,
})
