---
name: add-frontend-page
description: >
  Scaffold a new frontend page — route + view component + types + minimum data fetching. Use
  when user says 'add a page', 'new route for X', 'scaffold a page', or 'create a new view'.
  Do NOT use for reusable components (use add-frontend-component), for pure API endpoints
  (use add-api-endpoint), or for modifying an existing page.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new frontend page

<!--
  ADAPT TO YOUR PROJECT:
    {{PAGES_DIR}}        — `src/pages/`, `app/`, `src/views/`, `src/routes/`
    {{ROUTER_FILE}}      — router config if explicit: `src/router.ts`, `src/App.tsx`. File-routing frameworks (Next.js, Nuxt) skip this.
    {{TYPES_DIR}}        — `src/types/`, `src/sdk/`, `packages/*/types/`
    {{TEST_DIR}}         — `tests/e2e/`, `src/**/*.spec.ts`
    {{TEST_COMMAND}}     — `pnpm test`, `pnpm e2e`
    {{EXEMPLAR_PAGE}}    — a recently-added page
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_PAGE}}` — a recently-added page. Copy structure, layout wrapper, data fetching pattern.
- **Routing convention:** file-based (Next.js, Nuxt, Remix) OR explicit router (React Router, Vue Router)? Match the exemplar.
- **Data fetching:** server components, client queries (React Query / Pinia Colada / SWR), or server-rendered? The exemplar's choice is the project's choice.
- **Layout:** does the page use a project-wide layout wrapper (`<AppLayout>`)? Exemplar knows.

## Step 1: decide the route

Confirm path (`/users`, `/orders/[id]`, `/settings/billing`), dynamic segments, and access requirements (public, authenticated, role-restricted).

Check for collisions:

```bash
find {{PAGES_DIR}} -name "*{{path-component}}*"
```

## Step 2: create the page file

Copy the exemplar:

```bash
# File-based routing: use the framework's file-name convention
cp {{EXEMPLAR_PAGE}} {{PAGES_DIR}}/{{new-page-path}}

# Explicit routing: any file name works, but match the convention in {{PAGES_DIR}}
```

Update: page title, layout (if the project has a choice), query hooks / server-data-fetch, rendered components.

Keep the page file SMALL. Business logic → composables / hooks. UI chunks → components. A page that's 300 lines is hiding components that should be extracted.

## Step 3: register in the router (explicit routing only)

If the project uses an explicit router (`{{ROUTER_FILE}}`), add the route:

```bash
# React Router: add to the routes array
# Vue Router: add to the routes config
# Others: match the exemplar
grep -rn "{{ExemplarPagePath}}" {{ROUTER_FILE}}
```

File-based routing frameworks pick up the file automatically — skip this step.

## Step 4: add types for the page's data

If the page fetches from an API, the request/response types usually come from a generated SDK (`{{TYPES_DIR}}`). Check whether a regen is needed:

```bash
# Common: pnpm generate-sdk, openapi-typescript, graphql-codegen
# Pull the command from CLAUDE.md Quick Reference
```

Never hand-write types that should come from the API contract — they'll drift.

## Step 5: add tests

Choice depends on the project's testing posture:

- **Component tests** (Vitest + React Testing Library / Vue Test Utils): render the page with mocked data, assert the critical rendering path.
- **E2E tests** (Playwright, Cypress): navigate to the page, interact with a key element, assert the result.
- **Snapshot tests**: avoid unless the project already relies on them. Snapshots rot faster than focused assertions.

At minimum: one test that renders the page without data errors.

## Step 6: verify

```bash
# The page file exists
test -f {{PAGES_DIR}}/{{new-page-path}} && echo ok

# (Explicit routing only) the router registers it
grep -q "{{new-page-path-or-id}}" {{ROUTER_FILE}} && echo ok

# The dev server renders the page without console errors
# {{DEV_COMMAND}}  (e.g., `pnpm dev`)
# then navigate to the new route in a browser

# Tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-page-test}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Page fetches data with a hand-crafted URL instead of the generated client | Use the SDK. Hand-crafted URLs skip type safety and drift from the backend. |
| 400-line page component with inline logic | Extract into smaller components + a composable/hook for state. |
| Missing auth guard on a protected page | Check the exemplar's guard / middleware. File-routing frameworks usually have a layout-level guard; explicit routers require per-route protection. |
| Added to the router but the file name doesn't match the framework's expected path | File-based routers are strict about names. Check a passing page in the same folder for the convention. |
