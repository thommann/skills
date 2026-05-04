#!/usr/bin/env bash
# Hook: stop-lint-check
# Event: Stop
#
# Final gate before Claude declares "done". Runs project lint / typecheck and
# reports failures to stderr, which Claude sees. This turns silent breakage
# into a visible fix-it-before-stop signal.
#
# Do NOT exit 2 here — Stop hooks can't block completion, and exit 2 is
# reserved for PreToolUse. Exit 0 even on lint failures; the stderr output is
# what Claude picks up.

set -euo pipefail

input=$(cat || true)
[[ -z "$input" ]] && exit 0

# Only run if we detected recent edits this session. The Stop event fires on
# every turn including pure-Q&A turns — running lint every time is wasteful.
# If the payload includes an 'edited' hint, respect it; otherwise default to running.
# (Claude Code's Stop payload format varies; adapt as needed.)

failures=0

run_check() {
  local name="$1"; shift
  if "$@" >/tmp/stop-check-$$.log 2>&1; then
    return 0
  else
    echo "[stop-lint-check] $name FAILED:" >&2
    sed 's/^/  /' /tmp/stop-check-$$.log >&2
    failures=$((failures + 1))
  fi
  rm -f /tmp/stop-check-$$.log
}

# Adapt this block to your project's lint/typecheck commands.
# Each gate checks for tool presence first; missing tools are skipped.
if [[ -f pyproject.toml ]] && command -v ruff >/dev/null 2>&1; then
  run_check "ruff check" ruff check
fi

if [[ -f tsconfig.json ]] && command -v npx >/dev/null 2>&1; then
  if npx --no-install tsc --version >/dev/null 2>&1; then
    run_check "tsc --noEmit" npx --no-install tsc --noEmit
  fi
fi

if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then
  run_check "go vet" go vet ./...
fi

if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then
  run_check "cargo check" cargo check --quiet
fi

if [[ $failures -gt 0 ]]; then
  echo "[stop-lint-check] $failures gate(s) failed. Address before declaring done." >&2
fi

exit 0
