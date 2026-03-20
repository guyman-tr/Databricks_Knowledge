# DWH_dbo.Dim_VerificationLevel -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 6 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

1. **DWHVerificationLevelID usage**: This column appears to be an alias of `ID`. Confirm which DWH ETL procedures reference `DWHVerificationLevelID` specifically (rather than `ID`) to understand if this column is actively consumed or can be deprecated.

## Structural Questions

1. **DWHVerificationLevelID redundancy**: Storing the same value as both `ID` and `DWHVerificationLevelID` is redundant. Consider deprecating one of these in a future cleanup pass.
2. **StatusID/InsertDate/UpdateDate trinity**: These three ETL-convention columns are hardcoded and carry no business meaning. Candidates for removal in a leaner schema.
3. **ID=-1 sentinel purpose**: Verify which fact tables require this sentinel for NULL-safe JOINs on VerificationLevelID.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
