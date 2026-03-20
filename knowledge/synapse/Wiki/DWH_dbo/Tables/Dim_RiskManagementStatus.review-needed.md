# DWH_dbo.Dim_RiskManagementStatus - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1, Tier 2, or Tier 3.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ID=0 (N/A) midnight timestamp | ID=0 has InsertDate/UpdateDate = 2026-03-11 00:00:00 (midnight) while all other rows have 2026-03-11 02:13:19. The SP uses GETDATE() for both columns. Where does the midnight timestamp for ID=0 come from? Is there a separate sentinel INSERT for ID=0, or does the staging table contain this row with a pre-set midnight timestamp? |
| DWHRiskManagementStatusID | This column always equals RiskManagementStatusID. Why does this alias exist? Is there legacy DWH code that specifically references the DWHRiskManagementStatusID column name? |

## Structural Questions

- **70 DWH rows vs 69 production rows**: Production Dictionary.RiskManagementStatus has IDs 1-69. DWH has IDs 0-69. Where does the ID=0 (N/A) row come from - is it in the staging table, or added separately?
- **StatusID always 1**: Hardcoded Active. No production equivalent. Could there be inactive risk management statuses that are excluded from DWH?
- **No DWH views join this table**: Should this be joined in any customer or deposit views?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
