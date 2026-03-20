# DWH_dbo.Dim_RiskStatus - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1 or Tier 2.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DWHRiskStatusID | Always equals RiskStatusID. Is there legacy DWH code that requires this specific column name? Can it be deprecated? |
| IsActive vs StatusID | IsActive (from production) and StatusID (hardcoded 1 by ETL) are two different "active" flags. Is StatusID meaningful in context, or is it purely an artifact of the SP template? Should IsActive=0 rows be filtered in analytics? |
| RiskCategoryID dropped | Production Dictionary.RiskStatus has RiskCategoryID (FK to Dictionary.RiskCategories) for grouping risk flags by category. This is dropped by DWH ETL. Should it be added back? It would enable grouping by category (velocity, country, fraud, etc.) without hardcoding IDs. |

## Structural Questions

- **Three risk dimensions**: DWH has Dim_RiskClassification (overall level), Dim_RiskManagementStatus (deposit check), Dim_RiskStatus (customer flag). Are there DWH fact tables that join to all three? Clarify which fact tables carry each type of RiskID.
- **90 rows with gaps**: Some IDs between 0-90 are absent. Were these permanently deleted from production, or temporarily inactive?
- **"Negative Paramaters Relations" typo**: ID=9 has a Name typo ("Paramaters"). Is this from production or a DWH-specific entry?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
