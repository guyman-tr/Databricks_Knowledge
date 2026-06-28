#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[4]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    q = """
    SELECT table_catalog, table_schema, table_name
    FROM system.information_schema.tables
    WHERE lower(table_name) LIKE '%snapshotcustomer%'
    ORDER BY table_catalog, table_schema, table_name
    """
    _, rows = execute_sql(w, sql_text=q, warehouse_id=wid)
    print(json.dumps(rows, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
