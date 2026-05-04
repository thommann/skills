---
name: configuration
description: >
  Reference for how this project reads, layers, and validates configuration — files, env vars,
  secrets, runtime overrides. Use when user says 'how does config work', 'where does this
  setting come from', 'add a new config option', 'config precedence', or 'where are secrets
  stored'. Do NOT use for debugging a misconfigured deployment (use debug-infrastructure) or
  for CI-specific config (those live in `.github/workflows/` directly).
allowed-tools: Read, Grep, Glob
---

# Configuration — reference

<!--
  ADAPT TO YOUR PROJECT:
    {{CONFIG_LOADER}}     — `src/config.ts`, `src/core/settings.py`, `packages/*/config/`
    {{CONFIG_SCHEMA}}     — the typed schema: `src/config/schema.ts`, a Pydantic `Settings` class
    {{ENV_EXAMPLE}}       — `.env.example`, `.env.template`, `.env.dev`
    {{SECRETS_MECHANISM}} — where secrets come from: Vault, AWS Secrets Manager, k8s Secrets, `.env.local`
    {{ENVS}}              — environments: dev, staging, prod
-->

## What this reference covers

How the project loads config from files, env vars, and runtime overrides; how secrets are supplied; how values are validated and made available to code.

**NOT covered:**

- Debugging why a specific environment is misconfigured — use `debug-infrastructure`.
- CI pipeline config — `.github/workflows/` directly.
- Feature flags — a separate concern; see `reference/feature-flags` if that skill exists.

## Minimum-viable example

- **Schema:** `{{CONFIG_SCHEMA}}` — every valid config key, its type, default, and whether it's required.
- **Loader:** `{{CONFIG_LOADER}}` — where the schema is populated at startup.
- **Sample file:** `{{ENV_EXAMPLE}}` — a template the developer copies to `.env` (or equivalent).

Read these three before adding or changing config.

## The contract

### Layering (precedence, highest wins)

1. **Runtime overrides** — CLI flags, programmatic `setConfig()` calls (usually only in tests).
2. **Environment variables** — `PROJECT_DATABASE_URL=...`. Highest priority among deployed-env sources.
3. **Environment-specific file** — `.env.prod`, `.env.dev` — picked by `NODE_ENV` / `APP_ENV`.
4. **Default file** — `.env`, `config/default.yml`. Committed, non-secret defaults only.
5. **Schema defaults** — values declared in `{{CONFIG_SCHEMA}}` as fallbacks.

The layering is built into `{{CONFIG_LOADER}}`. Never bypass it by reading `process.env.X` / `os.environ["X"]` directly — that skips validation and defaults.

### Secret handling

- Secrets live in `{{SECRETS_MECHANISM}}`, NOT committed files.
- `.env` is **gitignored**; `.env.example` is committed as a template with placeholder values.
- `.env.prod` / `.env.dev` that are committed hold NON-secret defaults only (URLs, feature flags). Real secrets are injected at runtime.
- A hook (see `hooks/examples/protect-sensitive-files.sh`) blocks edits/reads on `.env` to prevent accidental commits.

### Validation

- All config loaded through `{{CONFIG_LOADER}}` passes through `{{CONFIG_SCHEMA}}` validation.
- Unknown keys: rejected (typo protection) OR ignored (flexibility) — check which the project does.
- Type coercion: strings from env vars must coerce to the schema's type. A required integer with value `"abc"` is an error at startup, not a runtime surprise.

## Adding a new config option

1. Add the key to `{{CONFIG_SCHEMA}}` with type, default, and documentation.
2. Add the key to `{{ENV_EXAMPLE}}` with a placeholder value.
3. If it's secret, also update the secrets-provisioning flow (external to this repo).
4. Use it in code via `config.newOption`, not via direct env access.

## Environment-specific values

| Environment | Where its values come from |
|---|---|
| Local dev | `.env.dev` + local `.env` (developer's personal overrides) |
| CI | Env vars set in `.github/workflows/*.yml` or secrets in the CI system |
| Staging | {{SECRETS_MECHANISM}} → env vars in the deployment |
| Production | {{SECRETS_MECHANISM}} → env vars in the deployment |

**Never hardcode a production value in a file.** Prod-specific values come from the deployment pipeline, not the repo.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| Reading `process.env.X` (or equivalent) directly in application code | Go through `{{CONFIG_LOADER}}`. Direct access skips validation and creates drift — some callers will use a default, others won't. |
| Adding a required config without updating `{{ENV_EXAMPLE}}` | New developers' environments break silently. Every required key has a template entry. |
| Committing a `.env` file with real values | Revoke any secrets that touched git; add a pre-commit hook that blocks `.env`. |
| Config option used in code but never declared in `{{CONFIG_SCHEMA}}` | Undeclared config drifts. Every consumed key is declared with a type. |

## Source of truth

- **Schema:** `{{CONFIG_SCHEMA}}`
- **Loader:** `{{CONFIG_LOADER}}`
- **Template:** `{{ENV_EXAMPLE}}`
- **Secrets provider docs:** project-specific — usually in `docs/operations/secrets.md` or the runbook.
- **Layering ADR:** `grep -l config docs/adr/ docs/decisions/` for the decision record if one exists.

## Verify

```bash
for p in {{CONFIG_LOADER}} {{CONFIG_SCHEMA}} {{ENV_EXAMPLE}}; do
  [ -e "$p" ] || echo "STALE: $p"
done

# Every required key in the schema is present in the example file
# (implementation varies; adapt)
# grep '"required"' {{CONFIG_SCHEMA}} | extract keys | diff against {{ENV_EXAMPLE}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Documenting "config goes in `.env`" when the project uses layering | State the full precedence order. Dev/prod confusion comes from assuming "just put it in `.env`." |
| Listing env var names without naming the loader | Future readers grep for the name and find callers. Point at `{{CONFIG_LOADER}}` so they know where the layering happens. |
| Skipping the secrets mechanism | Every project has one, even if it's "we use `.env.local`." Document honestly; security decisions can't be tacit. |
| Claiming validation happens when it doesn't | Run through `{{CONFIG_SCHEMA}}` to confirm. Undocumented validation gaps bite at 3 a.m. |
