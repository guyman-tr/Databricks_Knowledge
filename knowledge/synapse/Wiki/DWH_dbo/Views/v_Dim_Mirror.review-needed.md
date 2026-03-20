# DWH_dbo.v_Dim_Mirror -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. The view adds only one column (`snapshot_date`) and all inherited columns are documented in Dim_Mirror.

## Columns Needing Clarification

1. **snapshot_date usage intent**: Who created this view and what consumes it? Understanding the consumers would help determine if `snapshot_date` should be a query-time value (current behavior) or a fixed ETL load timestamp.

## Structural Questions

1. **SELECT * risk**: This view uses `SELECT *`, meaning any schema change to `Dim_Mirror` (column additions, reorders) will silently affect this view's output. Consider listing columns explicitly in a future revision.
2. **Consumers unknown**: No DWH objects that reference `v_Dim_Mirror` were identified during Phase 7/8 scan. This may be used by external BI tools (Tableau, Power BI) or SSRS reports directly.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
