#!/usr/bin/env python3
"""Delete snapshotequity AutoPOC artifacts for clean restart."""
from __future__ import annotations

import json

import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

PROCS = [
    "sp_fact_snapshotequity_autopoc",
    "sp_fact_snapshotequity_dl_to_synapse_autopoc",
    "sp_fact_snapshotequity_inprocesscashouts_autopoc",
    "sp_fact_snapshotequity_totalpositionamount_autopoc",
    "sp_fact_snapshotequity_extract_autopoc",
]

JOB_NAME = "DWH_Daily_Process__Fact_SnapshotEquity_DAG_AutoPOC"


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    deleted = {"procedures": [], "job_ids": []}

    for p in PROCS:
        sql = f"DROP PROCEDURE IF EXISTS dwh_daily_process.migration_tables.{p}"
        execute_sql(w, sql_text=sql, warehouse_id=wid)
        deleted["procedures"].append(p)

    for j in w.jobs.list(name=JOB_NAME):
        if j.settings and j.settings.name == JOB_NAME and j.job_id is not None:
            w.jobs.delete(job_id=int(j.job_id))
            deleted["job_ids"].append(int(j.job_id))

    print(json.dumps(deleted, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
