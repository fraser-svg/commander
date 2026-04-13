#!/usr/bin/env bash
# verify-agent-def.sh <file.md> — validates a single agent definition
# Exits 1 on any failure with specific error messages.
# Callable per-file or batched via `for f in agents/*.md; do verify-agent-def.sh "$f"; done`

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: verify-agent-def.sh <agent-file.md>" >&2
  exit 2
fi

FILE="$1"
if [[ ! -f "$FILE" ]]; then
  echo "FAIL: file not found: $FILE" >&2
  exit 1
fi

ERRORS=0
fail() { echo "FAIL [$FILE]: $1" >&2; ERRORS=$((ERRORS+1)); }

# Extract frontmatter block
FRONTMATTER=$(awk '/^---$/{c++; if(c==2) exit; next} c==1' "$FILE")

# model field
MODEL=$(echo "$FRONTMATTER" | awk '/^model:/{sub(/^model:[[:space:]]*/,""); gsub(/["'"'"']/,""); print; exit}')
if ! [[ "$MODEL" =~ ^(opus|sonnet|haiku)$ ]]; then
  fail "model must be opus|sonnet|haiku, got: '$MODEL'"
fi

# allowedTools must exist and not be empty or "all"
if ! echo "$FRONTMATTER" | grep -q "allowedTools:"; then
  fail "security.allowedTools missing"
else
  TOOLS=$(echo "$FRONTMATTER" | awk '/allowedTools:/{sub(/^[[:space:]]*allowedTools:[[:space:]]*/,""); print; exit}')
  if [[ -z "$TOOLS" || "$TOOLS" == "[]" ]]; then
    fail "allowedTools is empty"
  fi
  if echo "$TOOLS" | grep -qi '"all"\|: all\b'; then
    fail "allowedTools must not be 'all'"
  fi
fi

# required sections in body
for SECTION in "## Core Role" "## Input" "## Output" "## Error Handling"; do
  grep -q "$SECTION" "$FILE" || fail "missing section: $SECTION"
done

# size guard
LINES=$(wc -l < "$FILE")
if [[ "$LINES" -gt 300 ]]; then
  fail "exceeds 300-line limit (got $LINES)"
fi

# no ALL-CAPS MUST/NEVER/ALWAYS without a # WHY: comment nearby
if grep -nE '\b(MUST|NEVER|ALWAYS|FORBIDDEN)\b' "$FILE" > /tmp/verify_caps.$$; then
  while IFS=: read -r lineno content; do
    # check within 2 lines for a # WHY:
    START=$((lineno > 2 ? lineno - 2 : 1))
    END=$((lineno + 2))
    if ! sed -n "${START},${END}p" "$FILE" | grep -q "# WHY:"; then
      fail "ALL-CAPS directive at line $lineno has no '# WHY:' justification"
    fi
  done < /tmp/verify_caps.$$
  rm -f /tmp/verify_caps.$$
fi

# brevity constraint presence check (warning-only, not a hard fail)
if ! echo "$FRONTMATTER" | grep -q "brevity:"; then
  echo "WARN [$FILE]: no brevity: constraint in frontmatter" >&2
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "FAIL: $ERRORS error(s) in $FILE" >&2
  exit 1
fi

echo "OK: $FILE"
exit 0
