#!/usr/bin/env bash
# path-validator.sh — PreToolUse:Write|Edit hook
# Rejects paths outside project root or matching a deny list.
# Usage: path-validator.sh <path>
# Exit 0 = allow. Exit non-zero = block.

set -euo pipefail

TARGET_PATH="${1:-}"
if [[ -z "$TARGET_PATH" ]]; then
  echo "path-validator: no path supplied" >&2
  exit 1
fi

# Resolve to absolute
if [[ "$TARGET_PATH" == /* ]]; then
  ABS="$TARGET_PATH"
else
  ABS="$(pwd)/$TARGET_PATH"
fi

# Deny list — system paths an agent should never touch
DENY=(
  "/etc"
  "/usr"
  "/bin"
  "/sbin"
  "/var"
  "${HOME}/.ssh"
  "${HOME}/.aws"
  "${HOME}/.gnupg"
  "${HOME}/.config/gh"
  "${HOME}/.anthropic"
)

for DENIED in "${DENY[@]}"; do
  if [[ "$ABS" == "$DENIED"* ]]; then
    echo "path-validator: BLOCKED path in deny list: $ABS" >&2
    exit 1
  fi
done

# Must be inside a project-like root (pwd or HOME)
PROJECT_ROOT="$(pwd)"
if [[ "$ABS" != "$PROJECT_ROOT"* && "$ABS" != "$HOME"* ]]; then
  echo "path-validator: BLOCKED path outside project root or HOME: $ABS" >&2
  exit 1
fi

exit 0
