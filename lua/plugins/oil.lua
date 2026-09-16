-- lua/plugins/oil.lua
local key = require("config.map").lazy

-- gitignored entries per directory (see opts below)
local git_ignored
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    key("-", "<CMD>Oil<CR>", "Files", "open parent directory (oil)"),
  },
  opts = function()
    -- Create a module-scoped variable for detail view toggle
    local detail_view_enabled = false

    -- Gitignored entries per directory: one `git ls-files` per directory,
    -- cached until the oil view is refreshed (oil's documented recipe; the
    -- previous version ran `git check-ignore` once per entry)
    local function new_git_ignored()
      return setmetatable({}, {
        __index = function(cache, dir)
          local ignored = {}
          local res = vim.system(
            { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
            { cwd = dir, text = true }
          ):wait()
          if res.code == 0 then
            for line in vim.gsplit(res.stdout, "\n", { plain = true, trimempty = true }) do
              ignored[(line:gsub("/$", ""))] = true
            end
          end
          rawset(cache, dir, ignored)
          return ignored
        end,
      })
    end
    git_ignored = new_git_ignored()

    -- Re-read .gitignore state on refresh (<C-l>)
    local refresh = require("oil.actions").refresh
    local orig_refresh = refresh.callback
    refresh.callback = function(...)
      git_ignored = new_git_ignored()
      orig_refresh(...)
    end

    return {
      -- File system options
      columns = {
        "icon",
      },
      -- Buffer display and behavior
      view_options = {
        -- Hide dotfiles and gitignored files (toggle with g.)
        show_hidden = false,
        is_hidden_file = function(name, bufnr)
          if vim.startswith(name, ".") then
            return true
          end
          local dir = require("oil").get_current_dir(bufnr)
          if not dir then return false end -- not a local directory (e.g. ssh)
          return git_ignored[dir][name] == true
        end,
        -- Natural sort order (10.txt comes after 2.txt)
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },
      -- UI settings
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },
      keymaps = {
        ["gd"] = {
          desc = "Toggle file detail view",
          callback = function()
            detail_view_enabled = not detail_view_enabled
            if detail_view_enabled then
              require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
            else
              require("oil").set_columns({ "icon" })
            end
          end,
        },
      },
      -- Status line integration
      use_default_keymaps = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = true,
      cleanup_delay_ms = 2000,
      lsp_file_methods = {
        autosave_changes = true,
      },
    }
  end,
  -- Additional setup hook for post-initialization
  config = function(_, opts)
    require("oil").setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil",
      callback = function()
        vim.opt_local.scrolloff = 3
      end,
    })
  end,
}
