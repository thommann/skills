# CLAUDE.md templates and examples

Templates and worked examples for the `CLAUDE.md` file that Claude Code loads as ambient context at the start of every session.

## When to create a CLAUDE.md

**Always** for a project root. A `.claude/` without a root `CLAUDE.md` leaves the agent reasoning from filenames and guesswork.

**Create a subdirectory CLAUDE.md** when ANY of these is true (four criteria, any one triggers):

1. The directory uses a different language or framework than the root.
2. The directory has 3+ patterns that differ from the root's conventions.
3. The directory has its own build/test commands.
4. The directory has 10+ source files with distinct conventions.

A monorepo typically has 5–15 subdirectory CLAUDE.md files. Most repos have 0–3.

## Contents

- [`templates/root.md.template`](templates/root.md.template) — annotated root skeleton
- [`templates/subdirectory.md.template`](templates/subdirectory.md.template) — annotated subdir skeleton
- [`examples/backend-service.md`](examples/backend-service.md) — worked example (Python/FastAPI-shaped)
- [`examples/frontend-app.md`](examples/frontend-app.md) — worked example (Vue/React-shaped)
- [`examples/monorepo-root.md`](examples/monorepo-root.md) — worked example (monorepo orchestration)

## Schema (enforced by `../validation/validate-claude-md.sh`)

Required sections:

1. `# <Project Name>` + one-line description
2. `## Quick Reference` — task→command table
3. `## Architecture` (longest section) — Overview, Directory Structure, Subsystem deep-dives, Key Abstractions
4. `## Patterns and Conventions`
5. `## Development Workflow`
6. `## Things to Know` — gotchas, hidden invariants (most valuable section for agents)
7. `## Security-Critical Areas`
8. `## Domain Terminology`

Quality gates:

- **≥50 lines** (warning), **≥30 lines** (error). Dense, not brief.
- **≥1 code block or pipe table.** A prose-only CLAUDE.md is rejected — it has no commands or file paths.
- **No banned generic phrases** (`../validation/lib/generic-phrases.txt`).
- **Every prohibition has an alternative** in the same section (principle 05 — enforced by the validator).

## Things that don't belong in CLAUDE.md

- **Rules already enforced by tools.** If ESLint catches it, don't restate it (principle 03).
- **Temporary state.** Current sprint goals, "in-progress" features. That's issue-tracker territory.
- **Long tutorials.** If a walkthrough is >20 lines, it's a skill, not ambient context.
- **Embedded code snippets over 10 lines.** They rot. Reference the file instead (principle 04).
