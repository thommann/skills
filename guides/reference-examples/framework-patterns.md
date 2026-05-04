---
name: framework-patterns
description: >
  Reference for how this project uses its primary framework — the project-specific conventions
  layered on top of the framework's own patterns. Use when user says 'how do we use {framework}',
  'what's our {framework} pattern', 'show me our {framework} convention', or 'how is {framework}
  set up here'. Do NOT use for framework-level documentation (read the framework's docs), for
  debugging (use debug-backend or debug-frontend), or for adding new instances (use the
  scaffolding skill).
allowed-tools: Read, Grep, Glob
---

# {{FRAMEWORK_NAME}} — reference for this project

<!--
  ADAPT TO YOUR PROJECT:
    {{FRAMEWORK_NAME}}       — FastAPI, Nest, Vue, React, Rails, ...
    {{ENTRY_POINT}}          — `src/app.ts`, `src/main.py`, `src/index.tsx`
    {{ROUTES_DIR}}           — where the framework's routes/controllers live
    {{EXEMPLAR_USAGE}}        — 1–2 canonical files
    {{PROJECT_EXTENSIONS}}    — any project-specific base class, decorator, or plugin on top
-->

## What this reference covers

Project-specific conventions for {{FRAMEWORK_NAME}} — the patterns that aren't from the framework's docs but from this codebase's local decisions.

**NOT covered:**

- How {{FRAMEWORK_NAME}} works in general — read the framework's docs.
- Debugging {{FRAMEWORK_NAME}} issues — see `debug-backend` / `debug-frontend`.
- Adding a new {{FRAMEWORK_NAME}} instance — see the corresponding scaffolding skill.

## Minimum-viable example

The smallest complete usage — `{{EXEMPLAR_USAGE}}`. Open this file before writing anything new; copy its shape.

## The contract

- **Entry point:** `{{ENTRY_POINT}}` — where {{FRAMEWORK_NAME}} is bootstrapped. Config loading, middleware registration, plugin wiring.
- **Layer boundaries:** this project layers {{FRAMEWORK_NAME}} as: {{LAYER_DESCRIPTION}} — e.g., "route → controller (thin) → service → repository." A router that calls an ORM directly violates this layering.
- **Base class / common abstraction:** `{{PROJECT_EXTENSIONS}}` — if the project wraps the framework's primitives (e.g., every controller extends `BaseController`, every service is `@Injectable`). Use it; don't bypass.

## Project-specific conventions on top of the framework

Conventions that aren't enforced by {{FRAMEWORK_NAME}} but are followed consistently here:

- **Naming:** {{NAMING_RULE}} (e.g., "routes named `<resource>-controller.ts`, services `<resource>-service.ts`").
- **Error handling:** {{ERROR_HANDLING}} (e.g., "every controller throws typed errors from `src/errors/`; a boundary middleware maps them to HTTP status codes").
- **Validation:** {{VALIDATION_RULE}} (e.g., "request bodies validated via Zod schemas in `src/api/schemas/`; never hand-parse `req.body`").
- **Auth:** `{{AUTH_ENTRY_POINT}}` — where request identity is loaded. The convention for checking permissions on a new endpoint.
- **Config:** how {{FRAMEWORK_NAME}} reads config — see `reference/configuration` for the full rule.
- **Observability:** logging / tracing / metrics conventions — see `reference/observability` if that skill exists.

## Extension points

Adding a new variant of the framework's primitive (middleware, plugin, route group):

1. See the scaffolding skill most relevant (e.g., `scaffolding/add-api-endpoint` for a new route).
2. Register the new variant at `{{REGISTRATION_POINT}}` — the framework won't auto-discover everything.
3. If the extension needs a project-specific base class, see `{{PROJECT_EXTENSIONS}}`.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| Using the framework's primitive directly instead of the project's wrapped version | Use `{{PROJECT_EXTENSIONS}}` — the wrapper adds logging, tracing, and error handling that the raw primitive lacks. |
| Parsing request input manually | Use the schema-validation system. Manual parsing skips type safety AND the project's structured error responses. |
| Importing from the framework's internal modules | Import from the framework's public API. Internals change between versions. |
| Registering a new endpoint in the router config but not adding the handler | `{{REGISTRATION_POINT}}` and the handler file must both exist. Check with `grep`. |

## Source of truth

When this skill goes stale:

- **Entry point:** `{{ENTRY_POINT}}` — the actual bootstrap.
- **Canonical example:** `{{EXEMPLAR_USAGE}}` — reflects current convention.
- **Project extensions:** `{{PROJECT_EXTENSIONS}}` — the wrapper layer.
- **Framework docs:** the installed version's docs (check the project's lockfile for the exact version).

## Verify

```bash
for p in {{ENTRY_POINT}} {{EXEMPLAR_USAGE}} {{PROJECT_EXTENSIONS}} {{REGISTRATION_POINT}}; do
  [ -e "$p" ] || echo "STALE: $p"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Extending this skill with framework-level content | That belongs in the framework's docs. Keep this skill focused on what this project adds. |
| Documenting conventions without a canonical file reference | Every convention cites `{{EXEMPLAR_USAGE}}` or an equivalent. Unanchored conventions drift. |
| Skill that contradicts the current `{{EXEMPLAR_USAGE}}` | Update the skill — the file wins. |
| Over-relying on the wrapper when the framework primitive would do | Sometimes raw framework primitives are fine. The wrapper adds value; it's not religion. |
