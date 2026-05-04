# Quality rubric

The validators in `validation/` enforce mechanical rules. This rubric documents those same rules plus the non-mechanical ones in prose — useful for human review.

## Skill

### Hard requirements (validator enforces)

- [ ] Folder is kebab-case, file is exactly `SKILL.md`.
- [ ] Frontmatter has opening and closing `---`.
- [ ] `name` field present, matches folder, is kebab-case.
- [ ] `description` field present, under 1024 chars, no angle brackets.
- [ ] Body has ≥3 backticked file path references.

### Soft requirements (validator warns)

- [ ] Description has ≥3 trigger phrases ("use when", "invoke when", "user says").
- [ ] Description has ≥1 "Do NOT use for" clause.
- [ ] Has `## Verify` section with concrete commands.
- [ ] Has `## Common Mistakes` with 2–4 real pitfalls.
- [ ] Under 600 lines (over 600 warns — consider splitting).
- [ ] Fewer than 3 generic-phrase matches (see `validation/lib/generic-phrases.txt`).

### Human-review requirements

- [ ] **Multi-step.** Single-step procedures belong in `CLAUDE.md`.
- [ ] **Project-specific.** Fails the portability test — wouldn't work unchanged in another repo.
- [ ] **Actionable.** Every step is "do X at path Y", not "consider implementing Z".
- [ ] **Non-duplicative.** Not duplicated by another skill or a `CLAUDE.md` entry.
- [ ] **Not a hook in disguise.** If the rule is deterministic and always applies, it's a hook.
- [ ] **Not an agent in disguise.** If the work is read-only analysis producing a report, it's an agent.

## Agent

### Hard requirements (validator enforces)

- [ ] Filename is lowercase-with-hyphens, ends in `.md`.
- [ ] Frontmatter opens and closes with `---`.
- [ ] `name` matches filename, description under 1024 chars, no angle brackets.
- [ ] If description mentions review/analyze/audit/scan/check AND NOT fix/implement/create/write/modify/update, `tools` MUST NOT include `Write` or `Edit`.

### Soft requirements (validator warns)

- [ ] Body word count ≥ 20 — agents need self-contained context.
- [ ] Body has ≥3 backticked file path references.
- [ ] Description has ≥3 trigger phrases and ≥1 negative-scope clause.
- [ ] `model` field is one of `sonnet | opus | haiku | inherit`.

### Human-review requirements

- [ ] **Read-only.** No side effects — no commits, no API calls, no file writes.
- [ ] **Bounded.** The task has a clear start and end; the output is a structured report.
- [ ] **Least-privileged tools.** Only the tools the agent demonstrably uses.
- [ ] **Orientation section.** Names ≥1 file the agent should read first.
- [ ] **Output format skeleton.** A markdown template the caller can rely on.
- [ ] **Explicit non-goals.** A "What You Do NOT Do" section with redirects.

## Hook

### Hard requirements (validator enforces)

- [ ] `#!/usr/bin/env bash` on line 1.
- [ ] `set -euo pipefail` near the top.
- [ ] Reads JSON from stdin (has `cat`, `read`, `stdin`, `jq`, or `/dev/stdin`).
- [ ] If uses `exit 2`, also writes to stderr.

### Soft requirements (validator warns)

- [ ] Has an explicit `exit 0` short-circuit for irrelevant input.
- [ ] No obvious network calls (`curl`, `wget`).

### Human-review requirements

- [ ] **Fast.** Runs in under a second on typical input.
- [ ] **Silent on irrelevant.** Wrong tool or wrong file type → `exit 0` with no output.
- [ ] **Actionable when blocking.** `exit 2` has a clear stderr message explaining the block and the alternative.
- [ ] **Tool-presence checked.** External tools gated by `command -v` — missing tools → `exit 0`.
- [ ] **Idempotent.** Running twice with the same input has the same effect.
- [ ] **Wired in `settings.json`.** File existing isn't enough.

## CLAUDE.md

### Hard requirements (validator enforces)

- [ ] At least 30 lines (warning under 50, error under 30).
- [ ] No banned generic phrases in bare prose (backticks/quotes strip mentions).
- [ ] At least one code block or pipe table.
- [ ] Every prohibition has a matching alternative nearby.

### Human-review requirements

- [ ] **Dense.** Every line carries information the reader can't derive from the code.
- [ ] **Evidence-based.** Every claim cites a file, a command, or a convention.
- [ ] **Doesn't duplicate tooling.** If the linter enforces it, don't restate.
- [ ] **Uses file references, not embedded code.** Snippets rot; references don't.
- [ ] **Has a `## Things to Know`.** The single most valuable section — hidden invariants.
- [ ] **Subdirectory CLAUDE.md where criteria hit.** Different framework / 3+ divergent patterns / own build commands / 10+ files with distinct conventions.

## ADR (Architecture Decision Record)

### Required sections

- [ ] **Context** — the problem or situation, anchored in specifics.
- [ ] **Decision Drivers** — verifiable forces (constraints, measurable requirements).
- [ ] **Considered Options** — at least two. A decision without alternatives isn't an ADR.
- [ ] **Decision** — what was chosen.
- [ ] **Consequences** — positive AND trade-offs. Every decision has trade-offs.

### Human-review requirements

- [ ] **Context is specific.** "We need to scale" → replace with measurable latency/cost numbers.
- [ ] **Drivers are verifiable.** "Ease of use" → replace with "junior engineers onboard in a week."
- [ ] **Decision names the trade-off explicitly.** "We chose X accepting Y in exchange for Z."
- [ ] **Consequences are observable.** "Developer velocity improves" → replace with "CI runs in 6 min instead of 18."
- [ ] **References related ADRs** if any are superseded or complemented.

## Full library audit

Run periodically:

```bash
cd .claude/
LIB=~/.local/share/ai-augmented-se

# Validation (mechanical)
for f in skills/*/SKILL.md; do bash "$LIB/validation/validate-skill.sh" "$f"; done
for f in agents/*.md;       do bash "$LIB/validation/validate-agent.sh" "$f"; done
for f in hooks/*.sh;        do bash "$LIB/validation/validate-hook.sh"  "$f"; done
bash "$LIB/validation/validate-claude-md.sh" ../CLAUDE.md

# Stale reference scan (human review)
find .claude -type f -name '*.md' -o -name '*.sh' | xargs grep -l "TODO\|FIXME" 2>/dev/null

# Skill count (check against cumulative token cost)
find .claude/skills -name 'SKILL.md' | wc -l
```

If any validator fails, block the commit. If the skill count is above 30, audit for overlap.
