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


DEFAULT_FLOWS = [
    "dim_mirror",
    "fact_deposit_state",
    "fact_cashout_state",
    "dim_historysplitratio",
    "dim_customer",
]


def _target_date(value: str) -> str:
    if value.strip():
        return value.strip()
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def _sql_escape(value: str) -> str:
    return value.replace("'", "''")


def _latest_cumulative_mid(w, wid: str) -> float:
    cols, rows = execute_sql(
        w,
        sql_text=(
            "SELECT COALESCE(MAX(cumulative_mid_usd), 0.0) AS c "
            "FROM dwh_daily_process.qa.autoloop_flow_telemetry"
        ),
        warehouse_id=wid,
    )
    if not rows:
        return 0.0
    idx = cols.index("c")
    return float(rows[0][idx] or 0.0)


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
    ap = argparse.ArgumentParser(description="Run 5 flows and write telemetry to QA table under cost cap.")
    ap.add_argument("--target-date", default="")
    ap.add_argument("--cost-cap-mid-usd", type=float, default=200.0)
    ap.add_argument("--mid-per-flow", type=float, default=10.0)
    args = ap.parse_args()

    target_date = _target_date(args.target_date)
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cumulative_mid = _latest_cumulative_mid(w, wid)
    results: list[dict[str, object]] = []

    for flow_id in DEFAULT_FLOWS:
        projected = cumulative_mid + float(args.mid_per_flow)
        if projected > float(args.cost_cap_mid_usd):
            row = {
                "flow_key": flow_id,
                "proc_name": "",
                "target_date": target_date,
                "run_status": "skipped_cost_cap",
                "parity_pass": False,
                "return_code": 99,
                "mapped_table_count": 0,
                "pass_count": 0,
                "fail_count": 0,
                "report_path": "",
                "report_json": "",
                "model_cost_usd_low": float(args.mid_per_flow) * 0.5,
                "model_cost_usd_mid": float(args.mid_per_flow),
                "model_cost_usd_high": float(args.mid_per_flow) * 1.5,
                "cumulative_mid_usd": cumulative_mid,
                "notes": f"Skipped due to cap {args.cost_cap_mid_usd}",
            }
            _insert_row(w, wid, row)
            results.append(row)
            continue

        out_json = Path(f"tools/migration_autoloop/out/{flow_id}_trust_report_{target_date}.json")
        cmd = [
            sys.executable,
            "tools/migration_autoloop/run_flow_autoloop_report.py",
            "--flow-id",
            flow_id,
            "--target-date",
            target_date,
            "--out-json",
            str(out_json),
            "--out-md",
            f"tools/migration_autoloop/out/{flow_id}_trust_report_{target_date}.md",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        report = {}
        if out_json.exists():
            try:
                report = json.loads(out_json.read_text(encoding="utf-8"))
            except Exception as exc:  # noqa: BLE001
                report = {"error": f"report_parse_failed: {exc}"}
        parity_pass = bool(report.get("qa_pass_migration_vs_gold"))
        mapped = int(1 if report.get("migration_table") else 0)
        run_status = "success" if proc.returncode == 0 and parity_pass else "failed"
        cumulative_mid = projected
        notes = (proc.stderr or proc.stdout or "").strip()
        if len(notes) > 3000:
            notes = notes[:3000] + " ...truncated..."
        row = {
            "flow_key": flow_id,
            "proc_name": str(report.get("procedure_name") or ""),
            "target_date": target_date,
            "run_status": run_status,
            "parity_pass": parity_pass,
            "return_code": int(proc.returncode),
            "mapped_table_count": mapped,
            "pass_count": int(1 if parity_pass else 0),
            "fail_count": int(0 if parity_pass else 1),
            "report_path": str(out_json),
            "report_json": json.dumps(report, ensure_ascii=True),
            "model_cost_usd_low": float(args.mid_per_flow) * 0.5,
            "model_cost_usd_mid": float(args.mid_per_flow),
            "model_cost_usd_high": float(args.mid_per_flow) * 1.5,
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
                "mid_per_flow": args.mid_per_flow,
                "final_cumulative_mid_usd": cumulative_mid,
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
