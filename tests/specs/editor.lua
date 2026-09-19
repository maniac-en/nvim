-- tests/specs/editor.lua
-- Runner commands, swap names, trailing whitespace on save, cloak, :AiCommit, :W typos.
return function(T)
  local check = T.check

  -- :Run and <leader>r exist only in the filetypes that have a run command
  for _, case in ipairs({
    { file = "run/t.go", ft = "go" }, { file = "run/t.py", ft = "python" }, { file = "run/t.c", ft = "c" },
    { file = "run/t.js", ft = "javascript" }, { file = "run/t.ts", ft = "typescript" }, { file = "run/t.lua", ft = "lua" },
  }) do
    T.write(case.file, { "" })
    local buf = T.open(case.file)
    check((":Run and <leader>r in %s buffers"):format(case.ft),
      vim.api.nvim_buf_get_commands(buf, {}).Run ~= nil and T.has_buf_map(buf, "n", "<leader>r"),
      ("ft=%s"):format(vim.bo.filetype))
  end
  T.write("run/t.txt", { "" })
  local plain = T.open("run/t.txt")
  check(":Run is not defined in other buffers",
    vim.api.nvim_buf_get_commands(plain, {}).Run == nil and vim.api.nvim_get_commands({}).Run == nil)

  -- C: :Run builds into a temporary file and runs it, leaving the folder alone
  T.write("run_c/hello.c", { "#include <stdio.h>", "int main(void) { puts(\"hello from c\"); return 0; }" })
  T.write("run_c/out", { "not a binary" })
  T.open("run_c/hello.c")
  vim.cmd.lcd(T.root .. "/run_c")
  vim.cmd("Run")
  local term = vim.api.nvim_get_current_buf()
  local ran = T.await(function() return T.text(term):find("hello from c", 1, true) ~= nil end, 20000)
  local files = vim.fn.readdir(T.root .. "/run_c")
  check("C :Run builds and runs without touching the folder",
    ran and vim.deep_equal(files, { "hello.c", "out" }) and vim.fn.readfile(T.root .. "/run_c/out")[1] == "not a binary",
    ("output=%q files=%s"):format(T.text(term):sub(1, 200), vim.inspect(files)))
  vim.cmd("stopinsert | silent! only")
  vim.cmd.lcd(T.root)

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

  -- cloak.nvim hides .env values, and in shell scripts only exported values
  local function cloaked_lines(path, lines)
    T.write(path, lines)
    T.open(path)
    local ns = vim.api.nvim_create_namespace("cloak")
    vim.wait(1000, function() return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0 end, 20)
    return vim.tbl_map(function(m) return m[2] + 1 end, vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}))
  end
  local env = cloaked_lines("cloak/.env", { "API_KEY=sk-live-123", "DEBUG=true" })
  check("cloak: .env values hidden", vim.deep_equal(env, { 1, 2 }), vim.inspect(env))
  local sh = cloaked_lines("cloak/deploy.sh",
    { "export API_KEY=sk-live-123", "count=$((count+1))", "  export TOKEN=abc", 'name="world"', "# export in a comment" })
  check("cloak: .sh hides only exported values", vim.deep_equal(sh, { 1, 3 }), vim.inspect(sh))

  vim.cmd("enew | setfiletype gitcommit")
  check("gitcommit: :AiCommit is buffer-local", vim.api.nvim_buf_get_commands(0, {}).AiCommit ~= nil
    and vim.api.nvim_get_commands({}).AiCommit == nil)

  -- Shift-held typos: :W saves, but a W typed in a search stays a W
  T.write("typo/t.txt", { "Width W here" })
  local tbuf = T.open("typo/t.txt")
  vim.api.nvim_buf_set_lines(tbuf, 0, -1, false, { "changed" })
  T.run_keys(":W<CR>")
  check(":W saves the file", not vim.bo[tbuf].modified and vim.fn.readfile(T.root .. "/typo/t.txt")[1] == "changed")
  vim.api.nvim_buf_set_lines(tbuf, 0, -1, false, { "Width W here" })
  T.run_keys("gg0/W <CR>")
  check("a W typed in a search stays W", vim.fn.getreg("/") == "W ", vim.inspect(vim.fn.getreg("/")))
end
