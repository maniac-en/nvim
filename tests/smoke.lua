-- tests/smoke.lua
-- Headless smoke test for this config: startup, LSP, format-on-save, linting,
-- keymaps. Checks behavior, not exact formatter output. Needs the Mason tools
-- (and go, git) installed. Takes ~30-60s.
--
-- Run: tests/run.sh   (or directly:)
--   nvim --headless -i NONE -c 'lua dofile(vim.fn.stdpath("config") .. "/tests/smoke.lua")'
-- Exit code is 0 when every check passes, 1 otherwise.

-- Don't leave undo files for the throwaway sample files
vim.o.undofile = false
-- Keep "-- INSERT --" and similar mode text out of the output
vim.o.showmode = false

-- Results are printed as each check runs; a summary follows at the end
local function print_line(line)
  io.stdout:write(line .. "\n")
  io.stdout:flush()
end
local results = {}
local function check(name, ok, detail)
  ok = ok and true or false
  results[#results + 1] = { name = name, ok = ok }
  print_line(("%s  %s"):format(ok and "PASS" or "FAIL", name))
  if not ok and detail then
    print_line("      " .. tostring(detail):gsub("\n", "\n      "))
  end
end

-- Sections are registered here and run in order inside a coroutine at the end,
-- so checks that type keys can wait without blocking Neovim's main loop.
-- An error inside a section counts as a failed check.
local sections = {}
local function section(name, fn)
  sections[#sections + 1] = { name = name, fn = fn }
end

-- Wait for cond() without blocking the main loop (queued keys get processed).
-- Only usable inside a section. Returns whether cond() became true.
local function await(cond, timeout)
  local co = assert(coroutine.running(), "await() must run inside a section")
  local start = vim.uv.now()
  local function tick()
    local ok = cond()
    if ok or vim.uv.now() - start > (timeout or 5000) then
      coroutine.resume(co, ok and true or false)
    else
      vim.defer_fn(tick, 30)
    end
  end
  vim.defer_fn(tick, 0)
  return coroutine.yield()
end
-- Queue keys as if typed (processed by the main loop during await)
local function keys(k) vim.api.nvim_feedkeys(vim.keycode(k), "t", false) end

local root = vim.fn.tempname()
local function write(path, lines)
  local full = root .. "/" .. path
  vim.fn.mkdir(vim.fs.dirname(full), "p")
  vim.fn.writefile(lines, full)
  return full
end

local function open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end
local function lines(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end
local function text(buf) return table.concat(lines(buf), "\n") end
local function client_names(buf)
  return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = buf }))
end
local function wait_client(buf, name, timeout)
  return vim.wait(timeout or 20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = name }) > 0
  end, 100)
end
local function wait_formatter(buf, timeout)
  return vim.wait(timeout or 10000, function()
    return #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0
  end, 100)
end
local function diag_sources(buf)
  local seen = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do seen[d.source or "?"] = true end
  return seen
end
local function has_buf_map(buf, mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true).buffer == 1 and vim.api.nvim_get_current_buf() == buf
end

-- Count vim.lsp.buf.format calls (format-on-save should call it once per save)
local format_calls = 0
local real_format = vim.lsp.buf.format
vim.lsp.buf.format = function(...)
  format_calls = format_calls + 1
  return real_format(...)
end

local startup_messages = vim.trim(vim.fn.execute("messages"))

-- One git repo for all sample files, used as the working directory like a real
-- project (workspace-diagnostics lists files via `git ls-files` from the cwd,
-- once per session, at the first LSP attach)
vim.fn.mkdir(root, "p")
vim.system({ "git", "init", "-q", root }):wait()
write("py/scripts/other.py", { "x = 1" })
vim.system({ "git", "add", "-A" }, { cwd = root }):wait()
vim.cmd.cd(vim.fn.fnameescape(root))

