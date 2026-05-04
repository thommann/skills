# Adopting in a new project

Safe-merge workflow for copying artifacts into a project with an existing `.claude/` setup. Principle 07 — no destructive overwrites.

## Inventory what the project already has

```bash
cd ~/myproject
find .claude -type f 2>/dev/null | sort
```

Take note of:

- Existing `CLAUDE.md` files at root and in subdirectories.
- Existing skills, agents, hooks.
- Existing `settings.json` contents.

## Copy artifacts non-destructively

### Hooks

```bash
LIB=~/.local/share/ai-augmented-se
for h in "$LIB/hooks/examples/"*.sh; do
  name=$(basename "$h")
  if [[ -e ".claude/hooks/$name" ]]; then
    echo "skip: $name (already exists)"
  else
    cp "$h" ".claude/hooks/$name"
    chmod +x ".claude/hooks/$name"
    echo "copied: $name"
  fi
done
```

### Skills

```bash
for d in "$LIB/skills/meta/"*/ "$LIB/skills/workflow/"*/ "$LIB/skills/documentation/"*/; do
  name=$(basename "$d")
  if [[ -e ".claude/skills/$name" ]]; then
    echo "skip: $name (already exists)"
  else
    cp -r "$d" ".claude/skills/"
    echo "copied: $name"
  fi
done
```

`cp -r` + the `-e` guard preserves existing work. The library's skills land only where there's no collision.

### Agents

```bash
for a in "$LIB/agents/examples/"*.md; do
  name=$(basename "$a")
  if [[ -e ".claude/agents/$name" ]]; then
    echo "skip: $name"
  else
    cp "$a" ".claude/agents/$name"
  fi
done
```

## Merge `settings.json`

Settings must merge, not replace. Use jq deep-merge:

```bash
if [[ ! -f .claude/settings.json ]]; then
  cp "$LIB/settings/examples/full-featured.json" .claude/settings.json
else
  jq -s '.[0] * .[1]' \
     .claude/settings.json \
     "$LIB/settings/examples/full-featured.json" \
     > /tmp/merged-settings.json
  diff .claude/settings.json /tmp/merged-settings.json | head -60
  echo ""
  echo "Review /tmp/merged-settings.json. If it's right, move it into place:"
  echo "  mv /tmp/merged-settings.json .claude/settings.json"
fi
```

`jq -s '.[0] * .[1]'` deep-merges: the second file's values win on conflicts, but arrays are replaced (not concatenated). If your project's existing `hooks.*` arrays should keep their entries AND gain the library's, you need to merge arrays manually — see the "Array-merge conflict" section below.

## Merge `CLAUDE.md`

`CLAUDE.md` doesn't merge mechanically. If the project has one:

- Open both files side by side.
- Import sections from the template that don't exist in the project's version (usually **Security-Critical Areas**, **Domain Terminology**).
- Keep the project's version of sections it already has.
- Do NOT blindly copy — the template has placeholder headings; only sections filled with real content belong.

After merging, run:

```bash
bash "$LIB/validation/validate-claude-md.sh" CLAUDE.md
```

## Array-merge conflict (hooks wiring)

If both your existing `settings.json` and the library's example wire hooks to the same event (`PostToolUse`, `PreToolUse`), jq's `*` operator replaces one array with the other. You lose the non-library hooks.

Manual fix:

1. Open both files.
2. In the merged result, for each `hooks.<Event>[].hooks[]` array, union the entries from both sources.
3. Keep matchers specific — `matcher: "Write|Edit"` is fine; a wildcard matcher overrides everything.

Example combined PostToolUse:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/your-existing-hook.sh" },
          { "type": "command", "command": ".claude/hooks/auto-format-python.sh" },
          { "type": "command", "command": ".claude/hooks/auto-format-markdown.sh" }
        ]
      }
    ]
  }
}
```

## Validate after adoption

```bash
LIB=~/.local/share/ai-augmented-se
for f in .claude/skills/*/SKILL.md; do
  bash "$LIB/validation/validate-skill.sh" "$f"
done
for f in .claude/agents/*.md; do
  bash "$LIB/validation/validate-agent.sh" "$f"
done
for f in .claude/hooks/*.sh; do
  bash "$LIB/validation/validate-hook.sh" "$f"
done
bash "$LIB/validation/validate-claude-md.sh" CLAUDE.md
```

Scaffolding / debugging / reference skills that still contain `{{PLACEHOLDERS}}` will fail — that's expected. Adapt them to your project (see each example's "Adapt to your project" block) before validating.

## Git hygiene

```bash
# Track the adoption
git add .claude/
git add CLAUDE.md
git status

# Commit with a message that identifies where artifacts came from
git commit -m "chore: adopt ai-augmented-se artifacts (review, reflect, format hooks)"
```

## Roll back

If an adopted artifact causes friction:

```bash
# Remove the file
rm .claude/skills/<name>/SKILL.md
rmdir .claude/skills/<name>

# Or revert the whole adoption commit
git revert <commit-sha>
```

No library artifact is "infectious" — every one is a plain file you can delete.
