# 02 — Dense, not brief

> A 300-line CLAUDE.md that's load-bearing in every line beats an 80-line one missing critical context.

## Why

The fear of "too long" leads to artifacts that omit the facts agents actually need — the hidden invariants, the gotchas, the non-obvious conventions. Context windows are large; what they can't tolerate is vagueness. Every sentence should either teach something the reader couldn't infer from the code, or go.

Density means: high signal per line, not verbose prose. A dense CLAUDE.md is a reference document, not a marketing page.

## Rule

- Write every line until it carries information a reader can't derive from the current source tree.
- Prefer tables, bullet lists, and pipe tables over paragraphs for look-up content.
- Do not pad with transitions ("In summary...", "As mentioned above...") — they add line count and zero signal.
- If a section shrinks to a single sentence, merge it or delete it. Sections exist to organize information, not to reach a template.

## How validators check it

- `validate-claude-md.sh` **warns** on files under 50 lines ("likely too thin"). Under 30 is a hard error.
- `validate-claude-md.sh` **errors** on CLAUDE.md with zero code blocks AND zero pipe tables ("no commands, no file paths — this can't be load-bearing").
- `validate-skill.sh` **warns** on files over 600 lines ("split into multiple skills instead").

## Good vs bad

**Bad (too thin):**
```markdown
## Testing

We use Jest for unit tests and Playwright for end-to-end tests. Run tests before committing.
```

**Good (dense):**
```markdown
## Testing

| Kind | Command | Location | Fixture source |
|---|---|---|---|
| Unit | `pnpm test:unit` | `**/*.spec.ts` | `tests/fixtures/unit.ts` |
| Integration | `pnpm test:int` | `tests/integration/` | `tests/fixtures/db.ts` (uses `testcontainers`) |
| E2E | `pnpm test:e2e` | `tests/e2e/*.spec.ts` | `tests/e2e/fixtures.ts` (starts the API + DB) |

Integration tests **must** hit a real Postgres (via `testcontainers`) — see ADR `docs/adr/0014-no-mock-db.md` for the reason. Mocking the DB is caught by `scripts/check-no-db-mocks.ts`.

E2E suite requires the dev server running (`pnpm dev`) — CI starts it via `.github/workflows/e2e.yml`.
```

The good version costs ~12 lines, the bad one ~2. The good one lets an agent produce correct work. The bad one forces the agent to guess or ask.
