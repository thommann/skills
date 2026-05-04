#!/usr/bin/env bash
# validate-all.sh — Run every validator against every artifact in this repo.
# Skips scaffolding/debugging/reference skills (they're templates with placeholders).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

total=0
fails=0

run() {
  local script="$1"
  local target="$2"
  total=$((total + 1))
  if ! bash "$script" "$target" >/dev/null 2>&1; then
    fails=$((fails + 1))
    echo "FAIL: $target"
    # Re-run with output for detail
    bash "$script" "$target" 2>&1 | sed 's/^/    /'
  else
    echo "pass: $target"
  fi
}

shopt -s nullglob

echo "=== Skills ==="
# Portable skills — must pass. Scaffolding/debugging/reference contain {{PLACEHOLDERS}} and are skipped.
for f in skills/meta/*/SKILL.md skills/workflow/*/SKILL.md skills/documentation/*/SKILL.md skills/planning/*/SKILL.md; do
  run "$SCRIPT_DIR/validate-skill.sh" "$f"
done

echo ""
echo "=== Agents ==="
for f in agents/examples/*.md; do
  run "$SCRIPT_DIR/validate-agent.sh" "$f"
done

echo ""
echo "=== Hooks ==="
for f in hooks/examples/*.sh; do
  run "$SCRIPT_DIR/validate-hook.sh" "$f"
done

echo ""
echo "=== CLAUDE.md files ==="
for f in CLAUDE.md claude-md/examples/*.md; do
  [ -f "$f" ] && run "$SCRIPT_DIR/validate-claude-md.sh" "$f"
done

echo ""
echo "=== Summary ==="
echo "Total: $total | Passed: $((total - fails)) | Failed: $fails"

if [ "$fails" -gt 0 ]; then
  exit 1
fi
exit 0
