---
name: review-diff
description: >
  Review the diff between the current branch and main as a senior developer. Analyzes
  architecture, coding standards, security, performance, and correctness. Use when user
  says 'review my code', 'pre-PR review', 'review diff', 'code review before PR', 'check
  my changes', or 'senior review'. Do NOT use for only running tests (use a test skill),
  only linting (use a lint skill), or full PR preparation (use create-pr).
allowed-tools: Read, Grep, Glob, Bash
---

# Review diff — pre-PR code review

Produce a senior-level review of all changes between the current branch and `origin/main`, organized by severity, with file-and-line references.

## Before You Start

- `CLAUDE.md` — the project's coding conventions and "Things to Know." The review is FROM this perspective.
- Any scope-level `CLAUDE.md` under subdirectories touched by the diff — scope-specific rules override root.
- Recent ADRs (`docs/adr/`, `docs/decisions/`, or `docs/arc42/decisions/`) — the *why* behind recent architectural rules.

## Step 1: gather the diff

```bash
git fetch origin main
git diff origin/main...HEAD
git diff origin/main...HEAD --stat
git log origin/main..HEAD --oneline
```

Read the full diff end to end. Understand every change before reviewing.

## Step 2: read affected CLAUDE.md files

For every top-level directory touched by the diff, check for a scope-level `CLAUDE.md`. Example:

```bash
git diff origin/main...HEAD --name-only | awk -F/ '{print $1"/"$2}' | sort -u | while read d; do
  [ -f "$d/CLAUDE.md" ] && echo "READ: $d/CLAUDE.md"
done
```

## Step 3: review checklist

### Architecture and boundaries

- Code is in the correct scope (shared code in the project's designated shared library — common locations are `src/lib/`, `src/shared/`, or a monorepo's core package — and scope-specific code in its scope).
- No cross-scope imports where the project's rule forbids them (check root `CLAUDE.md` for the dependency-direction rule).
- Layering respected (controller → service → repository or equivalent).
- New public APIs match the existing pattern — read an adjacent file for comparison.

### Coding conventions

Review against every convention in root `CLAUDE.md`. Pay special attention to rules that linters don't catch:

- Use of typed errors vs generic `catch (e)`.
- Dependency-injection conventions.
- Async/sync discipline (e.g., no blocking I/O in async code paths).
- Naming patterns for new public symbols.

### Security (OWASP-style pass)

- No string concatenation in SQL, shell, or logging.
- Auth and permission checks present on new endpoints.
- Secrets are not hardcoded; use the project's secrets mechanism.
- Input validated at boundaries (API params, form submissions, webhook payloads).
- Untrusted input not interpolated into templates or `eval`-like constructs.

### Testing

- New code has corresponding tests.
- Tests assert something meaningful — not just "no exception."
- External services (DB, HTTP APIs, message brokers) are isolated or mocked appropriately.
- Test markers/tags (slow, integration, flaky) applied where the project uses them.

### Performance (when relevant)

- No N+1 queries introduced.
- No loops with per-iteration network calls where a batch would do.
- Hot paths don't allocate unnecessarily.

## Step 4: produce the review

Format findings by severity. Be specific: reference `file.ts:42`, not "somewhere in the users code."

```markdown
## Review of {branch} ({N} files, {+X -Y} lines)

## Critical (must fix before merge)
- `src/api/users.ts:42` — SQL injection via `getUserByName`: user input is concatenated into
  the query. Use the parameterized `db.query(..., [params])` form — see `src/api/orders.ts:78`
  for the pattern.

## Important (should fix)
- `src/services/payment.ts:15` — new service does not extend `ServiceBase`. Convention per
  root `CLAUDE.md` is that all services extend it for logging + error-wrapping.

## Suggestions (nice to have)
- `src/lib/utils.ts:22` — `formatDate` duplicates logic already in `src/lib/dates.ts:8`.
  Consider re-using or removing the duplicate.

## What looks good
- Error handling in `src/api/auth.ts` correctly uses `AppError` subclasses.
- New tests in `tests/integration/users.spec.ts` cover both happy path and permission denial.
```

### Rules for the review output

- Be specific: file:line, not "somewhere."
- Be constructive: state the fix, not just the problem.
- Be honest: if the code is good, say so in **What looks good**.
- Skip nitpicks that the formatter or linter catches (principle 03 — don't duplicate tooling).
- Don't suggest adding backwards-compatibility unless the user asked.

## Verify

The review is presented to the user as a markdown report — there's no auto-verification. Sanity checks:

```bash
# Did you miss any files in the diff?
git diff origin/main...HEAD --name-only | wc -l
# Your review should touch a substantial fraction of these (not necessarily every one —
# formatter-only changes and pure test additions may not need flagging).
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Re-flagging issues the formatter already caught | Skip them — focus on substance. Principle 03: don't duplicate tooling. |
| Vague "this could be cleaner" | Quote the line, propose the specific change, name a file that already does it right. |
| Only finding problems, never acknowledging good work | The "What looks good" section matters — it calibrates the reviewer's honesty and helps the author learn what's landing well. |
| Reviewing against rules from a different project | Re-read `CLAUDE.md` before starting. Every project has its own conventions. |
