---
name: debug-tests
description: >
  Diagnose a failing or flaky test — isolate the failure, find whether it's a real regression
  or test-environment issue, and propose a fix. Use when user says 'test is failing', 'flaky
  test', 'test passes locally but fails in CI', 'test sometimes fails', or 'test hangs'.
  Do NOT use for writing new tests (use add-test-suite) or for code review of tests (use
  review-diff).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug a failing or flaky test

## Before You Start

- Root `CLAUDE.md` → the project's test commands, test directories, and any fixture setup.
- The test file in question — read it end to end.
- Recent changes to the file under test AND the test file — `git log -10 --oneline -- <test-file> <source-file>`.
- CI logs, if the failure is CI-only. Local reproduction is the first goal.

## Step 1: reproduce locally

```bash
# Run just the failing test
pnpm test <file> --testNamePattern='<test name>'
pytest <file>::<test_name>
cargo test --test <file> <test_name> -- --exact
go test -run '<TestName>' ./<pkg>
```

If it fails locally on the first try: continue to step 2.

If it passes locally: this is the flaky / env-dependent case. Go to step 5.

## Step 2: understand the failure

Read the assertion that failed:

- **What did it expect?**
- **What did it get?**
- **Is the diff a single wrong value, or shapes that don't match at all?**

A precise diff points at a single bug; a wildly different shape points at a setup problem (fixture not ran, state leaked in).

## Step 3: narrow to a bisection point

If the test passed recently and now fails:

```bash
# Find the last commit where it passed
git log --oneline -20 -- <source-file> <test-file>

# Check out an older commit and run
git checkout <older-sha>
<test command>

# Bisect
git bisect start HEAD <older-known-good-sha>
git bisect run <test command>
git bisect reset
```

`git bisect` finds the commit that introduced the failure — often the fastest path when the bug isn't obvious.

## Step 4: read the code under test

With the commit pinpointed (or the latest code), read the code the test exercises. Common causes:

- **Signature changed but the test wasn't updated.**
- **Behavior changed in a subtle way** — e.g., rounding, ordering, default values.
- **New required dependency not satisfied by the fixture.**
- **Race condition introduced by making a function async.**

## Step 5: flaky tests — pin down the source of randomness

Flakies have one of a few root causes:

### Fixture / test-order dependence

```bash
# Run the suite with a fixed seed / order
pytest --random-order-seed=42
vitest --shuffle false
# Most runners also support running tests in parallel — disable for reproduction
pytest -p no:randomly -n 0
```

If the test fails only when preceded by specific other tests, one of them is leaving state behind (global singleton, env var, DB rows, file on disk).

### Timing / async

The test `await`s something but the thing awaited completes non-deterministically. Symptoms: `expect(...).toEqual(...)` where the value is sometimes computed, sometimes not.

Fixes:

- `await` until the predicate is true (polling) instead of `sleep()`.
- Use the framework's `waitFor` utilities rather than fixed delays.
- If testing a debounce/throttle, use fake timers (`jest.useFakeTimers`, `sinon.useFakeTimers`).

### External resource

Test hits a network endpoint, a running local service, or a file that varies. Isolate with a mock or a deterministic fixture.

### System clock

Test computes "now" and compares against a fixed value. Freeze time (`freezegun` in Python, `@sinonjs/fake-timers` in JS).

### CI-only failures

If local passes and CI fails:

- **Different timezone?** Set `TZ=UTC` in CI.
- **Different locale?** Set `LC_ALL=C.UTF-8`.
- **Slower runner?** Tests with timing assumptions fail on slow CI. Increase timeouts; prefer polling over sleeps.
- **Different OS?** Linux vs macOS line endings, path separators, case sensitivity. Rare but real.

## Step 6: propose or apply the fix

If the test caught a real regression: fix the code, not the test.

If the test itself is flaky: fix the test (or the fixture).

If the test was asserting wrong behavior: update the assertion, document why in the PR.

## Step 7: prevent regression

- **Run the fix in a loop** — `for i in {1..20}; do pnpm test <file> || break; done` — to confirm the flake is gone.
- **Document in `CLAUDE.md`** under **Things to Know** if the flake root cause was non-obvious (e.g., "tests under `tests/integration/` require `TZ=UTC`; unset TZ causes date comparisons to flake").
- **Remove `.skip` / `.only` / `@pytest.mark.skip`** — if any test is still skipped, that's a liability.

## Verify

```bash
# Run the failing test 10x in a row — passes every time
for i in $(seq 1 10); do
  <test command> <file> || { echo "flaked on run $i"; break; }
done

# Run the full suite — no new failures
<full test command>

# If the fix was to the code under test, run a broader slice
<test command> <broader-path>
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Marking a flaky test `@skip` instead of fixing it | Skipped tests decay. Either fix or delete; don't accumulate skipped tests. |
| `sleep(1)` to "fix" a race condition | Poll for the condition, or use fake timers. `sleep` makes the test slow and doesn't truly fix it. |
| Changing the assertion to match the wrong output | Only update assertions when the new behavior is correct. If the test caught a regression, fix the code. |
| Blaming "CI is just flaky" | CI is a system under your control. If a test is flaky in CI, it's flaky — reproduce in the CI environment (matching OS, CPU count, env vars). |
