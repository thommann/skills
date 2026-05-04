# Writing a good agent

Companion to [`../skills/meta/create-or-audit-agent/SKILL.md`](../skills/meta/create-or-audit-agent/SKILL.md).

## Agents vs skills — the line

Agents are **bounded, isolated, read-only analyses** that produce a structured report. Skills are **multi-step workflows that take actions**.

Signals you want an agent, not a skill:

- Running the work inline would dump thousands of lines of tool output into main context.
- The caller needs a report in a specific shape they can rely on.
- The task is pure analysis — no writes, no commits, no external effects.

Signals you want a skill:

- The work changes files, runs tests, opens PRs.
- The work requires user interaction mid-flow.
- The work is short enough to run inline without context blowup.

## Principle of least privilege

An agent's `tools` field should list only what the agent demonstrably uses.

For review / analyze / audit agents:

- **Always:** `Read, Grep, Glob`.
- **Sometimes:** `Bash` (for git read operations, running tests read-only).
- **Never:** `Write, Edit`. Validator enforces this as an error.

Missing `tools` field = inherits all tools. For a read-only agent, that's a bug — restrict explicitly.

## The cold-start problem

Agents begin with NO context from the invoking conversation. Everything they need must be in the system prompt.

That's why:

- A "What You Should Read First" orientation section is load-bearing.
- An "How You Work" section with concrete steps beats "be thorough."
- An explicit output format (a markdown skeleton) is required — otherwise every invocation produces different shapes.

## Output format as API

The calling assistant relies on the agent's output format. Treat it like an API:

- **Stable section headers.** Don't vary them between runs.
- **Tables over prose** where the data is enumerable.
- **Severity/category labels** that are a fixed vocabulary — "Critical / Important / Suggestion", "BREAKS / BEHAVIOR CHANGE / NEEDS UPDATE / UNAFFECTED".
- **File:line references** in every finding — the reader needs to jump to the code.

An agent with freeform prose output can't be consumed reliably by another assistant.

## The "what you do NOT do" section

Explicit non-goals prevent scope creep. An impact analyzer that starts speculating about architecture isn't an impact analyzer — it's drift.

Each non-goal pairs with a redirect:

- "You do NOT apply fixes. The caller applies them."
- "You do NOT cross into architecture review — that's `code-reviewer`'s territory."
- "You do NOT estimate effort — a file count is not an effort estimate."

## Sizing the agent

Agents are isolated subconversations — they have their own context budget. Spend it wisely:

| Token budget | Use for |
|---|---|
| 15–30k | Quick reviews, targeted analysis (diff review, single-file audit) |
| 30–80k | Codebase-scanning reviews (full-repo security scan, dependency analysis) |
| 80k+ | Multi-phase deep dives — usually better as two agents chained |

Set `maxTurns` accordingly — `25` is fine for a focused review; `40` for a wider sweep. Above that, the agent is wandering.

## Model choice

- `sonnet` (default) — most review / audit work. Fast, capable, economical.
- `opus` — complex reasoning, architecture review, ambiguous findings.
- `haiku` — trivial scans, simple data extraction.
- `inherit` — take the caller's model. Rare; usually pin to give the caller predictability.

## Common Mistakes

### Agent that's really a skill

"Review my diff and commit the fixes." That's two operations: the review (agent) and the fix application (skill). Split them.

### Agent with no orientation

```yaml
---
name: code-reviewer
tools: Read, Grep, Glob
---
Review the code.
```

This agent will search randomly. Give it starting points: "Read `CLAUDE.md` first. Then read every file in the diff." Three lines of orientation save dozens of exploratory tool calls.

### Agent with `tools: Read, Write, Edit, Bash`

If the description says "review" or "audit", `Write` and `Edit` are wrong. Validator errors. Reviewers report; they don't apply.

### Freeform output

```markdown
## Findings
I noticed several issues with the code...
```

No caller can parse this. Use a consistent structure:

```markdown
## Findings

### Critical
| File | Line | Issue | Fix |
|---|---|---|---|
```

### System prompt full of `CLAUDE.md`-style project context

If the agent is portable, keep it portable — reference the project's `CLAUDE.md` instead of inlining it. The agent reads `CLAUDE.md` in Phase 1 of "How You Work"; the agent's prompt focuses on the procedure and the report format.

## Pre-ship checklist

- [ ] `bash validation/validate-agent.sh <path>` exits 0.
- [ ] Description has ≥3 trigger phrases and ≥1 "Do NOT use for."
- [ ] `tools` restricted; no `Write`/`Edit` for reviewers.
- [ ] Body has ≥3 backticked file references.
- [ ] "What You Should Read First" names 1–3 orientation files.
- [ ] "How You Work" has concrete phases.
- [ ] "What You Report Back" has a markdown skeleton.
- [ ] "What You Do NOT Do" section present with redirects.

## When to split an agent

Split when:

- Phases have different concerns (e.g., security scan vs code quality).
- One phase needs wider tool access than another — split to preserve least-privilege.
- The output is genuinely two reports the caller consumes differently.

Don't split when:

- The agent is simply long but cohesive. Length alone isn't a split signal.
