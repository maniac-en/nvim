-- ftplugin/gitcommit.lua
-- :AiCommit generates a commit message for the staged changes via an external script

local ai_script_name = "ai-commit-msg.sh" -- Assumes script is in $PATH

local function run_ai_commit_generator()
  -- Check if already run for this buffer to prevent accidental re-runs
  if vim.b.ai_commit_generated then
    vim.notify("AI commit message already generated or attempted for this buffer.", vim.log.levels.INFO)
    return
  end

  local confirm = vim.fn.confirm("Generate AI commit message for staged changes?", "&Yes\n&No")
  if confirm ~= 1 then -- 1 is "Yes"
    vim.notify("AI commit message generation cancelled.", vim.log.levels.INFO)
    return
  end

  -- Set a flag to indicate generation has been attempted for this buffer
  vim.b.ai_commit_generated = true

  -- The current buffer is the temporary Git commit message file
  local commit_file_path = vim.fn.bufname("%")

  vim.defer_fn(function()
    vim.notify("Generating AI commit message... Please wait.", vim.log.levels.INFO)

    -- The script writes directly to the file and reports its own errors on stderr
    vim.cmd(string.format("silent !%s %s", ai_script_name, vim.fn.shellescape(commit_file_path)))

    if vim.v.shell_error ~= 0 then
      vim.notify("AI commit script failed. Check stderr for details.", vim.log.levels.ERROR)
      -- Unset the flag so the user can try again after fixing
      vim.b.ai_commit_generated = nil
    else
      vim.notify("AI commit message generated successfully!", vim.log.levels.INFO)
    end

    -- Reload the buffer to show the updated content
    vim.cmd("e!")
  end, 10) -- Small delay to allow prompt to render
end

vim.api.nvim_buf_create_user_command(0, "AiCommit", run_ai_commit_generator, {
  desc = "Generate AI Git Commit Message for Staged Changes",
})
