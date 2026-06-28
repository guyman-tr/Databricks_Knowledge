#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

PROCS = [
    "sp_dictionaries_dl_to_synapse_autopoc",
    "sp_dim_position_dl_to_synapse_autopoc",
]


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    out_dir = Path("tools/migration_autoloop/runtime/top2_defs")
    out_dir.mkdir(parents=True, exist_ok=True)
    for p in PROCS:
        q = (
            "SELECT routine_definition "
            "FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' "
            "AND routine_schema='migration_tables' "
            f"AND routine_name='{p}'"
        )
        _, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
        txt = str(rows[0][0] or "") if rows else ""
        path = out_dir / f"{p}.sql"
        path.write_text(txt, encoding="utf-8")
        print(f"wrote={path} chars={len(txt)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
