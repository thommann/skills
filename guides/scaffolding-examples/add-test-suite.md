---
name: add-test-suite
description: >
  Scaffold a new test suite for a module — fixtures, mocks, and happy-path + edge-case tests —
  matching the project's testing patterns. Use when user says 'add tests for X', 'scaffold a
  test suite', 'new test file', 'test this module', or 'backfill tests'. Do NOT use for adding
  a single test to an existing suite (just add it) or for fixing a flaky test (use debug-tests).
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Add a test suite for a module

<!--
  ADAPT TO YOUR PROJECT:
    {{TEST_DIR}}          — `tests/`, `src/**/*.spec.ts`, `src/**/__tests__/`
    {{UNIT_TEST_DIR}}     — `tests/unit/`, flat under {{TEST_DIR}}
    {{INTEGRATION_DIR}}   — `tests/integration/`, empty if project doesn't split
    {{FIXTURE_FILE}}      — `tests/conftest.py`, `tests/fixtures.ts`, `tests/helpers.ts`
    {{TEST_COMMAND}}      — `pnpm test`, `pytest`, `cargo test`
    {{TARGET_FILE}}       — the module being tested
    {{EXEMPLAR_TEST}}     — a recently-added test file
-->

## Before You Start

- **Exemplar test:** `{{EXEMPLAR_TEST}}` — canonical test file for a similar module. Copy structure, imports, setup.
- **Fixture convention:** `{{FIXTURE_FILE}}` — how the project creates test data (factories, builders, static JSON).
- **Test runner's idioms:** `pytest`, `vitest`, `jest`, `cargo test`, `go test` each have conventions (parametrized tests, setup/teardown, snapshots).
- **What kinds of tests the project uses** — unit (pure functions with mocks), integration (with real DB/HTTP), e2e (via browser / CLI), contract (API schema).

## Step 1: decide the test kind(s)

For the module being tested:

| Module type | Preferred test kind | Why |
|---|---|---|
| Pure function / calculation | Unit | Fast, deterministic |
| Service orchestrating repositories | Unit (mocked repos) + one integration | Unit covers branches; integration catches repo/service misalignment |
| Repository | Integration (real DB) | Mocks prove nothing about ORM behavior |
| API handler | Integration + contract | HTTP mechanics matter |
| UI component | Component test in JSDOM | Renders + interaction without full app |
| Full user flow | E2E | Catches issues at seams |

Pick the minimum set that gives real confidence. Don't over-test pure functions; don't under-test I/O.

## Step 2: create the test file

```bash
# Mirror the source structure
cp {{EXEMPLAR_TEST}} {{TEST_DIR}}/{{same-shape-as-target}}.test.*
```

Update: import of the module under test, fixture imports, describe/test block structure.

## Step 3: set up fixtures

Reuse `{{FIXTURE_FILE}}` where possible. If a new fixture is needed:

- **Small:** define inline in the test file.
- **Reused:** add to `{{FIXTURE_FILE}}` or create a new file under `tests/fixtures/`.

Rules:

- Fixtures produce concrete, readable objects — not overly parameterized builders.
- Fixtures match production shapes. A user fixture with no email won't catch a bug in email-required code paths.
- Fixtures don't depend on each other in non-obvious ways; each test's setup is self-evident.

## Step 4: write tests — happy path first

Start with the canonical usage:

- Call the module with typical inputs.
- Assert the observable behavior: return value, side effect, state change.
- **Assert the shape, not just "no error."** A `expect(x).toBeDefined()` catches approximately nothing.

## Step 5: add edge cases

Systematic coverage:

- **Null / missing input** — does the module handle it, reject it, or fail safe?
- **Empty collections** — `[]`, `{}`, `""`. Common source of off-by-ones.
- **Boundary values** — `0`, `-1`, `MAX_SAFE_INTEGER`.
- **Unicode / long strings** — if the module handles text.
- **Concurrent invocation** — if the module touches shared state.
- **Error branches** — every `throw` / `raise` / `return Err(..)` in the module under test should be exercised.

One edge case per test. A single test asserting 10 things fails ambiguously.

## Step 6: review for anti-patterns

Read your test suite end to end:

- **No test is longer than ~20 lines of arrangement.** If setup is that long, extract a fixture.
- **No test name ends in "works".** Name the expected behavior: "rejects when quantity is negative."
- **No test mocks everything.** Pure-mock tests pass trivially and prove nothing about real interactions.
- **No hidden ordering.** Tests don't depend on execution order; state is reset between.

## Step 7: verify

```bash
# The test file is picked up by the runner
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-test-file}}

# All tests pass
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-test-file}} --verbose  # or equivalent

# Coverage of the target module (if the project tracks coverage)
# Project-specific command — `pnpm test:coverage`, `pytest --cov=...`

# Re-run to confirm no flake
{{TEST_COMMAND}} {{TEST_DIR}}/{{new-test-file}}
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Mocking the thing being tested | Mock its collaborators, not itself. A mocked-self test is a no-op. |
| One test asserting three behaviors | Split. Three tests produce a specific failure message; one mega-test produces an ambiguous one. |
| Tests pass because the mocks are trivial | Integration tests — at least one — against real I/O catch mock drift. |
| Fixtures shared across tests that mutate them | Either make fixtures immutable, or construct fresh ones per test. Hidden mutation = flaky. |
