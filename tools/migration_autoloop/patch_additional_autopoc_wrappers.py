#!/usr/bin/env python3
"""Create lightweight AutoPOC wrappers for procedures without autopoc variants."""
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env


WRAPPERS: list[tuple[str, str]] = [
    (
        "sp_dim_mirror_dl_to_synapse_autopoc(V_dt TIMESTAMP)",
        """
BEGIN
  CALL dwh_daily_process.migration_tables.sp_dim_mirror_dl_to_synapse(V_dt);
END
""".strip(),
    ),
    (
        "sp_fact_deposit_state_autopoc(V_dt TIMESTAMP)",
        """
BEGIN
  CALL dwh_daily_process.migration_tables.sp_fact_deposit_state(V_dt);
END
""".strip(),
    ),
    (
        "sp_dictionaries_country_dl_to_synapse_autopoc()",
        """
BEGIN
  CALL dwh_daily_process.migration_tables.sp_dictionaries_country_dl_to_synapse();
END
""".strip(),
    ),
]


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()
    for signature, body in WRAPPERS:
        sql = (
            "CREATE OR REPLACE PROCEDURE "
            f"dwh_daily_process.migration_tables.{signature} "
            "LANGUAGE SQL "
            "SQL SECURITY INVOKER "
            f"AS {body}"
        )
        execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
        print(f"created_or_updated={signature.split('(')[0]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
