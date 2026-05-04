---
name: debug-frontend
description: >
  Diagnose a frontend issue — rendering bug, console error, network failure, broken interaction —
  using browser devtools, source maps, and (when available) Playwright for automated reproduction.
  Use when user says 'debug frontend', 'page is broken', 'UI not updating', 'console errors',
  'component not rendering', or 'network tab shows failure'. Do NOT use for backend API issues
  (use debug-backend) or for styling-only regressions (inspect CSS).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug a frontend issue

## Before You Start

- Root `CLAUDE.md` → the project's frontend directory and framework.
- Scope-level `CLAUDE.md` under `src/` or the frontend package.
- The Playwright MCP server — `.claude/mcp/mcp-playwright.sh` — if available. Lets the agent drive a real browser.
- Source map status — are production builds shipping source maps? If not, stack traces in prod won't map to source files.

## Step 1: collect symptoms

- What does the user see? — screenshot, short video, exact error message.
- What were they doing? — the interaction that triggered it.
- Browser + version. Some bugs are browser-specific.
- Environment — dev, staging, prod. Dev often has extra warnings that aren't bugs.
- Console output — text + severity.
- Network tab — failed or unexpected requests.

## Step 2: gather evidence

**Browser devtools** (the most important tool):

- **Console** — uncaught exceptions, framework warnings, custom logs. Filter by severity to cut through React/Vue dev-mode noise.
- **Network** — request URL, method, status, response body. Look for 4xx/5xx that the UI swallowed.
- **Elements** — the actual DOM. Sometimes the bug is "component didn't render" — check if the element is in the DOM but hidden vs not in the DOM at all.
- **React/Vue DevTools** — component tree, props, state. Catches "wrong prop passed" bugs the console doesn't surface.

**Playwright (via MCP)** — when available, use it to automate:

```
# Via mcp__claude-in-chrome__* or mcp-playwright:
#   - navigate to the failing URL
#   - simulate the user's actions
#   - capture console + network
```

Automated reproduction beats "try it yourself" — it's repeatable.

**Source maps** — clicking a stack trace line should jump to the TypeScript/TSX/Vue source. If it jumps to minified JS, source maps aren't loaded — either build them for the environment you're debugging in, or debug against dev.

## Step 3: narrow

| Signal | Classification |
|---|---|
| Only one page broken, others fine | Page-specific bug — recent change to that route's code. |
| Only one browser affected | Browser-specific API (Intl, Stream, ResizeObserver) or CSS feature. |
| Broken in production, fine in dev | Build output differs — minification stripped something, or env config differs. |
| Intermittent — sometimes works | Timing, race condition, data-dependent. Hardest to debug. |
| Network request returning HTML instead of JSON | Server is serving the SPA's index.html on a 404 — backend routing issue, not frontend. |

## Step 4: reproduce minimally

```
# Dev server
pnpm dev   # or npm run dev, yarn dev

# Navigate to the failing URL with the exact state (query params, auth, feature flags)
# If the bug requires specific data, seed it or use a test account.

# If Playwright is available:
mcp__claude-in-chrome__navigate <url>
mcp__claude-in-chrome__find <selector>
mcp__claude-in-chrome__read_console_messages
```

Try to isolate: does the bug happen with minimal data? With no feature flags? In a private window (rules out browser extensions)?

## Step 5: read the code

Once you know which component or hook is involved:

```bash
# Start from the failing symptom — the component name or error message
grep -rn '<ErrorMessage>' src/
grep -rn 'function <ComponentName>' src/
```

Read the component, its parents (for incoming props), and the hooks/composables it uses. Common issues:

- **Stale closure** — a callback captured an old value.
- **Missing dependency in a hook/effect** — effect runs with stale data.
- **State mutation** — mutated state in-place in a framework that expects immutable updates.
- **Key mismatch** — a list item's key is not unique or not stable across renders.
- **Hydration mismatch** — SSR rendered one thing, client rendered another.

## Step 6: propose or apply the fix

Fix the root cause. "Wrap in `useCallback`" or "wrap in `React.memo`" is sometimes right, but often papers over a different bug.

## Step 7: prevent regression

- **A component test** — asserts the rendered DOM or captured events match.
- **An E2E test** — Playwright test that reproduces the original interaction.
- **A `Things to Know` entry** if the bug depended on project-specific knowledge.

## Verify

```
# Repro no longer fails — navigate to the URL, perform the action, observe correct behavior.

# Tests pass
pnpm test <new-test-file>
pnpm e2e <new-e2e-file>

# Build the project (production build sometimes surfaces issues the dev build hides)
pnpm build && pnpm preview
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Debugging against the minified production bundle with no source maps | Enable source maps or debug against dev. Minified stack traces are not useful. |
| Trusting a dev-mode warning as a bug | Some warnings (React strict mode double-render) are informational. Read the warning; not every one is an error. |
| Ignoring the console in favor of the UI | The console has the exception. The UI has the symptom. Read both. |
| Blaming a third-party library for a state bug in your own code | Reproduce with the library stripped. Most "library bugs" are usage bugs. |
