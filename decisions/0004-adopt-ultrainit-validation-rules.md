# 0004 — Adopt ultrainit's validation rules verbatim (with one adjustment)

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

Ultrainit ships two standalone quality validators (`scripts/validate-skill.sh`, `scripts/validate-subagent.sh`) plus validation functions inside `lib/validate.sh` for `CLAUDE.md` and hooks. These scripts encode:

- Mechanical structure checks (frontmatter, shebang, file extension).
- Content quality gates (trigger phrases, negative scope, description length, angle brackets, file-reference count).
- A generic-phrase rejection list (`best practice`, `clean code`, `SOLID`, etc.).

The library needed a validation story. Options ranged from "no validation" to "rewrite from scratch."

## Decision Drivers

- **The rules are good.** ultrainit's thresholds (≥3 file references, ≥3 trigger phrases, ≥1 negative scope, < 1024 chars, no angle brackets) are backed by observed failure modes.
- **Rules should be enforced from day one.** If the library itself fails its own validators, it has no authority to recommend them.
- **Independent of the generator.** The rules are self-contained; porting them to standalone scripts is straightforward.
- **Adopters should be able to run validators in their own projects.** No dependency on the library's internals; standalone bash.
- **One gap to fill.** Ultrainit's validator scans for banned phrases across the whole file, including backticked mentions. For a library whose documentation discusses the banned phrases, this is a bug — the validator flags pedagogical mentions.

## Considered Options

1. **Copy ultrainit's scripts verbatim.** Least work; preserves the exact rule set.
2. **Port logically, rewrite the scripts.** Match the rules but write our own bash.
3. **Drop the validators entirely.** Principles as prose; human review only.

## Decision

We chose **Option 2: port logically, rewrite the scripts** — and added one adjustment: before the generic-phrase scan, strip backtick-delimited and double-quoted content.

The library's validators in `validation/` mirror ultrainit's rule set. They're standalone bash with no dependencies beyond `jq`. Each accepts one file path argument and exits non-zero on failure with categorized errors and warnings.

The backtick/quote-stripping preprocessing:

```bash
sed -E 's/`[^`]*`//g; s/"[^"]*"//g' "$file" | grep -ciEf "$GENERIC_PHRASES_FILE"
```

Treats phrases inside backticks or double quotes as mentions (pedagogical), not usages. This allows documentation files to enumerate the banned list without failing their own check.

## Consequences

### Positive

- Every artifact this library ships is self-validated.
- Adopters can run the same validators on their own projects by copying `validation/` alongside the artifacts.
- The rules are versioned alongside the library; if we discover a better rule, we edit the script and commit.
- Adding new rules is a bash edit, not a pipeline change.
- The backtick/quote fix lets pedagogical documentation coexist with the strict ban.

### Trade-offs

- Bash validators are less expressive than proper parsers. Complex rules (e.g., semantic duplication detection) remain human review.
- The ports may diverge from ultrainit over time if ultrainit tightens rules we don't adopt.
- The generic-phrase file is editable per-project, but the library's version is the canonical starting list.

## References

- [`../validation/README.md`](../validation/README.md) — full rule enumeration.
- [`../skills/meta/create-or-audit-skill/lib/validate.sh`](../skills/meta/create-or-audit-skill/lib/validate.sh), [`../skills/meta/create-or-audit-agent/lib/validate.sh`](../skills/meta/create-or-audit-agent/lib/validate.sh), [`../skills/meta/create-or-audit-hook/lib/validate.sh`](../skills/meta/create-or-audit-hook/lib/validate.sh), [`../skills/meta/create-or-audit-claude-md/lib/validate.sh`](../skills/meta/create-or-audit-claude-md/lib/validate.sh) — the port targets.
- [`../skills/meta/create-or-audit-skill/lib/generic-phrases.txt`](../skills/meta/create-or-audit-skill/lib/generic-phrases.txt) — the rejection list.
- [`../principles/`](../principles/) — the seven principles these validators enforce.
