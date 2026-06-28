#!/usr/bin/env python3
"""Build a runnable _autopoc proc for fact_billingwithdraw.

The Codex-era autopoc orchestrator was a no-op stub. Rebuild it (and its helper) from
the original transpiled bodies, fixing the Databricks SQL dialect defects:

Orchestrator (sp_fact_billingwithdraw_dl_to_synapse):
  1. Backtick-wrapped `CAST(Approved AS INT)` -> strip outer backticks.
  2. DATEADD(day, DATEDIFF(0, bw.ModificationDate), 0) floor-to-midnight idiom whose
     DATEDIFF lost its 'day' unit -> date_format(bw.ModificationDate, 'yyyyMMdd').
  3. MERGE USING lacks a dedup -> add QUALIFY ROW_NUMBER by WithdrawID (Delta forbids
     multi-source matches).
  4. Repoint the helper CALL to the _autopoc helper (positional arg, not named).

Helper (sp_fact_billingwithdraw): only an infinite freshness-wait WHILE loop remains
(the original MERGE was already elided in transpilation). Disable the loop.

ExtractXMLValue UDF (shared) is created by patch_billingdeposit_autopoc.py / the billing
family; this proc reuses it. Gated measures (rows, WithdrawID, Amount_Withdraw, Fee) are
produced by the orchestrator extract+insert; the helper is inert.
"""
from __future__ import annotations

import re
from pathlib import Path
import sys

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

SCHEMA = "dwh_daily_process.migration_tables"


def _fetch_body(w, wid: str, name: str) -> str:
    _, rows = execute_sql(
        w,
        sql_text=(
            "SELECT routine_definition FROM system.information_schema.routines "
            "WHERE routine_catalog='dwh_daily_process' AND routine_schema='migration_tables' "
            f"AND routine_name='{name}'"
        ),
        warehouse_id=wid,
    )
    if not rows or not rows[0][0]:
        raise RuntimeError(f"procedure body not found: {name}")
    return str(rows[0][0])


def patch_orchestrator(body: str) -> str:
    body = re.sub(r"`(CAST\([^`]+?\bAS\b[^`]+?\))`", r"\1", body, flags=re.IGNORECASE)
    body = re.sub(
        r"date_format\(\s*DATEADD\(day,\s*DATEDIFF\(0,\s*([\w\.]+)\),\s*0\)\s*,\s*'yyyyMMdd'\)",
        r"date_format(\1, 'yyyyMMdd')",
        body,
        flags=re.IGNORECASE,
    )
    # Dedup the MERGE source so each target WithdrawID matches at most one source row.
    body = re.sub(
        r"(ON\s+w\.`WithdrawID`\s*=\s*e\.`WithdrawID`\s*)\n(\s*)\)",
        r"\1\nQUALIFY ROW_NUMBER() OVER (PARTITION BY w.`WithdrawID` ORDER BY 1) = 1\n\2)",
        body,
        flags=re.IGNORECASE,
    )
    # Repoint helper call to the _autopoc helper, positional arg.
    body = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Fact_BillingWithdraw\s*\(\s*V_date\s*=\s*V_Yesterday\s*\)",
        "call dwh_daily_process.migration_tables.SP_Fact_BillingWithdraw_autopoc(V_Yesterday)",
        body,
        flags=re.IGNORECASE,
    )
    return body


def patch_helper(body: str) -> str:
    body = re.sub(r"WHILE\s+V_flag\s*<\s*1", "WHILE V_flag < 0", body, flags=re.IGNORECASE)
    return body


def deploy(w, wid: str, target: str, params: str, body: str) -> None:
    sql = (
        f"CREATE OR REPLACE PROCEDURE {SCHEMA}.{target}({params}) "
        "LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {body}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=1800.0)
    print(f"deployed {target} ({params})")


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    helper_body = patch_helper(_fetch_body(w, wid, "sp_fact_billingwithdraw"))
    orch_body = patch_orchestrator(_fetch_body(w, wid, "sp_fact_billingwithdraw_dl_to_synapse"))

    dump = Path(__file__).resolve().parent / "runtime" / "proc_dumps"
    (dump / "sp_fact_billingwithdraw_autopoc.sql").write_text(helper_body, encoding="utf-8")
    (dump / "sp_fact_billingwithdraw_dl_to_synapse_autopoc.sql").write_text(orch_body, encoding="utf-8")

    deploy(w, wid, "SP_Fact_BillingWithdraw_autopoc", "V_date TIMESTAMP", helper_body)
    deploy(w, wid, "sp_fact_billingwithdraw_dl_to_synapse_autopoc", "V_dt TIMESTAMP", orch_body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
