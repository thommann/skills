#!/usr/bin/env bash
# MCP launcher: context7
# Provides version-pinned library documentation lookup.
# No env vars required.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "context7 MCP unavailable: npx is not installed." >&2
  exit 0
fi

exec npx -y @upstash/context7-mcp "$@"
