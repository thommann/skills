# Scaffolding skills — the pattern

Scaffolding skills answer the question **"how do I add a new X in THIS codebase?"** They are inherently project-specific — a skill that scaffolds an API endpoint must name the project's router, service layer, and test fixtures.

This library ships the **pattern** and a set of **worked example templates**. Users copy a template and substitute `{{PLACEHOLDERS}}` with their project's paths and conventions.

## The pattern (every scaffolding skill looks like this)

1. **Identify the exemplar.** Before writing a new X, read the most-recently-added X as the template. Don't invent; copy the prevailing structure.
2. **Follow naming conventions.** The project has a rule (kebab-case, snake_case, PascalCase) — state it and point at a file that obeys it.
3. **Wire it up.** List every registration point: router, DI container, migrations list, i18n keys, export barrel, module registry. Wiring is the #1 forgotten step.
4. **Add tests.** Point at the test-fixture pattern with a happy-path and an error-path example.
5. **Verify.** Exact commands that confirm the addition worked (test, type-check, startup-without-error).

A scaffolding skill missing step 3 (wiring) is the most common failure mode.

## Contents

- [`TEMPLATE.md`](TEMPLATE.md) — annotated parameterized skeleton.
- [`examples/add-api-endpoint.md`](examples/add-api-endpoint.md) — backend route + controller + service pattern.
- [`examples/add-data-model.md`](examples/add-data-model.md) — ORM model + migration pattern.
- [`examples/add-service.md`](examples/add-service.md) — business-logic layer between controllers and repositories.
- [`examples/add-frontend-page.md`](examples/add-frontend-page.md) — route + view + types.
- [`examples/add-frontend-component.md`](examples/add-frontend-component.md) — component + story/test + barrel export.
- [`examples/add-migration.md`](examples/add-migration.md) — schema migration with rollback.
- [`examples/add-test-suite.md`](examples/add-test-suite.md) — fixtures, mocks, happy-path + edge cases.

## How to adapt an example

Every example has an "Adapt to your project" block at the top listing placeholders. Typical substitutions:

| Placeholder | Replace with |
|---|---|
| `{{ROUTER_FILE}}` | Your router module — `src/api/router.ts`, `src/app/routes.ts`, ... |
| `{{SERVICE_DIR}}` | Where services live — `src/services/`, `src/core/services/`, ... |
| `{{TEST_DIR}}` | Where tests go — `tests/`, `__tests__/`, `src/**/*.spec.ts`, ... |
| `{{TEST_COMMAND}}` | Your test command — `pnpm test`, `pytest`, `cargo test`, ... |
| `{{NAMING}}` | Your naming rule — "kebab-case file names", "PascalCase classes", ... |
| `{{ENTITY_NAME}}` | The thing being added — `User`, `Order`, `Subscription`, ... |

Do the substitution once per placeholder (find-and-replace). Remove the "Adapt to your project" block after substitution. Run `skills/meta/create-or-audit-skill/lib/validate.sh` on the result — if it still fails the ≥3 file-reference rule, add 2–3 real file paths to your body.

## Validation

These examples will NOT pass `validate-skill.sh` cleanly as shipped — they contain placeholders rather than real paths for your codebase. After adaptation they should. `validate-all.sh` deliberately skips this directory.

To validate an adapted scaffolding skill:

```bash
bash skills/meta/create-or-audit-skill/lib/validate.sh .claude/skills/scaffolding/add-api-endpoint/SKILL.md
```

## When NOT to write a scaffolding skill

- The "thing to add" happens less than monthly. A `CLAUDE.md` line is enough.
- The "thing to add" is a single file with no wiring. That's not a multi-step workflow.
- A hook already handles it deterministically (rare, but possible for auto-registration setups).

In those cases, go back to [`../meta/create-or-audit-skill/SKILL.md`](../meta/create-or-audit-skill/SKILL.md) and reconsider.
