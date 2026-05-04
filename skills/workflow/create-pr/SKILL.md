---
name: create-pr
description: >
  Prepare code for a pull request by orchestrating sync, format, lint, test, review, and
  doc updates. Use when user says 'create a PR', 'prepare pull request', 'get ready for PR',
  'validate my changes', 'prepare for review', 'pre-merge checks', or 'is this ready to merge'.
  Do NOT use for only running tests, only reviewing (use review-diff), only syncing with main
  (use merge-main), or actually opening the PR on GitHub — this skill stops at "ready."
allowed-tools: Read, Grep, Glob, Bash, Edit
---

# Create PR — pre-pull-request validation orchestration

Orchestrates every check a PR needs before it's opened. Does NOT open the PR — that's a separate action the user takes after this skill reports "ready."

## Before You Start

- `CLAUDE.md` — "Quick Reference" section lists the project's test, lint, and build commands.
- `.github/workflows/` — tells you what CI will run. The local gates should mirror these.
- `skills/workflow/merge-main/SKILL.md`, `skills/workflow/review-diff/SKILL.md` — this skill delegates to them.

## Step 1: commit current work

Same discipline as `merge-main` step 1 — uncommitted changes block the rest.

```bash
git status
git diff
git add <specific-files>
git commit -m "type(scope): concise message"
```

Follow the project's commit convention (check root `CLAUDE.md` or `.github/`). Common patterns: `type(scope): subject` with types from `fix | feat | test | doc | chore | refactor`.

Keep commits focused — one logical change per commit. Imperative mood ("Add X", not "Added X").

## Step 2: sync with main

Delegate to the `merge-main` skill. It commits any stragglers, fetches, merges, resolves conflicts, and validates post-merge. After it returns, the branch is up to date.

## Step 3: format and lint

Run the project's format + lint command (from root `CLAUDE.md` Quick Reference). Common patterns:

```bash
# pick the one your project uses; these are illustrative
make pr-ready
pnpm lint:fix
ruff format . && ruff check --fix .
cargo fmt && cargo clippy --fix --allow-dirty
```

Fix any remaining errors until the command exits clean. Re-run after fixes — lint rules sometimes interact.

## Step 4: run tests

Run the project's test command, scoped to the affected paths when the project supports it:

```bash
# pick the project's pattern
make test
pnpm test
pytest tests/
cargo test
```

**Every test must pass.** Never disable or skip a test to "get to green." Fix root causes.

## Step 5: review changes

Delegate to `review-diff` for a senior-level review against the project's conventions. Fix every **Critical** and **Important** finding. Re-run step 3 (format + lint) and step 4 (tests) for any scopes touched while fixing.

## Step 6: update documentation

If the changes touched:

- **API contracts, schemas, or public behavior** — update the relevant docs (`docs/`, `README.md`, OpenAPI specs, etc.). Delegate to `update-doc` if the project has multiple doc locations.
- **Architecture-level decisions** — an ADR may be required. Delegate to `document-decision`.
- **`CLAUDE.md`-level invariants** — if you discovered a new gotcha while implementing, add it to `CLAUDE.md` under **Things to Know**.

## Step 7: declare ready

Print a summary for the user:

```markdown
## PR Readiness: {branch}

- [x] Committed ({N} commits on this branch)
- [x] Synced with origin/main
- [x] Format + lint clean
- [x] Tests pass ({N} passed)
- [x] Reviewed — {critical resolved, important resolved, suggestions noted}
- [x] Docs updated: {list}
- [ ] PR not yet opened — run `gh pr create` when ready

Summary of changes for the PR body:
{2–4 bullet points}
```

## Critical Rules

- **Do NOT** open the PR. This skill stops at "ready." The user runs `gh pr create` themselves.
- **Do NOT** skip any failing test.
- **Fix the actual problem**, not the symptom.
- **Commit fixes from the review as separate commits**, not amended into feature commits.
- **Do NOT** add backwards-compatibility shims unless the user explicitly asked.

## Verify

```bash
# On a feature branch (not main)
git branch --show-current
# Expected: not "main" / "master"

# Branch is up to date with origin/main
git fetch origin main && git log --oneline HEAD..origin/main | wc -l
# Expected: 0

# Working tree clean
git status --short
# Expected: empty output

# Project-specific final gate (pull from CLAUDE.md Quick Reference)
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Amending feature commits with review-fix commits | Keep review fixes as separate commits. The PR reviewer sees the progression; amending erases it. |
| Running tests against a stale branch | Sync with main first (step 2). Tests passing on an old base prove nothing. |
| Opening the PR before fixing **Important** findings | "Important" from `review-diff` means "should fix before merge." Address them, then open. |
| Updating docs in a separate later PR | Doc drift compounds. Keep code and docs in the same PR — easier to review and less likely to be forgotten. |
