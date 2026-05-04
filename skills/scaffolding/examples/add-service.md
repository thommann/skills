---
name: add-service
description: >
  Scaffold a new service class — the business-logic layer between controllers and repositories.
  Use when user says 'add a service', 'new service class', 'create business logic for X', or
  'scaffold service layer'. Do NOT use for adding a method to an existing service (edit directly),
  for data access (use add-data-model + the repository it creates), or for API endpoints
  (use add-api-endpoint).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new service

<!--
  ADAPT TO YOUR PROJECT:
    {{SERVICES_DIR}}     — `src/services/`, `src/core/services/`, `packages/*/services/`
    {{SERVICE_BASE}}     — base class / interface services extend, if any (`ServiceBase`, `Injectable`)
    {{DI_CONTAINER}}     — where services register (Nest module, Fastify decorate, Django AppConfig, ...)
    {{TEST_DIR}}         — `tests/services/`, `src/services/**/*.spec.ts`
    {{TEST_COMMAND}}     — `pnpm test`, `pytest`, `cargo test`
    {{EXEMPLAR_SERVICE}} — a recently-added service
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_SERVICE}}` — the canonical recently-added service. Copy structure and dependencies.
- **Layer boundary:** services call repositories, not the ORM directly. Services are called by handlers, not other services (usually — check the project's rule).
- **DI pattern:** constructor injection vs static methods vs functional. Match what the exemplar does.

## Step 1: confirm the responsibility

A service owns ONE domain concern. Confirm the scope with the user:

- What does this service do? (one sentence)
- What does it NOT do? (draws the boundary to sibling services)

If the answer to "what does it do" is "stuff about X" with multiple concerns, split into multiple services before scaffolding.

## Step 2: create the service file

Copy the exemplar:

```bash
cp {{EXEMPLAR_SERVICE}} {{SERVICES_DIR}}/{{new-service-file}}
```

Update:

- Class name.
- Injected dependencies (usually repositories + other services).
- Methods — the concrete operations. Keep each method small; if a method exceeds ~30 lines, consider extracting a helper.

The exemplar's base class, decorators, and import style are authoritative — match them.

## Step 3: register in the DI container

Open `{{DI_CONTAINER}}` and add the service. Patterns differ by framework:

- **Nest:** add to `providers: []` in the module.
- **Fastify:** `fastify.decorate('newService', new NewService(...))` at app bootstrap.
- **Python (FastAPI / Litestar):** add to the dependency factory.
- **Manual:** export an instance from a module-level file; consumers import it.

Check the exemplar's registration site:

```bash
grep -rn "{{ExemplarServiceName}}" {{DI_CONTAINER}} {{SERVICES_DIR}}
```

## Step 4: add tests

Services are the sweet spot for unit tests — they have business logic but don't touch I/O directly.

Create `{{TEST_DIR}}/{{new-service-test}}`:

- Mock the repository dependencies with simple in-memory stubs.
- Test each public method's happy path.
- Test each method's error branches (not-found, validation failure, permission denial).

If the service orchestrates multiple repositories, add an integration test against a real DB for the full flow.

## Step 5: verify

```bash
# Service file exists
test -f {{SERVICES_DIR}}/{{new-service-file}} && echo ok

# DI container registers it
grep -q "{{NewServiceName}}" {{DI_CONTAINER}} && echo ok

# Unit tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-service-test}}

# Integration tests pass (if applicable)
{{TEST_COMMAND}} tests/integration/{{new-service-name}}*
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Calling the ORM directly from the service | Call the repository. Services should be data-source-agnostic. |
| Injecting another service that itself injects this service (cycle) | Split: extract the shared logic into a third service or a utility module. |
| Service method that does three unrelated things | Split into three methods. One method, one responsibility. |
| Testing only by mocking everything | Pure-mock tests prove the mocks are consistent with themselves. Add at least one integration test hitting real I/O. |
