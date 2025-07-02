-- lua/plugins/git.lua
return {
  -- Fugitive: Git commands in nvim
  {
    "tpope/vim-fugitive",
    event = { "VeryLazy", "BufReadPre" },
    cmd = { "Git", "Gvdiffsplit", "GBrowse", "Gdiffsplit", "Gwrite", "Gread" },
    dependencies = { "tpope/vim-rhubarb" },
    config = function()
      local map = function(mode, lhs, rhs, desc, silent)
        silent = silent or false
        if desc then
          desc = "MANIAC_FUGITIVE: " .. desc
        end
        vim.keymap.set(mode, lhs, rhs, { remap = false, silent = silent, desc = desc })
      end

      map("n", "<leader>gs", vim.cmd.Git, "[<leader>gs] [G]it [S]tatus", true)
      map("n", "<leader>gb", ":GBrowse %<CR>", "[<leader>gb] [G]it [B]rowse", false)

      -- Generate commit message via AI
      local ai_script_name = "ai-commit-msg.sh" -- Assumes script is in $PATH

      -- Create an autocommand group for organization (cleared on config reload)
      vim.api.nvim_create_augroup("AiGitCommit", { clear = true })

      -- Function to run the AI commit message generation
      local function run_ai_commit_generator()
        -- Check if already run for this buffer to prevent accidental re-runs
        if vim.b.ai_commit_generated then
          vim.notify("AI commit message already generated or attempted for this buffer.", vim.log.levels.INFO)
          return
        end

        -- Prompt user for confirmation
        local confirm = vim.fn.confirm("Generate AI commit message for staged changes?", "&Yes\n&No")
        if confirm ~= 1 then -- 1 is "Yes"
          vim.notify("AI commit message generation cancelled.", vim.log.levels.INFO)
          return
        end

        -- Set a flag to indicate generation has been attempted for this buffer
        vim.b.ai_commit_generated = true

        -- Get the current buffer name (which is the temporary Git commit message file path)
        local commit_file_path = vim.fn.bufname("%")

        -- Use vim.defer_fn to run the script asynchronously
        vim.defer_fn(function()
          vim.notify("Generating AI commit message... Please wait.", vim.log.levels.INFO)

          -- Construct and execute the shell command
          local cmd = string.format("silent !%s %s", ai_script_name, vim.fn.shellescape(commit_file_path))
          -- Use vim.fn.system for better error detection, but it's synchronous by default.
          -- For non-blocking, we'd need to use nvim_call_dict_function with jobstart,
          -- but for a quick script like this, system() is fine unless it's very slow.
          vim.cmd(cmd) -- We'll let the script write directly and handle its own errors to stderr

          -- After the script runs, check for shell_error from the last ! command
          if vim.v.shell_error ~= 0 then
            vim.notify("AI commit script failed. Check stderr for details.", vim.log.levels.ERROR)
            -- Optionally: unset the flag if generation failed so user can try again after fixing
            vim.b.ai_commit_generated = nil
          else
            vim.notify("AI commit message generated successfully!", vim.log.levels.INFO)
          end

          -- Reload the buffer to show the updated content
          vim.cmd("e!") -- 'e!' reloads the current buffer, reading from disk
        end, 10)        -- Small delay to allow prompt to render
      end

      -- Create a buffer-local command and keymap when a gitcommit buffer opens
      vim.api.nvim_create_autocmd("FileType", {
        group = "AiGitCommit",
        pattern = "gitcommit",
        callback = function()
          -- Define the user command (without 'buffer=true' for NVIM v0.11.1)
          vim.api.nvim_create_user_command(
            "AiCommit", -- The command name (e.g., :AiCommit)
            run_ai_commit_generator,
            {
              -- 'buffer=true' is not supported in NVIM v0.11.1 for nvim_create_user_command.
              -- Its placement inside this FileType autocmd already makes it buffer-local.
              desc = "Generate AI Git Commit Message for Staged Changes",
            }
          )

          -- -- Initialize ai_commit_generated flag if the buffer is empty
          -- -- This provides a way to regenerate if the user clears the buffer.
          -- -- This should run *after* the command/keymap are set up for the buffer.
          -- vim.defer_fn(function()
          --   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          --   local has_content = false
          --   for _, line in ipairs(lines) do
          --     if not line:match("^#") and not (line:gsub("%s", "") == "") then
          --       has_content = true
          --       break
          --     end
          --   end
          --   if not has_content then
          --     vim.b.ai_commit_generated = nil -- Reset the flag if buffer is essentially empty
          --   end
          -- end, 50)                            -- Small delay after FileType autocommand fires
        end,
      })
    end,
  },

  -- Gitsigns: Git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
      },
      watch_gitdir = {
        follow_files = true,
        interval = 2000,
      },
      attach_to_untracked = true,
      update_debounce = 200,
      word_diff = false,
    },
  },

  -- GV: A git commit browser in Vim
  {
    "junegunn/gv.vim",
    dependencies = {
      "tpope/vim-fugitive",
    },
  },
}
