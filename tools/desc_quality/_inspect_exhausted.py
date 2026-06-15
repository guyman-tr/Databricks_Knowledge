"""Inspect remaining exhausted rows in the latest rewrite report."""
from __future__ import annotations

import csv
import sys
from collections import Counter
from pathlib import Path


def main(argv: list[str]) -> int:
    path = (
        argv[1]
        if len(argv) > 1
        else "audits/_desc_quality_rewrite_corpus2/report.csv"
    )
    rows = list(csv.DictReader(open(path, encoding="utf-8")))
    exhausted = [r for r in rows if r["status"] == "EXHAUSTED"]
    print(f"Total exhausted: {len(exhausted)}")
    print()
    for r in exhausted:
        wiki = r["wiki_path"].split("/")[-1]
        print(
            f"  {wiki:55s} {r['column']:30s} "
            f"src={r['source']!r:55s} reason={r['exhausted_reason']}"
        )
    print()
    print("Reason histogram:")
    for k, v in Counter(r["exhausted_reason"] for r in exhausted).most_common():
        print(f"  {v:>4}  {k}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
