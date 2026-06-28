from __future__ import annotations

import base64
import json
import re
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import workspace as ws

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    out_dir = Path("tools/migration_autoloop/out")
    out_dir.mkdir(parents=True, exist_ok=True)

    w_sql = make_workspace_client()
    wid = warehouse_id_from_env()
    q = (
        "SELECT routine_name "
        "FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        "ORDER BY routine_name"
    )
    _, rows = execute_sql(w_sql, sql_text=q, warehouse_id=wid, poll_deadline_sec=1800.0)
    routines = [str(r[0]).lower() for r in rows]
    (out_dir / "migration_routines_full.txt").write_text("\n".join(routines), encoding="utf-8")

    w = WorkspaceClient(profile="guyman")
    proc_calls: list[dict[str, object]] = []
    for j in w.jobs.list(expand_tasks=True):
        s = j.settings
        if not s or not s.tasks:
            continue
        for t in s.tasks:
            if not t.sql_task or not t.sql_task.file or not t.sql_task.file.path:
                continue
            sql_path = t.sql_task.file.path
            sql_text = ""
            try:
                exported = w.workspace.export(path=sql_path, format=ws.ExportFormat.SOURCE)
                content = exported.content or ""
                if isinstance(content, str):
                    try:
                        sql_text = base64.b64decode(content).decode("utf-8", errors="ignore")
                    except Exception:
                        sql_text = content
                elif isinstance(content, (bytes, bytearray)):
                    try:
                        sql_text = base64.b64decode(content).decode("utf-8", errors="ignore")
                    except Exception:
                        sql_text = content.decode("utf-8", errors="ignore")
            except Exception:
                continue

            for proc in re.findall(
                r"CALL\s+dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)\s*\(",
                sql_text,
                flags=re.IGNORECASE,
            ):
                proc_calls.append(
                    {
                        "job_id": int(j.job_id),
                        "job_name": s.name,
                        "task_key": t.task_key,
                        "sql_path": sql_path,
                        "proc": proc.lower(),
                    }
                )

    (out_dir / "job_sql_proc_calls.json").write_text(json.dumps(proc_calls, indent=2), encoding="utf-8")

    orchestrated = sorted({x["proc"] for x in proc_calls})
    missing = sorted(set(routines) - set(orchestrated))
    coverage = {
        "workspace": w.config.host,
        "migration_routine_count": len(routines),
        "orchestrated_proc_count": len(orchestrated),
        "missing_proc_count": len(missing),
        "coverage_pct": round((len(orchestrated) / len(routines) * 100.0), 2) if routines else 0.0,
    }
    (out_dir / "migration_orchestration_coverage.json").write_text(json.dumps(coverage, indent=2), encoding="utf-8")
    (out_dir / "migration_missing_procs.txt").write_text("\n".join(missing), encoding="utf-8")
    print(json.dumps(coverage, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
