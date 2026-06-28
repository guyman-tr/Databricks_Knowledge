#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


TARGETS = [
    ("fact_snapshotcustomercloseyear_retry", "sp_fact_snapshotcustomercloseyear", True, 10.0, 20.0, 30.0),
    ("fact_regulationtransfer_retry", "sp_fact_regulationtransfer_autopoc", True, 10.0, 20.0, 30.0),
]


def _sql_escape(value: str) -> str:
    return value.replace("'", "''")


def _insert_row(w, wid: str, row: dict[str, object]) -> None:
    sql = f"""
INSERT INTO dwh_daily_process.qa.autoloop_flow_telemetry
SELECT
  current_timestamp(),
  '{_sql_escape(str(row["flow_key"]))}',
  '{_sql_escape(str(row["proc_name"]))}',
  DATE '{_sql_escape(str(row["target_date"]))}',
  '{_sql_escape(str(row["run_status"]))}',
  {str(bool(row["parity_pass"])).lower()},
  {int(row["return_code"])},
  {int(row["mapped_table_count"])},
  {int(row["pass_count"])},
  {int(row["fail_count"])},
  '{_sql_escape(str(row["report_path"]))}',
  '{_sql_escape(str(row["report_json"]))}',
  {float(row["model_cost_usd_low"])},
  {float(row["model_cost_usd_mid"])},
  {float(row["model_cost_usd_high"])},
  {float(row["cumulative_mid_usd"])},
  '{_sql_escape(str(row["notes"]))}'
"""
    execute_sql(w, sql_text=sql, warehouse_id=wid)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target-date", default="")
    ap.add_argument("--start-cumulative-mid", type=float, default=90.0)
    args = ap.parse_args()

    target_date = args.target_date.strip() or (
        dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)
    ).isoformat()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cumulative_mid = float(args.start_cumulative_mid)
    results = []

    for flow_key, proc_name, has_date, low, mid, high in TARGETS:
        report_path = Path(f"tools/migration_autoloop/out/{proc_name}_parity_{target_date}.json")
        cmd = [
            sys.executable,
            "tools/migration_autoloop/evaluate_proc_parity.py",
            "--proc-name",
            proc_name,
            "--target-date",
            target_date,
            "--out-json",
            str(report_path),
        ]
        if has_date:
            cmd.append("--has-date-param")
        proc = subprocess.run(cmd, capture_output=True, text=True)
        report = {}
        if report_path.exists():
            try:
                report = json.loads(report_path.read_text(encoding="utf-8"))
            except Exception:
                report = {}
        mapped = int(report.get("mapped_table_count") or 0)
        parity_pass = bool(report.get("all_pass"))
        run_status = "success" if proc.returncode == 0 and parity_pass else ("executed_no_mapping" if proc.returncode == 0 and mapped == 0 else "failed")
        cumulative_mid += mid
        notes = (proc.stderr or proc.stdout or "").strip()
        if len(notes) > 3000:
            notes = notes[:3000] + " ...truncated..."

        row = {
            "flow_key": flow_key,
            "proc_name": proc_name,
            "target_date": target_date,
            "run_status": run_status,
            "parity_pass": parity_pass,
            "return_code": proc.returncode,
            "mapped_table_count": mapped,
            "pass_count": int(report.get("pass_count") or 0),
            "fail_count": int(report.get("fail_count") or 0),
            "report_path": str(report_path),
            "report_json": json.dumps(report, ensure_ascii=True),
            "model_cost_usd_low": low,
            "model_cost_usd_mid": mid,
            "model_cost_usd_high": high,
            "cumulative_mid_usd": cumulative_mid,
            "notes": notes,
        }
        _insert_row(w, wid, row)
        results.append(row)

    print(json.dumps({"target_date": target_date, "cumulative_mid_usd": cumulative_mid, "results": results}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
