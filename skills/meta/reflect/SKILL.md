---
name: reflect
description: >
  Run a session retrospective against the CLAUDE.md, skills, and hooks — identify guidance
  violations, stale rules, and gaps. Use when user says 'reflect on this session', 'what did
  we learn', 'post-mortem this work', 'what should we update in CLAUDE.md', or 'are our skills
  still right'. Do NOT use for code review (use /review-diff), PR prep (use /create-pr), or
  creating new skills from scratch (use /create-or-audit-skill).
allowed-tools: Read, Grep, Glob, Bash
---

# Reflect — session retrospective

A structured self-audit after a non-trivial session: what friction did the current `.claude/` setup cause? What should be added, changed, or removed?

## Before You Start

- `CLAUDE.md` — the ambient project context. Read it alongside this session's transcript.
- `.claude/skills/` — scan every active skill's description.
- `.claude/hooks/` and `.claude/settings.json` — see what's wired.
- `principles/` — the seven principles are the benchmark for any proposed change.

## Step 1: collect evidence

Scan the session for friction signals:

- **User corrections** — "no, not that", "don't do X", "stop doing Y" indicate either misleading guidance or a missing rule.
- **User confirmations on non-obvious choices** — "yes, exactly", "that's the right call" validate a non-obvious pattern worth encoding.
- **Places the agent searched for a file repeatedly** — missing directory landmark in `CLAUDE.md`.
- **Places the agent proposed an approach then had to back out** — missing convention.
- **Hook blocked work in a frustrating way** — hook's message was not actionable.
- **Skills that triggered when they shouldn't have** — description is too broad.

## Step 2: classify findings

For each signal, put it into a category:

| Category | What to do |
|---|---|
| Hidden invariant or gotcha the agent didn't know | Add to `CLAUDE.md` under **Things to Know** |
| Repeated multi-step workflow that isn't yet a skill | Candidate for a new skill (use `create-or-audit-skill`) |
| Rule that a linter/formatter should enforce | Wire a hook; don't add prose |
| Skill that fired wrongly / too often | Tighten the description's "Do NOT use for" clause |
| Rule in `CLAUDE.md` that contradicts current behavior | Update or remove — stale guidance is worse than none |
| Generic phrase that sneaked in | Remove it. The `create-or-audit-claude-md` skill's validator catches the common ones. |

## Step 3: propose changes

Write one concrete change per finding. Example shape:

```markdown
### Finding: agent created service classes inconsistently

**Evidence:** 2 instances in this session — `src/users/service.ts` got a `ServiceBase` extension,
`src/orders/service.ts` did not.

**Classification:** hidden invariant — the codebase uses `ServiceBase` consistently, but it's
not documented.

**Proposed change:** add to `CLAUDE.md` under "Patterns and Conventions":

  New services extend `ServiceBase` (`src/lib/service-base.ts`), which provides logging
  and error wrapping. See `src/users/service.ts` for the canonical example.
```

## Step 4: apply with user confirmation

Never edit `CLAUDE.md` or skills without the user's say-so. Present all proposed changes as a single list; the user approves or rejects each. Apply only what's approved.

## Step 5: re-validate

For every file touched, re-run the artifact-specific audit skill so the mechanical gates pass:

- Changed `CLAUDE.md` → run `create-or-audit-claude-md` (Mode 2)
- Changed `SKILL.md` → run `create-or-audit-skill` (Mode 2)
- Changed `*.sh` hook → run `create-or-audit-hook` (Mode 2)

A validator regression after reflection means the reflection made things worse — fix before declaring done.

## Verify

For each artifact you changed, the corresponding `create-or-audit-*` skill's Mode 2 audit reports `VERDICT: PASS`. If anything regressed, the reflection has not landed cleanly.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Turning one-off friction into a permanent rule | Reflect asks "would this happen again?" — one incident isn't a pattern. Usually two instances before codifying. |
| Adding a rule without deleting the stale one it contradicts | Replace, don't append. `CLAUDE.md` contradictions compound into unusable guidance. |
| Editing files without showing the user | Always propose; user approves. Reflection is collaborative, not autonomous. |
| Skipping the validator re-run | Principle 01 is evidence-based — if the validator now fails, the reflection made things worse. |
