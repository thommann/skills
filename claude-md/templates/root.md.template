# {Project Name}

<!--
  ROOT CLAUDE.md template.

  Required sections (enforced by validation/validate-claude-md.sh):
    1. # Project title + one-line description
    2. ## Quick Reference   — task→command table
    3. ## Architecture      — the longest section: Overview, Directory Structure, Subsystems, Key Abstractions
    4. ## Patterns and Conventions
    5. ## Development Workflow
    6. ## Things to Know
    7. ## Security-Critical Areas
    8. ## Domain Terminology

  Quality gates:
    - No banned generic phrases (see ../../validation/lib/generic-phrases.txt).
    - Every prohibition must include an alternative in the same section (principle 05).
    - At least one code block or pipe table — prose-only CLAUDE.md is rejected.
    - Minimum ~100 lines of load-bearing content. Under 50 lines = warning, under 30 = error.
-->

A one-line description of what this project IS (not what it aspires to be).

## Quick Reference

| Task | Command |
|---|---|
| Install dependencies | `<install cmd>` |
| Run the app locally | `<run cmd>` |
| Run tests | `<test cmd>` |
| Lint | `<lint cmd>` |
| Format | `<format cmd>` |
| Type-check | `<typecheck cmd>` |
| Build for production | `<build cmd>` |
| Generate SDK / codegen | `<codegen cmd>` |

## Architecture

### Overview

<!-- 2–3 paragraphs. What the major subsystems are, how they communicate, what the deployment model looks like. Reference real top-level directories. -->

### Directory Structure

```
<project-root>/
├── <dir1>/          # <what lives here>
├── <dir2>/          # <what lives here>
└── ...
```

### <Subsystem 1>

<!-- Deep-dive. Where its code lives, what it's responsible for, how it interacts with adjacent subsystems. Reference key files. -->

### <Subsystem 2>

<!-- ... -->

### Key Abstractions

<!-- Named classes/modules/protocols that matter. For each: what it is, where it lives, why it exists. -->

## Patterns and Conventions

### Naming

<!-- Non-tooling-enforced naming rules only. If ESLint or Ruff enforces it, don't restate. -->

### Imports / Module Boundaries

<!-- If there's a dependency direction (monorepo), state it here with file references. -->

### Error Handling

<!-- The project-specific error hierarchy and how it's thrown/caught. Point at files. -->

### Logging

<!-- Which logger, where it's configured, what structured fields are expected. -->

## Development Workflow

### Building and Running

<!-- The happy path: clone → install → run → observe. Commands, not prose. -->

### Testing

<!-- Tiers of tests, where they live, how to run a single one, what fixtures exist. -->

### Tooling

<!-- Linters, formatters, type checkers, code generators. Pre-commit hooks if any. -->

## Things to Know

<!--
  The most important section for an agent. List gotchas, hidden invariants, surprising rules,
  things that will bite someone who doesn't know them. Every entry should have:
    - What happens
    - Why
    - What to do instead

  Examples of the shape:

  - **Database migrations**: run `<migration cmd>` only from the `<dir>` — running it from the repo
    root silently creates a duplicate config file. See ADR `docs/adr/0012-single-migration-root.md`.

  - **Environment variables**: the app reads `.env` at startup via `<loader>`. Variables added after
    startup are ignored; restart. There's no hot-reload because `<reason>`.
-->

## Security-Critical Areas

<!--
  Files that need human review when modified. Short list, ≤10 items.

  - `src/auth/` — authentication flow
  - `src/middleware/rate-limit.ts` — abuse prevention
  - `<migration dir>` — irreversible schema changes
-->

## Domain Terminology

<!-- Project-specific glossary. One line per term. -->

- **<Term>** — <what it means in this project's context>
- **<Term>** — <...>
