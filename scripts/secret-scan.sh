#!/usr/bin/env bash
# secret-scan.sh — PostToolUse:Write|Edit hook
# Scans a file for secret patterns and blocks commit if found.
# Usage: secret-scan.sh <file-path>
# Exit 0 = clean. Non-zero = secret detected, block.

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  # not a file write — ignore
  exit 0
fi

# Skip binary files
if file "$FILE" 2>/dev/null | grep -q 'binary'; then
  exit 0
fi

# Secret patterns — additive, keep simple and high-signal
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                              # AWS access key
  'ASIA[0-9A-Z]{16}'                              # AWS session key
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'
  'ghp_[0-9A-Za-z]{36}'                           # GitHub personal access token
  'gho_[0-9A-Za-z]{36}'                           # GitHub OAuth token
  'ghs_[0-9A-Za-z]{36}'                           # GitHub app token
  'github_pat_[0-9A-Za-z_]{82}'                   # GitHub fine-grained PAT
  'sk-ant-[A-Za-z0-9-]{32,}'                      # Anthropic API key
  'sk-[A-Za-z0-9]{48}'                            # OpenAI-style
  '-----BEGIN (RSA |OPENSSH |EC |DSA |)PRIVATE KEY-----'
  'xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[A-Za-z0-9]{24}'  # Slack
  'AIza[0-9A-Za-z_\-]{35}'                        # Google API key
)

HITS=0
for PAT in "${PATTERNS[@]}"; do
  if grep -qE "$PAT" "$FILE" 2>/dev/null; then
    LINE=$(grep -nE "$PAT" "$FILE" 2>/dev/null | head -1)
    echo "secret-scan: BLOCKED possible secret in $FILE :: $LINE" >&2
    HITS=$((HITS+1))
  fi
done

if [[ "$HITS" -gt 0 ]]; then
  exit 1
fi
exit 0
