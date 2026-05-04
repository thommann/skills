#!/usr/bin/env bash
# Hook: auto-format-python
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .py file, run `ruff format` + `ruff check --fix` on it.
# If ruff is not installed, exit 0 silently — do not block work.

set -euo pipefail

input=$(cat)
[[ -z "$input" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

[[ "$file_path" == *.py ]] || exit 0

# Prefer `uv run ruff` if a pyproject.toml is next to the file; fall back to plain ruff.
if command -v ruff >/dev/null 2>&1; then
  ruff format "$file_path" >/dev/null 2>&1 || true
  ruff check --fix --exit-zero "$file_path" >/dev/null 2>&1 || true
elif command -v uv >/dev/null 2>&1; then
  uv run --quiet ruff format "$file_path" >/dev/null 2>&1 || true
  uv run --quiet ruff check --fix --exit-zero "$file_path" >/dev/null 2>&1 || true
fi

exit 0
