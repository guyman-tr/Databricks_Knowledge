#!/usr/bin/env python3
"""Phase B driver — Await + Compare + Drop.

For each target in the ring (event-driven, decoupled from Phase A):
  1. await_gold — poll until the gold table's etr_ymd=D-1 partition has rows
     (primary signal) or until DESCRIBE HISTORY shows today's commit (fallback).
  2. parity_gate — compare migration_parallel.X vs gold WHERE etr_ymd=D-1:
     rowcount + optional key aggregate. Raise on mismatch.
  3. drop — DROP TABLE migration_parallel.X (ephemeral lifecycle).

``fact_snapshotcustomer`` is in the skip_compare list; its clone is still dropped.

Usage:
  python -m tools.migration_autoloop.runtime.run_phase_b --ring 0
  python -m tools.migration_autoloop.runtime.run_phase_b --ring 0 --target-date 2026-06-23
  python -m tools.migration_autoloop.runtime.run_phase_b --ring 0 --poll-interval 60
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.freshness import (
    gold_state,
    run_date_default,
    target_date_default,
)
from tools.migration_autoloop.orchestration_targets import ALL_TARGETS, targets_for_ring
from tools.migration_autoloop.parallel_materializer import (
    PARALLEL_SCHEMA,
    drop_table,
)

OUT_DIR = Path("tools/migration_autoloop/out")

# Maximum time to wait for gold postflip per table (seconds).
DEFAULT_AWAIT_TIMEOUT_SEC = 4 * 3600  # 4 hours


def _await_gold_postflip(
    w, wid: str, target, *, target_date: str, run_date: str,
    poll_interval_sec: int = 120, timeout_sec: int = DEFAULT_AWAIT_TIMEOUT_SEC,
) -> dict:
    """Poll until the gold table is postflip for target_date."""
    deadline = time.time() + timeout_sec
    attempt = 0
    while True:
        attempt += 1
        gs = gold_state(
            w, wid, target.gold_table,
            target_date=target_date,
            run_date=run_date,
            date_column=target.gold_date_column,
        )
        print(f"[Phase B] await_gold {target.target_id} attempt={attempt} state={gs['state']} signal={gs.get('signal')}")
        if gs["state"] == "postflip":
            return {"target_id": target.target_id, "attempts": attempt, "gold_state": gs, "timed_out": False}
        if time.time() >= deadline:
            return {"target_id": target.target_id, "attempts": attempt, "gold_state": gs, "timed_out": True}
        time.sleep(poll_interval_sec)


def _parity_check(
    w, wid: str, target, *, target_date: str,
) -> dict:
    """Partition-scoped parity: migration_parallel.X vs gold WHERE etr_ymd=D-1.

    For tables without etr_ymd (has_etr_ymd=False), falls back to full rowcount.
    Raises RuntimeError (via execute_sql raise_error) on mismatch.
    """
    par = f"{PARALLEL_SCHEMA}.{target.parallel_table_name}"
    gold = target.gold_table

    if target.has_etr_ymd:
        etr_filter = f"WHERE etr_ymd = '{target_date}'"
    else:
        etr_filter = ""

    count_sql = f"""
WITH c AS (
  SELECT
    (SELECT COUNT(*) FROM {par} {etr_filter}) AS par_rows,
    (SELECT COUNT(*) FROM {gold} {etr_filter}) AS gold_rows
)
SELECT
  par_rows,
  gold_rows,
  CASE
    WHEN par_rows = gold_rows THEN 'PARITY_PASS'
    ELSE raise_error(CONCAT(
      'PARITY_FAIL target={target.target_id} etr_ymd={target_date} ',
      'par_rows=', CAST(par_rows AS STRING), ' gold_rows=', CAST(gold_rows AS STRING)
    ))
  END AS parity_status
FROM c
""".strip()

    started = time.time()
    try:
        cols, rows = execute_sql(w, sql_text=count_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        row = dict(zip(cols, rows[0])) if rows else {}
        result = {
            "target_id": target.target_id,
            "status": "pass",
            "parity_status": row.get("parity_status"),
            "par_rows": row.get("par_rows"),
            "gold_rows": row.get("gold_rows"),
            "elapsed_ms": int((time.time() - started) * 1000),
        }
        # Optional aggregate check
        if target.parity_agg_col and target.has_etr_ymd:
            agg_sql = f"""
