"""Generate a readable CSV report of the latest orchestration run results."""
import sys, json, csv
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql

w = make_workspace_client()
wid = "6f72189f967b42a9"

_, rows = execute_sql(w,
    sql_text=(
        "SELECT ts, run_date, ring, overall_status, payload "
        "FROM dwh_daily_process.migration_parallel._phase_b_results "
        "ORDER BY ts DESC LIMIT 40"
    ),
    warehouse_id=wid)

latest = {}
for r in rows:
    ts, run_date, ring, overall, payload_str = r
    ring = int(ring)
    if ring not in latest:
        latest[ring] = (ts, run_date, overall, payload_str)

# Also pull skip_compare and reason from orchestration_targets
import importlib, sys as _sys
_sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.orchestration_targets import ALL_TARGETS

SKIP_REASONS = {
    "dictionaries":              "Multi-table proc (Dim_Affiliate, Dim_CountryBin, etc.) — no single output to compare",
    "dictionaries_country":      "Parity deferred until proc output confirmed",
    "channel_affiliate":         "No gold equivalent for Dim_Channel_Affiliate_UnifyCode",
    "dim_mirror":                "Accumulating SCD — 1-day increment ≠ full 11M-row gold",
    "fact_currencypricewithsplit": "Gold stamps ALL historical rows with load date; proc only merges new splits",
    "fact_deposit_state":        "Full-history state table (22M+); single-day increment can't match total",
    "fact_cashout_state":        "Full-history state table; single-day increment can't match total",
    "fact_billingredeem":        "7-day rolling window: proc loads D-7..D-1, gold only counts modified=D-1",
    "fact_regulationtransfer":   "Snapshot ValidFrom timing differs from Synapse cutoff (11 vs 973 rows)",
    "fact_history_cost":         "Lake captures all intra-day events (6.5M); Synapse ETL loads filtered subset (3.3M)",
    "dim_positionchangelog":     "Lake snapshot captures late-arriving changes Synapse missed (+10K expected delta)",
    "fact_guru_copiers":         "Cross-ring dependency: JOINs Fact_SnapshotCustomer (Ring 2) before it is populated",
    "fact_customerunrealized_pnl": "Delta -448/2.8M (0.016%) — within noise from baseline timing",
    "fact_customeraction_etl":   "Proc patched to no-op to preserve existing migrated data slice",
    "fact_snapshotequity":       "Full-history view (863M rows); parallel holds only 1-day increment",
    "dim_customer":              "Full SCD2 history (48M rows); parallel holds only 1-day delta",
    "fact_snapshotcustomer":     "Frozen SCD — DE has not refreshed the gold mirror yet",
    "dim_position":              "First run: 142M open positions → produces D-1 increment only; proc success = validation",
    "positionhedgeserverchangelog": "",
}

report_rows = []
for ring in sorted(latest):
    ts, run_date, overall, payload_str = latest[ring]
    try:
        payload = json.loads(payload_str)
        for tr in payload.get("target_results", []):
            tid = tr.get("target_id", "?")
            par = tr.get("parity", {})
            status = par.get("status", "?")
            par_rows = par.get("par_rows", "")
            gold_rows = par.get("gold_rows", "")
            msg = par.get("message", "") or par.get("reason", "")
            skip_reason = SKIP_REASONS.get(tid, "")
            tgt = ALL_TARGETS.get(tid)
            gold_table = tgt.gold_table if tgt else ""
            parallel_table = tgt.parallel_table_name if tgt else ""
            report_rows.append({
                "ring": ring,
                "target_id": tid,
                "parallel_table": parallel_table,
                "gold_table": gold_table,
                "run_date": run_date,
                "run_ts": ts,
                "phase_b_status": status,
                "par_rows": par_rows,
                "gold_rows": gold_rows,
                "phase_b_message": msg,
                "skip_reason": skip_reason,
            })
    except Exception as e:
        print(f"parse error ring {ring}: {e}")

out_path = r"c:\Users\guyman\Documents\github\Databricks_Knowledge\tools\migration_autoloop\out\orchestration_report.csv"
with open(out_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=[
        "ring", "target_id", "parallel_table", "gold_table",
        "run_date", "run_ts", "phase_b_status", "par_rows", "gold_rows",
        "phase_b_message", "skip_reason"
    ])
    writer.writeheader()
    writer.writerows(report_rows)

print(f"Written: {out_path}")
print(f"Total targets: {len(report_rows)}")
pass_count = sum(1 for r in report_rows if r["phase_b_status"] == "pass")
skip_count = sum(1 for r in report_rows if r["phase_b_status"] == "skipped")
fail_count  = sum(1 for r in report_rows if r["phase_b_status"] == "fail")
print(f"  pass:    {pass_count}")
print(f"  skipped: {skip_count}  (populated but parity check deferred)")
print(f"  fail:    {fail_count}")
