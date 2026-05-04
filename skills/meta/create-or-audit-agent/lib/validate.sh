#!/usr/bin/env bash
# validate-agent.sh — Quality check for a subagent .md file.
# Adapted from https://github.com/joelbarmettlerUZH/ultrainit.sh/blob/main/scripts/validate-subagent.sh
# Usage: bash skills/meta/create-or-audit-agent/lib/validate.sh path/to/agent.md
set -euo pipefail

AGENT_PATH="${1:?Usage: validate-agent.sh <path-to-agent.md>}"
ERRORS=0
WARNINGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERIC_PHRASES_FILE="${GENERIC_PHRASES_FILE:-$SCRIPT_DIR/generic-phrases.txt}"

if [ ! -f "$AGENT_PATH" ]; then
  echo "ERROR: File not found: $AGENT_PATH" >&2
  exit 1
fi

AGENT_NAME=$(basename "$AGENT_PATH" .md)

echo "=== Validating agent: $AGENT_NAME ==="

# --- Structural checks ------------------------------------------------------

if [[ "$AGENT_PATH" != *.md ]]; then
  echo "ERROR: Agent file must have .md extension" >&2
  ERRORS=$((ERRORS + 1))
fi

if echo "$AGENT_NAME" | grep -qE '[A-Z _]'; then
  echo "WARNING: Agent filename should use lowercase-with-hyphens (got: $AGENT_NAME)" >&2
  WARNINGS=$((WARNINGS + 1))
fi

if ! head -1 "$AGENT_PATH" | grep -q '^---$'; then
  echo "ERROR: Missing opening frontmatter delimiter (---)" >&2
  ERRORS=$((ERRORS + 1))
fi

FRONTMATTER_END=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$AGENT_PATH")
if [ -z "$FRONTMATTER_END" ]; then
  echo "ERROR: Missing closing frontmatter delimiter (---)" >&2
  ERRORS=$((ERRORS + 1))
fi

# --- Required fields --------------------------------------------------------

NAME_VAL=$(grep -m1 '^name:' "$AGENT_PATH" 2>/dev/null | sed 's/^name: *//' | tr -d '"'"'"'' || true)
if [ -z "$NAME_VAL" ]; then
  echo "ERROR: Missing required 'name' field in frontmatter" >&2
  ERRORS=$((ERRORS + 1))
else
  if echo "$NAME_VAL" | grep -qE '[A-Z _]'; then
    echo "WARNING: name field should use lowercase-with-hyphens (got: $NAME_VAL)" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
  if [ "$NAME_VAL" != "$AGENT_NAME" ]; then
    echo "WARNING: name field ($NAME_VAL) does not match filename ($AGENT_NAME)" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

DESC_LINE=$(grep -n '^description:' "$AGENT_PATH" 2>/dev/null | head -1 | cut -d: -f1 || true)
DESC=""
if [ -z "$DESC_LINE" ]; then
  echo "ERROR: Missing required 'description' field in frontmatter" >&2
  ERRORS=$((ERRORS + 1))
