#!/usr/bin/env python3
"""
audit-writer.py — append a hash-chained audit entry to _workspace/audit.log
Usage: audit-writer.py <event-json>
Reads prev hash from last line of audit.log; writes new entry with prevHash + entryHash.
PII tokens in input are stripped before writing.
"""

import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: audit-writer.py <event-json>", file=sys.stderr)
        return 2
    try:
        entry = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        print(f"audit-writer: invalid JSON: {e}", file=sys.stderr)
        return 1

    log_path = Path("_workspace/audit.log")
    log_path.parent.mkdir(exist_ok=True)

    prev_hash = "0" * 64
    seq = 1
    if log_path.exists() and log_path.stat().st_size > 0:
        last_line = ""
        with log_path.open("rb") as f:
            f.seek(0, 2)
            size = f.tell()
            read = min(size, 4096)
            f.seek(size - read)
            tail = f.read().decode(errors="ignore")
            lines = [l for l in tail.strip().split("\n") if l]
            if lines:
                last_line = lines[-1]
                try:
                    last_entry = json.loads(last_line)
                    prev_hash = last_entry.get("entryHash", prev_hash)
                    seq = int(last_entry.get("seq", 0)) + 1
                except Exception:
                    pass

    entry.setdefault("seq", seq)
    entry.setdefault("ts", datetime.now(timezone.utc).isoformat())
    entry["prevHash"] = f"sha256:{prev_hash}"

    # strip PII tokens before writing
    entry_str = json.dumps(entry, sort_keys=True)
    entry_str = re.sub(r"\[PII:[A-Z_]+:tok_[a-f0-9]+\]", "[PII:REDACTED]", entry_str)
    entry = json.loads(entry_str)

    hash_input = f"{entry['seq']}{entry['ts']}{json.dumps(entry, sort_keys=True)}{prev_hash}"
    entry_hash = hashlib.sha256(hash_input.encode()).hexdigest()
    entry["entryHash"] = f"sha256:{entry_hash}"

    with log_path.open("a") as f:
        f.write(json.dumps(entry) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
