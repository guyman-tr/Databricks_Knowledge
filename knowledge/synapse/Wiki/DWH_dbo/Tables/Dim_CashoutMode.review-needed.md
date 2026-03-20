# DWH_dbo.Dim_CashoutMode -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 4 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

No clarification needed. Column meanings are well-established from the upstream wiki.

## Structural Questions

1. **All columns nullable**: DWH DDL has all 4 columns as NULL despite CashoutModeID and CashoutModeName being NOT NULL in production. This is a schema inconsistency worth fixing in a future cleanup.
2. **ID=0 is Manual (not placeholder)**: Unlike most DWH Dim_ tables, ID=0 here is a legitimate business value (Manual processing mode), not a NULL-safety placeholder. Any code that treats ID=0 as "unknown/not applicable" would incorrectly categorize manual withdrawals.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
