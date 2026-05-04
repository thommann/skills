---
name: explain
description: >
  Explain a piece of code, a subsystem, or an architectural concept in the codebase, grounded
  in real files. Use when user says 'explain this', 'walk me through X', 'how does Y work',
  'what does this module do', 'help me understand the Z flow', or 'onboard me on this component'.
  Do NOT use for writing permanent docs (use write-doc or arc42) or for code review (use review-diff).
allowed-tools: Read, Grep, Glob, Bash
---

# Explain — guided walk-through of code

Produce a focused, file-anchored explanation. The output is conversational — NOT a permanent doc. If the user wants a persistent artifact, point them at `write-doc`, `document-feature`, or `arc42`.

## Before You Start

- Root `CLAUDE.md` — the ambient context. Read it before explaining anything to match the project's vocabulary.
- Any scope-level `CLAUDE.md` relevant to the code in question.
- If the project has an arc42 tree under `docs/arc42/` or similar, chapters 3 (context), 4 (solution strategy), and 5 (building blocks) are the best orientation for higher-level explanations.

## Step 1: scope the ask

Clarify what level the user wants:

| Level | Example ask | What you do |
|---|---|---|
| **Line/function** | "What does `calculateDiscount` do?" | Read the function and adjacent helpers, explain mechanics. |
| **File/module** | "What does `src/billing/` do?" | Read the module, map exports to responsibilities. |
| **Subsystem** | "How does the billing pipeline work?" | Trace data flow across multiple files, draw the path. |
| **Concept** | "How does our auth model work?" | Read CLAUDE.md + the canonical implementation, explain the pattern. |

If the level is ambiguous, ask before diving. A code-level walk-through and a concept-level explanation require different reading and different output shapes.

## Step 2: orient yourself

For a subsystem or concept explanation, start with the macro view:

```bash
ls <relevant-dir>
find <relevant-dir> -type f | head -30

# Which files are central? (entry points often show up as most-imported)
grep -rn "from ['\"]<relevant-module>" src/ | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
```

For a line or function, just open the file.

## Step 3: read, don't assume

Open the actual files. Every claim you make should trace to a file you have just read, not to pattern-matching on the name.

Common traps:

- The file name suggests one thing; the contents do another.
- A class looks standard but has a project-specific override.
- The "obvious" caller of a function isn't the only caller — grep for all usages.

## Step 4: structure the explanation

For a line/function:

```markdown
## `<function-name>` in `<file>:<line>`

**What it does:** one sentence.

**Inputs:** ...
**Returns:** ...
**Side effects:** (DB writes, network calls, mutations). None if pure.

**Called from:** {list of callers with file:line}.

**How it works:** paragraph walking through the body, naming the helper it delegates to.

**Gotcha (if any):** {a non-obvious thing the reader should know}.
```

For a module:

```markdown
## `<path/to/module>`

**Responsibility:** one-sentence scope — what this module owns.

**Key files:**
- `<file1>` — {what it does}
- `<file2>` — {what it does}

**Public API:** the exports, briefly.

**Depends on:** {other modules this one imports from}.
**Depended on by:** {modules that import this one}.

**How it fits in:** how a typical flow enters this module and what it hands off.
```

For a subsystem/concept:

```markdown
## How `<concept>` works

**What it is:** paragraph at the right level — higher than code, lower than marketing.

**The flow:** step-by-step, naming files and functions at each step.

1. Entry: request arrives at `src/api/routes/<...>.ts:<line>`.
2. Middleware: `<middleware>` runs, validating `<x>`.
3. Handler dispatches to `<service.method>`.
4. Service calls `<repository.method>` and `<external-client.method>`.
5. Response is shaped by `<mapper.method>` and returned.

**The contract:** a minimal code reference (file + line) for the shape.

**Extension points:** where to add a variant. Often a factory, a registry, or a subclass.

**Pitfalls:** 1–3 things that trip up newcomers.
```

## Step 5: link and stop

End the explanation with pointers:

- **To go deeper:** 1–2 files worth reading next.
- **To extend:** the right skill (scaffolding, documentation) or ADR.
- **To verify:** a test file that exercises the flow.

Do **not** write a wall of text. The goal is orientation, not exhaustive coverage.

## Verify

This skill's output is conversational, so there's no mechanical verification. Self-checks:

- Every file path mentioned actually exists (grep the output against the filesystem).
- No claims that aren't anchored in a file you just read.
- The explanation is not a permanent artifact — it's in the chat, not in `docs/`.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Explaining based on file names without reading contents | Read every file you cite. Pattern-matching on names produces confident wrong answers. |
| Dumping 50 lines of code in the response | Reference the file (principle 04). The user can open it. Explain WHY, not WHAT the code already shows. |
| Turning an explanation into a tutorial | If the user wants a reusable walk-through, it's `write-doc`. `explain` is for one-shot context-building in the current conversation. |
| Answering "how does X work" by quoting `CLAUDE.md` alone | `CLAUDE.md` orients; the code answers. Read the code; cite the exact files. |
