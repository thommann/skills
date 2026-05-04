#!/usr/bin/env bash
# Hook: protect-sensitive-files
# Event: PreToolUse
# Matcher: Read|Edit|Write
#
# Blocks the agent from reading or writing sensitive files (live secrets,
# credentials, private keys). Exit 2 refuses the tool call with a message.
#
# This is a safety net — not a replacement for `.gitignore` or a secrets manager.

set -euo pipefail

input=$(cat)
[[ -z "$input" ]] && exit 0

file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.command // empty')
[[ -z "$file_path" ]] && exit 0

case "$file_path" in
  *.env|*/.env)
    echo "BLOCKED: $file_path contains live secrets. Use .env.example or .env.template for committed templates." >&2
    exit 2
    ;;
  *.pem|*.key|*.p12|*.pfx)
    echo "BLOCKED: $file_path is a private key or certificate file — refusing." >&2
    exit 2
    ;;
  *credentials.json|*credentials.yaml|*credentials.yml|*client_secret*|*service_account*.json)
    echo "BLOCKED: $file_path appears to be a credentials file — refusing." >&2
    exit 2
    ;;
  */certs/*.pem|*/certs/*.key|*/certs/*.crt|*/tls/*.key|*/tls/*.crt)
    echo "BLOCKED: $file_path is under a certs/tls directory — refusing." >&2
    exit 2
    ;;
  *.p8|*.jks|*.keystore)
    echo "BLOCKED: $file_path is a keystore file — refusing." >&2
    exit 2
    ;;
  *id_rsa|*id_ed25519|*id_ecdsa|*id_dsa)
    echo "BLOCKED: $file_path looks like an SSH private key — refusing." >&2
    exit 2
    ;;
esac

exit 0
