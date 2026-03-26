# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP/function code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IsGlobalFTD | Does this flag consider eMoney and IBAN deposits as well, or only TP + Options? |
| FundingTypeID | Is 0 a valid FundingTypeID in Dim_FundingType, or is it a sentinel for "not applicable"? |

## Structural Questions

- Full TRUNCATE + reload daily for ~99K rows. Is this performant enough, or should it switch to date-scoped delete/insert like the other DDR facts?
