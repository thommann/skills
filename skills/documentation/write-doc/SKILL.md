---
name: write-doc
description: >
  Write a new doc-site page (guide, tutorial, reference, concept) following the project's
  docs conventions. Use when user says 'write a doc', 'add a page to the docs site', 'create
  a guide for X', 'write a tutorial', 'document this concept', or 'add reference for our API'.
  Do NOT use for feature-specific end-user docs (use document-feature), ADRs (use document-decision),
  or CLAUDE.md updates (use create-or-audit-claude-md).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Write a doc — create a new docs-site page

Author a new page in the project's documentation site. Works with any Markdown-based site (VitePress, Docusaurus, MkDocs, mdBook, Hugo).

## Before You Start

- The docs root — `docs/`, `docs-site/`, `website/`, or equivalent. Use `find . -maxdepth 3 -type f -name '*.config.*' | xargs grep -l -i 'doc'` to locate config.
- The docs site's frontmatter conventions — look at 2–3 existing pages.
- The site's navigation config (sidebar, navbar) — adding a file without wiring it in is invisible.

## Step 1: classify the page

Use the Diátaxis framework (or the project's equivalent):

| Type | Question it answers | Example |
|---|---|---|
| **Tutorial** | "How do I get started from zero?" | "Your first request" |
| **Guide** | "How do I solve a specific problem?" | "Migrating from v1 to v2" |
| **Reference** | "What exactly does this thing do?" | "API reference: `/v1/users`" |
| **Concept** | "What is this and why does it exist?" | "How our event system works" |

Pick one. A page that tries to be two types ends up being neither.

## Step 2: find the right location

```bash
ls docs/
# Typical layout:
# docs/
#   getting-started/     # tutorials
#   guides/              # problem-driven guides
#   reference/           # API/config reference
#   concepts/            # explanations
```

Place the new file in the correct category. If the site uses locales (`index.en.md`, `index.de.md`), write the primary locale first; translations come after.

## Step 3: copy frontmatter from a sibling page

Every docs engine uses frontmatter; the exact fields vary:

```yaml
---
# VitePress
title: "Page title"
description: "One-line description for search + social"
# Sometimes:
outline: deep
layout: doc
---

# Docusaurus
id: unique-id
title: Page title
sidebar_position: 3
---

# MkDocs — no frontmatter by default; title comes from the first H1
---
```

Copy frontmatter from a neighboring page and adjust.

## Step 4: write with the type's shape

### Tutorial

1. State the outcome in one sentence.
2. List prerequisites (versions, accounts, prior knowledge).
3. Walk through a minimal end-to-end path.
4. Show the user's successful result (screenshot, output block).
5. Link to the next tutorial or a concept page.

### Guide

1. State the problem the guide solves.
2. List when to use this approach vs an alternative.
3. Walk through the solution.
4. Show verification.
5. Link to related guides.

### Reference

1. One-sentence summary.
2. Signature or config schema.
3. Parameters table.
4. Return value or output.
5. Example usage.
6. Related references.

Reference is the most mechanical. Keep examples real — tested code snippets that would run.

### Concept

1. One-sentence "what this is."
2. The problem it solves.
3. How it works, at the right level of abstraction (usually higher than reference).
4. Trade-offs — when it's the right tool vs when it isn't.
5. Links to guides and references.

## Step 5: cross-link

Every page cites its neighbors:

- Tutorials end with "next step" links.
- Guides link to relevant reference pages.
- Reference entries link to the guides that use them.
- Concepts link to guides that apply the concept.

Broken or dangling pages in the site are noise.

## Step 6: add to navigation

```bash
# VitePress sidebar
cat docs/.vitepress/config.ts
# Add the page path in the relevant sidebar group.

# Docusaurus sidebars.js
# Insert the doc id in the category.

# MkDocs mkdocs.yml
# Add under `nav:` in the right section.
```

## Step 7: embed assets

- **Screenshots / diagrams** — store adjacent to the `.md` file: `docs/guides/{topic}/image.png`. Reference with relative paths.
- **Code snippets** — if the project has a code-snippet tester (tested-docs, dprint-runtime), use it. Otherwise copy from a file that is tested, and reference the source: `<!-- from src/example.ts -->`.
- **Videos** — link, don't embed raw binary. Host on the project's tenant (not personal accounts).

## Verify

```bash
# Build the docs site to catch broken links and invalid frontmatter.
# (Project-specific command from CLAUDE.md Quick Reference.)
# Examples:
# pnpm docs:build
# yarn build
# mkdocs build --strict
# mdbook build

# The page appears in navigation — browse to it in the built site.
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Tutorial that jumps into the advanced use case | Tutorials assume zero context. If the reader needs to know something, state the prereq or teach it. |
| Reference with no examples | Add one working example per entry. Schema alone is often not enough to unblock a reader. |
| Guide that reads like a tutorial ("Welcome! In this guide...") | Guides are problem-first: the reader already has the problem, they're looking for the solution, not an onramp. |
| Writing a single page that's tutorial + reference + guide | Split. One page per type. Cross-link generously. |
| Page file exists but not in navigation | Users can't find it. Wire it in the sidebar/nav config (step 6). |
