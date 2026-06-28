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
    q1 = """
    SELECT migration_table_name, synapse_table_name, gold_table_name, is_active
    FROM dwh_daily_process.qa.gold_phase_table_mapping
    WHERE lower(migration_table_name) LIKE '%fact_snapshotcustomer%'
       OR lower(synapse_table_name) LIKE '%fact_snapshotcustomer%'
       OR lower(gold_table_name) LIKE '%fact_snapshotcustomer%'
    ORDER BY migration_table_name
    """
    _, rows1 = execute_sql(w, sql_text=q1, warehouse_id=wid)
    q2 = """
    SELECT specific_name, parameter_name, data_type, ordinal_position
    FROM system.information_schema.parameters
    WHERE specific_catalog='dwh_daily_process'
      AND specific_schema='migration_tables'
      AND specific_name IN ('sp_fact_snapshotcustomer_dl_to_synapse','sp_fact_snapshotcustomer')
    ORDER BY specific_name, ordinal_position
    """
    _, rows2 = execute_sql(w, sql_text=q2, warehouse_id=wid)
    print(json.dumps({"mapping": rows1, "params": rows2}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
