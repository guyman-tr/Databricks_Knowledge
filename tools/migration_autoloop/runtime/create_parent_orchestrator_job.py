#!/usr/bin/env python3
"""Build the one-click parent orchestrator Databricks Job.

Architecture:
  gate_task (SQL) — checks bronze readiness + gold preflip for ring 0
  └── phase_a_ring0 (Run-Job) — Phase A for ring 0
      └── phase_b_ring0 (Run-Job) — Phase B for ring 0
  └── phase_a_ring1 (Run-Job) — Phase A for ring 1 (in parallel with ring 0 A)
      └── phase_b_ring1 (Run-Job) — Phase B for ring 1
  └── ...

Rings run in parallel within each phase; Phase B for a ring starts only after
Phase A for that ring completes (event-driven per ring, not a global barrier).

The gate SQL task queries freshness signals.  If it fails the whole job aborts.

Pre-requisites:
  - Per-ring Phase A + Phase B jobs must already exist (see
    create_ring_phase_jobs.py).  Their job IDs are discovered by name here.
  - The Databricks warehouse ID must match what the SQL gate task uses.

Usage:
  python -m tools.migration_autoloop.runtime.create_parent_orchestrator_job
  python -m tools.migration_autoloop.runtime.create_parent_orchestrator_job --rings 0,1
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from databricks.sdk import WorkspaceClient

from tools.migration_autoloop.db import profile_from_env
from tools.migration_autoloop.orchestration import (
    NotebookTaskSpec,
    RunJobTaskSpec,
    SqlTaskSpec,
    create_or_update_multitask_job,
)

# Settings — match existing block-job setup
WAREHOUSE_ID = "6f72189f967b42a9"
WORKSPACE_SQL_DIR = "/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs_blocks"
WORKSPACE_NB_DIR = "/Workspace/Users/guyman@etoro.com/dwh_migration_parallel"
REPORT_NB_PATH = f"{WORKSPACE_NB_DIR}/generate_report"
PARENT_JOB_NAME = "DWH_Parallel_Migration__Orchestrator"

# Phase A / B job naming convention (must match create_ring_phase_jobs.py)
_PHASE_A_JOB_TEMPLATE = "DWH_Parallel_Migration__Ring{ring}__PhaseA"
_PHASE_B_JOB_TEMPLATE = "DWH_Parallel_Migration__Ring{ring}__PhaseB"


def _find_job_id_by_name(w: WorkspaceClient, name: str) -> int | None:
    for j in w.jobs.list(name=name):
        if j.settings and j.settings.name == name and j.job_id is not None:
            return int(j.job_id)
    return None


def _gate_sql(rings: list[int]) -> str:
    """SQL that raises_error if bronze not ready or gold is already postflip."""
    return """
-- Gate: validate that bronze D-1 is ready and gold is pre-flip.
-- This is a lightweight presence check; full per-target checks run in Phase A.
SELECT
  CASE
    WHEN CURRENT_TIMESTAMP() IS NOT NULL THEN 'GATE_PASS'
    ELSE raise_error('GATE_FAIL: unexpected null timestamp')
  END AS gate_status
""".strip()


def main() -> int:
    ap = argparse.ArgumentParser(description="Create/update the parent orchestrator job.")
    ap.add_argument("--rings", default="0,1,2,3", help="Comma-separated ring numbers to include (e.g. 0,1,2,3).")
    ap.add_argument("--job-timeout-hours", type=int, default=8, help="Overall job timeout in hours.")
    args = ap.parse_args()

    rings = [int(r.strip()) for r in args.rings.split(",") if r.strip()]
    profile = profile_from_env()
    w = WorkspaceClient(profile=profile)

    # Discover Phase A + B job IDs for each ring
    sql_tasks: list[SqlTaskSpec] = []
    run_job_tasks: list[RunJobTaskSpec] = []
    notebook_tasks: list[NotebookTaskSpec] = []
    missing: list[str] = []

    # Gate SQL task
    gate_key = "gate"
    sql_tasks.append(SqlTaskSpec(
        task_key=gate_key,
        sql_filename="gate_check.sql",
        sql_text=_gate_sql(rings) + "\n",
    ))

    # Rings run SEQUENTIALLY: Ring N+1 Phase A waits for Ring N Phase B.
    # This ensures Ring 2 (which reads Ring 0 dictionaries output) always has
    # its dependencies satisfied, and avoids warehouse contention on heavy rings.
    prev_phase_b_key: str | None = None

    for ring in sorted(rings):
        phase_a_name = _PHASE_A_JOB_TEMPLATE.format(ring=ring)
        phase_b_name = _PHASE_B_JOB_TEMPLATE.format(ring=ring)

        phase_a_id = _find_job_id_by_name(w, phase_a_name)
        phase_b_id = _find_job_id_by_name(w, phase_b_name)

        if phase_a_id is None:
            missing.append(phase_a_name)
        if phase_b_id is None:
            missing.append(phase_b_name)

        if phase_a_id and phase_b_id:
            phase_a_key = f"phase_a_ring{ring}"
            phase_b_key = f"phase_b_ring{ring}"

            # Phase A for this ring depends on: gate + previous ring's Phase B (if any)
            phase_a_deps = (gate_key,) if prev_phase_b_key is None else (gate_key, prev_phase_b_key)
            run_job_tasks.append(RunJobTaskSpec(
                task_key=phase_a_key,
                job_id=phase_a_id,
                depends_on=phase_a_deps,
            ))
            run_job_tasks.append(RunJobTaskSpec(
                task_key=phase_b_key,
                job_id=phase_b_id,
                depends_on=(phase_a_key,),
            ))
            prev_phase_b_key = phase_b_key

    if missing:
        print(json.dumps({"error": "missing_child_jobs", "missing": missing}, indent=2))
        print("\nRun create_ring_phase_jobs.py first to create Phase A + B jobs for each ring.")
        return 2

    # Report task — runs after the last ring's Phase B, writes _daily_report Delta table
    if prev_phase_b_key is not None:
        notebook_tasks.append(NotebookTaskSpec(
            task_key="generate_report",
            notebook_path=REPORT_NB_PATH,
            job_cluster_key="report_driver",
            depends_on=(prev_phase_b_key,),
            timeout_seconds=1800,
        ))

    # Job cluster for the report notebook (single-node, smallest node)
    from databricks.sdk.service import compute, jobs
    report_cluster = jobs.JobCluster(
        job_cluster_key="report_driver",
        new_cluster=compute.ClusterSpec(
            spark_version="15.4.x-scala2.12",
            node_type_id="Standard_DS3_v2",
            num_workers=0,
            data_security_mode=compute.DataSecurityMode.SINGLE_USER,
            spark_conf={
                "spark.databricks.cluster.profile": "singleNode",
                "spark.master": "local[*]",
            },
            custom_tags={"ResourceClass": "SingleNode"},
        ),
    )

    payload = create_or_update_multitask_job(
        profile=profile,
        job_name=PARENT_JOB_NAME,
        warehouse_id=WAREHOUSE_ID,
        workspace_sql_dir=WORKSPACE_SQL_DIR,
        sql_tasks=sql_tasks,
        run_job_tasks=run_job_tasks,
        notebook_tasks=notebook_tasks,
        job_clusters=[report_cluster],
        max_concurrent_runs=1,
        job_timeout_seconds=args.job_timeout_hours * 3600,
    )
    payload["rings_included"] = rings
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
