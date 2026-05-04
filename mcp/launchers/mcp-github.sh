#!/usr/bin/env bash
# MCP launcher: github
# Gives Claude Code access to GitHub API: issues, PRs, actions, repo metadata.
# Requires GITHUB_PERSONAL_ACCESS_TOKEN with the scopes the project needs
# (commonly: repo, read:org, workflow).

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "github MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN-}" ]]; then
  echo "github MCP unavailable: set GITHUB_PERSONAL_ACCESS_TOKEN." >&2
  exit 0
fi

exec npx -y @modelcontextprotocol/server-github "$@"
