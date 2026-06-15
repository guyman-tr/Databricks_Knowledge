"""Deploy Phase-1 high-confidence wiki §4 descriptions to UC.

Scope: rows in audits/_weakness_inventory/phase1_auto_deploy_wiki.csv where
  - UC column is currently empty
  - Wiki §4 has a non-trivial row authored for THIS exact table

Safety:
  - Re-fetches live UC comment per column; SKIPs if non-empty (someone else
    deployed since the inventory was built).
  - SKIPs UNRESOLVED_COLUMN errors (column doesn't exist in this object).
  - Logs every action with full before/after preview.
  - --dry-run mode shows what would happen without touching UC.

Auth: PAT via DATABRICKS_TOKEN, or SDK profile (default 'guyman').
"""
from __future__ import annotations
import argparse
import csv
import os
import sys
from pathlib import Path

DBX_HOST = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "audits" / "_weakness_inventory" / "phase1_auto_deploy_wiki.csv"


def esc_sql(text: str) -> str:
    return text.replace("'", "''")


def quote_col(col: str) -> str:
    """Backtick-quote column name if it contains characters that need escaping
    in Spark SQL (e.g. '$', '+', spaces, hyphens)."""
    if any(c in col for c in "$+ -.()"):
        # Backslash-escape any literal backticks (paranoia; never seen in our names)
        return "`" + col.replace("`", "``") + "`"
    return col


def open_connection():
    from databricks import sql
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)")
        return sql.connect(server_hostname=DBX_HOST, http_path=DBX_HTTP_PATH, access_token=token)
    from databricks.sdk import WorkspaceClient
    profile = os.environ.get("DATABRICKS_MCP_PROFILE", "guyman")
    print(f"Auth: SDK profile '{profile}'")
    wc = WorkspaceClient(profile=profile)
    return sql.connect(
        server_hostname=DBX_HOST,
        http_path=DBX_HTTP_PATH,
        credentials_provider=lambda: wc.config.authenticate,
    )


def fetch_current(cur, schema, table, col):
    q = (
        f"SELECT comment FROM system.information_schema.columns "
        f"WHERE table_catalog='main' AND table_schema='{esc_sql(schema)}' "
        f"AND table_name='{esc_sql(table)}' "
        f"AND lower(column_name)=lower('{esc_sql(col)}')"
    )
    cur.execute(q)
    row = cur.fetchone()
    return (row[0] if row and row[0] else "") if row else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--limit", type=int, default=0,
                    help="Only attempt the first N rows (sanity)")
    args = ap.parse_args()
    if not args.dry_run and not args.apply:
        print("Specify --dry-run or --apply")
        return 2

    rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))
    if args.limit:
        rows = rows[: args.limit]
    print(f"Targets: {len(rows)} rows from {CSV_PATH.relative_to(ROOT)}")

    print(f"Connecting to {DBX_HOST}...")
    conn = open_connection()
    cur = conn.cursor()
    print("Connected.\n")

    applied = skipped = failed = race = 0
    for r in rows:
        sch = r["schema"]
        tbl = r["table"]
        col = r["column"]
        proposed = (r["proposed_comment"] or "").strip()
        fqn = f"main.{sch}.{tbl}"

        if not proposed:
            print(f"  SKIP   {fqn}.{col}   empty proposed_comment")
            skipped += 1
            continue

        try:
            current = fetch_current(cur, sch, tbl, col)
        except Exception as e:
            print(f"  FAIL   {fqn}.{col}   fetch failed: {e}")
            failed += 1
            continue

        if current is None:
            print(f"  SKIP   {fqn}.{col}   column not found")
            skipped += 1
            continue
        if current.strip():
            # Race: someone else populated this since the inventory ran.
            race += 1
            print(f"  RACE   {fqn}.{col}   already populated, skipping")
            continue

        if args.dry_run:
            print(f"  DRY    {fqn}.{col}  (len={len(proposed)})")
            print(f"         {proposed[:200]}{'...' if len(proposed) > 200 else ''}")
            applied += 1
            continue

        stmt = f"COMMENT ON COLUMN {fqn}.{quote_col(col)} IS '{esc_sql(proposed)}'"
        try:
            cur.execute(stmt)
            applied += 1
            print(f"  OK     {fqn}.{col}   len={len(proposed)}")
        except Exception as e:
            err = str(e)[:200]
            if "UNRESOLVED_COLUMN" in err or "Cannot resolve column" in err:
                skipped += 1
                print(f"  SKIP   {fqn}.{col}   UNRESOLVED_COLUMN (column not exposed)")
            else:
                failed += 1
                print(f"  FAIL   {fqn}.{col}   {err}")

    print()
    print(f"Applied: {applied}   Race: {race}   Skipped: {skipped}   Failed: {failed}")
    cur.close()
    conn.close()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
