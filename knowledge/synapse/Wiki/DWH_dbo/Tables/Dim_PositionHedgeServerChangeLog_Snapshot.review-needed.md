# DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-date; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 5 columns have Tier 2 or Tier 3 descriptions.

## Columns Needing Clarification

- **HedgeServerID FK**: HedgeServerID=84 is the most recent value seen in live data. Is there a dimension table for hedge servers (e.g., Dim_HedgeServer)? Or is it a purely internal ID?
- **UpdateDate staleness**: UpdateDate is 2026-02-27 -- about 20 days stale relative to other DWH tables (which are stale to 2026-03-11). Does this SP run on a different schedule, or was it specifically disrupted?
- **Positions not in this table**: Are there positions in Dim_Position that NEVER appear in this table? (Positions that were assigned to one hedge server at open and never changed.) If so, how do analysts determine the hedge server for those positions?
- **HedgeServerID FK destination**: Is there a Dim table for HedgeServerID lookup? The value 84 appears frequently -- what entity/system does it represent?

## Structural Questions

- **Dim_PositionHedgeServerChangeLog (no suffix) was dropped**: The original table was replaced by this Snapshot table. Is the historical data preserved in the Snapshot, or was there data loss during the migration?
- **SCD2 completeness**: The FromDate for initial position rows = OpenDateID, which is joined from Dim_Position at ETL time. What happens if a position exists in PositionsHedgeServerChangeLog but NOT in Dim_Position (newly opened position not yet loaded)?
- **No partition**: This table could grow large for long-lived platforms. Is the HASH(PositionID) + CCI sufficient, or is date-based partitioning needed?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
