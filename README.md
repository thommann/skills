# skills

A curated library of portable Claude Code artifacts: skills, agents, hooks, MCP launchers, output styles, settings, statuslines, CLAUDE.md templates, and the validators that gate them.

## Install

```bash
npx skills add thommann/skills
```

## What's here

```
.
├── principles/     # Seven normative docs every artifact cites
├── skills/         # meta, workflow, documentation, planning, scaffolding, debugging, reference
├── agents/         # Read-only subagent templates
├── hooks/          # PreToolUse / PostToolUse / Stop hook templates
├── output-styles/  # Voice/formatting presets
├── settings/       # settings.json skeletons (minimal, full, locked-down)
├── statusline/     # Portable statusline.sh
├── mcp/            # mcp.json config + per-server launchers
├── claude-md/      # CLAUDE.md templates and worked examples
├── guides/         # Longer-form how-tos
├── decisions/      # ADRs documenting this library's own design
└── validation/     # Shell scripts that enforce the seven principles
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

## Origin

Philosophy and validation rules were harvested from [ultrainit.sh](https://github.com/joelbarmettlerUZH/ultrainit.sh) by Joel Barmettler.
