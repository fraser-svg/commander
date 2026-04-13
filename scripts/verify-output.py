#!/usr/bin/env python3
"""
verify-output.py — CaMeL Layer C output verifier
Scans agent output for secrets, PII token leakage, data-class violations.
Usage: verify-output.py <output-file> [--dataclass public|internal|sensitive|pii]
Exit 0 = clean. Non-zero = blocked.
"""

import re
import sys
from pathlib import Path

SECRET_PATTERNS = [
    (r"AKIA[0-9A-Z]{16}", "AWS access key"),
    (r"ghp_[0-9A-Za-z]{36}", "GitHub PAT"),
    (r"sk-ant-[A-Za-z0-9-]{32,}", "Anthropic API key"),
    (r"sk-[A-Za-z0-9]{48}", "OpenAI-style key"),
    (r"-----BEGIN (RSA |OPENSSH |EC |DSA |)PRIVATE KEY-----", "Private key"),
]

DATACLASS_ORDER = {"public": 0, "internal": 1, "sensitive": 2, "pii": 3}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: verify-output.py <output-file> [--dataclass CLASS]", file=sys.stderr)
        return 2
    fpath = Path(sys.argv[1])
    if not fpath.exists():
        print(f"verify-output: file not found: {fpath}", file=sys.stderr)
        return 1

    dataclass = "internal"
    if "--dataclass" in sys.argv:
        idx = sys.argv.index("--dataclass")
        dataclass = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else "internal"

    content = fpath.read_text(errors="ignore")

    hits = 0
    for pat, label in SECRET_PATTERNS:
        if re.search(pat, content):
            print(f"verify-output: BLOCKED {label} found in {fpath}", file=sys.stderr)
            hits += 1

    if "[PII:" in content and dataclass in ("public", "internal"):
        print(f"verify-output: WARN PII token leakage in output scoped {dataclass}", file=sys.stderr)

    size_kb = fpath.stat().st_size / 1024
    if size_kb > 100:
        print(f"verify-output: flag oversized output {size_kb:.0f}KB", file=sys.stderr)

    if hits > 0:
        return 1
    print(f"verify-output: OK ({fpath}, {size_kb:.1f}KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
