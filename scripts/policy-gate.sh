#!/usr/bin/env bash
# policy-gate.sh — general policy decision shim
# Reads agent security block and returns block|allow based on tool + target
# Usage: policy-gate.sh <agent-file.md> <tool-name> <target>
# Exit 0 = allow. Non-zero = block.

set -euo pipefail

AGENT_FILE="${1:-}"
TOOL="${2:-}"
TARGET="${3:-}"

if [[ -z "$AGENT_FILE" || -z "$TOOL" ]]; then
  echo "policy-gate: usage: policy-gate.sh <agent-file> <tool> [target]" >&2
  exit 1
fi

if [[ ! -f "$AGENT_FILE" ]]; then
  echo "policy-gate: agent file not found: $AGENT_FILE" >&2
  exit 1
fi

# Extract allowedTools from frontmatter
TOOLS_LINE=$(awk '/^---$/{c++; if(c==2) exit; next} c==1 && /allowedTools:/{print}' "$AGENT_FILE")
if [[ -z "$TOOLS_LINE" ]]; then
  echo "policy-gate: BLOCKED agent has no allowedTools declaration" >&2
  exit 1
fi

# Simple contains check — real implementation parses YAML list properly
if echo "$TOOLS_LINE" | grep -q "\b${TOOL}\b"; then
  # For Bash tool, defer to command-allowlist.sh
  if [[ "$TOOL" == "Bash" && -n "$TARGET" ]]; then
    exec "$(dirname "$0")/command-allowlist.sh" "$(basename "$AGENT_FILE" .md)" "$TARGET"
  fi
  # For Write/Edit, defer to path-validator.sh
  if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]] && [[ -n "$TARGET" ]]; then
    exec "$(dirname "$0")/path-validator.sh" "$TARGET"
  fi
  exit 0
fi

echo "policy-gate: BLOCKED tool=$TOOL not in allowedTools for $(basename "$AGENT_FILE")" >&2
exit 1
