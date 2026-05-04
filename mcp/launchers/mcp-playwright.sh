#!/usr/bin/env bash
# MCP launcher: playwright
# Browser automation — navigate URLs, click elements, capture console + network.
# Installs Playwright browsers on first launch (~200 MB).

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "playwright MCP unavailable: npx is not installed." >&2
  exit 0
fi

exec npx -y @modelcontextprotocol/server-playwright "$@"
