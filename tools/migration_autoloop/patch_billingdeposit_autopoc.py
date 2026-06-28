#!/usr/bin/env python3
"""Build runnable _autopoc procs for fact_billingdeposit.

The Codex-era autopoc orchestrator was a no-op stub ("preserve existing migrated
slice") -- it never actually ran the extract/merge logic. This rebuilds BOTH the
orchestrator and its helper from the original transpiled bodies, fixing the
Databricks SQL dialect defects that prevented them from ever running:

Orchestrator (sp_fact_billingdeposit_dl_to_synapse):
  1. Backtick-wrapped CAST expressions e.g. `CAST(Approved AS INT)` are invalid
     identifiers -> strip the outer backticks so they become real expressions.
  2. TEMP_TABLE_Fact_BillingDepositAction view references local var V_Yesterday
     (LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION). The view is DEAD CODE (created,
     never consumed by the helper, then dropped) -> remove the local-var ref.
  3. Repoint the helper CALL to the _autopoc helper.

Helper (sp_fact_billingdeposit):
  1. Infinite freshness-wait WHILE loop (WaitforSeconds(60)) -> disable the loop
     (reference dims are already present; we don't poll for same-day refresh).
  2. TEMP_TABLE_MOPCountry view references local var V_dateID
     (LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION). The MOPCountry views are DEAD
     CODE (the BankName/CardCategory MERGE does not consume them) -> neutralize.
  3. CAST(BinCodeAsString AS INT) can fail on non-numeric bins -> TRY_CAST.

The orchestrator's extract + MERGE + INSERT produces every column the parity gate
measures (rows, DepositID, Amount, AmountUSD). The helper only enriches
non-gated descriptive columns (BankName, CardCategory).
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
    # 1. Strip outer backticks around `CAST(... AS ...)` expressions.
    body = re.sub(r"`(CAST\([^`]+?\bAS\b[^`]+?\))`", r"\1", body, flags=re.IGNORECASE)
    # 1b. Fix the T-SQL floor-to-midnight idiom whose DATEDIFF lost its day unit:
    #     DATEADD(day, DATEDIFF(0, ModificationDate), 0)  ==  midnight of ModificationDate.
    body = re.sub(
        r"date_format\(\s*DATEADD\(day,\s*DATEDIFF\(0,\s*ModificationDate\),\s*0\)\s*,\s*'yyyyMMdd'\)",
        "date_format(ModificationDate, 'yyyyMMdd')",
        body,
        flags=re.IGNORECASE,
    )
    # 2. Kill the local-var reference inside the dead TEMP_TABLE_Fact_BillingDepositAction view.
    body = body.replace(
        "CAST(date_format(DATEADD(DAY, -14, V_Yesterday), 'yyyyMMdd') AS int)",
        "19000101",
    )
    # 3. Repoint helper call to the _autopoc helper.
    body = re.sub(
        r"call\s+dwh_daily_process\.migration_tables\.SP_Fact_BillingDeposit\s*\(",
        "call dwh_daily_process.migration_tables.SP_Fact_BillingDeposit_autopoc(",
        body,
        flags=re.IGNORECASE,
    )
    return body


def patch_helper(body: str) -> str:
    # 1. Disable the freshness-wait loop (V_flag starts at 0, so <0 never runs).
    body = re.sub(r"WHILE\s+V_flag\s*<\s*2", "WHILE V_flag < 0", body, flags=re.IGNORECASE)
    # 2. Neutralize the dead MOPCountry view's local-var filter.
    body = body.replace("WHERE fbd.ModificationDateID=V_dateID", "WHERE 1=0")
    # 3. Guard the bin-code cast.
    body = re.sub(
        r"CAST\s*\(\s*fbw\.BinCodeAsString\s+AS\s+INT\s*\)",
        "TRY_CAST(fbw.BinCodeAsString AS INT)",
        body,
        flags=re.IGNORECASE,
    )
    # 4. Disambiguate the day filter in the BankName/CardCategory MERGE ON clause.
    body = re.sub(
        r"ON\s+ModificationDateID\s*=\s*V_dateID",
        "ON fbw_TGT.ModificationDateID = V_dateID",
        body,
        flags=re.IGNORECASE,
    )
    # 5. The BankName/CardCategory MERGE matches the target by BinCodeAsString, so
    #    one target row matches MANY source rows (every fact row sharing that bin).
    #    T-SQL UPDATE..FROM silently picks one; Delta MERGE rejects multi-matches.
    #    Dedup the source to one row per bin (mirrors the orchestrator's own QUALIFY).
    body = re.sub(
        r"(=\s*cb\.BinCode\s*)\n(\s*)\)",
        r"\1\nQUALIFY ROW_NUMBER() OVER (PARTITION BY fbw.BinCodeAsString ORDER BY 1) = 1\n\2)",
        body,
        flags=re.IGNORECASE,
    )
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

    helper_body = patch_helper(_fetch_body(w, wid, "sp_fact_billingdeposit"))
    orch_body = patch_orchestrator(_fetch_body(w, wid, "sp_fact_billingdeposit_dl_to_synapse"))

    # Save local copies for inspection.
    dump = Path(__file__).resolve().parent / "runtime" / "proc_dumps"
    (dump / "sp_fact_billingdeposit_autopoc.sql").write_text(helper_body, encoding="utf-8")
    (dump / "sp_fact_billingdeposit_dl_to_synapse_autopoc.sql").write_text(orch_body, encoding="utf-8")

    deploy(w, wid, "SP_Fact_BillingDeposit_autopoc", "V_date TIMESTAMP", helper_body)
    deploy(w, wid, "sp_fact_billingdeposit_dl_to_synapse_autopoc", "V_dt TIMESTAMP", orch_body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
