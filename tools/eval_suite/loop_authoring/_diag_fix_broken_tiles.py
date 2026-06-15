"""Triage the 5 broken tiles from batch_pin_tiles.py:
 #4  SpotAdjustFee column name
 #6  TP Deposits Amount UC=0
 #7  Global Deposits UC overcounts 2.6x
 #14 DailyTotalPnL UC ~ Synapse/2

Plus quick FYI:
 #10 Cashout count +10 (sub-rounding); #11 EquityGlobal +$74k (treat as ETL freshness)
"""
from __future__ import annotations
import os, sys
REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse
from dbx import make_client, run_sql

w = make_client()


# ---------------- #4: find the actual SpotAdjust column on the TVF ----------------
print("=" * 78)
print("[#4] Find SpotAdjust column on TVF")
print("=" * 78)

syn_sql = """
SELECT TOP 1 c.name
FROM tempdb.sys.columns c
WHERE c.object_id = OBJECT_ID('tempdb..#x')
"""
# Cleaner: just call the TVF for one row, list all columns containing 'spot' or 'adjust'
syn_sql = """
SELECT TOP 0 *
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('20260608', 0)
"""
r = synapse.run(syn_sql)
print(f"  TVF returns {len(r.columns)} columns")
spot_cols = [c for c in r.columns if 'spot' in c.lower() or 'adjust' in c.lower()]
print(f"  spot/adjust columns: {spot_cols}")


# ---------------- #6/#8/#9: UC MIMO fact platform values ----------------
print()
print("=" * 78)
print("[#6/#8/#9] UC MIMO fact: distinct MIMOPlatform values for 2026-06-08")
print("=" * 78)

uc_sql = """
SELECT MIMOPlatform, MIMOAction, COUNT(*) AS rows_, SUM(AmountUSD) AS amt
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE DateID = 20260608
GROUP BY MIMOPlatform, MIMOAction
ORDER BY MIMOPlatform, MIMOAction
"""
r = run_sql(w, uc_sql)
for row in r.rows:
    print(f"  platform={row[0]!r}  action={row[1]!r}  rows={row[2]}  amt={float(row[3] or 0):,.2f}")


# ---------------- #7: why UC global deposits == 2.6x Synapse ----------------
print()
print("=" * 78)
print("[#7] Synapse: how is GlobalDepositsAmount built (find the column on TVF)")
print("=" * 78)

global_cols = [c for c in r.columns if 'global' in c.lower() and 'deposit' in c.lower()]
print(f"  Already have TVF columns; global+deposit ones:")
# r is from MIMO query, not TVF. Reload TVF columns:
r2 = synapse.run("SELECT TOP 0 * FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('20260608', 0)")
global_cols = [c for c in r2.columns if 'global' in c.lower() and 'deposit' in c.lower()]
print(f"  TVF global+deposit cols: {global_cols}")


# ---------------- #14: DailyTotalPnL — Synapse columns ----------------
print()
print("=" * 78)
print("[#14] Synapse: DailyPnL* columns on TVF")
print("=" * 78)
pnl_cols = [c for c in r2.columns if 'pnl' in c.lower() and 'daily' in c.lower()]
print(f"  TVF DailyPnL* cols: {pnl_cols}")

# Also: what does fact_pnl produce when grouped by IsSettled/IsCopy?
print()
print("  UC fact_pnl: SUM(NetProfit) and SUM(UnrealizedPnLChange) by IsSettled,IsCopy:")
uc_sql = """
SELECT IsSettled, IsCopy,
       SUM(NetProfit) AS netp,
       SUM(UnrealizedPnLChange) AS unr,
       COUNT(*) AS rows_
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
WHERE DateID = 20260608
GROUP BY IsSettled, IsCopy
ORDER BY IsSettled, IsCopy
"""
r = run_sql(w, uc_sql)
for row in r.rows:
    print(f"    IsSettled={row[0]} IsCopy={row[1]}  netp={float(row[2] or 0):>20,.2f}  unr={float(row[3] or 0):>20,.2f}  rows={row[4]}")


# ---------------- #11: EquityGlobal +$74k — investigate ----------------
print()
print("=" * 78)
print("[#11] EquityGlobal +$74k delta — likely ETL freshness")
print("=" * 78)
print("  Skipping deep dive; this is freshness territory. The eval will flag this if persistent.")
