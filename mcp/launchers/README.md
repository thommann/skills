# MCP launcher scripts

Per-server bash wrappers. Each is a thin script that:

1. Checks for prerequisites (required binary, required env var).
2. **Silently exits 0 if prerequisites are missing** — so missing local state degrades gracefully.
3. Injects env vars with a project-specific prefix.
4. `exec`s the MCP server, inheriting stdio.

Launchers are referenced from `.claude/settings.json` under `mcpServers`, or launched automatically when `enableAllProjectMcpServers: true`.

## Why launcher scripts vs a single `mcp.json`?

Either works. Pick launchers when:

- A server needs **conditional availability** per developer (e.g., the DB proxy only runs on team members with VPN).
- A server needs **setup before launch** — port-forwarding, vault-unlocking, starting a sidecar.
- You want **per-server logging** to a dedicated file for debugging.
- You want **version pinning** controlled per script (a script can `npx @pkg@1.2.3` while others float to latest).

Otherwise, [`../mcp.json.template`](../mcp.json.template) is simpler.

## Contents

- [`TEMPLATE.sh`](TEMPLATE.sh) — annotated skeleton. Copy this and adapt.
- [`mcp-context7.sh`](mcp-context7.sh) — library documentation lookup.
- [`mcp-github.sh`](mcp-github.sh) — GitHub API (requires PAT via `GITHUB_PERSONAL_ACCESS_TOKEN`).
- [`mcp-playwright.sh`](mcp-playwright.sh) — browser automation.
- [`mcp-postgres.sh`](mcp-postgres.sh) — Postgres read access (requires `POSTGRES_URL`).
- [`mcp-mongodb.sh`](mcp-mongodb.sh) — MongoDB read access (requires `MONGODB_URI`).
- [`mcp-filesystem.sh`](mcp-filesystem.sh) — sandboxed filesystem access (paths via env).
- [`mcp-fetch.sh`](mcp-fetch.sh) — HTTP fetch with allowlisting.
- [`mcp-slack.sh`](mcp-slack.sh) — Slack workspace integration.
- [`mcp-sentry.sh`](mcp-sentry.sh) — Sentry error tracking.
- [`mcp-custom-api.sh.template`](mcp-custom-api.sh.template) — template for a project-owned REST/OpenAPI MCP.
- [`mcp-custom-db.sh.template`](mcp-custom-db.sh.template) — template for any DB with a connection string.

## Wiring in `settings.json`

```json
{
  "mcpServers": {
    "context7":   { "command": "bash", "args": [".claude/mcp/mcp-context7.sh"] },
    "github":     { "command": "bash", "args": [".claude/mcp/mcp-github.sh"] },
    "playwright": { "command": "bash", "args": [".claude/mcp/mcp-playwright.sh"] }
  }
}
```

Or enable all of them with `"enableAllProjectMcpServers": true`.

## Convention: where launchers live

In a project that adopts this pattern, launchers typically go under `.claude/mcp/` (not `.claude/mcp/launchers/` — that's only this library's internal organization). Adjust paths in `settings.json` accordingly when copying.

## Security posture

- **No tokens inline in launcher scripts.** Tokens come from env vars. The hook [`../../hooks/examples/protect-sensitive-files.sh`](../../hooks/examples/protect-sensitive-files.sh) prevents accidental reads of `.env` files.
- **Read-only by default** where the MCP server supports it — e.g., postgres and mongodb launchers use read-only connection strings.
- **Silent exit 0 on missing prerequisites** — a launcher failing `exit 1` blocks Claude Code. Missing env vars should degrade; they should not halt work.

## Versioning

The shipped launchers use `npx -y <package>` which pulls the latest version on each invocation. To pin:

```bash
exec npx -y @modelcontextprotocol/server-github@0.4.2 "$@"
```

Pin when the project needs stable MCP behavior (e.g., in a team setting where everyone must see the same schema).
