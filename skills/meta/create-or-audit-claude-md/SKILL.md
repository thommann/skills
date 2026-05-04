---
name: create-or-audit-claude-md
description: >
  Creates or audits a CLAUDE.md file — the ambient project-context document Claude Code loads
  at session start. Use when user says 'create a CLAUDE.md', 'audit our CLAUDE.md', 'is our
  CLAUDE.md any good', 'our CLAUDE.md is out of date', 'make CLAUDE.md load-bearing', or
  'write scope-level CLAUDE.md'. Do NOT use for skills (use create-or-audit-skill), agents
  (use create-or-audit-agent), or user-facing documentation (use write-doc).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Create or audit a CLAUDE.md

Two modes, same skill: **Mode 1** writes a new `CLAUDE.md` by reading the codebase and distilling ambient context an agent needs. **Mode 2** audits an existing one against the quality gates.

## Before You Start

- `principles/02-dense-not-brief.md` — the rule that drives `CLAUDE.md` length. Load-bearing, not pad.
- `skills/meta/create-or-audit-claude-md/templates/CLAUDE.md` — the annotated root skeleton with required sections.
- `skills/meta/create-or-audit-claude-md/templates/CLAUDE.subdir.md` — the subdir skeleton + the four trigger criteria.
- `skills/meta/create-or-audit-claude-md/lib/validate.sh` — the mechanical gate.

## Mode 1 — create a CLAUDE.md

### Step 1: discover the codebase

```bash
# Top-level shape
ls -la
find . -maxdepth 2 -type d -not -path '*/node_modules*' -not -path '*/.git*'

# Build/test/lint commands (look in all the usual places)
cat package.json 2>/dev/null | jq '.scripts // {}'
cat pyproject.toml 2>/dev/null | grep -A 20 '\[tool\.' | head -40
cat Makefile 2>/dev/null | grep -E '^[a-zA-Z_-]+:'
cat justfile .justfile 2>/dev/null
ls .github/workflows/ 2>/dev/null

# Entry points
git log --pretty=format: --name-only -200 | sort | uniq -c | sort -rn | head -30
```

### Step 2: identify subsystems

Look at the top-level source tree. For each major directory (likely candidates: `src/`, `apps/`, `packages/`, `services/`, `lib/`), ask:

- What does it own?
- How does it communicate with siblings?
- What language/framework does it use?

### Step 3: extract the "things to know"

The most valuable section of a `CLAUDE.md`. These are the hidden invariants and gotchas — the things not obvious from the code but known by every veteran.

Mine them from:

```bash
# Recent bug fixes reveal invariants
git log --oneline --all | grep -iE 'fix|bug' | head -30

# ADRs if they exist
ls docs/adr docs/decisions docs/arc42/decisions 2>/dev/null

# "Do not edit this" and "DANGER" comments in the code
grep -rniE 'DO NOT|DANGER|CAREFUL|WARNING|HACK|FIXME|TODO' --include='*.py' --include='*.ts' --include='*.js' --include='*.go' --include='*.rs' | head -30
```

### Step 4: write the file using `root.md.template`

Copy `skills/meta/create-or-audit-claude-md/templates/CLAUDE.md` and fill in every section. Keep the section order from the template — agents rely on it.

Special discipline for each section:

- **Quick Reference** — real commands that actually run. If `pnpm test` doesn't exist, don't list it.
- **Architecture** — the longest section. 2–3 paragraphs overview + directory tree + per-subsystem deep-dives.
- **Patterns and Conventions** — only things a linter doesn't catch (principle 03).
- **Things to Know** — gotchas with structure: *what happens → why → what to do*. These are pure value for the agent.
- **Security-Critical Areas** — a short, honest list. Lying here will erode trust.

### Step 5: create subdirectory CLAUDE.md files

A subdirectory gets its own `CLAUDE.md` when ANY of the four criteria holds (`skills/meta/create-or-audit-claude-md/SKILL.md` enumerates them): different language/framework, 3+ divergent patterns, own build commands, 10+ files with distinct conventions.

Each must be **self-contained** — a developer working in that directory should not need to flip back to root.

## Mode 2 — audit an existing CLAUDE.md

### Step 1: run the validator

```bash
bash skills/meta/create-or-audit-claude-md/lib/validate.sh CLAUDE.md
```

Fix errors before continuing.

### Step 2: five quality gates

**Gate 1 — density.** Is every line load-bearing? Cut transitional prose ("In summary...", "As mentioned above..."), cut sections that have shrunk to a single sentence.

**Gate 2 — evidence.** Every declarative statement cites a file or a command. Run:

```bash
grep -oE '`[a-zA-Z_./-]+/[a-zA-Z_.-]+`' CLAUDE.md | sort -u | while read p; do
  path=$(echo "$p" | tr -d '`')
  [ ! -e "$path" ] && echo "STALE: $p"
done
```

**Gate 3 — duplication.** Scan for rules already enforced by tooling (linter rules, formatter rules, CI checks). Remove them; point at the tool instead.

**Gate 4 — alternatives.** Every prohibition (`never`, `don't`, `do not`) must have a nearby alternative (`instead`, `use X instead`, `prefer`). Validator enforces.

**Gate 5 — Things to Know.** This section's presence is a strong signal the `CLAUDE.md` has earned its keep. If it's empty or trivial, interview the team: "What's the most surprising thing about this codebase?"

### Step 3: report

```markdown
## CLAUDE.md Audit: {path}

### Verdict: APPROVE | REVISE | REJECT

### Gate results
...

### Stale references (must fix)
{List of paths that no longer exist}

### Duplicated tooling rules (remove these — point at the tool)
...

### Missing sections
...

### Proposed additions to "Things to Know"
{From your discovery in step 2}
```

## Verify

```bash
# Validator passes
bash skills/meta/create-or-audit-claude-md/lib/validate.sh CLAUDE.md
# Expected: VERDICT: PASS

# No stale file references
grep -oE '`[a-zA-Z_./-]+/[a-zA-Z_.-]+`' CLAUDE.md | tr -d '`' | while read p; do
  [ ! -e "$p" ] && echo "STALE: $p"
done
# Expected: empty output
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Padding to reach a line count | Dense, not bulky. A 150-line file with every line load-bearing beats a 400-line mix. |
| Embedding a 30-line code snippet | Reference the file (principle 04): `` `src/api/routes.ts` — see this for the pattern. `` |
| Restating every linter rule | Point at the tool (`.eslintrc.json`, `ruff.toml`) and document only the non-obvious rules. |
| "Don't use `x`" with no alternative | Pair with "Use `y` instead, defined in `src/lib/y.ts`." Validator errors without this. |

## What doesn't belong in CLAUDE.md

- **Rules already enforced by tooling.** If ESLint catches it, don't restate it (principle 03).
- **Temporary state.** Current sprint goals, "in-progress" features. That's issue-tracker territory.
- **Long tutorials.** If a walkthrough is >20 lines, it's a skill, not ambient context.
- **Embedded code snippets over 10 lines.** They rot. Reference the file instead (principle 04).
