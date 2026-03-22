# Review Notes: Dealing_Daily_Latency_Compensation

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 7.0

## Items Requiring Human Review

1. **⚠️ PIPELINE DECOMMISSION STATUS**: Max date is 2025-01-11. The Dealing team must confirm: (a) Was SP_Latency_Report officially decommissioned? (b) Was it replaced by a new system? (c) Is the historical data in this table still consumed by any active process? This is the most important review item.

2. **Latency threshold value**: Documented as >1000ms based on SP comments. The exact threshold constant in the SP should be confirmed — it may have been changed in the 2024 updates.

3. **EMS vs legacy source**: The SP switched from `Hedge.HBCExecutionLog` to `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` (SR-223342, Dec 2023). Confirm the new source covers the same LP population and there are no gaps in coverage during the transition.

4. **CBH vs HBC HedgingType derivation**: The exact logic for classifying a position as CBH vs HBC from the EMS orders table should be confirmed — it's not obvious from the SP header.

5. **PnLVersion**: The `PnLVersion` column was added in a 2024 update (SR-245072). Confirm what values this takes and how it should be used for filtering.

6. **SlippageInDollar source**: This column is populated from `Dealing_Daily_Slippage_Positions` — confirm that the latency SP runs AFTER the slippage SP in the ETL chain (or at minimum that it reads from the same date's slippage data).

## Low-Confidence Fields

- **eToroTime**: The exact source field from the EMS log for this column is unclear from partial SP read.
- **Price_Requested**: Source unclear — may be from client request data in EMS or from `Dim_Position`.
- **Spread (CBH)**: CBH spread formula is `InitForexRate_ToSpread - InitForex_Ask` or similar — confirm the exact formula for opens vs closes and buy vs sell.
