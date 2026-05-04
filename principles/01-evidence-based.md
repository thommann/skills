# 01 — Evidence over opinion

> Every line must trace to a real file, command, or convention. If you can't cite where you found it, delete it.

## Why

Generated or hand-written configuration drifts from reality within weeks. A skill that says "our auth uses JWT" without pointing at the file that implements it becomes wrong the moment someone swaps to sessions. If the reader can't verify the claim by opening a file, the claim is noise and teaches nothing.

This principle is the difference between a `.claude/` that earns its keep and one that poisons the agent's context.

## Rule

Every declarative statement in a skill, agent, hook, or CLAUDE.md must be backed by one of:

- **A file reference** in backticks: `` `src/auth/jwt.ts` ``
- **A command** the reader can run: `pnpm test`, `ruff check`
- **A convention anchored in a named file**: "filenames follow the pattern established in `docs/adr/template.md`"

Opinion-shaped language without a citation is removed. Examples that fail the rule:

- "We follow clean code principles." → generic phrase + no citation. Delete.
- "Use immutable data structures where appropriate." → opinion without anchor. Delete or rewrite.
- "Our API layer uses dependency injection." → add `` `src/api/container.ts` ``.

## How validators check it

- `validate-skill.sh` counts backtick-wrapped path-like strings (matches `/`, well-known dirs `src|packages|apps|...`, and file extensions). **<3 references → hard error** ("Skill is too generic").
- `validate-claude-md.sh` requires ≥1 code block or pipe-table. A CLAUDE.md with zero commands and zero file paths fails.
- The generic-phrase grep (`skills/meta/create-or-audit-skill/lib/generic-phrases.txt`) runs against every artifact.

## Good vs bad

**Bad:**
```markdown
Follow our established patterns for error handling. Use structured logging and avoid generic catch blocks.
```

**Good:**
```markdown
Error handling uses the `AppError` hierarchy defined in `src/errors/index.ts`. Controllers catch
`AppError` in the boundary middleware (`src/middleware/errors.ts`) and map to HTTP status via
`AppError.statusCode`. A generic `try { ... } catch (e) { logger.error(e) }` defeats this —
throw typed errors instead. See `src/users/service.ts:45` for the canonical example.
```

The good version is longer, denser, and the reader can open three files to verify every claim.
