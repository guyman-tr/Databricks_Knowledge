# DWH_dbo.Dim_CashoutReason - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All elements confirmed via upstream wiki (Dictionary.CashoutReason) and ETL SP code.

## Columns Needing Clarification

None.

## Structural Questions

- **No ID=0 placeholder**: Unlike most SP_Dictionaries-loaded tables, Dim_CashoutReason has no N/A row at ID=0. Is this intentional? Fact tables storing CashoutReasonID=0 as a default will get NULL on JOIN.
- **ID 2 "Partners withdraw"**: Different from ID 15 "Affiliate Payment" - what is the distinction between a "partner" and an "affiliate" in this context?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
