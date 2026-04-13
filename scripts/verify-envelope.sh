#!/usr/bin/env bash
# verify-envelope.sh — recomputes envelope hash and checks it matches
# Usage: verify-envelope.sh <envelope-file>
# Exit 0 = hash valid. Non-zero = mismatch, halt orchestrator.

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "verify-envelope: file not found: $FILE" >&2
  exit 1
fi

# Extract frontmatter fields from the envelope opening tag
SOURCE=$(grep -oE 'source="[^"]*"' "$FILE" | head -1 | sed 's/source="//;s/"//')
TS=$(grep -oE 'ts="[^"]*"' "$FILE" | head -1 | sed 's/ts="//;s/"//')
CLAIMED_HASH=$(grep -oE 'hash="sha256:[a-f0-9]+"' "$FILE" | head -1 | sed 's/hash="sha256://;s/"//')

if [[ -z "$SOURCE" || -z "$TS" || -z "$CLAIMED_HASH" ]]; then
  echo "verify-envelope: malformed envelope in $FILE" >&2
  exit 1
fi

# Extract content between opening tag and closing tag
CONTENT=$(awk '/<agent-output /{flag=1; next} /<\/agent-output>/{flag=0} flag' "$FILE")

HASH_INPUT="${SOURCE}${TS}${CONTENT}"
if command -v shasum >/dev/null 2>&1; then
  ACTUAL=$(echo -n "$HASH_INPUT" | shasum -a 256 | awk '{print $1}')
else
  ACTUAL=$(echo -n "$HASH_INPUT" | sha256sum | awk '{print $1}')
fi

if [[ "$ACTUAL" != "$CLAIMED_HASH" ]]; then
  echo "verify-envelope: HASH MISMATCH in $FILE" >&2
  echo "  claimed: $CLAIMED_HASH" >&2
  echo "  actual:  $ACTUAL" >&2
  exit 1
fi

echo "verify-envelope: OK ($FILE)"
exit 0
