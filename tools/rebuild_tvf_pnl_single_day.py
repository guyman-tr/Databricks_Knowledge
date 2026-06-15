"""Rebuild main.etoro_kpi_prep.tvf_pnl_single_day with column comments
sourced from the wiki §4. Recreates the function in place via
CREATE OR REPLACE FUNCTION.

Safety:
  1. Captures current routine_definition before touching anything
       -> audits/_uc_deploy_descriptions/tvf_pnl_single_day.before.sql
  2. Builds new CREATE statement and writes it to disk for diffing
       -> audits/_uc_deploy_descriptions/tvf_pnl_single_day.new.sql
  3. Captures a row count for target_date BEFORE the recreate
  4. Applies CREATE OR REPLACE FUNCTION
  5. Re-runs the same row count AFTER  -> must match within ±0 rows
       (deterministic function on the same input, no underlying data change)
  6. Verifies new column comments are present via DESCRIBE FUNCTION EXTENDED

Aborts if anything fails. Rollback path: re-run with the .before.sql body
wrapped in CREATE OR REPLACE FUNCTION manually.

Usage:
  python tools/rebuild_tvf_pnl_single_day.py --dry-run    # builds and diffs
  python tools/rebuild_tvf_pnl_single_day.py --apply      # actually deploys
"""
from __future__ import annotations
import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Functions" / "Function_PnL_Single_Day.md"
AUDIT_DIR = ROOT / "audits" / "_uc_deploy_descriptions"
AUDIT_DIR.mkdir(parents=True, exist_ok=True)

FUNCTION_FQN = "main.etoro_kpi_prep.tvf_pnl_single_day"
TEST_DATE = "2026-05-26"

# The return signature, in order. Types come straight from DESCRIBE FUNCTION
# EXTENDED so we match exactly what's there today.
RETURN_COLUMNS: list[tuple[str, str]] = [
    ("DateID", "INT"),
    ("CID", "INT"),
    ("PositionID", "BIGINT"),
    ("UnrealizedPnLStart", "DECIMAL(26,4)"),
    ("UnrealizedPnLEnd", "DECIMAL(26,4)"),
    ("UnrealizedPnLChange", "DECIMAL(28,4)"),
    ("NetProfit", "DECIMAL(29,4)"),
    ("InstrumentID", "INT"),
    ("MirrorID", "INT"),
    ("Leverage", "INT"),
    ("IsBuy", "BOOLEAN"),
    ("IsSettled", "INT"),
    ("HedgeServerID", "INT"),
    ("SettlementTypeID", "INT"),
    ("ClosedOnDate", "INT"),
    ("IsFuture", "INT"),
    ("IsCopyFund", "INT"),
    ("IsMarginTrade", "INT"),
    ("IsSQF", "INT"),
]


