"""
Apply ALTER TABLE comments + column comments to UC views that represent
Synapse BI_DB_dbo Table-Valued Functions (TVFs).

For each of the 34 mapped TVF → UC view pairs:
  1. Parse the TVF wiki .md to extract:
       - §1 Business Meaning  → table TBLPROPERTIES comment
       - §4 Output Columns    → column-level comments (Source + Transformation)
  2. DESCRIBE the UC view to get actual column list
  3. Execute ALTER TABLE SET TBLPROPERTIES + ALTER COLUMN COMMENT
  4. Overwrite the TVF .alter.sql stub with a proper file recording all executed statements

Usage:
  python tools/apply_tvf_comments.py [--dry-run] [--only Function_Revenue_AdminFee]
"""

import os, re, sys, argparse, textwrap
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
FUNC_DIR  = os.path.join(REPO_ROOT, "knowledge", "synapse", "Wiki", "BI_DB_dbo", "Functions")

DBX_HOST      = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

MAPPING = [
    ("Function_Revenue_AdminFee",                       "main.etoro_kpi_prep.v_revenue_adminfee"),
    ("Function_Revenue_CashoutFee_ExcludeRedeem",       "main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem"),
    ("Function_Revenue_CashoutFee_IncRedeem",           "main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem"),
    ("Function_Revenue_Commissions",                    "main.etoro_kpi_prep.v_revenue_commission"),
    ("Function_Revenue_ConversionFee",                  "main.etoro_kpi_prep.v_revenue_conversionfee"),
    ("Function_Revenue_ConversionFee_WithPositionData", "main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata"),
    ("Function_Revenue_CryptoToFiat_C2F",               "main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f"),
    ("Function_Revenue_Dividend",                       "main.etoro_kpi_prep.v_revenue_dividend"),
    ("Function_Revenue_DormantFee",                     "main.etoro_kpi_prep.v_revenue_dormantfee"),
    ("Function_Revenue_FullCommissions",                "main.etoro_kpi_prep.v_revenue_fullcommission"),
    ("Function_Revenue_InterestFee",                    "main.etoro_kpi_prep.v_revenue_interestfee"),
    ("Function_Revenue_OptionsPlatform",                "main.etoro_kpi_prep.v_revenue_optionsplatform"),
    ("Function_Revenue_RolloverFee",                    "main.etoro_kpi_prep.v_revenue_rollover"),
    ("Function_Revenue_SDRT",                           "main.etoro_kpi_prep.v_revenue_sdrt"),
    ("Function_Revenue_Share_Lending",                  "main.etoro_kpi_prep.v_revenue_share_lending"),
    ("Function_Revenue_SpotAdjustFee",                  "main.etoro_kpi_prep.v_revenue_spotadjustfee"),
    ("Function_Revenue_StakingFee",                     "main.etoro_kpi_prep.v_revenue_stakingfee"),
    ("Function_Revenue_TicketFee",                      "main.etoro_kpi_prep.v_revenue_ticketfee_fixed"),
    ("Function_Revenue_TicketFeeByPercent",             "main.etoro_kpi_prep.v_revenue_ticketfee_bypercent"),
    ("Function_Revenue_TransferCoinFee",                "main.etoro_kpi_prep.v_revenue_transfercoinfee"),
    ("Function_Population_Active_Traders",              "main.etoro_kpi_prep.v_population_active_traders"),
    ("Function_Population_Balance_Only_Accounts",       "main.etoro_kpi_prep.v_population_balance_only_accounts"),
    ("Function_Population_First_Time_Funded",           "main.etoro_kpi_prep.v_population_first_time_funded"),
    ("Function_Population_First_Trading_Action",        "main.etoro_kpi_prep.v_population_first_trading_action"),
    ("Function_Population_Funded",                      "main.etoro_kpi_prep.v_population_funded"),
    ("Function_Population_OTD_DateRange",               "main.etoro_kpi_prep.v_population_otd_daterange"),
    ("Function_Population_Portfolio_Only",              "main.etoro_kpi_prep.v_population_portfolio_only"),
    ("Function_PnL_Single_Day",                         "main.etoro_kpi_prep.v_pnl_single_day"),
    ("Function_MIMO_First_Deposit_All_Platforms",       "main.etoro_kpi_prep.v_mimo_first_deposit_all_platforms"),
    ("Function_MIMO_Options_Platform",                  "main.etoro_kpi_prep.v_mimo_options_platform"),
    ("Function_Instrument_Conversion_Rates",            "main.etoro_kpi_prep.v_instrument_conversion_rates_dwh"),
    ("Function_Instrument_Snapshot_Enriched",           "main.etoro_kpi_prep.v_dim_instrument_enriched"),
    ("Function_Trading_Volume",                         "main.etoro_kpi_prep.v_trading_volume_and_amount"),
    ("Function_Trading_Volume_PositionLevel",           "main.etoro_kpi_prep.v_trading_volume_positionlevel"),
]

