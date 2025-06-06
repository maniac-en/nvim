-- lua/config/autocmds.lua
local augroup = vim.api.nvim_create_augroup
local maniac_aug = augroup("maniac_aug", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- highlight the yanked text post yanking
autocmd("TextYankPost", {
    group = maniac_aug,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

-- clear out trailing spaces on buffer write
autocmd("BufWrite", {
    group = maniac_aug,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- disable line numbers in terminal
autocmd("TermOpen", {
    group = maniac_aug,
    pattern = "*",
    callback = function()
        vim.o.number = false
        vim.o.relativenumber = false
        vim.o.spell = false
    end,
})

-- file-type buffer-specific format options

-- Auto-format paragraphs
autocmd("FileType", {
    group = maniac_aug,
    pattern = { "text" },
    callback = function()
        vim.opt_local.formatoptions = vim.opt_local.formatoptions + "a"
    end,
})

-- Preferred format options for coding
autocmd("FileType", {
    group = maniac_aug,
    pattern = { "sh", "go", "lua", "python", "javascript" },
    callback = function()
        vim.opt_local.formatoptions = "jcroql"
    end,
})

-- Ref: https://www.reddit.com/r/neovim/comments/1jpbc7s/comment/mlh9o31/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- Only show virtual line diagnostic on current line
vim.api.nvim_create_autocmd({ 'CursorMoved', 'DiagnosticChanged' }, {
     group = vim.api.nvim_create_augroup('diagnostic_virt_text_hide', {}),
  callback = function(ev)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local lnum =  cursor_pos[1] - 1 -- Convert to 0-based index

   local hidden_lnum = vim.b[ev.buf].diagnostic_hidden_lnum
   if hidden_lnum and hidden_lnum ~= lnum then
     vim.b[ev.buf].diagnostic_hidden_lnum = nil
     -- display all the decorations if the current line changed
     vim.diagnostic.show(nil, ev.buf)
   end

   for _, namespace in pairs(vim.diagnostic.get_namespaces()) do
     local ns_id = namespace.user_data.virt_text_ns
       if ns_id then
         local extmarks = vim.api.nvim_buf_get_extmarks(ev.buf, ns_id, { lnum, 0 }, { lnum, -1 }, {})
         for _, extmark in pairs(extmarks) do
           local id = extmark[1]
           vim.api.nvim_buf_del_extmark(ev.buf, ns_id, id)
         end

         if extmarks and not vim.b[ev.buf].diagnostic_hidden_lnum then
           vim.b[ev.buf].diagnostic_hidden_lnum = lnum
        end
      end
    end
  end,
})
vim.api.nvim_create_autocmd('ModeChanged', {
  group = vim.api.nvim_create_augroup('diagnostic_redraw', {}),
  callback = function()
    pcall(vim.diagnostic.show)
  end
})
