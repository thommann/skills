# 07 — Safe-merge by default

> Copy instructions never overwrite existing user files; configuration merges use deep-merge.

## Why

An adopter already has `.claude/` content — their own skills, hooks, custom settings. Instructions that blindly copy over that state destroy hand-written work. A library that overwrites silently will be abandoned after the first data loss.

Safe-merge means the adopter's existing state wins by default. The library's artifacts either (a) land in a new location alongside the existing ones, or (b) merge additively into configuration, never replacing.

## Rule

Three concrete behaviors:

1. **File-level copies are additive.** Instructions in `guides/adopting-in-a-new-project.md` and in each category's `README.md` always say *"copy into your `.claude/` — skip if the filename already exists."* No `cp -f`. If a filename collides, the adopter renames or merges manually.

2. **Configuration merges use deep-merge.** For `settings.json` and `mcp.json`, the merge recipe is:
   ```bash
   jq -s '.[0] * .[1]' existing.json additions.json > merged.json
   ```
   The `*` operator in jq is a deep merge: object keys union, later values win at leaf conflicts. The adopter reviews conflicts manually.

3. **Skills/agents/hooks live in their own namespaced filenames.** If this library's skill is named `review-diff`, it lands as `skills/review-diff/SKILL.md`. An existing `review-diff` in the adopter's repo is NOT overwritten — they rename one or the other.

## How this manifests in the library

- `guides/adopting-in-a-new-project.md` is the canonical merge recipe.
- `validation/` scripts do not modify files; they only report.
- No file in this library invokes `cp -f`, `rsync --delete`, or `rm -rf`.
- Skills that manipulate target-project files (e.g., a hypothetical `install-hook` skill, if it existed) would require explicit user confirmation before overwriting.

## How validators check it

No automated validator catches this — it's procedural. The safeguards are:

- Every `README.md` in this repo that describes copying artifacts uses "copy — skip if exists" language.
- `guides/adopting-in-a-new-project.md` is mandatory reading before any large adoption.
- Human review during PR: any instruction containing `cp -f`, `mv`, or overwriting redirection (`>`) is flagged.

## Good vs bad

**Bad (destructive):**
```markdown
## Install

```bash
cp -r skills/ ~/myproject/.claude/skills/
cp settings.json.template ~/myproject/.claude/settings.json
```
```

The second line destroys existing settings. The first `cp -r` will silently overwrite any same-named skill.

**Good (safe):**
```markdown
## Install

1. Copy the skill folder, but DO NOT overwrite:
   ```bash
   for d in skills/workflow/*/; do
     name=$(basename "$d")
     if [[ -e ~/myproject/.claude/skills/$name ]]; then
       echo "skip: $name (already exists)"
     else
       cp -r "$d" ~/myproject/.claude/skills/
     fi
   done
   ```

2. Merge settings instead of overwriting:
   ```bash
   jq -s '.[0] * .[1]' \
     ~/myproject/.claude/settings.json \
     settings/examples/full-featured.json \
     > /tmp/merged.json
   # Review /tmp/merged.json, then move it into place.
   ```
```

The good version inspects before copying, deep-merges configs, and asks the adopter to review.
