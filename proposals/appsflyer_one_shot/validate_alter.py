"""Validate every ALTER COLUMN comment in an alter.sql against the UC 1024-char limit."""
from __future__ import annotations
import re
import sys
from pathlib import Path


def check(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    overlong: list[tuple[str, int]] = []
    pattern = re.compile(r"ALTER COLUMN (\w+) COMMENT '((?:[^']|'')*)';", re.MULTILINE)
    n_total = 0
    for m in pattern.finditer(text):
        n_total += 1
        col = m.group(1)
        body = m.group(2).replace("''", "'")
        if len(body) > 1024:
            overlong.append((col, len(body)))
    print(f"{path.name}: {n_total} column comments")
    if overlong:
        print(f"  OVER 1024 chars on {len(overlong)} column(s):")
        for col, n in overlong:
            print(f"    {col}: {n}")
        return 1
    print("  all <= 1024 chars (OK)")
    return 0


if __name__ == "__main__":
    rc = 0
    for arg in sys.argv[1:]:
        rc |= check(Path(arg))
    sys.exit(rc)
