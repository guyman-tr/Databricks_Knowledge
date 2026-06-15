"""Dump SP -> referenced tables/views from sys.sql_expression_dependencies.

Used to build the SP-to-SP feeder graph in Phase B: a surviving table is an
"internal feeder" if some procedure in the keep universe READS from it AND
that procedure's output is consumed by Tableau.

Output: audits/blacklist/_b_work/sp_dependencies.csv
        columns: referencing_proc, referencing_schema, referenced_object, referenced_schema,
                 referenced_db, is_resolved
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import synapse_connect as sc  # noqa: E402
from synapse_connect import run_query  # noqa: E402

sc.SERVER   = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
sc.DATABASE = "sql_dp_prod_we"

OUT_CSV = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "sp_dependencies.csv"


def main() -> int:
    print("[deps] connecting to PROD synapse ...", flush=True)
    conn = sc.connect()
    print("[deps] connected", flush=True)

    sql = (
        "SELECT "
        "  OBJECT_SCHEMA_NAME(d.referencing_id)               AS referencing_schema, "
        "  OBJECT_NAME(d.referencing_id)                      AS referencing_proc, "
        "  d.referenced_database_name                         AS referenced_db, "
        "  d.referenced_schema_name                           AS referenced_schema, "
        "  d.referenced_entity_name                           AS referenced_object, "
        "  CAST(d.is_ambiguous AS int)                        AS is_ambiguous "
        "FROM sys.sql_expression_dependencies d "
        "JOIN sys.objects o ON o.object_id = d.referencing_id "
        "WHERE o.type IN ('P','V','FN','IF','TF') "
        "  AND OBJECT_SCHEMA_NAME(d.referencing_id) IN "
        "      ('BI_DB_dbo','Dealing_dbo','Dealing_staging','DWH_dbo','DWH_watchlists','DWH_pagetracking','eMoney_dbo','EXW_dbo','BI_DB_Migration','DE_dbo')"
    )
    cols, rows = run_query(conn, sql)
    print(f"[deps] fetched {len(rows)} dependency rows", flush=True)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["referencing_schema", "referencing_proc", "referenced_db",
                    "referenced_schema", "referenced_object", "is_ambiguous"])
        for r in rows:
            w.writerow([
                r[0] or "",
                r[1] or "",
                r[2] or "",
                r[3] or "",
                r[4] or "",
                r[5] or 0,
            ])
    print(f"[deps] wrote {OUT_CSV}", flush=True)

    distinct_procs   = len({(r[0], r[1]) for r in rows})
    distinct_objects = len({(r[3], r[4]) for r in rows})
    print(f"[deps] distinct referencing procs:    {distinct_procs}")
    print(f"[deps] distinct referenced objects:   {distinct_objects}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
