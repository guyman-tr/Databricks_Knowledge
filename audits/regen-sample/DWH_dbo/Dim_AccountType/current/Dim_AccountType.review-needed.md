# DWH_dbo.Dim_AccountType -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 6 columns have Tier 1 or Tier 2 descriptions.

## Columns Needing Clarification

| Column | Issue |
|--------|-------|
| DWHAccountTypeID | Always equals AccountTypeID per SP code. Was this intended to be a surrogate identity sequence or was the design always to mirror AccountTypeID? If a surrogate, future inserts would break the equality. |

## Structural Questions

1. **AccountTypeID=18 (Trust)**: This value appears in live DWH data but is not documented in the upstream Dictionary.AccountType wiki (which covers IDs 1-17). What category does Trust belong to -- retail, managed, or other? Is it subject to retail investor protections?
2. **DWHAccountTypeID redundancy**: This column is always equal to AccountTypeID (by SP code). Consider dropping it in a future schema cleanup, as it carries no additional information.
3. **StatusID column purpose**: Hardcoded to 1 by ETL, carries no business information. Consider dropping in future schema cleanup.
4. **InsertDate vs UpdateDate duality**: Both set to GETDATE() simultaneously on every TRUNCATE+INSERT reload -- always identical on this table.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
