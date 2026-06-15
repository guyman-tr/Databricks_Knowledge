"""Deploy converged column comments to Unity Catalog.

Reads audits/_convergence_gap/proposed_converged.csv and issues
COMMENT ON COLUMN ... IS '...' for each row whose `converged` differs
from the currently-deployed comment.

Auth: same as tools/apply_tvf_col_comments.py — PAT via DATABRICKS_TOKEN
if set, else WorkspaceClient profile (DATABRICKS_MCP_PROFILE, default 'guyman').

Modes:
  --dry-run   : print what we'd send, no execution
  --apply     : actually execute against UC
  --only-rules X,Y : only deploy rows whose rules_fired contains any of X/Y
"""
from __future__ import annotations
import argparse
import csv
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "audits" / "_convergence_gap" / "proposed_converged.csv"

DBX_HOST = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

# View/TVF tables that map column comments differently — TVFs need
# CREATE OR REPLACE FUNCTION, views & tables accept COMMENT ON COLUMN.
TVF_FQNS = {
    "main.etoro_kpi_prep.tvf_pnl_single_day",
}

MAX_COMMENT = 500


def esc_sql(text: str) -> str:
    return text.replace("'", "''")


def truncate(text: str, limit: int = MAX_COMMENT) -> str:
    return text if len(text) <= limit else text[: limit - 3] + "..."


def fetch_current_comment(cursor, uc_fqn: str, col: str) -> str | None:
    catalog, schema, table = uc_fqn.split(".")
    q = (
        f"SELECT comment FROM system.information_schema.columns "
        f"WHERE table_catalog = '{esc_sql(catalog)}' "
        f"AND table_schema = '{esc_sql(schema)}' "
        f"AND table_name = '{esc_sql(table)}' "
        f"AND lower(column_name) = lower('{esc_sql(col)}')"
    )
    cursor.execute(q)
    row = cursor.fetchone()
    return row[0] if row else None


def build_alter(uc_fqn: str, column: str, comment: str) -> str:
    return f"COMMENT ON COLUMN {uc_fqn}.{column} IS '{esc_sql(comment)}'"


def open_connection():
    from databricks import sql
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)")
        return sql.connect(
            server_hostname=DBX_HOST,
            http_path=DBX_HTTP_PATH,
            access_token=token,
        )
    from databricks.sdk import WorkspaceClient
    profile = os.environ.get("DATABRICKS_MCP_PROFILE", "guyman")
    print(f"Auth: SDK profile '{profile}'")
    wc = WorkspaceClient(profile=profile)

    def _cp():
        return wc.config.authenticate

    return sql.connect(
        server_hostname=DBX_HOST,
        http_path=DBX_HTTP_PATH,
        credentials_provider=_cp,
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only-rules", help="Comma-separated list of rule names to include")
    ap.add_argument("--only-column", help="Only deploy rows whose column matches (case-insensitive)")
    ap.add_argument("--src", default=str(SRC), help="Path to proposed_converged.csv")
    args = ap.parse_args()

    if not args.dry_run and not args.apply:
        print("Specify --dry-run or --apply")
        return 2

    rule_filter = None
    if args.only_rules:
        rule_filter = {r.strip() for r in args.only_rules.split(",") if r.strip()}

    rows = list(csv.DictReader(open(args.src, encoding="utf-8")))

    if rule_filter:
        rows = [r for r in rows
                if any(rf in r["rules_fired"] for rf in rule_filter)]
    if args.only_column:
        rows = [r for r in rows
                if r["column"].lower() == args.only_column.lower()]

    # We keep rows where rules_fired == NONE because the source-of-truth wiki
    # cell may have been edited (e.g. Tier 5 corrections) without the converger
    # selecting a different sibling — the live UC comment may still differ.
    # The per-row diff check below catches genuine noops.
    print(f"Rows to deploy: {len(rows)}")
    if not rows:
        return 0

    conn = cur = None
    if args.apply:
        print(f"Connecting to {DBX_HOST}...")
        conn = open_connection()
        cur = conn.cursor()
        print("Connected.\n")

    applied = skipped = failed = 0
    for r in rows:
        uc_fqn = r["uc_fqn"]
        column = r["column"]
        converged = truncate(r["converged"])

        if uc_fqn in TVF_FQNS:
            print(f"  SKIP   {uc_fqn}.{column}   reason: TVF (needs CREATE OR REPLACE FUNCTION)")
            skipped += 1
            continue

        if args.dry_run:
            print(f"  DRY    {uc_fqn}.{column}   ({r['rules_fired']})")
            print(f"         {converged[:140]}{'...' if len(converged) > 140 else ''}")
            applied += 1
            continue

        # Real apply: fetch current, compare, only execute if different
        try:
            current = fetch_current_comment(cur, uc_fqn, column)
        except Exception as e:
            print(f"  FAIL   {uc_fqn}.{column}   info_schema fetch failed: {e}")
            failed += 1
            continue

        if (current or "").strip() == converged.strip():
            print(f"  NOOP   {uc_fqn}.{column}   already matches converged text")
            skipped += 1
            continue

        sql_stmt = build_alter(uc_fqn, column, converged)
        try:
            cur.execute(sql_stmt)
            applied += 1
            print(f"  OK     {uc_fqn}.{column}   ({r['rules_fired']})")
        except Exception as e:
            msg = str(e)[:200]
            if "UNRESOLVED_COLUMN" in msg:
                skipped += 1
                print(f"  SKIP   {uc_fqn}.{column}   column not in view")
            else:
                failed += 1
                print(f"  FAIL   {uc_fqn}.{column}   {msg}")

    print(f"\nApplied: {applied}  Skipped: {skipped}  Failed: {failed}")
    if cur:
        cur.close()
    if conn:
        conn.close()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
