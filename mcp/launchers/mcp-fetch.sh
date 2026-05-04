#!/usr/bin/env bash
# MCP launcher: fetch
# HTTP fetch with optional allowlisting. Set MCP_FETCH_ALLOWED_DOMAINS to a
# comma-separated list of hosts if you want to restrict fetch targets
# (e.g., "api.github.com,docs.python.org").

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "fetch MCP unavailable: npx is not installed." >&2
  exit 0
fi

# Export the allowlist only if set; the server reads it as an env var.
if [[ -n "${MCP_FETCH_ALLOWED_DOMAINS-}" ]]; then
  export MCP_FETCH_ALLOWED_DOMAINS
fi

exec npx -y @modelcontextprotocol/server-fetch "$@"
