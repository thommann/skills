---
name: add-data-model
description: >
  Scaffold a new persisted data model — entity + schema + migration + repository + tests —
  matching the project's ORM and persistence conventions. Use when user says 'add a model',
  'new entity', 'create a table for X', or 'scaffold a domain object'. Do NOT use for in-memory
  types (just define a type), for changing an existing model's fields (add a migration and edit
  the model), or for API request/response DTOs (those belong in the API schema, not the model).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a new data model

<!--
  ADAPT TO YOUR PROJECT:
    {{MODELS_DIR}}        — `src/models/`, `packages/core/entities/`, `src/domain/`
    {{MIGRATIONS_DIR}}    — `migrations/`, `src/db/migrations/`, `alembic/versions/`
    {{REPOSITORIES_DIR}}  — `src/repositories/`, `src/core/persistence/`
    {{MIGRATION_COMMAND}} — `pnpm db:migrate:generate`, `alembic revision --autogenerate`, `cargo sqlx migrate add`
    {{TEST_DIR}}          — `tests/integration/`, `tests/models/`
    {{TEST_COMMAND}}      — `pnpm test`, `pytest`, `cargo test`
    {{EXEMPLAR_MODEL}}    — a recently-added model file
-->

## Before You Start

- **Exemplar:** `{{EXEMPLAR_MODEL}}` — canonical recently-added model. Copy structure, base class, decorators.
- **ORM conventions:** see how `{{EXEMPLAR_MODEL}}` declares fields, indexes, relationships.
- **Naming:** table name (singular or plural?), column case (snake_case, camelCase?), primary-key strategy (autoinc int, UUID, composite).
- **Migration pattern:** one migration per logical change, or one per PR? Check `{{MIGRATIONS_DIR}}` history.

## Step 1: name the model

Confirm the name + table name with the user. Check for collisions:

```bash
grep -rn "class {{ModelName}}\b" {{MODELS_DIR}}
grep -rn "table.*{{table_name}}" {{MODELS_DIR}} {{MIGRATIONS_DIR}}
```

## Step 2: define the model class

Copy the exemplar and adapt:

```bash
cp {{EXEMPLAR_MODEL}} {{MODELS_DIR}}/{{new-model-file}}
```

Update: class name, table name, primary key (match the project's convention — usually UUID or autoinc), fields with types and nullability, indexes, relationships.

Follow the project's field-order convention (usually: primary key first, then core fields, then timestamps, then relationships).

## Step 3: register the model

Export the model from the barrel file if the project uses one:

```bash
# Common: src/models/index.ts, packages/*/entities/__init__.py
grep -n "{{ExemplarName}}" {{MODELS_DIR}}/index.*
```

If the ORM needs explicit registration (SQLAlchemy `Base.metadata`, Prisma schema, TypeORM entity array), add the new model there.

## Step 4: generate the migration

```bash
{{MIGRATION_COMMAND}} "create {{model_name}} table"
```

Review the generated SQL/DSL:

- Every field's type matches the model definition.
- Indexes are present (especially on foreign keys and frequently-filtered columns).
- Constraints (NOT NULL, UNIQUE, CHECK) match the model's annotations.
- Default values match where the model declares them.

Do NOT hand-write migrations when the project uses auto-generation. Auto-generated migrations are easier to review and reconcile.

## Step 5: add a repository (if the project uses the repository pattern)

If `{{REPOSITORIES_DIR}}` exists, copy the exemplar repository:

```bash
cp {{REPOSITORIES_DIR}}/{{exemplar-repo-file}} {{REPOSITORIES_DIR}}/{{new-repo-file}}
```

Adapt: type references, query methods (`findById`, `findByEmail`, ...), any project-specific cross-cutting (multi-tenancy filters, soft-delete).

## Step 6: add tests

Create `{{TEST_DIR}}/{{new-model-test}}` with at minimum:

- **Create + read round-trip** — a record written via the repository reads back with identical fields.
- **Constraint violation** — an insert violating NOT NULL or UNIQUE raises the expected error.
- **Index usage** — if a query method is added, test that it returns the right subset.

Integration tests hit a real DB (via testcontainers, a dockerized DB, or a test database). Unit tests that mock the ORM are rarely worth it.

## Step 7: verify

```bash
# Model file exists
test -f {{MODELS_DIR}}/{{new-model-file}} && echo ok

# Migration exists
ls {{MIGRATIONS_DIR}}/*{{model_name}}* 2>/dev/null

# Migrations run cleanly from empty DB
# (project-specific command — `pnpm db:reset`, `alembic upgrade head`, `sqlx migrate run`)

# Tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-model-test}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Forgetting an index on a foreign key | Add it. Query plans degrade badly without it once the table grows. |
| Auto-generated migration doesn't match intent | Review it line by line. Re-run generation if you edited the model after generating. |
| Testing the model with mocks instead of a real DB | Integration tests against the DB catch schema drift. Mocked tests prove only that the mock is consistent. |
| Adding a nullable column to populate "later" | Add it with a default OR make it a required-with-migration-backfill. Silent nullables accumulate and hide data bugs. |
