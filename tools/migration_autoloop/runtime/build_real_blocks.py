#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.adf_block_catalog import (
    ADF_BLOCKS,
    compute_block_steps,
    compute_task_sequences,
)
from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


OUT_PATH = Path("tools/migration_autoloop/out/adf_real_blocks.json")


def _routine_def(w, wid: str, proc_name: str) -> str:
    sql = f"""
SELECT routine_definition
FROM system.information_schema.routines
WHERE routine_catalog='dwh_daily_process'
  AND routine_schema='migration_tables'
  AND routine_name='{proc_name}'
""".strip()
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1200.0)
    return str(rows[0][0] or "") if rows else ""


def _calls_from_body(body: str) -> list[str]:
    return [
        p.lower()
        for p in re.findall(
            r"\bcall\s+dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)\s*\(",
            body,
            flags=re.IGNORECASE,
        )
    ]


def _walk_calls(w, wid: str, root_proc: str) -> list[dict[str, object]]:
    seen: set[str] = set()
    chain: list[dict[str, object]] = []
    queue: list[tuple[str, int]] = [(root_proc, 0)]
    while queue:
        proc, level = queue.pop(0)
        key = proc.lower()
        if key in seen:
            continue
        seen.add(key)
        body = _routine_def(w, wid, proc)
        calls = _calls_from_body(body)
        chain.append(
            {
                "proc_name": proc,
                "level": level,
                "body_chars": len(body),
                "calls": calls,
            }
        )
        for c in calls:
            queue.append((c, level + 1))
    return chain


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    payload: dict[str, object] = {"blocks": []}
    block_steps = compute_block_steps(ADF_BLOCKS)
    for block_id, block in ADF_BLOCKS.items():
        proc_chain = _walk_calls(w, wid, block.wrapper_proc)
        task_seq = compute_task_sequences(block)
        task_plan = []
        for t in block.tasks:
            task_plan.append(
                {
                    "task_id": t.task_id,
                    "task_kind": t.task_kind,
                    "sequence": task_seq[t.task_id],
                    "depends_on": list(t.depends_on),
                }
            )
        parallel_groups: dict[int, list[str]] = {}
        for t in task_plan:
            parallel_groups.setdefault(int(t["sequence"]), []).append(str(t["task_id"]))
        payload["blocks"].append(
            {
                "block_id": block_id,
                "block_step": block_steps[block_id],
                "pipeline_name": block.pipeline_name,
                "wrapper_proc": block.wrapper_proc,
                "depends_on_blocks": list(block.depends_on_blocks),
                "migration_table": block.migration_table,
                "gold_table": block.gold_table,
                "task_plan": task_plan,
                "parallel_groups": [
                    {"sequence": k, "tasks": v} for k, v in sorted(parallel_groups.items(), key=lambda x: x[0])
                ],
                "procedure_call_chain": proc_chain,
            }
        )
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(json.dumps({"out_json": str(OUT_PATH), "block_count": len(payload["blocks"])}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

