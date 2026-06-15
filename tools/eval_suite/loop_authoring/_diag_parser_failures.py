"""Print the FULL agent reply for the 4 cases the parser misclassified."""
from __future__ import annotations
import csv
from pathlib import Path

CSV = Path("audits/eval_suite/runs/run-trace-15case-20260614-075302.csv")
INTEREST = {
    "ddr_mimo_global_deposits_count_yesterday",
    "ddr_revenue_full_commission_yesterday",
    "ddr_pnl_total_position_pnl_yesterday",
    "ddr_pnl_daily_total_pnl_yesterday",
}

with open(CSV, encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

for r in rows:
    if r["case_id"] not in INTEREST:
        continue
    print(f"\n{'='*78}\nCASE: {r['case_id']}")
    print(f"  expected={r['expected_value']}  observed={r['observed_value']}  diff_pct={r['diff_pct']}")
    print("=" * 78)
    print(r["sut_text_answer"])
