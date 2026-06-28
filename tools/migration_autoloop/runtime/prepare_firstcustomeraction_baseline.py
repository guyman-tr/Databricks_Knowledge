#!/usr/bin/env python3
"""Side-action: reseed Fact_FirstCustomerAction baseline (<= cutoff) from gold.

Why: the codex-era autopoc orchestrator was a destructive stub (DELETE without
the helper CALL), so migration's Fact_FirstCustomerAction drifted ~30 days
behind gold AND lost scattered historical first-occurrence rows (149.2M vs
gold 150.3M). Fact_FirstCustomerAction is APPEND-ONLY (MERGE ... WHEN NOT
MATCHED only), so a correct day-D run requires the <= D-1 baseline to match
gold exactly; otherwise combos missing from the baseline are wrongly re-claimed
on day D (overcount).

The source Fact_CustomerAction slice for the target day is already bit-identical
to gold (verified), and the proc logic is faithful, so re-seeding the baseline
from gold makes the day-D output reproduce gold by construction.

This is a partial-environment repair (NOT part of the production job): in
production yesterday's state is already present.
"""
from __future__ import annotations

import argparse
from pathlib import Path

if __package__ in {None, ""}:
    import sys

    sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.db import execute_sql, make_workspace_client, warehouse_id_from_env

MIG = "dwh_daily_process.migration_tables.Fact_FirstCustomerAction"
GOLD = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction"

COLS = (
    "GCID,RealCID,DemoCID,FirstOccurred,IPNumber,IsReal,ActionTypeID,PlatformTypeID,"
    "InstrumentID,Amount,PositionID,CampaignID,BonusTypeID,FundingTypeID,LoginID,MirrorID,"
    "WithdrawID,PostID,CaseID,UpdateDate,UpdateDateID,DateID,TimeID,CompensationReasonID,"
    "WithdrawPaymentID,DepositID,HistoryID,FirstEver,etr_y,etr_ym,etr_ymd"
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cutoff-dateid", type=int, default=20260522,
                    help="Reseed baseline for DateID <= this value from gold.")
    args = ap.parse_args()

    w = make_workspace_client()
    wid = warehouse_id_from_env()

    sql = (
        f"INSERT OVERWRITE {MIG} ({COLS}) "
        f"SELECT {COLS} FROM {GOLD} WHERE DateID <= {args.cutoff_dateid}"
    )
    execute_sql(w, sql_text=sql, warehouse_id=wid, poll_deadline_sec=2400.0)
    print(f"reseeded {MIG} baseline from gold for DateID <= {args.cutoff_dateid}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
