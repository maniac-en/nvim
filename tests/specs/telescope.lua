-- tests/specs/telescope.lua
-- File ignore patterns: LSP pickers unfiltered, file pickers hide only junk.
return function(T)
  local check, await = T.check, T.await

  -- LSP pickers must not be filtered by file ignore patterns: a definition in a
  -- path like .../golang.org/... used to be dropped by an unanchored "%.o"
  check("no global file_ignore_patterns (LSP pickers unfiltered)",
    vim.tbl_isempty(require("telescope.config").values.file_ignore_patterns or {}),
    vim.inspect(require("telescope.config").values.file_ignore_patterns))

  -- gd (telescope lsp_definitions) into a dependency under a golang.org/ path; offline via replace
  T.write("tele_go/deps/golang.org/dep/go.mod", { "module example.org/dep", "", "go 1.22" })
  T.write("tele_go/deps/golang.org/dep/dep.go", { "package dep", "", "func Hello() string { return \"hi\" }" })
  T.write("tele_go/go.mod", { "module example.com/tele", "", "go 1.22", "",
    "require example.org/dep v0.0.0", "", "replace example.org/dep => ./deps/golang.org/dep" })
  T.write("tele_go/main.go",
    { "package main", "", 'import "example.org/dep"', "", "func main() {", "\t_ = dep.Hello()", "}" })
  local gbuf = T.open("tele_go/main.go")
  T.wait_client(gbuf, "gopls")
  await(function() return false end, 2500)
  vim.api.nvim_win_set_cursor(0, { 6, 9 }) -- on Hello
  T.run_keys("gd")
  local target = T.root .. "/tele_go/deps/golang.org/dep/dep.go"
  check("gd reaches a definition under a golang.org/ path",
    await(function() return vim.api.nvim_buf_get_name(0) == target end, 10000), vim.api.nvim_buf_get_name(0))

  -- <leader>sf (hidden + no_ignore) lists real files, hides .git/, node_modules/ and binaries
  local shown_files = { "tele/internal/auth.api.go", "tele/cmd/server.app/main.go", "tele/pkg/target/x.go",
    "tele/scripts/rebuild/run.sh", "tele/notes/todo.org", "tele/config.old.yaml", "tele/app/.air.toml" }
  local hidden_files = { "tele/.git/HEAD", "tele/sub/.git/config", "tele/node_modules/x/index.js",
    "tele/web/node_modules/y/a.js", "tele/bin/app.o", "tele/lib/libfoo.a", "tele/report.pdf", "tele/.DS_Store" }
  for _, f in ipairs(vim.list_extend(vim.deepcopy(shown_files), hidden_files)) do T.write(f, { "x" }) end
  T.open("tele/config.old.yaml")
  T.run_keys("<leader>sf")
  local picker
  await(function()
    local ok, pk = pcall(require("telescope.actions.state").get_current_picker, vim.api.nvim_get_current_buf())
    picker = ok and pk or nil
    return picker ~= nil
  end)
  await(function() return false end, 1500) -- let the finder finish
  local listed = {}
  if picker then
    for entry in picker.manager:iter() do listed[entry.value] = true end
    require("telescope.actions").close(picker.prompt_bufnr)
  end
  local missing, leaked = {}, {}
  for _, f in ipairs(shown_files) do if not listed[f] then missing[#missing + 1] = f end end
  for _, f in ipairs(hidden_files) do if listed[f] then leaked[#leaked + 1] = f end end
  check("<leader>sf shows real files like auth.api.go, server.app/, target/, rebuild/",
    picker ~= nil and #missing == 0, "missing: " .. table.concat(missing, ", "))
  check("<leader>sf hides .git/, node_modules/ and binaries", picker ~= nil and #leaked == 0,
    "leaked: " .. table.concat(leaked, ", "))

  -- <C-f> (live grep) searches the whole project, dotfiles included, with paths
  -- relative to the project root even when Neovim's cwd is a subdirectory
  -- under proj/ (tele/ holds fake .git fixtures, which are repo roots of their own)
  T.write("proj/app/.air.toml", { "grep_needle_here" })
  T.write("proj/internal/x.go", { "package internal" })
  T.open("proj/internal/x.go") -- the root comes from the buffer's file, not Neovim's cwd
  vim.cmd.cd("proj/internal")
  T.run_keys("<C-f>")
  picker = nil
  await(function()
    local ok, pk = pcall(require("telescope.actions.state").get_current_picker, vim.api.nvim_get_current_buf())
    picker = ok and pk or nil
    return picker ~= nil
  end)
  local found = {}
  if picker then
    picker:set_prompt("grep_needle_here")
    await(function()
      found = {}
      for entry in picker.manager:iter() do found[#found + 1] = entry.filename end
      return #found > 0
    end, 5000)
    require("telescope.actions").close(picker.prompt_bufnr)
  end
  vim.cmd.cd(T.root)
  check("<C-f> finds text in dotfiles, paths relative to the project root",
    #found == 1 and found[1] == "proj/app/.air.toml",
    ("cwd=%s found=%s"):format(tostring(picker and picker.cwd), vim.inspect(found)))

  -- From an oil buffer (<C-p> is oil's preview there, so <C-f>): the project root
  -- comes from the browsed directory, not Neovim's cwd, and the oil:// buffer
  -- name doesn't send the root search into an endless loop
  vim.cmd.cd("/")
  vim.cmd("Oil " .. vim.fn.fnameescape(T.root .. "/proj/internal"))
  await(function() return vim.bo.filetype == "oil" end)
  T.run_keys("<C-f>")
  picker = nil
  await(function()
    local ok, pk = pcall(require("telescope.actions.state").get_current_picker, vim.api.nvim_get_current_buf())
    picker = ok and pk or nil
    return picker ~= nil
  end)
  local cwd = picker and picker.cwd
  if picker then require("telescope.actions").close(picker.prompt_bufnr) end
  vim.cmd.cd(T.root)
  check("<C-f> in oil searches the browsed project, not Neovim's cwd",
    cwd ~= nil and vim.fs.normalize(tostring(cwd)) == vim.fs.normalize(T.root), tostring(cwd))
end
