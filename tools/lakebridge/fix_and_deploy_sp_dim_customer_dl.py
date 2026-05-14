"""Sister script to fix_and_deploy_sp_dim_customer.py for the upstream loader
SP_Dim_Customer_DL_To_Synapse which populates the 14 Ext_Dim_Customer_*
tables in dwh_daily_process.migration_tables from the daily_snapshot tier.

Adds one extra transformation on top of the shared fixers:

    SELECT <cols> INTO <name> FROM <body>
        --> CREATE OR REPLACE TEMPORARY VIEW <name> AS SELECT <cols> FROM <body>

Walks the SQL once, finds each `INTO <ident> FROM` occurrence inside a SELECT
statement, locates the start of that statement, and rewrites it.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path

# Reuse the existing fixers.
sys.path.insert(0, str(Path(__file__).parent))
import fix_and_deploy_sp_dim_customer as base


SRC = Path(r"C:\Users\guyman\Desktop\lakebridge_transplier_v3\Stored Procedures\DWH_dbo.SP_Dim_Customer_DL_To_Synapse.sql")
OUT = Path(r"C:\Users\guyman\Desktop\sp_dim_customer_dl_fixed.sql")


def rewrite_select_into(body: str) -> str:
    """Convert `[WITH ... ] SELECT ... INTO <ident> FROM ... ;`
    into `CREATE OR REPLACE TEMPORARY VIEW <ident> AS <WITH..><SELECT..>;`.
    """
    pat = re.compile(r"\bINTO\s+(\w+)\s+FROM\b", re.IGNORECASE)
    out_chunks: list[str] = []
    cursor = 0
    seen_starts: set[int] = set()

    while True:
        m = pat.search(body, cursor)
        if not m:
            out_chunks.append(body[cursor:])
            break

        # Walk backwards to find the start of the statement: the position
        # right after the most recent `;` (or the start of body).
        start = m.start()
        i = start - 1
        while i >= 0 and body[i] != ";":
            i -= 1
        stmt_start = i + 1  # right after the `;` (or start of body if i==-1)

        # Skip whitespace at statement start.
        while stmt_start < start and body[stmt_start] in " \t\r\n":
            stmt_start += 1

        # Ensure this statement actually begins with WITH or SELECT.
        head = body[stmt_start:stmt_start + 7].upper().lstrip()
        if not (head.startswith("WITH") or head.startswith("SELECT")):
            out_chunks.append(body[cursor:m.end()])
            cursor = m.end()
            continue

        if stmt_start in seen_starts:
            out_chunks.append(body[cursor:m.end()])
            cursor = m.end()
            continue
        seen_starts.add(stmt_start)

        view_name = m.group(1)
        # Append everything up to the statement start unchanged.
        out_chunks.append(body[cursor:stmt_start])
        # Prepend CREATE TEMPORARY VIEW.
        out_chunks.append(f"CREATE OR REPLACE TEMPORARY VIEW {view_name} AS\n")
        # Append from statement start up to the INTO clause.
        out_chunks.append(body[stmt_start:m.start()])
        # Skip the `INTO <name> ` part, keep `FROM` onwards.
        out_chunks.append("FROM")
        cursor = m.end()

    return "".join(out_chunks)


def fix(text: str) -> str:
    body = base.fix(text)
    body = rewrite_select_into(body)
    return body


def main() -> int:
    token = base.fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    print("Loading column types from UC...", flush=True)
    base.set_column_types(base._load_column_types(conn))
    base.set_bool_vs_int_columns(base._load_type_mismatch_columns(conn))
    print(f"  loaded types")

    raw = SRC.read_text(encoding="utf-8-sig", errors="replace")
    fixed = fix(raw)
    OUT.write_text(fixed, encoding="utf-8", newline="\n")
    print(f"Fixed SQL written to: {OUT}")

    body = re.sub(r"^\s*USE\s+CATALOG\s+\w+\s*;\s*", "", fixed, count=1, flags=re.IGNORECASE)
    body = re.sub(r"^\s*USE\s+SCHEMA\s+\w+\s*;\s*", "", body, count=1, flags=re.IGNORECASE)
    body = body.strip().rstrip(";").strip()
    Path(r"C:\Users\guyman\Desktop\sp_dim_customer_dl_body.sql").write_text(body, encoding="utf-8", newline="\n")

    cur = conn.cursor()
    cur.execute("USE CATALOG dwh_daily_process")
    cur.execute("USE SCHEMA migration_tables")
    print("Deploying ...", flush=True)
    t0 = time.time()
    try:
        cur.execute(body)
    except Exception as exc:
        elapsed = int((time.time() - t0) * 1000)
        print(f"FAILED after {elapsed}ms:")
        print(str(exc)[:1500])
        return 2
    elapsed = int((time.time() - t0) * 1000)
    print(f"Deployed in {elapsed}ms.")

    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
