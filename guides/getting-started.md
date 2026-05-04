# Getting started

Adopt this library in your project in ~15 minutes.

## 1. Clone the library

```bash
git clone https://github.com/thommann/skills ~/.local/share/skills
```

## 2. Pick artifacts

Start small — add three hooks, two skills, and a `CLAUDE.md` template. You can layer more later.

```bash
cd ~/myproject
mkdir -p .claude/hooks .claude/skills
```

### Hooks (3 recommended to start)

```bash
LIB=~/.local/share/skills

cp "$LIB/hooks/examples/protect-sensitive-files.sh" .claude/hooks/
cp "$LIB/hooks/examples/auto-format-markdown.sh"    .claude/hooks/
cp "$LIB/hooks/examples/stop-lint-check.sh"         .claude/hooks/
chmod +x .claude/hooks/*.sh
```

### Skills (pick from workflow + meta)

```bash
cp -rn "$LIB/skills/workflow/review-diff"             .claude/skills/
cp -rn "$LIB/skills/workflow/create-pr"               .claude/skills/
cp -rn "$LIB/skills/meta/create-or-audit-claude-md"   .claude/skills/
cp -rn "$LIB/skills/meta/reflect"                     .claude/skills/
```

`cp -rn` is non-destructive: existing skills are NOT overwritten (principle 07 — safe-merge).

### CLAUDE.md

```bash
[ -f CLAUDE.md ] || cp "$LIB/skills/meta/create-or-audit-claude-md/templates/CLAUDE.md" CLAUDE.md
# Now edit CLAUDE.md — fill in Quick Reference, Architecture, Things to Know.
```

### settings.json

```bash
mkdir -p .claude
if [ ! -f .claude/settings.json ]; then
  cp "$LIB/settings/examples/full-featured.json" .claude/settings.json
else
  jq -s '.[0] * .[1]' .claude/settings.json "$LIB/settings/examples/full-featured.json" > /tmp/merged.json
  echo "Review /tmp/merged.json, then replace .claude/settings.json manually."
fi
```

## 3. Validate

```bash
LIB=~/.local/share/skills
bash "$LIB/skills/meta/create-or-audit-claude-md/lib/validate.sh" CLAUDE.md
for f in .claude/skills/*/SKILL.md; do bash "$LIB/skills/meta/create-or-audit-skill/lib/validate.sh" "$f"; done
for f in .claude/hooks/*.sh;        do bash "$LIB/skills/meta/create-or-audit-hook/lib/validate.sh"  "$f"; done
```

Fix any errors before using. The `CLAUDE.md` validator is the most opinionated — you may need to remove generic phrases or add a prohibition's alternative.

## 4. Try it

Open the project in Claude Code. Test:

- **Hooks:** edit a file; the formatter hook runs (check with a deliberately misformatted line).
- **Skills:** ask "review my diff" — Claude should invoke `review-diff` and produce a severity-organized report.
- **CLAUDE.md:** confirm it loads at session start (the agent knows your Quick Reference commands).

## 5. Extend

Add more as you find friction:

- A scaffolding skill (start with `guides/scaffolding-examples/` and adapt to your project).
- An agent (`agents/examples/security-reviewer.md`) for bounded review tasks.
- MCP servers (`mcp/mcp.json.examples/` or `mcp/launchers/`).
- A reference skill encoding a project-specific pattern (`guides/reference-examples/`).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `validate-skill.sh` says "fewer than 3 references" after adaptation | Add backticked paths from your real project — `src/api/routes.ts`, etc. |
| Hook exists but doesn't run | Wire it in `.claude/settings.json` under `hooks.<Event>[].hooks[]`. See `settings/examples/full-featured.json`. |
| `CLAUDE.md` validator errors on a prohibition | Pair "don't use X" with "use Y instead" in the same section. Principle 05. |
| Skill description failing YAML parse | Remove angle brackets (`<` / `>`). Validator errors on them. |

## Next reading

- [`when-to-create-what.md`](when-to-create-what.md) — decision tree for skill vs agent vs hook vs CLAUDE.md.
- [`adopting-in-a-new-project.md`](adopting-in-a-new-project.md) — safe-merge workflow in detail.
- [`anti-patterns.md`](anti-patterns.md) — common failure modes in `.claude/` setups.
