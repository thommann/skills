# Anti-patterns

Common failure modes in `.claude/` setups. Each has a symptom → diagnosis → fix shape.

## Symptom: Claude keeps missing obvious patterns

**Diagnosis:** `CLAUDE.md` is too thin, or contains generic advice instead of project-specific invariants.

**Fix:** Audit with `skills/meta/create-or-audit-claude-md`. Add a **Things to Know** section with 5–10 real gotchas drawn from recent bug fixes. Generic advice ("follow best practices", "write clean code") comes out.

---

## Symptom: A skill fires for unrelated queries

**Diagnosis:** Description is too broad, or missing a "Do NOT use for" clause.

**Fix:** Tighten trigger phrases to be the exact words users say, and add a negative-scope clause pointing at a sibling skill:

```yaml
description: >
  Do NOT use for <adjacent case that should invoke <other-skill> instead>.
```

---

## Symptom: A skill never fires even when it should

**Diagnosis:** Trigger phrases don't match how users actually phrase the request.

**Fix:** Ask users how they ASK for the thing. "Code review before PR" → include "review my code", "check before PR", "review diff". Don't use internal vocabulary; use engineer vocabulary.

---

## Symptom: Hooks are making Claude Code noticeably slow

**Diagnosis:** A hook is doing expensive work unconditionally. Common causes: running a formatter on every file type, checking network, not short-circuiting.

**Fix:** Add early `exit 0` for wrong tool name, wrong file extension. Filter to the matching case. Run heavy tools only when relevant.

---

## Symptom: Claude is breaking the rules you wrote in `CLAUDE.md`

**Diagnosis:** Usually one of:

1. The rule is buried in a dense paragraph — not callout-formatted.
2. The rule is stated without an alternative ("don't use X"), and the agent can't find the "right" way.
3. The rule contradicts another rule in the same file or a subdirectory `CLAUDE.md`.

**Fix:** Move rules to lists or tables. Add "use Y instead" to every "don't use X" (principle 05). Resolve contradictions — conflicting rules make the agent pick randomly.

---

## Symptom: Formatters / linters running twice (once by hook, once by Claude)

**Diagnosis:** `CLAUDE.md` tells Claude to "always run `make pr-ready` before committing," AND a `Stop` hook runs `make pr-ready` automatically.

**Fix:** Principle 03 — if a hook enforces it, don't restate in prose. Delete the `CLAUDE.md` line; keep the hook.

---

## Symptom: `CLAUDE.md` says "see ADR-xyz" but the ADR doesn't exist

**Diagnosis:** Stale references. The ADR was renamed, deleted, or never written.

**Fix:** Run `grep -oE '\bADR-[0-9]+\b' CLAUDE.md` and verify each. Update or remove. Add a periodic check — the `update-doc` skill sweeps for stale refs.

---

## Symptom: An agent returns inconsistent report formats

**Diagnosis:** The agent's system prompt lacks an output-format skeleton, so each invocation improvises.

**Fix:** Add a "What You Report Back" section with an explicit markdown skeleton. Callers can now parse the report mechanically.

---

## Symptom: A reviewer agent has `Write` and `Edit` tools

**Diagnosis:** Either the agent's role crept ("review AND fix"), or the author didn't think about least privilege.

**Fix:** Remove `Write`/`Edit` from the `tools` list. If the agent needs to take actions, split it into an analyzer agent + a skill that applies the analyzer's output.

---

## Symptom: Skills directory is bloated (40+ skills) and slow to invoke

**Diagnosis:** Each skill's description adds ~100 tokens to every session. 40 skills = ~4000 tokens of overhead.

**Fix:** Audit with `skills/meta/create-or-audit-skill` (Mode 3). Remove:

- Skills that fail the portability test.
- Skills that duplicate another skill.
- Skills that are really one-liners that belong in `CLAUDE.md`.
- Skills that fire less than monthly.

---

## Symptom: Scaffolding skills produce the wrong structure

**Diagnosis:** The "exemplar" cited in the skill is stale — recently-added code follows a different pattern.

**Fix:** Run through the skill's `Before You Start` section: does the exemplar path exist? Does it reflect current conventions? Update the exemplar reference to the newest correct instance.

---

## Symptom: Documentation skills produce walls of boilerplate

**Diagnosis:** The skill is generating output from its own template rather than reading real project documents.

**Fix:** Every doc skill's Step 1 is "Read the canonical existing doc." Enforce this. If the project has 5 feature pages and none is cited in the skill, the skill isn't doing research, it's filling a template.

---

## Symptom: Hooks block Claude with "file not found" for a missing formatter

**Diagnosis:** The hook did `exit 1` when `ruff` wasn't installed, instead of `exit 0`.

**Fix:** Missing local tooling is not a Claude concern. Replace:

```bash
ruff format "$file_path"
```

with:

```bash
if command -v ruff >/dev/null 2>&1; then
  ruff format "$file_path" || true
fi
exit 0
```

---

## Symptom: Settings.json is 1000 lines and nobody knows what's in it

**Diagnosis:** Settings accrete. Permissions piled on over time, no one reviews.

**Fix:** Strip to `settings/examples/full-featured.json` as a baseline. Re-add custom entries only when a real workflow demands them. Keep a comment (`//foo`) above non-obvious entries explaining WHY.

---

## Symptom: ADRs are all "Proposed" forever

**Diagnosis:** No process moves ADRs from Proposed → Accepted.

**Fix:** Make ADR acceptance part of PR merge: the PR that lands the change is also the PR that marks the ADR as Accepted. If the ADR's decision isn't landing, either the ADR is wrong (reject it) or the decision isn't being made (push for resolution).

---

## Symptom: Validation scripts exist but nobody runs them

**Diagnosis:** Manual invocation is forgotten. No automation.

**Fix:** Wire into:

- A `Stop` hook: `bash validation/validate-all.sh` runs before completion.
- A pre-commit hook: `validate-skill.sh` on any changed `.claude/skills/**/SKILL.md`.
- CI: a workflow step that runs the full validation suite on PR.

---

## Symptom: The project's `.claude/` works fine, but new contributors are confused

**Diagnosis:** `CLAUDE.md` is tuned for the agent, not for humans; no `guides/` equivalent exists in the project.

**Fix:** Add a human-oriented `.claude/README.md` briefly explaining the layout. Or add a "For humans" section in `CLAUDE.md` linking to the main entry points.

---

## The meta anti-pattern

**Symptom:** The `.claude/` setup has grown to resemble a second codebase that needs its own maintenance.

**Diagnosis:** You've crossed from "lightweight context for the agent" to "second product." Usually caused by adding every skill/agent/hook that came to mind rather than the ones earning their keep.

**Fix:** Do an audit sweep. Delete anything that fails the "would we notice if this was gone" test. Fewer, higher-quality artifacts beat more, mediocre ones.
