# BI_DB_dbo.BI_DB_FSRA_Weekly_Report — Review Needed

## Tier 4 Items
None.

## Open Questions
1. **FSRA reporting cadence**: The SP name prefix `SP_W_Wed_` suggests Wednesday execution. Confirm this is the correct reporting schedule and whether the 7-day window (Mon–Sun) aligns with FSRA regulatory requirements.
2. **Dim_Regulation JOIN field**: The SP joins on `Dim_Regulation.ID` (not `DWHRegulationID`). This is unusual — most BI_DB SPs join on DWHRegulationID. Confirm ID=11 maps to FSRA.
3. **Amount semantics vary by category**: Closed positions use realized value (Amount+NetProfit), opened positions use initial investment (InitialAmountCents/100), current-open positions use equity (Amount+PositionPnL). This makes the Amount column semantically inconsistent. Recommend documenting this clearly for analysts.
4. **No historical retention**: TRUNCATE pattern means only the latest week is available. Confirm whether historical snapshots are needed and if the backup table (Backup_20241114) serves this purpose.
5. **Writer SP mismatch in OpsDB**: OpsDB maps SP_US_Daily_Crypto as the writer. The actual writer is SP_W_Wed_BI_DB_FSRA_Weekly_Report. This is an OpsDB configuration artifact — SP_US_Daily_Crypto writes to different tables (BI_DB_US_Daily_State_Report, BI_DB_US_Daily_Conversions, BI_DB_US_Daily_State_Report_MIMO).

## Reviewer Corrections
- None pending.

## Atlassian
- Atlassian search unavailable during this batch. Recommend manual check for Jira tickets related to "FSRA" or "Abu Dhabi weekly report".
