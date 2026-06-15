"""
Deploy patched DBX sp_ddr_customer_daily_status to Unity Catalog.

Companion to REQ-25250 - adds final demotion UPDATE block for bad $1 FTD
cohort (Bug #2) on top of the previously-deployed aligned SP.
"""
import os
import sys
from pathlib import Path

try:
    from databricks import sql
except ImportError:
    print("pip install databricks-sql-connector", file=sys.stderr)
    sys.exit(1)


def main():
    repo_root = Path(__file__).resolve().parents[3]
    ddl_path = repo_root / "proposals" / "bad_ftd_cohort_2026_05" / "sp_ddr_customer_daily_status.aligned.sql"

    if not ddl_path.exists():
        print(f"DDL not found: {ddl_path}", file=sys.stderr)
        sys.exit(1)

    ddl = ddl_path.read_text(encoding="utf-8-sig")
    print(f"Loaded DDL: {len(ddl)} chars from {ddl_path}")

    host = os.environ.get("DATABRICKS_HOST") or os.environ.get("DBSQL_HOST")
    http_path = os.environ.get("DATABRICKS_HTTP_PATH") or os.environ.get("DBSQL_HTTP_PATH")
    token = os.environ.get("DATABRICKS_TOKEN") or os.environ.get("DBSQL_TOKEN")

    if not (host and http_path and token):
        print("Missing DATABRICKS_HOST / DATABRICKS_HTTP_PATH / DATABRICKS_TOKEN", file=sys.stderr)
        sys.exit(2)

    print(f"Connecting to {host} {http_path}...")
    with sql.connect(server_hostname=host, http_path=http_path, access_token=token) as conn:
        with conn.cursor() as cur:
            print("Executing CREATE OR REPLACE PROCEDURE ...")
            cur.execute(ddl)
            print("OK")

            cur.execute("DESCRIBE PROCEDURE main.de_output.sp_ddr_customer_daily_status")
            rows = cur.fetchall()
            for r in rows[:5]:
                print(r)


if __name__ == "__main__":
    main()
