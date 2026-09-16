-- tests/specs/python.lua
-- basedpyright + ruff: diagnostics, hover, sort imports + format on save.
return function(T)
  local check = T.check

  -- A tracked project file, staged before the first LSP attach: workspace-diagnostics
  -- pre-opens tracked files, which must not cause "redundant open" warnings later
  T.write("py/scripts/other.py", { "x = 1" })
  T.git_add_all()

  T.write("py/t.py", {
    "import sys",
    "import os",
    "import json",
    "",
    "def f( a ):",
    '    x: int = "not an int"', -- type error: basedpyright diagnostics must stay silent
    '    return os.path.join(a,json.dumps(x))',
  })
  local buf = T.open("py/t.py")
  check("basedpyright attaches", T.wait_client(buf, "basedpyright"), vim.inspect(T.client_names(buf)))
  check("ruff attaches", T.wait_client(buf, "ruff"), vim.inspect(T.client_names(buf)))
  check("ruff provides formatting", T.wait_formatter(buf))

  vim.wait(20000, function() return T.diag_sources(buf).Ruff end, 200)
  vim.wait(2000)
  local sources = T.diag_sources(buf)
  check("ruff diagnostics (unused import)", sources.Ruff, vim.inspect(sources))
  check("basedpyright diagnostics silenced", not sources.basedpyright, vim.inspect(sources))

  vim.api.nvim_win_set_cursor(0, { 7, 12 }) -- on `os`
  local hovers = vim.lsp.buf_request_sync(buf, "textDocument/hover",
    vim.lsp.util.make_position_params(0, "utf-16"), 10000) or {}
  local hover_from = {}
  for id, r in pairs(hovers) do
    if r.result then hover_from[#hover_from + 1] = vim.lsp.get_client_by_id(id).name end
  end
  check("hover only from basedpyright", #hover_from == 1 and hover_from[1] == "basedpyright",
    vim.inspect(hover_from))

  T.formats = 0
  vim.cmd("silent write")
  local l = T.lines(buf)
  check("save sorts imports", l[1] == "import json" and l[2] == "import os" and l[3] == "import sys", T.text(buf))
  check("save formats", vim.tbl_contains(l, "def f(a):"), T.text(buf))
  check("formatted exactly once per save", T.formats == 1, "format calls: " .. T.formats)

  for _, lhs in ipairs({ "<leader>r", "gd", "K" }) do
    check("buffer keymap " .. lhs, T.has_buf_map(buf, "n", lhs))
  end

  local before = vim.fn.execute("messages")
  local other = T.open("py/scripts/other.py")
  T.wait_client(other, "basedpyright")
  vim.wait(3000)
  local new_msgs = vim.fn.execute("messages"):sub(#before + 1)
  check("no 'redundant open text document' warning",
    not new_msgs:find("redundant open text document", 1, true), new_msgs)
end
