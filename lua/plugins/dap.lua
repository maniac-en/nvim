-- lua/plugins/dap.lua
-- Debugging: nvim-dap (client), nvim-dap-ui (panels), debugpy for Python and
-- Delve for Go (both installed with Mason). Stepping is on F5/F10/F11/F12,
-- everything else under <leader>d. Nothing loads until one of those keys is used.
local key = require("config.map").lazy

local function dap() return require("dap") end

local function debug_key(lhs, rhs, text, opts)
  return key(lhs, rhs, "Debug", text, vim.tbl_extend("force", { silent = true }, opts or {}))
end

-- Python test runs offered by <leader>dt, default first. pytest also runs
-- unittest.TestCase classes; unittest is for projects without pytest. "Library
-- code too" turns off debugpy's justMyCode (Delve has no such switch: it already
-- steps into libraries, so Go starts right away)
local python_test_runs = {
  { label = "pytest", runner = "pytest" },
  { label = "unittest", runner = "unittest" },
  { label = "pytest (library code too)", runner = "pytest", all_code = true },
  { label = "unittest (library code too)", runner = "unittest", all_code = true },
}

-- Debug the test under the cursor: the Go test function, or the Python test
-- (after picking how to run it)
local function debug_test()
  if vim.bo.filetype == "go" then
    require("dap-go").debug_test()
  elseif vim.bo.filetype == "python" then
    vim.ui.select(python_test_runs, {
      prompt = "Debug the test with",
      format_item = function(run) return run.label end,
    }, function(run)
      if not run then return end
      require("dap-python").test_method({
        test_runner = run.runner,
        config = run.all_code and { justMyCode = false } or nil,
      })
    end)
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- required by nvim-dap-ui
      -- lazy = true: its rockspec would otherwise make lazy.nvim load it at startup
      { "mfussenegger/nvim-dap-python", lazy = true },
      "leoluz/nvim-dap-go",
    },
    keys = {
      debug_key("<F5>", function() dap().continue() end, "start / continue"),
      debug_key("<F10>", function() dap().step_over() end, "step over"),
      debug_key("<F11>", function() dap().step_into() end, "step into"),
      debug_key("<F12>", function() dap().step_out() end, "step out"),
      debug_key("<leader>db", function() dap().toggle_breakpoint() end, "toggle [B]reakpoint"),
      debug_key("<leader>dB", function() dap().set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        "conditional [B]reakpoint"),
      debug_key("<leader>dc", function() dap().run_to_cursor() end, "run to [C]ursor"),
      debug_key("<leader>dl", function() dap().run_last() end, "re-run the [L]ast session"),
      debug_key("<leader>dq", function() dap().terminate() end, "[Q]uit the session"),
      debug_key("<leader>du", function() require("dapui").toggle() end, "toggle the debug [U]I"),
      debug_key("<leader>de", function() require("dapui").eval() end, "[E]valuate expression under cursor",
        { mode = { "n", "x" } }),
      debug_key("<leader>dt", debug_test, "debug the [T]est under the cursor (Python: pick the runner)",
        { ft = { "python", "go" } }),
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup()

      -- Python: debugpy from Mason's own virtualenv; the program itself runs with
      -- the project's Python ($VIRTUAL_ENV, else .venv/venv in the project)
      require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
      -- A twin of each launch configuration that steps into library code too
      -- (picked from the list F5 shows)
      local python = dap().configurations.python
      for _, config in ipairs(vim.deepcopy(python)) do
        if config.request == "launch" then
          table.insert(python, vim.tbl_extend("force", config, {
            name = config.name .. " (library code too)",
            justMyCode = false,
          }))
        end
      end
      -- Go: Delve (dlv, from Mason)
      require("dap-go").setup()

      -- The UI opens when a session starts and closes when it ends
      local listeners = dap().listeners
      listeners.before.attach.dapui = function() dapui.open() end
      listeners.before.launch.dapui = function() dapui.open() end
      listeners.before.event_terminated.dapui = function() dapui.close() end
      listeners.before.event_exited.dapui = function() dapui.close() end

      -- Signs; colors come from catppuccin's dap integration
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "○", texthl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "✗", texthl = "DapBreakpointRejected" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "CursorLine" })
    end,
  },
}
