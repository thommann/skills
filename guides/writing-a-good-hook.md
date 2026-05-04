# Writing a good hook

Companion to [`../skills/meta/create-or-audit-hook/SKILL.md`](../skills/meta/create-or-audit-hook/SKILL.md).

## The three rules

1. **Fast.** Hooks run on every matching tool use. Target sub-second execution.
2. **Silent on irrelevant input.** Exit 0 immediately if the hook doesn't care.
3. **Actionable when blocking.** Exit 2 with a stderr message explaining what to do instead.

Hooks that violate any of these make Claude Code sluggish or inexplicable.

## The event map

| Event | Matcher | Typical use | Example |
|---|---|---|---|
| `PreToolUse` | tool name regex | Block / allow the tool call | `protect-sensitive-files.sh` |
| `PostToolUse` | tool name regex | React to a successful call | `auto-format-python.sh` |
| `Stop` | — | Final gate before completion | `stop-lint-check.sh` |
| `SessionStart` | — | Initialize session state | `session-start.sh` |

Pick the earliest event that lets you do the job. Blocking work in `PostToolUse` is usually too late — the write already happened.

## Parsing the payload

Every hook gets a JSON payload on stdin. Parse once:

```bash
input=$(cat)
[[ -z "$input" ]] && exit 0

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
```

Common fields:

| Field | For | Example value |
|---|---|---|
| `.tool_name` | routing | `"Write"`, `"Edit"`, `"Bash"` |
| `.tool_input.file_path` | Read, Edit, Write | `/path/to/file.py` |
| `.tool_input.command` | Bash | `pnpm test` |
| `.tool_response` | PostToolUse | depends on tool |

## Short-circuit early, short-circuit often

```bash
# Tool not relevant — exit cleanly
case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# No file path — exit cleanly
[[ -z "$file_path" ]] && exit 0

# Wrong file type — exit cleanly
case "$file_path" in
  *.py) ;;
  *) exit 0 ;;
esac
```

Three short-circuits before any real work. This is deliberate — hooks that do expensive processing unconditionally slow every single tool call.

## Tool presence checks

```bash
if ! command -v ruff >/dev/null 2>&1; then
  exit 0
fi
```

**Never exit 1 because a formatter is missing.** The user's local state isn't your hook's problem. Exit 0, silently. Alternatives:

- `command -v <tool>` is the standard check — portable, fast.
- Try `which <tool>` — works on most systems.
- `hash <tool> 2>/dev/null` — POSIX-ish, no stdout pollution.

## Blocking (exit 2)

When a PreToolUse hook decides to block:

```bash
if [[ "$file_path" == *.env ]]; then
  echo "BLOCKED: $file_path is a secrets file." >&2
  echo "Use .env.example for templates. Real secrets go in the secrets manager." >&2
  exit 2
fi
```

Rules:

- **Always print to stderr before exiting 2.** The user sees the stderr; without a message, they see an opaque refusal.
- **Explain what to do instead** (principle 05). "Use .env.example" is actionable; "blocked" is not.
- **Only PreToolUse uses exit 2 meaningfully.** In other events, exit 2 is ambiguous.

## Non-fatal work (exit 0 with logging)

For PostToolUse formatters that fail:

```bash
ruff format "$file_path" >/dev/null 2>&1 || true
```

The `|| true` prevents `set -e` from halting the script. The formatter failing doesn't mean anything important went wrong — maybe the file has a syntax error the user is about to fix.

## Idempotency

Run the hook twice on the same input — should produce the same result. Common violations:

- Appending to a log file on every `SessionStart` — file grows without bound. Add a staleness check or rotate.
- Installing dependencies on every SessionStart — slow. Check if already installed.
- Sending a notification on every `Stop` — spam. Gate on recent changes.

## No network

```bash
# DO NOT DO THIS:
curl -s https://api.example.com/some-check
```

Hooks are in the critical path. A 2-second network call multiplies across every edit. Move network work to a skill the user invokes explicitly.

## Wiring

A hook file without a `settings.json` entry never runs. Common gotcha — shipping a hook and forgetting to enable it.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/auto-format-python.sh" }
        ]
      }
    ]
  }
}
```

Match specificity:

- `"matcher": "Write|Edit"` — only Write and Edit.
- `"matcher": ""` or omitted — all tools.

Prefer specific matchers to reduce unnecessary invocations.

## Pre-ship checklist

- [ ] `bash skills/meta/create-or-audit-hook/lib/validate.sh <path>` exits 0.
- [ ] Shebang `#!/usr/bin/env bash` on line 1.
- [ ] `set -euo pipefail` near the top.
- [ ] Reads from stdin.
- [ ] Short-circuits with `exit 0` for irrelevant tools / file types.
- [ ] If blocking (exit 2), prints an actionable stderr message.
- [ ] Wired in `.claude/settings.json`.
- [ ] Dry-run tested:
  ```bash
  echo '{"tool_name":"Write","tool_input":{"file_path":"test.py","content":"x=1"}}' | bash <hook>
  ```
- [ ] No network calls.
- [ ] Tool-presence checks use `command -v`, not hardcoded paths.

## Anti-patterns

### The silent blocker

```bash
[[ "$file_path" == *.env ]] && exit 2
```

No stderr message. User sees an opaque refusal. Always explain.

### The network hook

```bash
curl -X POST https://slack.example.com/... -d "..."
```

Hooks are not webhooks. Route notifications through your alerting system instead.

### The universal formatter

```bash
black "$file_path"
prettier --write "$file_path"
gofmt -w "$file_path"
rustfmt "$file_path"
```

Runs four tools on every file regardless of type. Filter by extension first, run one tool.

### The state-mutating SessionStart

```bash
# Pulls the latest main on every session
git checkout main && git pull
```

Destructive. A user in the middle of work on a feature branch loses their state. Never mutate checkout state from a hook.

### The slow hook

```bash
npm install   # sometimes
docker compose up -d some-service   # always
```

Takes minutes. Every session. Users will disable the hook. Move heavy init to a one-time script.
