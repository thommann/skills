---
name: create-or-audit-agent
description: >
  Creates or audits a Claude Code subagent file. Use when user says 'create an agent',
  'build a subagent', 'review this agent', 'audit our agents', 'add a code-reviewer agent',
  or 'our agents are too broad'. Do NOT use for skills (use create-or-audit-skill), hooks
  (use create-or-audit-hook), or CLAUDE.md files (use create-or-audit-claude-md).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Create or audit a subagent

Subagents are isolated, read-only (by default) contexts for bounded analysis tasks. They do NOT replace skills — skills take actions; agents produce reports.

## Before You Start

- `skills/meta/create-or-audit-agent/templates/agent.md` — annotated blank skeleton with frontmatter rules and the read-only-enforcement rationale.
- `skills/meta/create-or-audit-agent/lib/validate.sh` — mechanical checks including the read-only enforcement rule.
- Decision rule: agents = read-only analysis producing structured reports; skills = action-taking workflows. If the task writes files or changes state, build a skill (use `create-or-audit-skill`).

## Mode 1 — build a new agent

### Step 1: decide agent vs skill

If the task is any of the following, a subagent is the right tool:

- The analysis would flood main context with tool output (large codebase scans, full log dumps).
- The output is a structured report the caller can consume (review, audit, impact analysis).
- The context is bounded and read-only (no writes, no shell commands with side effects).

If the task takes actions (edits files, creates PRs, runs tests that change state), write a **skill** instead.

### Step 2: choose the read-only posture

If the description mentions `review`, `analyze`, `audit`, `scan`, `check`, or `research` without `fix`, `implement`, `create`, `write`, `modify`, or `update`:

- `tools: Read, Grep, Glob` (minimum) — add `Bash` only if the agent must run tests or `git` read-only commands.
- Do NOT include `Write` or `Edit`. The validator errors on read-only-sounding agents with write tools.

### Step 3: write the frontmatter

```yaml
---
name: agent-name-kebab-case
description: >
  One dense sentence: what this agent analyzes.
  Use when user says 'trigger 1', 'trigger 2', 'trigger 3'.
  Do NOT use for (sibling case that redirects).
tools: Read, Grep, Glob
model: sonnet
permissionMode: plan
maxTurns: 25
---
```

- `name` matches the filename.
- Description: ≥3 trigger phrases, ≥1 "Do NOT use for", no angle brackets, < 1024 chars.
- `maxTurns` — a read-only analysis rarely needs > 30.

### Step 4: write the body

The body is the agent's **system prompt** — it starts cold, no conversation context. Structure it as:

- **You are a {role}** — one-line role declaration.
- **What You Should Read First** — 1–3 orientation files (`src/...`, `docs/...`). The agent runs `Read` on these before starting.
- **How You Work** — numbered phases or steps. Each phase has a concrete goal and a hand-off.
- **What You Report Back** — a markdown skeleton. Agents with unstable output format cannot be called reliably.
- **What You Do NOT Do** — explicit non-goals. Keeps scope creep out. Each prohibition pairs with a redirect (principle 05).

### Step 5: run the validator

```bash
bash skills/meta/create-or-audit-agent/lib/validate.sh .claude/agents/{agent-name}.md
```

Fix errors, especially: read-only-with-write-tools (hard error), angle brackets in description, name-matches-filename.

### Step 6: smoke test

Invoke the agent manually with a representative query. The report should land in the exact format from "What You Report Back." If it doesn't, the system prompt needs tightening.

## Mode 2 — audit an existing agent

### Step 1: structural

```bash
bash skills/meta/create-or-audit-agent/lib/validate.sh path/to/agent.md
```

### Step 2: five gates

**Gate 1 — least privilege.** Does the agent have only the tools it demonstrably uses? If `Bash` is listed but the body never runs a command, remove it.

**Gate 2 — read-only intent.** If the description sounds review/analyze/audit, the tools list must NOT contain `Write` or `Edit`. Validator errors on this.

**Gate 3 — orientation.** The body names ≥1 file the agent should read first. An agent that opens with "Find all the X" without naming where starts with a codebase-wide grep — wasteful.

**Gate 4 — output format.** Is there a report skeleton the caller can rely on? If not, add one.

**Gate 5 — portability.** Remove project-specific names from the library version. Concrete project paths stay in the project's `.claude/agents/` — not here.

### Step 3: report

```markdown
## Agent Audit: {agent-name}

### Verdict: APPROVE | REVISE | REJECT

### Gate results
| Gate | Result | Notes |
|---|---|---|
| 1. Least privilege | ... | ... |
| 2. Read-only enforced | ... | ... |
| 3. Orientation | ... | ... |
| 4. Output format | ... | ... |
| 5. Portability | ... | ... |

### Proposed revisions
...
```

## Verify

```bash
bash skills/meta/create-or-audit-agent/lib/validate.sh .claude/agents/{name}.md
# Expected: VERDICT: PASS

# Smoke: invoke the agent. Output should match the declared format.
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Write agent that should be a skill | Agents are for analysis; skills take actions. Move to `skills/workflow/` and use a concrete verb in the name. |
| Reviewer agent with Write/Edit tools | Remove them. Read-only reviewers must stay read-only — validator enforces. |
| Agent body is 10 lines of "do your best" | Agents start cold. Spell out the exact procedure and the exact report shape, or every invocation produces different output. |
| Description without "Do NOT use for" | Add the counter-scenario pointing at a sibling agent. Without it, the router over-matches. |
