#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


OUT_DIR = Path("tools/migration_autoloop/out")


def _delete_parked_rows(w, wid: str) -> int:
    q_count = """
SELECT COUNT(*) AS c
FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE run_status = 'parked'
"""
    cols, rows = execute_sql(w, sql_text=q_count, warehouse_id=wid)
    idx = cols.index("c")
    count = int(rows[0][idx] or 0) if rows else 0
    if count > 0:
        q_del = """
DELETE FROM dwh_daily_process.qa.autoloop_flow_telemetry
WHERE run_status = 'parked'
"""
        execute_sql(w, sql_text=q_del, warehouse_id=wid)
    return count


def _delete_non_success_reports() -> list[str]:
    deleted: list[str] = []
    for p in OUT_DIR.glob("*_trust_report_*.json"):
        if "fact_snapshotequity" in p.name:
            continue
        md = p.with_suffix(".md")
        deleted.append(str(p))
        p.unlink(missing_ok=True)
        if md.exists():
            deleted.append(str(md))
            md.unlink(missing_ok=True)
    for p in OUT_DIR.glob("*_parity_*.json"):
        if "fact_snapshotequity" in p.name:
            continue
        deleted.append(str(p))
        p.unlink(missing_ok=True)
    return deleted


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    parked_deleted = _delete_parked_rows(w, wid)
    files_deleted = _delete_non_success_reports()
    print(
        json.dumps(
            {
                "parked_rows_deleted": parked_deleted,
                "artifact_files_deleted": files_deleted,
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

