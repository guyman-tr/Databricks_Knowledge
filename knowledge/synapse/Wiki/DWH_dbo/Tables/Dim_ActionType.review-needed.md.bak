# DWH_dbo.Dim_ActionType - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns have Tier 2-3 evidence.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| CategoryID vs Category | ActionTypeID=45 (InternalWithdraw) has CategoryID=4 but Category="Withdraw" instead of "Cashout". Is this intentional (a separate Withdraw sub-category within CategoryID=4) or a data quality issue? |
| UpdateDate/InsertDate | These appear to be passthrough from the legacy DWH SQL Server. Were new entries (IDs 44-45 added 2024-04-03) manually inserted, or is there a pipeline/mechanism outside the SSDT repo that updates this table? |

## Structural Questions

| Question | Context |
|----------|---------|
| ETL mechanism | No writer SP found in SSDT repo. How are new ActionTypeIDs added? Is there an ADF pipeline, a linked server connection, or a manual DBA process? |
| Production source mismatch | etoro.Dictionary.ActionType (Generic Pipeline ID 213) has completely different content (16 session/registration events). Is DWH_dbo.Dim_ActionType purely a DWH-internal dimension with no production equivalent, or is there a separate production source not covered by the Generic Pipeline? |
| Category/CategoryID relationship | Is the mapping between Category string and CategoryID integer stable/enforced, or can different rows have the same CategoryID with different Category strings (as seen with ID=45)? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
