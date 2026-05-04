# Agents (Subagents)

Subagents run in isolated, read-only contexts. Use them for analysis tasks that would pollute the main conversation with large tool outputs — code review, security review, impact analysis, documentation research.

## Schema

```yaml
---
name: agent-name-kebab-case
description: >
  One sentence describing what this agent analyzes.
  Use when user says 'trigger 1', 'trigger 2', 'trigger 3'.
  Do NOT use for (counter-scenario that redirects).
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: plan
maxTurns: 25
---
```

Rules (enforced by `../validation/validate-agent.sh`):

- `name` is lowercase with hyphens, matches filename.
- `description` has ≥3 trigger phrases, ≥1 negative scope, no angle brackets, under 1024 chars.
- **Read-only enforcement:** if `description` contains `review|analyze|scan|audit|check` and NOT `fix|implement|create|write|modify|update`, then `tools` MUST NOT contain `Write` or `Edit`. Validator errors.
- Body has ≥3 backtick-wrapped file references.
- System prompt is self-contained (the agent starts cold — no conversation context).

## Design rules

- **Principle of least privilege.** Most review agents only need `Read, Grep, Glob`. Add `Bash` only when the agent must run tests or git commands. `Write`/`Edit` are for action agents, not review agents.
- **Specify output format.** The invoking assistant relies on stable report structure. Put it at the bottom of the system prompt as a markdown skeleton.
- **Tell the agent what to read first.** An orientation section (1–3 files) lets the agent start analysis instead of searching.
- **Be explicit about non-goals.** "You do NOT modify files" removes scope creep.

## When to use an agent vs a skill

| Signal | Use agent | Use skill |
|---|---|---|
| Large tool output would flood main context | ✓ | |
| Isolated, bounded task with clear report | ✓ | |
| Needs to take actions (edit, write, commit) | | ✓ |
| Invoked mid-workflow by another skill | | ✓ |
| Read-only analysis | ✓ | sometimes |
| Needs orchestration with user | | ✓ |

See [`../guides/when-to-create-what.md`](../guides/when-to-create-what.md) for the full decision tree.

## Validation

```bash
bash ../validation/validate-agent.sh examples/code-reviewer.md
for f in examples/*.md; do bash ../validation/validate-agent.sh "$f" || exit 1; done
```

## Included examples

- [`examples/code-reviewer.md`](examples/code-reviewer.md) — diff review against this library's principles
- [`examples/security-reviewer.md`](examples/security-reviewer.md) — OWASP + secrets + auth flow check
- [`examples/impact-analyzer.md`](examples/impact-analyzer.md) — cross-module blast radius
- [`examples/docs-researcher.md`](examples/docs-researcher.md) — fetch library docs via MCP
- [`examples/test-gap-analyzer.md`](examples/test-gap-analyzer.md) — untested code paths
