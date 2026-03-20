# DWH_dbo.Dim_ThreeDsResponseTypes -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

None. The 15-row lookup table maps directly to the upstream Dictionary.ThreeDsResponseTypes wiki with complete value descriptions.

## Structural Questions

1. **Column name mismatch**: Source uses `Name`; DWH uses `ThreeDsResponseTypesName`. No functional impact but worth noting if aligning schemas.
2. **No ETL placeholder row**: Most DWH Dims add an ID=0 placeholder for NULL-safe JOINs. This table relies on ID=0 (Unspecified) already existing in the source. Verify this is handled in fact table JOINs.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
