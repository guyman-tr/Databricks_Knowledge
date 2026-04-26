# Review Needed: BI_DB_dbo.BI_DB_eTorian_PnL

Generated: 2026-04-22 | Reviewer: —

## Tier 4 Items (Unverified — Human Review Required)

None — all columns are Tier 2 (from SP code).

## Questions for SME

1. **CID=149 hardcoded inclusion**: The SP always includes `OR fsc.RealCID=149` in the eTorian population filter. Is CID=149 a test account, an internal trading account, or a legacy placeholder? Should it be excluded from analytics?

2. **BI_DB_PositionPnL as source**: This table's PnL data comes from `BI_DB_PositionPnL.PositionPnL` (filtered by DateID). Is `BI_DB_PositionPnL` itself refreshed before `SP_eTorian_PnL_NetProfit` runs in the OpsDB dependency chain? If `BI_DB_PositionPnL` is stale at month-end, the PnL snapshot here would be incorrect.

3. **InstrumentTypeID coverage**: The three buckets (TypeID=10, TypeIDs 5/6, TypeIDs 1/2/4) cover the known types. Are there other InstrumentTypeIDs (e.g., 3, 7, 8, 9) that could appear in `BI_DB_PositionPnL` for eTorian customers? If so, their PnL is silently excluded from all three columns.

4. **Month-end vs daily OpsDB**: OpsDB registers this SP as SB_Daily (Priority 20). On non-month-end days the BI_DB_eTorian_PnL block is skipped entirely. Is the daily OpsDB run necessary for this table, or was the schedule set to match `BI_DB_eTorian_NetProfit` (which is daily)?

5. **Historical gap before 2021**: The table starts Jan 2021. Was eTorian PnL tracked elsewhere before this table was created, or was this a new reporting requirement introduced in 2021?

## Corrections Log

No corrections applied.

## Pipeline Flags

- **UC Target**: _Not_Migrated — no Unity Catalog migration planned as of 2026-04-22.
- **Month-end only write**: Despite SB_Daily OpsDB schedule, SP guard `IF @Date = EOMONTH(@Date)` means the table is written at most once per month.
- **Companion table**: `BI_DB_eTorian_NetProfit` is the daily closed-position counterpart; both are written by `SP_eTorian_PnL_NetProfit`.
- **Pnl_Other sparsity**: 76% of rows have Pnl_Other=0 — Other instruments (Forex/index/commodity) are rarely held by eTorian customers.
