#!/usr/bin/env bash
# MCP launcher: slack
# Slack workspace access — read channels, post messages, look up users.
# Requires SLACK_BOT_TOKEN (xoxb-...) and optionally SLACK_TEAM_ID.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
  echo "slack MCP unavailable: npx is not installed." >&2
  exit 0
fi

if [[ -z "${SLACK_BOT_TOKEN-}" ]]; then
  echo "slack MCP unavailable: set SLACK_BOT_TOKEN (xoxb-...)." >&2
  exit 0
fi

export SLACK_BOT_TOKEN
[[ -n "${SLACK_TEAM_ID-}" ]] && export SLACK_TEAM_ID

exec npx -y @modelcontextprotocol/server-slack "$@"
