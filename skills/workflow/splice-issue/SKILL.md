---
name: splice-issue
description: >
  Break a large GitHub issue into independent, mergeable sub-issues with clear scope and
  acceptance criteria. Use when user says 'split this issue', 'break this down', 'this issue
  is too big', 'splice this epic', 'create sub-issues', or 'decompose this task'. Do NOT use
  for planning implementation steps within a single issue (use plan-issue) or for creating a
  fresh issue from scratch.
allowed-tools: Read, Grep, Glob, Bash
---

# Splice an issue — decompose into sub-issues

Take an oversized issue or epic and cut it into a set of independently mergeable sub-issues. Each sub-issue should be 1–3 days of work, ship independently, and leave the system in a working state if later ones don't land.

## Before You Start

- The source issue — read it in full with `gh issue view <number>`.
- Any linked design docs or ADRs — find them in the issue body or referenced PRs.
- The project's contribution guide (`CONTRIBUTING.md`, `.github/CONTRIBUTING.md`) — it may specify issue conventions (labels, milestones, project board).

## Step 1: read the issue end-to-end

```bash
gh issue view <number> --comments
```

Identify:

- The **goal** — what "done" looks like in user-visible terms.
- The **scope boundary** — what's explicitly out of scope.
- **Linked issues / PRs** — prior work that informs this one.
- **Mentioned files or subsystems** — where the work lives in the codebase.

## Step 2: map the work to the codebase

```bash
# For each subsystem mentioned, inspect it
ls src/<mentioned-area>/
grep -rn "<key-term>" src/ | head -20

# Recent activity in relevant files
git log --oneline -20 -- src/<area>/
```

The goal is to know WHERE each chunk of work would land, so sub-issues can be scoped to independent code areas.

## Step 3: identify natural seams

Look for cut lines that produce independently shippable pieces:

- **Data first, then behavior** — add a field or table migration as one issue; use it as a second.
- **Read-only before mutation** — "display X" before "edit X."
- **Backend then frontend** (or vice-versa) when the contract is stable.
- **Single-user before multi-user** — demo-quality before production-quality.
- **One entity at a time** — if the epic covers three entity types, three sub-issues.
- **Instrumentation before change** — log / metric the current behavior before rewriting it.

Each seam should satisfy:

- **Independently mergeable.** The system works without the next issue landing.
- **User- or developer-visible.** Produces observable value.
- **Testable on its own.** Not just scaffolding with no behavior.

## Step 4: draft the sub-issues

For each chunk, draft an issue with this shape:

```markdown
## {one-line title — imperative, concrete}

Part of #{parent-issue}.

### Context
{2–3 sentences: the parent goal, where this slice fits in.}

### Scope
- What this issue adds: {bullet list — specific files or behaviors}
- What this issue does NOT cover: {explicit non-goals, linking to sibling sub-issues}

### Acceptance criteria
- [ ] {Testable outcome 1}
- [ ] {Testable outcome 2}
- [ ] {Tests added / updated}
- [ ] {Docs updated if public behavior changed}

### Dependencies
- Blocks: #{sibling-issue-if-this-must-land-first}
- Blocked by: #{sibling-issue-this-waits-on}
- Independent of: {list siblings this doesn't touch}
```

Aim for **3–6 sub-issues** on a typical epic. If you're at 10+, the parent was probably multiple epics.

## Step 5: present to the user

Before creating anything on GitHub, show the full plan:

```markdown
## Splice plan for #{parent-issue}: {parent title}

Proposed sub-issues (ordered by dependency):

1. **#NEW-1** — {title} — {1-line scope}
2. **#NEW-2** — {title} — {1-line scope} (blocked by #NEW-1)
3. **#NEW-3** — {title} — {1-line scope} (independent)
...

Estimated order of implementation: 1 → (2, 3 in parallel) → 4 → 5.
```

Get explicit user approval before creating issues. Offer to adjust the seams.

## Step 6: create the sub-issues

After approval:

```bash
for each sub-issue draft:
  gh issue create --title "<title>" --body "<body from step 4>" --label "part-of-<parent>"
```

Capture the new issue numbers. Then update the parent:

```bash
gh issue comment <parent> --body "$(cat <<EOF
Spliced into sub-issues:
- [ ] #<NEW-1> — <title>
- [ ] #<NEW-2> — <title>
...
Closing this epic; individual sub-issues track work.
EOF
)"

# If the parent is an epic that should stay open to track the rollup, skip the close.
gh issue close <parent> --comment "Work tracked in sub-issues listed above."
```

## Verify

```bash
# Every sub-issue exists and references the parent
for n in <NEW-1> <NEW-2> ...; do
  gh issue view "$n" | grep -i "part of"
done

# The parent references every sub-issue
gh issue view <parent> | grep -E "#<NEW-[0-9]+>"
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Sub-issues that depend on each other linearly (no parallelism) | Look for independent cuts (by entity, by layer, by user segment). A linear 5-issue chain is often a single sequenced issue with phases. |
| Sub-issues with no visible outcome | "Set up scaffolding" alone isn't an issue — fold it into the first user-visible slice. |
| Acceptance criteria that say "works well" | Concrete, testable: "`/api/users/:id` returns 404 for a missing user with `Content-Type: application/json`." |
| Creating issues before the user approves the splice | Always show the plan first (step 5). Issues are public records — wrong splits waste everyone's time. |
