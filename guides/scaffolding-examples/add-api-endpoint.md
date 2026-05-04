---
name: add-api-endpoint
description: >
  Scaffold a new HTTP endpoint — route + controller/handler + service method + tests — following
  the project's existing pattern. Use when user says 'add an endpoint', 'new API route', 'add a
  route for X', or 'scaffold API handler'. Do NOT use for modifying an existing endpoint, for
  frontend routes (use add-frontend-page), or for changing the API's schema without adding an
  endpoint (modify the contract file directly).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new API endpoint

<!--
  ADAPT TO YOUR PROJECT (once per substitution):
    {{ROUTES_DIR}}        — `src/api/routes/`, `src/routes/`, `packages/api/src/routes/`
    {{CONTROLLERS_DIR}}   — `src/api/controllers/` or same as routes
    {{SERVICES_DIR}}      — `src/services/`, `src/core/services/`, `packages/*/services/`
    {{ROUTER_FILE}}       — where routes are wired: `src/api/router.ts`, `src/app.ts`
    {{TEST_DIR}}          — `tests/integration/api/`, `src/**/*.spec.ts`
    {{TEST_COMMAND}}      — `pnpm test`, `pytest`, `cargo test`, `go test`
    {{EXEMPLAR_ENDPOINT}} — a recently-added endpoint file
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_ENDPOINT}}` — the canonical recently-added endpoint. Copy its structure.
- **Router wiring:** `{{ROUTER_FILE}}` — where every endpoint registers. Check how the exemplar is registered.
- **Auth convention:** the exemplar's auth decorator/middleware. Public endpoints are rare; default to authenticated.
- **Error handling:** the project's error-response pattern — usually a shared middleware in `src/middleware/` or similar.

## Step 1: decide the route

Confirm with the user: path (`/api/v1/...`), method (GET / POST / PATCH / DELETE), auth level, rate-limit bucket.

Check for collisions:

```bash
grep -rn "'{{METHOD}}', ['\"]{{PATH}}['\"]" {{ROUTES_DIR}}
grep -rn '{{PATH}}' {{ROUTES_DIR}}
```

## Step 2: add the request/response schema

If the project uses typed schemas (Zod, Pydantic, JSON Schema, Protobuf), define the new schemas first. The handler is typed FROM the schema — never the other way around.

Look at the exemplar's schema file:

```bash
# Find the schema file pattern
find {{ROUTES_DIR}} -type f -name '*.schema.*' -o -name '*_schema.*' | head -5
```

Add `{{EndpointName}}Request` and `{{EndpointName}}Response` matching the style of the exemplar.

## Step 3: create the handler

Copy the exemplar and adapt:

```bash
cp {{EXEMPLAR_ENDPOINT}} {{ROUTES_DIR}}/{{new-endpoint-file}}
```

In the new file, update:

- Route path and method.
- Request/response schema references.
- Handler body — call the service layer (step 4), don't put business logic here.
- Auth and permission checks — match the exemplar's pattern.

## Step 4: add the service method

API handlers are thin; business logic goes in services.

- If a relevant service already exists in `{{SERVICES_DIR}}`, add a method to it.
- If not, create a new service following the pattern in `{{SERVICES_DIR}}/{{exemplar-service}}`.

The service method handles the work; the handler handles HTTP concerns (status codes, content negotiation, error mapping).

## Step 5: register the route

Open `{{ROUTER_FILE}}` and add the new handler to the registration list. Follow the existing alphabetical or grouped-by-resource order.

Many frameworks auto-discover routes from a directory; others require explicit registration. Check how `{{EXEMPLAR_ENDPOINT}}` reaches the router:

```bash
grep -rn "{{exemplar-name}}" {{ROUTER_FILE}} {{ROUTES_DIR}}
```

## Step 6: add tests

Create `{{TEST_DIR}}/{{new-endpoint-test}}` with at minimum:

- **Happy path** — authenticated request with valid payload returns 2xx and the expected shape.
- **Auth** — unauthenticated request returns 401; authenticated-but-unauthorized returns 403.
- **Validation** — malformed payload returns 400 with a useful error.
- **One not-found** — request for a missing resource returns 404 (if applicable).

Test fixtures pattern:

```bash
find {{TEST_DIR}} -type f -name 'conftest.*' -o -name 'fixtures*' -o -name 'setup*' | head -5
```

## Step 7: verify

```bash
# The endpoint file exists
test -f {{ROUTES_DIR}}/{{new-endpoint-file}} && echo ok

# The router references it
grep -q "{{new-endpoint-identifier}}" {{ROUTER_FILE}} && echo ok

# Tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-endpoint-test}}

# Start the server and hit the endpoint — the endpoint returns 200 (or 401 if unauthenticated)
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Business logic in the handler | Move it to a service. Handlers map HTTP ↔ domain; they don't contain domain logic. |
| Endpoint file exists but router wasn't updated | Step 5. The endpoint won't respond; it's dead code until registered. |
| No auth check | Default to authenticated. If the endpoint is truly public, say so explicitly (comment + PR discussion). |
| Tests only assert 200 status | Assert the response body shape. A 200 with wrong JSON is a bug the test should catch. |
