---
name: add-frontend-component
description: >
  Scaffold a new reusable UI component — the component file, its types, a test, a story (if the
  project uses Storybook), and a barrel export. Use when user says 'add a component', 'new
  UI component', 'extract into a component', or 'scaffold shared widget'. Do NOT use for a
  page-level view (use add-frontend-page) or for a one-off fragment that lives only in one
  place — inline it instead.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new frontend component

<!--
  ADAPT TO YOUR PROJECT:
    {{COMPONENTS_DIR}}   — `src/components/`, `packages/ui/src/`, `src/shared/components/`
    {{BARREL_FILE}}      — export index, if the project uses one: `src/components/index.ts`
    {{STORY_CONVENTION}} — `*.stories.tsx`, `*.story.vue`, or skip if no Storybook
    {{TEST_CONVENTION}}  — `*.test.tsx`, `*.spec.ts`
    {{TEST_COMMAND}}     — `pnpm test`, `vitest`
    {{EXEMPLAR_COMPONENT}} — a recently-added reusable component
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_COMPONENT}}` — a recently-added shared component. Copy the structure (props type, file layout, export pattern).
- **Props convention:** typed props interface at the top of the file (common in React/Vue TS projects) or inline (untyped projects).
- **Styling:** CSS Modules, Tailwind, styled-components, utility classes, design-system primitives? The exemplar's choice is the project's choice.
- **Accessibility baseline:** does the exemplar use semantic HTML, ARIA attributes, keyboard handling? Match that posture.

## Step 1: confirm the component belongs here

A reusable component earns a file in `{{COMPONENTS_DIR}}` when:

- It's used in two or more places, OR
- It encapsulates a non-trivial behavior (form field with validation, menu with keyboard nav) that isolating simplifies the caller.

If the fragment is used in exactly one place and is a straightforward wrapper, inline it.

## Step 2: create the component file

```bash
cp {{EXEMPLAR_COMPONENT}} {{COMPONENTS_DIR}}/{{NewComponent}}/{{NewComponent}}.tsx
```

Or if the project uses flat files:

```bash
cp {{EXEMPLAR_COMPONENT}} {{COMPONENTS_DIR}}/{{NewComponent}}.tsx
```

Update: props interface, render logic, styling hooks. Keep the component PURE — side effects belong in hooks/composables, not inline.

## Step 3: add the test

Create `{{TEST_CONVENTION}}` next to the component or under `{{TEST_DIR}}`:

- **Renders without error** with minimal props.
- **Renders with each notable prop variation** (states: loading, error, empty, populated).
- **Responds to key user interactions** (click, keyboard events, form submission).
- **Accessibility sanity** — if the component is form-like or interactive, assert the role/label is reachable.

Component tests should run in JSDOM (or the project's equivalent). Avoid full-app rendering; mount just this component.

## Step 4: add a story (if the project uses Storybook or similar)

```bash
cp {{EXEMPLAR_COMPONENT}}.stories.* {{COMPONENTS_DIR}}/{{NewComponent}}.stories.*
```

Stories document the component visually. Minimum: one story per notable prop variation. Stories double as free accessibility baselines — running a11y addons catches issues the test suite misses.

## Step 5: export from the barrel

If the project uses an export barrel:

```bash
# Common:
echo "export * from './{{NewComponent}}';" >> {{BARREL_FILE}}
# Or edit {{BARREL_FILE}} to insert the line alphabetically.
```

Without the barrel entry, consumers can still import the component via its full path, but they usually import from the barrel — missing exports cause "module not found" after refactors.

## Step 6: verify

```bash
# Component file exists
test -f {{COMPONENTS_DIR}}/{{NewComponent}}* && echo ok

# Barrel exports it (if used)
grep -q "{{NewComponent}}" {{BARREL_FILE}} && echo ok

# Tests pass
{{TEST_COMMAND}} {{COMPONENTS_DIR}}/{{NewComponent}}

# Dev server renders the story (if using Storybook)
# `pnpm storybook` — navigate to the new story
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Component fetches its own data via a global client | Reusable components accept data via props. Fetching couples them to the caller's data shape and breaks reuse. |
| Inline styles that violate the design system | Use the project's design-system tokens / primitives. Inline colors and spacing drift from the system. |
| Test asserts only "renders without crashing" | Assert the rendered output. Existence-only tests catch approximately nothing. |
| Forgetting the barrel export | Consumers will work through full paths; refactors will then break. Always update the barrel. |
