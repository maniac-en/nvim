-- lua/plugins/oil.lua
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory in Oil" },
  },
  opts = function()
    -- Create a module-scoped variable for detail view toggle
    local detail_view_enabled = false

    return {
      -- File system options
      columns = {
        "icon",
      },
      -- Buffer display and behavior
      view_options = {
        -- Show hidden files (respects .gitignore)
        show_hidden = false,
        is_hidden_file = function(name, entry)
          local dir = require("oil").get_current_dir()
          if not dir then return false end

          -- Always hide dotfiles
          if vim.startswith(name, ".") then
            return true
          end

          -- Fallback to name if entry is not a table
          local rel_path = type(entry) == "table" and entry.name or name

          -- Check via git check-ignore
          local result = vim.system({ "git", "check-ignore", rel_path }, {
            cwd = dir,
            text = true,
          }):wait()

          return result.code == 0
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
