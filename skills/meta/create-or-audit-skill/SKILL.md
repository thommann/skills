---
name: create-or-audit-skill
description: >
  Builds new project-specific skills or audits existing ones against the seven principles.
  Use when user says 'build a skill', 'create a skill', 'review this skill', 'audit our skills',
  'is this skill good', 'what skills should we have', or 'clean up our skills directory'.
  Do NOT use for CLAUDE.md files (use create-or-audit-claude-md), subagents (use create-or-audit-agent),
  or hooks (use create-or-audit-hook).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Create or audit a skill

Two modes, same skill: **Mode 1** writes a new skill by discovering the pattern already used in the codebase and encoding it. **Mode 2** reviews an existing or proposed `SKILL.md` against the principles and the `validation/validate-skill.sh` quality gates.

## Before You Start

- `principles/06-portability-test.md` — the core rule: a skill belongs in a project's `.claude/skills/` only if it would **fail** in an unrelated project. If it works unchanged elsewhere, it's generic and does not belong there.
- `skills/TEMPLATE/SKILL.md` — annotated blank skeleton with comments explaining every field.
- `skills/README.md` — the seven-category taxonomy (meta, workflow, documentation, planning, scaffolding, debugging, reference).
- `validation/validate-skill.sh` — the authoritative structural checks. Run this BEFORE any content review.

## Mode 1 — build a new skill

### Step 1: validate the idea

Determine whether this SHOULD be a skill:

1. **Is it multi-step?** Single-step procedures belong in `CLAUDE.md`, not a skill.
2. **Is it project-specific?** Generic programming workflows (writing tests, using git) don't need skills unless the codebase does them in a non-obvious way.
3. **Is it frequent?** Runs < 1×/month → a `CLAUDE.md` line is sufficient.
4. **Is it already covered?** Check existing skills and `CLAUDE.md`:

```bash
find .claude/skills -name "SKILL.md" 2>/dev/null | while read f; do
  echo "=== $(basename "$(dirname "$f")") ==="
  sed -n '/^description:/,/^[a-z]*:/p' "$f" | head -5
done
```

5. **Should it be a hook?** If the rule is "always do X after Y" and X is deterministic → `PostToolUse` hook, not a skill.

If 1–3 is no or 4–5 is yes, tell the user why a skill isn't the right tool and propose the alternative.

### Step 2: find the existing pattern

The skill encodes what senior engineers already do; don't invent a procedure:

```bash
# Find 2-3 real examples of this workflow in the codebase
git log --pretty=format: --name-only -100 | sort | uniq -c | sort -rn | head -20

# Look at which files changed together in past PRs (reveals coupled files)
git log --all --pretty=format:"%h %s" --name-only -50 | grep -iE "{keyword}"
```

Read 2–3 real examples. Note: files created/modified, exact verification commands, ordering, registration/wiring steps that are easy to forget, edge cases from code comments or PR reviews.

### Step 3: write the skill

Copy `skills/TEMPLATE/SKILL.md` and fill in. The description is load-bearing:

- Include **what it does**, referencing specific parts of this codebase.
- **≥3 trigger phrases** in natural language engineers actually say.
- **≥1 "Do NOT use for"** clause defining the boundary to a sibling skill.
- **< 1024 characters** total.
- **No angle brackets** (`<` or `>`) — they break YAML parsers.

The body:

- Every instruction references a real file path, command, or pattern from this repo.
- If you find generic advice ("use descriptive names", "handle errors properly"), delete it — it's not earning its tokens.
- End with a concrete verification — a test command or a validation script. "Make sure it works" is not verification.

### Step 4: run the validator

```bash
bash validation/validate-skill.sh .claude/skills/{skill-name}/SKILL.md
```

Fix every error and warning before presenting to the user.

### Step 5: semantic test

- **Trigger test:** "When would you use the {skill-name} skill?" — the answer should accurately describe the intended case.
- **Negative test:** Would it trigger for adjacent-but-different queries? Adjust the "Do NOT" clause until no.
- **Token check:** `wc -l .claude/skills/{skill-name}/SKILL.md` — over 500 lines warns; over 600 fails.

## Mode 2 — audit an existing skill

### Step 1: structural check first

```bash
bash validation/validate-skill.sh path/to/SKILL.md
```

If this exits 1, stop and report. No point reviewing content if the skeleton is broken.

### Step 2: six gates (semantic)

**Gate 1 — Portability.** Read every instruction. For each, ask: does it reference something specific to this project? Hard fail if fewer than 3 real references OR if the skill would work unchanged in a random GitHub repo.

**Gate 2 — Overlap.** Check against `CLAUDE.md` and other skills:

```bash
find .claude/skills -name "SKILL.md" | xargs grep -l "{skill-topic}"
grep -l "{skill-topic}" CLAUDE.md **/CLAUDE.md 2>/dev/null
```

Hard fail if > 50% of content duplicates `CLAUDE.md` or if another skill has > 70% overlap.

**Gate 3 — Description quality.** Verify trigger phrases (≥3), negative scope (≥1), length (< 1024), no angle brackets. Ask "would an adjacent query wrongly trigger this?"

**Gate 4 — Instruction quality.** For each step: real path/command/pattern, actionable language, includes the *why* when non-obvious, doesn't restate what a linter catches (principle 03).

Check for stale paths:

```bash
grep -oE '`[a-zA-Z_./-]+/[a-zA-Z_.-]+`' .claude/skills/{name}/SKILL.md | tr -d '`' | while read p; do
  [ ! -e "$p" ] && echo "STALE: $p"
done
```

**Gate 5 — Safety.** `allowed-tools` scoped to what's needed. No embedded secrets. Validation scripts have no destructive side effects.

**Gate 6 — Alternatives for prohibitions.** Every "never", "don't", "do not" must pair with an "instead" in the same section (principle 05). If not, add the alternative.

### Step 3: report

```markdown
## Skill Audit: {skill-name}

### Verdict: APPROVE | REVISE | REJECT

### Gate results

| Gate | Result | Notes |
|---|---|---|
| 1. Portability | PASS/FAIL | {X/Y instructions are project-specific} |
| 2. Overlap | PASS/FAIL | {overlaps with X / none} |
| 3. Description | PASS/FAIL | {specific issues} |
| 4. Instructions | PASS/FAIL | {stale paths, generic advice, ...} |
| 5. Safety | PASS/FAIL | {specific issues} |
| 6. Alternatives | PASS/FAIL | {prohibitions without instead-clauses} |

### Proposed revisions

{Concrete rewrites, not just "make it more specific".}
```

## Verify

Run the validator against the produced or audited skill:

```bash
bash validation/validate-skill.sh path/to/SKILL.md
```

Expected: `VERDICT: PASS`. Fix errors until it does.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Writing a skill that's really a generic programming tutorial | Delete it or move its content to `CLAUDE.md`. Skills encode project-specific procedures. |
| Description without a "Do NOT use for" clause | Add one pointing at a sibling skill. Without it, the router will over-match. |
| Instructions that say "handle errors properly" or similar | Replace with "use `ProjectError` from `src/errors/index.ts`; see `src/users/service.ts:45` for an example." |
| Missing the verification step | Every skill ends with a concrete check — a test command, a file-exists probe, a lint pass. |