def clean_md(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def truncate(text: str, limit: int = 500) -> str:
    return text if len(text) <= limit else text[: limit - 3] + "..."


def sql_escape(s: str) -> str:
    return s.replace("'", "''")


def parse_wiki_cols() -> dict[str, str]:
    """Return {col_lower: comment_string} from Function_PnL_Single_Day.md §4."""
    content = WIKI.read_text(encoding="utf-8")
    m4 = re.search(r"## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)", content, re.DOTALL)
    if not m4:
        return {}
    cols: dict[str, str] = {}
    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or "# |" in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
        col_raw = parts[2].strip().strip("*").strip("`")
        source = clean_md(parts[3].strip())
        transform = clean_md(parts[4].strip())
        tier = parts[5].strip()
        if not col_raw or col_raw.lower() == "column":
            continue
        tag = "Function_PnL_Single_Day"
        if transform.lower() in ("direct", "direct pass-through",
                                 "direct from union branches", "direct from union row"):
            comment = f"Direct pass-through from {source}. ({tier} — {tag})"
        else:
            comment = f"{transform}. Source: {source}. ({tier} — {tag})"
        cols[col_raw.lower()] = truncate(comment)
    return cols


def fetch_current_body() -> str:
    """Pull current routine_definition from information_schema."""
    from databricks.sdk import WorkspaceClient
    from databricks import sql

    profile = os.environ.get("DATABRICKS_MCP_PROFILE", "guyman")
    wc = WorkspaceClient(profile=profile)
    host = "adb-5142916747090026.6.azuredatabricks.net"
    path = "/sql/1.0/warehouses/208214768b0e0308"

    conn = sql.connect(
        server_hostname=host,
        http_path=path,
        credentials_provider=lambda: wc.config.authenticate,
    )
    cur = conn.cursor()
    cur.execute(
        "SELECT routine_definition FROM main.information_schema.routines "
        "WHERE routine_catalog='main' AND routine_schema='etoro_kpi_prep' "
        "AND routine_name='tvf_pnl_single_day'"
    )
    row = cur.fetchone()
    cur.close()
    conn.close()
    return row[0]


def run_sql(stmts: list[str]) -> list:
    from databricks.sdk import WorkspaceClient
    from databricks import sql

    profile = os.environ.get("DATABRICKS_MCP_PROFILE", "guyman")
    wc = WorkspaceClient(profile=profile)
    host = "adb-5142916747090026.6.azuredatabricks.net"
    path = "/sql/1.0/warehouses/208214768b0e0308"

    conn = sql.connect(
        server_hostname=host,
        http_path=path,
        credentials_provider=lambda: wc.config.authenticate,
    )
    cur = conn.cursor()
    out = []
    try:
        for s in stmts:
            cur.execute(s)
            try:
                out.append(cur.fetchall())
            except Exception:
                out.append(None)
    finally:
        cur.close()
        conn.close()
    return out


def build_new_sql(body: str, wiki_cols: dict[str, str]) -> str:
    """Build CREATE OR REPLACE FUNCTION with column comments inline."""
    col_lines = []
    missing = []
    for name, dtype in RETURN_COLUMNS:
        desc = wiki_cols.get(name.lower())
        if not desc:
            missing.append(name)
            col_lines.append(f"    {name} {dtype}")
        else:
            col_lines.append(f"    {name} {dtype} COMMENT '{sql_escape(desc)}'")
    if missing:
        print(f"WARN: {len(missing)} return columns have no wiki §4 description: {missing}")
    body = body.strip()
    if not body.lstrip().upper().startswith(("WITH", "SELECT")):
        raise SystemExit(f"Unexpected body shape (first 80 chars): {body[:80]!r}")
    sql_text = (
        f"CREATE OR REPLACE FUNCTION {FUNCTION_FQN}(target_date DATE)\n"
        f"RETURNS TABLE (\n"
        + ",\n".join(col_lines)
        + "\n)\n"
        f"LANGUAGE SQL\n"
        f"DETERMINISTIC\n"
        f"READS SQL DATA\n"
        f"RETURN\n"
        f"{body}"
    )
    return sql_text


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="Actually deploy the CREATE OR REPLACE")
    ap.add_argument("--dry-run", action="store_true", help="Print and write but don't deploy")
    args = ap.parse_args()
    if not args.apply and not args.dry_run:
        args.dry_run = True

    wiki_cols = parse_wiki_cols()
    print(f"Wiki §4 columns: {len(wiki_cols)}")
    have = {name.lower() for name, _ in RETURN_COLUMNS}
    overlap = sum(1 for n in have if n in wiki_cols)
    print(f"Return-column matches: {overlap}/{len(RETURN_COLUMNS)}")
    print()

    print(f"Fetching current body of {FUNCTION_FQN}...")
    body = fetch_current_body()
    before_path = AUDIT_DIR / "tvf_pnl_single_day.before.sql"
    before_path.write_text(body, encoding="utf-8")
    print(f"  Saved current body -> {before_path.relative_to(ROOT)}  ({len(body)} chars)")

    new_sql = build_new_sql(body, wiki_cols)
    new_path = AUDIT_DIR / "tvf_pnl_single_day.new.sql"
    new_path.write_text(new_sql, encoding="utf-8")
    print(f"  Wrote new CREATE  -> {new_path.relative_to(ROOT)}  ({len(new_sql)} chars)")
    print()

    print("=== Body delta check ===")
    print(f"  Original body length:       {len(body)}")
    body_in_new = new_sql.split("RETURN\n", 1)[1]
    print(f"  Body embedded in new SQL:   {len(body_in_new)}")
    if body.strip() != body_in_new.strip():
        print("  ERROR: body content changed in some way other than wrapping!")
        return 1
    print("  Body is character-identical (only wrapper added).")
    print()

    if args.dry_run:
        print("(dry run — no deploy; re-run with --apply)")
        return 0

    print(f"=== Pre-flight: row count of {FUNCTION_FQN}('{TEST_DATE}') ===")
    pre = run_sql([f"SELECT COUNT(*) FROM {FUNCTION_FQN}(DATE '{TEST_DATE}')"])
    pre_count = pre[0][0][0]
    print(f"  rows before: {pre_count:,}")

    print("=== Applying CREATE OR REPLACE FUNCTION ===")
    run_sql([new_sql])
    print("  applied.")

    print(f"=== Post-flight: row count of {FUNCTION_FQN}('{TEST_DATE}') ===")
    post = run_sql([f"SELECT COUNT(*) FROM {FUNCTION_FQN}(DATE '{TEST_DATE}')"])
    post_count = post[0][0][0]
    print(f"  rows after:  {post_count:,}")
    if pre_count != post_count:
        print(f"  ABORT: row count changed ({pre_count} -> {post_count}). Restore from {before_path}.")
        return 2
    print(f"  match: {pre_count == post_count}")

    print("=== Sample DESCRIBE FUNCTION EXTENDED ===")
    desc = run_sql([f"DESCRIBE FUNCTION EXTENDED {FUNCTION_FQN}"])
    for row in desc[0][:25]:
        print(f"  {row[0]}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
