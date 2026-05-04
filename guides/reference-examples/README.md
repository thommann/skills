# Reference skills — the pattern

Reference skills encode **domain knowledge a contributor needs but can't derive from the code alone**. They are the hardest category to ship as templates because the *content* is the value, and that content is inherently project-specific.

What this library can ship: the **shape** of a good reference skill. Examples are pattern skeletons; the user fills in the actual knowledge.

## The pattern (every reference skill looks like this)

1. **Header: what this reference covers.** State the boundary explicitly. What does it NOT cover? Point at a sibling skill for adjacent concerns.
2. **Minimum-viable example.** The smallest complete usage of the pattern, with file references. A reader should be able to copy this and get a working instance in 5 minutes.
3. **The contract.** The interface, required fields, lifecycle, invariants. What must be true for the pattern to work? What does the framework enforce vs what must the code enforce?
4. **Extension points.** How to add a new variant of the pattern. Often links to a scaffolding skill.
5. **Common pitfalls.** 2–4 real mistakes contributors have made, with corrections.
6. **Source of truth.** Which file(s) to read when this skill goes stale. Reference skills will eventually rot — give future readers a path to verify.

## Contents

- [`TEMPLATE/SKILL.md`](TEMPLATE/SKILL.md) — annotated parameterized skeleton.
- [`examples/framework-patterns.md`](examples/framework-patterns.md) — "how we use {framework}" pattern.
- [`examples/auth-reference.md`](examples/auth-reference.md) — identity, sessions, permission checks.
- [`examples/state-management.md`](examples/state-management.md) — client-side store OR server-side state layering.
- [`examples/event-system.md`](examples/event-system.md) — messaging / event-bus conventions.
- [`examples/configuration.md`](examples/configuration.md) — config layering (file → env → runtime overrides).

## How to adapt an example

Each example is largely a skeleton. You fill:

| Placeholder | Replace with |
|---|---|
| `{{SUBSYSTEM_NAME}}` | Your subsystem — `auth`, `events`, `settings`. |
| `{{CONTRACT_FILE}}` | The file defining the contract — `src/auth/contract.ts`, `packages/core/events/base.py`. |
| `{{EXAMPLE_FILES}}` | 1–2 canonical usages. |
| `{{EXTENSION_POINT}}` | Where to add a new variant — a factory, a registry, a subclass. |

Reference skills start out thin and grow as the project learns. A 100-line `auth-reference.md` that cites 3 real files beats a 400-line one that invents conventions.

## Validation

Reference examples use backticked placeholder references, so they pass `validate-skill.sh` as shipped. After substitution they should still pass.

```bash
bash validation/validate-skill.sh .claude/skills/reference/auth-reference/SKILL.md
```

## When NOT to write a reference skill

- The pattern is already in an ADR (`docs/adr/`). Point at the ADR; don't duplicate.
- The pattern is framework-standard (e.g., "how Express middleware works"). The framework's docs cover it; write a skill only if your usage is non-standard.
- The subsystem is shrinking or being removed. Reference skills for dying code are a liability.

Reference skills earn their keep when the project has invented a project-specific convention on top of a framework, and contributors consistently get it wrong.
