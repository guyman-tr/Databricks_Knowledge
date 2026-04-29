# DWH_dbo.Dim_CardType - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns have Tier 1-2 evidence.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IsActive discrepancies | DWH shows CardTypeID=0 (None) as IsActive=1, but production wiki says IsActive=0. DWH shows Maestro (ID=8) as inactive=0, but production says active. Are these intentional DWH overrides or 2019 snapshot artifacts? |
| UpdateDate | Is this the migration load date (2019-06-30), or was it a column in the original legacy DWH SQL Server table? |

## Structural Questions

| Question | Context |
|----------|---------|
| Missing Is3dsOn | Production Dictionary.CardType has Is3dsOn (3D Secure flag) which was not migrated to DWH. Is this column needed for any DWH use cases? |
| Stale snapshot | Table is frozen at 2019 with 18 rows vs 32 in production. Should this table be refreshed from the Generic Pipeline (etoro.Dictionary.CardType, ID 229 - already landing daily in Bronze)? |
| CarTypeName typo | Column name is "CarTypeName" (missing "d"). Should this be corrected in a future schema update? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
