# When to create what

Decision tree for the four primary artifact types. Use this before starting an artifact.

## The decision tree

```
Is the behavior DETERMINISTIC and should run EVERY TIME a tool fires?
  └─ Yes → HOOK (e.g., auto-format, block-on-secrets)

Is it READ-ONLY analysis that would flood main context with tool output?
  └─ Yes → AGENT (e.g., code-reviewer, security-reviewer, impact-analyzer)

Is it a MULTI-STEP WORKFLOW a developer (or Claude) invokes by name?
  └─ Yes → SKILL (e.g., create-pr, document-decision, add-api-endpoint)

Is it AMBIENT CONTEXT Claude needs at session start?
  └─ Yes → CLAUDE.md (project-level conventions, architecture, things to know)

Is none of the above?
  └─ Probably doesn't need a new artifact — inline code, a README note, or an ADR.
```

## Detailed rules per type

### Hook

**Use when:**

- The rule is mechanical (block vs allow, format vs skip).
- It must run every single time the event fires.
- Latency under 1 second — hooks run on every tool use.

**Do NOT use when:**

- The decision requires judgment or conversation.
- The rule is stateful across multiple tool calls.
- The rule is rare or project-specific in a way that's hard to encode in bash.

Canonical examples: `protect-sensitive-files.sh` (block writes), `auto-format-*.sh` (format on save).

### Agent (subagent)

**Use when:**

- The analysis is bounded and produces a structured report.
- Running it inline would dump large tool output into main context.
- The task is read-only (review, audit, scan, impact analysis).

**Do NOT use when:**

- The task needs to take actions (write, edit, commit, deploy).
- The task needs to collaborate with the user mid-flow.
- The task is short enough to run inline.

Canonical examples: `code-reviewer`, `security-reviewer`, `impact-analyzer`, `docs-researcher`.

### Skill

**Use when:**

- It's a multi-step workflow.
- Engineers say the same trigger phrases repeatedly ("create a PR", "document this decision", "add an endpoint").
- It takes actions — writes, commits, runs tests — not just analyzes.
- It encodes project-specific procedure (file locations, naming, wiring points).

**Do NOT use when:**

- It's a single-step procedure — a `CLAUDE.md` line is enough.
- It's generic programming advice ("use descriptive names") — not worth its tokens.
- It runs less than monthly — a doc pointer in `CLAUDE.md` suffices.
- A hook already enforces the rule deterministically.

Canonical examples: `create-pr`, `document-decision`, `add-api-endpoint`, `reflect`.

### CLAUDE.md

**Use when:**

- The agent needs the fact to reason correctly — architecture, conventions, gotchas.
- The fact is stable across many sessions and tasks.
- Linters/formatters don't already enforce it (principle 03).

**Do NOT use when:**

- The fact is enforced by tooling — point at the tool.
- It's task-specific — issues and PR descriptions are the right home.
- It's a long procedure — extract into a skill.

Canonical structure: Quick Reference, Architecture, Patterns and Conventions, Development Workflow, Things to Know, Security-Critical Areas, Domain Terminology.

## Common mistakes

### "This should be a skill"

A single-step procedure — "run `pnpm test` before you commit." That's a `CLAUDE.md` line, not a skill. Skills earn their keep with multi-step orchestration.

### "Let's add a hook for it"

"Require PR descriptions to mention the ticket number." This is a CI check, not a Claude hook. Hooks gate Claude's tool use; they don't lint your workflow.

### "Let's make that an agent"

"Summarize this file." That's inline work. Agents earn their keep when the tool output would otherwise flood main context — a full-codebase scan, a multi-hundred-line log dump, a whole-diff review.

### "Put it in CLAUDE.md"

"Document every endpoint." That's a docs site or an OpenAPI spec. `CLAUDE.md` is for ambient context, not API reference.

## Hybrid cases

Some work needs two artifacts working together:

- **A skill that delegates to an agent.** `create-pr` calls `review-diff` (a skill, but could be an agent for isolation). Skills compose; agents are leaf operations.
- **A hook that invokes a skill.** Rare, but a `Stop` hook could suggest "run `reflect`" if friction signals were detected.
- **A reference skill paired with a scaffolding skill.** `reference/auth-reference` describes the pattern; `scaffolding/add-api-endpoint` uses it.

## When in doubt

Start with `CLAUDE.md`. If the content grows, extract into a skill. If the skill is doing analysis that bloats context, isolate as an agent. If the rule is mechanical and always applies, move to a hook.

Iteration beats upfront design — but avoid creating all four at once for a pattern that will change next week.
