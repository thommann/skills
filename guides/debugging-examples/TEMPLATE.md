---
name: debug-{{SUBSYSTEM}}
description: >
  Diagnose a {{SUBSYSTEM}} problem by collecting evidence, narrowing the blast radius,
  reproducing minimally, and proposing a fix. Use when user says 'debug {{SUBSYSTEM}}',
  'the {{SUBSYSTEM}} is broken', '{{SUBSYSTEM}} errors', 'why is {{SUBSYSTEM}} failing',
  or '{{SUBSYSTEM}} is slow'. Do NOT use for writing new {{SUBSYSTEM}} code (use a scaffolding
  skill) or for code review (use review-diff).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug — {{SUBSYSTEM}}

<!--
  ADAPT TO YOUR PROJECT:
    {{SUBSYSTEM}}         — the subsystem name (backend, frontend, database, infra, tests)
    {{LOG_LOCATION}}      — where its logs live (kubectl logs, docker logs, /var/log/..., Sentry)
    {{TRACE_TOOL}}        — your tracing tool (Jaeger, Tempo, Langfuse, Honeycomb) — or remove step 2
    {{METRICS_DASHBOARD}} — Grafana / Datadog URL, or remove step 2b
    {{REPRO_COMMAND}}     — your smallest-repro script (`scripts/repro.sh`, `make repro`)
  Remove this comment block after adapting.
-->

## Before You Start

- `CLAUDE.md` → **Things to Know** section — known-gotchas for this subsystem.
- Any scope-level `CLAUDE.md` under the {{SUBSYSTEM}} directory.
- `{{LOG_LOCATION}}` — where the evidence is.

## Step 1: collect symptoms

Ask the user (or extract from the report):

- **What did you see?** Exact error message, stack trace, HTTP status, UI screenshot.
- **When did it start?** A specific deploy? A specific user action? An always-existing bug finally noticed?
- **Scope:** everyone or a specific user/tenant? All environments or just prod?
- **Correlation ID / request ID / trace ID**, if any.

Without symptoms you have a hunch, not a bug.

## Step 2: gather evidence

```bash
# Fetch the relevant logs
{{LOG_LOCATION}}

# If you have a trace ID, open it in {{TRACE_TOOL}}
# (or skip this step if the project has no tracing)
```

Skim the logs for:

- The error at or near the reported timestamp.
- What happened just BEFORE the error (often the cause isn't at the error line).
- Any adjacent warnings the team habitually ignores.

### Step 2b — if the issue is performance, not correctness

```bash
# Open {{METRICS_DASHBOARD}} and inspect:
#   - Request rate and error rate
#   - Latency distribution (p50, p95, p99)
#   - Resource saturation (CPU, memory, DB connections)
```

A latency spike without an error rate change often points to a specific slow path; with errors it points to a failure cascade.

## Step 3: narrow the blast radius

Classify the bug:

| Classification | Next step |
|---|---|
| Happens on every request | Look at the newest deploy or config change. `git log --since='2 days ago'`. |
| Happens only for a specific user / tenant | Check that user's data for something out of the ordinary (null field, edge case). |
| Happens only in one environment | Compare config and infra. Env-var drift, feature-flag state, network policy. |
| Happens intermittently | Flaky — fixture order, timing, concurrent state. Capture rate and try to correlate with any signal. |

## Step 4: reproduce minimally

Before proposing a fix, reproduce the bug in isolation:

```bash
{{REPRO_COMMAND}}
```

Aim for the smallest input that still fails. If the project has no repro script, it's worth writing one — even a single bash command that hits the endpoint with the offending payload.

If you cannot reproduce, stop and report. "Investigated; cannot reproduce" is a valid outcome. Continuing past non-reproduction produces speculative fixes that sometimes mask the cause.

## Step 5: identify and propose the fix

With a minimal repro in hand:

1. Find the code path the repro hits (`grep` for log messages, trace spans, or known function names).
2. Read the code carefully.
3. Form a hypothesis for the cause.
4. Test the hypothesis — can you modify the input to avoid the bug? Does the hypothesis explain the minimal repro?
5. Propose the fix. Either apply it (if the caller has given scope to do so) or describe it in a report.

## Step 6: prevent regression

Every fixed bug gets one of:

- **A test** that reproduces the bug and fails before the fix, passes after.
- **An alert** (log level + pattern) that will catch the same class of bug in production.
- **A documented "Things to Know" entry** in `CLAUDE.md` if the fix is conditional on knowledge that isn't visible in the code.

Without at least one of these, the bug will return.

## Verify

- **Repro no longer reproduces.** Re-run `{{REPRO_COMMAND}}` after the fix.
- **The regression test passes.**
- **No new errors in logs** after the fix has been deployed for a few hours.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Proposing a fix without a minimal repro | Step 4 is mandatory. A fix without a repro is a guess. |
| Fixing the symptom, not the cause | If the fix is "catch and ignore the error," you're hiding the bug. Trace back to why the error occurs. |
| Skipping step 6 (regression test / alert) | The bug WILL return. Always add a guard. |
| Treating "can't reproduce" as failure | Cannot-reproduce is a valid report. Document what you tried and close. |
