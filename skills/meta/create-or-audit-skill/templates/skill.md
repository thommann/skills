---
name: skill-name-here
description: "One dense sentence stating what this skill does. Use when user says 'trigger phrase one', 'trigger phrase two', or 'trigger phrase three'. Do NOT use for (a counter-scenario that redirects to a sibling skill)."
allowed-tools: Read, Grep, Glob, Bash
---

<!--
  Frontmatter rules (enforced by skills/meta/create-or-audit-skill/lib/validate.sh):
    - name: kebab-case, must match the folder name.
    - description: ≥3 trigger phrases in natural language; ≥1 "Do NOT use for" negative scope;
      NO angle brackets (breaks YAML); under 1024 characters total.
    - allowed-tools: principle of least privilege — list only tools this skill actually uses.

  Body rules:
    - ≥3 backtick-wrapped file references somewhere in this file.
    - Must include "## Before You Start", numbered steps, "## Verify", "## Common Mistakes".
    - No banned generic phrases (see skills/meta/create-or-audit-skill/lib/generic-phrases.txt).
    - Every prohibition must come with an alternative in the same section (principle 05).
-->

# <Skill title — human-readable, not a slug>

<!-- One paragraph: what this skill does, when to invoke it, what the user gets out of it. -->

## Before You Start

<!-- List 1–3 exemplar files the reader should open before doing anything. -->

- **Exemplar:** `path/to/the/canonical/example` — a good instance of the thing this skill produces.
- **Convention anchor:** `path/to/file/stating/the/convention` — where the project's rule is defined.
- **Related skill (if any):** link or reference — so the reader can redirect if they're in the wrong place.

## Step 1: <First concrete action>

<!-- Describe the action. Include the exact command(s) to run. -->

```bash
<real, runnable command>
```

## Step 2: <Second action>

<!-- Continue. Reference real files: `src/example.ts`, not "the source file". -->

## Step 3: <Final action, often "wire it up" or "add tests">

<!-- ... -->

## Verify

<!-- The exact command(s) that confirm the skill worked. Include expected output where useful. -->

```bash
# 1. The file exists where we expect it
test -f path/to/produced/file && echo "ok"

# 2. It passes project checks
<project lint / test / format command>
```

## Common Mistakes

<!-- 2–4 real pitfalls with corrections. Each mistake should be something that actually happens. -->

| Mistake | Correction |
|---|---|
| Example: forgetting to register the new file in `src/index.ts` | Add the export; run `<re-export check command>` to verify. |
| ... | ... |
