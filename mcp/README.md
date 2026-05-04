# MCP (Model Context Protocol)

MCP servers extend Claude Code with external tools: database access, GitHub API, browser automation, observability, library-docs lookup. This directory ships both MCP configuration patterns and explains when to use each.

## Two patterns

### Pattern A — single `mcp.json`

One JSON file lists every MCP server with its launch command and env vars. Simple, declarative, portable between machines.

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}" }
    }
  }
}
```

**Use when:** every developer has the same MCP toolkit; env vars come from a root `.env`; no custom startup logic per server.

See [`mcp.json.template`](mcp.json.template) and [`mcp.json.examples/`](mcp.json.examples/).

### Pattern B — per-server launcher scripts

One bash wrapper per MCP server, referenced from `settings.json`. More code, more flexibility.

```bash
#!/usr/bin/env bash
# .claude/mcp/mcp-postgres.sh
set -euo pipefail
[[ -n "${POSTGRES_URL-}" ]] || { echo "POSTGRES_URL unset; skipping postgres MCP" >&2; exit 0; }
exec npx -y @modelcontextprotocol/server-postgres "$POSTGRES_URL"
```

**Use when:**
- Each MCP needs a different env var prefix or setup (port-forwarding, vault unlock).
- Some MCPs are optional per developer — the launcher exits 0 silently when prerequisites are missing.
- You want per-server logging or version pinning.

See [`launchers/`](launchers/).

## Trade-offs

| | `mcp.json` | Launcher scripts |
|---|---|---|
| Simplicity | ✓ simpler | — |
| Version pinning | weak (npx grabs latest) | strong (scripts can pin) |
| Conditional availability | no | yes (exit 0 if env missing) |
| Per-server logging | — | ✓ |
| Cross-team portability | ✓ (just JSON) | needs shared scripts |
| Custom setup (port-forward, vault) | no | yes |

If in doubt, start with `mcp.json`. Migrate to launchers if you hit a limitation.

## Server packages worth knowing

| Package | Use |
|---|---|
| `@upstash/context7-mcp` | library documentation lookup (any language) |
| `@modelcontextprotocol/server-github` | GitHub API (issues, PRs, actions) |
| `@modelcontextprotocol/server-playwright` | browser automation |
| `@modelcontextprotocol/server-postgres` | Postgres read access |
| `@modelcontextprotocol/server-filesystem` | sandboxed filesystem access |
| `@modelcontextprotocol/server-fetch` | HTTP fetch with allowlists |
| `@modelcontextprotocol/server-slack` | Slack workspace integration |
| `@sentry/mcp-server` | Sentry error tracking |
| `mongodb-mcp-server` | MongoDB read access |

Check each package's README for current env-var names and CLI shape; MCPs evolve fast.

## Security posture

- **Env vars, never inline.** No MCP config file in this library contains a real token.
- **Read-only by default.** Database MCPs in the examples launch with read-only flags where the package supports it. Elevate deliberately.
- **`.env` is gitignored.** Adopters should confirm before their first commit.

See [`../hooks/examples/protect-sensitive-files.sh`](../hooks/examples/protect-sensitive-files.sh) — it blocks edits to `.env` and credential files to backstop this.