WITH a AS (
  SELECT
    SUM(`{target.parity_agg_col}`) AS par_agg FROM {par} {etr_filter}
),
b AS (
  SELECT
    SUM(`{target.parity_agg_col}`) AS gold_agg FROM {gold} {etr_filter}
)
SELECT a.par_agg, b.gold_agg,
  CASE WHEN a.par_agg IS NOT DISTINCT FROM b.gold_agg THEN 'AGG_PASS'
       ELSE raise_error(CONCAT(
         'AGG_FAIL target={target.target_id} col={target.parity_agg_col} ',
         'par=', COALESCE(CAST(a.par_agg AS STRING), 'NULL'),
         ' gold=', COALESCE(CAST(b.gold_agg AS STRING), 'NULL')
       ))
  END AS agg_status
FROM a, b
""".strip()
            _, agg_rows = execute_sql(w, sql_text=agg_sql, warehouse_id=wid, poll_deadline_sec=1800.0)
            if agg_rows:
                result["par_agg"] = agg_rows[0][0]
                result["gold_agg"] = agg_rows[0][1]
                result["agg_status"] = agg_rows[0][2]
        return result
    except Exception as exc:
        return {
            "target_id": target.target_id,
            "status": "fail",
            "error": str(exc),
            "elapsed_ms": int((time.time() - started) * 1000),
        }


def run_phase_b(
    *,
    ring: int,
    target_date: str,
    run_date: str,
    poll_interval_sec: int = 120,
    await_timeout_sec: int = DEFAULT_AWAIT_TIMEOUT_SEC,
    skip_drop: bool = False,
    skip_wait: bool = False,
) -> dict:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    ring_targets = targets_for_ring(ring)
    started_total = time.time()

    result: dict = {
        "ring": ring,
        "target_date": target_date,
        "run_date": run_date,
        "targets": [t.target_id for t in ring_targets],
        "target_results": [],
        "overall_status": "pending",
    }

    overall = "success"
    for t in ring_targets:
        tgt_started = time.time()
        tgt_result: dict = {"target_id": t.target_id}

        if t.skip_compare:
            print(f"[Phase B] {t.target_id}: skip_compare=True — skipping parity, dropping clone.")
            tgt_result["parity"] = {"status": "skipped", "reason": "skip_compare=True"}
        else:
            if skip_wait:
                tgt_result["await_gold"] = {"skipped": True, "reason": "skip_wait_flag"}
            else:
                # 1. Await gold postflip
                print(f"[Phase B] {t.target_id}: awaiting gold postflip ...")
                await_result = _await_gold_postflip(
                    w, wid, t,
                    target_date=target_date,
                    run_date=run_date,
                    poll_interval_sec=poll_interval_sec,
                    timeout_sec=await_timeout_sec,
                )
                tgt_result["await_gold"] = await_result
                if await_result["timed_out"]:
                    tgt_result["parity"] = {"status": "skipped", "reason": "await_timed_out"}
                    overall = "partial"
                    print(f"[Phase B] {t.target_id}: AWAIT TIMED OUT after {await_result['attempts']} attempts")
                    # Drop clone even on timeout and continue to next target
                    if not skip_drop:
                        print(f"[Phase B] {t.target_id}: dropping migration_parallel.{t.parallel_table_name} ...")
                        drop_result = drop_table(w, wid, t.parallel_table_name)
                        tgt_result["drop"] = drop_result
                    else:
                        tgt_result["drop"] = {"action": "skipped"}
                    tgt_result["elapsed_ms"] = int((time.time() - tgt_started) * 1000)
                    result["target_results"].append(tgt_result)
                    OUT_DIR.mkdir(parents=True, exist_ok=True)
                    path = OUT_DIR / f"parallel_phase_b_{t.target_id}_{target_date}.json"
                    path.write_text(json.dumps(tgt_result, indent=2, default=str), encoding="utf-8")
                    print(f"[Phase B] {t.target_id} done, written: {path}")
                    continue

            # 2. Parity check (reached when skip_wait=True or postflip confirmed)
            print(f"[Phase B] {t.target_id}: running parity check ...")
            parity = _parity_check(w, wid, t, target_date=target_date)
            tgt_result["parity"] = parity
            if parity["status"] != "pass":
                overall = "failed"
                print(f"[Phase B] {t.target_id}: PARITY FAILED: {parity.get('error', '')}")

        # 3. Drop clone (always, even on parity failure — clones are ephemeral)
        if not skip_drop:
            print(f"[Phase B] {t.target_id}: dropping migration_parallel.{t.parallel_table_name} ...")
            drop_result = drop_table(w, wid, t.parallel_table_name)
            tgt_result["drop"] = drop_result
        else:
            tgt_result["drop"] = {"action": "skipped"}

        tgt_result["elapsed_ms"] = int((time.time() - tgt_started) * 1000)
        result["target_results"].append(tgt_result)

        OUT_DIR.mkdir(parents=True, exist_ok=True)
        path = OUT_DIR / f"parallel_phase_b_{t.target_id}_{target_date}.json"
        path.write_text(json.dumps(tgt_result, indent=2, default=str), encoding="utf-8")
        print(f"[Phase B] {t.target_id} done, written: {path}")

    result["overall_status"] = overall
    result["total_elapsed_ms"] = int((time.time() - started_total) * 1000)
    print(f"[Phase B] Ring {ring} done: {overall} ({result['total_elapsed_ms']} ms)")

    # Persist results to Delta so they survive after the cluster terminates
    try:
        import datetime as _dt
        ts = _dt.datetime.utcnow().isoformat()
        payload = json.dumps(result, default=str).replace("'", "''")[:30000]
        execute_sql(w, sql_text=(
            "CREATE TABLE IF NOT EXISTS dwh_daily_process.migration_parallel._phase_b_results "
            "(ts STRING, run_date STRING, target_date STRING, ring INT, overall_status STRING, payload STRING) "
            "USING DELTA"
        ), warehouse_id=wid)
        execute_sql(w, sql_text=(
            "INSERT INTO dwh_daily_process.migration_parallel._phase_b_results VALUES ("
            f"'{ts}', '{run_date}', '{target_date}', {ring}, '{overall}', '{payload}')"
        ), warehouse_id=wid)
        print(f"[Phase B] Results persisted to _phase_b_results")
    except Exception as _pe:
        print(f"[Phase B] WARNING: could not persist results to Delta: {_pe}")

    return result


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase B: await postflip -> parity -> drop clone.")
    ap.add_argument("--ring", type=int, default=0, help="Ring number (0-3).")
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD (D-1); default yesterday UTC.")
    ap.add_argument("--run-date", default="", help="YYYY-MM-DD (D); default today UTC.")
    ap.add_argument("--poll-interval", type=int, default=120, help="Seconds between gold-state polls.")
    ap.add_argument("--await-timeout", type=int, default=DEFAULT_AWAIT_TIMEOUT_SEC,
                    help="Max seconds to wait for gold postflip per table.")
    ap.add_argument("--skip-drop", action="store_true", help="Keep migration_parallel clones (debugging).")
    ap.add_argument("--skip-wait", action="store_true",
                    help="Skip gold postflip await and go straight to parity (shadow-validation mode).")
    ap.add_argument("--out-json", default="", help="Path for overall result JSON.")
    args = ap.parse_args()

    target_date = args.target_date.strip() or target_date_default()
    run_date = args.run_date.strip() or run_date_default()

    result = run_phase_b(
        ring=args.ring,
        target_date=target_date,
        run_date=run_date,
        poll_interval_sec=args.poll_interval,
        await_timeout_sec=args.await_timeout,
        skip_drop=args.skip_drop,
        skip_wait=args.skip_wait,
    )

    out_path = (
        Path(args.out_json)
        if args.out_json
        else OUT_DIR / f"parallel_phase_b_ring{args.ring}_{target_date}.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2, default=str), encoding="utf-8")
    print(json.dumps({"overall_status": result["overall_status"], "out_json": str(out_path)}, indent=2))
    return 0 if result["overall_status"] == "success" else 2


if __name__ == "__main__":
    raise SystemExit(main())
