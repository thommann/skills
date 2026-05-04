---
name: implement-feedback-from-pr
description: >
  Fetch review comments from an existing GitHub pull request and implement the requested changes.
  Use when user says 'address PR feedback', 'implement review comments', 'fix the PR review',
  'reviewer asked for changes', or 'my PR got comments'. Do NOT use for initial PR creation
  (use create-pr) or for writing your own review (use review-diff).
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Implement feedback from a PR review

Fetch reviewer comments from a GitHub pull request, classify them, apply the requested changes, and respond to each comment in-thread.

## Before You Start

- `gh` CLI authenticated — `gh auth status` confirms.
- `CLAUDE.md` — the project's conventions are the reference point when a reviewer asks for a "standard pattern."
- `skills/workflow/review-diff/SKILL.md` — after applying feedback, run `review-diff` locally to check for regressions.

## Step 1: identify the PR

```bash
# Current branch's PR (if one exists)
gh pr view --json number,title,url

# Or by number if the user gave one
PR=<number>
gh pr view "$PR" --json number,title,url
```

Confirm with the user which PR this is.

## Step 2: fetch all review comments

GitHub has three comment types; fetch all:

```bash
PR=<number>

# PR-level "conversation" comments (top-level on the PR)
gh api "repos/{owner}/{repo}/issues/$PR/comments" > /tmp/pr-conversation.json

# Review comments (inline on specific lines)
gh api "repos/{owner}/{repo}/pulls/$PR/comments" > /tmp/pr-inline.json

# Review summaries with verdicts (approved / changes requested)
gh api "repos/{owner}/{repo}/pulls/$PR/reviews" > /tmp/pr-reviews.json
```

Extract the substance:

```bash
jq -r '.[] | "[\(.user.login)] \(.body)"' /tmp/pr-conversation.json
jq -r '.[] | "[\(.user.login)] \(.path):\(.line // .original_line) — \(.body)"' /tmp/pr-inline.json
jq -r '.[] | select(.body != null and .body != "") | "[\(.user.login)] \(.state) — \(.body)"' /tmp/pr-reviews.json
```

## Step 3: classify each comment

Put every comment into one of five buckets:

| Bucket | What to do |
|---|---|
| **Must change** — reviewer is correct, apply the change | Implement, commit separately, reply to the thread linking the commit |
| **Question** — reviewer asked something | Answer in-thread; no code change needed |
| **Discuss** — reviewer suggested an alternative worth considering | Reply with your reasoning; if you agree, move to "must change"; if not, explain why |
| **Out of scope** — valid point but outside this PR's goal | Reply acknowledging, link to a follow-up issue you create |
| **Nit / optional** — formatting, personal preference | Apply if easy, otherwise acknowledge |

Show the classified list to the user before acting. Let them adjust the buckets.

## Step 4: apply "must change" edits

For each comment in **Must change**:

1. Open the file and make the change exactly as the reviewer requested (or the closest correct interpretation).
2. Commit as a separate commit with a message referencing the feedback:

   ```bash
   git add <file>
   git commit -m "fix: address review feedback on <file> — <one-line summary>"
   ```

3. Push the commit:

   ```bash
   git push
   ```

Do NOT squash review-fix commits into feature commits — the reviewer wants to see the diff from their comment.

## Step 5: create follow-up issues for out-of-scope items

For each **Out of scope** comment, create a GitHub issue:

```bash
gh issue create --title "Follow-up: <one-line>" --body "$(cat <<EOF
Raised in #<PR-number>:

> <quote from the comment>

<your proposed scope>
EOF
)"
```

Capture the issue URL for the reply.

## Step 6: reply to every comment

For each review comment, post a reply. Use the comment's `id` from `/tmp/pr-inline.json`:

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/$PR/comments/<comment-id>/replies" \
  -f body="Addressed in <commit-sha>. <optional note>."
```

For conversation-level comments:

```bash
gh api -X POST "repos/{owner}/{repo}/issues/$PR/comments" \
  -f body="Addressed in <commit-sha>. <optional note>."
```

Reply to every comment, even "Nit" ones — a silent response leaves the reviewer wondering.

## Step 7: re-request review

```bash
gh pr comment "$PR" --body "All feedback addressed in <range-of-commits>. Re-requesting review."
gh pr review-request "$PR" --reviewer <reviewer-login>    # if the project uses review-request
```

## Verify

```bash
# Every must-change comment has a commit that references it
git log --oneline origin/main..HEAD | grep -i "review\|feedback"

# Lint/tests still pass after the changes (pull from CLAUDE.md Quick Reference)

# CI has re-run on the latest commit
gh pr checks "$PR"
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Squashing review fixes into the original commits | Keep them separate. The PR reviewer needs to see what changed since they last looked. |
| Silently ignoring a comment | Reply to every comment. "Deferred to follow-up #123" is a valid reply; silence is not. |
| Applying changes you disagree with without pushback | If the reviewer is wrong, reply explaining why. Healthy reviews are dialogues, not dictations. |
| Missing reviews posted as top-level PR comments | Fetch all three comment APIs (`/issues/$PR/comments`, `/pulls/$PR/comments`, `/pulls/$PR/reviews`). They're separate endpoints. |
