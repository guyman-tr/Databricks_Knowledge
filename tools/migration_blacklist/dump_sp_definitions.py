"""Dump SP/View/Function definitions from sys.sql_modules in PROD Synapse for
the relevant schemas, so we can grep them for cross-table references.

Why: Synapse Dedicated SQL Pool's sys.sql_expression_dependencies has very
incomplete coverage for stored procedures (it mostly captures views/functions).
Source-level grep against sys.sql_modules is more reliable.

Output: audits/blacklist/_b_work/sp_definitions.csv
        columns: schema, name, object_type, definition
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

OUT_CSV = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "sp_definitions.csv"


def main() -> int:
    print("[defs] connecting to PROD synapse ...", flush=True)
    conn = sc.connect()
    print("[defs] connected", flush=True)

    sql = (
        "SELECT "
        "  OBJECT_SCHEMA_NAME(m.object_id) AS sch, "
        "  OBJECT_NAME(m.object_id)        AS name, "
        "  o.type_desc                     AS object_type, "
        "  m.definition                    AS definition "
        "FROM sys.sql_modules m "
        "JOIN sys.objects o ON o.object_id = m.object_id "
        "WHERE o.type IN ('P','V','FN','IF','TF') "
        "  AND OBJECT_SCHEMA_NAME(m.object_id) IN "
        "      ('BI_DB_dbo','Dealing_dbo','Dealing_staging','DWH_dbo','DWH_watchlists','DWH_pagetracking','eMoney_dbo','EXW_dbo','BI_DB_Migration','DE_dbo')"
    )
    cols, rows = run_query(conn, sql)
    print(f"[defs] fetched {len(rows)} object definitions", flush=True)

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["schema", "name", "object_type", "definition"])
        for r in rows:
            w.writerow([r[0] or "", r[1] or "", r[2] or "", r[3] or ""])
    size_mb = OUT_CSV.stat().st_size / 1024.0 / 1024.0
    print(f"[defs] wrote {OUT_CSV} ({size_mb:.1f} MB)", flush=True)

    types: dict[str, int] = {}
    for r in rows:
        types[r[2] or "?"] = types.get(r[2] or "?", 0) + 1
    print("[defs] by type:")
    for k, v in sorted(types.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