else
  DESC=$(awk -v start="$DESC_LINE" -v end="${FRONTMATTER_END:-9999}" '
    NR==start { sub(/^description: *>?-?/, ""); desc=$0; next }
    NR>start && NR<end && /^  / { sub(/^  /, ""); desc=desc " " $0; next }
    NR>start && NR<end && /^[a-zA-Z_-]+:/ { exit }
    NR>=end { exit }
    END { print desc }
  ' "$AGENT_PATH")

  DESC_LEN=${#DESC}
  if [ "$DESC_LEN" -gt 1024 ]; then
    echo "ERROR: description is $DESC_LEN chars (limit: 1024)" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if echo "$DESC" | grep -qE '[<>]'; then
    echo "ERROR: description contains angle brackets (< or >). Use parentheses or quotes instead." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if ! echo "$DESC" | grep -qiE '(use when|use for|use proactively|invoke|trigger|user says)'; then
    echo "WARNING: description may be missing trigger phrases" >&2
    WARNINGS=$((WARNINGS + 1))
  fi

  if ! echo "$DESC" | grep -qiE '(do not use|don.t use|not for|instead use)'; then
    echo "WARNING: description missing negative scope (WHEN NOT to use)" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# --- Body length ------------------------------------------------------------

if [ -n "$FRONTMATTER_END" ]; then
  BODY_WORDS=$(tail -n +"$FRONTMATTER_END" "$AGENT_PATH" | tail -n +2 | wc -w)
  if [ "$BODY_WORDS" -lt 20 ]; then
    echo "WARNING: System prompt body is very short ($BODY_WORDS words). Subagents need self-contained context." >&2
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# --- Model field ------------------------------------------------------------

MODEL_VAL=$(grep -m1 '^model:' "$AGENT_PATH" 2>/dev/null | sed 's/^model: *//' | tr -d '"'"'"'' || true)
if [ -n "$MODEL_VAL" ]; then
  case "$MODEL_VAL" in
    sonnet|opus|haiku|inherit) ;;
    *)
      echo "WARNING: Unusual model value '$MODEL_VAL'. Expected: sonnet, opus, haiku, or inherit" >&2
      WARNINGS=$((WARNINGS + 1))
      ;;
  esac
fi

# --- Permissions ------------------------------------------------------------

if grep -q 'permissionMode.*bypassPermissions' "$AGENT_PATH"; then
  echo "WARNING: bypassPermissions is set. Ensure this is intentional and sandboxed." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# --- Tool scope (read-only enforcement for review/analyze/audit agents) -----

TOOLS_VAL=$(grep -m1 '^tools:' "$AGENT_PATH" 2>/dev/null | sed 's/^tools: *//' || true)
IS_READONLY_INTENT=false
if echo "${DESC:-}" | grep -qiE '(review|analyze|scan|audit|check|research|explore)' && \
   ! echo "${DESC:-}" | grep -qiE '(fix|implement|create|write|modify|update|edit)'; then
  IS_READONLY_INTENT=true
fi

if [ "$IS_READONLY_INTENT" = true ]; then
  if [ -z "$TOOLS_VAL" ]; then
    echo "WARNING: Agent appears read-only but no 'tools' field set (inherits all). Restrict tools." >&2
    WARNINGS=$((WARNINGS + 1))
  elif echo "$TOOLS_VAL" | grep -qiE '(Write|Edit)'; then
    echo "ERROR: Read-only reviewer agent has Write/Edit tools — violates least privilege." >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# --- Codebase specificity ---------------------------------------------------

TOTAL_LINES=$(wc -l < "$AGENT_PATH")
WORD_COUNT=$(wc -w < "$AGENT_PATH")
PATH_REFS=$(grep -cE '(`[a-zA-Z_./-]+/[a-zA-Z_.-]+`|`[A-Z][A-Za-z0-9_.]+\.(md|ts|tsx|js|jsx|py|go|rs|java|rb|sh|json|yaml|yml)`|apps/|packages/|src/|backend/|frontend/|scripts/|lib/|tests/|docs/|\.claude/|\.github/)' "$AGENT_PATH" 2>/dev/null || true)
PATH_REFS=${PATH_REFS:-0}

echo "Size: $TOTAL_LINES lines, ~$WORD_COUNT words"
echo "Codebase-specific references: $PATH_REFS"

if [ "$PATH_REFS" -lt 3 ]; then
  echo "WARNING: Fewer than 3 codebase-specific references. Agent may be too generic." >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Generic phrases — strip backtick-delimited and double-quoted content first.
GENERIC_COUNT=0
if [ -f "$GENERIC_PHRASES_FILE" ]; then
  GENERIC_COUNT=$(sed -E 's/`[^`]*`//g; s/"[^"]*"//g' "$AGENT_PATH" | grep -ciEf "$GENERIC_PHRASES_FILE" 2>/dev/null || true)
  GENERIC_COUNT=${GENERIC_COUNT:-0}
  if [ "$GENERIC_COUNT" -gt 2 ]; then
    echo "WARNING: Found $GENERIC_COUNT banned generic phrases (threshold: 2)." >&2
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
