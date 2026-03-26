# BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all columns traced to SP code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ActionType | CompensationReasonID 22 maps to PnLAdjustment — but the CASE for CompensationReasonID 22 appears inside ActionTypeID 36 block. Is this intentional given the ordering? |
| IsCopyFund | The SP notes Fact_CustomerAction doesn't have MirrorID for ActionTypeID=5 — is this still the case or has it been fixed? |

## Structural Questions

- The "Registred" spelling (not "Registered") — is this a known spelling that should be preserved for compatibility, or is it a bug?
- ActionTypeID 36 maps to 8+ ActionType strings. Is there a canonical reference for all CompensationReasonID values?
