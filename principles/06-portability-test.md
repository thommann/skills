# 06 — The portability test

> Every skill, agent, and hook in this library must work in an unrelated project after trivial adaptation. If not, it belongs in the project, not here.

## Why

This library is a collection of generics. An artifact that names `packages/core`, `NATS events`, or `Dagster assets` may be excellent in the project it came from, but dragged into an unrelated codebase it misleads the agent. The agent will look for `packages/core` and find nothing; it will reason about events through the lens of NATS when the target uses Kafka.

The portability test separates **templates** (which ship here) from **worked instances** (which live in a project's own `.claude/`). Worked instances in a specific project are first-class; this library's artifacts are their de-specialized siblings.

## Rule

Every portable artifact (everything under `skills/{meta,workflow,documentation,planning}/`, `agents/examples/`, `hooks/examples/`, `output-styles/`, `statusline/`, `mcp/launchers/`, `settings/`) must PASS this test:

> "Could a stranger drop this into an unrelated project and have it work after replacing a handful of placeholder paths?"

If the answer is no, the artifact is project-specific. Either:

- De-specialize it (remove project names, swap paths for placeholders or conventions).
- Move it to an `examples/` directory with an "Adapt to your project" block.
- Don't include it.

**Project-patterned** artifacts (`skills/scaffolding/`, `skills/debugging/`, `skills/reference/`) are a documented exception — they ship with `{{PLACEHOLDERS}}` and require adaptation. Each category's `README.md` declares this explicitly.

## How validators check it

Mechanical:

- `validate-skill.sh` / `validate-agent.sh` require ≥3 backtick-wrapped path-like references. Generic references to conventional paths (`src/`, `tests/`, `docs/`, `.github/`, `CHANGELOG.md`) count — they name structures present in most projects.
- The generic-phrase ban catches the laziest failures ("following best practices").

Human (required):

- Grep the artifact for concrete project-specific names. Examples of what to ban in a portable artifact: package names (`packages/<name>`), specific service/framework names (a message broker, a vector store, an orchestrator, a web framework), specific UI library names. Any hit in a portable artifact → fail. Maintain the exact list per library instance; this library's is in its root `CLAUDE.md`.
- Ask: *"If I handed this to someone working on an unrelated Python monolith, a Rust CLI, or a Next.js blog, would it mislead them?"* If yes, de-specialize or move to `examples/`.

## Good vs bad

**Bad (fails portability):**
```markdown
## Debug a failing pipeline

1. Check Dagster logs: `dagster asset materialize --select failed_asset`.
2. Open the Langfuse trace at `https://langfuse.internal.example.com/traces/...`.
3. Reproduce locally with `make run-pipeline SCOPE=packages/pipeline`.
```

Every line names a specific tool or path. An adopter on a different stack has nothing to work from.

**Good (portable):**
```markdown
## Debug a failing pipeline

1. Check your pipeline runner's log output (placeholder command: `{{PIPELINE_CMD}} --job failed_job`).
2. If your stack has a tracing system (Langfuse, Jaeger, Tempo, Honeycomb), open the trace for the
   failing run — the trace ID is usually in the log line.
3. Reproduce locally with the smallest possible input; your repo should have a `scripts/reproduce.*`
   or `make repro` for this. If not, create one and add it under `scripts/`.

**Adapt to your project:** replace `{{PIPELINE_CMD}}` with your pipeline CLI. If you don't have
tracing wired, skip step 2 — this skill doesn't require it.
```

The good version names placeholders, offers multiple concrete tool examples, and is explicit about what to replace.

## Exceptions

Three categories are exempt from "ships working" but not from the spirit of the rule:

- **Scaffolding, debugging, reference skill examples** — ship as templates with `{{PLACEHOLDERS}}`. Declared in each README; validators relax accordingly.
- **References to the originating production setup in `decisions/` ADRs** — allowed, because ADRs document why this library exists.
- **Examples in this `principles/` directory** — may name fictional files (`src/auth/jwt.ts`) for pedagogy.
