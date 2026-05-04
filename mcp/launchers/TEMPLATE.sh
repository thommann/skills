#!/usr/bin/env bash
# MCP launcher: <SERVER_NAME>
# Launches the <server-name> MCP server via stdio so Claude Code can talk to it.
#
# Principles:
#   - Prerequisites (binary present, env var set) are CHECKED, and missing ones
#     cause silent exit 0. Never exit 1 on missing prerequisites — that blocks
#     Claude Code with no useful message.
#   - Real failures (the MCP server itself crashing) are surfaced by `exec`ing
#     so the shell's exit code == the server's exit code.

set -euo pipefail

# 1. Binary check — is the runner we need installed?
if ! command -v npx >/dev/null 2>&1; then
  echo "<server-name> MCP unavailable: npx is not installed." >&2
  exit 0
fi

# 2. Env var check — are the required secrets set?
# Adapt this check; delete the block if the server needs no env.
# if [[ -z "${MY_REQUIRED_VAR-}" ]]; then
#   echo "<server-name> MCP unavailable: set MY_REQUIRED_VAR." >&2
#   exit 0
# fi

# 3. (Optional) Pre-launch setup.
# Example: port-forward, vault-unlock, start a sidecar.
# kubectl port-forward svc/my-db 5432:5432 >/dev/null 2>&1 &
# PF_PID=$!
# trap "kill $PF_PID 2>/dev/null || true" EXIT

# 4. Launch — exec replaces this shell with the MCP server process so stdio flows correctly.
exec npx -y <@scope/mcp-package-name> "$@"
