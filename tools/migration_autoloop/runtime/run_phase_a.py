#!/usr/bin/env python3
"""Phase A driver — Capture + Run.

Execution sequence for a given ring:
  1. gate  — bronze D-1 ready (gold pre-flip check skipped: we run post-flip by design).
  2. snapshot_guard — point daily_snapshot.* at etr_ymd=D-1 (auto-refresh).
  3. materialize — SHALLOW CLONE gold AS OF 01:00 UTC (pre-flip baseline) + rewrite procs.
  4. run — CALL each target's wrapper proc for D-1, in dependency order.

Gold tables flip at ~03:32-04:49 UTC; Phase A runs at 07:30 UTC (post-flip).
Using TIMESTAMP AS OF 01:00 UTC ensures every clone reflects the D-2 state so
proc increments are genuinely new rows, not stale re-inserts of gold's existing data.

Emit one JSON result file per target to out/parallel_phase_a_{target_id}.json.

Usage:
  python -m tools.migration_autoloop.runtime.run_phase_a --ring 0
  python -m tools.migration_autoloop.runtime.run_phase_a --ring 0 --target-date 2026-06-23
  python -m tools.migration_autoloop.runtime.run_phase_a --ring 0 --skip-gate
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import date, timedelta
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.freshness import (
    bronze_ready,
    run_date_default,
    target_date_default,
)
from tools.migration_autoloop.orchestration_targets import ALL_TARGETS, targets_for_ring
from tools.migration_autoloop.parallel_materializer import PARALLEL_SCHEMA, materialize_target
from tools.migration_autoloop.snapshot_guard import ensure_snapshot_date

OUT_DIR = Path("tools/migration_autoloop/out")


def _ts() -> float:
    return time.time()


def _run_proc(w, wid: str, proc_call_sql: str) -> dict:
    started = _ts()
    try:
        cols, rows = execute_sql(w, sql_text=proc_call_sql, warehouse_id=wid, poll_deadline_sec=7200.0)
        return {
            "status": "success",
            "elapsed_ms": int((_ts() - started) * 1000),
            "columns": cols,
            "sample_row": rows[0] if rows else [],
        }
    except Exception as exc:
        return {
            "status": "failed",
            "elapsed_ms": int((_ts() - started) * 1000),
            "error": str(exc),
        }


def _gate_check(
    w, wid: str, *, ring: int, target_date: str, run_date: str, skip_gate: bool
) -> dict:
    """Return gate result dict. Raises SystemExit(1) if gate fails and not --skip-gate.

    Gate checks bronze readiness only. Gold pre-flip is NOT checked: we intentionally
    run post-flip and use TIMESTAMP AS OF to clone the pre-flip baseline.
    """
    if skip_gate:
        return {"passed": True, "skipped": True}

    ring_targets = targets_for_ring(ring)

    # Bronze check — union all wrapper procs across the ring
    proc_names = [t.wrapper_proc for t in ring_targets]
    bronze = bronze_ready(w, wid, target_date=target_date, proc_names=proc_names)

    gate_passed = bronze.ready
    return {
        "passed": gate_passed,
        "bronze": bronze.as_dict(),
    }


def run_phase_a(
    *,
    ring: int,
    target_date: str,
    run_date: str,
    skip_gate: bool = False,
    dry_run: bool = False,
) -> dict:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    ring_targets = targets_for_ring(ring)
    started_total = _ts()

    result: dict = {
        "ring": ring,
        "target_date": target_date,
        "run_date": run_date,
        "targets": [t.target_id for t in ring_targets],
        "gate": None,
        "snapshot_guard": None,
        "target_results": [],
        "overall_status": "pending",
    }

    # 1. Gate
    print(f"[Phase A] Ring {ring} | target_date={target_date} | {len(ring_targets)} targets")
    print("[Phase A] Step 1: gate check ...")
    gate = _gate_check(w, wid, ring=ring, target_date=target_date, run_date=run_date, skip_gate=skip_gate)
    result["gate"] = gate
    if not gate["passed"]:
        result["overall_status"] = "gate_failed"
        print(f"[Phase A] GATE FAILED: {json.dumps(gate, indent=2, default=str)}")
        return result
    print(f"[Phase A] Gate passed (bronze_ready={gate.get('bronze', {}).get('ready')})")

    if dry_run:
        result["overall_status"] = "dry_run_stop"
        return result

    # 2. Snapshot guard — point daily_snapshot at target_date for all procs in ring.
    # Some tables in daily_snapshot are owned by the platform team; ALTER TABLE on
    # those raises PERMISSION_DENIED which we treat as a warning (the table was
    # already pointed to the right partition by the platform ETL).
    print("[Phase A] Step 2: snapshot_guard ...")
    sg_results = []
    sg_hard_failed = False
    for t in ring_targets:
        try:
            sg = ensure_snapshot_date(
                warehouse_id=wid,
                target_date=target_date,
                proc_name=t.wrapper_proc,
                auto_refresh=True,
            )
            warn = int(sg.get("unresolved_count", 0)) > 0
            sg_results.append({"target_id": t.target_id, "snapshot_guard": sg, "warning": warn})
            if warn:
                print(f"[Phase A] Snapshot guard WARNING for {t.target_id}: unresolved={sg['unresolved_count']}")
        except RuntimeError as exc:
            err_str = str(exc)
            if "permission_denied" in err_str.lower() or "manage on table" in err_str.lower():
                print(f"[Phase A] Snapshot guard PERMISSION_DENIED for {t.target_id} (platform table, treating as current): {err_str[:200]}")
                sg_results.append({"target_id": t.target_id, "snapshot_guard": {"note": "permission_denied_skipped"}, "warning": True})
            else:
                sg_results.append({"target_id": t.target_id, "snapshot_guard": {"error": err_str}, "warning": False, "failed": True})
                sg_hard_failed = True
                print(f"[Phase A] Snapshot guard HARD FAILED for {t.target_id}: {err_str[:300]}")
                break
    result["snapshot_guard"] = sg_results
    if sg_hard_failed:
        result["overall_status"] = "snapshot_guard_failed"
        return result
    print(f"[Phase A] Snapshot guard done for all {len(ring_targets)} targets")

    # 3+4. Materialize + run each target (in dependency order)
    # Compute pre_flip_ts: pin all gold clones to 01:00 UTC of the TARGET day (D-1).
    # Gold tables flip at ~04:24 UTC each night — i.e. the D-1 gold flip happens on D-1 at ~04:24 UTC.
    # At 01:00 UTC on target_date (D-1) the gold table still has D-2 as its latest data.
    # By contrast, run_date 01:00:00 is already AFTER D-1 flipped (04:24 UTC the night before),
    # so cloning at run_date 01:00:00 gives a baseline that already contains D-1 rows —
    # the proc would double-count them (baseline 3.3M + proc 3.3M = 6.5M for Fact_History_Cost).
    run_day = date.fromisoformat(run_date)
    target_day = run_day - timedelta(days=1)
    pre_flip_ts = f"{target_day.isoformat()} 01:00:00"
    print(f"[Phase A] Using pre_flip_ts={pre_flip_ts} (target_date 01:00 UTC, before D-1 gold flip)")

    overall = "success"
    for t in ring_targets:
        tgt_started = _ts()
        print(f"[Phase A] Target {t.target_id}: materializing ...")

        mat = materialize_target(
            w, wid,
            target_id=t.target_id,
            gold_table=t.gold_table,
            parallel_table_name=t.parallel_table_name,
            wrapper_proc=t.wrapper_proc,
            gold_overrides=dict(t.gold_overrides),
            schema_source_table=t.schema_source_table,
            pre_flip_ts=pre_flip_ts,
        )
        if not mat.ok:
            overall = "failed"
            tgt_result = {
                "target_id": t.target_id,
                "status": "materialize_failed",
                "materialize": mat.as_dict(),
                "elapsed_ms": int((_ts() - tgt_started) * 1000),
            }
            result["target_results"].append(tgt_result)
            _write_target_json(tgt_result, target_date)
            print(f"[Phase A] MATERIALIZE FAILED for {t.target_id}")
            break

        print(f"[Phase A] Target {t.target_id}: running proc ...")
        proc_result = _run_proc(w, wid, t.proc_call_sql)

        # Stamp etr_ymd on newly written rows.  The migration procs write business
        # data but don't set etr_ymd themselves — that's the generic pipeline's job.
        # For parity to work we stamp rows where etr_ymd IS NULL after the proc call.
        stamp_result: dict = {"action": "skipped"}
        if t.has_etr_ymd and proc_result["status"] == "success":
            par_tbl = f"{PARALLEL_SCHEMA}.{t.parallel_table_name}"
            try:
                execute_sql(
                    w,
                    sql_text=(
                        f"UPDATE {par_tbl} "
                        f"SET etr_ymd = '{target_date}' "
                        f"WHERE etr_ymd IS NULL"
                    ),
                    warehouse_id=wid,
                    poll_deadline_sec=1800.0,
                )
                stamp_result = {"action": "stamped", "table": par_tbl, "etr_ymd": target_date}
                print(f"[Phase A] {t.target_id}: etr_ymd={target_date} stamped on NULL rows")
            except Exception as exc:
                stamp_result = {"action": "stamp_error", "error": str(exc)[:300]}
                print(f"[Phase A] {t.target_id}: etr_ymd stamp WARNING: {exc}")

        tgt_result = {
            "target_id": t.target_id,
            "status": proc_result["status"],
            "materialize": mat.as_dict(),
            "proc_call": proc_result,
            "etr_ymd_stamp": stamp_result,
            "elapsed_ms": int((_ts() - tgt_started) * 1000),
        }
        result["target_results"].append(tgt_result)
        _write_target_json(tgt_result, target_date)

        if proc_result["status"] != "success":
            overall = "failed"
            print(f"[Phase A] PROC FAILED for {t.target_id}: {proc_result.get('error', '')}")
            break
        print(f"[Phase A] {t.target_id} OK ({tgt_result['elapsed_ms']} ms)")

    result["overall_status"] = overall
    result["total_elapsed_ms"] = int((_ts() - started_total) * 1000)
    print(f"[Phase A] Ring {ring} done: {overall} ({result['total_elapsed_ms']} ms)")
    return result


def _write_target_json(tgt_result: dict, target_date: str) -> None:
    tid = tgt_result["target_id"]
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"parallel_phase_a_{tid}_{target_date}.json"
    path.write_text(json.dumps(tgt_result, indent=2, default=str), encoding="utf-8")
    print(f"[Phase A] Written: {path}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Phase A: gate -> snapshot_guard -> materialize -> run.")
    ap.add_argument("--ring", type=int, default=0, help="Ring number (0-3).")
    ap.add_argument("--target-date", default="", help="YYYY-MM-DD (D-1); default yesterday UTC.")
    ap.add_argument("--run-date", default="", help="YYYY-MM-DD (D); default today UTC.")
    ap.add_argument("--skip-gate", action="store_true", help="Skip bronze/preflip gate (for testing).")
    ap.add_argument("--dry-run", action="store_true", help="Gate only, no changes.")
    ap.add_argument("--out-json", default="", help="Path for overall result JSON.")
    args = ap.parse_args()

    target_date = args.target_date.strip() or target_date_default()
    run_date = args.run_date.strip() or run_date_default()

    result = run_phase_a(
        ring=args.ring,
        target_date=target_date,
        run_date=run_date,
        skip_gate=args.skip_gate,
        dry_run=args.dry_run,
    )

    out_path = (
        Path(args.out_json)
        if args.out_json
        else OUT_DIR / f"parallel_phase_a_ring{args.ring}_{target_date}.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2, default=str), encoding="utf-8")
    print(json.dumps({"overall_status": result["overall_status"], "out_json": str(out_path)}, indent=2))
    return 0 if result["overall_status"] in ("success", "dry_run_stop") else 2


if __name__ == "__main__":
    raise SystemExit(main())
