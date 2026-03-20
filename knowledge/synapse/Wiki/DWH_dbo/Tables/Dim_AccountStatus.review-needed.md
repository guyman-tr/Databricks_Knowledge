# DWH_dbo.Dim_AccountStatus -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 5 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

No clarification needed. This is a simple 2-value lookup table with self-evident meaning.

## Structural Questions

1. **StatusID column purpose**: This column is hardcoded to 1 by ETL and carries no business information. Consider dropping it in a future schema cleanup.
2. **InsertDate vs UpdateDate duality**: Both columns are set to GETDATE() simultaneously on every TRUNCATE+INSERT reload, making them identical and redundant for this table.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
