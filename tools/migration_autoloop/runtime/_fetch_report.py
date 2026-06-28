"""
Fetch the latest daily orchestration report from Databricks and write it locally.

Run this any time after the nightly orchestrator job completes:
  python tools/migration_autoloop/runtime/_fetch_report.py

Writes:
  tools/migration_autoloop/out/orchestration_report.md   ← readable narrative
  tools/migration_autoloop/out/orchestration_report.csv  ← open in Excel
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
from tools.migration_autoloop.db import make_workspace_client, execute_sql

WAREHOUSE_ID = "6f72189f967b42a9"
OUT_DIR = Path(__file__).resolve().parents[3] / "tools" / "migration_autoloop" / "out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

w = make_workspace_client()
_, rows = execute_sql(w,
    sql_text=(
        "SELECT ts, run_date, report_md, report_csv "
        "FROM dwh_daily_process.migration_parallel._daily_report "
        "ORDER BY ts DESC LIMIT 1"
    ),
    warehouse_id=WAREHOUSE_ID)

if not rows:
    print("No report found in _daily_report yet. Has the nightly job run?")
    sys.exit(1)

ts, run_date, report_md, report_csv = rows[0]

md_path  = OUT_DIR / "orchestration_report.md"
csv_path = OUT_DIR / "orchestration_report.csv"

md_path.write_text(report_md, encoding="utf-8")
csv_path.write_text(report_csv, encoding="utf-8")

print(f"Report for run_date={run_date} (generated {ts})")
print(f"  {md_path}")
print(f"  {csv_path}")
