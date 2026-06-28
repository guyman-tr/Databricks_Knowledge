#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


TARGET_PROC = "sp_dim_position_dl_to_synapse_autopoc_diag"
SOURCE_PROC = "sp_dim_position_dl_to_synapse_autopoc"


def _fetch_body(w, wid: str, proc: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{proc}'"
        ),
        warehouse_id=wid,
    )
    if not rows:
        raise RuntimeError(f"missing procedure {proc}")
    return str(rows[0][0] or "")


def _merge_blocks(body: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    for m in re.finditer(r"(?im)^\s*MERGE\s+INTO\b", body):
        start = m.start()
        semicolon = body.find(";", start)
        if semicolon == -1:
            continue
        spans.append((start, semicolon + 1))
    return spans


def _rewrite_with_limit(body: str, keep_merges: int) -> str:
    spans = _merge_blocks(body)
    out = []
    cursor = 0
    for i, (s, e) in enumerate(spans, start=1):
        out.append(body[cursor:s])
        block = body[s:e]
        if i <= keep_merges:
            out.append(block)
        else:
            out.append(f"\n-- [diag] merge {i} skipped\n")
        cursor = e
    out.append(body[cursor:])
    return "".join(out)


def _create_diag_proc(w, wid: str, body: str) -> None:
    sql = (
        "CREATE OR REPLACE PROCEDURE "
        f"dwh_daily_process.migration_tables.{TARGET_PROC}(V_dt TIMESTAMP) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)


def _run_diag(w, wid: str) -> tuple[bool, str]:
    sql = (
        "CALL dwh_daily_process.migration_tables."
        f"{TARGET_PROC}(CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP))"
    )
    try:
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=3600.0)
        return True, ""
    except Exception as exc:
        return False, str(exc)


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    body = _fetch_body(w, wid, SOURCE_PROC)
    spans = _merge_blocks(body)
    results: list[dict[str, object]] = []
    for keep in range(1, len(spans) + 1):
        trial_body = _rewrite_with_limit(body, keep)
        _create_diag_proc(w, wid, trial_body)
        ok, err = _run_diag(w, wid)
        results.append({"keep_merges": keep, "ok": ok, "error": err[:600]})
        if not ok:
            break
    print(json.dumps({"merge_count": len(spans), "results": results}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
