# Hooks

Hooks are bash scripts Claude Code runs on specific events. They are **deterministic gates** — not orchestration. Use them when:

- The check is fast (runs in under a second).
- The decision is mechanical (block vs allow; format vs skip).
- It must run every single time, not on invocation.

Everything else is a skill.

## Events

| Event | When it fires | Typical use |
|---|---|---|
| `PreToolUse` | Before any tool call | Block writes to protected files; refuse dangerous commands |
| `PostToolUse` | After a tool call succeeds | Auto-format a file that was just edited |
| `Stop` | When Claude finishes a response | Final lint/typecheck before the user sees "done" |
| `SessionStart` | When a new Claude session begins | Warm caches, install deps, sync local state |

Hooks are wired in `settings.json` under `hooks.<Event>[].hooks[].command`.

## Schema (enforced by `skills/meta/create-or-audit-hook/lib/validate.sh`)

Every hook MUST:

1. Start with `#!/usr/bin/env bash` on line 1.
2. Include `set -euo pipefail` near the top.
3. Read JSON from stdin (Claude Code sends a payload to every hook).
4. Handle empty/irrelevant input by exiting `0` early — never block work you don't care about.
5. When blocking (`exit 2`), print an actionable message to stderr (`echo "..." >&2`).
6. Have a matching wiring entry in `settings.json` — an orphan hook file won't run.

## The input payload

Claude Code passes a JSON object on stdin. Common fields:

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.ts",
    "content": "..."
  },
  "tool_response": "..."   // only for PostToolUse
}
```

Extract fields with `jq`. See [the meta hook template](../skills/meta/create-or-audit-hook/templates/hook.sh) for the canonical parse-and-dispatch shape.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success, or irrelevant input — tool proceeds |
| `2` | Blocking error (PreToolUse): tool is refused; stderr is shown |
| other | Hook itself errored; Claude Code logs it but does not block by default |

## Design rules

- **Never block on a missing tool.** If `ruff` is not installed, a PostToolUse formatting hook should exit `0`, not `1` — missing tooling on this machine is not the user's problem.

  ```bash
  command -v ruff >/dev/null 2>&1 || exit 0
  ```

- **Short-circuit loudly, act quietly.** If the hook is not relevant (wrong tool, wrong file type), exit `0` immediately with no output. If it acts, the output is OK but keep it terse.

- **Blocking hooks explain the block.** `echo "BLOCKED: reason + what to do instead" >&2` — tell the user what went wrong and how to proceed (principle 05).

- **No network calls in hooks.** They run on every tool use; network slowness will make the whole session sluggish.

## Included examples

- [`examples/protect-sensitive-files.sh`](examples/protect-sensitive-files.sh) — PreToolUse; blocks reads/edits of `.env`, `.pem`, `.key`, `credentials.*`
- [`examples/auto-format-python.sh`](examples/auto-format-python.sh) — PostToolUse; runs `ruff format` on edited `.py` files
- [`examples/auto-format-javascript.sh`](examples/auto-format-javascript.sh) — PostToolUse; `prettier` / `eslint --fix`
- [`examples/auto-format-markdown.sh`](examples/auto-format-markdown.sh) — PostToolUse; `mdformat`
- [`examples/auto-format-yaml.sh`](examples/auto-format-yaml.sh) — PostToolUse; `yamlfix`
- [`examples/auto-format-go.sh`](examples/auto-format-go.sh) — PostToolUse; `gofmt -w`
- [`examples/auto-format-rust.sh`](examples/auto-format-rust.sh) — PostToolUse; `rustfmt`
- [`examples/session-start.sh`](examples/session-start.sh) — SessionStart; warm project state
- [`examples/stop-lint-check.sh`](examples/stop-lint-check.sh) — Stop; final lint gate

## Validation

```bash
bash skills/meta/create-or-audit-hook/lib/validate.sh examples/protect-sensitive-files.sh
for f in examples/*.sh; do bash skills/meta/create-or-audit-hook/lib/validate.sh "$f" || exit 1; done
```
