#!/usr/bin/env bash
# command-allowlist.sh — PreToolUse:Bash hook
# Blocks commands not in the agent's bashPolicy.allow list.
# Usage: command-allowlist.sh <agent-name> <command>
# Exit 0 = allow. Non-zero = block.
# Reads allow list from environment: COMMANDER_BASH_ALLOW (space-separated command prefixes)
# Defaults to denying everything if no allow list is set (safe default).

set -euo pipefail

AGENT="${1:-unknown}"
CMD="${2:-}"
ALLOW_LIST="${COMMANDER_BASH_ALLOW:-}"

if [[ -z "$CMD" ]]; then
  echo "command-allowlist: no command supplied" >&2
  exit 1
fi

# Global hard-deny: destructive patterns regardless of allow list
DENY_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \$HOME'
  ':(){ :|:& };:'
  'dd if='
  'mkfs'
  '> /dev/sda'
  'chmod -R 777 /'
  'curl .* | sh'
  'wget .* | sh'
)
for PAT in "${DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$PAT"; then
    echo "command-allowlist: BLOCKED destructive pattern matched for agent=$AGENT: $PAT" >&2
    exit 1
  fi
done

# If no explicit allow list → default deny (fail closed)
if [[ -z "$ALLOW_LIST" ]]; then
  echo "command-allowlist: BLOCKED agent=$AGENT has no bashPolicy.allow set; default deny" >&2
  exit 1
fi

# Check first word of command against allow list prefixes
FIRST_WORD=$(echo "$CMD" | awk '{print $1}')
for ALLOWED in $ALLOW_LIST; do
  if [[ "$FIRST_WORD" == "$ALLOWED" || "$FIRST_WORD" == "$ALLOWED"* ]]; then
    exit 0
  fi
done

echo "command-allowlist: BLOCKED command not in allow list for agent=$AGENT: $FIRST_WORD" >&2
exit 1
