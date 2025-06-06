-- lua/plugins/telescope.lua
return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		cmd = "Telescope",
		lazy = false,
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
			local themes = require("telescope.themes")
			local builtin = require("telescope.builtin")

			-- Layout configurations
			local default_layout = {
				prompt_position = "top",
				width = 0.85,
				height = 0.85,
			}

			local large_layout = {
				width = 0.9,
				height = 0.9,
			}

			telescope.setup({
				defaults = {
					layout_config = default_layout,
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
					file_ignore_patterns = {
						"node_modules/",
						"%.git/",
						"%.DS_Store",
						"target/",
						"build/",
						"dist/",
						"%.o",
						"%.a",
						"%.out",
						"%.class",
						"%.pdf",
						"%.mkv",
						"%.mp4",
						"%.zip",
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
					find_files = { hidden = true, },
					live_grep = {
						additional_args = function()
							return { "--hidden" }
						end,
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
					["ui-select"] = themes.get_dropdown(),
				},
			})

			-- Load extensions
			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "ui-select")

			-- Project root detection
			local function find_project_root()
				local current_file = vim.api.nvim_buf_get_name(0)
				local current_dir = current_file == "" and vim.fn.getcwd()
					or vim.fn.fnamemodify(current_file, ":h")

				-- Check for git root first
				local git_cmd = "git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel"
				local git_root = vim.fn.systemlist(git_cmd)[1]
				if vim.v.shell_error == 0 then
					return git_root, "git"
				end

				-- Check for common project markers
				local project_markers = {
					"package.json", "Cargo.toml", "pyproject.toml", "go.mod",
					"pom.xml", "build.gradle", "Makefile", "CMakeLists.txt"
				}

				local check_dir = current_dir
				while check_dir ~= "/" do
					for _, marker in ipairs(project_markers) do
						if vim.fn.filereadable(check_dir .. "/" .. marker) == 1 then
							return check_dir, "project"
						end
					end
					check_dir = vim.fn.fnamemodify(check_dir, ":h")
				end

				return current_dir, "cwd"
			end

			-- Find files
			local function find_files()
				local root_dir, root_type = find_project_root()
				local opts = {
					cwd = root_dir,
					hidden = true,
					layout_config = large_layout,
					winblend = 10,
				}

				if root_type == "git" then
					builtin.git_files(opts)
				else
					builtin.find_files(opts)
				end
			end

			-- Live grep
			local function live_grep()
				local root_dir, _ = find_project_root()
				builtin.live_grep({
					search_dirs = { root_dir },
					layout_config = large_layout,
					winblend = 10,
				})
			end

			-- Current directory functions (for <M-p>)
			local function find_files_current_dir()
				local current_file = vim.api.nvim_buf_get_name(0)
				local current_dir = current_file == "" and vim.fn.getcwd()
					or vim.fn.fnamemodify(current_file, ":h")

				builtin.find_files({
					cwd = current_dir,
					hidden = true,
					no_ignore = true,
					layout_config = large_layout,
					winblend = 10,
				})
			end

			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, {
					silent = true,
					desc = "Telescope: " .. desc
				})
			end

			map("n", "<C-b>", function()
				builtin.buffers(themes.get_dropdown({
					previewer = false,
					sort_lastused = true,
					winblend = 10,
				}))
			end, "Find buffers")

			map("n", "<C-p>", find_files, "Find files with project detection")
			map("n", "<M-p>", find_files_current_dir, "Find files (current dir)")
			map("n", "<C-f>", live_grep, "Live grep with project detection")
			map("n", "z=", builtin.spell_suggest, "Spell suggest")
			map("n", "<leader>ft", builtin.filetypes, "File Types")

			-- Current buffer search
			-- @@@(self): use "Ctrl-V", and then "Ctrl+/" to actually add the
			-- mapping for it to work. Simply using "<C+/>" doesn't work!
			map("n", "", function()
				builtin.current_buffer_fuzzy_find(themes.get_dropdown({
					previewer = false,
					layout_config = {
						height = 0.75,
						width = 0.75,
					},
					winblend = 10,
				}))
			end, "Search in current buffer")

			-- Leader-based search functions
			map("n", "<leader>sh", builtin.help_tags, "[S]earch [H]elp")
			map("n", "<leader>sd", builtin.diagnostics, "[S]earch [D]iagnostics")
			map("n", "<leader>sr", builtin.resume, "[S]earch [R]esume")

			map("n", "<leader>sw", function()
				local root_dir, _ = find_project_root()
				builtin.grep_string({
					cwd = root_dir,
				})
			end, "[S]earch current [W]ord")

			map("n", "<leader>ss", function()
				local search_query = vim.fn.input("Yoink: ")
				if search_query ~= "" then
					local root_dir, _ = find_project_root()
					builtin.grep_string({
						cwd = root_dir,
						search = search_query,
						use_regex = true,
					})
				end
			end, "[S]earch [S]tring")

			map("n", "<leader>sf", function()
				builtin.find_files({
					hidden = true,
					no_ignore = true,
				})
			end, "[S]earch all [F]iles (no ignore)")

			-- Commands for manual use
			vim.api.nvim_create_user_command("TelescopeProjectRoot", function()
				local root_dir, root_type = find_project_root()
				print("Project root: " .. root_dir .. " (detected as: " .. root_type .. ")")
			end, { desc = "Show detected project root" })
		end,
	},
}
