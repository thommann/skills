# Skills

Skills are named, reusable workflows a developer (or Claude itself) invokes by name. This library ships skills in seven categories:

| Category | What it contains | Ships working? |
|---|---|---|
| [`meta/`](meta/) | Skills that author or audit other `.claude/` artifacts | Yes |
| [`workflow/`](workflow/) | Git, PR, branch, review, feedback-ingest | Yes |
| [`documentation/`](documentation/) | ADRs, feature docs, doc-sync, explain, arc42 | Yes |
| [`planning/`](planning/) | Issue → implementation plan | Yes |
| [`scaffolding/`](scaffolding/) | Pattern + templates for project-specific "add-X" skills | Templates only |
| [`debugging/`](debugging/) | Pattern + templates for project-specific debug-X skills | Mostly working |
| [`reference/`](reference/) | Pattern + templates for project-specific domain-knowledge skills | Templates only |

`scaffolding`, `debugging`, and `reference` ship as templates because a working `add-api-endpoint` skill inherently references your project's router, ORM, and test fixture — it can't be portable. See each category's `README.md` for the adaptation workflow.

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

Rules (enforced by `../validation/validate-skill.sh`):

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
- **No banned generic phrases** (`validation/lib/generic-phrases.txt`).
- **Every prohibition comes with an alternative** in the same section (principle 05).

## Taxonomy (for authoring new skills)

The four classical categories from ultrainit — plus three we've added for complete coverage:

1. **Scaffolding** — one per entity type ("add an X"). Project-specific; ships as template.
2. **Workflow** — cross-cutting procedures (PR prep, lint-before-commit).
3. **Debugging** — one per major subsystem (backend, frontend, db, infra, tests).
4. **Reference** — domain knowledge encoding ("how we use X"). Project-specific; ships as shape-only template.
5. **Meta** *(our addition)* — skills that author/audit other skills/agents/hooks/CLAUDE.md.
6. **Documentation** *(our addition)* — ADRs, feature docs, doc-sync, explain. Fills the ultrainit gap.
7. **Planning** *(our addition)* — issue/task planning, splice, plan-issue.

When adding a new skill to this library, place it in the category matching its shape. If none fits, extend the taxonomy and update this table.

## Validation

```bash
# Validate one
bash ../validation/validate-skill.sh meta/create-or-audit-skill/SKILL.md

# Validate all
for f in */**/SKILL.md; do bash ../validation/validate-skill.sh "$f" || exit 1; done
```

Scaffolding/debugging/reference examples with `{{PLACEHOLDERS}}` will fail validation until adapted — this is expected. The README in each of those directories explains.
