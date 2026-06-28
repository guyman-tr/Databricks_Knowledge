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


TARGETS: list[dict[str, object]] = [
    {
        "flow_key": "fact_currencypricewithsplit",
        "proc_name": "sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
        "has_date_param": True,
        "cost_low": 8.0,
        "cost_mid": 15.0,
        "cost_high": 25.0,
    },
    {
        "flow_key": "validation_cycle_gap",
        "proc_name": "sp_validation_cycle_gap_dl_to_synapse",
        "has_date_param": True,
        "cost_low": 10.0,
        "cost_mid": 20.0,
        "cost_high": 30.0,
    },
    {
        "flow_key": "fact_snapshotcustomercloseyear",
        "proc_name": "sp_fact_snapshotcustomercloseyear",
        "has_date_param": True,
        "cost_low": 10.0,
        "cost_mid": 20.0,
        "cost_high": 30.0,
    },
    {
        "flow_key": "fact_regulationtransfer",
        "proc_name": "sp_fact_regulationtransfer_autopoc",
        "has_date_param": True,
        "cost_low": 10.0,
        "cost_mid": 20.0,
        "cost_high": 30.0,
    },
    {
        "flow_key": "daily_marketpageviews",
        "proc_name": "sp_daily_marketpageviews_dl_to_synapse",
        "has_date_param": True,
        "cost_low": 8.0,
        "cost_mid": 15.0,
        "cost_high": 25.0,
    },
]


def _target_date(value: str) -> str:
    if value.strip():
        return value.strip()
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def _sql_escape(value: str) -> str:
    return value.replace("'", "''")


def _ensure_table(w, wid: str) -> None:
    sql = """
CREATE TABLE IF NOT EXISTS dwh_daily_process.qa.autoloop_flow_telemetry (
  event_ts TIMESTAMP,
  flow_key STRING,
  proc_name STRING,
  target_date DATE,
  run_status STRING,
  parity_pass BOOLEAN,
  return_code INT,
  mapped_table_count INT,
  pass_count INT,
  fail_count INT,
  report_path STRING,
  report_json STRING,
  model_cost_usd_low DOUBLE,
  model_cost_usd_mid DOUBLE,
  model_cost_usd_high DOUBLE,
  cumulative_mid_usd DOUBLE,
  notes STRING
)
USING DELTA
"""
    execute_sql(w, sql_text=sql, warehouse_id=wid)


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
    ap = argparse.ArgumentParser(description="Run queued flows and persist QA telemetry to QA table.")
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD (default yesterday UTC)")
    ap.add_argument("--cost-cap-mid-usd", type=float, default=200.0)
    args = ap.parse_args()

    target_date = _target_date(args.target_date)
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    _ensure_table(w, wid)

    cumulative_mid = 0.0
    results: list[dict[str, object]] = []

    for t in TARGETS:
        next_mid = cumulative_mid + float(t["cost_mid"])
        if next_mid > float(args.cost_cap_mid_usd):
            results.append(
                {
                    "flow_key": t["flow_key"],
                    "proc_name": t["proc_name"],
                    "target_date": target_date,
                    "run_status": "skipped_cost_cap",
                    "parity_pass": False,
                    "return_code": 99,
                    "mapped_table_count": 0,
                    "pass_count": 0,
                    "fail_count": 0,
                    "report_path": "",
                    "report_json": "",
                    "model_cost_usd_low": float(t["cost_low"]),
                    "model_cost_usd_mid": float(t["cost_mid"]),
                    "model_cost_usd_high": float(t["cost_high"]),
                    "cumulative_mid_usd": cumulative_mid,
                    "notes": f"Skipped due to cap {args.cost_cap_mid_usd}",
                }
            )
            continue

        proc_name = str(t["proc_name"])
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
        if bool(t["has_date_param"]):
            cmd.append("--has-date-param")

        proc = subprocess.run(cmd, capture_output=True, text=True)
        report: dict[str, object] = {}
        if report_path.exists():
            try:
                report = json.loads(report_path.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001
                report = {"error": f"report_parse_failed: {exc}"}

        mapped_count = int(report.get("mapped_table_count") or 0)
        parity_pass = bool(report.get("all_pass"))
        if proc.returncode == 0 and parity_pass:
            run_status = "success"
        elif proc.returncode == 0 and mapped_count == 0:
            run_status = "executed_no_mapping"
        else:
            run_status = "failed"
        cumulative_mid += float(t["cost_mid"])
        notes = (proc.stderr or proc.stdout or "").strip()
        if len(notes) > 3000:
            notes = notes[:3000] + " ...truncated..."

        row = {
            "flow_key": t["flow_key"],
            "proc_name": proc_name,
            "target_date": target_date,
            "run_status": run_status,
            "parity_pass": parity_pass,
            "return_code": int(proc.returncode),
            "mapped_table_count": mapped_count,
            "pass_count": int(report.get("pass_count") or 0),
            "fail_count": int(report.get("fail_count") or 0),
            "report_path": str(report_path),
            "report_json": json.dumps(report, ensure_ascii=True),
            "model_cost_usd_low": float(t["cost_low"]),
            "model_cost_usd_mid": float(t["cost_mid"]),
            "model_cost_usd_high": float(t["cost_high"]),
            "cumulative_mid_usd": cumulative_mid,
            "notes": notes,
        }
        _insert_row(w, wid, row)
        results.append(row)

    print(
        json.dumps(
            {
                "target_date": target_date,
                "cost_cap_mid_usd": args.cost_cap_mid_usd,
                "cumulative_mid_usd": cumulative_mid,
                "table": "dwh_daily_process.qa.autoloop_flow_telemetry",
                "results": results,
            },
            indent=2,
        )
    )
    all_success = all(r["run_status"] == "success" for r in results if r["run_status"] != "skipped_cost_cap")
    return 0 if all_success else 2


if __name__ == "__main__":
    raise SystemExit(main())
