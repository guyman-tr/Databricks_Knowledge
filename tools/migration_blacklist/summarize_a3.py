"""Print a quick summary of the latest Phase A3 review CSV."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
A3_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"


def main() -> int:
    rows = list(csv.DictReader(A3_CSV.open("r", encoding="utf-8-sig")))
    total = len(rows)

    print("=== A3 verdict distribution ===")
    verdicts: dict[str, int] = {}
    for r in rows:
        verdicts[r["verdict"]] = verdicts.get(r["verdict"], 0) + 1
    for k, v in sorted(verdicts.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}  ({100*v/total:5.1f}%)")

    print()
    print("=== Top 20 stalest (non-KEEP) ===")
    stale = [r for r in rows if r["verdict"] != "KEEP" and r["days_stale"]]
    stale.sort(key=lambda r: -float(r["days_stale"]))
    print(f"{'verdict':22s} {'days':6s}  {'freq':10s}  {'method':12s} TableName")
    for r in stale[:20]:
        print(
            f"{r['verdict']:22s} {float(r['days_stale']):6.0f}  "
            f"{r['FrequencySP']:10s}  {r['freshness_method']:12s} {r['TableName']}"
        )

    print()
    print("=== A3_TABLE_MISSING (proc writes to a table not in sys.objects) ===")
    for r in rows:
        if r["verdict"] == "A3_TABLE_MISSING":
            print(f"  {r['ProcedureName']} -> {r['TableName']} (freq={r['FrequencySP']})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
