#!/usr/bin/env python3
"""
sanitize-input.py — CaMeL Layer A input sanitizer
Redacts PII and strips prompt-injection prefixes before agent sees user input.
Usage: sanitize-input.py [--strict] <input-file>
Writes sanitized text to _workspace/sanitized-input.txt and token map to
_workspace/pii-tokens.json. Exit non-zero in --strict mode if PII found.
"""

import json
import os
import re
import sys
import hashlib
from pathlib import Path

# Minimal PII patterns. Full list lives in pii-patterns.json once loaded.
DEFAULT_PATTERNS = {
    "EMAIL": r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    "PHONE": r"\+?\d[\d\s\-().]{8,}\d",
    "SSN": r"\b\d{3}-\d{2}-\d{4}\b",
    "CREDITCARD": r"\b(?:\d[ -]*?){13,16}\b",
    "AWS_KEY": r"AKIA[0-9A-Z]{16}",
    "GH_PAT": r"ghp_[0-9A-Za-z]{36}",
    "ANTHROPIC_KEY": r"sk-ant-[A-Za-z0-9-]{32,}",
}

INJECTION_PREFIXES = [
    r"ignore (all )?previous instructions",
    r"disregard (all )?previous",
    r"you are now (a |an |the )?",
    r"\bDAN\b",
    r"system:",
    r"<\|.*?\|>",
]

CONTROL_CHARS = re.compile(r"[\x00\x1b\u202e\u202d]")


def tokenize(match_text: str, label: str) -> str:
    h = hashlib.sha256(match_text.encode()).hexdigest()[:8]
    return f"[PII:{label}:tok_{h}]"


def main() -> int:
    strict = False
    args = [a for a in sys.argv[1:]]
    if "--strict" in args:
        strict = True
        args.remove("--strict")
    if not args:
        print("usage: sanitize-input.py [--strict] <input-file>", file=sys.stderr)
        return 2
    input_path = Path(args[0])
    if not input_path.exists():
        print(f"sanitize-input: file not found: {input_path}", file=sys.stderr)
        return 1

    text = input_path.read_text()
    original_len = len(text)
    found = 0
    token_map = {}

    patterns_file = Path(__file__).parent / "pii-patterns.json"
    patterns = DEFAULT_PATTERNS
    if patterns_file.exists():
        try:
            patterns = json.loads(patterns_file.read_text())
        except Exception:
            pass

    for label, pattern in patterns.items():
        for m in re.finditer(pattern, text):
            raw = m.group(0)
            tok = tokenize(raw, label)
            token_map[tok] = raw
            text = text.replace(raw, tok)
            found += 1

    for pat in INJECTION_PREFIXES:
        text = re.sub(pat, "[STRIPPED:INJECTION]", text, flags=re.IGNORECASE)

    text = CONTROL_CHARS.sub("", text)

    ws = Path.cwd() / "_workspace"
    ws.mkdir(exist_ok=True)
    (ws / "sanitized-input.txt").write_text(text)
    (ws / "pii-tokens.json").write_text(json.dumps(token_map, indent=2))

    print(f"sanitize-input: {found} PII match(es), {original_len}→{len(text)} chars")
    if strict and found > 0:
        print("sanitize-input: STRICT mode + PII found → halt", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
