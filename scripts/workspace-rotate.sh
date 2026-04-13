#!/usr/bin/env bash
# workspace-rotate.sh — keep last 3 runs, compress older into _archive/
# Never touches HANDOFF.md, run.log, audit.log (they live at workspace root, not in run dirs)
# Usage: workspace-rotate.sh <workspace-root>   (defaults to ./_workspace)

set -euo pipefail

WORKSPACE="${1:-./_workspace}"
KEEP=3

if [[ ! -d "$WORKSPACE" ]]; then
  echo "workspace-rotate: $WORKSPACE not a directory, nothing to do"
  exit 0
fi

ARCHIVE="$WORKSPACE/_archive"
mkdir -p "$ARCHIVE"

# list run dirs (skip _archive, checkpoints symlink, and top-level files)
# sort by directory name (which encodes timestamp per our scheme)
mapfile -t ALL_RUNS < <(
  find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d \
    -not -name "_archive" -not -name "checkpoints" -not -name "skill-god" \
    2>/dev/null | sort
)

TOTAL=${#ALL_RUNS[@]}
if [[ "$TOTAL" -le "$KEEP" ]]; then
  echo "workspace-rotate: $TOTAL run(s), nothing to archive (keep=$KEEP)"
  exit 0
fi

TO_ARCHIVE_COUNT=$((TOTAL - KEEP))
echo "workspace-rotate: $TOTAL run(s) found, archiving oldest $TO_ARCHIVE_COUNT"

for (( i=0; i<TO_ARCHIVE_COUNT; i++ )); do
  RUN="${ALL_RUNS[$i]}"
  RUN_ID=$(basename "$RUN")
  TARGET="$ARCHIVE/${RUN_ID}.tar.gz"
  if [[ -f "$TARGET" ]]; then
    echo "  already archived: $RUN_ID"
    rm -rf "$RUN"
    continue
  fi
  tar -czf "$TARGET" -C "$WORKSPACE" "$RUN_ID" && rm -rf "$RUN"
  echo "  archived: $RUN_ID"
done

echo "workspace-rotate: done"
