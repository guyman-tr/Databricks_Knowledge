"""Round 2 triage: tile #7 (GlobalDepositsAmount), #14 (DailyTotalPnL)."""
from __future__ import annotations
import os, sys
REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse
from dbx import make_client, run_sql

w = make_client()


# ---------------- #7: how does Synapse build GlobalDepositsAmount ----------------
print("=" * 78)
print("[#7] Synapse Function_DDR_Aggregation_Yesterday vs raw MIMO platform sum")
print("=" * 78)
print("Synapse TVF GlobalDepositsAmount = 29,898,543.14 (from previous batch)")
print("UC raw MIMO 'Deposit' rows         = 78,423,879.65 (sum across all platforms)")
print("Difference = 48,525,336 (~equal to internal-transfer + eMoney + something)")

# What are the platform/action breakdowns IN SYNAPSE for the DDR fact (gold mirror)?
print()
print("UC: same gold mirror, GROUP BY MIMOPlatform/MIMOAction with various flag filters:")
sql = """
SELECT MIMOPlatform, MIMOAction,
       SUM(CASE WHEN IsRedeem=0 AND IsInternalTransfer=0 THEN AmountUSD ELSE 0 END) AS amt_external_norepem,
       SUM(CASE WHEN IsRedeem=0 AND IsInternalTransfer=1 THEN AmountUSD ELSE 0 END) AS amt_internal,
       SUM(CASE WHEN IsRedeem=1 THEN AmountUSD ELSE 0 END) AS amt_redeem,
       SUM(CASE WHEN IsCryptoToFiat=1 THEN AmountUSD ELSE 0 END) AS amt_c2f,
       SUM(AmountUSD) AS amt_total,
       COUNT(*) AS rows_
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE DateID = 20260608
GROUP BY MIMOPlatform, MIMOAction
ORDER BY MIMOPlatform, MIMOAction
"""
r = run_sql(w, sql)
print(f"  {'platform':<16} {'action':<10} {'extl(non-redeem)':>18} {'internal':>14} {'redeem':>14} {'c2f':>14} {'total':>16} rows")
for row in r.rows:
    p, a, ext, intl, rd, c2f, tot, n = row
    print(f"  {str(p):<16} {str(a):<10} {float(ext or 0):>18,.2f} {float(intl or 0):>14,.2f} {float(rd or 0):>14,.2f} {float(c2f or 0):>14,.2f} {float(tot or 0):>16,.2f} {n}")

# Now let's see Synapse customer_daily_status — what would it show for this date?
# Since GlobalDepositsAmount is on the wide TVF, but the TVF rolls up from the daily-status table.
# Try: SUM(TP_External_FTDA + ...) ? Actually it's an aggregate metric. Let me find similar wide cols on customer_daily_status:

print()
print("UC customer_daily_status: GlobalDeposits-related cols")
sql = """
DESCRIBE TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
"""
r = run_sql(w, sql)
for row in r.rows:
    name = str(row[0])
    if not name or name.startswith("#"):
        break
    if 'global' in name.lower() or 'deposit' in name.lower() or 'cashout' in name.lower():
        print(f"   {name:<40} {row[1]}")


# ---------------- #14: DailyTotalPnL build -----------------
print()
print("=" * 78)
print("[#14] How is DailyTotalPnL built in Synapse?")
print("=" * 78)
print("Synapse DailyTotalPnL = 200,678,311 / DailyPnLStocks+Crypto+Copy+Manual = ?")

# Compute the per-component sums on the TVF for sanity
print()
print("Synapse TVF: per-component sums for valid CB:")
syn_sql = """
SELECT SUM(DailyTotalPnL)        AS DailyTotalPnL,
       SUM(DailyPnLStocks)       AS DailyPnLStocks,
       SUM(DailyPnLCrypto)       AS DailyPnLCrypto,
       SUM(DailyPnLCopy)         AS DailyPnLCopy,
       SUM(DailyPnLManual)       AS DailyPnLManual,
       SUM(DailyPnLETF)          AS DailyPnLETF,
       SUM(DailyPnLStocksReal)   AS DailyPnLStocksReal,
       SUM(DailyPnLCryptoReal)   AS DailyPnLCryptoReal,
       SUM(DailyPnLStocksCFD)    AS DailyPnLStocksCFD,
       SUM(DailyPnLCryptoCFD)    AS DailyPnLCryptoCFD
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('20260608', 0)
WHERE IsCreditReportValidCB = 1
"""
r = synapse.run(syn_sql)
for col, val in zip(r.columns, r.rows[0]):
    print(f"  {col:<25} {float(val or 0):>20,.2f}")

# Now the UC fact_pnl — the same numbers via the gold mirror
print()
print("UC fact_pnl: SUM by IsSettled,IsCopy,IsLeveraged for 2026-06-08, valid-CB cohort")
sql = """
SELECT d.IsSettled, d.IsCopy, d.IsLeveraged, d.IsFuture,
       SUM(d.NetProfit) AS netp,
       SUM(d.UnrealizedPnLChange) AS unr,
       SUM(d.NetProfit + d.UnrealizedPnLChange) AS total,
       COUNT(*) AS rows_
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl d
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = 20260608
GROUP BY d.IsSettled, d.IsCopy, d.IsLeveraged, d.IsFuture
ORDER BY d.IsSettled, d.IsCopy, d.IsLeveraged, d.IsFuture
"""
r = run_sql(w, sql)
print(f"  {'IsSettled':>9} {'IsCopy':>6} {'IsLev':>6} {'IsFut':>6} {'netp':>16} {'unr':>16} {'total':>16} {'rows':>10}")
for row in r.rows:
    print(f"  {row[0]:>9} {row[1]:>6} {row[2]:>6} {row[3]:>6} {float(row[4] or 0):>16,.2f} {float(row[5] or 0):>16,.2f} {float(row[6] or 0):>16,.2f} {row[7]:>10}")

# ---------------- #11: EquityGlobal +$74k — quick row-count diff -----------------
print()
print("=" * 78)
print("[#11] EquityGlobal +$74k — rowcount + null check")
print("=" * 78)
sql = """
SELECT COUNT(*) AS rows_, COUNT(EquityGlobal) AS rows_with_val, SUM(EquityGlobal) AS total
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260608
"""
r = run_sql(w, sql)
print(f"  UC AUM (no valid-CB filter): {r.rows[0]}")

sql = """
SELECT MAX(UpdateDate) AS max_upd, MIN(UpdateDate) AS min_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
WHERE DateID = 20260608
"""
r = run_sql(w, sql)
print(f"  UC AUM UpdateDate range: {r.rows[0]}")
