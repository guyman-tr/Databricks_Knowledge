"""Summarize the Phase B CSV: verdict distribution + top dead candidates +
feeder-protected list."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
B_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_b_2026-05-31.csv"


def main() -> int:
    rows = list(csv.DictReader(B_CSV.open("r", encoding="utf-8-sig")))
    total = len(rows)

    print(f"=== Phase B verdict distribution ({total} surviving rows) ===")
    counts: dict[str, int] = {}
    for r in rows:
        counts[r["verdict"]] = counts.get(r["verdict"], 0) + 1
    for k, v in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}  ({100*v/total:5.1f}%)")

    print()
    print("=== Top 15 B_NO_TABLEAU_CONSUMER (sample for sanity check) ===")
    nodbash = [r for r in rows if r["verdict"] == "B_NO_TABLEAU_CONSUMER"]
    nodbash.sort(key=lambda r: r["TableName"])
    for r in nodbash[:15]:
        print(f"  {r['TableName']:60s} freq={r['FrequencySP']:10s} max_update={r['max_update']}")

    print()
    print("=== B_FEEDER_KEEP tables (protected by feeder graph) ===")
    feeders = [r for r in rows if r["verdict"] == "B_FEEDER_KEEP"]
    for r in feeders:
        print(f"  {r['TableName']:60s} ({r['ProcedureName']})")

    print()
    print("=== B_NEVER_VIEWED (workbook exists but lifetime views = 0) ===")
    for r in rows:
        if r["verdict"] == "B_NEVER_VIEWED":
            print(f"  {r['TableName']:60s} workbooks={r['tableau_workbooks']} newest_wb={r['newest_wb_updated']}")

    print()
    print("=== B_LOW_USE_STALE (low total_views + workbook >1y old) ===")
    for r in rows:
        if r["verdict"] == "B_LOW_USE_STALE":
            print(f"  {r['TableName']:60s} workbooks={r['tableau_workbooks']} total_views={r['total_views_sum']} wb_age={r['newest_wb_age_days']}d")

    print()
    print("=== KEEP rows by Tableau usage (top 10 by total_views) ===")
    keep_rows = [r for r in rows if r["verdict"] == "KEEP"]
    keep_rows.sort(key=lambda r: -int(r["total_views_sum"] or 0))
    for r in keep_rows[:10]:
        print(f"  {r['TableName']:60s} workbooks={r['tableau_workbooks']:>3s}  total_views={r['total_views_sum']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
