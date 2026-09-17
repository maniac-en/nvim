-- lua/plugins/telescope.lua
local key = require("config.map").lazy

local function builtin() return require("telescope.builtin") end
local function themes() return require("telescope.themes") end

-- File pickers get a larger window than the default
local large_layout = { width = 0.9, height = 0.9 }

local project_markers = {
  "package.json", "Cargo.toml", "pyproject.toml", "go.mod",
  "pom.xml", "build.gradle", "Makefile", "CMakeLists.txt",
}

-- Directory to start from: the folder shown in oil, the file's folder, else Neovim's cwd
local function current_dir()
  if vim.bo.filetype == "oil" then return require("oil").get_current_dir() or vim.fn.getcwd() end
  local file = vim.api.nvim_buf_get_name(0)
  return (vim.bo.buftype == "" and file ~= "") and vim.fs.dirname(file) or vim.fn.getcwd()
end

-- Project root: git root, else the nearest project marker, else the current directory
local function find_project_root()
  local dir = current_dir()
  local root = vim.fs.root(dir, ".git")
  if root then return root, "git" end
  root = vim.fs.root(dir, project_markers)
  if root then return root, "project" end
  return dir, "cwd"
end

-- Project files: git files in a repo, else all files from the project root
local function find_files()
  local root_dir, root_type = find_project_root()
  local opts = { cwd = root_dir, layout_config = large_layout, winblend = 10 }
  if root_type == "git" then
    builtin().git_files(opts)
  else
    builtin().find_files(opts)
  end
end

-- All files in the current directory, including ignored ones
local function find_files_current_dir()
  builtin().find_files({ cwd = current_dir(), no_ignore = true, layout_config = large_layout, winblend = 10 })
end

local function live_grep()
  local root_dir, _ = find_project_root()
  builtin().live_grep({ cwd = root_dir, layout_config = large_layout, winblend = 10 })
end

local function buffers()
  builtin().buffers(themes().get_dropdown({ previewer = false, sort_lastused = true, winblend = 10 }))
end

local function current_buffer_search()
  builtin().current_buffer_fuzzy_find(themes().get_dropdown({
    previewer = false,
    layout_config = { height = 0.75, width = 0.75 },
    winblend = 10,
  }))
end

local function grep_word()
  local root_dir, _ = find_project_root()
  builtin().grep_string({ cwd = root_dir })
end

local function grep_prompt()
  local search_query = vim.fn.input("Yoink: ")
  if search_query ~= "" then
    local root_dir, _ = find_project_root()
    builtin().grep_string({ cwd = root_dir, search = search_query, use_regex = true })
  end
end

local function all_files()
  builtin().find_files({ no_ignore = true })
end

-- `silent` like the other telescope maps
local function search(lhs, rhs, text)
  return key(lhs, rhs, "Search", text, { silent = true })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope", "TelescopeProjectRoot" },
    -- declared here (not in config) so they're described before telescope loads
    keys = {
      search("<C-p>", find_files, "[P]roject files"),
      search("<M-p>", find_files_current_dir, "files in current dir (incl. ignored)"),
      search("<C-f>", live_grep, "[F]ind text in project (live grep)"),
      search("<C-b>", buffers, "open [B]uffers"),
      -- Ctrl+/ arrives as <C-/> with modern key reporting (e.g. WezTerm), as <C-_> in older terminals
      search("<C-/>", current_buffer_search, "text in current buffer"),
      search("<C-_>", current_buffer_search, "text in current buffer"),
      search("<leader>sh", function() builtin().help_tags() end, "[S]earch [H]elp"),
      search("<leader>sd", function() builtin().diagnostics() end, "[S]earch [D]iagnostics"),
      search("<leader>sr", function() builtin().resume() end, "[S]earch [R]esume last picker"),
      search("<leader>sw", grep_word, "[S]earch [W]ord under cursor"),
      search("<leader>ss", grep_prompt, "[S]earch [S]tring (regex prompt)"),
      search("<leader>sf", all_files, "[S]earch all [F]iles (incl. ignored)"),
      search("<leader>sk", function() builtin().keymaps() end, "[S]earch [K]eymaps"),
      search("<leader>ft", function() builtin().filetypes() end, "[F]ile[T]ype (set for buffer)"),
      key("z=", function() builtin().spell_suggest() end, "Spell", "suggestions for word under cursor", { silent = true }),
    },
    init = function()
      -- telescope-ui-select replaces vim.ui.select (code actions, etc.) once
      -- telescope loads; load it on the first vim.ui.select call too
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "telescope.nvim" } })
        return vim.ui.select(...)
      end
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      -- Paths hidden from the file pickers (find_files, live_grep, grep_string),
      -- mainly for <M-p>/<leader>sf which skip .gitignore. Lua patterns, anchored
      -- to whole directory names / file extensions. Not set globally: telescope
      -- would also filter LSP pickers (gd, gi, ...) by these, on absolute paths.
      local file_ignore_patterns = {
        "^%.git/", "/%.git/",
        "^node_modules/", "/node_modules/",
        "%.DS_Store$",
        "%.o$", "%.a$", "%.out$", "%.class$",
        "%.pdf$", "%.mkv$", "%.mp4$", "%.zip$",
      }

      telescope.setup({
        defaults = {
          layout_config = {
            prompt_position = "top",
            width = 0.85,
            height = 0.85,
          },
          sorting_strategy = "ascending",
          scroll_strategy = "cycle",
          selection_strategy = "reset",
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            "--hidden",
            "--glob=!.git/",
          },
          path_display = { "truncate" },
          winblend = 10,
          set_env = { ["COLORTERM"] = "truecolor" },
        },
        pickers = {
          buffers = {
            sort_lastused = true,
            sort_mru = true,
            show_all_buffers = true,
            mappings = {
              i = { ["<C-d>"] = actions.delete_buffer },
              n = { ["dd"] = actions.delete_buffer },
            },
          },
          find_files = { hidden = true, file_ignore_patterns = file_ignore_patterns },
          live_grep = { file_ignore_patterns = file_ignore_patterns },
          grep_string = { file_ignore_patterns = file_ignore_patterns },
          git_files = { show_untracked = true },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          ["ui-select"] = themes().get_dropdown(),
        },
      })

      -- Load extensions
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      -- Commands for manual use
      vim.api.nvim_create_user_command("TelescopeProjectRoot", function()
        local root_dir, root_type = find_project_root()
        print("Project root: " .. root_dir .. " (detected as: " .. root_type .. ")")
      end, { desc = "Show detected project root" })
    end,
  },
}
