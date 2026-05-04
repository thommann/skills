# 0005 — Document both MCP patterns (single `mcp.json` and per-server launchers)

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

Two prior art sources use different MCP configuration patterns:

- **ultrainit.sh** produces a single `.claude/mcp.json` with every server declared inline. Simple, declarative, portable.
- **The prior production setup** uses 12 per-server bash wrappers under `.claude/mcp/` (e.g., `mcp-context7.sh`, `mcp-postgres.sh`). Each is a launcher script referenced from `settings.json`.

Both are legitimate patterns with different trade-offs:

- `mcp.json` wins when the toolkit is uniform, env vars come from a single `.env`, and no custom startup logic is needed.
- Launchers win when servers need conditional availability, per-server logging, different env-var prefixes, port-forwarding or vault-unlocking before launch, or version pinning per server.

The library had to pick: one pattern, the other, or both.

## Decision Drivers

- **User autonomy.** Adopters should pick the pattern matching their team's workflow, not be forced into ours.
- **Completeness.** A library that shows only one pattern signals the other is wrong — which is false.
- **Documentation clarity.** Mixing patterns in a single example is confusing; two separate, clean examples each illustrate their pattern.
- **Minimal duplication.** The MCP packages underlying both patterns are the same; only the wrapping differs.

## Considered Options

1. **Single `mcp.json` only** — simpler library, pushes launcher pattern out of scope.
2. **Launchers only** — matches the prior setup; mcp.json users would have to convert.
3. **Both patterns, documented side by side** — users pick.
4. **Both, with a "use this one" recommendation** — opinionated.

## Decision

We chose **Option 3: both patterns, documented side by side, no recommendation**.

`mcp/` contains:

- `mcp.json.template` + `mcp.json.examples/` (3 files: minimal, web-app, data-platform).
- `launchers/` with a `TEMPLATE.sh` + 10 concrete launchers (context7, github, playwright, postgres, mongodb, filesystem, fetch, slack, sentry) + 2 custom templates (custom-api, custom-db).

`mcp/README.md` explains the trade-offs. If the reader asks "which should I use?", the answer is: `mcp.json` if your toolkit is uniform; launchers if you need env-var or startup-logic flexibility.

## Consequences

### Positive

- Users coming from either convention find a familiar pattern.
- The launcher pattern is fully templated with TEMPLATE.sh — easy to add a new launcher.
- `mcp.json` users see progressively complex examples (minimal → web-app → data-platform).
- Custom API and custom DB launcher templates give a starting point for project-owned MCP servers.

### Trade-offs

- The `mcp/` directory is larger than ultrainit's. More surface area to maintain.
- Users have to make a choice. Some may prefer opinionated guidance.
- When both a `.claude/mcp.json` and `.claude/mcp/*.sh` exist in a project, the loading order is non-obvious — mitigated by each `mcp/README.md` noting the trade-offs explicitly.

## References

- [`../mcp/README.md`](../mcp/README.md) — pattern comparison table.
- [`../mcp/launchers/README.md`](../mcp/launchers/README.md) — launcher-specific guidance.
- ultrainit.sh's `.claude/mcp.json` (upstream) — the canonical single-file pattern.
- The prior production setup's `.claude/mcp/` (not public) — the canonical launcher pattern.
