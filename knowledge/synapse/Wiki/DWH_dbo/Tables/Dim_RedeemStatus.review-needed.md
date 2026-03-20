# DWH_dbo.Dim_RedeemStatus - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 1 or Tier 2 (with some Tier 3 for row values that have evolved past the upstream wiki).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Name column values | The upstream wiki (Dictionary.RedeemStatus.md, 2026-03-13) documents ID=2 as "InProcess" and ID=3 as "Completed". DWH now has ID=2 as "Rejected" and ID=3 as "Approved". Has the production Dictionary.RedeemStatus table been significantly reworked? Or is the upstream wiki simply outdated? |
| RedeemStatusID=100 (New) | Why is ID=100 used for "New" (initial submission state) when all other IDs are sequential 0-25? Is this intentional to separate future status ranges? |
| State machine ordering | The documented state machine (New->PositionPending->Approved->ReadyToRedeem->PositionClosing->PositionClosed->TransactionInProcess->TransactionDone) is inferred from IDs and names. Can a domain expert confirm the correct transition order? |
| FailedToCancel (21) | This has IsCancelable=True. Does this mean the user can re-attempt cancellation, or that the system can retry? |
| TransferNegativeBalance (25) | How does this differ from TransferNegativeBalanceTerminated in Dim_RedeemReason? Are these used together? |

## Structural Questions

- **Upstream wiki is outdated**: Dictionary.RedeemStatus.md was generated 2026-03-13 and documents only 5 rows. The current production table has at least 12 rows (excluding DWH sentinel). The upstream wiki should be regenerated.
- **DWH adds InsertDate**: Production Dictionary.RedeemStatus does not have InsertDate per the upstream wiki DDL. The DWH ETL adds it via GETDATE(). Is this intentional for DWH-specific freshness tracking?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
