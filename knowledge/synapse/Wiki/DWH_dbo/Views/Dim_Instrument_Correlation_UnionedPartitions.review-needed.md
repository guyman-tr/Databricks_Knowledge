# DWH_dbo.Dim_Instrument_Correlation_UnionedPartitions - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns - all elements sourced from SP code (Tier 2).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DateID range | Active window shows only ~66 days (20260103-20260310). Is this window deliberately capped at ~2 months? The SP uses 3-month lookback for correlation but the partition tables only show 2 months of DateIDs. Are older dates rolled off to archive? |
| SampleSize threshold | What minimum SampleSize is considered reliable for production use? Documented as ">=100 recommended" but no formal threshold exists in the SP. |
| UpdateDate vs InsertDate | Both are set to GETDATE() in the SP. When would UpdateDate differ from InsertDate (re-computation scenario)? |

## Structural Questions

| Question | Context |
|----------|---------|
| Why 20 partition tables? | The SP writes to `Dim_Instrument_Correlation_Half_Records` (single logical table), but data is physically in 20 numbered tables. How are rows routed to specific partition numbers? Is there a SP or ADF pipeline that does the splitting? |
| Freshness SLA | MaxInsert as of 2026-03-19 is 2026-03-11 (8 days stale). Is this expected? What is the normal refresh schedule for SP_Dim_Instrument_Correlation_Half_Records? |
| Query performance on 3.8B rows | Are there known performance patterns or materialized subsets that consumers should use instead? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|-----------------------------|--------------|----------------|
