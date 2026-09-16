-- tests/specs/editor.lua
-- Quickfix/location lists, runner commands, swap names, whitespace on save, :AiCommit.
return function(T)
  local check = T.check

  -- <CR> in quickfix and location list windows jumps to the entry under the cursor
  T.write("qf/target.txt", { "one", "two", "three" })
  local target = T.root .. "/qf/target.txt"
  for _, kind in ipairs({ "quickfix", "location" }) do
    vim.cmd("silent! only | enew")
    local entries = { { filename = target, lnum = 1, text = "first" }, { filename = target, lnum = 3, text = "third" } }
    if kind == "quickfix" then
      vim.fn.setqflist({}, "r")
      vim.fn.setqflist(entries, "r")
      vim.cmd("copen")
    else
      vim.fn.setqflist({}, "r") -- empty quickfix list: a quickfix-only command would fail here
      vim.fn.setloclist(0, entries, "r")
      vim.cmd("lopen")
    end
    vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- second entry
    vim.v.errmsg = ""
    T.run_keys("<CR>")
    local jumped = vim.api.nvim_buf_get_name(0) == target and vim.api.nvim_win_get_cursor(0)[1] == 3
    check(("%s list: <CR> jumps to the entry"):format(kind), jumped and vim.v.errmsg == "",
      ("buf=%s line=%d errmsg=%s"):format(vim.api.nvim_buf_get_name(0), vim.api.nvim_win_get_cursor(0)[1], vim.v.errmsg))
    vim.cmd("silent! cclose | silent! lclose | silent! only")
  end

  for _, cmd in ipairs({ "RunGo", "RunPython", "RunC", "RunJavascript", "RunTypescript", "RunLua" }) do
    check("command :" .. cmd, vim.fn.exists(":" .. cmd) == 2)
  end

  -- Same-named files in different directories get distinct swap files ('directory' ends in //)
  T.write("swap/a/same.txt", { "a" })
  T.write("swap/b/same.txt", { "b" })
  T.open("swap/a/same.txt")
  local swap_a = vim.fn.swapname("%")
  T.open("swap/b/same.txt")
  local swap_b = vim.fn.swapname("%")
  check("swap: same-named files get distinct, full-path swap names",
    swap_a ~= swap_b and swap_a:find("swap%%a%%same.txt") ~= nil, swap_a .. " vs " .. swap_b)

  -- Trailing whitespace is stripped on save without moving the cursor or the search
  T.write("ws/t.txt", { "x   ", "hello" })
  local buf = T.open("ws/t.txt")
  vim.fn.setreg("/", "hello")
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  vim.cmd("silent write")
  check("whitespace: stripped on save", T.lines(buf)[1] == "x", vim.inspect(T.lines(buf)))
  check("whitespace: cursor kept", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 3 }))
  check("whitespace: search pattern kept", vim.fn.getreg("/") == "hello", vim.fn.getreg("/"))

  -- ...but not in markdown, where two trailing spaces are a hard line break
  T.write("ws/notes.md", { "first line  ", "second line" })
  local mbuf = T.open("ws/notes.md")
  vim.cmd("silent write")
  check("whitespace: markdown keeps trailing spaces", T.lines(mbuf)[1] == "first line  ", vim.inspect(T.lines(mbuf)))

  -- ...and a project's .editorconfig decides when it sets trim_trailing_whitespace
  T.write("ws_ec/.editorconfig", { "root = true", "", "[*]", "trim_trailing_whitespace = false" })
  T.write("ws_ec/keep.txt", { "x   ", "y" })
  local ebuf = T.open("ws_ec/keep.txt")
  vim.cmd("silent write")
  check("whitespace: .editorconfig trim_trailing_whitespace = false is respected",
    T.lines(ebuf)[1] == "x   ", vim.inspect(T.lines(ebuf)))

  vim.cmd("enew | setfiletype gitcommit")
  check("gitcommit: :AiCommit is buffer-local", vim.api.nvim_buf_get_commands(0, {}).AiCommit ~= nil
    and vim.api.nvim_get_commands({}).AiCommit == nil)
end
