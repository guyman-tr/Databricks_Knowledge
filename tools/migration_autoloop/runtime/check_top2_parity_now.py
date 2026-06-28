#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


def _one_value(w, wid: str, sql: str) -> int:
    _, rows = execute_sql(w, sql_text=sql, warehouse_id=wid)
    return int(rows[0][0])


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    checks = [
        (
            "dictionaries_dim_country_count",
            "SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_country",
            "SELECT COUNT(*) FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country",
        ),
        (
            "dim_position_count",
            "SELECT COUNT(*) FROM dwh_daily_process.migration_tables.dim_position",
            "SELECT COUNT(*) FROM main.dwh.dim_position",
        ),
    ]
    out: list[dict[str, object]] = []
    for name, mig_sql, gold_sql in checks:
        mig = _one_value(w, wid, mig_sql)
        gold = _one_value(w, wid, gold_sql)
        out.append({"check": name, "migration": mig, "gold": gold, "match": mig == gold})
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
