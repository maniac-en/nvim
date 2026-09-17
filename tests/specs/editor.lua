-- tests/specs/editor.lua
-- Quickfix/location lists, runner commands, swap names, whitespace on save, :AiCommit, winbar/statusline look, config paths.
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

  -- Indentation is guessed per file by vim-sleuth (sibling files for new/unindented
  -- ones); it beats ftplugin defaults, and modelines/.editorconfig beat it
  local function indent_of(path, lines)
    if lines then T.write(path, lines) end
    local b = T.open(path)
    vim.wait(300)
    return { sw = vim.fn.shiftwidth(), et = vim.bo[b].expandtab, sts = vim.bo[b].softtabstop }
  end
  local two_js = { "function f() {", "  if (x) {", "    return 1;", "  }", "}" }
  local two = indent_of("indent/two.js", two_js)
  check("indent: 2-space file gets shiftwidth=2 (spaces)", two.sw == 2 and two.et, vim.inspect(two))
  local tabs = indent_of("indent/tabs.c", { "int main() {", "\tif (1) {", "\t\treturn 0;", "\t}", "}" })
  check("indent: tab-indented file gets noexpandtab", tabs.et == false, vim.inspect(tabs))
  local py = indent_of("indent/two.py", { "def f():", "  if x:", "    return 1" })
  check("indent: 2-space Python stays 2 (beats the ftplugin's 4)", py.sw == 2 and py.et, vim.inspect(py))
  local ml = indent_of("indent/modeline.js", vim.list_extend(vim.deepcopy(two_js), { "// vim: set sw=6 et:" }))
  check("indent: modeline wins, softtabstop follows shiftwidth", ml.sw == 6 and ml.sts == -1, vim.inspect(ml))
  for _, n in ipairs({ "a", "b", "c" }) do T.write("neighbors/" .. n .. ".js", two_js) end
  local new_file = indent_of("neighbors/new.js")
  check("indent: new file takes 2-space style from sibling files", new_file.sw == 2 and new_file.et,
    vim.inspect(new_file))
  local flat = indent_of("neighbors/flat.js", { "const a = 1;", "const b = 2;" })
  check("indent: unindented file takes style from sibling files", flat.sw == 2 and flat.et, vim.inspect(flat))
  T.write("indent_ec/.editorconfig", { "root = true", "", "[*]", "indent_style = space", "indent_size = 8" })
  local ec = indent_of("indent_ec/two.js", { "function f() {", "  return 1;", "}" })
  check("indent: .editorconfig indent_size wins over guessing", ec.sw == 8 and ec.et, vim.inspect(ec))

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

  -- Winbar (used as the statusline) is bold, in the editor's colors, in every window
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  for _, group in ipairs({ "WinBar", "WinBarNC" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    check(group .. " is bold with the editor's colors", hl.bold == true and hl.fg == normal.fg and hl.bg == normal.bg,
      vim.inspect(hl))
  end
  -- Statusline (only the separator row between stacked windows) blends into the editor
  for _, group in ipairs({ "StatusLine", "StatusLineNC" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    check(group .. " is hidden in the editor background", hl.bg == normal.bg, vim.inspect(hl))
  end
  -- ...and has no text (e.g. the file name) that a transparent background would reveal
  T.write("notes.txt", { "hello" })
  T.open("notes.txt")
  vim.cmd("split | redraw!")
  local top = vim.fn.win_getid(1) -- the upper window (splitbelow puts the new one below)
  local row = vim.fn.win_screenpos(top)[1] + vim.api.nvim_win_get_height(top)
  local text = {}
  for col = 1, vim.o.columns do text[#text + 1] = vim.fn.screenstring(row, col) end
  text = table.concat(text)
  check("separator row between stacked windows is empty", vim.trim(text) == "", ("row %d: %q"):format(row, text))
  vim.cmd("only")

  -- Config paths come from stdpath("config"), not a hard-coded ~/.config/nvim
  local config = vim.fn.stdpath("config")
  check("spellfile lives in the config dir", vim.o.spellfile == config .. "/spell/en.utf-8.add", vim.o.spellfile)
  local tabs = #vim.api.nvim_list_tabpages()
  T.run_keys("<leader>ev")
  local ev = T.await(function() return vim.bo.filetype == "oil" end)
  local dir = ev and require("oil").get_current_dir() or vim.api.nvim_buf_get_name(0)
  check("<leader>ev opens the config dir in a new tab",
    ev and #vim.api.nvim_list_tabpages() == tabs + 1 and vim.fs.normalize(dir) == vim.fs.normalize(config),
    ("filetype=%s dir=%s tabs=%d"):format(vim.bo.filetype, dir, #vim.api.nvim_list_tabpages()))
  vim.cmd("silent! tabonly")
end
