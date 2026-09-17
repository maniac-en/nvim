-- tests/specs/treesitter.lua
-- nvim-treesitter main, textobjects, node selection, commenting, hover code
-- blocks, http request textobjects.
return function(T)
  local check, await = T.check, T.await

  check("nvim-treesitter is on the main branch",
    type(require("nvim-treesitter").install) == "function" and not pcall(require, "nvim-treesitter.configs"))
  check("exactly one go parser on runtimepath (no stale parsers)",
    #vim.api.nvim_get_runtime_file("parser/go.so", true) == 1,
    vim.inspect(vim.api.nvim_get_runtime_file("parser/go.so", true)))

  T.go_module("go")
  T.write("go/ts.go", {
    "package main",
    "",
    'import "fmt"',
    "",
    "func helper(a int, b string) {",
    "\tif a > 0 {",
    "\t\tfmt.Println(b)",
    "\t}",
    "}",
    "",
    "func caller() {",
    '\thelper(1, "x")',
    "}",
  })
  local buf = T.open("go/ts.go")
  check("highlighting active in Go", vim.treesitter.highlighter.active[buf] ~= nil)
  check("indentexpr set in Go", vim.bo[buf].indentexpr:find("nvim%-treesitter") ~= nil, vim.bo[buf].indentexpr)

  local function yank_after(k, row, col)
    vim.api.nvim_win_set_cursor(0, { row, col })
    T.run_keys(k .. "y")
    return vim.fn.getreg('"')
  end
  local got = yank_after("vam", 7, 3)
  check("textobjects: vam selects the function", got:match("^func helper") and got:match("}$"), got)
  got = yank_after("via", 12, 8)
  check("textobjects: via selects an argument", got == "1", got)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  T.run_keys("]f")
  local after_move = vim.api.nvim_win_get_cursor(0)[1]
  T.run_keys(";")
  check("textobjects: ]f moves to next function, ; repeats",
    after_move == 5 and vim.api.nvim_win_get_cursor(0)[1] == 11, vim.inspect(vim.api.nvim_win_get_cursor(0)))
  vim.api.nvim_win_set_cursor(0, { 12, 8 })
  T.run_keys("<leader>sa")
  check("textobjects: <leader>sa swaps arguments",
    vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1] == '\thelper("x", 1)',
    vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1])
  vim.cmd("silent undo")

  -- <C-space> selects the node under the cursor, grows to parents, <C-backspace> shrinks back
  got = yank_after("<C-space>", 7, 14)
  local grown = yank_after("<C-space><C-space><C-space>", 7, 14)
  local shrunk = yank_after("<C-space><C-space><C-space><C-backspace><C-backspace>", 7, 14)
  check("selection: <C-space> starts at node, grows, <C-backspace> shrinks back",
    got == "b" and grown:find("fmt.Println(b)", 1, true) and shrunk == "b",
    vim.inspect({ start = got, grown = grown, shrunk = shrunk }))

  vim.api.nvim_win_set_cursor(0, { 12, 1 })
  T.run_keys("gcc")
  check("comment: gcc comments the line", vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1] == '\t// helper(1, "x")',
    vim.api.nvim_buf_get_lines(buf, 11, 12, false)[1])
  vim.cmd("silent undo")

  -- K hover with a code block: its markdown injections must parse (the old
  -- master branch crashed here and turned highlighting off)
  T.wait_client(buf, "gopls")
  await(function() return false end, 1500)
  vim.api.nvim_win_set_cursor(0, { 7, 7 }) -- on Println
  vim.lsp.buf.hover()
  local float
  await(function()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(w).relative ~= "" and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "markdown" then
        float = w
        return true
      end
    end
  end, 10000)
  check("hover: K opens a markdown popup", float ~= nil)
  if float then
    local fbuf = vim.api.nvim_win_get_buf(float)
    local ok, err = pcall(function() vim.treesitter.get_parser(fbuf):parse(true) end)
    local langs = {}
    if ok then vim.treesitter.get_parser(fbuf):for_each_tree(function(_, t) langs[t:lang()] = true end) end
    check("hover: code blocks in the popup parse without errors", ok and langs.go, err or vim.inspect(langs))
    vim.api.nvim_win_close(float, true)
  end

  -- http requests as textobjects (queries/http/textobjects.scm)
  T.write("misc/t.http", {
    "### Get a user", "# @name getUser", "GET https://example.com/users/1", "Accept: application/json", "",
    "### Create a user", "POST https://example.com/users", "Content-Type: application/json", "", "{}", "",
  })
  T.open("misc/t.http")
  check("opening a .http file loads rest.nvim (:Rest available)",
    T.plugin_loaded("rest.nvim") and vim.fn.exists(":Rest") == 2)
  got = yank_after("vir", 4, 0)
  check("textobjects: vir selects the request (method line to body)",
    got:find("^GET https://example.com/users/1\nAccept") ~= nil and not got:find("###"), got)
  got = yank_after("var", 4, 0)
  check("textobjects: var selects the whole section (### title, comments, request)",
    got:find("^### Get a user\n# @name getUser\nGET ") ~= nil and not got:find("Create"), got)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  T.run_keys("]r")
  check("textobjects: ]r moves to the next request's ### title line", vim.api.nvim_win_get_cursor(0)[1] == 6,
    vim.inspect(vim.api.nvim_win_get_cursor(0)))
end
