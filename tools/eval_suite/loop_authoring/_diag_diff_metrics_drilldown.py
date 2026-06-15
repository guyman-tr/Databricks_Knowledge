"""For every metric flagged DIFF/BROKEN, show the actual mismatching days."""
from __future__ import annotations
import os, sys, csv

CSV_PATH = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                         '..', '..', '..', 'audits', 'eval_suite', 'all_metrics_since_jan.csv'))

with open(CSV_PATH, encoding='utf-8') as f:
    rows = list(csv.DictReader(f))

# group by metric, only non-MATCH rows
from collections import defaultdict
buckets: dict[str, list[dict]] = defaultdict(list)
for r in rows:
    if r['status'] != 'MATCH':
        buckets[r['Metric']].append(r)

for metric in sorted(buckets):
    print(f"\n=== {metric}  ({len(buckets[metric])} non-match days) ===")
    print(f"  {'DateID':<10} {'syn_rows':>8} {'syn_sum':>16} {'uc_rows':>8} {'uc_sum':>16} {'Δ_rows':>7} {'Δ_sum':>14} {'%Δ':>7}  status")
    for r in buckets[metric]:
        d = r['DateID']
        sr = r['syn_rows'] or '-'; ss = r['syn_sum'] or '-'
        ur = r['uc_rows'] or '-'; us = r['uc_sum'] or '-'
        rd = r['rows_delta'] or '-'; sd = r['sum_delta'] or '-'
        pct = r['pct_delta'] or '-'
        print(f"  {d:<10} {sr:>8} {ss:>16} {ur:>8} {us:>16} {rd:>7} {sd:>14} {pct:>6}%  {r['status']}")
