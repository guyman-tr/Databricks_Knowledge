#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import time

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.adf_block_catalog import ADF_BLOCKS, compute_block_steps, compute_task_sequences
from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _now_ts() -> float:
    return time.time()


def _run_task(w, wid: str, task_id: str, sql: str) -> dict[str, object]:
    started = _now_ts()
    try:
        cols, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=7200.0)
        elapsed_ms = int((_now_ts() - started) * 1000)
        sample = rows[0] if rows else []
        return {
            "task_id": task_id,
            "status": "success",
            "elapsed_ms": elapsed_ms,
            "columns": cols,
            "sample_row": sample,
        }
    except Exception as exc:  # noqa: BLE001
        elapsed_ms = int((_now_ts() - started) * 1000)
        return {
            "task_id": task_id,
            "status": "failed",
            "elapsed_ms": elapsed_ms,
            "error": str(exc),
        }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--block-id", default="fact_snapshotequity", choices=sorted(ADF_BLOCKS.keys()))
    ap.add_argument("--out-json", default="")
    args = ap.parse_args()

    block = ADF_BLOCKS[args.block_id]
    out_json = (
        Path(args.out_json)
        if args.out_json
        else Path(f"tools/migration_autoloop/out/{args.block_id}_block_run.json")
    )

    w = make_workspace_client()
    wid = warehouse_id_from_env()

    block_steps = compute_block_steps(ADF_BLOCKS)
    seq = compute_task_sequences(block)
    task_map = {t.task_id: t for t in block.tasks}
    task_results: list[dict[str, object]] = []
    overall = "success"
    stop = False
    for sequence in sorted(set(seq.values())):
        level_tasks = [t for t in block.tasks if seq[t.task_id] == sequence]
        for task in level_tasks:
            res = _run_task(w, wid, task.task_id, task.sql)
            res["sequence"] = sequence
            res["task_kind"] = task.task_kind
            res["depends_on"] = list(task.depends_on)
            task_results.append(res)
            if res["status"] != "success":
                overall = "failed"
                stop = True
                break
        if stop:
            break

    payload = {
        "block_id": block.block_id,
        "block_step": block_steps[block.block_id],
        "pipeline_name": block.pipeline_name,
        "wrapper_proc": block.wrapper_proc,
        "migration_table": block.migration_table,
        "gold_table": block.gold_table,
        "task_sequences": {tid: seq[tid] for tid in sorted(task_map.keys())},
        "overall_status": overall,
        "task_results": task_results,
    }
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2, default=str), encoding="utf-8")
    print(json.dumps({"overall_status": overall, "out_json": str(out_json)}, indent=2))
    return 0 if overall == "success" else 2


if __name__ == "__main__":
    raise SystemExit(main())

