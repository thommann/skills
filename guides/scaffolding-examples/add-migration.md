---
name: add-migration
description: >
  Create a schema migration — new table, new column, index, or constraint — with both apply
  and rollback paths, matching the project's migration tool. Use when user says 'add a migration',
  'schema change', 'add column', 'create table', or 'alter index'. Do NOT use for data-only
  changes (use a separate data-migration mechanism), for seeding reference data (use seeders),
  or for local dev-only schema changes (migrations are shared with the team).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a schema migration

<!--
  ADAPT TO YOUR PROJECT:
    {{MIGRATIONS_DIR}}      — `migrations/`, `src/db/migrations/`, `alembic/versions/`, `prisma/migrations/`
    {{MIGRATION_TOOL}}      — `alembic`, `prisma migrate`, `drizzle-kit`, `flyway`, `sqlx`, `knex`, `sequelize-cli`
    {{MIGRATION_COMMAND}}   — `alembic revision --autogenerate`, `pnpm prisma migrate dev`, ...
    {{MIGRATION_APPLY}}     — `alembic upgrade head`, `prisma migrate deploy`, ...
    {{MIGRATION_ROLLBACK}}  — `alembic downgrade -1`, `prisma migrate reset` (irreversible!), ...
    {{TEST_COMMAND}}        — `pnpm test`, `pytest`
-->

## Before You Start

- `{{MIGRATIONS_DIR}}/` — browse the latest 2–3 migrations. Match their comment style, naming, and level of detail.
- Any migration-review guidelines in `docs/` or `CONTRIBUTING.md`.
- The project's deployment flow — are migrations auto-applied on deploy, or manual? This affects how safe a migration must be.
- **Production data shape** — if the table has > 1M rows, schema changes need special care (online migrations, backfill in batches). Flag with the user before writing.

## Step 1: decide the change

Common migrations:

| Change | Care required |
|---|---|
| Add nullable column | Safe. Default null, backfill later (or not). |
| Add non-nullable column with default | Safe for small tables; can lock large tables while rewriting. |
| Drop column | Breaking — any running code referencing the column fails. Do in two deploys: stop reading, THEN drop. |
| Rename column | Even more breaking — same two-deploy pattern with an aliased view. |
| Add index | Usually safe. On large tables, use `CREATE INDEX CONCURRENTLY` (Postgres) or equivalent. |
| Add NOT NULL constraint | Breaks if nulls exist. Backfill first, then constrain. |
| Add foreign key | Validates existing rows — slow on large tables. |
| Drop table | Verify no code references it. Grep first. |

If the change is "breaking" above, do it in staged deploys — not a single migration.

## Step 2: generate the migration

```bash
{{MIGRATION_COMMAND}} "describe_the_change"
```

Auto-generation diff:

- Compares the ORM model to the current schema.
- Produces a migration that moves DB → model shape.

If the project uses hand-written migrations (raw SQL, Flyway), copy the latest migration as a template.

## Step 3: review the migration

Open the generated file and read every line:

- **Every intended change present?** Auto-gen sometimes misses renames (it sees as drop+add).
- **No unintended changes?** Auto-gen occasionally picks up noise (capitalization, default-to-default differences).
- **Ordering safe?** If the migration both drops a foreign key and adds a new one, the order matters.
- **Rollback path sane?** Most tools generate a `downgrade` or `down` section. Check it — automated rollbacks of destructive changes often don't restore data.

Edit the generated SQL/DSL if needed — that's normal and expected.

## Step 4: test the migration

```bash
# Apply to an empty DB
{{MIGRATION_APPLY}}

# Roll back
{{MIGRATION_ROLLBACK}}

# Re-apply
{{MIGRATION_APPLY}}
```

Round-trip confirms the rollback is wired. If the rollback drops data, state that in the migration comment — future-you deserves the warning.

If the project has integration tests, run them against the migrated schema:

```bash
{{TEST_COMMAND}}
```

## Step 5: add a data-backfill step if needed

If the new column needs a value for existing rows:

- **Small table:** inline the UPDATE in the migration.
- **Large table:** split — migration adds the column nullable; a separate backfill job populates it in batches; a follow-up migration adds NOT NULL.

Never do a non-batched `UPDATE` on a multi-million-row table in a migration. It locks the table and blocks writes for the duration.

## Step 6: document

If the migration is non-trivial (renames, destructive changes, multi-deploy coordination), add a comment at the top of the migration file explaining the WHY and the rollout plan. Future on-call engineers running `{{MIGRATION_ROLLBACK}}` at 3 a.m. will thank you.

## Verify

```bash
# Migration file exists and is auto-discovered by the tool
ls {{MIGRATIONS_DIR}}/*{{migration_slug}}* 2>/dev/null

# Applying from scratch works
{{MIGRATION_APPLY}}

# Rollback works (where non-destructive)
{{MIGRATION_ROLLBACK}} && {{MIGRATION_APPLY}}

# Integration tests pass against the migrated schema
{{TEST_COMMAND}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Hand-editing the model and not running migration generation | The DB and model drift. Always generate, always apply, always test round-trip. |
| Combining schema + data changes in one migration | Split. Schema migration first (reversible); data migration second (typically not easily reversible). |
| Dropping a column that the current code still reads | Stage: remove all reads in one deploy; THEN drop the column in a second. |
| No rollback for a destructive migration | Document it: "-- destructive: rollback requires restore from backup" so future you doesn't trust an automated down step. |
