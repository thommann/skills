#!/usr/bin/env bash
# Hook: auto-format-rust
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .rs file, run `rustfmt` on it.
# Uses the project-local toolchain via rustup if available.

set -euo pipefail

input=$(cat)
[[ -z "$input" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

[[ "$file_path" == *.rs ]] || exit 0

if command -v rustfmt >/dev/null 2>&1; then
  rustfmt --edition 2021 "$file_path" >/dev/null 2>&1 || true
fi

exit 0
