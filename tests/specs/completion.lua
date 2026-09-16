-- tests/specs/completion.lua
-- blink.cmp (typing, accept, comments, per-filetype sources, cmdline) and
-- whole-line completion (<C-x><C-m>, <C-x><C-w>).
return function(T)
  local check, await, keys = T.check, T.await, T.keys

  check("nvim-cmp is gone", package.loaded.cmp == nil and not pcall(require, "cmp"))

  T.go_module("go")
  T.write("go/comp.go", { "package main", "", "func helper() {", "\t", "}" })
  local buf = T.open("go/comp.go")
  T.wait_client(buf, "gopls")
  await(function() return false end, 1500) -- let gopls load the package

  local blink = require("blink.cmp")
  check("Rust fuzzy matcher active", require("blink.cmp.fuzzy").implementation_type == "rust",
    require("blink.cmp.fuzzy").implementation_type)
  local gopls = vim.lsp.get_clients({ bufnr = buf, name = "gopls" })[1]
  check("LSP clients get blink.cmp capabilities", gopls and vim.deep_equal(
    gopls.config.capabilities.textDocument.completion, blink.get_lsp_capabilities().textDocument.completion))

  -- Typing shows LSP items; <C-y> accepts the selected (first) one
  vim.api.nvim_win_set_cursor(0, { 4, 1 })
  keys("A")
  await(function() return vim.fn.mode() == "i" end)
  keys("fmt.Prin")
  local shown = await(function()
    for _, item in ipairs(blink.get_items() or {}) do
      if item.source_id == "lsp" and item.label == "Println" then return blink.is_menu_visible() end
    end
  end, 10000)
  check("menu shows LSP items while typing", shown,
    vim.inspect(vim.tbl_map(function(i) return i.label end, vim.list_slice(blink.get_items() or {}, 1, 5))))
  keys("<C-y>")
  local accepted = await(function() return vim.api.nvim_get_current_line():find("fmt%.Print%w*%(") ~= nil end)
  check("<C-y> accepts an item", accepted, vim.api.nvim_get_current_line())
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)

  -- No completion inside comments
  vim.api.nvim_buf_set_lines(buf, 3, 4, false, { "\t// fmt.Prin" })
  vim.api.nvim_win_set_cursor(0, { 4, 11 })
  keys("a")
  await(function() return vim.fn.mode() == "i" end)
  keys("t")
  check("no menu inside comments", not await(function() return blink.is_menu_visible() end, 2000))
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)
  vim.cmd("silent! bwipeout!")

  -- Filetype-specific sources
  local providers = function() return vim.tbl_keys(require("blink.cmp.sources.lib").get_enabled_providers("default")) end
  T.write("misc/t.sql", { "select 1;" })
  T.open("misc/t.sql")
  check("SQL uses dadbod source", vim.tbl_contains(providers(), "dadbod"), vim.inspect(providers()))
  T.write("misc/t.lua", { "local x = 1" })
  local lbuf_lua = T.open("misc/t.lua")
  T.wait_client(lbuf_lua, "lua_ls")
  -- lazydev's source enables itself once lazydev has attached to the buffer
  check("Lua uses lazydev source",
    await(function() return vim.tbl_contains(providers(), "lazydev") end, 10000), vim.inspect(providers()))

  -- Command-line menu shows automatically (after 4 characters)
  keys(":checkhea")
  local cmd_menu = await(function() return vim.fn.mode() == "c" and blink.is_menu_visible() end)
  keys("<C-c>")
  await(function() return vim.fn.mode() == "n" end)
  check("cmdline menu shows while typing", cmd_menu)

  -- Whole-line completion: <C-x><C-m> (current buffer), <C-x><C-w> (workspace via rg)
  T.write("misc/lines_other.txt", { "unopened = smoke_marker_42 * 2" })
  T.write("misc/lines.txt", { "in buffer: smoke_marker_42 here", "" })
  local lbuf = T.open("misc/lines.txt")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  local function pum_words()
    return vim.tbl_map(function(i) return i.word end, vim.fn.complete_info({ "items" }).items or {})
  end
  keys("A")
  await(function() return vim.fn.mode() == "i" end)
  keys("smoke_marker_42")
  await(function() return vim.api.nvim_get_current_line() == "smoke_marker_42" end)
  keys("<C-x><C-m>")
  await(function() return vim.fn.pumvisible() == 1 end)
  local words = pum_words()
  check("line completion: <C-x><C-m> offers matching buffer lines only",
    vim.deep_equal(words, { "in buffer: smoke_marker_42 here" }), vim.inspect(words))
  keys("<C-e>")
  await(function() return vim.fn.pumvisible() == 0 end)
  keys("<C-x><C-w>")
  await(function() return vim.fn.pumvisible() == 1 end)
  words = pum_words()
  check("line completion: <C-x><C-w> includes lines from unopened files",
    vim.tbl_contains(words, "unopened = smoke_marker_42 * 2"), vim.inspect(words))
  keys("<C-e><Esc>")
  await(function() return vim.fn.mode() == "n" end)
  vim.api.nvim_buf_delete(lbuf, { force = true })
end
