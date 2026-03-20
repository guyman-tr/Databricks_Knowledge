# DWH_dbo.Dim_CashoutStatus - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns. All elements confirmed via upstream wiki and ETL SP code.

## Columns Needing Clarification

None.

## Structural Questions

- **Missing statuses 5-17**: The DWH Dim_CashoutStatus has only 5 rows (IDs 0-4). Production Dictionary.CashoutStatus has 17 values. The staging table etoro_Dictionary_CashoutStatus appears to only contain IDs 1-4. Is this intentional (only core states needed for DWH analytics) or a data pipeline gap? Analysts JOINing Fact_Cashout_State against this table will get NULL for Rejected, Reversed, Under Review, etc.
- **Dropped flags**: IsFinalStatus and IsFinishedWithoutMoneyTransfer (from production) are not loaded into DWH. Are these needed for any planned DWH analytics? They would be valuable for distinguishing no-money-moved cancellations from successful completions.
- **DWHCashoutStatusID utility**: This column is always equal to CashoutStatusID. Is it used by any downstream consumer or is it a legacy artifact from the ETL migration pattern?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
