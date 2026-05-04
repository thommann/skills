# skills

A curated library of portable Claude Code artifacts: skills, agents, hooks, MCP launchers, output styles, settings, statuslines, CLAUDE.md templates, and the validators that gate them.

## Install

Two distribution channels with different reach.

### Skills only — works with any agent (Claude Code, Cursor, Codex, Gemini CLI, …)

```bash
# Install all 18 skills
npx skills add thommann/skills

# Preview the catalog
npx skills add thommann/skills --list

# Install only what you want
npx skills add thommann/skills --skill create-pr --skill review-diff
```

Skills install per-project to `.claude/skills/` (or your agent's equivalent — see [`vercel-labs/skills`](https://github.com/vercel-labs/skills) for the supported-agents matrix). Add `-g` for a global install, `-y` for non-interactive.

### Skills + agents — Claude Code plugin

`npx skills` only knows about skills. To also install the 5 read-only subagents, use Claude Code's plugin marketplace. From inside Claude Code:

```
/plugin marketplace add thommann/skills
/plugin install thommann-skills
```

The plugin clones the whole repo into `~/.claude/plugins/thommann-skills/`. Components declared in `.claude-plugin/plugin.json` (skills, agents) are wired into Claude Code's runtime. The other artifacts in this repo — `hooks/examples/`, `mcp/`, `output-styles/`, `settings/`, `statusline/` — are reference templates rather than installable plugin components; they sit in the cloned cache for you to copy into your own project. `validation/`, `principles/`, `decisions/`, and `guides/` are documentation, also inert in the cache.

## What's here

```
.
├── principles/         # Seven normative docs every artifact cites
├── skills/             # 18 portable skills: meta, workflow, documentation, planning
├── agents/             # Read-only subagent examples
├── hooks/              # PreToolUse / PostToolUse / Stop hook examples
├── output-styles/      # Voice/formatting presets
├── settings/           # settings.json skeletons (minimal, full, locked-down)
├── statusline/         # Portable statusline.sh
├── mcp/                # mcp.json config + per-server launchers
├── guides/             # Longer-form how-tos and project-specific starter kits
│   ├── scaffolding-examples/   # "add an X" patterns (adapt per codebase)
│   ├── debugging-examples/     # debug-X patterns (adapt per codebase)
│   └── reference-examples/     # domain-knowledge skill patterns
├── decisions/          # ADRs documenting this library's own design
├── validation/         # Maintainer harness; per-skill validators live in skills/meta/*/lib/
└── .claude-plugin/     # plugin.json — Claude Code marketplace manifest
```

## The seven principles

1. **[Evidence over opinion](principles/01-evidence-based.md).** Every line cites a real file, command, or convention.
2. **[Dense, not brief](principles/02-dense-not-brief.md).** Load-bearing beats short.
3. **[Don't duplicate tooling](principles/03-no-duplication-with-tooling.md).** If a linter enforces a rule, don't restate it.
4. **[Point, don't paste](principles/04-file-references-over-snippets.md).** Reference paths, not snippets that go stale.
5. **[Alternatives, not just prohibitions](principles/05-alternatives-not-prohibitions.md).** "Use Y instead of X" beats "Don't use X."
6. **[The portability test](principles/06-portability-test.md).** Works in any project after trivial adaptation.
7. **[Safe-merge by default](principles/07-safe-merge.md).** Copy instructions never overwrite existing files.

## Validate

```bash
bash validation/validate-all.sh
```

Runs every per-skill validator (`skills/meta/create-or-audit-*/lib/validate.sh`) against every artifact in this repo and confirms `npx skills` discovers all 18 skills.

## Origin

Philosophy and validation rules were harvested from [ultrainit.sh](https://github.com/joelbarmettlerUZH/ultrainit.sh) by Joel Barmettler.
