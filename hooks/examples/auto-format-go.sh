#!/usr/bin/env bash
# Hook: auto-format-go
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .go file, run `gofmt -w` and (if present) `goimports -w`.

set -euo pipefail

input=$(cat)
[[ -z "$input" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

[[ "$file_path" == *.go ]] || exit 0

if command -v goimports >/dev/null 2>&1; then
  goimports -w "$file_path" >/dev/null 2>&1 || true
elif command -v gofmt >/dev/null 2>&1; then
  gofmt -w "$file_path" >/dev/null 2>&1 || true
fi

exit 0
