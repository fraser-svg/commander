#!/usr/bin/env bash
# verify-audit.sh — walks _workspace/audit.log and verifies the hash chain
# Usage: verify-audit.sh [audit-log-path]
# Exit 0 = chain valid. Non-zero = tampering detected.

set -euo pipefail

LOG="${1:-_workspace/audit.log}"

if [[ ! -f "$LOG" ]]; then
  echo "verify-audit: no audit log at $LOG"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "verify-audit: python3 required" >&2
  exit 2
fi

python3 - "$LOG" <<'PY'
import hashlib, json, sys
path = sys.argv[1]
prev = "0" * 64
n = 0
with open(path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        n += 1
        entry = json.loads(line)
        if entry.get("prevHash", "").removeprefix("sha256:") != prev:
            print(f"verify-audit: BROKEN CHAIN at seq={entry.get('seq')}: prevHash mismatch")
            sys.exit(1)
        claimed = entry.pop("entryHash", "").removeprefix("sha256:")
        hash_input = f"{entry['seq']}{entry['ts']}{json.dumps(entry, sort_keys=True)}{prev}"
        actual = hashlib.sha256(hash_input.encode()).hexdigest()
        if actual != claimed:
            print(f"verify-audit: BROKEN CHAIN at seq={entry.get('seq')}: entryHash mismatch")
            sys.exit(1)
        prev = claimed
print(f"verify-audit: OK ({n} entries, chain valid)")
PY
