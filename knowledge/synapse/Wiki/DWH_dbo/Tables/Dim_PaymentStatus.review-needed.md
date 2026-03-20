# DWH_dbo.Dim_PaymentStatus -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code or live data.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| PaymentStatusID=-1 | The -1 row (Name='N/A', DWHPaymentStatusID=0) has a midnight UpdateDate, suggesting it was manually inserted. Who inserted it and why? Should it be treated as a null-sentinel for fact tables, or does it represent a real production state? |
| DWHPaymentStatusID=0 for ID=-1 | For PaymentStatusID=-1, the DWHPaymentStatusID is 0 (not -1 as the SP pattern `[PaymentStatusID] as [DWHPaymentStatusID]` would produce). Was this manually set? Is 0 meaningful in downstream systems? |

## Structural Questions

| Question |
|----------|
| Some Declined* statuses reference legacy payment methods no longer active on eToro (e.g., DeclinedBlockedMoneyBookers, DeclinedBlockedGiropay, DeclinedBlockedELV, DeclinedBlockedDirect24, DeclinedBlockedSofort). Are these statuses still appearing in new transactions, or are they purely historical? Should they be flagged as deprecated? |
| What does PaymentStatusID=25 (MultipleDepositsAggregatedAmount) mean in practice? Does it represent a single aggregated deposit record, or is it used to mark transactions that were combined for compliance/reporting? |
| PaymentStatusID=27 (MigratedToDepositTable) -- what was migrated to the deposit table? Is this a historical status from a legacy system migration? |
| PaymentStatusID=35 (DeclineByRRE) -- what is RRE? (Risk Rules Engine?) Clarify the source system that generates this decline code. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
