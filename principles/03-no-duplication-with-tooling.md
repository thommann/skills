# 03 — Don't duplicate tooling

> If a linter, formatter, or hook enforces a rule, don't restate it in prose.

## Why

Rules stated in two places drift. A prose rule "always 2-space indentation" alongside a `.prettierrc` with `"tabWidth": 2` means the prose is redundant when they agree and wrong when they disagree. Worse, when the tooling changes, the prose silently becomes misinformation that the agent will follow for weeks.

The tool is the source of truth. The doc points at the tool.

## Rule

Prose should explain:

- **What** the tool does and **where** it lives (`ruff check` runs the rules in `pyproject.toml`).
- **Why** a non-obvious rule exists (if the reason would surprise a new reader).
- **How to override** when overriding is legitimate (`# noqa` comment with rationale).

Prose should NOT restate:

- Syntax rules the linter catches (line length, import order, trailing commas, naming conventions the linter enforces).
- Formatting rules the formatter handles (indentation, quote style, spacing).
- Commit message rules if `commitlint` runs in CI.
- Type rules if `tsc --noEmit` runs on every push.

## How validators check it

No automated validator catches this — it's human review. During review, ask: *"Is a tool already enforcing this? If yes, is the prose adding the **what**/**why**/**override**, or is it duplicating the rule?"* If the latter, delete the prose.

The generic-phrase ban (`skills/meta/create-or-audit-skill/lib/generic-phrases.txt`) catches some symptoms (e.g., "readable code" often accompanies duplicated lint rules).

## Good vs bad

**Bad:**
```markdown
## Code style

- Use 2-space indentation.
- Single quotes for strings.
- Trailing commas in multi-line literals.
- Import order: external packages first, then internal.
```

Every one of those is enforced by `prettier` + `eslint` in a typical JS project. The section is noise.

**Good:**
```markdown
## Code style

Formatting and lint rules live in `.prettierrc` and `eslint.config.ts`. `pnpm lint:fix` applies
them automatically; CI blocks merges that fail `pnpm lint`.

The one non-obvious rule: internal imports use the `@/` alias — a bare relative import like
`../../lib/x` is caught by `eslint-plugin-import`'s `no-relative-parent-imports`. This exists
because the codebase was refactored from a flat structure; see ADR `docs/adr/0008-path-aliases.md`.
```

The good version points at two real files, explains one surprising rule with its reason, and documents the override path.
