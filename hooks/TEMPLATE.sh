#!/usr/bin/env bash
# Hook: <one-line description>
# Event: PreToolUse | PostToolUse | Stop | SessionStart
# Matcher: <tool name pattern, e.g. "Write|Edit", or "" for all>
#
# This hook <describes what it does and why>.
#
# Exit codes:
#   0 — proceed (or irrelevant input; short-circuited silently)
#   2 — block the tool call (PreToolUse) or signal error (other events)
#       Must print an actionable message to stderr when exiting 2.

set -euo pipefail

# Read the JSON payload from stdin that Claude Code sends to every hook.
input=$(cat)

# Short-circuit on empty input (happens in some edge cases).
[[ -z "$input" ]] && exit 0

# Extract the relevant field. Most hooks care about one of these:
#   .tool_name          — which tool is firing
#   .tool_input.file_path — file being written/edited (Write, Edit, Read)
#   .tool_input.command — bash command about to run (Bash)
#   .tool_response      — tool output (PostToolUse only)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Short-circuit when this hook is not relevant to the current tool.
# Do NOT error here — Claude Code calls every hook on every matching event.
case "$tool_name" in
  Write|Edit) ;;  # relevant — continue
  *) exit 0 ;;    # not our event — exit cleanly
esac

# Short-circuit when we have no file path (safety).
[[ -z "$file_path" ]] && exit 0

# --- Main logic -------------------------------------------------------------
#
# Now do the thing this hook is for. Common patterns:
#
# 1) Precondition check: is a required tool installed?
#    Use `command -v` and exit 0 (not 1) if missing — don't block work just
#    because a formatter isn't installed on this machine.
#
#      command -v ruff >/dev/null 2>&1 || exit 0
#
# 2) Filter by file extension:
#
#      case "$file_path" in
#        *.py) ;;
#        *) exit 0 ;;
#      esac
#
# 3) Blocking (PreToolUse): decide whether to allow the tool call.
#    Exit 2 with an actionable stderr message when blocking.
#
#      if [[ "$file_path" == *".env" ]]; then
#        echo "BLOCKED: .env contains secrets. Use .env.example for templates." >&2
#        exit 2
#      fi
#
# 4) Acting (PostToolUse): run formatters, tests, etc.
#
#      ruff format "$file_path" 2>&1 | head -20
#      # Non-fatal — if it fails, log and continue.
#
# ---------------------------------------------------------------------------

# TODO: replace with this hook's actual logic.

exit 0
