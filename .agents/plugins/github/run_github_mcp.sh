#!/bin/bash
set -e

# Dynamically resolve token from environment or active gh CLI authentication session
TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:-${GH_TOKEN:-$(gh auth token 2>/dev/null || true)}}"

if [ -z "$TOKEN" ]; then
  echo "Error: GITHUB_PERSONAL_ACCESS_TOKEN or gh CLI authentication session not found." >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="$TOKEN"
exec npx -y @modelcontextprotocol/server-github
