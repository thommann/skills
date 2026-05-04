# 0006 — Scaffolding, debugging, and reference skills ship as templates, not working skills

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

A core tension: the library's principle 06 (portability test) says every artifact should work unchanged in any project, but three categories of skill are inherently project-specific:

- **Scaffolding** — "add a new API endpoint" must name the project's router, service layer, and test fixture. Generic "add an API endpoint" skill gives Claude no more information than "add a file named `<your-file>`."
- **Debugging** — troubleshooting flows are mostly portable, but "check logs" must name where logs are. "Run the repro" must name the repro command.
- **Reference** — "how auth works here" is, by definition, about how THIS project does auth. A generic auth reference is framework docs, not a reference skill.

These categories can't ship as working skills by the portability test. But dropping them leaves a gap — adopters would have to author scaffolding/debugging/reference skills from scratch, with no template.

## Decision Drivers

- **User value.** Even non-working templates with `{{PLACEHOLDERS}}` speed up skill authoring massively — the structure, verification commands, and common mistakes are the hard parts.
- **Principle integrity.** Can't weaken the portability test for these categories without eroding it for everything.
- **Validator coherence.** The `validate-skill.sh` rule "≥3 project-specific file references" is the right gate for portable skills but wrong for shipped templates with placeholder paths.
- **Discoverability.** A user who finds `skills/scaffolding/add-api-endpoint.md` needs to immediately know "this is a template; adapt placeholders" — not assume it's broken.

## Considered Options

1. **Omit these categories entirely.** Users write from scratch. Keeps the library strictly portable.
2. **Include them as working skills with generic defaults.** Risks shipping skills that fail the portability test, undermining principle 06.
3. **Ship them as templates with explicit placeholders and a category-README explaining the workflow.** Users adapt.
4. **Generate them at adoption time via a setup script.** Reintroduces a generator mechanism, contradicts ADR 0001.

## Decision

We chose **Option 3: ship as templates**.

`skills/scaffolding/`, `skills/debugging/`, `skills/reference/` each contain:

- A category `README.md` documenting the pattern (the stable 5–6 step structure all skills of this category follow) and explicitly stating "these are templates — adapt `{{PLACEHOLDERS}}` to your project."
- A parameterized `TEMPLATE/SKILL.md` for authoring new skills of this category.
- An `examples/` directory with 5–7 worked skeletons using placeholder conventions.

The `validate-all.sh` script deliberately skips these three directories, because the shipped examples are expected NOT to pass `validate-skill.sh`'s strictest gate (≥3 project-specific refs) until a user adapts them. Each category README documents this explicitly.

Each example marks itself with an `<!-- ADAPT TO YOUR PROJECT -->` comment block at the top, listing placeholders to replace.

## Consequences

### Positive

- Users get a massive head-start on writing scaffolding/debugging/reference skills — structure, verify sections, common mistakes.
- The three categories preserve principle 06: when adapted, each skill works in its project and fails in others.
- Debugging skills are the closest to portable — about 80% of each example works unchanged; only log paths and repro commands need substitution. This is called out in the category README.
- Reference skills encode the SHAPE of good domain-knowledge documentation, which is portable even if the content isn't.

### Trade-offs

- Users must do adaptation work before using a scaffolding/debugging/reference skill. Not drop-in-ready.
- The `validate-all.sh` skipping these three directories is a minor inconsistency that every contributor must internalize.
- Someone reading `skills/scaffolding/examples/add-api-endpoint.md` might mistake it for a working skill at first glance — mitigated by the prominent "Adapt to your project" comment and the category README.
- The distinction between portable categories (meta, workflow, documentation, planning) and template categories (scaffolding, debugging, reference) adds taxonomy complexity.

## References

- [`../skills/scaffolding/README.md`](../skills/scaffolding/README.md), [`../skills/debugging/README.md`](../skills/debugging/README.md), [`../skills/reference/README.md`](../skills/reference/README.md) — per-category rules.
- [`../principles/06-portability-test.md`](../principles/06-portability-test.md) — the principle whose exception this ADR formalizes.
- [`0002-hybrid-taxonomy-seven-skill-categories.md`](0002-hybrid-taxonomy-seven-skill-categories.md) — the taxonomy that distinguishes portable vs template-only categories.
