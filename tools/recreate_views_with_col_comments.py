"""
Add column-level COMMENTs to etoro_kpi_prep views by recreating their DDL.

Databricks views do not support ALTER COLUMN COMMENT — the only way to set
column descriptions is via CREATE OR REPLACE VIEW with inline COMMENT clauses.

For each of the 34 TVF-mapped views:
  1. SHOW CREATE TABLE  → get current DDL
  2. Parse column list  → identify columns with/without COMMENT
  3. Inject wiki §4 descriptions for unset columns
  4. Preserve existing COMMENTs (from prior propagation runs)
  5. CREATE OR REPLACE VIEW with the enriched column list
  6. Update the .alter.sql file to record the full new DDL

Usage:
  python tools/recreate_views_with_col_comments.py [--dry-run] [--only func1,func2]
"""

import os, re, sys, argparse
from datetime import datetime

# ---------------------------------------------------------------------------
# Config
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

MAX_COL_COMMENT = 500

# ---------------------------------------------------------------------------
# Wiki parser (same as apply_tvf_comments.py)
# ---------------------------------------------------------------------------

def clean_md(text: str) -> str:
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    text = re.sub(r'\*(.+?)\*',     r'\1', text)
    text = re.sub(r'`([^`]+)`',     r'\1', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    return re.sub(r'\s+', ' ', text).strip()

def esc(text: str) -> str:
    return text.replace("'", "''")

def truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[:limit - 3] + "..."

def parse_wiki_cols(tvf_name: str) -> dict:
    """Returns {col_lower: comment_string}"""
    path = os.path.join(FUNC_DIR, tvf_name + ".md")
    with open(path, encoding="utf-8") as f:
        content = f.read()

    m4 = re.search(r'## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    cols = {}
    if not m4:
        return cols

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
        if transform.lower() in ("direct", "direct pass-through", "direct from union branches",
                                  "direct from union row"):
            comment = f"Direct pass-through from {source}. ({tier} — {tvf_name})"
        else:
            comment = f"{transform}. Source: {source}. ({tier} — {tvf_name})"
        cols[col_raw.lower()] = truncate(comment, MAX_COL_COMMENT)

    return cols

# ---------------------------------------------------------------------------
# DDL parser / rebuilder
# ---------------------------------------------------------------------------

# Matches a column entry with an existing COMMENT (handles '' escapes inside)
_COL_WITH_COMMENT_RE = re.compile(
    r"^(\w+)\s+COMMENT\s+'((?:[^']|'')*)'$",
    re.IGNORECASE
)
_COL_NAME_RE = re.compile(r"^(\w+)$")


def rebuild_ddl(raw_ddl: str, uc_name: str, wiki_cols: dict) -> tuple:
    """
    Parse raw SHOW CREATE TABLE output, inject column COMMENTs, return
    (new_ddl_string, stats_dict).

    stats_dict = {added: int, kept: int, unmatched: int}
    """
    # ---- 1. Split body at `\nAS ` ----------------------------------------
    as_match = re.search(r'\nAS\s', raw_ddl, re.IGNORECASE)
    if not as_match:
        raise ValueError("Could not find 'AS ' in DDL — unexpected format")
    pre_as  = raw_ddl[: as_match.start()]
    as_body = raw_ddl[as_match.start():]     # \nAS SELECT ...  or \nAS WITH ...

    # ---- 2. Extract column list block ( ... ) ----------------------------
    # The column list is the first (...) block in pre_as
    paren_open = pre_as.index('(')
    # Walk forward to find the matching closing paren
    depth = 0
    paren_close = -1
    for i, ch in enumerate(pre_as[paren_open:], start=paren_open):
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                paren_close = i
                break
    if paren_close == -1:
        raise ValueError("Unbalanced parentheses in column list")

    col_block   = pre_as[paren_open + 1 : paren_close]   # content inside ()
    after_cols  = pre_as[paren_close + 1:]                 # COMMENT, TBLPROPERTIES, WITH SCHEMA...

    # ---- 3. Parse each column line ----------------------------------------
    new_lines = []
    added = kept = unmatched = 0

    for line in col_block.splitlines():
        stripped = line.strip().rstrip(',')
        if not stripped:
            continue

        m_existing = _COL_WITH_COMMENT_RE.match(stripped)
        if m_existing:
            # Column already has a COMMENT — preserve it
            col_name    = m_existing.group(1)
            existing_c  = m_existing.group(2)
            new_lines.append((col_name, existing_c, "kept"))
            kept += 1
        elif _COL_NAME_RE.match(stripped):
            col_name = stripped
            wiki_c = wiki_cols.get(col_name.lower())
            if wiki_c:
                new_lines.append((col_name, esc(wiki_c), "added"))
                added += 1
            else:
                new_lines.append((col_name, None, "unmatched"))
                unmatched += 1
        # else: skip separator lines or unexpected content

    # ---- 4. Rebuild column list -------------------------------------------
    rebuilt_lines = []
    for col_name, comment, status in new_lines:
        if comment is not None:
            rebuilt_lines.append(f"  {col_name} COMMENT '{comment}'")
        else:
            rebuilt_lines.append(f"  {col_name}")

    new_col_block = ",\n".join(rebuilt_lines)

    # ---- 5. Reconstruct full DDL ------------------------------------------
    # Replace the original `CREATE VIEW schema.view` with `CREATE OR REPLACE VIEW main.schema.view`
    # after_cols already has COMMENT '...', TBLPROPERTIES, WITH SCHEMA COMPENSATION intact
    new_ddl = (
        f"CREATE OR REPLACE VIEW {uc_name} (\n"
        f"{new_col_block}\n"
        f"){after_cols}{as_body}"
    )

    stats = {"added": added, "kept": kept, "unmatched": unmatched}
    return new_ddl, stats

# ---------------------------------------------------------------------------
# Databricks connection
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

def run_sql(stmt: str, dry_run: bool) -> bool:
    if dry_run:
        print(f"    [DRY RUN] {stmt[:120].strip()}...")
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
# Per-view processing
# ---------------------------------------------------------------------------

def process(tvf_name: str, uc_table: str, dry_run: bool) -> dict:
    print(f"\n{'='*70}")
    print(f"  {tvf_name}  ->  {uc_table}")

    wiki_cols = parse_wiki_cols(tvf_name)
    print(f"  Wiki: {len(wiki_cols)} columns from §4")

    # Get current DDL
    cursor = get_conn().cursor()
    cursor.execute(f"SHOW CREATE TABLE {uc_table}")
    rows = cursor.fetchall()
    cursor.close()
    raw_ddl = rows[0][0] if rows else ""

    if not raw_ddl:
        print("  ERROR: empty DDL returned")
        return {"tvf": tvf_name, "uc": uc_table, "ok": False, "added": 0, "kept": 0, "unmatched": 0}

    # Rebuild with column comments
    try:
        new_ddl, stats = rebuild_ddl(raw_ddl, uc_table, wiki_cols)
    except Exception as e:
        print(f"  ERROR rebuilding DDL: {e}")
        return {"tvf": tvf_name, "uc": uc_table, "ok": False, "added": 0, "kept": 0, "unmatched": 0}

    print(f"  Columns: {stats['added']} added, {stats['kept']} kept (existing), {stats['unmatched']} unmatched")

    if stats['added'] == 0:
        print("  No new comments to add — skipping CREATE OR REPLACE")
        return {"tvf": tvf_name, "uc": uc_table, "ok": True, "skipped": True, **stats}

    if dry_run:
        # Show the new column list portion only
        lines = new_ddl.split('\n')
        print("  [DRY RUN] New CREATE OR REPLACE VIEW header:")
        for ln in lines[:20]:
            print(f"    {ln}")
        if len(lines) > 20:
            print(f"    ... ({len(lines) - 20} more lines)")
        return {"tvf": tvf_name, "uc": uc_table, "ok": True, "skipped": False, **stats}

    ok = run_sql(new_ddl, dry_run=False)
    if ok:
        write_alter_sql(tvf_name, uc_table, new_ddl, stats)

    return {"tvf": tvf_name, "uc": uc_table, "ok": ok, "skipped": False, **stats}

# ---------------------------------------------------------------------------
# alter.sql writer
# ---------------------------------------------------------------------------

def write_alter_sql(tvf_name: str, uc_table: str, new_ddl: str, stats: dict):
    path = os.path.join(FUNC_DIR, tvf_name + ".alter.sql")
    today = datetime.now().strftime("%Y-%m-%d")

    header = "\n".join([
        f"-- {'='*77}",
        f"-- Databricks ALTER Script: BI_DB_dbo.{tvf_name}",
        f"-- Generated: {today} | recreate_views_with_col_comments.py",
        f"-- UC Target: {uc_table}",
        f"-- Col comments: {stats['added']} added, {stats['kept']} preserved (existing), {stats['unmatched']} unmatched",
        f"-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).",
        f"-- {'='*77}",
        "",
        "-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----",
        "",
    ])

    with open(path, "w", encoding="utf-8") as f:
        f.write(header + new_ddl + "\n;\n")
    print(f"  alter.sql updated: {os.path.basename(path)}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--only", type=str, default=None,
                        help="Comma-separated TVF names")
    args = parser.parse_args()

    target_set = set(args.only.split(",")) if args.only else None
    jobs = [(t, u) for t, u in MAPPING if target_set is None or t in target_set]

    print(f"Processing {len(jobs)} views {'(DRY RUN)' if args.dry_run else ''}")

    results = []
    total_added = total_kept = total_unmatched = 0

    for tvf, uc in jobs:
        r = process(tvf, uc, args.dry_run)
        results.append(r)
        total_added     += r.get("added", 0)
        total_kept      += r.get("kept", 0)
        total_unmatched += r.get("unmatched", 0)

    if not args.dry_run:
        try:
            get_conn().close()
        except Exception:
            pass

    print(f"\n{'='*70}")
    print(f"SUMMARY: {len(results)} views processed")
    print(f"  Col comments added:    {total_added}")
    print(f"  Col comments kept:     {total_kept}")
    print(f"  Unmatched (no wiki):   {total_unmatched}")
    print()

    for r in results:
        if not r.get("ok"):
            status = "FAILED "
        elif r.get("skipped"):
            status = "SKIP   "
        else:
            status = "OK     "
        print(f"  [{status}] {r['tvf'].replace('Function_','')} -> {r['uc'].split('.',2)[2]}"
              f"  (+{r.get('added',0)} added, ={r.get('kept',0)} kept, ?{r.get('unmatched',0)} no-wiki)")

if __name__ == "__main__":
    main()
