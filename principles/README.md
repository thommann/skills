# Principles

Seven normative docs. Every artifact in this library cites at least one. Validators in `../validation/` mechanically enforce the rules where possible; the rest is human review.

| # | Principle | One-line |
|---|---|---|
| 01 | [Evidence-based](01-evidence-based.md) | Every line traces to a real file, command, or convention — or it gets deleted. |
| 02 | [Dense, not brief](02-dense-not-brief.md) | Skim-optimized is not the goal; load-bearing density is. |
| 03 | [No duplication with tooling](03-no-duplication-with-tooling.md) | If a linter, formatter, or hook enforces a rule, don't restate it in prose. |
| 04 | [File references over snippets](04-file-references-over-snippets.md) | Point at `` `src/auth.ts` ``; embedded snippets go stale. |
| 05 | [Alternatives, not just prohibitions](05-alternatives-not-prohibitions.md) | "Use Y instead of X" beats "Don't use X." |
| 06 | [The portability test](06-portability-test.md) | Every portable artifact must work in an unrelated project after trivial adaptation. |
| 07 | [Safe-merge by default](07-safe-merge.md) | Copy instructions never overwrite; configs deep-merge. |

## How these are enforced

- **Evidence-based** — `validate-skill.sh` counts backtick-wrapped path references and requires ≥3.
- **Dense, not brief** — `validate-claude-md.sh` warns on files under 50 lines.
- **No duplication with tooling** — human review. Question during PR: "Is a linter already enforcing this?"
- **File references over snippets** — human review + skill validator's file-reference count.
- **Alternatives, not just prohibitions** — `validate-claude-md.sh` errors when `never`/`don't`/`do not` appear without a matching `instead`/`use X instead`/`prefer`/`create new`.
- **Portability test** — human review + grep for project-specific names. See `../CLAUDE.md` "Conventions" for the banned list in this library.
- **Safe-merge** — `guides/adopting-in-a-new-project.md` documents the merge recipe; no validator.

## The generic-phrase ban

All principles together reject nine phrases as signal-free: `best practice`, `clean code`, `SOLID principles`, `maintainable`, `readable`, `scalable`, `well-structured`, `production-ready`, `industry standard`. The rejection list lives in `../validation/lib/generic-phrases.txt` and is grep-enforced.
