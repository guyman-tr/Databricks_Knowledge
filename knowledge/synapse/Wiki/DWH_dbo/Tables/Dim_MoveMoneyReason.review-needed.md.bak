# DWH_dbo.Dim_MoveMoneyReason - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns have Tier 1-3 evidence.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| MoveMoneyReason ID=4 | DWH has ID=4 as "Airdrop"; production wiki says ID=4 is "missing/deprecated". Is "Airdrop" a valid DWH-specific label added when airdrop credits were introduced, or is this a data quality error? |
| Missing IDs 5-9 | Production has IDs 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. These are absent from DWH. Should they be added? ID=5 is especially important since SP_Fact_CustomerAction uses it to derive ActionTypeID 44/45. |
| UpdateDate | IDs 1-3 were inserted 2022-03-27, ID 4 on 2022-11-13. What process inserts rows into this table? Manual DBA insert, or a pipeline not found in SSDT repo? |

## Structural Questions

| Question | Context |
|----------|---------|
| Missing ID=5 creates referential gap | Fact_CustomerAction rows with MoveMoneyReasonID=5 (InternalTransfer Trade) have no matching row in Dim_MoveMoneyReason. Any analyst JOIN without LEFT JOIN will silently drop these facts. Should ID=5 be inserted? |
| Stale lookup | DWH has 4 of 9 production codes. Should an automated pipeline (Generic Pipeline ID for Dictionary.MoveMoneyReason) feed this table to keep it current? |
| No ETL mechanism | No writer SP found in SSDT repo for Dim_MoveMoneyReason. Who is responsible for adding new reason codes when production Dictionary.MoveMoneyReason is updated? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
