# 0002 — Use a seven-category skill taxonomy

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

Ultrainit's skill taxonomy has four categories: Scaffolding, Workflow, Debugging, Reference. The prior production setup does not use explicit categorization, but inspection shows its ~44 skills cluster into seven shapes:

- Scaffolding (22 skills — `scaffold-*`)
- Workflow (5 skills — `create-pr`, `merge-main`, `review-diff`, `implement-feedback-from-pr`, `splice-issue`)
- Debugging (3 skills — `debug-agent`, `debug-frontend`, `debug-pipeline`)
- Reference (7 skills — `bot-framework`, `dagster-pipelines`, `nats-events`, `design-system`, `primevue-lookup`, `rclone-guide`, `i18n`)
- Meta (3 skills — `create-or-audit-claude-md`, `create-or-audit-skill`, `create-or-audit-subagent`, plus `reflect`)
- Documentation (5 skills — `arc42`, `document-decision`, `document-feature`, `explain`, `update-doc`, `write-doc`)
- Planning (2 skills — `plan-issue`, `pr-demo-video`; `splice-issue` is adjacent)

The library ships generic skills across these clusters. It needs an organizing taxonomy so users know where to put new skills and reviewers know which category's rules apply.

## Decision Drivers

- **Findability.** New contributors should open one category directory and see related skills.
- **Validation differentiation.** Scaffolding/debugging/reference skills are inherently project-specific (ultrainit ships no examples for them); meta/workflow/documentation/planning ship working.
- **Alignment with ultrainit's principles** (portability test, validation gates) without discarding the prior setup's richer category set.
- **No orphan skills.** Every skill this library ships falls into a category.

## Considered Options

1. **Ultrainit's four categories** (Scaffolding, Workflow, Debugging, Reference). Simplest.
2. **Seven categories** (the four above + Meta, Documentation, Planning).
3. **No categories** — flat `skills/` directory.

## Decision

We chose **Option 2: seven categories**.

`skills/` contains seven subdirectories:

- `meta/` — skills that author or audit other `.claude/` artifacts.
- `workflow/` — git, PR, branch, review, feedback-ingest.
- `documentation/` — ADRs, feature docs, doc-sync, arc42, explain.
- `planning/` — issue-to-plan.
- `scaffolding/` — project-specific templates for "add a new X".
- `debugging/` — subsystem troubleshooting patterns.
- `reference/` — project-specific domain-knowledge encoding.

The first four ship working generic skills. The last three ship as templates with `{{PLACEHOLDERS}}`, since working instances are inherently project-specific.

## Consequences

### Positive

- Skills are grouped by shape: portable vs project-patterned.
- Meta-skills get first-class status — acknowledging the prior setup's insight that a `.claude/` benefits from skills that audit itself.
- Documentation skills have a dedicated home, filling ultrainit's explicit gap.
- Users browsing `skills/scaffolding/` immediately see "these are templates to adapt" in that directory's README.

### Trade-offs

- Seven categories is more structure than ultrainit's four. New users have to learn the taxonomy.
- Some skills borderline between categories (`implement-feedback-from-pr` could be workflow OR planning). We documented placement with the "Taxonomy" section in `skills/README.md`.
- Validators need to know which categories are "working" and which are templates — implemented by having `validate-all.sh` skip scaffolding/debugging/reference.

## References

- [`../skills/README.md`](../skills/README.md) — per-category summaries.
- [`0003-documentation-skills-first-class.md`](0003-documentation-skills-first-class.md) — detailed decision on the Documentation category.
- [`0006-scaffolding-and-debugging-are-project-specific.md`](0006-scaffolding-and-debugging-are-project-specific.md) — detailed decision on the template-only categories.
