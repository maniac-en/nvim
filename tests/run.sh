#!/usr/bin/env bash
# Run the headless smoke test for this Neovim config.
#
# Usage (from anywhere):
#   ~/.config/nvim/tests/run.sh
#   bash ~/.config/nvim/tests/run.sh
#
# Exits 0 when every check passes, 1 otherwise.
set -euo pipefail

config_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test the config this script lives in (not necessarily ~/.config/nvim),
# while still using the installed plugins and Mason tools.
export XDG_CONFIG_HOME="$(dirname "$config_dir")"
app_name="$(basename "$config_dir")"
if [[ "$app_name" != "nvim" ]]; then
  export NVIM_APPNAME="$app_name"
fi

# -i NONE: don't read or write shada (command history, marks, oldfiles)
exec nvim --headless -i NONE -c 'lua dofile(vim.fn.stdpath("config") .. "/tests/smoke.lua")'
