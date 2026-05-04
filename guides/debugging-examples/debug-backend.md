---
name: debug-backend
description: >
  Diagnose a backend issue — bad response, slow endpoint, server error — by collecting logs,
  traces, and a minimal repro, then proposing a fix. Use when user says 'debug backend',
  '500 error', 'API returning wrong data', 'endpoint is slow', or 'service is broken'.
  Do NOT use for frontend rendering issues (use debug-frontend), database-specific issues
  (use debug-database), or infra issues (use debug-infrastructure).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug a backend issue

## Before You Start

- Root `CLAUDE.md` → **Things to Know** — known backend gotchas.
- Any scope-level `CLAUDE.md` under `src/api/` or your backend dir.
- The project's logging convention — structured JSON? Log level per env? Correlation IDs?
- Your tracing tool — Jaeger, Tempo, Langfuse, Honeycomb — if any. Skip step 2b if none.

## Step 1: collect symptoms

- What's the exact failure? Status code, error body, latency number.
- When — since a specific deploy, after a specific action, always?
- Scope — all users or a specific tenant? All endpoints or one?
- Request/correlation ID if the client surfaces it.

## Step 2: gather evidence

**Logs** — fetch around the reported time, filtered by the relevant request ID:

```bash
# Kubernetes
kubectl logs -n <namespace> -l app=<service> --since=1h | grep <correlation-id>

# Docker Compose
docker compose logs <service> --since 1h | grep <correlation-id>

# Plain systemd / file logs
journalctl -u <service> --since "1 hour ago" | grep <correlation-id>
grep <correlation-id> /var/log/<service>/*.log
```

Read backward from the error — the cause is usually a few lines before the error line.

**Traces** — if the project has tracing (Langfuse, Jaeger, Tempo, Honeycomb, OpenTelemetry-backed), open the trace for the failing request. Spot:

- Which span failed.
- Which span took unexpectedly long.
- Which downstream service returned the error.

### Step 2b — performance issues

Open `{{METRICS_DASHBOARD}}`:

- Latency distribution (p50 vs p99). A p99 spike without p50 change = a slow outlier path.
- Error rate. Is it spiking with latency (cascade) or flat (backpressure)?
- Resource saturation — CPU, memory, DB connection pool, thread pool. Often the real bottleneck.

## Step 3: narrow

| Signal | Classification |
|---|---|
| Error rate 100% on this endpoint | Latest deploy or config change. `git log --since='2 days ago'`. |
| Error rate high for one tenant | Data-shape edge case. Inspect that tenant's data. |
| Error rate high in one environment | Env-var drift or missing config. Compare `.env*` or Kubernetes ConfigMaps. |
| Error rate bursts sporadically | Timing, concurrency, or downstream dependency. Check downstream status + recent deploys. |

## Step 4: reproduce minimally

```bash
# Hit the endpoint with the offending payload in isolation:
curl -X <METHOD> http://localhost:<port>/<path> \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d @/tmp/repro-payload.json

# Or a project-specific repro script if one exists:
# bash scripts/repro.sh <test-case>
```

If you can reproduce: you have a handle. If you cannot, the bug is environment- or data-specific — widen your sample or try to reproduce against a snapshot of the failing tenant's data.

## Step 5: form a hypothesis and test it

From the trace + logs, identify which function raised. Read the function and its callers:

```bash
grep -rn "<specific-error-string-or-log-message>" src/
```

Form a hypothesis. Test it by adjusting the repro input — can you make the bug go away by avoiding the hypothesized condition? Can you make it worse?

## Step 6: propose or apply the fix

If you were given scope to edit: apply the fix, commit with a concise message referencing the observed behavior.

Otherwise: write the report, including the minimal repro, the hypothesis, and the proposed change.

## Step 7: prevent regression

Add one of:

- **A test** — integration test that fires the same request and asserts the correct response.
- **An alert** — a log pattern or metric threshold that would catch the same class of bug in prod.
- **A `Things to Know` entry** in `CLAUDE.md` if the fix depends on non-obvious knowledge.

## Verify

```bash
# Repro no longer fails
curl -X <METHOD> ... # expect 2xx

# New test passes
<test command> <new-test-file>

# No new errors in logs within the next hour
kubectl logs -l app=<service> --since=1h | grep -iE 'error|exception' | grep -v '<known-noise>'
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Searching logs without a correlation ID | Find one first. Correlation IDs are usually in the first lines of a request's log block — grep for the request path. |
| Reading the error line instead of the surrounding lines | The cause is rarely on the error line. Read the 5–10 lines before it. |
| Fixing the symptom — `try/except` around the failing call | Understand WHY the call fails. Catching errors hides bugs. |
| Declaring "fixed" without a regression test | The bug will return. Step 7 is non-negotiable. |
