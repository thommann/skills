#!/usr/bin/env bash
# validate-claude-md.sh — Quality check for a CLAUDE.md file.
# Adapted from the validate_claude_md function in
#   https://github.com/joelbarmettlerUZH/ultrainit.sh/blob/main/lib/validate.sh
# Usage: bash validation/validate-claude-md.sh path/to/CLAUDE.md
set -euo pipefail

CLAUDE_PATH="${1:?Usage: validate-claude-md.sh <path-to-CLAUDE.md>}"
ERRORS=0
WARNINGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERIC_PHRASES_FILE="${GENERIC_PHRASES_FILE:-$SCRIPT_DIR/lib/generic-phrases.txt}"

if [ ! -f "$CLAUDE_PATH" ]; then
  echo "ERROR: File not found: $CLAUDE_PATH" >&2
  exit 1
fi

echo "=== Validating CLAUDE.md: $CLAUDE_PATH ==="

# --- Size -------------------------------------------------------------------

LINES=$(wc -l < "$CLAUDE_PATH")
WORD_COUNT=$(wc -w < "$CLAUDE_PATH")
echo "Size: $LINES lines, ~$WORD_COUNT words"

if [ "$LINES" -lt 30 ]; then
  echo "ERROR: CLAUDE.md is only $LINES lines (minimum 30). Too thin to be load-bearing." >&2
  ERRORS=$((ERRORS + 1))
elif [ "$LINES" -lt 50 ]; then
  echo "WARNING: CLAUDE.md is only $LINES lines (recommended 100+). Likely too thin." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# --- Banned generic phrases -------------------------------------------------

if [ -f "$GENERIC_PHRASES_FILE" ]; then
  # Strip backtick-delimited and double-quoted content first; those are mentions, not usages.
  GENERIC_COUNT=$(sed -E 's/`[^`]*`//g; s/"[^"]*"//g' "$CLAUDE_PATH" | grep -ciEf "$GENERIC_PHRASES_FILE" 2>/dev/null || true)
  GENERIC_COUNT=${GENERIC_COUNT:-0}
  if [ "$GENERIC_COUNT" -gt 0 ]; then
    echo "ERROR: CLAUDE.md contains $GENERIC_COUNT banned generic phrase(s) in prose. See $GENERIC_PHRASES_FILE." >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# --- At least one code block or pipe table ----------------------------------

HAS_COMMANDS=$(grep -cE '(^```|^\|[^|]*\|[^|]*\|)' "$CLAUDE_PATH" 2>/dev/null || true)
HAS_COMMANDS=${HAS_COMMANDS:-0}
if [ "$HAS_COMMANDS" -lt 1 ]; then
  echo "ERROR: CLAUDE.md has no code blocks or command tables. Not load-bearing without commands or file paths." >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Prohibitions without alternatives --------------------------------------

PROHIBITIONS=$(grep -ciE '(never |don.t |do not |must not )' "$CLAUDE_PATH" 2>/dev/null || true)
PROHIBITIONS=${PROHIBITIONS:-0}
ALTERNATIVES=$(grep -ciE '(instead|use .* instead|prefer |create new|use the )' "$CLAUDE_PATH" 2>/dev/null || true)
ALTERNATIVES=${ALTERNATIVES:-0}

if [ "$PROHIBITIONS" -gt 0 ] && [ "$ALTERNATIVES" -eq 0 ]; then
  echo "ERROR: CLAUDE.md has $PROHIBITIONS prohibitions but no alternatives. Every 'don't' needs a 'do this instead'." >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Recommended sections (warnings, not errors) ----------------------------

if ! grep -qiE '^## architecture' "$CLAUDE_PATH"; then
  echo "WARNING: No '## Architecture' section. The longest and most important section of a CLAUDE.md." >&2
  WARNINGS=$((WARNINGS + 1))
fi

if ! grep -qiE '^## (things to know|gotchas)' "$CLAUDE_PATH"; then
  echo "WARNING: No '## Things to Know' section. The agent benefits most from hidden invariants and gotchas." >&2
  WARNINGS=$((WARNINGS + 1))
fi

if ! grep -qiE '^## (quick reference|commands)' "$CLAUDE_PATH"; then
  echo "WARNING: No '## Quick Reference' section with build/test commands." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# --- Summary ----------------------------------------------------------------

echo ""
echo "=== Results ==="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "VERDICT: FAIL — fix $ERRORS error(s)" >&2
  exit 1
elif [ "$WARNINGS" -gt 4 ]; then
  echo "VERDICT: NEEDS REVISION — $WARNINGS warnings exceed threshold (4)" >&2
  exit 1
else
  echo "VERDICT: PASS"
  exit 0
fi
