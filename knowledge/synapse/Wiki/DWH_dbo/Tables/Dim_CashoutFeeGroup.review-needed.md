# DWH_dbo.Dim_CashoutFeeGroup -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

No clarification needed. This is a simple 3-value lookup with well-established business meaning from the upstream wiki.

## Structural Questions

1. **No ID=0 placeholder**: Unlike most DWH Dim_ tables, this one has no ID=0 (N/A) row. If any customer or fact table has a NULL or 0 CashoutFeeGroupID, it will produce NULLs on LEFT JOIN. Is this intentional, or should an ID=0 placeholder be added for consistency?
2. **All columns nullable**: DWH DDL has all 3 columns as NULL despite them being NOT NULL in production. This is an inconsistency worth noting in a future schema cleanup.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
