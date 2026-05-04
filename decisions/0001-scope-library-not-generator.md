# 0001 — Scope this repo as a static library, not a generator

- **Status:** Accepted
- **Date:** 2026-04-20

## Context

Two prior art sources informed the design:

- [ultrainit.sh](https://github.com/joelbarmettlerUZH/ultrainit.sh) — a generator that analyzes a codebase and emits a full `.claude/` setup via multiple Claude-API passes.
- A prior production `.claude/` setup — hand-curated, with ~44 skills, 7 agents, 8 hooks, output-styles, and a statusline.

We needed to decide: does this new repository continue in the generator direction (ultrainit-style), or is it something else?

The requested scope was "a library/knowledge base of templates and best practices" — a static collection users copy from. Explicitly: "The result should not be a new ultrainit.sh."

## Decision Drivers

- **Predictability** — a static library produces the same artifacts every time; a generator's output depends on LLM determinism, prompt versions, and budget.
- **Reviewability** — humans can review a ~120-file library with diffs; reviewing a generator's output requires running the generator first.
- **Maintenance cost** — generators require prompt tuning, schema validation of LLM output, orchestration, and recovery. A library requires only Markdown editing and a handful of shell scripts.
- **Portability of learnings** — a library's philosophy (principles, validators) transfers to projects without the library. A generator's philosophy lives inside its pipeline.
- **User autonomy** — library users pick artifacts and adapt them; generator users accept or reject the bulk output.

## Considered Options

1. **Generator (ultrainit-shaped)** — multi-pass LLM pipeline producing `.claude/` for any target repo.
2. **Static library** — hand-maintained collection of templates, examples, validators, and guides.
3. **Hybrid** — static library plus a thin generator layer that instantiates templates with find-and-replace (no LLM).

## Decision

We chose **Option 2: static library**.

The repository is a knowledge base — principles, annotated templates, ready-to-copy skills/agents/hooks, MCP launchers, and validation scripts. It ships no pipeline, no cost tracking, no cache directory, no state files.

We accept that users must do manual adaptation in exchange for predictable, reviewable, low-maintenance artifacts.

## Consequences

### Positive

- Every artifact is reviewed diff-by-diff.
- Zero runtime LLM dependency — users can browse, copy, and adopt offline.
- Validators can be committed to the repo and run as part of CI.
- The library evolves as a standard Markdown repository.

### Trade-offs

- Users do more work up front than with a generator — picking, copying, and adapting artifacts.
- The library doesn't adapt itself to a specific codebase; project-specific skills still need writing.
- The library cannot discover a codebase's conventions — that remains a human task.
- The `scaffolding/`, `debugging/`, `reference/` categories ship as templates users must adapt — they are NOT working skills out of the box.

## References

- [`principles/06-portability-test.md`](../principles/06-portability-test.md) — the boundary between what belongs here (portable) vs what doesn't (project-specific).
- Subsequent ADRs refine specific areas: see [`0002`](0002-hybrid-taxonomy-seven-skill-categories.md), [`0003`](0003-documentation-skills-first-class.md).
