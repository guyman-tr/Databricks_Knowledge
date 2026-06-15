"""Day-by-day Options_PFOF: Synapse fact vs UC fact, since 2026-01-01."""
from __future__ import annotations
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== Synapse fact: Options_PFOF since 2026-01-01 ===")
syn = synapse.run("""
SELECT DateID, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE Metric = 'Options_PFOF' AND DateID >= 20260101
GROUP BY DateID
ORDER BY DateID
""")
syn_map = {int(row[0]): (int(row[1]), float(row[2]) if row[2] is not None else 0.0, str(row[3])) for row in syn.rows}
print(f"  Synapse rows for {len(syn_map)} days")

print()
print("=== UC fact: Options_PFOF since 2026-01-01 ===")
uc = run_sql(w, """
SELECT DateID, COUNT(*) AS rows_, SUM(Amount) AS sum_amt, MAX(UpdateDate) AS max_upd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'Options_PFOF' AND DateID >= 20260101
GROUP BY DateID
ORDER BY DateID
""")
uc_map = {int(row[0]): (int(row[1]), float(row[2]) if row[2] is not None else 0.0, str(row[3])) for row in uc.rows}
print(f"  UC rows for {len(uc_map)} days")

print()
print("=== Day-by-day diff (Synapse vs UC) ===")
all_days = sorted(set(syn_map.keys()) | set(uc_map.keys()))

import csv
out_csv = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'audits', 'eval_suite', 'pfof_since_jan.csv')
out_csv = os.path.normpath(out_csv)
with open(out_csv, 'w', newline='', encoding='utf-8') as f:
    wcsv = csv.writer(f)
    wcsv.writerow(['DateID', 'syn_rows', 'syn_sum', 'syn_max_upd', 'uc_rows', 'uc_sum', 'uc_max_upd', 'rows_delta', 'sum_delta', 'pct_delta', 'status'])

    print(f"  {'DateID':<10} {'syn_rows':>8} {'syn_sum':>14} {'uc_rows':>8} {'uc_sum':>14} {'Δ_rows':>7} {'Δ_sum':>14} {'%Δ':>7}  status")
    print(f"  {'-'*10} {'-'*8} {'-'*14} {'-'*8} {'-'*14} {'-'*7} {'-'*14} {'-'*7}  {'-'*15}")

    matching = 0
    syn_only = 0
    uc_only = 0
    diff = 0
    total_abs_delta = 0.0

    for d in all_days:
        s = syn_map.get(d)
        u = uc_map.get(d)
        if s and u:
            row_delta = s[0] - u[0]
            sum_delta = s[1] - u[1]
            pct = (sum_delta / s[1] * 100.0) if s[1] != 0 else 0.0
            if abs(sum_delta) < 0.01 and row_delta == 0:
                status = 'MATCH'
                matching += 1
            else:
                status = 'DIFF'
                diff += 1
                total_abs_delta += abs(sum_delta)
            print(f"  {d:<10} {s[0]:>8} {s[1]:>14.4f} {u[0]:>8} {u[1]:>14.4f} {row_delta:>7} {sum_delta:>14.4f} {pct:>6.2f}%  {status}")
            wcsv.writerow([d, s[0], f"{s[1]:.4f}", s[2], u[0], f"{u[1]:.4f}", u[2], row_delta, f"{sum_delta:.4f}", f"{pct:.4f}", status])
        elif s and not u:
            syn_only += 1
            print(f"  {d:<10} {s[0]:>8} {s[1]:>14.4f} {'-':>8} {'-':>14} {'-':>7} {'-':>14} {'-':>7}  SYN_ONLY")
            wcsv.writerow([d, s[0], f"{s[1]:.4f}", s[2], '', '', '', '', '', '', 'SYN_ONLY'])
            total_abs_delta += s[1]
        elif u and not s:
            uc_only += 1
            print(f"  {d:<10} {'-':>8} {'-':>14} {u[0]:>8} {u[1]:>14.4f} {'-':>7} {'-':>14} {'-':>7}  UC_ONLY")
            wcsv.writerow([d, '', '', '', u[0], f"{u[1]:.4f}", u[2], '', '', '', 'UC_ONLY'])
            total_abs_delta += u[1]

print()
print(f"  Summary: {matching} matching, {diff} differing, {syn_only} syn-only, {uc_only} uc-only")
print(f"  Total |Δ| sum: {total_abs_delta:.4f}")
print(f"  CSV: {out_csv}")
