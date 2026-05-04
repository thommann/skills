# Skills

Skills are named, reusable workflows a developer (or Claude itself) invokes by name. This library ships portable skills in four categories — every skill here works in any project after at most trivial adaptation.

| Category | What it contains |
|---|---|
| [`meta/`](meta/) | Skills that author or audit other `.claude/` artifacts (skills, agents, hooks, CLAUDE.md) |
| [`workflow/`](workflow/) | Git, PR, branch, review, feedback-ingest |
| [`documentation/`](documentation/) | ADRs, feature docs, doc-sync, explain, arc42, system-overview |
| [`planning/`](planning/) | Issue → implementation plan |

Project-specific starter kits (scaffolding, debugging, reference) live under [`../guides/`](../guides/) — they're reading material for adapting the patterns to your codebase, not turnkey skills.

## Schema

Every `SKILL.md` has YAML frontmatter + a body.

### Frontmatter

```yaml
---
name: kebab-case-matches-folder
description: "One sentence of what. Use when user says 'phrase 1', 'phrase 2', 'phrase 3'. Do NOT use for (counter-scenario)."
allowed-tools: Read, Grep, Glob, Bash
---
```

Rules (enforced by `meta/create-or-audit-skill/lib/validate.sh`):

- `name` is **kebab-case** and **matches the folder name**. Rejected: `MySkill`, `my_skill`, `my skill`.
- `description` contains **≥3 trigger phrases** in natural language (`use when`, `invoke when`, `trigger on`, `user says`).
- `description` contains **≥1 negative scope** (`Do NOT use for`, `don't use for`, `not for`, `instead use`).
- `description` is **under 1024 characters**.
- `description` contains **NO angle brackets** (`<` or `>`) — breaks YAML parsing.
- `allowed-tools` follows **principle of least privilege** — list only what the skill invokes.

### Body

Required sections:

- `## Before You Start` — 1–3 exemplar files to read, with their paths in backticks.
- Numbered steps (`## Step 1: ...`) with real commands.
- `## Verify` — exact validation commands.
- `## Common Mistakes` — 2–4 real pitfalls with corrections.

Rules:

- **≥3 backtick-wrapped file references** anywhere in the body.
- **No banned generic phrases** (`meta/create-or-audit-skill/lib/generic-phrases.txt`).
- **Every prohibition comes with an alternative** in the same section (principle 05).

## Validation

```bash
# Validate one skill (from repo root)
bash skills/meta/create-or-audit-skill/lib/validate.sh skills/meta/create-or-audit-skill/SKILL.md

# Validate everything (skills, agents, hooks, CLAUDE.md examples)
bash validation/validate-all.sh
```

`validation/validate-all.sh` is the maintainer harness; it orchestrates the per-skill validators that live under `skills/meta/create-or-audit-*/lib/`.
