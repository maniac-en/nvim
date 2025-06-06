-- lua/plugins/langtools.lua

local function setup_langtools()
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

    -- Create autocmd to set up the keybinding for this filetype
    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetype,
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local desc_prefix = string.format("MANIAC_%s", string.upper(filetype))
        vim.keymap.set("n", map_key,
          function() vim.cmd(cmd_name) end,
          { buffer = buf, desc = desc_prefix .. " : " .. description, silent = true })
      end
    })
  end

  -- Set up language-specific runners

  -- C language
  create_runner("c", "gcc -o out % && ./out && rm out")

  -- Golang
  create_runner("go", "go run %")

  -- Add go test command with special options
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.keymap.set("n", "<leader>t", function()
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
      end, { buffer = buf, desc = "MANIAC_GOLANG: [<leader>t] go test", silent = true })
    end
  })

  -- JavaScript/Node.js
  create_runner("javascript", "node %")
  create_runner("typescript", "ts-node %")
  create_runner("javascriptreact", "node %")
  create_runner("typescriptreact", "ts-node %")

  -- Lua
  create_runner("lua", "lua %")

  -- Python
  create_runner("python", "python3 %")

  -- Markdown settings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      -- Uncomment if you want conceallevel
      -- vim.opt_local.conceallevel = 2

      -- Additional markdown-specific settings can go here
      vim.opt_local.spell = true
      vim.opt_local.wrap = true
      vim.opt_local.textwidth = 80
    end
  })

  -- Database output settings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "dbout",
    callback = function()
      vim.opt_local.colorcolumn = "0"
      vim.opt_local.spell = false
    end
  })

  -- Quickfix list settings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.keymap.set("n", "<CR>", ":.cc<CR>",
        { buffer = buf, desc = "MANIAC_QUICKFIXLIST : Open the file/row/column under the cursor", silent = true })

      -- Additional quickfix window settings
      vim.opt_local.wrap = false
      vim.opt_local.number = true
      vim.opt_local.cursorline = true
    end
  })

  -- Set compiler options for different languages
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "c",
    callback = function()
      vim.opt_local.makeprg = "gcc -Wall -Wextra -o %:r %"
    end
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
      vim.opt_local.makeprg = "go build"
    end
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
      vim.opt_local.makeprg = "python3 -m py_compile %"
    end
  })
end

return {
  {
    "nvim-lua/plenary.nvim",     -- Use a real plugin, even if minimal
    name = "langtools",
    config = setup_langtools,
  },
}
