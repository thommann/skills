#!/usr/bin/env bash
# MCP launcher: postgres
# Read-only query access to a Postgres database.
# Requires POSTGRES_URL in the form: postgres://user:pass@host:port/db
#
# The official server honors the connection string's user; use a read-only
# role to prevent accidental mutations.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "postgres MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${POSTGRES_URL-}" ]]; then
  echo "postgres MCP unavailable: set POSTGRES_URL (read-only role recommended)." >&2
  exit 0
fi

exec npx -y @modelcontextprotocol/server-postgres "$POSTGRES_URL"
