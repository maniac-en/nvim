-- tests/specs/lazy.lua
-- Lazy-loaded plugins load on their keys, commands, filetypes and VeryLazy.
return function(T)
  local check, await, keys = T.check, T.await, T.keys
  local function close_floats()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w).relative ~= "" then
        pcall(vim.api.nvim_win_close, w, true)
      end
    end
  end

  -- lazydev loads only once a Lua file is opened
  T.write("lazy/t.txt", { "word here" })
  T.open("lazy/t.txt")
  check("lazydev not loaded before a Lua file", not T.plugin_loaded("lazydev.nvim"))
  T.write("lazy/t.lua", { "local x = 1" })
  T.open("lazy/t.lua")
  check("lazydev loaded once a Lua file was opened", T.plugin_loaded("lazydev.nvim"))
  T.open("lazy/t.txt")

  -- keys
  check("telescope not loaded before its keys", not T.plugin_loaded("telescope.nvim"))
  keys("<C-p>")
  check("<C-p> loads telescope and opens a picker",
    await(function() return T.plugin_loaded("telescope.nvim") and vim.bo.filetype == "TelescopePrompt" end, 5000),
    vim.bo.filetype)
  keys("<Esc><Esc>")
  await(function() return vim.bo.filetype ~= "TelescopePrompt" end)
  close_floats()

  keys("<C-\\>")
  check("<C-\\> loads toggleterm and opens a terminal",
    await(function() return T.plugin_loaded("toggleterm.nvim") and vim.bo.filetype == "toggleterm" end, 5000),
    vim.bo.filetype)
  vim.cmd("stopinsert")
  close_floats()

  keys("<leader>gs")
  check("<leader>gs loads fugitive and opens :Git status",
    await(function() return T.plugin_loaded("vim-fugitive") and vim.bo.filetype == "fugitive" end, 5000),
    vim.bo.filetype)
  vim.cmd("silent! bwipeout")

  -- commands
  for _, case in ipairs({
    { cmd = "GV",      plugin = "gv.vim" },
    { cmd = "ZenMode", plugin = "zen-mode.nvim", after = "ZenMode" },
    { cmd = "FSRead",  plugin = "fsread.nvim",   after = "FSClear" },
  }) do
    T.open("lazy/t.txt")
    local ok, err = pcall(vim.cmd, "silent " .. case.cmd)
    check((":%s loads %s"):format(case.cmd, case.plugin), ok and T.plugin_loaded(case.plugin), err)
    if case.after then pcall(vim.cmd, case.after) end
    if case.cmd == "GV" then pcall(vim.cmd, "tabclose") end
  end

  -- VeryLazy plugins
  for _, name in ipairs({ "Comment.nvim", "vim-surround", "vim-repeat", "vim-unimpaired" }) do
    check(name .. " loaded on VeryLazy", T.plugin_loaded(name))
  end
  local tbuf = T.open("lazy/t.txt")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  T.run_keys('ysiw"')
  check("surround: ysiw\" surrounds a word", vim.api.nvim_buf_get_lines(tbuf, 0, 1, false)[1] == '"word" here',
    vim.api.nvim_buf_get_lines(tbuf, 0, 1, false)[1])
  T.run_keys("]<Space>")
  check("unimpaired: ]<Space> adds a blank line below", vim.api.nvim_buf_line_count(tbuf) == 2,
    vim.inspect(vim.api.nvim_buf_get_lines(tbuf, 0, -1, false)))
  vim.api.nvim_buf_delete(tbuf, { force = true })
end
