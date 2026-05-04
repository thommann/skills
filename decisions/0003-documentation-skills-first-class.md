# 0003 — Documentation skills as a first-class category

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

Ultrainit generates four categories of skill (Scaffolding, Workflow, Debugging, Reference) and explicitly states that documentation is not a category. Its `synthesizer-docs.md` produces only CLAUDE.md files; its `synthesizer-tooling.md` enumerates the four categories above.

The prior production `.claude/` setup includes five dedicated documentation skills:

- `document-decision` — creates ADRs.
- `document-feature` — user-facing feature pages.
- `write-doc` — new VitePress pages.
- `update-doc` — syncs docs with code changes.
- `explain` — code walk-throughs.
- `arc42` — architecture chapters.

Plus a `doc-sync` agent. This investment reflects the reality that documentation work is a recurring, multi-step workflow that benefits from automation.

The library had to choose: follow ultrainit (no doc skills) or follow the prior setup (a full doc skill suite).

## Decision Drivers

- **The friction is real.** Documentation drift is a widespread problem; encoding a procedure helps.
- **Doc skills are multi-step and benefit from automation.** ADR creation has 5–7 steps including template lookup, naming conventions, index updates. A skill automates them correctly every time.
- **Doc skills are portable.** An ADR procedure is largely framework-agnostic; VitePress vs Docusaurus is a handful of placeholder substitutions.
- **The gap is visible in comparison.** Our initial library/ultrainit delta analysis explicitly identified "no doc skills" as the biggest ultrainit weakness.
- **Alignment with principle 04.** Documentation skills reinforce "point, don't paste" — the skill itself gets users to point at files rather than embed snippets.

## Considered Options

1. **Omit documentation skills** — follow ultrainit. Users author doc skills per-project.
2. **Include documentation skills as a first-class category** — follow the prior setup. Ship `document-decision`, `document-feature`, `write-doc`, `update-doc`, `arc42`, `explain`.
3. **Ship only ADR-related skills** — minimum viable subset.

## Decision

We chose **Option 2: include Documentation as a first-class category**.

`skills/documentation/` ships six generic skills. Each is written to work with common conventions (ADR directories at `docs/adr/`, `docs/decisions/`, `docs/arc42/decisions/`; docs sites via VitePress, Docusaurus, MkDocs, mdBook). Users adapt paths; the structure works unchanged.

## Consequences

### Positive

- The library provides immediate value for documentation workflows that ultrainit doesn't touch.
- Documentation skills reference each other cleanly (`document-decision` ↔ `arc42` chapter 9; `write-doc` ↔ `update-doc`).
- The `explain` skill acts as an onboarding tool for new contributors.
- Quality gates (principle 01 — evidence-based, principle 04 — file references over snippets) apply directly to doc skills.

### Trade-offs

- Each doc skill ships with generic conventions; users with unusual doc setups (custom SSG, proprietary wiki) will need to rewrite more than they would for a framework-agnostic skill.
- Keeping six doc skills in sync with each other is a maintenance tax when procedures change.
- `arc42` specifically is a framework-specific skill; projects that don't use arc42 will find it irrelevant but can safely ignore it.

## References

- [`../skills/documentation/`](../skills/documentation/) — the six shipped skills.
- [`../skills/README.md`](../skills/README.md) — explains why documentation is a distinct category.
- [`0002-hybrid-taxonomy-seven-skill-categories.md`](0002-hybrid-taxonomy-seven-skill-categories.md) — the broader taxonomy decision.
