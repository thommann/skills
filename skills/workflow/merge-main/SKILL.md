---
name: merge-main
description: >
  Sync the current feature branch with origin/main by committing local work, fetching,
  merging, and resolving conflicts. Use when user says 'merge main', 'update from main',
  'sync with main', 'pull main into branch', 'branch is behind main', or 'update my branch'.
  Do NOT use for creating PRs (use create-pr), reviewing code (use review-diff), or any
  rebase workflow — this skill does merge, not rebase.
allowed-tools: Read, Grep, Glob, Bash, Edit
---

# Merge main — sync feature branch with main

Bring the current feature branch up to date with `origin/main`: commit local work, understand what changed on main, merge, resolve conflicts, validate. Leaves the branch ready for a clean PR.

## Before You Start

- `CLAUDE.md` — check for the project's commit-message conventions and any post-merge validation steps.
- `.github/` or the project's CI config — identifies what CI expects after a merge (lockfile regen, codegen, ...).
- A clean working tree before starting. If there are uncommitted changes, this skill commits them first.

## Step 1: commit current work

Uncommitted changes cause merge failures. Commit before fetching:

```bash
git status
git diff --stat
```

If there are uncommitted changes:

```bash
git add <specific-files>         # prefer listing files over `git add -A`
git commit -m "type(scope): concise message"
```

Use the project's commit convention (check `CLAUDE.md` or `.github/`; common forms: `type(scope): message`, Angular-style, or plain imperative).

## Step 2: fetch and measure distance

```bash
git fetch origin main
behind=$(git log --oneline HEAD..origin/main | wc -l)
ahead=$(git log --oneline origin/main..HEAD | wc -l)
echo "Branch is $behind commits behind and $ahead ahead of origin/main."
```

If `behind` is 0, stop — nothing to merge.

## Step 3: understand what changed on main

```bash
git log --oneline HEAD..origin/main
git diff --stat HEAD...origin/main
```

Identify files changed on **both** main and this branch — these are conflict candidates:

```bash
git diff --name-only HEAD...origin/main > /tmp/main_changes.txt
git diff --name-only origin/main...HEAD > /tmp/branch_changes.txt
comm -12 <(sort /tmp/main_changes.txt) <(sort /tmp/branch_changes.txt)
```

Summarize for the user: how many main commits arrived, which directories they touched, which files overlap with this branch's changes.

## Step 4: merge

```bash
git merge origin/main
```

Clean merge → step 6. Conflicts → step 5.

## Step 5: resolve conflicts

```bash
git diff --name-only --diff-filter=U
```

For each conflicted file:

1. **Read the file** — understand both sides of the conflict.
2. **Read the main-side history** — `git log --oneline -5 origin/main -- <file>`.
3. **Decide resolution strategy**:

**Resolve yourself when:**

- The conflict is in a generated/lock file (`package-lock.json`, `pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`) — accept one side, then regenerate with the project's tool.
- The conflict is purely additive (both sides added different items to a list, import block, or config).
- The conflict is in a file you didn't intentionally change (formatting-only, auto-formatter drift).

**Ask the user when:**

- Both sides made substantive changes to the same function or class.
- The conflict involves architectural decisions.
- Business logic or test assertions are in conflict.

After resolving each file:

```bash
git add <resolved-file>
```

After all conflicts resolved:

```bash
git commit                       # use the default merge message; do not amend
```

## Step 6: post-merge validation

```bash
# Regenerate lockfile if the package manifest changed on main
# (pick the one your project uses)
# pnpm install    # if pnpm-lock.yaml was conflicted or package.json changed
# uv lock         # if uv.lock was conflicted
# cargo check     # validates Cargo.toml + Cargo.lock

# Re-run lint/typecheck to catch merge mistakes
# (use the project's command from Quick Reference in CLAUDE.md)
```

If the post-merge state needs a commit (lockfile regen, regenerated artifacts):

```bash
git add <regenerated-files>
git commit -m "chore: post-merge regen after syncing with main"
```

## Step 7: verify

Delegate to `review-diff` to check the full branch vs main. This catches merge mistakes where the wrong side was kept or the resolution introduced an inconsistency.

## Critical Rules

- **Never force-push after merging.** The merge commit is permanent.
- **Do not `git rebase`** a branch that's been pushed. This skill does merge. If the project mandates rebase, use a different skill — not this one.
- **Do not silently drop one side of a conflict.** If both sides made real changes, ask the user.
- Always commit before merging — uncommitted work gets clobbered.
- Use the default merge commit message; don't amend it.

## Verify

```bash
# No conflicts remain
git status
# Expected: "nothing to commit, working tree clean" (or only the merge commit)

# Branch is now up to date with origin/main
git log --oneline HEAD..origin/main | wc -l
# Expected: 0

# Lint/typecheck passes (project-specific command from CLAUDE.md)
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Running `git merge` with uncommitted changes | Commit first (step 1). Stashing loses the conventional-commit message. |
| Accepting one side of a lockfile conflict without regenerating | Accept either side, THEN run the package manager's regen command. Otherwise the lockfile drifts from the manifest. |
| Resolving a function-body conflict by deleting one side | Never drop real changes silently. If unsure which side's intent wins, ask. |
| Force-pushing to rewrite the merge commit | Merge commits stay. If the merge was wrong, create a revert commit instead. |
