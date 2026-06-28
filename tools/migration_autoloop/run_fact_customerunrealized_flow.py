#!/usr/bin/env python3
"""Run snapshot guard + orchestration + strict parity for Fact_CustomerUnrealized_PnL."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import subprocess
import sys
import time
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.snapshot_guard import ensure_snapshot_date

MIGRATION_TABLE = "dwh_daily_process.migration_tables.fact_customerunrealized_pnl"
GOLD_TABLE = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl"
DIM_CUSTOMER_TABLE = "dwh_daily_process.migration_tables.dim_customer"


def _date_id_for_snapshot(target_date: str) -> int:
    return int(target_date.replace("-", ""))


def _wait_job_success(job_id: int, timeout_sec: int) -> dict[str, object]:
    w = make_workspace_client()
    run = w.jobs.run_now(job_id=job_id)
    run_id = int(run.run_id)
    deadline = time.time() + timeout_sec
    while True:
        info = w.jobs.get_run(run_id=run_id)
        state_obj = info.state.life_cycle_state if info.state else ""
        result_obj = info.state.result_state if info.state else ""
        state = state_obj.name if hasattr(state_obj, "name") else str(state_obj or "")
        result = result_obj.name if hasattr(result_obj, "name") else str(result_obj or "")
        if state in {"TERMINATED", "SKIPPED", "INTERNAL_ERROR"}:
            return {
                "run_id": run_id,
                "state": state,
                "result_state": result,
                "state_message": info.state.state_message if info.state else "",
                "run_page_url": info.run_page_url,
            }
        if time.time() > deadline:
            return {
                "run_id": run_id,
                "state": "TIMEOUT",
                "result_state": "",
                "state_message": f"timeout after {timeout_sec}s",
                "run_page_url": info.run_page_url,
            }
        time.sleep(10)


def _qa_metrics_for_date(date_id: int) -> dict[str, float]:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    sql = f"""
WITH m AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(PositionPnL) AS sum_pnl,
    SUM(PositionPnL_old) AS sum_pnl_old,
    SUM(NOP) AS sum_nop,
    SUM(Notional) AS sum_notional
  FROM {MIGRATION_TABLE}
  WHERE DateModified = {date_id}
),
g AS (
  SELECT
    COUNT(*) AS rows_cnt,
    SUM(PositionPnL) AS sum_pnl,
    SUM(PositionPnL_old) AS sum_pnl_old,
    SUM(NOP) AS sum_nop,
    SUM(Notional) AS sum_notional
  FROM {GOLD_TABLE}
  WHERE DateModified = {date_id}
)
SELECT
  m.rows_cnt AS migration_rows,
  g.rows_cnt AS gold_rows,
  m.sum_pnl AS migration_sum_pnl,
  g.sum_pnl AS gold_sum_pnl,
  (m.sum_pnl - g.sum_pnl) AS delta_sum_pnl,
  m.sum_pnl_old AS migration_sum_pnl_old,
  g.sum_pnl_old AS gold_sum_pnl_old,
  (m.sum_pnl_old - g.sum_pnl_old) AS delta_sum_pnl_old,
  m.sum_nop AS migration_sum_nop,
  g.sum_nop AS gold_sum_nop,
  (m.sum_nop - g.sum_nop) AS delta_sum_nop,
  m.sum_notional AS migration_sum_notional,
  g.sum_notional AS gold_sum_notional,
  (m.sum_notional - g.sum_notional) AS delta_sum_notional
FROM m CROSS JOIN g
""".strip()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1200.0)
    row = rows[0]
    idx = {c: i for i, c in enumerate(cols)}
    out: dict[str, float] = {}
    for k in cols:
        v = row[idx[k]]
        if k.endswith("_rows"):
            out[k] = int(v or 0)
        else:
            out[k] = float(v or 0.0)
    return out


def _qa_pass(metrics: dict[str, float], tol_pnl_old: float = 0.02, tol_other: float = 0.000001) -> bool:
    if int(metrics["migration_rows"]) != int(metrics["gold_rows"]):
        return False
    if not math.isclose(metrics["delta_sum_pnl"], 0.0, abs_tol=tol_other):
        return False
    if not math.isclose(metrics["delta_sum_pnl_old"], 0.0, abs_tol=tol_pnl_old):
        return False
    if not math.isclose(metrics["delta_sum_nop"], 0.0, abs_tol=tol_other):
        return False
    if not math.isclose(metrics["delta_sum_notional"], 0.0, abs_tol=tol_other):
        return False
    return True


def _rewind_dim_customer_to_yesterday_baseline(target_date: str) -> dict[str, object]:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = f"""
SELECT version, timestamp, operation, userName
FROM (DESCRIBE HISTORY {DIM_CUSTOMER_TABLE})
WHERE timestamp < TIMESTAMP(DATEADD(DAY, 1, DATE('{target_date}')))
  AND operation NOT IN ('VACUUM START', 'VACUUM END')
