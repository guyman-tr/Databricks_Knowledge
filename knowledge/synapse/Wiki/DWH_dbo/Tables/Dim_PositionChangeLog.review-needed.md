# DWH_dbo.Dim_PositionChangeLog -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Tier 4 Description | Needs Clarification |
|--------|-------------------|---------------------|
| ChangeTypeID | 0=Initial open, 1=Rate change, 2=Unknown, 5=Unknown, 11=Partial close, 12=Amount adjust, 13=Unknown | What are the official names for all ChangeTypeID values? Is there a reference table in production? |

## Columns Needing Clarification

- **ChangeTypeID mapping**: No official lookup table exists in DWH. The meanings documented are inferred from SP_Dim_Position_DL_To_Synapse code (ChangeTypeID=0 used for initial open detection, ChangeTypeID=12 for cumulative amount adjustment). Please confirm all valid values and their meanings.
- **AmountChanged=0 rows**: Live data shows rows with AmountChanged=0 and ChangeTypeID=0 or ChangeTypeID=2. Is AmountChanged=0 expected for non-amount changes (e.g., settlement status change only), or does it indicate a data quality issue?
- **Historical completeness for ChangeTypeID=0 and =2**: Before 2025-01-05, the ETL only loaded ChangeTypeIDs 1, 5, 11, 12, 13. ChangeTypeIDs 0 and 2 were excluded. Is historical data for these types available in any other table?
- **PreviousIsSettled NULL pattern**: Many rows show PreviousIsSettled=NULL even when IsSettled=1. This appears to be the "initial settlement" event where there was no previous state. Is this correct?
- **Multiple rows per position per day**: The ETL does NOT deduplicate -- a position can have multiple rows on the same OccurredDateID. Is this expected and intentional (complete history)?

## Structural Questions

- **No partition on Dim_PositionChangeLog**: The table has CLUSTERED INDEX on OccurredDateID but no PARTITION clause. Given the volume of position changes, is performance adequate without partitioning?
- **DELETE + INSERT pattern (not MERGE)**: The ETL deletes all rows with OccurredDateID >= yesterday and re-inserts. This means if a change log event has Occurred time in one day but is processed the next day, it could be deleted and lost. Is this a known risk?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