----------------------------------------------------------------------------
section("startup", function()
  check("startup: no messages/errors in this session", startup_messages == "", startup_messages)

  local res = vim.system({ "nvim", "--headless", "-i", "NONE", "+qa" }):wait()
  check("startup: clean nested start (no stderr)", res.code == 0 and vim.trim(res.stderr or "") == "", res.stderr)

  local times = {}
  for i = 1, 3 do
    local log = vim.fn.tempname()
    vim.system({ "nvim", "--headless", "-i", "NONE", "--startuptime", log, "+qa" }):wait()
    for _, line in ipairs(vim.fn.readfile(log)) do
      if line:find("NVIM STARTED", 1, true) then times[i] = tonumber(line:match("^(%d+%.%d+)")) end
    end
    times[i] = times[i] or -1
    vim.fn.delete(log)
  end
  table.sort(times)
  check(("startup: median %.1fms (informational)"):format(times[2]), true)
end)

----------------------------------------------------------------------------
section("go", function()
  vim.fn.mkdir(root .. "/go", "p")
  vim.system({ "go", "mod", "init", "example.com/smoke" }, { cwd = root .. "/go" }):wait()
  write("go/main.go", {
    "package main",
    "",
    "func main() {",
    '  os.Remove("a")', -- missing import + bad indent + unchecked error
    '\tfmt.Println("hi")',
    "}",
  })
  local buf = open("go/main.go")
  check("go: gopls attaches", wait_client(buf, "gopls"), vim.inspect(client_names(buf)))

  format_calls = 0
  vim.cmd("silent write")
  local src = text(buf)
  check("go: save adds missing imports", src:find('"fmt"', 1, true) and src:find('"os"', 1, true), src)
  check("go: save formats (gofumpt indent)", src:find('\n\tos.Remove', 1, true) ~= nil, src)
  check("go: formatted exactly once per save", format_calls == 1, "format calls: " .. format_calls)

  local got_errcheck = vim.wait(60000, function() return diag_sources(buf).errcheck end, 250)
  check("go: golangci-lint reports issues after save", got_errcheck, vim.inspect(diag_sources(buf)))

  -- Compile error: gopls reports it; golangci-lint's "typecheck" copy is filtered
  local l = lines(buf)
  table.insert(l, #l, "\tx := 1")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, l)
  vim.cmd("silent write")
  vim.wait(60000, function() return diag_sources(buf).compiler end, 250)
  vim.wait(5000, function() return #require("lint").get_running(buf) == 0 end, 100)
  vim.wait(1000)
  local sources = diag_sources(buf)
  check("go: gopls reports compile error", sources.compiler, vim.inspect(sources))
  check("go: golangci-lint typecheck duplicates filtered", not sources.typecheck, vim.inspect(sources))

  for _, lhs in ipairs({ "<leader>r", "<leader>t", "<leader>dt", "gd", "K" }) do
    check("go: buffer keymap " .. lhs, has_buf_map(buf, "n", lhs))
  end
  check("go: makeprg", vim.bo[buf].makeprg == "go build", vim.bo[buf].makeprg)
end)

----------------------------------------------------------------------------
section("python", function()
  write("py/t.py", {
    "import sys",
    "import os",
    "import json",
    "",
    "def f( a ):",
    '    x: int = "not an int"', -- type error: basedpyright diagnostics must stay silent
    '    return os.path.join(a,json.dumps(x))',
  })
  local buf = open("py/t.py")
  check("python: basedpyright attaches", wait_client(buf, "basedpyright"), vim.inspect(client_names(buf)))
  check("python: ruff attaches", wait_client(buf, "ruff"), vim.inspect(client_names(buf)))
  check("python: ruff provides formatting", wait_formatter(buf))

  vim.wait(20000, function() return diag_sources(buf).Ruff end, 200)
  vim.wait(2000)
  local sources = diag_sources(buf)
  check("python: ruff diagnostics (unused import)", sources.Ruff, vim.inspect(sources))
  check("python: basedpyright diagnostics silenced", not sources.basedpyright, vim.inspect(sources))

  vim.api.nvim_win_set_cursor(0, { 7, 12 }) -- on `os`
  local hovers = vim.lsp.buf_request_sync(buf, "textDocument/hover",
    vim.lsp.util.make_position_params(0, "utf-16"), 10000) or {}
  local hover_from = {}
  for id, r in pairs(hovers) do
    if r.result then hover_from[#hover_from + 1] = vim.lsp.get_client_by_id(id).name end
  end
  check("python: hover only from basedpyright", #hover_from == 1 and hover_from[1] == "basedpyright",
    vim.inspect(hover_from))

  format_calls = 0
  vim.cmd("silent write")
  local l = lines(buf)
  check("python: save sorts imports", l[1] == "import json" and l[2] == "import os" and l[3] == "import sys",
    text(buf))
  check("python: save formats", vim.tbl_contains(l, "def f(a):"), text(buf))
  check("python: formatted exactly once per save", format_calls == 1, "format calls: " .. format_calls)

  for _, lhs in ipairs({ "<leader>r", "gd", "K" }) do
    check("python: buffer keymap " .. lhs, has_buf_map(buf, "n", lhs))
  end

  -- Opening another git-tracked project file must not warn about a redundant
  -- didOpen (workspace-diagnostics pre-opens tracked files)
  local before = vim.fn.execute("messages")
  local other = open("py/scripts/other.py")
  wait_client(other, "basedpyright")
  vim.wait(3000)
  local new_msgs = vim.fn.execute("messages"):sub(#before + 1)
  check("python: no 'redundant open text document' warning",
    not new_msgs:find("redundant open text document", 1, true), new_msgs)
end)

----------------------------------------------------------------------------
section("other languages", function()
  -- format: true = must change on save, false = must stay untouched, nil = not checked
  local cases = {
    { file = "t.c",    server = "clangd", content = { "int main(){return 0;}" } },
    { file = "t.ts",   server = "ts_ls",  content = { "let x: number = 1;" } },
    { file = "t.js",   server = "ts_ls",  content = { "const a = 1;", "a = 2;" },                     linter = "quick-lint-js" },
    { file = "t.json", server = "jsonls", content = { '{"a":1,', '"b":[1,2]}' },                      format = true },
    { file = "t.css",  server = "cssls",  content = { "p{color:red;margin:0}" },                      format = true },
    { file = "t.html", server = "html",   content = { "<div><p>hi</p>", "      <p>there</p></div>" }, format = false },
    { file = "t.sh",   server = "bashls", content = { "echo hi" } },
    { file = "t.lua",  server = "lua_ls", content = { "local x = 1" } },
  }
  for _, case in ipairs(cases) do
    write("misc/" .. case.file, case.content)
    local buf = open("misc/" .. case.file)
    check(("%s: %s attaches"):format(case.file, case.server), wait_client(buf, case.server),
      vim.inspect(client_names(buf)))
    if case.linter then
      local got = vim.wait(10000, function() return diag_sources(buf)[case.linter] end, 100)
      check(("%s: %s reports"):format(case.file, case.linter), got, vim.inspect(diag_sources(buf)))
    end
    if case.format ~= nil then
      if case.format then wait_formatter(buf) else vim.wait(2000) end
      local before = text(buf)
      vim.cmd("silent write")
      local changed = text(buf) ~= before
      check(("%s: %s on save"):format(case.file, case.format and "formatted" or "not formatted"),
        changed == case.format, text(buf))
    end
  end
end)

----------------------------------------------------------------------------
section("completion", function()
  check("completion: nvim-cmp is gone", package.loaded.cmp == nil and not pcall(require, "cmp"))

  write("go/comp.go", { "package main", "", "func helper() {", "\t", "}" })
  local buf = open("go/comp.go")
  wait_client(buf, "gopls")
  await(function() return false end, 1500) -- let gopls load the package

  local blink = require("blink.cmp")
  check("completion: Rust fuzzy matcher active", require("blink.cmp.fuzzy").implementation_type == "rust",
    require("blink.cmp.fuzzy").implementation_type)
  local gopls = vim.lsp.get_clients({ bufnr = buf, name = "gopls" })[1]
  check("completion: LSP clients get blink.cmp capabilities", gopls and vim.deep_equal(
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
  check("completion: menu shows LSP items while typing", shown,
    vim.inspect(vim.tbl_map(function(i) return i.label end, vim.list_slice(blink.get_items() or {}, 1, 5))))
  keys("<C-y>")
  local accepted = await(function() return vim.api.nvim_get_current_line():find("fmt%.Print%w*%(") ~= nil end)
  check("completion: <C-y> accepts an item", accepted, vim.api.nvim_get_current_line())
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)

  -- No completion inside comments
  vim.api.nvim_buf_set_lines(buf, 3, 4, false, { "\t// fmt.Prin" })
  vim.api.nvim_win_set_cursor(0, { 4, 11 })
  keys("a")
  await(function() return vim.fn.mode() == "i" end)
  keys("t")
  check("completion: no menu inside comments", not await(function() return blink.is_menu_visible() end, 2000))
  keys("<Esc>")
  await(function() return vim.fn.mode() == "n" end)
  vim.cmd("silent! bwipeout!")

  -- Filetype-specific sources
  local providers = function() return vim.tbl_keys(require("blink.cmp.sources.lib").get_enabled_providers("default")) end
  write("misc/t.sql", { "select 1;" })
  open("misc/t.sql")
  check("completion: SQL uses dadbod source", vim.tbl_contains(providers(), "dadbod"), vim.inspect(providers()))
  open("misc/t.lua")
  check("completion: Lua uses lazydev source", vim.tbl_contains(providers(), "lazydev"), vim.inspect(providers()))

  -- Command-line menu shows automatically (after 4 characters)
  keys(":checkhea")
  local cmd_menu = await(function() return vim.fn.mode() == "c" and blink.is_menu_visible() end)
  keys("<C-c>")
  await(function() return vim.fn.mode() == "n" end)
  io.stdout:write("\n") -- headless Neovim echoes the typed command line to stdout
  check("completion: cmdline menu shows while typing", cmd_menu)
end)

----------------------------------------------------------------------------
section("editor", function()
  for _, cmd in ipairs({ "RunGo", "RunPython", "RunC", "RunJavascript", "RunTypescript", "RunLua" }) do
    check("command :" .. cmd, vim.fn.exists(":" .. cmd) == 2)
  end

  -- Trailing whitespace is stripped on save without moving the cursor or the search
  write("ws/t.txt", { "x   ", "hello" })
  local buf = open("ws/t.txt")
  vim.fn.setreg("/", "hello")
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  vim.cmd("silent write")
  check("whitespace: stripped on save", lines(buf)[1] == "x", vim.inspect(lines(buf)))
  check("whitespace: cursor kept", vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 3 }))
  check("whitespace: search pattern kept", vim.fn.getreg("/") == "hello", vim.fn.getreg("/"))

  vim.cmd("enew | setfiletype gitcommit")
  check("gitcommit: :AiCommit is buffer-local", vim.api.nvim_buf_get_commands(0, {}).AiCommit ~= nil
    and vim.api.nvim_get_commands({}).AiCommit == nil)
end)

----------------------------------------------------------------------------
section("health", function()
  vim.cmd("silent checkhealth vim.deprecated")
  local report = text(0)
  check("health: no deprecated functions", report:find("No deprecated functions detected", 1, true) ~= nil, report)
  vim.cmd("bwipeout!")

  local msgs = vim.trim(vim.fn.execute("messages"))
  check("messages: empty after all checks", msgs == "", msgs)
end)

----------------------------------------------------------------------------
local finished = false
local function finish()
  if finished then return end
  finished = true
  vim.lsp.buf.format = real_format
  vim.cmd.cd("/")
  vim.fn.delete(root, "rf")

  local failed = vim.tbl_filter(function(r) return not r.ok end, results)
  print_line(("\n%d checks, %d failed"):format(#results, #failed))
  for _, r in ipairs(failed) do
    print_line("  FAIL  " .. r.name)
  end
  vim.cmd(#failed == 0 and "qa!" or "cquit! 1")
end

-- Never hang silently: report what ran so far and fail
local limit_minutes = 4
vim.defer_fn(function()
  check(("finished within %d minutes"):format(limit_minutes), false, "timed out; results above are partial")
  finish()
end, limit_minutes * 60 * 1000)

coroutine.wrap(function()
  for _, sec in ipairs(sections) do
    print_line("\n== " .. sec.name)
    local ok, err = xpcall(sec.fn, debug.traceback)
    if not ok then check(sec.name .. ": no errors", false, err) end
  end
  finish()
end)()
