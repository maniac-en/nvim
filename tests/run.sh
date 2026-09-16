#!/usr/bin/env bash
# Run the headless smoke tests for this Neovim config.
#
# Usage (from anywhere):
#   ~/.config/nvim/tests/run.sh             # all specs in tests/specs/
#   ~/.config/nvim/tests/run.sh go python   # only these specs
#
# Each spec runs in its own headless Neovim (tests/lib.lua). "startup" runs first
# on its own so its timing isn't skewed; the rest run in parallel. Results stream
# as "[spec] PASS/FAIL ..." lines, followed by a summary.
# Exits 0 when every check passes, 1 otherwise.
set -uo pipefail

config_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
specs_dir="$config_dir/tests/specs"

# Test the config this script lives in (not necessarily ~/.config/nvim),
# while still using the installed plugins and Mason tools.
export XDG_CONFIG_HOME="$(dirname "$config_dir")"
app_name="$(basename "$config_dir")"
if [[ "$app_name" != "nvim" ]]; then
  export NVIM_APPNAME="$app_name"
fi

if (( $# )); then
  specs=("$@")
else
  specs=()
  for f in "$specs_dir"/*.lua; do specs+=("$(basename "$f" .lua)"); done
fi
for s in "${specs[@]}"; do
  if [[ ! -f "$specs_dir/$s.lua" ]]; then
    echo "unknown spec: $s (available: $(cd "$specs_dir" && ls *.lua | sed 's/\.lua$//' | tr '\n' ' '))" >&2
    exit 2
  fi
done

logdir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")"
start=$SECONDS

# Run one spec; stream its results with a [spec] prefix, keep the raw log.
run_spec() {
  local name=$1
  # -i NONE: don't read or write shada (command history, marks, oldfiles)
  SMOKE_SPEC="$specs_dir/$name.lua" nvim --headless -i NONE \
    -c 'lua dofile(vim.fn.stdpath("config") .. "/tests/lib.lua").run(os.getenv("SMOKE_SPEC"))' 2>&1 \
    | tee "$logdir/$name.log" \
    | awk -v spec="$name" '
        /^@@PASS /   { printf "[%s] PASS  %s\n", spec, substr($0, 8); fflush(); next }
        /^@@FAIL /   { printf "[%s] FAIL  %s\n", spec, substr($0, 8); fflush(); next }
        /^@@DETAIL / { printf "[%s]         %s\n", spec, substr($0, 10); fflush(); next }'
  echo "${PIPESTATUS[0]}" > "$logdir/$name.code"
}

parallel=()
for s in "${specs[@]}"; do
  if [[ "$s" == "startup" ]]; then run_spec startup; else parallel+=("$s"); fi
done
pids=()
for s in "${parallel[@]}"; do
  run_spec "$s" &
  pids+=($!)
done
for pid in "${pids[@]}"; do wait "$pid"; done

# Summary
total=0
failed=0
failures=()
echo
for s in "${specs[@]}"; do
  log="$logdir/$s.log"
  code="$(cat "$logdir/$s.code" 2>/dev/null || echo "?")"
  passes=$(grep -c '^@@PASS ' "$log" || true)
  fails=$(grep -c '^@@FAIL ' "$log" || true)
  total=$((total + passes + fails))
  failed=$((failed + fails))
  if ! grep -q '^@@END ' "$log"; then
    # crashed or killed before reporting: count it as a failure
    failed=$((failed + 1))
    failures+=("[$s] did not finish (exit code $code), see $log")
    printf "  %-12s CRASHED (exit %s)\n" "$s" "$code"
  elif (( fails > 0 )); then
    printf "  %-12s %3d passed, %d FAILED\n" "$s" "$passes" "$fails"
    while IFS= read -r line; do failures+=("[$s] ${line#@@FAIL }"); done < <(grep '^@@FAIL ' "$log")
  else
    printf "  %-12s %3d passed\n" "$s" "$passes"
  fi
done

echo
echo "$total checks, $failed failed in $((SECONDS - start))s (${#specs[@]} specs)"
if (( failed > 0 )); then
  for f in "${failures[@]}"; do echo "  FAIL  $f"; done
  echo "raw logs: $logdir"
  exit 1
fi
rm -rf "$logdir"
exit 0
