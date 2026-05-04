#!/usr/bin/env bash
# MCP launcher: sentry
# Sentry error tracking access — query events, issues, releases.
# Requires SENTRY_AUTH_TOKEN and SENTRY_ORG; optionally SENTRY_PROJECT.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "sentry MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${SENTRY_AUTH_TOKEN-}" || -z "${SENTRY_ORG-}" ]]; then
  echo "sentry MCP unavailable: set SENTRY_AUTH_TOKEN and SENTRY_ORG." >&2
  exit 0
fi

export SENTRY_AUTH_TOKEN SENTRY_ORG
[[ -n "${SENTRY_PROJECT-}" ]] && export SENTRY_PROJECT

exec npx -y @sentry/mcp-server "$@"
