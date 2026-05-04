#!/usr/bin/env bash
# validate-all.sh — Maintainer harness. Runs every validator against every artifact in this repo.
# Per-artifact validators live inside their owning meta skill:
#   skills/meta/create-or-audit-{skill,agent,hook,claude-md}/lib/validate.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

VAL_SKILL=skills/meta/create-or-audit-skill/lib/validate.sh
VAL_AGENT=skills/meta/create-or-audit-agent/lib/validate.sh
VAL_HOOK=skills/meta/create-or-audit-hook/lib/validate.sh
VAL_CLAUDE_MD=skills/meta/create-or-audit-claude-md/lib/validate.sh

total=0
fails=0

run() {
  local script="$1"
  local target="$2"
  total=$((total + 1))
  if ! bash "$script" "$target" >/dev/null 2>&1; then
    fails=$((fails + 1))
    echo "FAIL: $target"
    bash "$script" "$target" 2>&1 | sed 's/^/    /'
  else
    echo "pass: $target"
  fi
}

shopt -s nullglob

echo "=== Skills ==="
for f in skills/meta/*/SKILL.md skills/workflow/*/SKILL.md skills/documentation/*/SKILL.md skills/planning/*/SKILL.md; do
  run "$VAL_SKILL" "$f"
done

echo ""
echo "=== Agents ==="
for f in agents/examples/*.md; do
  run "$VAL_AGENT" "$f"
done

echo ""
echo "=== Hooks ==="
for f in hooks/examples/*.sh; do
  run "$VAL_HOOK" "$f"
done

echo ""
echo "=== CLAUDE.md files ==="
for f in CLAUDE.md claude-md/examples/*.md; do
  [ -f "$f" ] && run "$VAL_CLAUDE_MD" "$f"
done

echo ""
echo "=== npx skills discovery smoke test ==="
expected=18
if command -v npx >/dev/null 2>&1; then
  # The CLI prints "Found N skills" once it's done discovering. Strip ANSI/box-drawing first.
  found=$(npx --yes skills add . --list 2>&1 | sed -r 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/[^[:print:][:space:]]//g' | grep -oE 'Found [0-9]+ skills' | grep -oE '[0-9]+' | head -1)
  found=${found:-0}
  total=$((total + 1))
  if [ "$found" -eq "$expected" ]; then
    echo "pass: npx skills discovers $found skills (expected $expected)"
  else
    fails=$((fails + 1))
    echo "FAIL: npx skills discovers $found skills, expected $expected"
  fi
else
  echo "skip: npx not installed"
fi

echo ""
echo "=== Summary ==="
echo "Total: $total | Passed: $((total - fails)) | Failed: $fails"

if [ "$fails" -gt 0 ]; then
  exit 1
fi
exit 0
