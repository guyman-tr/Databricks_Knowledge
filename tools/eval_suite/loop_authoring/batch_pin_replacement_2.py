"""Pin replacement for #2 (TP Deposits Amount, internal-flag ambiguity):
  ddr_mimo_global_deposits_count_yesterday — # of unique deposit transactions globally.

Also re-validate #11 (EquityGlobal) tolerance one more time at the same precision."""
from __future__ import annotations
import os, sys, time

REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse
from dbx import make_client, run_sql

ASOF = "20260608"

# 1. GlobalDepositsCount
print("=" * 60)
print("Case A: GlobalDepositsCount (replacement for the dropped TP-amount tile)")
print("=" * 60)
syn_sql = f"""
SELECT SUM(GlobalDepositsCount) AS value
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('{ASOF}', 0)
WHERE IsCreditReportValidCB = 1
""".strip()
uc_sql = f"""
SELECT COUNT(*) AS value
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms d
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked snap
    ON snap.RealCID = d.RealCID
   AND snap.IsCreditReportValidCB = 1
   AND d.DateID BETWEEN snap.FromDateID AND snap.ToDateID
WHERE d.DateID = {ASOF}
  AND d.MIMOAction = 'Deposit'
  AND d.IsRedeem = 0
  AND d.IsInternalTransfer = 0
""".strip()
print("Synapse:")
print(syn_sql)
t0 = time.time(); r = synapse.run(syn_sql); syn_v = float(r.rows[0][0] or 0); print(f"  syn = {syn_v:,.0f}  ({int((time.time()-t0)*1000)} ms)")
print("\nUC:")
print(uc_sql)
w = make_client(); t0 = time.time(); r = run_sql(w, uc_sql); uc_v = float(r.rows[0][0] or 0); print(f"  uc  = {uc_v:,.0f}  ({int((time.time()-t0)*1000)} ms)")
print(f"\ndiff = {uc_v - syn_v:+,.0f}  ({((uc_v-syn_v)/syn_v*100) if syn_v else 0:+.4f}%)")
