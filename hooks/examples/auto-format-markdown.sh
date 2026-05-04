#!/usr/bin/env bash
# Hook: auto-format-markdown
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .md/.markdown file, run mdformat on it.
# Silent no-op if mdformat is not installed.

set -euo pipefail

input=$(cat)
[[ -z "$input" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

case "$file_path" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

if command -v mdformat >/dev/null 2>&1; then
  mdformat --number "$file_path" >/dev/null 2>&1 || true
elif command -v uv >/dev/null 2>&1 && uv run --quiet mdformat --version >/dev/null 2>&1; then
  uv run --quiet mdformat --number "$file_path" >/dev/null 2>&1 || true
fi

exit 0
