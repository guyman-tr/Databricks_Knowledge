"""All-metric per-day diff: Synapse vs UC for BI_DB_DDR_Fact_Revenue_Generating_Actions since 2026-01-01.

Output:
  - per-(metric,day) CSV with row-count + sum-amount delta
  - per-metric summary printed to console
"""
from __future__ import annotations
import os, sys, csv
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import synapse
from databricks.sdk import WorkspaceClient
from dbx import run_sql

w = WorkspaceClient()

print("=== Synapse: per-(metric,day) since 2026-01-01 ===")
syn = synapse.run("""
SELECT DateID, Metric, COUNT(*) AS rows_, SUM(CAST(Amount AS FLOAT)) AS sum_amt
FROM BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions
WHERE DateID >= 20260101
GROUP BY DateID, Metric
""")
syn_map: dict[tuple[int, str], tuple[int, float]] = {}
for row in syn.rows:
    syn_map[(int(row[0]), str(row[1]))] = (int(row[1] if False else row[2]), float(row[3]) if row[3] is not None else 0.0)
# fix: row[2] is rows_, row[3] is sum
syn_map = {(int(r[0]), str(r[1])): (int(r[2]), float(r[3]) if r[3] is not None else 0.0) for r in syn.rows}
print(f"  {len(syn_map)} (metric,day) tuples")

print()
print("=== UC: per-(metric,day) since 2026-01-01 ===")
uc = run_sql(w, """
SELECT DateID, Metric, COUNT(*) AS rows_, SUM(Amount) AS sum_amt
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE DateID >= 20260101
GROUP BY DateID, Metric
""")
uc_map = {(int(r[0]), str(r[1])): (int(r[2]), float(r[3]) if r[3] is not None else 0.0) for r in uc.rows}
print(f"  {len(uc_map)} (metric,day) tuples")

print()
print("=== Metric coverage ===")
syn_metrics = sorted({k[1] for k in syn_map})
uc_metrics = sorted({k[1] for k in uc_map})
print(f"  Synapse metrics ({len(syn_metrics)}): {syn_metrics}")
print(f"  UC      metrics ({len(uc_metrics)}): {uc_metrics}")
only_syn = sorted(set(syn_metrics) - set(uc_metrics))
only_uc = sorted(set(uc_metrics) - set(syn_metrics))
print(f"  Synapse-only metrics: {only_syn}")
print(f"  UC-only      metrics: {only_uc}")

print()
print("=== Per-metric coverage summary ===")
print(f"  {'Metric':<28} {'syn_days':>8} {'uc_days':>7} {'match':>5} {'diff':>4} {'syn_only':>8} {'uc_only':>7} {'syn_total':>14} {'uc_total':>14} {'|delta|_total':>14}")
print(f"  {'-'*28} {'-'*8} {'-'*7} {'-'*5} {'-'*4} {'-'*8} {'-'*7} {'-'*14} {'-'*14} {'-'*14}")

all_metrics = sorted(set(syn_metrics) | set(uc_metrics))

# Open per-(metric,day) CSV
out_csv = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'audits', 'eval_suite', 'all_metrics_since_jan.csv')
out_csv = os.path.normpath(out_csv)
csv_f = open(out_csv, 'w', newline='', encoding='utf-8')
wcsv = csv.writer(csv_f)
wcsv.writerow(['Metric', 'DateID', 'syn_rows', 'syn_sum', 'uc_rows', 'uc_sum', 'rows_delta', 'sum_delta', 'pct_delta', 'status'])

# also write a per-metric summary CSV
summary_csv = os.path.join(os.path.dirname(out_csv), 'all_metrics_since_jan_summary.csv')
sf = open(summary_csv, 'w', newline='', encoding='utf-8')
swcsv = csv.writer(sf)
swcsv.writerow(['Metric', 'syn_days', 'uc_days', 'match_days', 'diff_days', 'syn_only_days', 'uc_only_days',
                'syn_total_sum', 'uc_total_sum', 'abs_delta_total', 'pct_total_gap'])

metric_status: list[tuple[str, str]] = []  # (metric, "FINE" / "BROKEN_FROM_<date>" / "PARTIAL")

for metric in all_metrics:
    syn_days = sorted({k[0] for k in syn_map if k[1] == metric})
    uc_days  = sorted({k[0] for k in uc_map  if k[1] == metric})
    all_days = sorted(set(syn_days) | set(uc_days))

    matches = 0
    diffs = 0
    syn_only_count = 0
    uc_only_count = 0
    syn_total = 0.0
    uc_total = 0.0
    abs_delta = 0.0
    first_break: int | None = None

    for d in all_days:
        s = syn_map.get((d, metric))
        u = uc_map.get((d, metric))
        if s and u:
            row_d = s[0] - u[0]
            sum_d = s[1] - u[1]
            pct = (sum_d / s[1] * 100.0) if s[1] != 0 else 0.0
            syn_total += s[1]
            uc_total += u[1]
            if abs(sum_d) < 0.01 and row_d == 0:
                status = 'MATCH'; matches += 1
            else:
                status = 'DIFF'; diffs += 1
                abs_delta += abs(sum_d)
                if first_break is None: first_break = d
            wcsv.writerow([metric, d, s[0], f"{s[1]:.4f}", u[0], f"{u[1]:.4f}", row_d, f"{sum_d:.4f}", f"{pct:.4f}", status])
        elif s and not u:
            syn_only_count += 1
            syn_total += s[1]
            abs_delta += s[1]
            if first_break is None: first_break = d
            wcsv.writerow([metric, d, s[0], f"{s[1]:.4f}", '', '', '', '', '', 'SYN_ONLY'])
        elif u and not s:
            uc_only_count += 1
            uc_total += u[1]
            abs_delta += u[1]
            if first_break is None: first_break = d
            wcsv.writerow([metric, d, '', '', u[0], f"{u[1]:.4f}", '', '', '', 'UC_ONLY'])

    pct_gap = (abs_delta / syn_total * 100.0) if syn_total > 0 else 0.0

    if diffs == 0 and syn_only_count == 0 and uc_only_count == 0:
        verdict = "FINE"
    elif syn_only_count > 0 and diffs == 0 and uc_only_count == 0:
        verdict = f"BROKEN_FROM_{first_break}_(syn_has_uc_missing)"
    elif uc_only_count > 0 and diffs == 0 and syn_only_count == 0:
        verdict = f"UC_HAS_SYN_MISSING_FROM_{first_break}"
    elif diffs > 0:
        verdict = f"DIFF_FROM_{first_break}"
    else:
        verdict = "MIXED"
    metric_status.append((metric, verdict))

    print(f"  {metric:<28} {len(syn_days):>8} {len(uc_days):>7} {matches:>5} {diffs:>4} {syn_only_count:>8} {uc_only_count:>7} {syn_total:>14.2f} {uc_total:>14.2f} {abs_delta:>14.2f}")
    swcsv.writerow([metric, len(syn_days), len(uc_days), matches, diffs, syn_only_count, uc_only_count,
                    f"{syn_total:.4f}", f"{uc_total:.4f}", f"{abs_delta:.4f}", f"{pct_gap:.4f}"])

csv_f.close()
sf.close()

print()
print("=== VERDICT BY METRIC ===")
for m, v in metric_status:
    print(f"  {m:<28}  {v}")

print()
print(f"Per-(metric,day) CSV: {out_csv}")
print(f"Per-metric summary CSV: {summary_csv}")
