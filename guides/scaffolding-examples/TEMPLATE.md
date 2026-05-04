---
name: add-{{ENTITY_NAME}}
description: >
  Scaffold a new {{ENTITY_NAME}} in this project, following the existing pattern. Creates the
  {{ENTITY_NAME}} file(s), wires them into {{REGISTRATION_POINT}}, and adds tests.
  Use when user says 'add a new {{ENTITY_NAME}}', 'scaffold a {{ENTITY_NAME}}', 'create
  another {{ENTITY_NAME}}', or 'new {{ENTITY_NAME}} for X'. Do NOT use for modifying an
  existing {{ENTITY_NAME}} (just edit it) or for a related-but-different entity (use the
  corresponding add-* skill).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new {{ENTITY_NAME}}

<!--
  ADAPT TO YOUR PROJECT:
    {{ENTITY_NAME}}       — the thing being added (User, Order, Component, ...)
    {{SOURCE_DIR}}        — where entities of this kind live (src/{{entities}}/, packages/*/models/)
    {{EXEMPLAR_PATH}}     — an existing instance worth copying (`src/users/user.ts`)
    {{REGISTRATION_POINT}} — the files that must be edited to register the new entity
    {{TEST_DIR}}          — where tests live (`tests/`, `src/**/*.spec.ts`)
    {{TEST_COMMAND}}      — how to run the tests (`pnpm test`, `pytest`, `cargo test`)
  Remove this comment block after adapting.
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_PATH}}` — the canonical {{ENTITY_NAME}} to copy the structure from. Do NOT invent — match what the project already does.
- **Registration point:** `{{REGISTRATION_POINT}}` — the file(s) that list every {{ENTITY_NAME}}. Missing this is the #1 reason scaffold skills fail.
- **Naming convention:** {{NAMING_RULE}} (e.g., "PascalCase class in a kebab-case file").
- **Test fixture pattern:** `{{TEST_FIXTURE_FILE}}` — how existing {{ENTITY_NAME}} tests set up their data.

## Step 1: name the new {{ENTITY_NAME}}

Confirm the name with the user. It must be {{NAMING_RULE}}. Check for collisions:

```bash
grep -rn "class {{NAME}}\b\|const {{NAME}}\b" {{SOURCE_DIR}}
```

## Step 2: create the {{ENTITY_NAME}} file

Copy the structure from `{{EXEMPLAR_PATH}}`:

```bash
cp {{EXEMPLAR_PATH}} {{SOURCE_DIR}}/{{new-entity-file}}
```

Adjust: the entity name, the type/schema, any fields specific to this {{ENTITY_NAME}}.

## Step 3: register the {{ENTITY_NAME}}

Open `{{REGISTRATION_POINT}}` and add the new {{ENTITY_NAME}}. Follow the existing alphabetical / insertion-order convention.

If there are multiple registration points (e.g., an export barrel, a DI container, a router), update all of them. A grep for the exemplar's name will reveal each:

```bash
grep -rn "{{EXEMPLAR_BASENAME}}" {{SOURCE_DIR}} {{REGISTRATION_DIR}}
```

## Step 4: add tests

Create `{{TEST_DIR}}/{{new-entity-test-file}}` following the pattern in `{{TEST_FIXTURE_FILE}}`.

At minimum:

- Happy path — the {{ENTITY_NAME}} works for the canonical input.
- One error path — what should happen on invalid input / permission denied / missing dependency.

## Step 5: verify

```bash
# The new file exists
test -f {{SOURCE_DIR}}/{{new-entity-file}} && echo ok

# The registration file references it
grep -q "{{NAME}}" {{REGISTRATION_POINT}} && echo ok

# Tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-entity-test-file}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| File created but not registered | Step 3. The {{ENTITY_NAME}} exists on disk but is dead code. |
| Copying the exemplar without updating all identifiers | Find-and-replace the exemplar's name → the new name. Easy to miss inner references. |
| Test passes with a trivial assertion (`expect(x).toBeDefined()`) | Assert the actual behavior. Existence-only tests catch nothing. |
| Adding a convention the codebase doesn't use | Match the exemplar. If you want a new convention, that's a separate decision — write an ADR first. |
