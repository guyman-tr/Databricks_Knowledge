# DWH_dbo.Dim_PendingClosureStatus -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

None.

## Structural Questions

- **ETL staleness**: As of 2026-03-19, UpdateDate shows 2026-03-11 (8 days). Is the SP_Dictionaries_DL_To_Synapse scheduled run failing? Investigate DataLakeTableStatus for this table.
- **No ID=0 sentinel**: Most DWH Dim_ tables have an ID=0 placeholder for NULL FK safety. Dim_PendingClosureStatus starts at ID=1. Confirm whether Dim_Customer and Fact_SnapshotCustomer use ISNULL(PendingClosureStatusID, 1) or LEFT JOIN.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
