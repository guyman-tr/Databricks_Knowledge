"""Apply canonical comments to recurring gold-pipeline-injected UC columns.

These columns are NOT in Synapse DDL — they are added by the gold-prod
spaceship pipeline when materializing Synapse tables into Unity Catalog.
Same physical column, same canonical semantic across every UC target.

This tool deploys those comments directly to UC without touching any wiki
(.md or .alter.sql) — they are UC-native metadata.
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


CANONICAL_COMMENTS = {
    "etr_y": (
        "Year partition value injected by the gold/spaceship pipeline. "
        "Equals YEAR(etr_ts). Used as Delta partition key in UC. "
        "(Pipeline-injected metadata; not present in Synapse source DDL.)"
    ),
    "etr_ym": (
        "Year-month partition value (YYYYMM as INT) injected by the gold/"
        "spaceship pipeline. Equals YEAR(etr_ts)*100 + MONTH(etr_ts). "
        "Used as Delta partition key for month-level pruning in UC. "
        "(Pipeline-injected metadata; not present in Synapse source DDL.)"
    ),
    "etr_ymd": (
        "Year-month-day partition value (YYYYMMDD as INT) injected by the "
        "gold/spaceship pipeline. Equals YEAR(etr_ts)*10000 + MONTH(etr_ts)"
        "*100 + DAY(etr_ts). Used as Delta partition key for day-level "
        "pruning in UC. (Pipeline-injected metadata; not present in "
        "Synapse source DDL.)"
    ),
    "etr_ts": (
        "Source row event timestamp captured by the gold/spaceship pipeline. "
        "Used as the basis for etr_y / etr_ym / etr_ymd partition columns. "
        "(Pipeline-injected metadata; not present in Synapse source DDL.)"
    ),
}


def _connect():
    sys.path.insert(0, str(REPO / "tools"))
    from redeploy_schema import _connect_databricks  # type: ignore
    return _connect_databricks()


def _q(s: str) -> str:
    return s.replace("'", "''")


def main() -> int:
    missing_csv = REPO / "knowledge" / "_dwh_uc_gap_missing_cols.csv"
    rows = list(csv.DictReader(missing_csv.open(encoding="utf-8")))
    # Filter to canonical cols
    targets = [
        r for r in rows if r["column"] in CANONICAL_COMMENTS
    ]
    print(f"Canonical cols to deploy: {len(targets)}")
    by_col = {}
    for r in targets:
        by_col.setdefault(r["column"], 0)
        by_col[r["column"]] += 1
    for c, n in sorted(by_col.items(), key=lambda x: -x[1]):
        print(f"  {n:>4}  {c}")

    if "--apply" not in sys.argv:
        print("\nDRY-RUN. Pass --apply to commit.")
        return 0

    conn = _connect()
    if conn is None:
        return 3
    cur = conn.cursor()

    report = REPO / "knowledge" / "_canonical_uc_cols_deploy_report.csv"
    ok = fail = 0
    with report.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "idx", "uc_target", "column", "status", "error",
        ])
        w.writeheader()
        for idx, r in enumerate(targets, 1):
            target = r["uc_table"]
            col = r["column"]
            comment_text = CANONICAL_COMMENTS[col]
            # Try ALTER TABLE first, fall back to COMMENT ON COLUMN (view)
            stmts = [
                f"ALTER TABLE {target} ALTER COLUMN {col} COMMENT '{_q(comment_text)}'",
                f"COMMENT ON COLUMN {target}.{col} IS '{_q(comment_text)}'",
            ]
            status, error = "FAIL", ""
            for stmt in stmts:
                try:
                    cur.execute(stmt)
                    status, error = "OK", ""
                    break
                except Exception as e:  # noqa: BLE001
                    error = str(e)[:300]
            if status == "OK":
                ok += 1
            else:
                fail += 1
            w.writerow({
                "idx": idx, "uc_target": target, "column": col,
                "status": status, "error": error,
            })
            if idx % 50 == 0 or status == "FAIL":
                print(f"  [{idx}/{len(targets)}] {status}  {target}.{col}"
                      + (f" -- {error[:120]}" if error else ""), flush=True)

    cur.close()
    conn.close()
    print(f"\nDONE  OK={ok}  FAIL={fail}")
    print(f"Report: {report.relative_to(REPO)}")
    return 0 if fail == 0 else 4


if __name__ == "__main__":
    sys.exit(main())
