"""One-shot helper: reset `Failed` rows to `Generated` in a bronze deploy-index,
and re-balance frontmatter counters. Used to redo Failed batches after preflight
auto-fixes resolve text-level issues.

Usage:
    python tools/_tmp_reset_failed_to_generated.py knowledge/ProdSchemas/.../<db>/_deploy-index.md ...
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


ROW_RE = re.compile(
    r"^(\|\s*\[[^\]]+\]\([^)]+\)\s*\|\s*`[^`]+`\s*\|\s*)([^|]+?)(\s*\|\s*)$"
)


def reset_one(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    n_reset = 0
    out: list[str] = []
    for line in lines:
        m = ROW_RE.match(line)
        if not m:
            out.append(line)
            continue
        prefix, status, suffix = m.group(1), m.group(2).strip(), m.group(3)
        if status.startswith("Failed"):
            out.append(prefix + "Generated" + suffix)
            n_reset += 1
        else:
            out.append(line)
    new_text = "\n".join(out) + ("\n" if text.endswith("\n") else "")

    # Recount from rows
    g = d = f = 0
    for line in out:
        m = ROW_RE.match(line)
        if not m:
            continue
        s = m.group(2).strip()
        if s.startswith("Deployed"):
            d += 1
        elif s.startswith("Failed"):
            f += 1
        else:
            g += 1

    new_text = re.sub(r"^generated:\s*\d+", f"generated: {g}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^deployed:\s*\d+", f"deployed: {d}", new_text, count=1, flags=re.MULTILINE)
    new_text = re.sub(r"^failed:\s*\d+", f"failed: {f}", new_text, count=1, flags=re.MULTILINE)

    path.write_text(new_text, encoding="utf-8")
    return {"path": str(path), "reset": n_reset, "generated": g, "deployed": d, "failed": f}


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    for arg in sys.argv[1:]:
        p = Path(arg)
        if not p.is_file():
            print(f"SKIP not a file: {p}")
            continue
        r = reset_one(p)
        print(
            f"  {r['path']}: reset={r['reset']} -> "
            f"generated={r['generated']} deployed={r['deployed']} failed={r['failed']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
