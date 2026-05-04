#!/usr/bin/env bash
# Hook: session-start
# Event: SessionStart
#
# Runs once when a new Claude Code session begins. Good place to:
#   - warn if required env vars are missing
#   - print a short status banner
#   - pre-warm caches or ensure local dev deps are current
#
# Must be fast (< 1s ideal). Do not run installs or migrations here without
# gating them behind a staleness check — every session pays the cost.
#
# This template reads the JSON payload for completeness, but SessionStart
# typically has an empty input.

set -euo pipefail

input=$(cat || true)
[[ -z "$input" ]] && input="{}"

# Example: warn about missing env vars the project relies on.
# Adapt the list to your project.
REQUIRED_ENV=("${REQUIRED_ENV-}")   # space-separated list, e.g. "DATABASE_URL GITHUB_PERSONAL_ACCESS_TOKEN"
for var in $REQUIRED_ENV; do
  if [[ -z "${!var-}" ]]; then
    echo "[session-start] NOTE: $var is not set — some tools may be unavailable." >&2
  fi
done

# Example: if a dependency lockfile changed more recently than the installed marker, hint at re-install.
# Uncomment and adapt for your stack.
#
# if [[ pnpm-lock.yaml -nt node_modules/.pnpm-install-marker ]]; then
#   echo "[session-start] pnpm-lock.yaml changed since last install — run 'pnpm install'." >&2
# fi

exit 0
