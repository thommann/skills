# Settings

`.claude/settings.json` is Claude Code's project-local config. It wires hooks, sets permission rules, picks a default model, configures the status line, and enables MCP servers.

## Contents

- [`settings.json.template`](settings.json.template) — annotated minimal scaffold
- [`examples/minimal.json`](examples/minimal.json) — smallest workable settings (no hooks, default model)
- [`examples/full-featured.json`](examples/full-featured.json) — all library hooks wired, generous permissions, statusline enabled
- [`examples/locked-down.json`](examples/locked-down.json) — conservative permissions for untrusted environments

## Key sections

### `model`

Sets the default model for this project. Examples: `"claude-opus-4-7"`, `"claude-sonnet-4-6"`, `"claude-haiku-4-5-20251001"`.

### `permissions`

Explicit allow/deny for tools, shell commands, and MCP calls. Format:

```json
{
  "permissions": {
    "allow": ["Bash(git status:*)", "Bash(pnpm test:*)", "Skill(*)", "Read", "Edit", "Write"],
    "deny":  ["Bash(rm -rf:*)", "Bash(git push:-f*)"]
  }
}
```

Patterns match against the tool invocation. `Bash(git:*)` allows `git <anything>`. Principle: allow the categories your workflow needs; deny the few that are destructive.

### `hooks`

Wires the scripts in `.claude/hooks/` to events:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": ".claude/hooks/protect-sensitive-files.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": ".claude/hooks/auto-format-python.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": ".claude/hooks/stop-lint-check.sh" }] }
    ]
  }
}
```

Every hook file in `.claude/hooks/` needs a matching entry here — otherwise it never runs.

### `statusLine`

```json
{ "statusLine": { "type": "command", "command": ".claude/statusline.sh" } }
```

### `enableAllProjectMcpServers` and `mcpServers` (or `mcp.json`)

See [`../mcp/README.md`](../mcp/README.md) for the two patterns.

## Merging into an existing `settings.json`

Use `jq` deep-merge (principle 07 — safe-merge):

```bash
jq -s '.[0] * .[1]' ~/myproject/.claude/settings.json settings/examples/full-featured.json > /tmp/merged.json
# Review /tmp/merged.json, then move it into place.
```

## Permission profile cheat sheet

| Profile | Who for | Notable allows | Notable denies |
|---|---|---|---|
| `minimal` | Trying the library out | `Read`, `Skill(*)`, a few git commands | Destructive bash, network writes |
| `full-featured` | Daily development | Everything in minimal + `Write`, `Edit`, `Bash(pnpm:*)`, `Bash(make:*)`, `Bash(gh:*)` | `rm -rf`, `git push --force` to main |
| `locked-down` | Untrusted code, student mode, CI agents | `Read`, `Grep`, `Glob` only | Everything else |
