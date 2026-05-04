# 05 — Alternatives, not just prohibitions

> "Use Y instead of X" beats "Don't use X."

## Why

A prohibition on its own leaves the agent with a gap and no guidance — it knows what to avoid but not what to do. Worse, prohibitions stated without alternatives invite rule-lawyering: the agent finds a way to do the forbidden thing under a different name, because it has no other path.

Every "don't" that a codebase wants to stick must come with a "do this instead" that is at least as easy to follow.

## Rule

When writing a prohibition:

- Name the banned thing specifically (`axios`, `console.log`, `@Autowired`).
- Explain in one phrase **why** it's banned (history, security, consistency).
- Name the replacement specifically (`our `apiClient` in `src/lib/api.ts``, `the `logger` in `src/lib/logger.ts``).
- Point at a file that uses the replacement correctly.

If you cannot provide an alternative, the prohibition is probably wrong — reconsider the rule.

## How validators check it

`validate-claude-md.sh` greps for prohibition language (`never`, `don't`, `do not`, `must not`, `never use`). If any match is found, it also requires at least one alternative marker to appear in the same document (`instead`, `use .* instead`, `prefer `, `create new`, `use the `). **Prohibition without alternative → hard error.**

The same check runs on `SKILL.md` and `agent.md` files.

## Good vs bad

**Bad:**
```markdown
## Rules

- Never use `console.log` in production code.
- Don't use `any` types.
- Avoid global state.
```

Three prohibitions, zero alternatives. The agent will strip `console.log` calls and replace them with... what? It will change `any` to `unknown` (technically correct, often wrong in context). It will refactor global state into a singleton (same thing, worse name).

**Good:**
```markdown
## Logging and globals

- **Logging**: use `logger` from `src/lib/logger.ts` instead of `console.log`. The logger adds
  request IDs via AsyncLocalStorage (see `src/middleware/request-id.ts`) and ships to Sentry
  at the `error` level. `console.log` is stripped by the bundler in `vite.config.ts`, so it
  silently disappears in production — that's the reason for the rule.
- **Types**: prefer a named interface or a zod schema over `any`. The repo uses `zod` for runtime
  contracts at boundaries (see `src/api/schemas/`). When `unknown` is needed (e.g., third-party
  webhook payloads), narrow with a zod parse at the earliest boundary.
- **State**: for cross-component state, use the store in `src/store/` (Pinia). For per-request
  server-side state, use the AsyncLocalStorage context in `src/context.ts`. Module-level `let`
  is banned because it leaks across test files — see ADR `docs/adr/0012-no-module-state.md`.
```

Three prohibitions, three alternatives, five file references, and a pointer to the ADR that explains the module-state rule.
