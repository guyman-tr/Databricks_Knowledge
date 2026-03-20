# DWH_dbo.Dim_ClosePositionReason - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All elements confirmed via upstream wiki and ETL SP code.

## Columns Needing Clarification

None.

## Structural Questions

- **ID=11 "Join Demo Challenge" usage**: This reason (ID=11) appears in the lookup but is not mentioned in the upstream wiki description. Confirm whether this is still actively used or is a legacy value retained for historical position records.
- **IDs 1 vs 3 and 5 vs 6 client/server split**: The upstream wiki documents both client-side and trade-server-side triggers for Stop Loss (1, 3) and Take Profit (5, 6). Confirm the exact routing logic that determines which code fires - is this based on position type, platform version, or trade server assignment?
- **ID=4 "Return to Market" usage**: This ID is in the 0-26 range but was not described in the upstream wiki. Confirm current usage status.
- **ID=16 BSL close price**: The gotcha notes that BSL closes may have close prices significantly worse than stated stop-loss. Should a flag or indicator column be added to Fact tables to identify BSL slippage magnitude for P&L reconciliation?
- **Source table naming**: DWH source staging is `etoro_Dictionary_ClosePositionActionType` but the DWH table is `Dim_ClosePositionReason`. Confirm this rename was intentional (semantic alignment) and is not causing confusion in downstream SQL.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