ORDER BY version DESC
LIMIT 1
""".strip()
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    if not rows:
        return {"rewound": False, "reason": "no_baseline_version_found"}
    row = rows[0]
    idx = {c: i for i, c in enumerate(cols)}
    baseline_version = int(row[idx["version"]])
    baseline_ts = str(row[idx["timestamp"]])
    baseline_op = str(row[idx["operation"]])
    baseline_user = str(row[idx["userName"]])

    execute_sql(
        w,
        sql_text=f"RESTORE TABLE {DIM_CUSTOMER_TABLE} TO VERSION AS OF {baseline_version}",
        warehouse_id=wid,
        poll_deadline_sec=1800.0,
    )
    return {
        "rewound": True,
        "baseline_version": baseline_version,
        "baseline_timestamp": baseline_ts,
        "baseline_operation": baseline_op,
        "baseline_user": baseline_user,
    }


def _refresh_special_snapshot_views(target_date: str) -> dict[str, object]:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    d = dt.date.fromisoformat(target_date)
    d_prev = d - dt.timedelta(days=1)

    def _path(day: dt.date) -> str:
        iso = day.isoformat()
        return (
            "abfss://internal-sources@dldataplatformprodwe.dfs.core.windows.net/"
            f"Bronze/DailySnapshot/etr_y={day.year}/etr_ym={day.year}-{day.month:02d}/etr_ymd={iso}/"
            "etoro/History/BackOfficeCustomer"
        )

    path_d = _path(d)
    path_prev = _path(d_prev)
    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE VIEW dwh_daily_process.migration_tables.vw_fcupnl_backofficecustomer_target "
            "AS "
            f"SELECT * FROM parquet.`{path_d}` UNION ALL SELECT * FROM parquet.`{path_prev}`"
        ),
        warehouse_id=wid,
        poll_deadline_sec=1200.0,
    )
    execute_sql(
        w,
        sql_text=(
            "CREATE OR REPLACE VIEW dwh_daily_process.migration_tables.vw_fcupnl_currencypricemaxdate_target "
            "AS SELECT * FROM dwh_daily_process.daily_snapshot.pricelog_candles_currencypricemaxdatewithsplitview"
        ),
        warehouse_id=wid,
        poll_deadline_sec=1200.0,
    )
    return {"refreshed": True, "backoffice_days": [target_date, d_prev.isoformat()]}


def _ensure_autopoc_procs(target_date: str) -> dict[str, object]:
    patch_script = Path(__file__).with_name("patch_customerunrealized_autopoc.py")
    cmd = [sys.executable, str(patch_script), "--run-date", target_date]
    run = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return {"run_date": target_date, "stdout": run.stdout.strip()}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--job-id", type=int, default=18080659306023, help="Databricks job id for the orchestration.")
    ap.add_argument("--target-date", default="", help="Snapshot date YYYY-MM-DD. Default: yesterday UTC.")
    ap.add_argument("--auto-refresh-snapshot", action="store_true", help="Refresh stale daily_snapshot locations.")
    ap.add_argument(
        "--rewind-dim-customer",
        action="store_true",
        help="Restore dim_customer to prior-day baseline before orchestration.",
    )
    ap.add_argument(
        "--out-json",
        default="tools/migration_autoloop/runtime/fact_customerunrealized_flow_report.json",
        help="Output report path.",
    )
    ap.add_argument("--tol-pnl-old", type=float, default=0.02, help="Absolute tolerance for SUM(PositionPnL_old).")
    args = ap.parse_args()

    target_date = args.target_date.strip() or (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()
    autopoc_proc_regen = _ensure_autopoc_procs(target_date)
    snapshot = ensure_snapshot_date(
        warehouse_id=warehouse_id_from_env(),
        target_date=target_date,
        proc_name="sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
        auto_refresh=args.auto_refresh_snapshot,
    )
    special_snapshot_views = _refresh_special_snapshot_views(target_date)
    dim_customer_rewind = (
        _rewind_dim_customer_to_yesterday_baseline(target_date) if args.rewind_dim_customer else {"rewound": False}
    )
    date_id = _date_id_for_snapshot(target_date)
    run = _wait_job_success(args.job_id, timeout_sec=3600)
    qa_metrics = _qa_metrics_for_date(date_id)
    parity_pass = _qa_pass(qa_metrics, tol_pnl_old=args.tol_pnl_old)
    report = {
        "target_date": target_date,
        "date_id": date_id,
        "autopoc_proc_regen": autopoc_proc_regen,
        "snapshot_guard": snapshot,
        "special_snapshot_views": special_snapshot_views,
        "dim_customer_rewind": dim_customer_rewind,
        "job_run": run,
        "qa_date_scope": {**qa_metrics, "qa_pass": parity_pass},
    }

    out_path = Path(args.out_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(
        json.dumps(
            {
                "report": str(out_path),
                "job_state": run["state"],
                "job_result_state": run["result_state"],
                "dim_customer_rewind": dim_customer_rewind,
                "qa_date_scope": report["qa_date_scope"],
            },
            indent=2,
        )
    )
    return 0 if (run["result_state"] == "SUCCESS" and parity_pass) else 2


if __name__ == "__main__":
    raise SystemExit(main())

