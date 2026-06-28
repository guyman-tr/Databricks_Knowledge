#!/usr/bin/env python3
"""Run up to N autonomous FCUPNL attempts and stop on parity."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

MIGRATION_TABLE = "dwh_daily_process.migration_tables.fact_customerunrealized_pnl"
GOLD_TABLE = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl"


def _scalar(sql: str, poll_deadline_sec: float = 1800.0) -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=poll_deadline_sec)
    return int(rows[0][0]) if rows and rows[0] else 0


def _call_proc(name: str, target_date: str) -> None:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    execute_sql(
        w,
        sql_text=f"CALL dwh_daily_process.migration_tables.{name}(TIMESTAMP '{target_date}')",
        warehouse_id=wid,
        poll_deadline_sec=3600.0,
    )


def _run_qa_metrics(date_id: int) -> dict[str, float]:
    sql = f"""
WITH m AS (
       SELECT COUNT(*) AS rows_cnt, SUM(PositionPnL) AS sum_pnl, SUM(PositionPnL_old) AS sum_pnl_old, SUM(NOP) AS sum_nop, SUM(Notional) AS sum_notional
       FROM {MIGRATION_TABLE}
       WHERE DateModified = {date_id}
     ),
     g AS (
       SELECT COUNT(*) AS rows_cnt, SUM(PositionPnL) AS sum_pnl, SUM(PositionPnL_old) AS sum_pnl_old, SUM(NOP) AS sum_nop, SUM(Notional) AS sum_notional
       FROM {GOLD_TABLE}
       WHERE DateModified = {date_id}
     )
SELECT
  m.rows_cnt AS migration_rows,
  g.rows_cnt AS gold_rows,
  (m.sum_pnl - g.sum_pnl) AS delta_sum_pnl,
  (m.sum_pnl_old - g.sum_pnl_old) AS delta_sum_pnl_old,
  (m.sum_nop - g.sum_nop) AS delta_sum_nop,
  (m.sum_notional - g.sum_notional) AS delta_sum_notional
FROM m CROSS JOIN g
""".strip()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=7200.0)
    idx = {c: i for i, c in enumerate(cols)}
    row = rows[0]
    return {
        "migration_rows": int(row[idx["migration_rows"]]),
        "gold_rows": int(row[idx["gold_rows"]]),
        "delta_sum_pnl": float(row[idx["delta_sum_pnl"]] or 0.0),
        "delta_sum_pnl_old": float(row[idx["delta_sum_pnl_old"]] or 0.0),
        "delta_sum_nop": float(row[idx["delta_sum_nop"]] or 0.0),
        "delta_sum_notional": float(row[idx["delta_sum_notional"]] or 0.0),
    }


def _qa_pass(metrics: dict[str, float], tol_pnl_old: float = 0.02, tol_other: float = 0.000001) -> bool:
    return (
        metrics["migration_rows"] == metrics["gold_rows"]
        and math.isclose(metrics["delta_sum_pnl"], 0.0, abs_tol=tol_other)
        and math.isclose(metrics["delta_sum_pnl_old"], 0.0, abs_tol=tol_pnl_old)
        and math.isclose(metrics["delta_sum_nop"], 0.0, abs_tol=tol_other)
        and math.isclose(metrics["delta_sum_notional"], 0.0, abs_tol=tol_other)
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--target-date",
        default="",
        help="Target date YYYY-MM-DD. Default: yesterday UTC.",
    )
    ap.add_argument("--max-attempts", type=int, default=5)
    ap.add_argument(
        "--out-json",
        default="tools/migration_autoloop/out/fcupnl_overnight_attempts.json",
    )
    args = ap.parse_args()

    target_date = args.target_date.strip() or (
        dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)
    ).isoformat()
    date_id = int(target_date.replace("-", ""))
    attempts: list[dict[str, object]] = []
    final_status = "not_run"

    for i in range(1, args.max_attempts + 1):
        rec: dict[str, object] = {
            "attempt": i,
            "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "target_date": target_date,
        }
        try:
            _call_proc("sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc", target_date)
            _call_proc("sp_fact_customerunrealized_pnl_autopoc", target_date)
            rec["proc_calls"] = "ok"
            rec["migration_rows"] = _scalar(
                f"SELECT COUNT(*) FROM {MIGRATION_TABLE} WHERE DateModified={date_id}"
            )
            rec["gold_rows"] = _scalar(
                f"SELECT COUNT(*) FROM {GOLD_TABLE} WHERE DateModified={date_id}"
            )
            if rec["migration_rows"] == rec["gold_rows"] and int(rec["gold_rows"]) > 0:
                qa = _run_qa_metrics(date_id)
                rec["qa_metrics"] = qa
                if _qa_pass(qa):
                    rec["status"] = "qa_pass"
                    attempts.append(rec)
                    final_status = "qa_pass"
                    break
                rec["status"] = "rowcount_match_but_qa_diff_exists"
            else:
                rec["status"] = "rowcount_mismatch"
        except Exception as exc:  # noqa: BLE001
            rec["status"] = "error"
            rec["error"] = str(exc)
        attempts.append(rec)
    else:
        final_status = "max_attempts_reached_without_parity"

    out = {
        "target_date": target_date,
        "max_attempts": args.max_attempts,
        "final_status": final_status,
        "attempts": attempts,
        "finished_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    out_path = Path(args.out_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(json.dumps({"final_status": final_status, "out_json": str(out_path)}, indent=2))
    return 0 if final_status == "qa_pass" else 2


if __name__ == "__main__":
    raise SystemExit(main())

