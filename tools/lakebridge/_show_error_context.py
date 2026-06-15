"""For each failed SP, print the line+near context from the bulk fix output
so we can see exactly where the parser blew up."""
import csv
import re
from pathlib import Path

OUT_DIR = Path(__file__).parent / "bulk_fix_output"

# Read residual failures.
rows = [
    r for r in csv.DictReader(
        open(Path(__file__).parent / "bulk_fix_deploy_report.csv", encoding="utf-8")
    )
    if r["status"] == "error"
]


def parse_loc(err: str) -> tuple[int | None, int | None, str]:
    m = re.search(r"line (\d+), pos (\d+)", err or "")
    if m:
        return int(m.group(1)), int(m.group(2)), err
    return None, None, err


def main():
    import sys
    only = set(a.lower() for a in sys.argv[1:])
    for r in rows:
        name = Path(r["rel"]).name
        if only and not any(o in name.lower() for o in only):
            continue
        line, pos, err = parse_loc(r["error"])
        m = re.search(r"near '([^']*)'", err or "")
        near = m.group(1) if m else "?"
        fp = OUT_DIR / name
        if not fp.exists():
            print(f"\n=== {name} (NO FIXED FILE) ===")
            continue
        lines = fp.read_text(encoding="utf-8").splitlines()
        # The deployed body strips USE headers (first 2 lines plus blanks).
        # Find the offset where CREATE PROCEDURE starts in the fixed file
        # and apply it.
        offset = 0
        for i, ln in enumerate(lines):
            if re.match(r"\s*CREATE\s+OR\s+REPLACE\s+PROCEDURE", ln, re.IGNORECASE):
                offset = i
                break
        print(f"\n=== {name}  (near '{near}', line {line}, pos {pos}) ===")
        if line is not None:
            actual = offset + line - 1
            lo = max(0, actual - 3)
            hi = min(len(lines), actual + 3)
            for j in range(lo, hi):
                marker = ">>>" if j == actual else "   "
                print(f"  {marker} {j + 1:4d}| {lines[j]}")


if __name__ == "__main__":
    main()
