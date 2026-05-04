---
name: create-or-audit-hook
description: >
  Creates or audits a Claude Code hook. Use when user says 'add a hook', 'create a hook',
  'review our hooks', 'audit hooks', 'wire up a format-on-save hook', 'block edits to secrets',
  or 'our hooks are broken'. Do NOT use for skills (use create-or-audit-skill), agents
  (use create-or-audit-agent), or settings (edit `settings.json` directly).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Create or audit a hook

Hooks are deterministic gates bash-scripted against Claude Code events. Use them for things that must run every time, fast.

## Before You Start

- `skills/meta/create-or-audit-hook/templates/hook.sh` — annotated blank hook with stdin parsing, dispatch, and exit-code examples.
- `skills/meta/create-or-audit-hook/lib/validate.sh` — mechanical checks (shebang, pipefail, stdin read, stderr-when-blocking).
- Event taxonomy: `PreToolUse` (block before tool runs), `PostToolUse` (act after tool runs), `Stop` (gate session end), `SessionStart` (warm caches). Exit codes: `0` allow, `2` block + stderr message.

## Mode 1 — build a new hook

### Step 1: pick the event

| You want... | Event | Matcher |
|---|---|---|
| Block a write to protected files | `PreToolUse` | `Write\|Edit` |
| Refuse a dangerous shell command | `PreToolUse` | `Bash` |
| Format a file after editing | `PostToolUse` | `Write\|Edit` |
| Run typecheck before "done" | `Stop` | — |
| Warm caches at session start | `SessionStart` | — |

If the rule isn't deterministic (requires judgment), it's not a hook — it's a skill.

### Step 2: copy the template

```bash
cp .claude/skills/meta/create-or-audit-hook/templates/hook.sh .claude/hooks/{hook-name}.sh
chmod +x .claude/hooks/{hook-name}.sh
```

### Step 3: fill in the logic

Enforce these rules:

- `#!/usr/bin/env bash` + `set -euo pipefail` at the top.
- Read JSON from stdin: `input=$(cat)`.
- Short-circuit `exit 0` on empty input, wrong tool, or irrelevant file type.
- If blocking (`exit 2`), print an actionable message to stderr: `echo "BLOCKED: reason + instead" >&2`.
- Check for tool presence with `command -v` before running an external tool. **Never `exit 1` because a formatter is missing** — the user's local state isn't your hook's concern.

### Step 4: wire it in `settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": ".claude/hooks/{hook-name}.sh" }]
      }
    ]
  }
}
```

Without wiring, the hook file exists but never runs — the #1 cause of "my hook doesn't work."

### Step 5: run the validator

```bash
bash skills/meta/create-or-audit-hook/lib/validate.sh .claude/hooks/{hook-name}.sh
```

### Step 6: dry-run

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"test.py","content":"x"}}' | \
  bash .claude/hooks/{hook-name}.sh
```

Confirm: relevant input acts; irrelevant input (wrong tool, wrong filetype) exits 0 silently.

## Mode 2 — audit hooks

### Step 1: structural on each

```bash
for f in .claude/hooks/*.sh; do
  echo "=== $f ==="
  bash skills/meta/create-or-audit-hook/lib/validate.sh "$f" | tail -5
done
```

### Step 2: five gates

**Gate 1 — wiring.** Every hook file has a matching entry in `settings.json`. Orphans are dead code:

```bash
jq -r '.hooks | to_entries[] | .value[] | .hooks[]?.command' .claude/settings.json \
  | grep -oE '[^/]+\.sh$' | sort -u > /tmp/wired.txt
ls .claude/hooks/*.sh | xargs -n1 basename | sort > /tmp/exists.txt
comm -23 /tmp/exists.txt /tmp/wired.txt    # hooks that exist but are not wired
comm -13 /tmp/exists.txt /tmp/wired.txt    # wirings that point to missing hooks
```

**Gate 2 — tool presence checks.** `PostToolUse` formatters must check for the tool (`command -v ruff >/dev/null 2>&1 || exit 0`) before running. Missing this makes the hook break silently on machines without the formatter.

**Gate 3 — blocking discipline.** `exit 2` without `>&2` output is broken. The user sees no message, only a refusal.

**Gate 4 — no network.** `curl`, `wget`, `fetch` in a hook means every tool call pays that latency. Move network-dependent work to a skill or a manual command.

**Gate 5 — idempotency.** Running the hook twice on the same input has the same effect. A `SessionStart` hook that appends to a log without a staleness check breaks idempotency.

### Step 3: report

```markdown
## Hooks Audit

### Verdict per hook
| Hook | Event | Wired? | Validator | Gates |
|---|---|---|---|---|
| protect-sensitive-files.sh | PreToolUse | yes | PASS | all |
| ... |

### Orphan hooks (remove or wire)
...

### Broken wirings (point to missing files)
...

### Proposed additions (hooks the codebase would benefit from)
...
```

## Verify

```bash
bash skills/meta/create-or-audit-hook/lib/validate.sh .claude/hooks/{name}.sh
# Expected: VERDICT: PASS

# Dry-run with a representative payload
echo '{"tool_name":"Write","tool_input":{"file_path":"x.py"}}' | bash .claude/hooks/{name}.sh
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Hook file exists but isn't in `settings.json` | Wire it. Claude Code only runs what's declared. |
| `exit 1` when a formatter is missing | `exit 0` instead. Missing local tooling should not block Claude's work. |
| `exit 2` with no stderr message | Add `echo "BLOCKED: reason + use X instead" >&2` before the `exit 2`. |
| Reading `.tool_input.command` for a Write hook | Write's payload is `.tool_input.file_path`. Use `.command` only for `Bash`. |
