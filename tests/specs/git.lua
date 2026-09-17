-- tests/specs/git.lua
-- gitsigns hunk keymaps: navigation, preview, quickfix, textobject, staging.
return function(T)
  local check, await, keys = T.check, T.await, T.keys

  -- A committed file, then two separate changes in the working copy
  local lines = {}
  for i = 1, 30 do lines[i] = "line " .. i end
  T.write("repo/file.txt", lines)
  T.git_add_all()
  vim.system({ "git", "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "base" }, { cwd = T.root }):wait(30000)
  lines[5] = "line 5 changed"
  lines[20] = "line 20 changed"
  T.write("repo/file.txt", lines)

  local buf = T.open("repo/file.txt")
  check("gitsigns attaches to a file in a repo",
    await(function() return package.loaded.gitsigns ~= nil and T.has_buf_map(buf, "n", "]h") end, 10000))

  -- gitsigns computes hunks asynchronously; wait for both before navigating
  local hunks = await(function()
    local ok, got = pcall(function() return require("gitsigns").get_hunks(buf) end)
    return ok and got ~= nil and #got == 2
  end, 10000)
  check("gitsigns sees both changes as hunks", hunks,
    vim.inspect((pcall(require, "gitsigns")) and require("gitsigns").get_hunks(buf)))

  -- ]h / [h / ]H / [H move between hunks
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  T.run_keys("]h")
  local first = await(function() return vim.api.nvim_win_get_cursor(0)[1] == 5 end, 5000)
  check("]h moves to the first hunk", first, "line " .. vim.api.nvim_win_get_cursor(0)[1])
  T.run_keys("]h")
  check("]h moves to the next hunk", await(function() return vim.api.nvim_win_get_cursor(0)[1] == 20 end, 5000),
    "line " .. vim.api.nvim_win_get_cursor(0)[1])
  T.run_keys("[h")
  check("[h moves back", await(function() return vim.api.nvim_win_get_cursor(0)[1] == 5 end, 5000),
    "line " .. vim.api.nvim_win_get_cursor(0)[1])

  -- <leader>hp opens the preview float
  T.run_keys("<leader>hp")
  local float = await(function()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(w).relative ~= "" then return true end
    end
    return false
  end, 5000)
  check("<leader>hp previews the hunk in a float", float)
  keys("<Esc>")
  await(function() return true end, 200)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= "" then pcall(vim.api.nvim_win_close, w, true) end
  end

  -- vih selects exactly the hunk's lines
  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  T.run_keys("vihy")
  check("vih selects the hunk", vim.fn.getreg('"') == "line 5 changed\n", vim.inspect(vim.fn.getreg('"')))

  -- <leader>hq sends this buffer's hunks to the quickfix list
  vim.fn.setqflist({}, "r")
  T.run_keys("<leader>hq")
  local qf = await(function() return #vim.fn.getqflist() == 2 end, 5000)
  check("<leader>hq fills the quickfix list with both hunks", qf, vim.inspect(vim.fn.getqflist()))

  -- <leader>hr resets a hunk in the buffer (setqflist opened and focused the list)
  vim.cmd("cclose")
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  T.run_keys("<leader>hr")
  local reset = await(function() return T.lines(buf)[5] == "line 5" end, 5000)
  check("<leader>hr resets the hunk", reset and T.lines(buf)[20] == "line 20 changed", T.lines(buf)[5])

  -- ]c moves between classes normally, but between changes inside a diff
  T.write("cls/a.py", { "class One:", "    pass", "", "", "class Two:", "    pass" })
  T.open("cls/a.py")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  T.run_keys("]c")
  check("]c jumps to the next class outside a diff", vim.api.nvim_win_get_cursor(0)[1] == 5,
    "line " .. vim.api.nvim_win_get_cursor(0)[1])

  vim.cmd("silent! only")
  T.open("repo/file.txt")
  vim.cmd("diffthis | vnew | diffthis")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "line 1", "changed here", "line 3" })
  vim.cmd("redraw")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  T.run_keys("]c")
  check("]c inside a diff jumps to the next change", vim.wo.diff and vim.api.nvim_win_get_cursor(0)[1] == 2,
    ("diff=%s line=%d"):format(tostring(vim.wo.diff), vim.api.nvim_win_get_cursor(0)[1]))
  vim.cmd("diffoff! | silent! only")
end
