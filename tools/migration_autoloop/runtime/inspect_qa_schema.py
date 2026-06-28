#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = """
SELECT
  table_name,
  column_name,
  data_type,
  ordinal_position
FROM system.information_schema.columns
WHERE table_catalog='dwh_daily_process'
  AND table_schema='qa'
ORDER BY table_name, ordinal_position
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
