#!/usr/bin/env bash
# scan-skills.sh — builds ~/.claude/skill-index.json
# Walks ~/.claude/skills/ and ~/.claude/plugins/**/skills/ and writes an index.
# Run by SessionStart hook or manually; NOT on every commander invocation.

set -euo pipefail

INDEX="${HOME}/.claude/skill-index.json"
SEARCH_ROOTS=(
  "${HOME}/.claude/skills"
  "${HOME}/.claude/plugins"
)
TMP=$(mktemp)
echo "[]" > "$TMP"

have_jq=0
if command -v jq >/dev/null 2>&1; then have_jq=1; fi

if [[ $have_jq -eq 0 ]]; then
  echo "scan-skills: jq not installed; writing minimal plain-text index" >&2
fi

append_entry() {
  local name="$1" desc="$2" path="$3" mtime="$4"
  if [[ $have_jq -eq 1 ]]; then
    local TMP2
    TMP2=$(mktemp)
    jq --arg n "$name" --arg d "$desc" --arg p "$path" --argjson m "${mtime:-0}" \
      '. += [{name:$n, description:$d, path:$p, mtime:$m}]' "$TMP" > "$TMP2" && mv "$TMP2" "$TMP"
  else
    printf '%s\t%s\t%s\n' "$name" "$path" "$mtime" >> "$TMP.plain"
  fi
}

for ROOT in "${SEARCH_ROOTS[@]}"; do
  [[ -d "$ROOT" ]] || continue
  while IFS= read -r SKILL_FILE; do
    name=""
    desc=""
    # parse frontmatter between first two --- markers
    if command -v awk >/dev/null 2>&1; then
      name=$(awk '/^---$/{c++; next} c==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "$SKILL_FILE" || true)
      desc=$(awk '/^---$/{c++; next} c==1 && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$SKILL_FILE" || true)
    fi
    [[ -z "$name" ]] && name=$(basename "$(dirname "$SKILL_FILE")")
    [[ -z "$desc" ]] && desc="(no description)"

    if stat -f "%m" "$SKILL_FILE" >/dev/null 2>&1; then
      mtime=$(stat -f "%m" "$SKILL_FILE")
    else
      mtime=$(stat -c "%Y" "$SKILL_FILE" 2>/dev/null || echo 0)
    fi

    append_entry "$name" "$desc" "$SKILL_FILE" "$mtime"
  done < <(find "$ROOT" -type f -name "SKILL.md" 2>/dev/null | grep -v '/_workspace/' || true)
done

if [[ $have_jq -eq 1 ]]; then
  mv "$TMP" "$INDEX"
  COUNT=$(jq 'length' "$INDEX")
  echo "scan-skills: wrote $COUNT skills to $INDEX"
else
  mv "$TMP.plain" "$INDEX.tsv"
  rm -f "$TMP"
  echo "scan-skills: wrote plain TSV to $INDEX.tsv (install jq for JSON)"
fi
