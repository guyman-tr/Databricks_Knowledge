"""
Apply column-level descriptions to etoro_kpi_prep TVF-mapped views.

Uses COMMENT ON COLUMN (ANSI SQL) — works on views without touching DDL.
This is the canonical permanent tool for TVF column metadata.

Run after any wiki update to sync descriptions to UC:
  python tools/apply_tvf_col_comments.py
  python tools/apply_tvf_col_comments.py --dry-run
  python tools/apply_tvf_col_comments.py --only Function_Revenue_AdminFee
"""

import os, re, sys, argparse

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

MAX_COMMENT = 500

# ---------------------------------------------------------------------------
# Wiki parser
# ---------------------------------------------------------------------------

def clean_md(text):
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    text = re.sub(r'\*(.+?)\*',     r'\1', text)
    text = re.sub(r'`([^`]+)`',     r'\1', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    return re.sub(r'\s+', ' ', text).strip()

def esc(text):
    return text.replace("'", "''")

def truncate(text, limit):
    return text if len(text) <= limit else text[:limit - 3] + "..."

def parse_wiki_cols(tvf_name):
    """Return {col_lower: comment_string} from §4 Output Columns."""
    path = os.path.join(FUNC_DIR, tvf_name + ".md")
    if not os.path.isfile(path):
        return {}
    with open(path, encoding="utf-8") as f:
        content = f.read()

    m4 = re.search(r'## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    if not m4:
        return {}

    cols = {}
    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith('|') or line.startswith('|---') or '# |' in line:
            continue
        parts = [p.strip() for p in line.split('|')]
        if len(parts) < 6:
            continue
        col_raw   = parts[2].strip().strip('*').strip('`')
        source    = clean_md(parts[3].strip())
        transform = clean_md(parts[4].strip())
        tier      = parts[5].strip()
        if not col_raw or col_raw.lower() == 'column':
            continue
        if transform.lower() in ("direct", "direct pass-through",
                                  "direct from union branches", "direct from union row"):
            comment = f"Direct pass-through from {source}. ({tier} — {tvf_name})"
        else:
            comment = f"{transform}. Source: {source}. ({tier} — {tvf_name})"
        cols[col_raw.lower()] = truncate(comment, MAX_COMMENT)

    return cols

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Apply TVF column descriptions via COMMENT ON COLUMN")
    parser.add_argument("--dry-run", action="store_true", help="Print statements without executing")
    parser.add_argument("--only", metavar="TVF", help="Run for a single TVF name (e.g. Function_Revenue_AdminFee)")
    args = parser.parse_args()

    targets = MAPPING
    if args.only:
        targets = [(t, u) for t, u in MAPPING if t == args.only]
        if not targets:
            print(f"ERROR: '{args.only}' not found in MAPPING")
            sys.exit(1)

    conn = cursor = None
    if not args.dry_run:
        from databricks import sql
        print(f"Connecting to {DBX_HOST}...")
        conn = sql.connect(
            server_hostname=DBX_HOST,
            http_path=DBX_HTTP_PATH,
            auth_type="databricks-oauth",
        )
        cursor = conn.cursor()
        print("Connected.\n")

    total_applied = total_skipped = total_failed = 0

    for tvf_name, uc_name in targets:
        print(f"{'='*60}")
        print(f"  {tvf_name}  ->  {uc_name}")

        wiki_cols = parse_wiki_cols(tvf_name)
        if not wiki_cols:
            print(f"  SKIP — no §4 Output Columns in wiki")
            continue
        print(f"  Wiki: {len(wiki_cols)} columns from §4")

        # Get actual UC columns
        if not args.dry_run:
            try:
                cursor.execute(f"DESCRIBE TABLE {uc_name}")
                uc_cols = [row[0] for row in cursor.fetchall()
                           if row[0] and not row[0].startswith("#")]
            except Exception as e:
                print(f"  SKIP — DESCRIBE failed: {e}")
                continue
        else:
            uc_cols = list(wiki_cols.keys())  # dry-run: pretend all cols exist

        applied = skipped = failed = 0
        for col in uc_cols:
            desc = wiki_cols.get(col.lower())
            if not desc:
                skipped += 1
                continue
            stmt = f"COMMENT ON COLUMN {uc_name}.`{col}` IS '{esc(desc)}'"
            if args.dry_run:
                print(f"  [DRY] {stmt[:120]}")
                applied += 1
            else:
                try:
                    cursor.execute(stmt)
                    applied += 1
                except Exception as e:
                    failed += 1
                    print(f"  WARN {col}: {e}")

        print(f"  -> {applied} applied, {skipped} no-desc, {failed} failed")
        total_applied += applied
        total_skipped += skipped
        total_failed  += failed

    if conn:
        conn.close()

    print(f"\n{'='*60}")
    print(f"DONE: {total_applied} comments applied, "
          f"{total_skipped} cols had no description, {total_failed} failed")

if __name__ == "__main__":
    main()
