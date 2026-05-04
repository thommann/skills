# Writing a good skill

Companion to [`../skills/meta/create-or-audit-skill/SKILL.md`](../skills/meta/create-or-audit-skill/SKILL.md). Goes deeper on how to make a skill pull its weight.

## The portability test — but backwards

The library's principle says portable artifacts must PASS the test (work in any project). For a skill you're writing for YOUR project, invert it: the skill must **FAIL** the test. If someone could drop it into an unrelated project and it would work, it's too generic to belong in your `.claude/`.

Concretely:

- Names ≥3 real files from your project.
- Names real commands (project's test runner, lint, build).
- References project-specific conventions (naming, layering, registration points).

Generic skills waste context without adding value.

## The description is load-bearing

The `description` field decides whether Claude invokes the skill. A vague description is either never invoked (misses its purpose) or invoked for wrong things (noise).

Good descriptions include:

- **≥3 trigger phrases** — the exact words engineers say. Not your taxonomy, their taxonomy.
- **≥1 "Do NOT use for"** clause pointing at a sibling skill.
- **No angle brackets** — breaks YAML.
- **Under 1024 characters.**

Trigger phrases to favor:

- "Use when user says '<phrase>', '<phrase>', '<phrase>'."
- "Invoke when the user asks about <situation>."
- "Trigger on: <symptom pattern>."

Phrases to avoid:

- Abstract categorization ("when the workflow involves..."). The router matches literal words.
- "This skill helps with..." — doesn't match trigger queries.

## Instruction discipline

Every step in the body must:

1. **Reference a real file, command, or pattern** from the project. If you write "create the file," name the directory and the filename convention.
2. **Be actionable.** "Consider implementing" is not a step. "Create `src/foo/bar.ts` with the structure from `src/foo/quux.ts`" is.
3. **Include the WHY** when the step isn't self-evident. "Register in `src/router.ts` — otherwise the handler never reaches the framework."
4. **Not duplicate a linter rule** (principle 03). If `eslint` catches it, point at the config, don't restate.

## The verify section is non-negotiable

A skill that ends with "make sure it works" has no verification. Real verification:

- **A test command** — `pnpm test <test-file>`.
- **A file-existence check** — `test -f <path>`.
- **A lint check** — `ruff check`, `tsc --noEmit`.
- **A runtime probe** — `curl http://localhost:port/new-route`.

If the skill scaffolds multiple artifacts, each should have an independent verify — the skill succeeded when all of them pass.

## Common Mistakes section — write real ones

Mistakes should be things you've actually seen happen. Each entry:

- Names the specific mistake.
- Names the specific correction (with file paths if relevant).
- Is NOT a motherhood statement ("make sure to follow the pattern" — what pattern? which file?).

Two to four entries. Ten is too many — if you have ten, several aren't mistakes, they're nice-to-haves.

## Size discipline

| Lines | Verdict |
|---|---|
| Under 150 | Tight — good if complete |
| 150–400 | Typical — normal working skill |
| 400–600 | Getting heavy — consider splitting by mode or concern |
| Over 600 | Too big — split |

Reasons a skill grows too big:

- It does two things. Split into two skills.
- It has a huge `Common Mistakes` table. Move non-essentials to the related-guides section.
- It embeds snippets that should be file references (principle 04).

## Pre-commit checklist

Before declaring a skill ready:

- [ ] `bash validation/validate-skill.sh <path>` exits 0.
- [ ] Description has ≥3 trigger phrases and ≥1 "Do NOT use for."
- [ ] Body has ≥3 backticked file references.
- [ ] Has `## Before You Start`, numbered steps, `## Verify`, `## Common Mistakes`.
- [ ] No banned generic phrases in prose (`validation/lib/generic-phrases.txt`).
- [ ] Every prohibition has a matching alternative nearby (principle 05).
- [ ] Imagined "trigger test": if a user said "<trigger phrase from description>", would this skill be the right answer?
- [ ] Imagined "negative test": if a user said something adjacent, would this skill wrongly trigger?

## After shipping

Skills decay. Re-validate quarterly:

- `find .claude/skills -name 'SKILL.md' | xargs -n1 bash validation/validate-skill.sh`
- Grep the stale-path scan from `create-or-audit-skill` Gate 4.
- Ask "does this still match how we actually work?" — if the project's procedure changed, update the skill.

The `reflect` skill helps identify which skills caused friction in a session; use its output as a prompt to audit specific entries.

## Anti-patterns

- **The novel.** A 1500-line skill that tries to cover every edge case. Split.
- **The tutorial.** Embedded 50-line code snippets. Replace with file references (principle 04).
- **The generic.** "Follow best practices." Deleted on sight.
- **The silent.** A skill without `## Verify`. Can't know if it worked.
- **The orphan.** No "Do NOT use for" — triggers on everything.
- **The imposter.** A skill that's really a hook (deterministic, fires every time) or an agent (read-only analysis). Put it in the right bucket.
