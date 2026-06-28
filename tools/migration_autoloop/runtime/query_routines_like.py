#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--like", required=True)
    args = ap.parse_args()
    like = args.like.lower()
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = f"""
SELECT routine_name
FROM system.information_schema.routines
WHERE routine_catalog='dwh_daily_process'
  AND routine_schema='migration_tables'
  AND lower(routine_name) LIKE '%{like}%'
ORDER BY routine_name
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
