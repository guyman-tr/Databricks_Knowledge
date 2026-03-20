# DWH_dbo.Dim_Desk -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns -- all 6 columns documented from live data or SSDT DDL.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| LanguageID | LanguageID=0 appears to be a default/catch-all. Is LanguageID=0 a valid entry in Dim_Language, or is it a sentinel value meaning "any language"? |
| CFKey | "CF" prefix assumed to mean "Customer Facing." Can a domain expert confirm this acronym? |

## Structural Questions

1. **SP_CIDFirstDates removal**: Dim_Desk was removed from SP_CIDFirstDates in January 2019 and replaced with Dim_Country. Are there other SPs that have similarly migrated away from Dim_Desk that are no longer tracked?
2. **Static data risk**: All InsertDate and UpdateDate values are NULL (frozen from DWH_Migration). If desk assignments change in production CRM, this table must be manually updated. Is there a process in place to detect and apply desk assignment changes?
3. **Israel desk (CFKey=10)**: Only 26 rows. Is this correct? Is Israel considered a special case in the CRM/CRO organization requiring a dedicated desk?
4. **Missing combinations**: Are there (CountryID, LanguageID) combinations for active customers that do NOT appear in Dim_Desk? If so, those customers would have NULL desk assignments in Tableau Revenue Churn.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
