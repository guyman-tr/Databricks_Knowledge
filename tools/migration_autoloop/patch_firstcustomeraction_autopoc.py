#!/usr/bin/env python3
"""Build DBSQL-clean autopoc procs for fact_firstcustomeraction.

Two problems in the codex-era autopoc:
  1. The orchestrator autopoc (sp_fact_firstcustomeraction_dl_to_synapse_autopoc)
     was a DESTRUCTIVE STUB: it ran the DELETE but *skipped* the helper CALL
     ("temp-view variable scope incompatibility"). Result: it deleted recent
     days and never re-inserted -> migration drifted ~30 days behind gold.
  2. The helper (sp_fact_firstcustomeraction) defines
     CREATE TEMPORARY VIEW TEMP_TABLE_FirstActions whose body references the
     scripting local variable V_dateid -> LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION.

Fix:
  - Build helper autopoc (sp_fact_firstcustomeraction_autopoc) that inlines the
    deduped FirstActions set (rn=1 per HistoryID) directly into both MERGE USING
    subqueries. Local vars ARE allowed inside DML subqueries, just not in temp
    object definitions.
  - Repoint the orchestrator autopoc to actually CALL the helper autopoc.

Parity note:
  The proc logic is identical to the production Synapse SP. Parity gaps are caused
  by the gold UC mirror of Fact_FirstCustomerAction being ~314k rows short of
  Synapse (gap concentrated in 2022-2024). Use prepare_firstcustomeraction_baseline.py
  with --sync-from-synapse to backfill those rows before running parity tests.
"""
from __future__ import annotations

from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

TGT = "dwh_daily_process.migration_tables.Fact_FirstCustomerAction"
SRC = "dwh_daily_process.migration_tables.Fact_CustomerAction"

# Deduped daily first-actions set: one row per HistoryID (rn=1), with the
# (ActionTypeID,GCID) ordinal kept as rn2. Local var V_date is legal here
# because this is a MERGE USING subquery, not a temp-object definition.
DEDUP = f"""(
  SELECT * FROM (
    SELECT a.*,
      row_number() OVER (PARTITION BY HistoryID ORDER BY Occurred, PositionID, SessionID) AS rn,
      row_number() OVER (PARTITION BY ActionTypeID, GCID ORDER BY Occurred, PositionID, SessionID) AS rn2
    FROM {SRC} a
    WHERE DateID = CAST(date_format(V_date,'yyyyMMdd') AS int)
  ) WHERE rn = 1
)"""

INSERT_COLS = """( GCID,RealCID,DemoCID,FirstOccurred,IPNumber,IsReal,ActionTypeID,PlatformTypeID,
InstrumentID,Amount,PositionID,CampaignID,BonusTypeID,FundingTypeID,LoginID,MirrorID,WithdrawID,
PostID,CaseID,DateID,TimeID,CompensationReasonID,WithdrawPaymentID,DepositID,HistoryID,FirstEver,UpdateDate)"""


def _values(first_ever: int) -> str:
    return f"""( b.GCID,b.RealCID,b.DemoCID,b.Occurred,b.IPNumber,b.IsReal,b.ActionTypeID,b.PlatformTypeID,
b.InstrumentID,b.Amount,b.PositionID,b.CampaignID,b.BonusTypeID,b.FundingTypeID,b.LoginID,b.MirrorID,b.WithdrawID,
b.PostID,b.CaseID,b.DateID,b.TimeID,b.CompensationReasonID,b.WithdrawPaymentID,b.DepositID,b.HistoryID,{first_ever},current_timestamp())"""


HELPER_BODY = f"""BEGIN
  MERGE INTO {TGT} AS a
  USING {DEDUP} AS b
  ON a.ActionTypeID = b.ActionTypeID AND a.GCID = b.GCID
  WHEN NOT MATCHED AND b.rn2 = 1 THEN INSERT {INSERT_COLS} VALUES {_values(1)};

  MERGE INTO {TGT} AS a
  USING {DEDUP} AS b
  ON a.HistoryID = b.HistoryID
  WHEN NOT MATCHED THEN INSERT {INSERT_COLS} VALUES {_values(0)};
END"""

ORCH_BODY = f"""BEGIN
  DECLARE V_Yesterday TIMESTAMP;
  SET V_Yesterday = CAST(V_dt AS TIMESTAMP);
  DELETE FROM {TGT} WHERE FirstOccurred >= V_Yesterday;
  CALL dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_autopoc(V_Yesterday);
END"""


def main() -> int:
    w = make_workspace_client()
    wid = warehouse_id_from_env()

    helper_sql = (
        "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_autopoc"
        "(V_date TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {HELPER_BODY}"
    )
    execute_sql(w, sql_text=helper_sql, warehouse_id=wid, poll_deadline_sec=600.0)
    print("deployed=sp_fact_firstcustomeraction_autopoc")

    orch_sql = (
        "CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.sp_fact_firstcustomeraction_dl_to_synapse_autopoc"
        "(V_dt TIMESTAMP) LANGUAGE SQL SQL SECURITY INVOKER "
        f"AS {ORCH_BODY}"
    )
    execute_sql(w, sql_text=orch_sql, warehouse_id=wid, poll_deadline_sec=600.0)
    print("deployed=sp_fact_firstcustomeraction_dl_to_synapse_autopoc (repointed to helper)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
