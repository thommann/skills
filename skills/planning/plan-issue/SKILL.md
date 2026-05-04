---
name: plan-issue
description: >
  Turn a GitHub issue into an implementation plan — investigate the codebase, propose an
  approach, list critical files and changes, outline test strategy. Use when user says 'plan
  this issue', 'what's the approach for', 'how would I tackle', 'implementation plan for',
  or 'before coding'. Do NOT use for actually implementing (write the code directly after
  the plan) or for breaking a too-large issue into sub-issues (use splice-issue).
allowed-tools: Read, Grep, Glob, Bash
---

# Plan issue — turn an issue into an implementation plan

Produce an implementation plan grounded in the current code. Output is a single markdown document the user reviews before implementation begins.

## Before You Start

- `gh` CLI authenticated (`gh auth status`).
- Root `CLAUDE.md` — for architecture context and coding conventions.
- Any scope-level `CLAUDE.md` for directories likely touched.
- Recent ADRs (`docs/adr/` or equivalent) — past decisions constrain the plan.

## Step 1: read the issue

```bash
ISSUE=<number>
gh issue view "$ISSUE" --comments
```

Extract:

- **Goal** — what does "done" look like in user-visible terms?
- **Scope / non-scope** — what's in, what's out?
- **Acceptance criteria** — testable outcomes.
- **Hints** — file paths, screenshots, error messages, linked PRs, mentioned subsystems.

If the issue is vague on any of these, ask the user before planning.

## Step 2: map the codebase

Find where the work will land:

```bash
# For each mentioned term, find candidate files
for term in "{term1}" "{term2}"; do
  echo "=== $term ==="
  grep -rn "$term" src/ --include='*.py' --include='*.ts' --include='*.js' --include='*.go' --include='*.rs' | head -10
done

# Identify neighbors — files that will likely change together
git log --pretty=format: --name-only -200 | sort | uniq -c | sort -rn | head -30
```

For each candidate file, read enough to understand its responsibility.

## Step 3: propose an approach

Consider 2–3 approaches before locking in. For each:

- **What it does** — one paragraph.
- **Files added / modified** — rough list.
- **Trade-offs** — what you give up vs what you gain.
- **Risk** — what could go wrong or block landing.

Pick one. Explain why in one sentence.

If all approaches have significant risk or the right choice isn't clear, present both approaches to the user and let them choose.

## Step 4: write the plan

```markdown
## Implementation plan for #<issue-number>: <title>

### Goal
{one paragraph — what done looks like}

### Approach
{one paragraph — the chosen approach and why, over alternatives}

### Files to change

| File | Change | Why |
|---|---|---|
| `src/...` | New — ... | ... |
| `src/...` | Modify function `X` to ... | ... |
| `src/...` | Delete — superseded by new ... | ... |

### New tests
| Test | What it asserts |
|---|---|
| `tests/integration/...` | The happy path returns 200 with expected shape |
| `tests/integration/...` | Permission denied returns 403 |
| `tests/unit/...` | Edge case: empty input returns validation error |

### Steps (implementation order)

1. Add the data layer change (`src/repositories/...`). Small, testable.
2. Add the service method using it. Unit tests for the service.
3. Add the controller / route exposing the service. Integration tests.
4. Update docs in `docs/...` referencing the new behavior.
5. Run `<lint command>` and `<test command>` before declaring done.

### Risks and mitigations

| Risk | Mitigation |
|---|---|
| A ripple-effect change to `<file>` breaks an unrelated feature | Search for callers of the changed function first (Phase 1 of impact-analyzer agent). |
| Migration on live data | Wrap in a guard; add a feature flag; roll out behind it. |

### Out of scope

- {Thing the issue hints at but we're not doing in this change} — {follow-up issue idea}
- {Refactor that would be nice but compounds risk} — {separate PR}

### Open questions for the user

- {Ambiguity in the issue that needs a decision}
- {Technical choice that depends on constraints not visible in the repo}
```

## Step 5: present the plan

Share the plan. The user either approves (and implementation starts), asks for changes, or pushes back on the approach. Do NOT write any code until the plan is approved.

## Verify

```bash
# Every file path mentioned in the plan exists (if it's a modify) or has a parent dir (if new)
# Copy the list of `src/...` paths from the plan into a check:
for p in src/foo/x.ts src/bar/y.ts; do
  if [[ "$p" == *new* ]]; then
    [ -d "$(dirname "$p")" ] || echo "PARENT MISSING: $p"
  else
    [ -f "$p" ] || echo "STALE: $p"
  fi
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Planning without reading the code | The plan says "modify `src/users.ts`" but `users.ts` doesn't exist. Read files before naming them. |
| Choosing the first approach without considering alternatives | Briefly name 2–3 approaches so trade-offs are visible. Picking the only one you thought of hides the tradeoff. |
| Acceptance criteria copied verbatim from the issue without expanding | Issues often say "works correctly." Translate into testable, specific outcomes. |
| Starting to code before the user approves | Plans are cheap; wasted code is expensive. Get explicit approval on the plan. |
