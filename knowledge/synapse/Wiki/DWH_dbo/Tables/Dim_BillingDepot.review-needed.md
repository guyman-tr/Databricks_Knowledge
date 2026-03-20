# DWH_dbo.Dim_BillingDepot -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 7 columns have Tier 1 or Tier 2 descriptions sourced from the upstream Billing.Depot wiki.

## Columns Needing Clarification

No clarification needed. Column meanings are well-established from the upstream wiki.

## Structural Questions

1. **Missing PayoutGeneration**: The production Billing.Depot table has a PayoutGeneration column (int, default=0) that controls automated payout batch file generation. This column is excluded from the DWH ETL SELECT. Was this intentional? If analysts need to identify payout-capable depots, they currently cannot do so from the DWH.
2. **Missing Features**: The production table also has a Features column (nvarchar(4000), nullable) for per-depot configuration flags (JSON/XML). Also excluded from DWH ETL. Same question -- intentional omission?
3. **IsActive nullable in DWH**: The DWH DDL has IsActive as bit NULL (matching production). Confirm that NULL should be treated as inactive (same as 0) in all DWH queries.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
