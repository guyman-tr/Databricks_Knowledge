"""Re-scan Unity Catalog for column comment gaps across the DWH schemas.

Writes:
  - knowledge/_dwh_uc_gap_table_level.csv  (one row per UC table)
  - knowledge/_dwh_uc_gap_missing_cols.csv (one row per missing column)

Mapping source_schema -> (catalog, schema) is taken from the prior gap CSV
(if present) so the picker mirrors the original scan's scope.
"""
from __future__ import annotations

import csv
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def _connect():
    sys.path.insert(0, str(REPO / "tools"))
    from redeploy_schema import _connect_databricks  # type: ignore
    return _connect_databricks()


# Source-schema -> list of (uc_catalog, uc_schema) we need to scan. Built from
# the original gap CSV's distinct (catalog, schema) pairs observed per source.
SCAN_SCOPE = {
    "DWH_dbo": [("main", "dwh"), ("main", "bi_db"), ("main", "pii_data")],
    "BI_DB_dbo": [("main", "bi_db"), ("main", "pii_data")],
    "Dealing_dbo": [("main", "dealing"), ("main", "bi_db")],
    "eMoney_dbo": [("main", "emoney"), ("main", "bi_db")],
    "EXW_dbo": [("main", "exw"), ("main", "bi_db")],
    "EXW_Wallet": [("main", "exw_wallet"), ("main", "bi_db")],
}


def main() -> int:
    conn = _connect()
    if conn is None:
        return 3
    cur = conn.cursor()

    table_rows = []
    missing_rows = []

    for src, scopes in SCAN_SCOPE.items():
        token = src.replace("_dbo", "_dbo_").lower()
        token_prefix = f"gold_sql_dp_prod_we_{src.lower()}_"
        for catalog, schema in scopes:
            cur.execute(f"""
                SELECT
                  c.table_name,
                  c.column_name,
                  c.data_type,
                  c.comment
                FROM {catalog}.information_schema.columns c
                WHERE c.table_schema = '{schema}'
                  AND c.table_name LIKE '{token_prefix}%'
                ORDER BY c.table_name, c.ordinal_position
            """)
            rows = cur.fetchall()
            if not rows:
                continue

            by_table: dict[str, list[tuple[str, str, str | None]]] = {}
            for table_name, col, dtype, comment in rows:
                by_table.setdefault(table_name, []).append((col, dtype, comment))

            for table_name, cols in by_table.items():
                total = len(cols)
                commented = sum(1 for _, _, cm in cols if cm and cm.strip())
                missing = total - commented
                pct = round(commented * 100 / total, 1) if total else 0.0
                table_rows.append({
                    "source_schema": src,
                    "catalog": catalog,
                    "uc_schema": schema,
                    "uc_table": table_name,
                    "col_count": total,
                    "commented": commented,
                    "missing": missing,
                    "pct_commented": pct,
                })
                for col, dtype, comment in cols:
                    if not (comment and comment.strip()):
                        missing_rows.append({
                            "source_schema": src,
                            "uc_table": f"{catalog}.{schema}.{table_name}",
                            "column": col,
                            "data_type": dtype,
                        })

    cur.close()
    conn.close()

    out_table = REPO / "knowledge" / "_dwh_uc_gap_table_level.csv"
    out_missing = REPO / "knowledge" / "_dwh_uc_gap_missing_cols.csv"
    # Sort by missing desc
    table_rows.sort(key=lambda r: -r["missing"])
    with out_table.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(table_rows[0].keys()) if table_rows else
                            ["source_schema","catalog","uc_schema","uc_table",
                             "col_count","commented","missing","pct_commented"])
        w.writeheader()
        for r in table_rows:
            w.writerow(r)

    with out_missing.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source_schema","uc_table","column","data_type"])
        w.writeheader()
        for r in missing_rows:
            w.writerow(r)

    print(f"Wrote {out_table.relative_to(REPO)}  ({len(table_rows)} tables)")
    print(f"Wrote {out_missing.relative_to(REPO)}  ({len(missing_rows)} missing-col rows)")
    print()
    print("Summary by schema:")
    by_src = {}
    for r in table_rows:
        by_src.setdefault(r["source_schema"], []).append(r)
    for src in sorted(by_src):
        rs = by_src[src]
        total_miss = sum(r["missing"] for r in rs)
        total_cols = sum(r["col_count"] for r in rs)
        with_gap = sum(1 for r in rs if r["missing"] > 0)
        print(f"  {src:<13}  tables={len(rs):>4}  with_gap={with_gap:>4}  "
              f"missing_cols={total_miss:>5}  total_cols={total_cols:>6}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
