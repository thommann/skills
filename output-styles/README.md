# Output styles

Output styles override Claude Code's default response voice and formatting. Useful for specific audiences (non-technical stakeholders, marketing drafts, executive summaries) or specific modes (deep architectural explanations).

Active style is set via `/output-style <name>` or configured in `settings.json`.

## Contents

- [`examples/architect-please-explain.md`](examples/architect-please-explain.md) — verbose, diagram-heavy, "explain like to a new architect joining the team"
- [`examples/business.md`](examples/business.md) — short, outcome-focused, minimal jargon
- [`examples/marketing.md`](examples/marketing.md) — user-benefit phrasing; keeps feature descriptions positive and skimmable

## Schema

```yaml
---
name: style-name
description: When to use this style
---
```

Body: free-form instructions to Claude that override default response conventions. Keep it focused — styles compound with the rest of the prompt, and a verbose style eats context.

## Validation

Output styles have no dedicated validator — they're prose instructions. Review for:

- The generic-phrase ban (same as everywhere else)
- File references are fine but rarely needed (styles are about voice, not content)
- Clear "when to use / when not to use" in description
