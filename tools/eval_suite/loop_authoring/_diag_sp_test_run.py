"""Test-run the SP for a single date (in a TEST table — NOT touching gold).

Plan:
  1. Snapshot main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
     filtered to a recent test date into a sandbox copy.
  2. CALL the SP with the sandbox table as target.
  3. Compare sandbox post-SP rows against Synapse fact for the test date.

This proves the SP is runnable AND that its output matches Synapse penny-for-penny
for a recent date, BEFORE we wire it onto the live target.
"""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
import time
from databricks.sdk import WorkspaceClient
from dbx import run_sql
import synapse

w = WorkspaceClient()

TEST_DATE = "20260608"   # the same Sunday we used for the eval-suite tile #1
TARGET = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions"
SANDBOX = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions__sp_test_20260610"

print(f"=== Test run: SP against sandbox copy for DateID={TEST_DATE} ===")

# 1. Build sandbox = clone of TARGET (full schema + data) so the SP has realistic
#    "current state" to overwrite. We could TRUNCATE + bulk INSERT to make the SP
#    run faster, but DELETE+INSERT-by-DateID inside SP is fast either way.
print("[1/5] Creating EMPTY sandbox table with same schema as target (LIKE)...")
t0 = time.time()
run_sql(w, f"DROP TABLE IF EXISTS {SANDBOX}")
# Target is EXTERNAL (3.1B rows on ABFSS) so SHALLOW CLONE is unsupported and a
# full CTAS would be unnecessarily heavy. The SP only reads the target via
# DELETE-by-predicate, never SELECT-aggregate, so an empty same-schema sandbox
# is a faithful test bed for one-day SP semantics.
run_sql(w, f"CREATE TABLE {SANDBOX} LIKE {TARGET}")
print(f"      created in {time.time()-t0:.1f}s.")

# 2. Snapshot pre-state (should be empty, sandbox just created via LIKE)
print(f"[2/5] Pre-call sandbox state (should be empty):")
r = run_sql(w, f"SELECT COUNT(*) FROM {SANDBOX}")
pre_n = int(r.rows[0][0]) if r.rows else 0
print(f"      sandbox row count: {pre_n}")
if pre_n != 0:
    print(f"      WARN: sandbox is not empty — unexpected state.")

# 3. CALL the SP
print(f"[3/5] CALL main.de_output.sp_ddr_fact_revenue_generating_actions('{SANDBOX}', '{TEST_DATE}')...")
t0 = time.time()
run_sql(w, f"CALL main.de_output.sp_ddr_fact_revenue_generating_actions('{SANDBOX}', '{TEST_DATE}')")
print(f"      SP completed in {time.time()-t0:.1f}s.")

# 4. Post-state on sandbox
print(f"[4/5] Post-call summary on sandbox for DateID={TEST_DATE}:")
r = run_sql(w, f"""
SELECT Metric, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM {SANDBOX}
WHERE DateID = {TEST_DATE} AND IncludedInTotalRevenue = 1
GROUP BY Metric ORDER BY Metric
""")
post_state = {row[0]: (int(row[1]), float(row[2] or 0.0)) for row in r.rows}
for m, (rows, s) in post_state.items():
    print(f"      post {m:<28} rows={rows:>10} sum={s:>14.2f}")
post_total = sum(s for _, s in post_state.values())
print(f"      post TOTAL = {post_total:.2f}")

# 5. Pull Synapse truth for the same date
print(f"[5/5] Synapse truth for DateID={TEST_DATE}:")
r = synapse.run(f"""
SELECT Metric, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID = {TEST_DATE} AND IncludedInTotalRevenue = 1
GROUP BY Metric ORDER BY Metric
""")
syn_state = {row[0]: (int(row[1]), float(row[2] or 0.0)) for row in r.rows}
for m, (rows, s) in syn_state.items():
    print(f"      syn  {m:<28} rows={rows:>10} sum={s:>14.2f}")
syn_total = sum(s for _, s in syn_state.values())
print(f"      syn  TOTAL = {syn_total:.2f}")

print()
print("=== Comparison: post-SP sandbox vs Synapse ===")
print(f"  {'Metric':<30} {'syn_rows':>10} {'syn_sum':>14} {'sb_rows':>10} {'sb_sum':>14} {'Δ_sum':>14} status")
all_metrics = sorted(set(syn_state) | set(post_state))
fails = 0
for m in all_metrics:
    syn = syn_state.get(m, (0, 0.0))
    sb  = post_state.get(m, (0, 0.0))
    ds  = syn[1] - sb[1]
    ok  = (syn[0] == sb[0]) and (abs(ds) < 0.01)
    if not ok:
        fails += 1
    print(f"  {m:<30} {syn[0]:>10} {syn[1]:>14.2f} {sb[0]:>10} {sb[1]:>14.2f} {ds:>14.2f} {'OK' if ok else 'DIFF'}")

print()
print(f"  TOTAL  syn={syn_total:.2f}  sandbox={post_total:.2f}  Δ={syn_total-post_total:+.2f}")
print()
if fails == 0:
    print("  PASS: SP output matches Synapse for all metrics on the test date.")
else:
    print(f"  FAIL: {fails} metric(s) drift between SP and Synapse. Investigate before scheduling.")

print()
print(f"Sandbox left in place: {SANDBOX} (drop manually when done).")
