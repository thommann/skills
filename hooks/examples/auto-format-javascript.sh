#!/usr/bin/env bash
# Hook: auto-format-javascript
# Event: PostToolUse
# Matcher: Write|Edit
#
# After editing a .js/.jsx/.ts/.tsx/.vue/.svelte/.mjs/.cjs file, run the
# project's JS formatter/linter on it.
#
# Prefers the project-local tool via npx (picks up local eslint/prettier config).
# Falls back to global tools. Silent no-op if nothing is installed.

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
  *.js|*.jsx|*.ts|*.tsx|*.vue|*.svelte|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

# Prefer eslint --fix (handles lint + format with prettier-eslint chain); fall back to prettier alone.
if command -v npx >/dev/null 2>&1; then
  if npx --no-install eslint --version >/dev/null 2>&1; then
    npx --no-install eslint --fix "$file_path" >/dev/null 2>&1 || true
  elif npx --no-install prettier --version >/dev/null 2>&1; then
    npx --no-install prettier --write "$file_path" >/dev/null 2>&1 || true
  fi
fi

exit 0
