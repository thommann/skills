# {Subdirectory / Package Name}

<!--
  SUBDIRECTORY CLAUDE.md template.

  Create a subdirectory CLAUDE.md when ANY of these are true:
    1. The directory uses a different language or framework than the project root.
    2. The directory has 3+ patterns that differ from the root.
    3. The directory has its own build/test commands.
    4. The directory has 10+ source files with distinct conventions.

  This file must be SELF-CONTAINED: a developer working in this directory should not need to
  flip back to the root CLAUDE.md to get their work done.

  Quality gates are the same as root CLAUDE.md but the file can be shorter (≥30 lines minimum).
-->

One-line description of what this subdirectory IS within the parent project.

## Quick Reference

| Task | Command |
|---|---|
| Install deps (if separate) | `<cmd>` |
| Run this service/package | `<cmd>` |
| Run tests for this scope | `<cmd>` |
| Lint this scope | `<cmd>` |

## Architecture (this scope)

### Role

<!-- What this scope owns within the project. One paragraph. -->

### Structure

```
<this-dir>/
├── <file>       # <purpose>
├── <file>       # <purpose>
└── ...
```

### Boundaries

<!-- What this scope MAY import from (and what it MUST NOT). Reference the rule. -->

- May depend on: `<parent-scope-of-shared-code>`
- Must not depend on: `<sibling-scopes>`
- Enforcement: `<lint rule | build rule | convention doc>`

## Patterns Specific to This Scope

<!-- What differs from the root CLAUDE.md for work done in this directory. -->

## Things to Know

<!-- Gotchas specific to this scope. Each: what happens, why, what to do. -->

## Testing

<!-- If tests run differently here — specifics. Otherwise link to root CLAUDE.md. -->