MAX_TABLE_COMMENT = 900   # stay comfortably under 1024 char UC limit
MAX_COL_COMMENT   = 500

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def clean_md(text: str) -> str:
    """Strip markdown bold/italic/backtick/link syntax for cleaner SQL comments."""
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    text = re.sub(r'\*(.+?)\*',     r'\1', text)
    text = re.sub(r'`([^`]+)`',     r'\1', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def esc(text: str) -> str:
    """Escape single quotes for SQL string literals."""
    return text.replace("'", "''")

def truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[:limit - 3] + "..."

# ---------------------------------------------------------------------------
# Wiki parser
# ---------------------------------------------------------------------------

def parse_wiki(tvf_name: str) -> dict:
    """
    Returns {
      'business_meaning': str,
      'columns': {col_lower: {'col': str, 'source': str, 'transformation': str, 'tier': str}}
    }
    """
    path = os.path.join(FUNC_DIR, tvf_name + ".md")
    with open(path, encoding="utf-8") as f:
        content = f.read()

    # §1 Business Meaning — text between '## 1. Business Meaning' and next '## '
    m = re.search(r'## 1\. Business Meaning\s*\n(.*?)(?=\n## )', content, re.DOTALL)
    business_meaning = clean_md(m.group(1).strip()) if m else tvf_name

    # §4 Output Columns table
    m4 = re.search(r'## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    columns = {}
    if m4:
        table_text = m4.group(1)
        for line in table_text.splitlines():
            line = line.strip()
            if not line.startswith('|') or line.startswith('|---') or line.startswith('| #'):
                continue
            parts = [p.strip() for p in line.split('|')]
            # parts[0]='' parts[1]=# parts[2]=Column parts[3]=Source parts[4]=Transformation parts[5]=Tier
            if len(parts) < 6:
                continue
            col_raw   = parts[2].strip()
            source    = clean_md(parts[3].strip())
            transform = clean_md(parts[4].strip())
            tier      = parts[5].strip() if len(parts) > 5 else ""
            if not col_raw or col_raw == 'Column':
                continue
            col_clean = col_raw.strip('*').strip('`')
            # Build comment
            if transform.lower() in ("direct", "direct pass-through", "direct from union branches",
                                     "direct from union row"):
                comment = f"Direct pass-through from {source}. ({tier} — {tvf_name})"
            else:
                comment = f"{transform}. Source: {source}. ({tier} — {tvf_name})"
            comment = truncate(comment, MAX_COL_COMMENT)
            columns[col_clean.lower()] = {
                "col": col_clean,
                "comment": comment,
            }

    return {"business_meaning": business_meaning, "columns": columns}

# ---------------------------------------------------------------------------
# UC helpers
# ---------------------------------------------------------------------------

_conn = None

def get_conn():
    global _conn
    if _conn is None:
        from databricks import sql
        print(f"  Connecting to {DBX_HOST}...")
        _conn = sql.connect(
            server_hostname=DBX_HOST,
            http_path=DBX_HTTP_PATH,
            auth_type="databricks-oauth",
        )
        print("  Connected.")
    return _conn

def describe_view(uc_table: str) -> list:
    """Returns list of column names (in order) from DESCRIBE TABLE EXTENDED."""
    cursor = get_conn().cursor()
    cursor.execute(f"DESCRIBE TABLE {uc_table}")
    rows = cursor.fetchall()
    cursor.close()
    cols = []
    for r in rows:
        name = r[0].strip() if r[0] else ""
        if not name or name.startswith("#") or name == "":
            break
        cols.append(name)
    return cols

def exec_sql(stmt: str, dry_run: bool) -> bool:
    if dry_run:
        print(f"    [DRY RUN] {stmt[:100]}...")
        return True
    cursor = get_conn().cursor()
    try:
        cursor.execute(stmt)
        cursor.close()
        return True
    except Exception as e:
        print(f"    FAILED: {e}")
        cursor.close()
        return False

# ---------------------------------------------------------------------------
# Per-TVF processing
# ---------------------------------------------------------------------------

def process(tvf_name: str, uc_table: str, dry_run: bool) -> dict:
    print(f"\n{'='*70}")
    print(f"  {tvf_name}  ->  {uc_table}")
    print(f"{'='*70}")

    wiki = parse_wiki(tvf_name)
    biz  = wiki["business_meaning"]
    wiki_cols = wiki["columns"]
    print(f"  Wiki: {len(wiki_cols)} columns parsed from §4")

    # Build full table comment: include source TVF name prefix
    table_comment_full = f"BI_DB_dbo.{tvf_name} > {biz}"
    table_comment = truncate(esc(table_comment_full), MAX_TABLE_COMMENT)

    # DESCRIBE UC view
    try:
        uc_cols = describe_view(uc_table)
    except Exception as e:
        print(f"  ERROR describing {uc_table}: {e}")
        return {"tvf": tvf_name, "uc": uc_table, "ok": 0, "fail": 1, "skipped": 0}
    print(f"  UC view has {len(uc_cols)} columns")

    executed = []
    ok = fail = skipped = 0

    # UC views use ALTER VIEW for TBLPROPERTIES and SET TAGS.
    # ALTER COLUMN COMMENT is unsupported on views — skipped.

    # 1 — Table TBLPROPERTIES comment (ALTER VIEW works for views)
    stmt_tbl = (
        f"ALTER VIEW {uc_table} SET TBLPROPERTIES (\n"
        f"    'comment' = '{table_comment}'\n"
        f");"
    )
    if exec_sql(stmt_tbl.rstrip(';'), dry_run):
        ok += 1
        executed.append(("tbl_comment", stmt_tbl))
    else:
        fail += 1

    # 2 — Table tags (ALTER VIEW SET TAGS)
    stmt_tags = (
        f"ALTER VIEW {uc_table} SET TAGS (\n"
        f"    'source_schema' = 'BI_DB_dbo',\n"
        f"    'source_system' = 'Synapse',\n"
        f"    'source_object_type' = 'TVF',\n"
        f"    'source_tvf' = '{tvf_name}',\n"
        f"    'pipeline' = 'dwh-semantic-doc',\n"
        f"    'pipeline_version' = 'tvf-comments-2026-04-12'\n"
        f");"
    )
    if exec_sql(stmt_tags.rstrip(';'), dry_run):
        ok += 1
        executed.append(("tbl_tags", stmt_tags))
    else:
        fail += 1

    # 3 — Column comments
    # Databricks does not support ALTER COLUMN COMMENT on views without DDL recreation.
    # We record the wiki column data as SQL comments for documentation but do not execute.
    col_stmts = []
    for uc_col in uc_cols:
        col_lower = uc_col.lower()
        if col_lower not in wiki_cols:
            skipped += 1
            continue
        comment = esc(wiki_cols[col_lower]["comment"])
        # Prefix with '--' — documented but not executable on views
        stmt_col = f"-- ALTER VIEW {uc_table} (col comment not supported on views without DDL recreation)\n-- Column `{uc_col}`: {comment}"
        col_stmts.append((uc_col, stmt_col))

    print(f"  Column matches documented (non-exec): {len(col_stmts)}/{len(uc_cols)} (unmatched {skipped})")

    for uc_col, stmt in col_stmts:
        executed.append(("col_doc", stmt))

    print(f"  Result: {ok} OK, {fail} failed, {skipped} unmatched cols, {len(col_stmts)} col descriptions documented")

    # 4 — Overwrite alter.sql stub
    if not dry_run and ok > 0:
        write_alter_sql(tvf_name, uc_table, executed, len(uc_cols), len(col_stmts))

    return {"tvf": tvf_name, "uc": uc_table, "ok": ok, "fail": fail, "skipped": skipped}

# ---------------------------------------------------------------------------
# Alter SQL writer
# ---------------------------------------------------------------------------

def write_alter_sql(tvf_name: str, uc_table: str, executed: list, total_uc_cols: int, matched_cols: int):
    path = os.path.join(FUNC_DIR, tvf_name + ".alter.sql")
    today = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"-- {'='*77}",
        f"-- Databricks ALTER Script: BI_DB_dbo.{tvf_name}",
        f"-- Generated: {today} | apply_tvf_comments.py",
        f"-- Target: UC view comment + column comments",
        f"-- UC Target: {uc_table}",
        f"-- Source: Synapse TVF BI_DB_dbo.{tvf_name}",
        f"-- UC cols: {total_uc_cols} total, {matched_cols} matched from wiki §4",
        f"-- {'='*77}",
        "",
    ]
    sections = {
        "tbl_comment": "-- ---- Table Comment ----",
        "tbl_tags":    "-- ---- Table Tags ----",
        "col_doc":     "-- ---- Column Descriptions (documented only; ALTER COLUMN not supported on views) ----",
    }
    written_sections = set()
    for kind, stmt in executed:
        if kind not in written_sections:
            lines.append("")
            lines.append(sections.get(kind, ""))
            written_sections.add(kind)
        lines.append(stmt)

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"  alter.sql updated: {os.path.basename(path)}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Apply TVF comments to UC views")
    parser.add_argument("--dry-run", action="store_true", help="Print statements without executing")
    parser.add_argument("--only", type=str, default=None, help="Comma-separated TVF names to process")
    args = parser.parse_args()

    target_set = set(args.only.split(",")) if args.only else None

    jobs = [(t, u) for t, u in MAPPING if target_set is None or t in target_set]
    print(f"Processing {len(jobs)} TVF->UC pairs {'(DRY RUN)' if args.dry_run else ''}")

    totals = {"ok": 0, "fail": 0, "skipped": 0}
    results = []
    for tvf, uc in jobs:
        r = process(tvf, uc, args.dry_run)
        results.append(r)
        totals["ok"]      += r["ok"]
        totals["fail"]    += r["fail"]
        totals["skipped"] += r["skipped"]

    if not args.dry_run:
        try:
            get_conn().close()
        except Exception:
            pass

    print(f"\n{'='*70}")
    print(f"SUMMARY: {len(results)} objects processed")
    print(f"  Statements OK:   {totals['ok']}")
    print(f"  Failed:          {totals['fail']}")
    print(f"  Unmatched cols:  {totals['skipped']}")
    print()
    for r in results:
        status = "OK" if r["fail"] == 0 else "PARTIAL" if r["ok"] > 0 else "FAILED"
        print(f"  [{status:7}] {r['tvf']} -> {r['uc'].split('.',2)[2]}  ({r['ok']} OK, {r['fail']} fail)")

if __name__ == "__main__":
    main()
