# 04 — Point, don't paste

> Reference real files rather than embedding code that goes stale. `` `src/middleware/auth.ts` `` beats a 20-line code block.

## Why

Embedded code snippets become wrong the moment anyone edits the underlying file. The skill or CLAUDE.md is then actively teaching an outdated pattern, and because the snippet looks authoritative, the agent will trust it over the real code. A file reference forces the agent to read the current state — which is always correct by definition.

This principle is the reason ultrainit's validators demand ≥3 file references per skill.

## Rule

Prefer, in order:

1. **A file reference** with a line number if the relevant part is small: `` `src/api/routes.ts:42` ``
2. **A file reference** to the whole file: `` `src/api/routes.ts` ``
3. **A command** that retrieves the information: `pnpm tsc --showConfig`
4. **A minimal snippet** (last resort) — only when the pattern is so small that a reference would cost more than the snippet. Keep snippets under 5 lines. Flag them with "(exemplar — verify against the file)" so future readers know to re-check.

**Never** embed a snippet longer than ~10 lines in a skill or CLAUDE.md. At that point the skill has become a tutorial, which rots the moment the file changes.

## How validators check it

- `validate-skill.sh` counts backtick-wrapped path-like strings. ≥3 is required.
- `validate-skill.sh` warns on skills over 600 lines (often a symptom of embedded tutorials).
- Human review: read any embedded code block in a skill and ask "does the referenced file still look like this?" — if no, the skill has rotted.

## Good vs bad

**Bad:**
```markdown
## How to add a new route

Create a file like this:

```typescript
import { Controller, Get } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.service.findOne(id);
  }
}
```

Now register it in the module...
```

This snippet will be wrong six months later when decorators change or the service layer gets async constructors. The agent will follow the stale pattern.

**Good:**
```markdown
## How to add a new route

1. Read the most-recently-added controller for the pattern: `src/users/users.controller.ts`.
2. Create `src/<domain>/<domain>.controller.ts` following the same structure (constructor injection,
   decorator stack, DTO validation via class-validator).
3. Register the controller in its module (`src/<domain>/<domain>.module.ts`) and the module in
   `src/app.module.ts`.
4. Add tests at `test/<domain>.e2e-spec.ts` — see `test/users.e2e-spec.ts` for a happy-path example.

Common mistake: forgetting the `ValidationPipe` on the DTO parameter. `main.ts` enables it globally,
so `@UsePipes` is rarely needed — check `main.ts:18` for the enabled pipes before adding one.
```

The good version names five real files. If any of those change, the agent reads the new truth, not a fossilized pattern.
