"""Snapshot DataPlatform OpsDB.dbo.ObjectsStatus to a CSV, filtered to Synapse-only objects.

Scope rule (per CTO clarification, 2026-04-26):
    Priority 0 entries in the service broker include data-lake orchestration paths
    (Bronze / Silver / Gold / external DBs). Those are NOT in scope for the
    sub-account Option 1 blast-radius analysis. Keep ONLY procedures whose
    schema-prefix lives in the Synapse SQL pool sql_dp_prod_we:
        BI_DB_dbo, BI_DB_staging,
        DWH_dbo, DWH_staging, DWH_pagetracking, DWH_watchlists,
        Dealing_dbo, Dealing_staging,
        eMoney_dbo,
        EXW_dbo, EXW_Wallet,
        DE_dbo, general, dbo

Output: knowledge/business/_objectsstatus_snapshot.csv
"""
import csv
import os
import sys
from pathlib import Path

import pyodbc

sys.stdout.reconfigure(line_buffering=True)

SERVER = "dbserver-dataplatform-prod-we.database.windows.net"
DATABASE = "opsdb-dataplatform-prod-we"
UID = "guyman@etoro.com"

OUT_CSV = Path(__file__).parent / "_objectsstatus_snapshot.csv"

SYNAPSE_SCHEMAS = (
    "BI_DB_dbo", "BI_DB_staging",
    "DWH_dbo", "DWH_staging", "DWH_pagetracking", "DWH_watchlists",
    "Dealing_dbo", "Dealing_staging",
    "eMoney_dbo",
    "EXW_dbo", "EXW_Wallet",
    "DE_dbo", "general", "dbo",
)


def connect():
    cs = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server={SERVER};"
        f"Database={DATABASE};"
        f"UID={UID};"
        "Authentication=ActiveDirectoryInteractive;"
        "Encrypt=yes;TrustServerCertificate=no;"
        "Connection Timeout=60;"
    )
    print(f"connecting to {SERVER}/{DATABASE} as {UID}...", flush=True)
    return pyodbc.connect(cs, timeout=60)


def main() -> int:
    in_clause = ",".join(f"'{s}'" for s in SYNAPSE_SCHEMAS)
    sql = f"""
        WITH base AS (
            SELECT
                ProcedureName,
                ISNULL(ProcessName, '') AS ProcessName,
                Priority,
                CAST(IsActive AS INT) AS IsActive
            FROM dbo.ObjectsStatus
            WHERE CHARINDEX('.', ProcedureName) > 0
              AND LEFT(ProcedureName, CHARINDEX('.', ProcedureName) - 1) IN ({in_clause})
        )
        SELECT
            ProcedureName,
            MAX(ProcessName) AS ProcessName,
            MAX(Priority)    AS Priority,
            MAX(IsActive)    AS IsActive
        FROM base
        GROUP BY ProcedureName
        ORDER BY Priority DESC, ProcedureName
    """

    conn = connect()
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    cols = [c[0] for c in cur.description]
    cur.close()
    conn.close()

    with OUT_CSV.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([*cols, "schema_prefix"])
        for r in rows:
            proc = r[0]
            schema = proc.split(".", 1)[0] if "." in proc else ""
            w.writerow([proc, r[1], r[2], r[3], schema])

    print(f"wrote {len(rows)} rows -> {OUT_CSV}", flush=True)

    by_pri = {}
    by_schema = {}
    for r in rows:
        by_pri[r[2]] = by_pri.get(r[2], 0) + 1
        sch = r[0].split(".", 1)[0]
        by_schema[sch] = by_schema.get(sch, 0) + 1

    print("\nby priority:", flush=True)
    for p in sorted(by_pri, reverse=True):
        print(f"  {p:>3}: {by_pri[p]:>4}", flush=True)

    print("\nby schema:", flush=True)
    for s in sorted(by_schema, key=lambda k: -by_schema[k]):
        print(f"  {s:<20s} {by_schema[s]:>4}", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
