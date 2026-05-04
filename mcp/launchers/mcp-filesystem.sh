#!/usr/bin/env bash
# MCP launcher: filesystem
# Sandboxed filesystem access — read and optionally write under a fixed set of
# directories. Paths are passed as arguments; the server refuses access outside
# them.
#
# Configure MCP_FS_ROOTS as a space-separated list of allowed roots.
# Example: MCP_FS_ROOTS="$HOME/Projects $HOME/Documents/scratch"

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "filesystem MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${MCP_FS_ROOTS-}" ]]; then
  echo "filesystem MCP unavailable: set MCP_FS_ROOTS to a space-separated list of allowed directories." >&2
  exit 0
fi

# shellcheck disable=SC2086
exec npx -y @modelcontextprotocol/server-filesystem $MCP_FS_ROOTS
