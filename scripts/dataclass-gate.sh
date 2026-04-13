#!/usr/bin/env bash
# dataclass-gate.sh — checks that source data class is ≤ agent dataScope
# Usage: dataclass-gate.sh <source-class> <agent-dataScope>
# Classes: public < internal < sensitive < pii
# Exit 0 = allowed. Non-zero = blocked.

set -euo pipefail

SOURCE="${1:-public}"
AGENT="${2:-public}"

rank() {
  case "$1" in
    public)    echo 0 ;;
    internal)  echo 1 ;;
    sensitive) echo 2 ;;
    pii)       echo 3 ;;
    *)         echo 99 ;;
  esac
}

SR=$(rank "$SOURCE")
AR=$(rank "$AGENT")

if [[ "$SR" -gt "$AR" ]]; then
  echo "dataclass-gate: BLOCKED source=$SOURCE exceeds agent scope=$AGENT" >&2
  exit 1
fi
exit 0
