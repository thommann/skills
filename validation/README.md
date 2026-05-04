# Validation

Shell scripts that mechanically enforce the [seven principles](../principles/). Run them against any artifact in this library — or against artifacts in a project that adopts the library.

## Contents

- [`validate-skill.sh`](validate-skill.sh) — validates a `SKILL.md`
- [`validate-agent.sh`](validate-agent.sh) — validates an agent `.md`
- [`validate-hook.sh`](validate-hook.sh) — validates a hook `.sh`
- [`validate-claude-md.sh`](validate-claude-md.sh) — validates a `CLAUDE.md`
- [`lib/generic-phrases.txt`](lib/generic-phrases.txt) — the rejection regex list (editable)

Each script takes one argument (the file to validate) and exits non-zero on failure, printing a categorized list of **ERRORS** (hard fails) and **WARNINGS** (soft fails).

## Usage

```bash
# Single file
bash validation/validate-skill.sh skills/workflow/review-diff/SKILL.md

# Every artifact in this library
bash validation/validate-all.sh     # if we add it; otherwise:
for f in skills/*/*/SKILL.md;   do bash validation/validate-skill.sh "$f"      || exit 1; done
for f in agents/examples/*.md;  do bash validation/validate-agent.sh "$f"      || exit 1; done
for f in hooks/examples/*.sh;   do bash validation/validate-hook.sh "$f"       || exit 1; done
for f in claude-md/examples/*.md; do bash validation/validate-claude-md.sh "$f" || exit 1; done
```

## Rules enforced

### `validate-skill.sh`

**Errors (exit 1):**
- Folder is not kebab-case, or file is not exactly `SKILL.md`.
- Missing opening/closing `---` frontmatter delimiters.
- Missing `name` or `description` field.
- `name` does not match the folder.
- `description` over 1024 characters.
- `description` contains `<` or `>`.
- Fewer than 3 backtick-wrapped file-path references in the body.

**Warnings:**
- No trigger phrases in description.
- No negative-scope phrase in description.
- Body over 600 lines (likely should be split).
- More than 2 banned generic phrases.
- No `## Verify` section.
- No `## Common Mistakes` section.

Exit code 1 on ≥1 error OR ≥4 warnings. Otherwise 0.

### `validate-agent.sh`

Similar to skill validation plus:

- **Error** if description matches review/analyze/audit/scan/check AND NOT fix/implement/create/write/modify/update AND `tools` contains `Write` or `Edit`. (Read-only enforcement.)

### `validate-hook.sh`

**Errors:**
- Missing `#!/usr/bin/env bash` on line 1.
- Missing `set -euo pipefail`.
- Does not read from stdin (no `cat`, `read`, `/dev/stdin`, `jq` piped from input).
- Blocking (`exit 2`) without stderr output.

**Warnings:**
- No early `exit 0` short-circuit for irrelevant input.
- Uses `set -e` without `-u -o pipefail`.

### `validate-claude-md.sh`

**Errors:**
- Under 30 lines (too thin).
- Zero code blocks AND zero pipe tables.
- Prohibition language (`never`, `don't`, `do not`, `must not`) appears without any alternative marker (`instead`, `use X instead`, `prefer `, `create new`) anywhere in the file.
- One or more banned generic phrases.

**Warnings:**
- Under 50 lines (thin).
- No `## Architecture` section.
- No `## Things to Know` section.

## The generic-phrase list

`lib/generic-phrases.txt` is a grep-compatible regex list (one pattern per line, case-insensitive). Phrases inside backticks or double quotes are treated as mentions (pedagogical) and excluded from the count — the validator strips quoted content before matching.

Adopters can edit this file in their own project (add terms that signal low-effort prose in their codebase). The validators read it at runtime.

## Running against an adopting project

```bash
# From the library repo
LIB=~/.local/share/ai-augmented-se
PROJ=~/myproject

for f in "$PROJ"/.claude/skills/*/SKILL.md; do
  bash "$LIB/validation/validate-skill.sh" "$f" || true
done
```

A pre-commit hook recipe for an adopter lives in [`../hooks/examples/stop-lint-check.sh`](../hooks/examples/stop-lint-check.sh).

## What the validators don't check

- **Principle 03 (no duplication with tooling)** — human review. The validator can't know what the project's linter enforces.
- **Principle 04 (point, don't paste)** in detail — the file-reference count catches the gross case; reviewing whether a snippet should be a reference is human.
- **Principle 06 (portability)** beyond the generic-phrase grep — the library maintains its own list of project-specific names to catch in its own `CLAUDE.md`, but adopters will have their own list. Not enforced by these scripts.
- **Principle 07 (safe-merge)** — procedural, enforced in the guides and review, not by a script.
