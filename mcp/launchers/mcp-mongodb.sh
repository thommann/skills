#!/usr/bin/env bash
# MCP launcher: mongodb
# Read access to a MongoDB deployment.
# Requires MONGODB_URI (mongodb://user:pass@host:port/db).
#
# Use a read-only database user to prevent accidental writes.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "mongodb MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${MONGODB_URI-}" ]]; then
  echo "mongodb MCP unavailable: set MONGODB_URI (read-only user recommended)." >&2
  exit 0
fi

exec npx -y mongodb-mcp-server --connectionString "$MONGODB_URI" "$@"
