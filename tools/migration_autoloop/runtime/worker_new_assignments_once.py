#!/usr/bin/env python3
from __future__ import annotations

import datetime as dt
import json
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env
from tools.migration_autoloop.flow_catalog import FLOW_CATALOG
from tools.migration_autoloop.runtime.ensure_flow_job import ensure_flow_job


def _target_date() -> str:
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def _latest_statuses(w, wid: str, target_date: str) -> dict[str, str]:
    q = f"""
WITH ranked AS (
  SELECT flow_key, run_status, ROW_NUMBER() OVER (PARTITION BY flow_key ORDER BY event_ts DESC) rn
  FROM dwh_daily_process.qa.autoloop_flow_telemetry
  WHERE target_date = DATE '{target_date}'
)
SELECT flow_key, run_status
FROM ranked
WHERE rn = 1
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    i_flow = cols.index("flow_key")
    i_status = cols.index("run_status")
    return {str(r[i_flow]): str(r[i_status]) for r in rows}


def _build_queue() -> list[tuple[str, str, str]]:
    # queue item: (assignment_type, flow_key, proc_name)
    queue: list[tuple[str, str, str]] = []
    proc_seen: set[str] = set()
    for fid, fdef in FLOW_CATALOG.items():
        if fdef.done_flow:
            continue
        proc = fdef.procedure_name.strip().lower()
        queue.append(("catalog", fid, proc))
        proc_seen.add(proc)

    missing_path = Path("tools/migration_autoloop/out/migration_missing_procs.txt")
    if missing_path.exists():
        for raw in missing_path.read_text(encoding="utf-8").splitlines():
            proc = raw.strip().lower()
            if not proc:
                continue
            if not proc.startswith("sp_"):
                continue
            if not proc.endswith("_dl_to_synapse"):
                continue
            if proc in proc_seen:
                continue
            queue.append(("missing_proc", proc, proc))
            proc_seen.add(proc)
    return queue


def _pick_assignment(latest: dict[str, str]) -> tuple[str, str, str] | None:
    for assignment_type, flow_key, proc_name in _build_queue():
        status = latest.get(flow_key, "")
        if status:
            continue  # already assigned/attempted today; leave to failure worker
        return assignment_type, flow_key, proc_name
    return None


def _has_date_param_for_proc(w, wid: str, proc_name: str) -> bool:
    q = f"""
SELECT COUNT(*) AS c
FROM system.information_schema.parameters
WHERE specific_catalog='dwh_daily_process'
  AND specific_schema='migration_tables'
  AND specific_name='{proc_name}'
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    if not rows:
        return False
    idx = cols.index("c")
    return int(rows[0][idx] or 0) > 0


def main() -> int:
    target_date = _target_date()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    latest = _latest_statuses(w, wid, target_date)
    picked = _pick_assignment(latest)
    if not picked:
        print(json.dumps({"status": "idle", "reason": "no_new_assignments"}))
        return 0
    assignment_type, flow_key, proc_name = picked

    job_payload: dict[str, object] = {}
    if assignment_type == "catalog":
        job_payload = ensure_flow_job(flow_key)

    if assignment_type == "catalog":
        out_json = f"tools/migration_autoloop/out/{flow_key}_trust_report_{target_date}.json"
        out_md = f"tools/migration_autoloop/out/{flow_key}_trust_report_{target_date}.md"
        cmd = [
            sys.executable,
            "tools/migration_autoloop/run_flow_autoloop_report.py",
            "--flow-id",
            flow_key,
            "--target-date",
            target_date,
            "--out-json",
            out_json,
            "--out-md",
            out_md,
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
    else:
        out_json = f"tools/migration_autoloop/out/{proc_name}_parity_{target_date}.json"
        cmd = [
            sys.executable,
            "tools/migration_autoloop/evaluate_proc_parity.py",
            "--proc-name",
            proc_name,
            "--target-date",
            target_date,
            "--out-json",
            out_json,
        ]
        if _has_date_param_for_proc(w, wid, proc_name):
            cmd.append("--has-date-param")
        proc = subprocess.run(cmd, capture_output=True, text=True)

    notes = (proc.stderr or proc.stdout or "").strip()
    if len(notes) > 3000:
        notes = notes[:3000] + " ...truncated..."

    # append telemetry row
    append_cmd = [
        sys.executable,
        "tools/migration_autoloop/runtime/append_single_telemetry.py",
        "--flow-key",
        flow_key,
        "--proc-name",
        proc_name,
        "--target-date",
        target_date,
        "--report-path",
        out_json,
        "--return-code",
        str(proc.returncode),
        "--cost-low",
        "4",
        "--cost-mid",
        "8",
        "--cost-high",
        "12",
        "--cumulative-mid",
        "0",
        "--notes",
        notes,
        "--max-passes",
        "10",
    ]
    # cumulative-mid is informational now; set dynamically in notes path elsewhere
    subprocess.run(append_cmd, check=False, capture_output=True, text=True)
    print(
        json.dumps(
            {
                "status": "ran",
                "assignment_type": assignment_type,
                "flow_id": flow_key,
                "proc_name": proc_name,
                "return_code": proc.returncode,
                "report": out_json,
                "job_action": job_payload.get("action"),
                "job_name": job_payload.get("job_name"),
                "job_id": job_payload.get("job_id"),
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
