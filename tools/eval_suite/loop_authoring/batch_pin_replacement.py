"""Pin replacement tile for #5 (Internal Deposits — too ambiguous):
  ddr_mimo_tp_first_funded_yesterday — count of first-time-funded TP customers."""
from __future__ import annotations
import os, sys, time

REPO_ROOT = os.path.dirname(os.path.abspath(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "eval_suite"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import synapse
from dbx import make_client, run_sql

ASOF = "20260608"
syn_sql = f"""
SELECT SUM(TPFirstDeposited) AS value
FROM BI_DB_dbo.Function_DDR_Aggregation_Yesterday('{ASOF}', 0)
WHERE IsCreditReportValidCB = 1
""".strip()
uc_sql = f"""
SELECT SUM(d.TPFirstDeposited) AS value
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status d
WHERE d.DateID = {ASOF}
  AND d.IsCreditReportValidCB = 1
""".strip()

print("Synapse TPFirstDeposited (valid CB):")
print(syn_sql)
t0 = time.time()
r = synapse.run(syn_sql)
syn_v = float(r.rows[0][0] or 0)
print(f"  syn = {syn_v:,.0f}  ({int((time.time()-t0)*1000)} ms)")

print("\nUC TPFirstDeposited (valid CB):")
print(uc_sql)
w = make_client()
t0 = time.time()
r = run_sql(w, uc_sql)
uc_v = float(r.rows[0][0] or 0)
print(f"  uc  = {uc_v:,.0f}  ({int((time.time()-t0)*1000)} ms)")

print(f"\ndiff = {uc_v - syn_v:+,.0f}  ({((uc_v-syn_v)/syn_v*100) if syn_v else 0:+.4f}%)")
