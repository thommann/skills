#!/usr/bin/env bash
# validate-hook.sh — Quality check for a Claude Code hook .sh file.
# Adapted from the validate_hook function in
#   https://github.com/joelbarmettlerUZH/ultrainit.sh/blob/main/lib/validate.sh
# Usage: bash validation/validate-hook.sh path/to/hook.sh
set -euo pipefail

HOOK_PATH="${1:?Usage: validate-hook.sh <path-to-hook.sh>}"
ERRORS=0
WARNINGS=0

if [ ! -f "$HOOK_PATH" ]; then
  echo "ERROR: File not found: $HOOK_PATH" >&2
  exit 1
fi

HOOK_NAME="$(basename "$HOOK_PATH")"

echo "=== Validating hook: $HOOK_NAME ==="

# --- Shebang ----------------------------------------------------------------

FIRST_LINE=$(head -1 "$HOOK_PATH")
if ! echo "$FIRST_LINE" | grep -q '^#!/'; then
  echo "ERROR: Missing shebang on line 1. Expected '#!/usr/bin/env bash'." >&2
  ERRORS=$((ERRORS + 1))
elif ! echo "$FIRST_LINE" | grep -qE '/(env )?bash'; then
  echo "WARNING: Shebang is '$FIRST_LINE' — prefer '#!/usr/bin/env bash' for portability." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# --- set -euo pipefail ------------------------------------------------------

if ! grep -q 'set -euo pipefail' "$HOOK_PATH"; then
  if grep -qE 'set -[eu]' "$HOOK_PATH"; then
    echo "WARNING: Hook uses partial 'set' flags. Prefer the full 'set -euo pipefail'." >&2
    WARNINGS=$((WARNINGS + 1))
  else
    echo "ERROR: Missing 'set -euo pipefail'. Hooks must fail loudly on errors." >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# --- Reads JSON from stdin --------------------------------------------------

if ! grep -qE '(cat\b|read |stdin|/dev/stdin|jq |< /dev/)' "$HOOK_PATH"; then
  echo "ERROR: Hook does not appear to read JSON from stdin. Claude Code sends a JSON payload to every hook." >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Blocking hooks must print to stderr ------------------------------------

if grep -q 'exit 2' "$HOOK_PATH"; then
  if ! grep -qE '(echo|printf|>&2)' "$HOOK_PATH"; then
    echo "ERROR: Hook uses 'exit 2' (blocking) but never writes to stderr. Print an actionable message before blocking." >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# --- Short-circuit on irrelevant input --------------------------------------

if ! grep -qE '(exit 0$|exit 0 *$|exit 0 *;)' "$HOOK_PATH"; then
  echo "WARNING: No explicit 'exit 0' short-circuit. Hooks should exit 0 silently when the input is not relevant." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# --- No obvious network calls -----------------------------------------------

if grep -qE '(curl |wget |fetch |http_request)' "$HOOK_PATH"; then
  echo "WARNING: Hook appears to make network calls. Hooks run on every tool use; network latency compounds." >&2
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
elif [ "$WARNINGS" -gt 3 ]; then
  echo "VERDICT: NEEDS REVISION — $WARNINGS warnings exceed threshold (3)" >&2
  exit 1
else
  echo "VERDICT: PASS"
  exit 0
fi
