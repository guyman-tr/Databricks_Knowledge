"""Dump sys.tables.modify_date for the three schemas in our keep-universe.

Writes audits/blacklist/_a3_work/modify_dates.csv directly via pyodbc, no MCP
truncation.
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

OUT_CSV = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "modify_dates.csv"


def main() -> int:
    print("[modify] connecting to PROD synapse ...", flush=True)
    conn = sc.connect()
    print("[modify] connected", flush=True)

    sql = (
        "SELECT SCHEMA_NAME(o.schema_id) AS schema_name, "
        "       o.name AS table_name, "
        "       o.type_desc AS object_type, "
        "       CONVERT(varchar(20), o.create_date, 120) AS create_date, "
        "       CONVERT(varchar(20), o.modify_date, 120) AS modify_date "
        "FROM sys.objects o "
        "WHERE SCHEMA_NAME(o.schema_id) IN ('BI_DB_dbo', 'Dealing_dbo', 'Dealing_staging') "
        "  AND o.type IN ('U','V') "
        "ORDER BY SCHEMA_NAME(o.schema_id), o.name"
    )
    cols, rows = run_query(conn, sql)
    print(f"[modify] fetched {len(rows)} objects", flush=True)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["schema", "table_name", "object_type", "create_date", "modify_date"])
        for r in rows:
            w.writerow([r[0], r[1], r[2], r[3] or "", r[4] or ""])
    print(f"[modify] wrote {OUT_CSV}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
