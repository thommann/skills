---
name: auth-reference
description: >
  Reference for authentication and authorization in this project — how identity is established,
  how permissions are checked, where the contract lives. Use when user says 'how does auth
  work', 'auth pattern', 'permission check', 'where do I add an auth guard', or 'who has
  access to X'. Do NOT use for user-management (account creation, password reset — those are
  feature docs) or for debugging auth issues (use debug-backend).
allowed-tools: Read, Grep, Glob
---

# Auth — reference

<!--
  ADAPT TO YOUR PROJECT:
    {{AUTH_MODULE}}       — `src/auth/`, `packages/*/auth/`
    {{AUTH_MIDDLEWARE}}   — the middleware/guard file: `src/middleware/auth.ts`
    {{USER_IDENTITY}}     — the type representing an authenticated user: `src/auth/identity.ts`
    {{PERMISSION_CHECKER}} — how permissions are evaluated: `src/auth/access-checker.ts`
    {{EXEMPLAR_PROTECTED}} — a recently-added protected endpoint
-->

## What this reference covers

How authentication (who is this?) and authorization (what can they do?) work in this project.

**NOT covered:**

- Login / signup / password reset flows — those are feature docs.
- Auth provider configuration (OAuth, SAML, SSO) — provider-specific; see `{{AUTH_MODULE}}/providers/`.
- Debugging an auth failure — see `debug-backend`.

## Minimum-viable example

A protected endpoint in `{{EXEMPLAR_PROTECTED}}`. Note how it:

1. Receives the authenticated identity — usually via a decorator, dependency injection, or middleware-populated request property.
2. Checks a specific permission before executing the business logic.
3. Lets the framework's error-mapping middleware convert an auth/permission error to the right HTTP status (401 vs 403).

## The contract

- **Identity type:** `{{USER_IDENTITY}}` — the shape of "who's calling." Fields typically include id, email, roles/groups, tenant, session/token metadata.
- **Where identity is established:** `{{AUTH_MIDDLEWARE}}` — runs before every handler, decodes the token/cookie/session, populates the request context. Without it, there's no identity.
- **Permission model:** {{PERMISSION_MODEL}} — usually one of:
  - **RBAC** — roles with coarse permissions: `admin`, `user`, `viewer`.
  - **ABAC** — attribute-based: `identity.tenant_id == resource.tenant_id && identity.has_role('editor')`.
  - **Policy engine** — OPA, Cerbos, Casbin — policies live in a separate file.
  - **Owner check + roles** — "you own this OR you're an admin."
- **Permission check:** `{{PERMISSION_CHECKER}}` — the single function/method that answers "can this identity do this action on this resource?" Call this everywhere; do not re-implement.

## How a new endpoint gets protected

1. Use the project's standard handler shape (see the scaffolding skill `add-api-endpoint`).
2. Apply the auth decorator/guard/middleware — the exemplar shows the exact syntax.
3. Call `{{PERMISSION_CHECKER}}` with the identity, the resource, and the action. Raise the project's `ForbiddenError` on denial.
4. Write tests covering: unauthenticated → 401, authenticated but unauthorized → 403, authorized → happy path.

## Known edge cases

- **Service-to-service calls** — often use a machine identity (client credentials, service account), not a user. Check `{{AUTH_MODULE}}/service-auth.*`.
- **Multi-tenant isolation** — every query must filter by `tenant_id`. A raw query without the filter is a data leak. If the project uses Postgres RLS, that's enforced at the DB layer — but apps must still set the session variable.
- **Background jobs** — run without a request context, so the middleware hasn't populated identity. They either impersonate a service identity or pass identity as a job argument.
- **WebSocket / long-lived connections** — auth happens on the first message, not the HTTP upgrade. Check `{{AUTH_MODULE}}/websocket.*` for the first-message handshake.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| Handler reads `request.user` but the middleware didn't run for this route | Every protected route group must have the middleware applied. Check the route group config, not just the handler. |
| Checking `if (user.role === 'admin')` inline | Use `{{PERMISSION_CHECKER}}`. Inline checks fragment the policy model — the next change to admin privileges won't reach these sites. |
| Fetching a resource and not verifying the caller has access | Fetch AND check. Missing this is the #1 cause of IDOR vulnerabilities. |
| Trusting a claim in the token without verifying | Tokens can be forged. The project's token verifier (`{{AUTH_MODULE}}/token.*`) signs/validates; don't parse tokens manually. |

## Source of truth

- **Identity type:** `{{USER_IDENTITY}}`
- **Middleware:** `{{AUTH_MIDDLEWARE}}`
- **Permission check:** `{{PERMISSION_CHECKER}}`
- **Exemplar protected endpoint:** `{{EXEMPLAR_PROTECTED}}`
- **ADRs on auth decisions:** grep `docs/adr/` for `auth` / `permission` / `rbac`.

## Verify

```bash
for p in {{USER_IDENTITY}} {{AUTH_MIDDLEWARE}} {{PERMISSION_CHECKER}} {{EXEMPLAR_PROTECTED}}; do
  [ -e "$p" ] || echo "STALE: $p"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Rolling your own auth for a new subsystem | Use the project's — consistency over local cleverness. Every auth fragmentation is future pain. |
| Documenting internal auth details without linking ADRs | If a subtle behavior exists because of a specific decision, link the ADR. Undocumented decisions are re-litigated. |
| Skill missing the "multi-tenant isolation" note | If the project is multi-tenant, that note is load-bearing. Undocumented tenant-scoping leads to data leaks. |
| Claiming "all endpoints are protected by default" without evidence | Assert it against the actual middleware wiring. Implicit rules fail silently when someone bypasses them. |
