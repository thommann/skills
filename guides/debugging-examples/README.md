# Debugging skills — the pattern

Debugging skills are more portable than scaffolding ones — the troubleshooting flow is universal; only the *where to look* is project-specific. This category ships skills that work as-is in ~80% of projects and need a few placeholder substitutions for the rest.

## The pattern (every debugging skill looks like this)

1. **Collect symptoms.** What is the user observing? What error messages, what correlation IDs, what user/request scope?
2. **Gather evidence.** Logs (where?), traces (which tool?), metrics dashboards, test output. Never skip to a guess — the first step is always "open the evidence."
3. **Narrow the blast radius.** Which subsystem? Which commit? Which user segment or tenant? Which environment?
4. **Reproduce minimally.** The smallest repro that still fails. If you can't reproduce, you can't reliably fix.
5. **Fix.** Often hands off to a scaffolding or edit workflow.
6. **Prevent.** Add a regression test or an alert so the bug doesn't silently return.

Skipping step 4 is the most common mistake. A guess-fix without a minimal repro has a high chance of "fixing" a symptom while leaving the cause.

## Contents

- [`TEMPLATE/SKILL.md`](TEMPLATE/SKILL.md) — annotated parameterized skeleton.
- [`examples/debug-backend.md`](examples/debug-backend.md) — structured logs, stack traces, request IDs, cross-service correlation.
- [`examples/debug-frontend.md`](examples/debug-frontend.md) — browser devtools, network tab, source maps, Playwright.
- [`examples/debug-database.md`](examples/debug-database.md) — slow queries, migration failures, connection pool exhaustion, locks.
- [`examples/debug-infrastructure.md`](examples/debug-infrastructure.md) — container logs, DNS, ports, resource limits.
- [`examples/debug-tests.md`](examples/debug-tests.md) — flaky tests, fixture isolation, mock drift, env dependencies.

## How to adapt an example

Most content works as-is. Substitute:

| Placeholder | Replace with |
|---|---|
| `{{LOG_LOCATION}}` | Where your logs are — `kubectl logs`, `docker compose logs`, `/var/log/<app>/`, `logs/`, Datadog, Sentry. |
| `{{TRACE_TOOL}}` | Your tracing — Langfuse, Jaeger, Tempo, Honeycomb, or remove step 2 if none. |
| `{{METRICS_DASHBOARD}}` | Grafana URL, Datadog board, CloudWatch. |
| `{{REPRO_COMMAND}}` | Your smallest-repro script — `scripts/repro.sh`, `make repro`, or prose if none exists. |

Only ~20% of each example needs replacement. The structure and the discipline apply unchanged.

## Validation

Debugging examples use backticked placeholder conventions, so they pass `validate-skill.sh` as shipped. After adaptation, they should still pass.

```bash
bash validation/validate-skill.sh .claude/skills/debugging/debug-backend/SKILL.md
```

## When NOT to write a debugging skill

- The "bug" is a one-off and unlikely to recur. A commit message and a test are enough.
- The subsystem is small enough that the project's general debugging entry (in `CLAUDE.md`) covers it.
- A framework-standard error (404, 500, `NullPointerException`) doesn't need a bespoke skill — the framework's docs cover it.

Debugging skills earn their keep when a specific project's subsystem has *recurring* failure modes requiring project-specific steps to diagnose.
