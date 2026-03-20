# DWH_dbo.Dim_WorldCheck -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 3 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

None. The 5-row lookup table maps directly to the upstream Dictionary.WorldCheck wiki with complete value descriptions.

## Structural Questions

1. **Type mismatch**: Source `WorldCheckID` is TINYINT; DWH DDL declares INT. No data loss but consider aligning for clarity.
2. **ID=0 empty string**: WorldCheckName for WorldCheckID=0 is an empty string, not NULL. Queries filtering on WorldCheckName should handle this case.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
