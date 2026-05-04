#!/usr/bin/env bash
# validate-skill.sh — Quality check for a SKILL.md file.
# Adapted from https://github.com/joelbarmettlerUZH/ultrainit.sh/blob/main/scripts/validate-skill.sh
# Usage: bash skills/meta/create-or-audit-skill/lib/validate.sh path/to/SKILL.md
set -euo pipefail

SKILL_PATH="${1:?Usage: validate-skill.sh <path-to-SKILL.md>}"
ERRORS=0
WARNINGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERIC_PHRASES_FILE="${GENERIC_PHRASES_FILE:-$SCRIPT_DIR/generic-phrases.txt}"

if [ ! -f "$SKILL_PATH" ]; then
  echo "ERROR: File not found: $SKILL_PATH" >&2
  exit 1
fi

SKILL_FILE="$(basename "$SKILL_PATH")"
SKILL_DIR="$(basename "$(dirname "$SKILL_PATH")")"

echo "=== Validating skill: $SKILL_DIR ==="

# --- Structural checks ------------------------------------------------------

if [[ "$SKILL_FILE" != "SKILL.md" ]]; then
  echo "ERROR: Skill file must be named exactly 'SKILL.md' (got: $SKILL_FILE)" >&2
  ERRORS=$((ERRORS + 1))
fi

if echo "$SKILL_DIR" | grep -qE '[A-Z _]'; then
  echo "ERROR: Skill folder must use kebab-case (got: $SKILL_DIR)" >&2
  ERRORS=$((ERRORS + 1))
fi

if ! head -1 "$SKILL_PATH" | grep -q '^---$'; then
  echo "ERROR: Missing opening frontmatter delimiter (---) on line 1" >&2
  ERRORS=$((ERRORS + 1))
fi

FRONTMATTER_END=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$SKILL_PATH")
if [ -z "$FRONTMATTER_END" ]; then
  echo "ERROR: Missing closing frontmatter delimiter (---)" >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Required fields --------------------------------------------------------

NAME_VAL=$(grep -m1 '^name:' "$SKILL_PATH" 2>/dev/null | sed 's/^name: *//' | tr -d '"'"'"'' || true)
if [ -z "$NAME_VAL" ]; then
  echo "ERROR: Missing required 'name' field in frontmatter" >&2
  ERRORS=$((ERRORS + 1))
else
  if [ "$NAME_VAL" != "$SKILL_DIR" ]; then
    echo "ERROR: name field ($NAME_VAL) does not match folder ($SKILL_DIR)" >&2
    ERRORS=$((ERRORS + 1))
  fi
  if echo "$NAME_VAL" | grep -qE '[A-Z _]'; then
    echo "ERROR: name field must be kebab-case (got: $NAME_VAL)" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

DESC_LINE=$(grep -n '^description:' "$SKILL_PATH" 2>/dev/null | head -1 | cut -d: -f1 || true)
if [ -z "$DESC_LINE" ]; then
  echo "ERROR: Missing required 'description' field in frontmatter" >&2
  ERRORS=$((ERRORS + 1))
else
  # Read description — single line or folded/indented block
  DESC=$(awk -v start="$DESC_LINE" -v end="${FRONTMATTER_END:-9999}" '
    NR==start { sub(/^description: *>?-?/, ""); desc=$0; next }
    NR>start && NR<end && /^  / { sub(/^  /, ""); desc=desc " " $0; next }
    NR>start && NR<end && /^[a-zA-Z_-]+:/ { exit }
    NR>=end { exit }
    END { print desc }
  ' "$SKILL_PATH")

  DESC_LEN=${#DESC}
  if [ "$DESC_LEN" -gt 1024 ]; then
    echo "ERROR: description is $DESC_LEN chars (limit: 1024)" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # Angle brackets in the description break YAML parsers downstream.
  if echo "$DESC" | grep -qE '[<>]'; then
    echo "ERROR: description contains angle brackets (< or >). Use parentheses or quotes instead." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if ! echo "$DESC" | grep -qiE '(use when|use for|use proactively|invoke|trigger|user says)'; then
    echo "WARNING: description may be missing trigger phrases (use when, invoke, ...)" >&2
    WARNINGS=$((WARNINGS + 1))
  fi

  if ! echo "$DESC" | grep -qiE '(do not use|don.t use|not for|instead use|do not trigger)'; then
    echo "WARNING: description missing negative scope (WHEN NOT to use)" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# --- Content checks ---------------------------------------------------------

TOTAL_LINES=$(wc -l < "$SKILL_PATH")
WORD_COUNT=$(wc -w < "$SKILL_PATH")

if [ "$TOTAL_LINES" -gt 600 ]; then
  echo "WARNING: skill is $TOTAL_LINES lines (>600). Consider splitting into multiple skills." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# File references: backtick-wrapped path-like strings OR mentions of common source dirs.
PATH_REFS=$(grep -cE '(`[a-zA-Z_./-]+/[a-zA-Z_.-]+`|`[A-Z][A-Za-z0-9_.]+\.(md|ts|tsx|js|jsx|py|go|rs|java|rb|sh|json|yaml|yml)`|apps/|packages/|src/|backend/|frontend/|scripts/|lib/|tests/|docs/|\.claude/|\.github/)' "$SKILL_PATH" 2>/dev/null || true)
PATH_REFS=${PATH_REFS:-0}

echo "Size: $TOTAL_LINES lines, ~$WORD_COUNT words"
echo "Codebase-specific references: $PATH_REFS"

if [ "$PATH_REFS" -lt 3 ]; then
  echo "ERROR: Fewer than 3 codebase-specific references ($PATH_REFS). Skill is too generic." >&2
  ERRORS=$((ERRORS + 1))
fi

# Required body sections
if ! grep -qiE '^## (verif|verify|check|test|validate|confirm)' "$SKILL_PATH"; then
  echo "WARNING: no '## Verify' (or similar) section found" >&2
  WARNINGS=$((WARNINGS + 1))
fi

if ! grep -qiE '^## (common mistakes|troubleshoot|pitfalls|gotchas)' "$SKILL_PATH"; then
  echo "WARNING: no '## Common Mistakes' (or similar) section found" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Generic phrases — strip backtick-delimited and double-quoted content first.
# A phrase inside `...` or "..." is a mention (pedagogical), not a usage.
GENERIC_COUNT=0
if [ -f "$GENERIC_PHRASES_FILE" ]; then
  GENERIC_COUNT=$(sed -E 's/`[^`]*`//g; s/"[^"]*"//g' "$SKILL_PATH" | grep -ciEf "$GENERIC_PHRASES_FILE" 2>/dev/null || true)
  GENERIC_COUNT=${GENERIC_COUNT:-0}
  if [ "$GENERIC_COUNT" -gt 2 ]; then
    echo "WARNING: Found $GENERIC_COUNT banned generic phrases (threshold: 2). See $GENERIC_PHRASES_FILE." >&2
    WARNINGS=$((WARNINGS + 1))
  fi
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
