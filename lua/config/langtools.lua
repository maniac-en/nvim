-- lua/config/langtools.lua
-- Language-specific runners, test shortcuts and filetype settings

local group = vim.api.nvim_create_augroup("maniac_langtools", { clear = true })
local autocmd = function(pattern, callback)
  vim.api.nvim_create_autocmd("FileType", { group = group, pattern = pattern, callback = callback })
end

-- Helper function to create a runner for a specific language
local function create_runner(filetype, command, key, desc)
  local map_key = key or "<leader>r"
  local description = desc or string.format("[%s] %s run", map_key, filetype)

  -- Create a custom command for the filetype
  local cmd_name = string.format("Run%s", string.upper(string.sub(filetype, 1, 1)) .. string.sub(filetype, 2))

  vim.api.nvim_create_user_command(cmd_name, function()
    vim.cmd("write")
    vim.cmd(string.format(":vsp term://%s", command))
    vim.cmd("startinsert")
  end, {})

  -- Set up the keybinding for this filetype
  autocmd(filetype, function(args)
    local desc_prefix = string.format("MANIAC_%s", string.upper(filetype))
    vim.keymap.set("n", map_key,
      function() vim.cmd(cmd_name) end,
      { buffer = args.buf, desc = desc_prefix .. " : " .. description, silent = true })
  end)
end

-- C language
create_runner("c", "gcc -o out % && ./out && rm out")
autocmd("c", function()
  vim.opt_local.makeprg = "gcc -Wall -Wextra -o %:r %"
end)

-- Golang
create_runner("go", "go run %")

-- Golang test shortcuts
autocmd("go", function(args)
  local buf = args.buf
  vim.keymap.set("n", "<leader>t", function()
    vim.cmd("write")
    local command = string.format(":vsp term://go test -v %%:p:h/*.go")
    vim.cmd(command)
    vim.cmd("startinsert")
  end, { buffer = buf, desc = "MANIAC_GOLANG: [<leader>t] [T]est", silent = true })
  vim.keymap.set("n", "<leader>dt", function()
    vim.cmd("write")
    local main_go_file = vim.fn.input("Main GO file > ")
    if main_go_file == "" then
      main_go_file = "dummy_main.go"
    elseif not string.match(main_go_file, "%.go$") then
      main_go_file = main_go_file .. ".go"
    end
    local command = string.format(":vsp term://go test -v %%:h/%s %%", main_go_file)
    vim.cmd(command)
    vim.cmd("startinsert")
  end, { buffer = buf, desc = "MANIAC_GOLANG: [<leader>dt] [D]ummy [T]est", silent = true })
  vim.opt_local.makeprg = "go build"
end)

-- JavaScript/Node.js
create_runner("javascript", "node %")
create_runner("typescript", "ts-node %")
create_runner("javascriptreact", "node %")
create_runner("typescriptreact", "ts-node %")

-- Lua
create_runner("lua", "lua %")

-- Python
create_runner("python", "python3 %")
autocmd("python", function()
  vim.opt_local.makeprg = "python3 -m py_compile %"
end)

-- HTTP (For testing with rest.nvim)
autocmd("http", function(args)
  vim.keymap.set("n", "<leader>r", ":Rest run<CR>", {
    buffer = args.buf, desc = "MANIAC_http : run the http request under the server",
  })
end)

-- Markdown settings
autocmd("markdown", function()
  -- Uncomment if you want conceallevel
  -- vim.opt_local.conceallevel = 2
  vim.opt_local.spell = true
  vim.opt_local.wrap = true
  vim.opt_local.textwidth = 80
end)

-- Database output settings
autocmd("dbout", function()
  vim.opt_local.colorcolumn = "0"
  vim.opt_local.spell = false
end)

-- Quickfix list settings
autocmd("qf", function(args)
  vim.keymap.set("n", "<CR>", ":.cc<CR>",
    { buffer = args.buf, desc = "MANIAC_QUICKFIXLIST : Open the file/row/column under the cursor", silent = true })
  vim.opt_local.wrap = false
  vim.opt_local.number = true
  vim.opt_local.cursorline = true
end)
