# Decisions (ADRs)

Architecture Decision Records documenting **why this library looks the way it does**. They double as worked examples of the [`document-decision`](../skills/documentation/document-decision/SKILL.md) skill.

## Format

Each ADR follows `YYYY_MM_DD_slug.md` for filename and has four sections:

1. **Context** — the problem or situation that prompted the decision
2. **Decision Drivers** — the forces pulling toward (or against) each option
3. **Decision** — what was chosen
4. **Consequences** — positive outcomes and trade-offs (often split into "Positive" and "Trade-offs")

## Index

| # | Decision | Status |
|---|---|---|
| [0001](0001-scope-library-not-generator.md) | Scope this repo as a static library, not a generator | Accepted |
| [0002](0002-hybrid-taxonomy-seven-skill-categories.md) | Use a seven-category skill taxonomy (ultrainit's four + meta/documentation/planning) | Accepted |
| [0003](0003-documentation-skills-first-class.md) | Documentation skills are first-class, filling the ultrainit gap | Accepted |
| [0004](0004-adopt-ultrainit-validation-rules.md) | Adopt ultrainit's validation rules verbatim | Accepted |
| [0005](0005-mcp-both-patterns-documented.md) | Document both MCP patterns (single `mcp.json` and per-server launchers) | Accepted |
| [0006](0006-scaffolding-and-debugging-are-project-specific.md) | Scaffolding/debugging/reference skills ship as templates, not working skills | Accepted |
