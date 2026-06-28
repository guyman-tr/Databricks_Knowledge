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
SELECT migration_table_name, synapse_table_name, gold_table_name, is_active, remarks
FROM dwh_daily_process.qa.gold_phase_table_mapping
WHERE lower(migration_table_name) IN (
  'dwh_daily_process.migration_tables.fact_snapshotcustomer',
  'dwh_daily_process.migration_tables.fact_regulationtransfer',
  'dwh_daily_process.migration_tables.fact_marketpageviews',
  'dwh_daily_process.migration_tables.util_resultsliabilities_cycle'
)
ORDER BY migration_table_name
"""
    cols, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    print(json.dumps({"columns": cols, "rows": rows}, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
