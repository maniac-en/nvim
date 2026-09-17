-- tests/lib.lua
-- Harness for the smoke-test specs in tests/specs/. tests/run.sh starts one
-- headless Neovim per spec and calls T.run(<spec file>). Each spec is a file
-- returning `function(T) ... end`; it runs in its own temporary git repo (the
-- working directory) and ends with shared health checks (no unexpected
-- deprecations, no stray messages).
--
-- Output protocol, parsed by run.sh (anything else on stdout is headless noise):
--   @@PASS <name>    @@FAIL <name>    @@DETAIL <text>    @@END <checks> <failed>

local T = {}

local function emit(line)
  -- leading newline: headless Neovim may have echoed text without one
  io.stdout:write("\n" .. line .. "\n")
  io.stdout:flush()
end

T.results = {}
function T.check(name, ok, detail)
  ok = ok and true or false
  T.results[#T.results + 1] = { name = name, ok = ok }
  emit((ok and "@@PASS " or "@@FAIL ") .. name)
  if not ok and detail then
    for line in (tostring(detail) .. "\n"):gmatch("(.-)\n") do
      emit("@@DETAIL " .. line)
    end
  end
end

-- Wait for cond() without blocking the main loop, so queued keys get processed.
-- Returns whether cond() became true within timeout (ms).
function T.await(cond, timeout)
  local co = assert(coroutine.running(), "T.await() must run inside a spec")
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

-- Queue keys as if typed (processed by the main loop during T.await)
function T.keys(k) vim.api.nvim_feedkeys(vim.keycode(k), "t", false) end

-- Execute keys (mappings included) immediately
function T.run_keys(k) vim.api.nvim_feedkeys(vim.keycode(k), "mx", false) end

function T.write(path, lines)
  local full = T.root .. "/" .. path
  vim.fn.mkdir(vim.fs.dirname(full), "p")
  vim.fn.writefile(lines, full)
  return full
end

function T.open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(T.root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end

function T.lines(buf) return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end

function T.text(buf) return table.concat(T.lines(buf), "\n") end

-- `go mod init` in a subdirectory of the spec's repo (gopls wants a module)
function T.go_module(dir, module)
  vim.fn.mkdir(T.root .. "/" .. dir, "p")
  vim.system({ "go", "mod", "init", module or "example.com/smoke" }, { cwd = T.root .. "/" .. dir }):wait(30000)
end

-- Stage all files (workspace-diagnostics lists tracked files, once per session)
function T.git_add_all() vim.system({ "git", "add", "-A" }, { cwd = T.root }):wait(30000) end

function T.client_names(buf)
  return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = buf }))
end

function T.wait_client(buf, name, timeout)
  return vim.wait(timeout or 20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = name }) > 0
  end, 100)
end

function T.wait_formatter(buf, timeout)
  return vim.wait(timeout or 10000, function()
    return #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0
  end, 100)
end

function T.diag_sources(buf)
  local seen = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do seen[d.source or "?"] = true end
  return seen
end

function T.has_buf_map(buf, mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true).buffer == 1 and vim.api.nvim_get_current_buf() == buf
end

function T.plugin_loaded(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin ~= nil and plugin._.loaded ~= nil
end

-- Deprecation warnings from third-party plugins we've decided to live with for
-- now (shown as a passing note). Matched against the warning's stack trace.
-- Anything else fails the health check.
local known_deprecations = {
  { stack = "/rest.nvim/",       note = "rest.nvim vim.validate{} (parked: fork rest.nvim)" },
  { stack = "/toggleterm.nvim/", note = "toggleterm vim.validate{} (tolerated)" },
}

local function health()
  vim.cmd("silent checkhealth vim.deprecated")
  local report = T.text(0)
  vim.cmd("bwipeout!")
  if report:find("No deprecated functions detected", 1, true) then
    T.check("health: no deprecated functions", true)
  else
    -- one chunk per warning, each followed by its stack trace
    local unknown = {}
    for warning in (report .. "\n- "):gmatch("WARNING(.-)\n%- ") do
      local known
      for _, k in ipairs(known_deprecations) do
        if warning:find(k.stack, 1, true) then known = k end
      end
      if known then
        T.check("health: known deprecation tolerated: " .. known.note, true)
      else
        unknown[#unknown + 1] = "WARNING" .. warning
      end
    end
    T.check("health: no unexpected deprecated functions", #unknown == 0, table.concat(unknown, "\n"))
  end

  local msgs = vim.trim(vim.fn.execute("messages"))
  T.check("messages: empty after all checks", msgs == "", msgs)
end

local finished = false
local function finish()
  if finished then return end
  finished = true
  vim.cmd.cd("/")
  vim.fn.delete(T.root, "rf")
  local failed = #vim.tbl_filter(function(r) return not r.ok end, T.results)
  emit(("@@END %d %d"):format(#T.results, failed))
  vim.cmd(failed == 0 and "qa!" or "cquit! 1")
end

function T.run(spec_path)
  T.startup_messages = vim.trim(vim.fn.execute("messages"))

  -- Don't leave undo files for throwaway sample files; keep mode text and
  -- "N lines yanked" out of the output
  vim.o.undofile = false
  vim.o.showmode = false
  vim.o.report = 9999

  -- Count vim.lsp.buf.format calls (format-on-save should call it once per save)
  T.formats = 0
  local real_format = vim.lsp.buf.format
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.format = function(...)
    T.formats = T.formats + 1
    return real_format(...)
  end

  -- Headless Neovim has no UI, so lazy.nvim's VeryLazy event (fired after the
  -- first redraw) never happens; fire it so VeryLazy plugins load as they would
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })

  -- The spec's own git repo, used as the working directory like a real project
  T.root = vim.fn.tempname()
  vim.fn.mkdir(T.root, "p")
  vim.system({ "git", "init", "-q", T.root }):wait(30000)
  vim.cmd.cd(vim.fn.fnameescape(T.root))

  -- Never hang silently: report what ran so far and fail. A plain libuv timer,
  -- not vim.defer_fn: scheduled callbacks don't run while Neovim waits inside a
  -- command (e.g. an unmapped <C-\> waiting for its second key), timer callbacks
  -- do. That context can't use Neovim's API, so it only writes the result and
  -- exits (the spec's temporary repo is left behind).
  local limit_minutes = 4
  vim.uv.new_timer():start(limit_minutes * 60 * 1000, 0, function()
    local failed = #vim.tbl_filter(function(r) return not r.ok end, T.results) + 1
    emit(("@@FAIL finished within %d minutes"):format(limit_minutes))
    emit("@@DETAIL timed out; results above are partial")
    emit(("@@END %d %d"):format(#T.results + 1, failed))
    os.exit(1)
  end)

  coroutine.wrap(function()
    local ok, err = xpcall(function() dofile(spec_path)(T) end, debug.traceback)
    if not ok then T.check("spec ran without errors", false, err) end
    vim.lsp.buf.format = real_format
    local hok, herr = xpcall(health, debug.traceback)
    if not hok then T.check("health checks ran without errors", false, herr) end
    finish()
  end)()
end

return T
