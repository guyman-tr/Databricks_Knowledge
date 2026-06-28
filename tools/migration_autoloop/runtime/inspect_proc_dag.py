#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    if len(sys.argv) < 2:
        raise SystemExit("usage: inspect_proc_dag.py <procedure_name> [--dump-path <path>]")
    proc = sys.argv[1].strip().lower()
    dump_path: Path | None = None
    if len(sys.argv) >= 4 and sys.argv[2] == "--dump-path":
        dump_path = Path(sys.argv[3])
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    q = (
        "SELECT routine_definition "
        "FROM system.information_schema.routines "
        "WHERE routine_catalog='dwh_daily_process' "
        "AND routine_schema='migration_tables' "
        f"AND routine_name='{proc}'"
    )
    _, rows = execute_sql(w, sql_text=q, warehouse_id=wid, poll_deadline_sec=1200.0)
    if not rows:
        raise SystemExit(f"procedure not found: {proc}")
    body = str(rows[0][0] or "")
    if dump_path is not None:
        dump_path.parent.mkdir(parents=True, exist_ok=True)
        dump_path.write_text(body, encoding="utf-8")

    calls = sorted(
        {
            x.lower()
            for x in re.findall(
                r"\bcall\s+dwh_daily_process\.migration_tables\.([A-Za-z0-9_]+)\s*\(",
                body,
                flags=re.IGNORECASE,
            )
        }
    )
    refs = sorted(
        {
            x.lower()
            for x in re.findall(
                r"\bdwh_daily_process\.(?:daily_snapshot|migration_tables)\.([A-Za-z0-9_]+)",
                body,
                flags=re.IGNORECASE,
            )
        }
    )
    temp_tables = sorted(
        {
            x.lower()
            for x in re.findall(r"\b(?:create|truncate|insert\s+into)\s+table\s+([A-Za-z0-9_.]+)", body, flags=re.IGNORECASE)
            if "ext_" in x.lower() or "tmp" in x.lower()
        }
    )

    out = {
        "procedure_name": proc,
        "body_chars": len(body),
        "calls_count": len(calls),
        "calls": calls,
        "ref_table_count": len(refs),
        "ref_tables": refs,
        "temp_or_ext_tables_hint": temp_tables[:80],
    }
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
