---
name: debug-database
description: >
  Diagnose a database issue — slow query, migration failure, connection exhaustion, lock contention,
  unexpected data. Use when user says 'slow query', 'migration failed', 'connection pool
  exhausted', 'database is locked', or 'why is this query taking so long'. Do NOT use for ORM
  usage bugs (those are backend code; use debug-backend) or for schema changes (use add-migration).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug a database issue

## Before You Start

- Root `CLAUDE.md` — the project's DB engine (Postgres, MySQL, SQLite, Mongo) and connection configuration.
- Scope-level `CLAUDE.md` where DB-adjacent code lives (`src/db/`, `packages/*/persistence/`).
- Your DB client — `psql`, `mysql`, `sqlite3`, `mongo`, or a tool like DBeaver. You'll need query access.
- The project's migration history — `migrations/` — for schema changes recent enough to be suspicious.

## Step 1: collect symptoms

- What exactly is wrong? Slow query (p50 / p99 numbers), query returning wrong data, migration error message, connection error, deadlock.
- Environment — prod, staging, dev. Local slow can mean local-only (stale analyze, small shared_buffers); prod slow is the real bug.
- When — after a deploy, after traffic changed, always?
- Error message (verbatim), if any.

## Step 2: gather evidence by problem class

### Slow query

```sql
-- Postgres: currently running slow queries
SELECT pid, now() - query_start AS duration, state, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - query_start > interval '1 second'
ORDER BY duration DESC;

-- Past slow queries (if pg_stat_statements enabled)
SELECT query, mean_exec_time, calls, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- EXPLAIN ANALYZE on a suspected query
EXPLAIN (ANALYZE, BUFFERS) <query>;
```

Key things to spot in the plan:

- **Sequential scan on a large table** — usually wants an index.
- **Nested loop with high row count** — often better as a hash join, which means the planner's row estimate is off.
- **Index scan returning many rows** — the index is too broad for the predicate.
- **Sort + Limit** — if the sort is the bottleneck and there's an ORDER BY with a LIMIT, a matching index lets the planner skip the sort.

### Migration failure

```bash
# What was the last applied migration?
# Postgres + common tools
psql -c "SELECT * FROM alembic_version"              # Alembic
psql -c "SELECT migration_name FROM _prisma_migrations ORDER BY finished_at DESC LIMIT 5"   # Prisma
psql -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5"    # Rails / common SQLx layouts

# The error message itself usually points at the failing SQL.
# Read the generated migration file and find the offending statement.
```

Common migration failures:

- **Adding NOT NULL without a default to a table with existing rows** — fill in data first, then constrain.
- **Unique constraint that existing data violates** — deduplicate first.
- **Concurrent DDL locked out by a long-running transaction** — find and end the blocker.

### Connection pool exhaustion

```sql
-- Postgres: what's connected?
SELECT datname, usename, application_name, state, COUNT(*)
FROM pg_stat_activity
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- Idle transactions (often the culprit)
SELECT pid, now() - xact_start AS duration, state, query
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'idle in transaction (aborted)')
ORDER BY duration DESC;
```

Look for `idle in transaction` — these hold connections open and starve the pool. Usually an application-side bug: a transaction started but not committed/rolled back.

### Locks / deadlocks

```sql
-- Postgres: what's locking what?
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_query,
       blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.pid != blocked_locks.pid
    AND blocking_locks.locktype = blocked_locks.locktype
    AND NOT blocked_locks.granted
    AND blocking_locks.granted
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid;
```

For deadlocks: the engine's log records the cycle. Read it — it names the exact queries and rows involved.

## Step 3: narrow

| Signal | Classification |
|---|---|
| Slow only for one tenant / large row set | Missing index or a plan that doesn't scale with row count. |
| Slow only after a deploy | New query pattern, or a changed query that used to hit a different plan. |
| Slow during deploys, fast otherwise | Migration running inline — move to an online-migration process. |
| Intermittent timeouts | Connection pool pressure or downstream resource contention. |
| Same table, different queries all slow | Bloat, or stats out of date (`VACUUM ANALYZE`). |

## Step 4: reproduce minimally

Reproduce against staging or a local copy with representative data volume. A slow query on 1000 rows is often fast; you need 1M+ to see the real plan.

```bash
# Snapshot production data shape (sanitized) into local DB
pg_dump --schema-only production > /tmp/schema.sql
pg_dump --data-only --table=<key_table> production | sanitize_script.sh > /tmp/data.sql
psql local < /tmp/schema.sql
psql local < /tmp/data.sql
```

## Step 5: propose or apply the fix

Common fixes:

- **Add an index** — `CREATE INDEX CONCURRENTLY` (Postgres) on large tables to avoid locking.
- **Rewrite the query** — push filters into the subquery, replace a subquery with a join, add `LIMIT`.
- **Fix the caller** — a bad usage pattern (N+1, fetching a million rows to count them) is a code bug, not a DB bug.
- **Vacuum/Analyze** — if stats are stale, the planner makes bad choices.
- **Add an index hint** — last resort; the planner usually knows best.

For migration failures: fix the underlying data issue, then re-run.

## Step 6: prevent regression

- **A regression test or benchmark** — if the query is hot, benchmark it and assert a ceiling (tested on representative data).
- **An alert** — slow-query log threshold or p99 latency alert on the endpoint that uses the query.
- **A `Things to Know` entry** for the non-obvious index or query pattern.

## Verify

```sql
-- The slow query now uses the intended plan
EXPLAIN (ANALYZE, BUFFERS) <query>;

-- The endpoint's p99 latency is within budget (check your dashboard)
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Reading EXPLAIN without ANALYZE | `EXPLAIN` shows the plan; `EXPLAIN ANALYZE` runs the query and shows actual row counts and timing. The gap between estimated and actual is where the bug is. |
| Adding an index without checking if one already covers the predicate | List existing indexes on the table first. Redundant indexes waste write performance. |
| Blaming the DB for an application bug | An N+1 query is the application doing the wrong thing. Fix it in code; don't index around it. |
| Running `VACUUM FULL` in production without understanding the lock | `VACUUM FULL` takes an exclusive lock. Use `VACUUM` for routine; `VACUUM FULL` only during maintenance windows. |
