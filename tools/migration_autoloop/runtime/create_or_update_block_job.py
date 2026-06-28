#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.adf_block_catalog import ADF_BLOCKS, compute_task_sequences
from tools.migration_autoloop.orchestration import SqlTaskSpec, create_or_update_sql_job


WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_blocks"


def _job_name(block_id: str) -> str:
    safe = re.sub(r"[^A-Za-z0-9_]+", "_", block_id)
    return f"DWH_Daily_Process__BLOCK__{safe}__AutoPOC"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--block-id", default="fact_snapshotequity", choices=sorted(ADF_BLOCKS.keys()))
    args = ap.parse_args()

    block = ADF_BLOCKS[args.block_id]
    seq = compute_task_sequences(block)
    specs: list[SqlTaskSpec] = []
    for t in block.tasks:
        specs.append(
            SqlTaskSpec(
                task_key=f"s{seq[t.task_id]:02d}_{t.task_id}",
                sql_filename=f"{block.block_id}_s{seq[t.task_id]:02d}_{t.task_id}.sql",
                sql_text=t.sql + "\n",
                depends_on=tuple(f"s{seq[d]:02d}_{d}" for d in t.depends_on),
            )
        )

    payload = create_or_update_sql_job(
        profile="guyman",
        job_name=_job_name(block.block_id),
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        task_specs=specs,
        max_concurrent_runs=1,
    )
    payload["block_id"] = block.block_id
    payload["task_count"] = len(specs)
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

