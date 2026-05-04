---
name: document-feature
description: >
  Write user-facing documentation for a new or changed feature, in the project's docs site.
  Use when user says 'document this feature', 'write user docs', 'create feature page', 'add
  to the docs site', or 'write the end-user guide'. Do NOT use for internal architecture
  docs (use arc42 or write-doc), ADRs (use document-decision), or CLAUDE.md updates
  (use create-or-audit-claude-md).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Document a feature — user-facing docs

Write a feature page that a user (not a developer) can follow. Covers: what the feature does, why it exists, how to turn it on, how to use it, and where its boundaries are.

## Before You Start

- The project's docs site root — common locations: `docs/`, `docs-site/`, `website/`, or a sibling `docs` package. Find it with `find . -maxdepth 3 -type f -name 'vitepress.config.*' -o -name 'docusaurus.config.*' -o -name 'mkdocs.yml'`.
- A well-written existing feature page — read 1–2 to match voice and structure.
- The feature's PR or design doc — the source of truth for behavior.
- Any screenshots, diagrams, or demo videos attached to the feature's issue or PR.

If the project has no docs site, ask the user whether this documentation belongs in `README.md`, a dedicated `FEATURES.md`, or a new docs site entirely.

## Step 1: understand the audience

Who reads this page? Usually one of:

- **End users** — people who click the UI. They need: what does this do for me, how do I turn it on, what's the shortest path to value.
- **Administrators / operators** — people who configure the system. They need: how to enable, permissions required, operational characteristics (latency, cost, failure modes).
- **Integrators** — developers calling your API. They need: request/response shapes, auth, rate limits, migration path.

Each audience gets a different page shape. If the feature serves more than one, write separate pages or separate sections.

## Step 2: find the doc path convention

```bash
ls docs/  # or docs-site/
find docs -type f -name '*.md' | head -20
```

Common patterns:

- `docs/features/<feature-name>.md`
- `docs/guides/<feature-name>/index.md`
- Localized: `docs/<section>/<feature>/index.en.md`, `docs/<section>/<feature>/index.de.md`
- Versioned: `docs/v2/features/<feature>.md`

Match the existing pattern exactly. Look at the file a user gets to from the docs site's navigation.

## Step 3: write the page

Structure for an end-user feature page:

```markdown
---
title: {Feature name — noun phrase}
description: {One-sentence summary that appears in search and social cards}
---

# {Feature name}

{One-paragraph "what it is, why it exists." Anchored in a user problem: "If you want to X,
this feature does Y." Not a technical description.}

## Prerequisites

- {Permissions or roles required}
- {Subscription or plan required, if any}
- {Other features that must be enabled first, with links}

## Enabling

{Step-by-step. Start from the most common entry point — usually the settings page or a CLI
command. Use screenshots where they save words; otherwise use numbered steps with UI labels in bold.}

1. Open **{Settings} → {Section}**.
2. Toggle **{Feature name}** on.
3. Click **Save**.

## Using

{Walk through the happy path. The user follows these steps and sees the feature work.}

### {Common task 1}

{Specific instruction, ending in an observable outcome.}

### {Common task 2}

{Another task.}

## Limits and boundaries

{Explicit list of what this feature does NOT do, rate limits, known caveats. Saves support
tickets.}

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| {what the user sees} | {what went wrong} | {concrete action} |

## Related

- [{Related feature}]({link})
- [{API reference, if applicable}]({link})
```

### Writing discipline

- **Start from the user's goal, not the feature's name.** "If you want to send a notification when a build fails" beats "Build-Failure Notifications are a feature that...".
- **Use the actual UI labels.** Bold them: **Settings**, **Save**. If the label changes, the docs rot — but rot is detectable.
- **Limits belong in a prominent section**, not a footnote. Users hit them; putting them up front saves frustration.
- **Troubleshooting is real.** Anticipate the top 3–5 failure modes. If the feature has a support history, mine the tickets.

## Step 4: add the page to navigation

Docs sites require a manual nav entry — the file existing isn't enough. Find the nav config:

```bash
# VitePress
cat docs/.vitepress/config.* | grep -A 10 "sidebar\|nav"
# Docusaurus
ls docs/sidebars* website/sidebars*
# MkDocs
cat mkdocs.yml | grep -A 20 "nav:"
```

Add a line pointing at the new file in the right section.

## Step 5: generate or embed assets

If the page needs screenshots or diagrams:

- **Screenshots:** store in `docs/<feature>/images/` alongside the page. Naming: `{feature}-{step-or-state}.png`.
- **Diagrams:** prefer Mermaid for anything the docs site renders natively (VitePress, Docusaurus do). SVG for complex diagrams. Avoid raster PNG exports of diagrams — they don't scale.

## Verify

```bash
# The page builds without broken links
# (Run the docs site's build command from CLAUDE.md Quick Reference)
# e.g. pnpm docs:build  OR  mkdocs build --strict  OR  yarn build

# The page appears in navigation
# Browse the rendered site and click through.

# Screenshots referenced by the page exist
grep -oE '!\[[^\]]*\]\([^)]+\)' <doc-path> | grep -oE '\([^)]+\)' | tr -d '()' | while read img; do
  [ ! -f "$(dirname <doc-path>)/$img" ] && echo "MISSING: $img"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Writing in developer voice ("This endpoint accepts a `User` object...") | Rewrite for the user. If the page is for integrators, it's a different page — use the API reference template. |
| Listing every setting without explaining which matter | Lead with the happy path (3–5 settings). Push exhaustive options into a "Reference" subsection or a separate page. |
| No troubleshooting section | Add one. Even "none that we know of" plus a contact/support link is better than silence. |
| Page exists but isn't in navigation | Users can't find it. Update the sidebar/nav file (step 4). |
