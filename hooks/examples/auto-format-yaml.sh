#!/usr/bin/env bash
# Hook: auto-format-yaml
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .yaml/.yml file, run yamlfix on it.
# Silent no-op if yamlfix is not installed.

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
  *.yaml|*.yml) ;;
  *) exit 0 ;;
esac

if command -v yamlfix >/dev/null 2>&1; then
  yamlfix "$file_path" >/dev/null 2>&1 || true
elif command -v uv >/dev/null 2>&1 && uv run --quiet yamlfix --version >/dev/null 2>&1; then
  uv run --quiet yamlfix "$file_path" >/dev/null 2>&1 || true
fi

exit 0
