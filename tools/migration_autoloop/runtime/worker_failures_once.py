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


def _target_date() -> str:
    return (dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)).isoformat()


def _pick_failure(w, wid: str, target_date: str) -> dict[str, str] | None:
    q = f"""
SELECT
  flow_key,
  proc_name,
  run_status,
  report_path,
  CAST(event_ts AS STRING) AS event_ts
FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE target_date = DATE '{target_date}'
ORDER BY event_ts DESC
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    if not rows:
        return None
    parsed = [{c: str(r[i] or "") for i, c in enumerate(cols)} for r in rows]

    latest_by_canonical: dict[str, dict[str, str]] = {}
    has_success: set[str] = set()
    for row in parsed:
        canonical = _canonical_flow_key(row["flow_key"], row["proc_name"])
        if row["run_status"] == "success":
            has_success.add(canonical)
        if canonical in latest_by_canonical:
            continue
        row["canonical_flow_key"] = canonical
        latest_by_canonical[canonical] = row

    for row in latest_by_canonical.values():
        if row.get("canonical_flow_key", "") in has_success:
            continue
        if row["run_status"] in {"failed", "executed_no_mapping"}:
            return row
    return None


def _canonical_flow_key(flow_key: str, proc_name: str) -> str:
    proc_name = (proc_name or "").strip().lower()
    for fid, fd in FLOW_CATALOG.items():
        if fd.procedure_name.strip().lower() == proc_name:
            return fid
    return flow_key


def main() -> int:
    target_date = _target_date()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    pick = _pick_failure(w, wid, target_date)
    if not pick:
        print(json.dumps({"status": "idle", "reason": "no_failures"}))
        return 0

    flow_key = pick.get("canonical_flow_key") or _canonical_flow_key(pick["flow_key"], pick["proc_name"])
    proc_name = FLOW_CATALOG.get(flow_key, FLOW_CATALOG.get(pick["flow_key"], None)).procedure_name if (FLOW_CATALOG.get(flow_key) or FLOW_CATALOG.get(pick["flow_key"])) else pick["proc_name"]

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
    # Best effort: most migration procs in this queue are date-param SPs.
    cmd.append("--has-date-param")

    proc = subprocess.run(cmd, capture_output=True, text=True)
    notes = (proc.stderr or proc.stdout or "").strip()
    if len(notes) > 3000:
        notes = notes[:3000] + " ...truncated..."

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
        "5",
        "--cost-mid",
        "10",
        "--cost-high",
        "15",
        "--notes",
        notes,
        "--max-passes",
        "5",
        "--park-reason",
        "Hit retry limit (5) without success/parity.",
    ]
    subprocess.run(append_cmd, check=False, capture_output=True, text=True)
    print(json.dumps({"status": "ran", "flow_key": flow_key, "proc_name": proc_name, "return_code": proc.returncode, "report": out_json}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
