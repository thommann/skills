---
name: state-management
description: >
  Reference for how this project manages state — client-side store, server-side state layering,
  cache / query-client configuration. Use when user says 'how do we manage state', 'where does
  the store live', 'state pattern', 'caching pattern', or 'how is {resource} state kept in sync'.
  Do NOT use for persistent-storage decisions (use auth-reference or data-model docs), for
  debugging state-sync bugs (use debug-backend / debug-frontend), or for framework state
  primitives (those are in the framework's docs).
allowed-tools: Read, Grep, Glob
---

# State management — reference

<!--
  ADAPT TO YOUR PROJECT:
    Pick the right side of this skill based on what your project needs. The skill has two halves:
      - Client-side state (for projects with a UI)
      - Server-side state (for projects with a backend)
    Replace placeholders in the applicable half; delete the other.

    Client-side placeholders:
      {{STORE_LIB}}        — Redux, Zustand, Pinia, Vuex, MobX, Jotai, Recoil, signals, ...
      {{QUERY_LIB}}        — TanStack Query, Pinia Colada, SWR, Apollo, URQL, ...
      {{STORE_DIR}}        — `src/store/`, `src/stores/`, `src/state/`
      {{QUERY_CONFIG}}     — query-client bootstrap: `src/queries/client.ts`

    Server-side placeholders:
      {{REQUEST_CONTEXT}}  — request-scoped state: `src/context.ts`, AsyncLocalStorage usage
      {{CACHE_LIB}}        — Redis client, in-memory cache module
      {{CACHE_WRAPPER}}    — the project's cache helper: `src/lib/cache.ts`
-->

## What this reference covers

The project's state-management layers: what's client-side, what's server-side, what's cached, what's request-scoped.

**NOT covered:**

- Persistent storage (databases, object storage) — see data-model reference.
- Debugging a stale-state bug — see `debug-frontend` or `debug-backend`.
- Framework state primitives (React `useState`, Vue `ref`) — framework docs.

## Minimum-viable example

### Client-side

A canonical store usage: `{{CLIENT_EXEMPLAR}}`. It demonstrates:

- Declaring the store with {{STORE_LIB}}.
- Selecting state to the component.
- Dispatching actions / mutations.
- Integrating with {{QUERY_LIB}} for server-sync'd data.

### Server-side

A canonical request-scoped read/write: `{{SERVER_EXEMPLAR}}`. It demonstrates:

- Storing per-request state in `{{REQUEST_CONTEXT}}`.
- Reading from `{{CACHE_WRAPPER}}` with a TTL.

## The contract (client-side)

- **Library:** {{STORE_LIB}} for UI state (what the user's currently doing) + {{QUERY_LIB}} for server-derived data (what the server knows).
- **Rule of thumb — where does this belong?**

  | Kind of state | Goes in |
  |---|---|
  | Fetched from the server, might go stale | {{QUERY_LIB}} |
  | UI-only (modal open, selected tab, form draft) | {{STORE_LIB}} |
  | Per-component transient | local component state — not in any store |
  | Shared across routes but session-scoped | {{STORE_LIB}} |

  Putting server-derived data in {{STORE_LIB}} leads to cache drift. Putting UI-only state in {{QUERY_LIB}} abuses the cache lifecycle.

- **Query client config:** `{{QUERY_CONFIG}}` — sets default staleTime, retry, refetchOnWindowFocus. Override per-query only when the default is wrong.

## The contract (server-side)

- **Request-scoped context:** `{{REQUEST_CONTEXT}}` — populated by middleware at request start (user identity, correlation ID, feature-flag snapshot). Read from anywhere via the helper; never mutate.
- **Process-scoped state:** long-lived singletons (DB pool, HTTP client). Bootstrapped once at startup. Never store request-scoped data here.
- **Cache:** `{{CACHE_WRAPPER}}` — the project's wrapper around {{CACHE_LIB}}. Every read/write goes through it for metrics and uniform key namespacing.

## Extension points

### Adding a new client-side store slice

1. Follow the scaffolding pattern — see `scaffolding/add-service` analog for the frontend.
2. Register in `{{STORE_DIR}}/index.*`.
3. Don't reinvent — if it's a server-derived list, use {{QUERY_LIB}}, not a hand-rolled store.

### Adding a cached server-side computation

1. Call `{{CACHE_WRAPPER}}.get(key, factory, ttl)` — factory runs only on cache miss.
2. Key: namespaced by resource type. Convention: `{{CACHE_KEY_CONVENTION}}`.
3. TTL: err on the side of short. Coordinated invalidation is complex; frequent recompute is simple.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| Copying server data into {{STORE_LIB}} and updating it manually | Use {{QUERY_LIB}}; mutations return fresh data that updates the cache. Manual duplication causes drift. |
| Using `window.*` or a module-level `let` as global state | Module-level state breaks under SSR and tests. Use the store. |
| Setting an infinite TTL on a cached value | Caches need an invalidation story. Infinite TTL + a bug = stale forever. |
| Treating the request context as an append-only grab bag | Keep it small. Everything added has a cost per request. |

## Source of truth

- **Store bootstrap:** `{{STORE_DIR}}/index.*`
- **Query client config:** `{{QUERY_CONFIG}}`
- **Request-context helper:** `{{REQUEST_CONTEXT}}`
- **Cache wrapper:** `{{CACHE_WRAPPER}}`

## Verify

```bash
for p in {{STORE_DIR}} {{QUERY_CONFIG}} {{REQUEST_CONTEXT}} {{CACHE_WRAPPER}}; do
  [ -e "$p" ] || echo "STALE: $p"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Documenting a state pattern the codebase doesn't actually use | Read the exemplar. This skill describes current reality, not an ideal. |
| Recommending a new state lib because the current one has rough edges | Library swaps are architectural changes — write an ADR (`document-decision`), get buy-in, THEN update this skill. |
| Ignoring the difference between "server-derived" and "UI-only" state | The rule-of-thumb table is load-bearing. Collapsing the two leads to cache drift or lifecycle abuse. |
| Not documenting cache-invalidation strategy | Every cache needs one. "TTL" is an answer; "eventually" is not. |
