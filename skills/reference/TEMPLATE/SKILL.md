---
name: {{SUBSYSTEM_NAME}}-reference
description: >
  Reference for how this project uses {{SUBSYSTEM_NAME}} — the contract, the canonical example,
  extension points, and common pitfalls. Use when user says 'how does our {{SUBSYSTEM_NAME}}
  work', '{{SUBSYSTEM_NAME}} pattern', 'how to use {{SUBSYSTEM_NAME}} here', or 'where's the
  {{SUBSYSTEM_NAME}} contract'. Do NOT use for debugging {{SUBSYSTEM_NAME}} issues
  (use debug-{{SUBSYSTEM_NAME}}) or adding new instances (use the scaffolding skill).
allowed-tools: Read, Grep, Glob
---

# {{SUBSYSTEM_NAME}} — reference

<!--
  ADAPT TO YOUR PROJECT:
    {{SUBSYSTEM_NAME}}  — the subsystem (auth, events, state, config, ...)
    {{CONTRACT_FILE}}   — the file defining the interface/contract
    {{EXAMPLE_FILES}}   — 1–2 canonical usage sites
    {{EXTENSION_POINT}} — where to add a new variant (factory, registry, subclass)
    {{ADR_LINKS}}       — relevant ADRs explaining the why
  Remove this comment after adapting.
-->

## What this reference covers

{{SUBSYSTEM_NAME}} in this project: the contract, how to use it, how to extend it.

**NOT covered here:**

- Debugging a specific {{SUBSYSTEM_NAME}} problem → see `debug-{{SUBSYSTEM_NAME}}` skill.
- Adding a new {{SUBSYSTEM_NAME}} instance → see scaffolding skill.
- The framework-level behavior — consult the framework's docs, not this skill.

## Minimum-viable example

The smallest complete usage in the codebase:

- **Canonical example:** `{{EXAMPLE_FILES}}` — read this first.
- **Minimal setup:** {{MINIMAL_SETUP_STEPS}} (e.g., "import X, call `init()`, pass to the wrapper").

## The contract

- **Contract file:** `{{CONTRACT_FILE}}` — the interface/schema/base class.
- **Required:** {{REQUIRED_FIELDS_OR_METHODS}}
- **Optional with defaults:** {{OPTIONAL_FIELDS}}
- **Lifecycle:** {{LIFECYCLE_DESCRIPTION}} — e.g., "initialized once at startup; request-scoped state lives in {{REQUEST_STATE_FILE}}."
- **Invariants:** {{INVARIANTS_LIST}} — conditions that must always hold.

## Extension points

To add a new variant of the {{SUBSYSTEM_NAME}} pattern:

1. Define the new variant at `{{EXTENSION_POINT}}` following `{{EXAMPLE_FILES}}`.
2. Register it at `{{REGISTRATION_POINT}}` (if the project uses explicit registration).
3. See the scaffolding skill `skills/scaffolding/add-{{SUBSYSTEM_NAME}}` for a mechanical walkthrough.

## Common pitfalls

| Pitfall | Correction |
|---|---|
| {{PITFALL_1}} (e.g., "forgetting to register the new variant") | {{CORRECTION_1}} — step 2 of the extension-point workflow. |
| {{PITFALL_2}} (e.g., "assuming request-scoped state when it's app-scoped") | {{CORRECTION_2}} — read `{{REQUEST_STATE_FILE}}` for the lifecycle. |
| {{PITFALL_3}} | {{CORRECTION_3}} |

## Source of truth

When this reference goes stale, verify against:

- **Contract:** `{{CONTRACT_FILE}}` — the code defining the interface.
- **Canonical implementation:** `{{EXAMPLE_FILES}}` — reference usages that always reflect the current behavior.
- **Decisions:** {{ADR_LINKS}} — why the subsystem is shaped this way.

## Verify

This is a reference skill — verification is that the file refs still exist:

```bash
for p in {{CONTRACT_FILE}} {{EXAMPLE_FILES}} {{REGISTRATION_POINT}}; do
  [ -e "$p" ] || echo "STALE: $p"
done
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Referring to this skill for framework behavior | The skill documents THIS project's usage. For framework mechanics, read the framework's docs. |
| Skill content that contradicts `{{CONTRACT_FILE}}` | Update the skill — the contract file wins (principle 01). |
| Growing this skill to 400+ lines with every edge case | Split by concern. A reference that can't be skimmed isn't reference material. |
| Referencing paths that no longer exist | Run the Verify step. Stale refs undermine trust in the whole skill. |
