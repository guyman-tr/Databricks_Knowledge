# DWH_dbo.Dim_CreditType - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| Referenced By | Which fact table(s) use CreditTypeID as a foreign key? Likely Fact_CustomerCredit or a similar credit history fact. Please confirm the downstream fact table name. |
| ID=10 (IB synchronization) | What is "IB synchronization"? Is "IB" Introducing Broker? What balance events trigger this type? |
| ID=17 (FixHistoryCreditChargeBacks) | Is ID=17 a one-time data fix or does it recur in normal operations? Should it be excluded from standard financial reporting? |
| ID=31 (Data Fix) | Same question as ID=17 - is this a recurring operational type or a one-time administrative fix? |
| IDs 18-28 (mirror/copy trading) | These mirror-related types have not been active since copy trading mechanics changed. Are all these IDs still actively generated in production, or are some historical-only? |

## Structural Questions

| Question |
|----------|
| CreditTypeName uses char(50) - this causes trailing space issues in string comparisons. Was this a deliberate DDL choice or should it be varchar(50)? |
| Does the DWH have exactly the same 33 rows as production etoro.Dictionary.CreditType, or has there been schema drift (new IDs in production not yet in DWH)? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
