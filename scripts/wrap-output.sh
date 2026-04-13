#!/usr/bin/env bash
# wrap-output.sh — wraps agent output in an envelope with a sha256 hash
# Usage: wrap-output.sh <source-agent> <data-class> <input-file> <output-file>
# Prevents prompt-injection across agent-to-agent handoffs.

set -euo pipefail

SOURCE="${1:-}"
DATACLASS="${2:-internal}"
INPUT="${3:-}"
OUTPUT="${4:-}"

if [[ -z "$SOURCE" || -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "usage: wrap-output.sh <source-agent> <data-class> <input-file> <output-file>" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "wrap-output: input file not found: $INPUT" >&2
  exit 1
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT=$(cat "$INPUT")
HASH_INPUT="${SOURCE}${TS}${CONTENT}"
if command -v shasum >/dev/null 2>&1; then
  HASH=$(echo -n "$HASH_INPUT" | shasum -a 256 | awk '{print $1}')
else
  HASH=$(echo -n "$HASH_INPUT" | sha256sum | awk '{print $1}')
fi

cat > "$OUTPUT" <<EOF
<agent-output source="${SOURCE}" ts="${TS}" dataClass="${DATACLASS}" outputsSanitized="false" hash="sha256:${HASH}">
${CONTENT}
</agent-output>
EOF

echo "wrap-output: wrote envelope to $OUTPUT (hash=sha256:${HASH:0:16}...)"
