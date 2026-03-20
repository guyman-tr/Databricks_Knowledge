# DWH_dbo.Dim_Mirror -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all 26 columns traced to SP code (Tier 2) or live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| CloseMirrorActionType | The SP passes this through from Trade.Mirror, but the mapping of specific code values is not documented. What are the valid CloseMirrorActionType values and their meanings? (e.g., does 1=manual stop, 2=stop-loss triggered, 3=admin close?) |
| IsOpenOpen | This appears to indicate whether the mirror has open positions inside it. Confirm: is IsOpenOpen=1 a blocker for immediate mirror closure, or just informational? Does it have significance for the ETL deduplication logic? |
| GuruTPV | Documented as "Guru Total Portfolio Value." Is this the copied person's total portfolio value at mirror open time, or the current value? Is it only populated for Popular Investor (MirrorTypeID=2) mirrors? |
| RealziedPnL (typo) | The column name has a persistent typo in both DDL and SP. Has a schema migration been planned to correct this to RealizedPnL? Any such migration would require coordinated update of all downstream consumers. |
| IsCopyFundMirror vs MirrorTypeID=4 | The table has both IsCopyFundMirror=1 AND MirrorTypeID=4 for Fund mirrors. Are these always identical, or can there be Fund mirrors with MirrorTypeID != 4 and vice versa? Confirm the exact relationship. |

## Structural Questions

| Question |
|----------|
| The SP deletes rows from Dim_Mirror for OpenOccurred in @Yesterday and resets CloseOccurred for rows closed @Yesterday. This means if the SP runs twice on the same day, the second run may overwrite the first. Is there any idempotency guard or is this handled by the orchestration layer? |
| MirrorTypeID=3 (Social Index) has only 122 rows total (all inactive). Is this product type deprecated? Are new Social Index mirrors still being created, or has Smart Portfolio replaced this at the DB level with a different type? |
| At 11.1M rows with no partition pruning, full table scans are expensive for analytics. Is there a plan to partition by OpenDateID year in the Gold Databricks table to improve query performance? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
