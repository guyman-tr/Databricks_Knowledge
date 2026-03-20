# DWH_dbo.Dim_CustomerChangeType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns — all 3 columns documented from live data or DWH_Migration DDL.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| CustomerChangeTypeID | Column is tinyint NULL (nullable despite being the natural key). Should this be NOT NULL? Or is NULL used for any special meaning in the consuming Fact_SnapshotCustomer? |

## Structural Questions

1. **SP_Fact_SnapshotCustomer commented-out reference**: The decode query using CustomerChangeTypeID is currently commented out in SP_Fact_SnapshotCustomer. Does Fact_SnapshotCustomer still contain a CustomerChangeTypeID column? If so, is it populated? Should this dimension be actively used for decoding?
2. **No NoDbObjectsScripts JUNK match**: The JUNK_ migration staging table was found, consistent with the standard Synapse migration pattern. Are there additional customer change types tracked in the current production system that were not present in 2018 and should be added?
3. **16 rows frozen since 2018**: Should newer Dim_Customer fields (e.g., WorldCheckID, ScreeningStatusID, MifidCategorizationID) be added as new rows if change tracking is extended?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
